;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - ACC Plugin                      ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kACCPlugin = "ACC"
global kDriveMode = "Drive"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class ACCPlugin extends ControllerPlugin {
	kOpenPitstopAppHotkey := false
	kClosePitstopAppHotkey := false
	
	iACCManager := false
	iDriveMode := false
	
	class ACCManager {
		iPlugin := false
		
		kPSOptions := ["Pit Limiter", "Strategy", "Refuel"
					 , "Change Tyres", "Tyre Set", "Tyre Compound", "Around", "Front Left", "Front Right", "Rear Left", "Rear Right"
					 , "Change Brakes", "Front Brake", "Rear Brake", "Repair Suspension", "Repair Bodywork"]
		
		kPSTyreOptionPosition := inList(this.kPSOptions, "Change Tyres")
		kPSTyreOptions := 7
		kPSBrakeOptionPosition := inList(this.kPSOptions, "Change Brakes")
		kPSBrakeOptions := 2
		
		iPSIsOpen := false
		iPSSelectedOption := 1
		iPSChangeTyres := false
		iPSChangeBrakes := false
		
		iPSImageSearchArea := false
		
		Plugin[] {
			Get {
				return this.iPlugin
			}
		}
		
		__New(plugin) {
			this.iPlugin := plugin
			
			SetTimer updatePitstopState, 10000
		}
		
		openPitstopApp() {
			SendEvent % this.Plugin.OpenPitstopAppHotkey
			Sleep 500
			
			this.updatePitStopState(false)
				
			this.iPSIsOpen := true
			this.iPSSelectedOption := 1
		}
		
		closePitstopApp() {
			SendEvent % this.Plugin.ClosePitstopAppHotkey
			
			this.iPSIsOpen := false
		}
		
		requirePitstopApp() {
			if !this.iPSIsOpen
				this.openPitstopApp()
		}
		
		selectPitstopOption(option) {
			targetSelectedOption := inList(this.kPSOptions, option)
			delta := 0
			
			if (targetSelectedOption > this.kPSTyreOptionPosition) {
				if (targetSelectedOption <= (this.kPSTyreOptionPosition + this.kPSTyreOptions)) {
					if !this.iPSChangeTyres
						this.toggleActivity("Change Tyres")
				}
				else
					if !this.iPSChangeTyres
						delta -= this.kPSTyreOptions
			}
			
			if (targetSelectedOption > this.kPSBrakeOptionPosition) {
				if (targetSelectedOption <= (this.kPSBrakeOptionPosition + this.kPSBrakeOptions)) {
					if !this.iPSChangeBrakes
						this.toggleActivity("Change Brakes")
				}
				else
					if !this.iPSChangeBrakes
						delta -= this.kPSBrakeOptions
			}
			
			targetSelectedOption += delta
			
			if (targetSelectedOption > this.iPSSelectedOption)
				Loop % targetSelectedOption - this.iPSSelectedOption
				{
					SendEvent {Down}
					Sleep 50
				}
			else
				Loop % this.iPSSelectedOption - targetSelectedOption
				{
					SendEvent {Up}
					Sleep 50
				}
			
			this.iPSSelectedOption := targetSelectedOption
		}
		
		changePitstopOption(direction, steps := 1) {
			switch direction {
				case "Increase":
					Loop % steps {
						SendEvent {Right}
						Sleep 50
					}
				case "Decrease":
					Loop % steps {
						SendEvent {Left}
						Sleep 50
					}
				default:
					Throw "Unsupported change operation """ . direction . """ detected in ACCManager.changePitstopOption..."
			}
		}
		
		toggleActivity(activity) {
			this.requirePitstopApp()
				
			switch activity {
				case "Change Tyres", "Change Brakes", "Repair Bodywork", "Repair Suspension":
					this.selectPitstopOption(activity)
					
					SendEvent {Right}
				default:
					Throw "Unsupported activity """ . activity . """ detected in ACCManager.toggleActivity..."
			}
			
			if (activity = "Change Tyres")
				this.iPSChangeTyres := !this.iPSChangeTyres
			else if (activity = "Change Brakes")
				this.iPSChangeBrakes := !this.iPSChangeBrakes
			
			Sleep 100
		}

		changeStrategy(selection, steps := 1) {
			this.requirePitstopApp()
				
			this.selectPitstopOption("Strategy")
			
			switch selection {
				case "Next":
					this.changePitstopOption("Increase")
				case "Previous":
					this.changePitstopOption("Decrease")
				default:
					Throw "Unsupported operation """ . selection . """ detected in ACCManager.changeStrategy..."
			}
			
			this.updatePitstopState(false)
		}

		changeFuelAmount(direction, liters := 5) {
			this.requirePitstopApp()
				
			this.selectPitstopOption("Refuel")
			
			this.changePitstopOption(direction, liters)
		}

		changeTyrePressure(tyre, direction, increments := 1) {
			this.requirePitstopApp()
				
			switch tyre {
				case "Around", "Front Left", "Front Right", "Rear Left", "Rear Right":
					this.selectPitstopOption(tyre)
				default:
					Throw "Unsupported tyre position """ . tyre . """ detected in ACCManager.changeTyrePressure..."
			}
			
			this.changePitstopOption(direction, increments)
		}

		changeBrakeType(brake, selection) {
			this.requirePitstopApp()
				
			switch brake {
				case "Front Brake", "Rear Brake":
					this.selectPitstopOption(brake)
				default:
					Throw "Unsupported brake """ . brake . """ detected in ACCManager.changeBrakeType..."
			}
				
			switch selection {
				case "Next":
					this.changePitstopOption("Increase")
				case "Previous":
					this.changePitstopOption("Decrease")
				default:
					Throw "Unsupported operation """ . selection . """ detected in ACCManager.changeBrakeType..."
			}
		}
		
		updatePitstopState(checkPitstopApp := true) {
			static kSearchAreaLeft := 250
			static kSearchAreaRight := 150
			
			if isACCRunning() {
				lastY := false
				
				if checkPitstopApp {
					pitstopLabel := getFileName("ACC\PITSTOP.jpg", kUserScreenImagesDirectory, kScreenImagesDirectory)
					curTickCount := A_TickCount
					
					if !this.iPSImageSearchArea {
						ImageSearch x, y, 0, 0, Round(A_ScreenWidth / 2), A_ScreenHeight, *50 %pitstopLabel%
			
						logMessage(kLogInfo, translate("Full search for 'PITSTOP' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					else {
						ImageSearch x, y, this.iPSImageSearchArea[1], this.iPSImageSearchArea[2], this.iPSImageSearchArea[3], this.iPSImageSearchArea[4], *50 %pitstopLabel%
			
						logMessage(kLogInfo, translate("Optimized search for 'PITSTOP' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					
					if x is Integer
					{
						this.iPSIsOpen := true
						
						lastY := y
				
						if !this.iPSImageSearchArea
							this.iPSImageSearchArea := [Max(0, x - kSearchAreaLeft), 0, Min(x + kSearchAreaRight, A_ScreenWidth), A_ScreenHeight]
					}
					else
						this.iPSIsOpen := false
				}
				
				if (!checkPitstopApp || this.iPSIsOpen) {
					tyreSetLabel := getFileName("ACC\Tyre Set.jpg", kUserScreenImagesDirectory, kScreenImagesDirectory)
					curTickCount := A_TickCount
					
					if !this.iPSImageSearchArea {
						ImageSearch x, y, 0, lastY ? lastY : 0, Round(A_ScreenWidth / 2), A_ScreenHeight, *50 %tyreSetLabel%
					
						logMessage(kLogInfo, translate("Full search for 'Tyre set' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					else {
						ImageSearch x, y, this.iPSImageSearchArea[1], lastY ? lastY : this.iPSImageSearchArea[2], this.iPSImageSearchArea[3], this.iPSImageSearchArea[4], *50 %tyreSetLabel%
					
						logMessage(kLogInfo, translate("Optimized search for 'Tyre set' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					
					if x is Integer
					{
						this.iPSChangeTyres := true
						
						lastY := y
						
						logMessage(kLogInfo, translate("Assetto Corsa Competizione - Pitstop: Tyres are selected for change"))
					}
					else {
						this.iPSChangeTyres := false
						
						logMessage(kLogInfo, translate("Assetto Corsa Competizione - Pitstop: Tyres are not selected for change"))
					}
					
					frontBrakeLabel := getFileName("ACC\Front Brake.jpg", kUserScreenImagesDirectory, kScreenImagesDirectory)
					curTickCount := A_TickCount
					
					if !this.iPSImageSearchArea {
						ImageSearch x, y, 0, lastY ? lastY : 0, Round(A_ScreenWidth / 2), A_ScreenHeight, *50 %frontBrakeLabel%
					
						logMessage(kLogInfo, translate("Full search for 'Front Brake' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					else {
						ImageSearch x, y, this.iPSImageSearchArea[1], lastY ? lastY : this.iPSImageSearchArea[2], this.iPSImageSearchArea[3], this.iPSImageSearchArea[4], *50 %frontBrakeLabel%
					
						logMessage(kLogInfo, translate("Optimized search for 'Front Brake' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					
					if x is Integer
					{
						this.iPSChangeBrakes := true
						
						logMessage(kLogInfo, translate("Assetto Corsa Competizione - Pitstop: Brakes are selected for change"))
					}
					else {
						this.iPSChangeBrakes := false
						
						logMessage(kLogInfo, translate("Assetto Corsa Competizione - Pitstop: Brakes are not selected for change"))
					}
					
					selectDriverLabel := getFileName("ACC\Select Driver.jpg", kUserScreenImagesDirectory, kScreenImagesDirectory)
					curTickCount := A_TickCount
					
					if !this.iPSImageSearchArea {
						ImageSearch x, y, 0, lastY ? lastY : 0, Round(A_ScreenWidth / 2), A_ScreenHeight, *50 %selectDriverLabel%
					
						logMessage(kLogInfo, translate("Full search for 'Select Driver' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					else {
						ImageSearch x, y, this.iPSImageSearchArea[1], lastY ? lastY : this.iPSImageSearchArea[2], this.iPSImageSearchArea[3], this.iPSImageSearchArea[4], *50 %selectDriverLabel%
					
						logMessage(kLogInfo, translate("Optimized search for 'Select Driver' took ") . A_TickCount - curTickCount . translate(" ms"))
					}
					
					if x is Integer
					{
						if !inList(this.kPSOptions, "Select Driver")
							this.kPSOptions.InsertAt(inList(this.kPSOptions, "Repair Suspension"), "Select Driver")
					}
					else {
						position := inList(this.kPSOptions, "Select Driver")
						
						if position
							this.kPSOptions.RemoveAt(position)
					}
				}
			}
		}
	}
	
	class DriveMode extends ControllerMode {
		Mode[] {
			Get {
				return kDriveMode
			}
		}
	}

	class ChatAction extends ControllerAction {
		iMessage := ""
		
		Message[] {
			Get {
				return this.iMessage
			}
		}
		
		__New(function, label, message) {
			this.iMessage := message
			
			base.__New(function, label)
		}
		
		fireAction(function, trigger) {
			message := this.Message
			
			Send {Enter}
			Sleep 100
			Send %message%
			Sleep 100
			Send {Enter}
		}
	}
	
	Manager[] {
		Get {
			return this.getACCManager()
		}
	}
	
	OpenPitstopAppHotkey[] {
		Get {
			return this.kOpenPitstopAppHotkey
		}
	}
	
	ClosePitstopAppHotkey[] {
		Get {
			return this.kClosePitstopAppHotkey
		}
	}
	
	__New(controller, name, configuration := false) {
		this.iDriveMode := new this.DriveMode(this)
		
		base.__New(controller, name, configuration)
		
		this.registerMode(this.iDriveMode)
		
		this.kOpenPitstopAppHotkey := this.getArgumentValue("openPitstopApp", false)
		this.kClosePitstopAppHotkey := this.getArgumentValue("closePitstopApp", false)
		
		this.getACCManager()
	}
	
	runningSimulator() {
		return (isACCRunning() ? "Assetto Corsa Competizione" : false)
	}
	
	simulatorStartup(simulator) {
		base.simulatorStartup(simulator)
		
		if (inList(this.Simulators, simulator)) {
			this.Controller.setMode(this.iDriveMode)
		}
	}
	
	loadFromConfiguration(configuration) {
		local function
		
		base.loadFromConfiguration(configuration)
		
		for descriptor, message in getConfigurationSectionValues(configuration, "Chat Messages", Object()) {
			function := this.Controller.findFunction(descriptor)
			
			if (function != false) {
				message := string2Values("|", message)
			
				this.iDriveMode.registerAction(new this.ChatAction(function, message[1], message[2]))
			}
			else
				logMessage(kLogWarn, translate("Controller function ") . descriptor . translate(" not found in plugin ") . this.Plugin . translate(" - please check the configuration"))
		}
	}
	
	getACCManager() {
		return (this.iACCManager ? this.iACCManager : (this.iACCManager := new this.ACCManager(this)))
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                     Function Hook Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

startACC() {
	return SimulatorController.Instance.startSimulator(new Application("Assetto Corsa Competizione"
													 , SimulatorController.Instance.Configuration), "Simulator Splash Images\ACC Splash.jpg")
}

stopACC() {
	if isACCRunning() {
		IfWinNotActive AC2  , , WinActivate, AC2  , 
		WinWaitActive AC2  , , 2
		MouseClick left,  2093,  1052
		Sleep 500
		MouseClick left,  2614,  643
		Sleep 500
		MouseClick left,  2625,  619
		Sleep 500
	}
}

isACCRunning() {
	Process Exist, acc.exe
	
	return (ErrorLevel != 0)
}

openPitstopApp() {
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.openPitstopApp()
	}
	finally {
		protectionOff()
	}
}

closePitstopApp() {
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.closePitstopApp()
	}
	finally {
		protectionOff()
	}
}

togglePitstopActivity(activity) {
	if !inList(["Change Tyres", "Change Brakes", "Repair Bodywork" "Repair Suspension"], activity)
		logMessage(kLogWarn, translate("Unsupported pit stop activity """) . activity . translate(""" detected in togglePitstopActivity - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.toggleActivity(activity)
	}
	finally {
		protectionOff()
	}
}

changePitstopStrategy(selection, steps := 1) {
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported strategy selection """) . selection . translate(""" detected in changePitstopStrategy - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeStrategy(selection, steps)
	}
	finally {
		protectionOff()
	}
}

changePitstopFuelAmount(direction, liters := 5) {
	if !inList(["Increase", "Decrease"], direction)
		logMessage(kLogWarn, translate("Unsupported refuel change """) . direction . translate(""" detected in changePitstopFuelAmount - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeFuelAmount(direction, liters)
	}
	finally {
		protectionOff()
	}
}

changePitstopTyreSet(selection) {
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported tyre set selection """) . selection . translate(""" detected in changePitstopTyreSet - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeTyreSet(selection)
	}
	finally {
		protectionOff()
	}
}

changePitstopTyreCompound(compound) {
	if !inList(["Wet", "Dry"], compound)
		logMessage(kLogWarn, translate("Unsupported tyre compound """) . compound . translate(""" detected in changePitstopTyreCompound - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeTyreCompound(compound)
	}
	finally {
		protectionOff()
	}
}

changePitstopTyrePressure(tyre, direction, increments := 1) {
	if !inList(["Around", "Front Left", "Front Right" "Rear Left", "Rear Right"], tyre)
		logMessage(kLogWarn, translate("Unsupported tyre position """) . tyre . translate(""" detected in changePitstopTyrePressure - please check the configuration"))
		
	if !inList(["Increase", "Decrease"], direction)
		logMessage(kLogWarn, translate("Unsupported pressure change """) . direction . translate(""" detected in changePitstopTyrePressure - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeTyrePressure(tyre, direction, increments)
	}
	finally {
		protectionOff()
	}
}

changePitstopBrakeType(brake, selection) {
	if !inList(["Front Brake", "Rear Brake"], selection)
		logMessage(kLogWarn, translate("Unsupported brake unit """) . brake . translate(""" detected in changePitstopBrakeType - please check the configuration"))
	
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported brake selection """) . selection . translate(""" detected in changePitstopBrakeType - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeBrakeType(brake, selection)
	}
	finally {
		protectionOff()
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

updatePitstopState() {
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.updatePitstopState()
	}
	finally {
		protectionOff()
	}
}

initializeACCPlugin() {
	local controller := SimulatorController.Instance
	
	new ACCPlugin(controller, kACCPLugin, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeACCPlugin()
