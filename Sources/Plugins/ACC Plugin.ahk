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
					 , "Change Tires", "Tire Set", "Tire Compound", "Around", "Front Left", "Front Right", "Rear Left", "Rear Right"
					 , "Change Brakes", "Front Brake", "Rear Brake", "Repair Bodywork", "Repair Suspension"]
		
		kPSTireOptionPosition := inList(this.kPSOptions, "Change Tires")
		kPSTireOptions := 7
		kPSBrakeOptionPosition := inList(this.kPSOptions, "Change Brakes")
		kPSBrakeOptions := 2
		
		iPSIsOpen := false
		iPSSelectedOption := 1
		iPSChangeTires := false
		iPSChangeBrakes := false
		
		Plugin[] {
			Get {
				return this.iPlugin
			}
		}
		
		__New(plugin) {
			this.iPlugin := plugin
			
			SetTimer updateACCManagerState, 10000
		}
		
		openPitstopApp() {
			SendEvent % this.Plugin.OpenPitstopAppHotkey
			Sleep 500
			
			tireSetLabel := getFileName("ACC\Tyre Set.jpg", kUserScreenImagesDirectory, kScreenImagesDirectory)
			
			ImageSearch x, y, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %tireSetLabel%
			
			if x is Integer
			{
				this.iPSChangeTires := true
				
				logMessage(kLogInfo, "Assetto Corsa Competizione - Pitstop: Tires are selected for change")
			}
			else {
				this.iPSChangeTires := false
				
				logMessage(kLogInfo, "Assetto Corsa Competizione - Pitstop: Tires are not selected for change")
			}
			
			frontBrakeLabel := getFileName("ACC\Front Brake.jpg", kUserScreenImagesDirectory, kScreenImagesDirectory)
			
			ImageSearch x, y, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %frontBrakeLabel%
			
			if x is Integer
			{
				this.iPSChangeBrakes := true
				
				logMessage(kLogInfo, "Assetto Corsa Competizione - Pitstop: Brakes are selected for change")
			}
			else {
				this.iPSChangeBrakes := false
				
				logMessage(kLogInfo, "Assetto Corsa Competizione - Pitstop: Brakes are not selected for change")
			}
				
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
			
			if (targetSelectedOption > this.kPSTireOptionPosition) {
				if (targetSelectedOption <= (this.kPSTireOptionPosition + this.kPSTireOptions)) {
					if !this.iPSChangeTires
						this.toggleActivity("Change Tires")
				}
				else
					if !this.iPSChangeTires
						delta -= this.kPSTireOptions
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
				case "Change Tires", "Change Brakes", "Repair Bodywork", "Repair Suspension":
					this.selectPitstopOption(activity)
					
					SendEvent {Right}
				default:
					Throw "Unsupported activity """ . activity . """ detected in ACCManager.toggleActivity..."
			}
			
			if (activity = "Change Tires")
				this.iPSChangeTires := !this.iPSChangeTires
			else if (activity = "Change Brakes")
				this.iPSChangeBrakes := !this.iPSChangeBrakes
			
			Sleep 100
		}

		changeStrategy(direction, steps := 1) {
			this.requirePitstopApp()
				
			this.selectPitstopOption("Strategy")
			
			switch direction {
				case "Next":
					this.changePitstopOption("Increase")
				case "Previous":
					this.changePitstopOption("Decrease")
				default:
					Throw "Unsupported operation """ . direction . """ detected in ACCManager.changeStrategy..."
			}
		}

		changeFuelAmount(direction, liters := 5) {
			this.requirePitstopApp()
				
			this.selectPitstopOption("Refuel")
			
			this.changePitstopOption(direction, liters)
		}

		changeTirePressure(tire, direction, increments := 1) {
			this.requirePitstopApp()
				
			switch tire {
				case "Around", "Front Left", "Front Right", "Rear Left", "Rear Right":
					this.selectPitstopOption(tire)
				default:
					Throw "Unsupported tire position """ . tire . """ detected in ACCManager.changeTirePressure..."
			}
			
			this.changePitstopOption(direction, increments)
		}

		changeBrakeType(brake, direction) {
			this.requirePitstopApp()
				
			switch brake {
				case "Front Brake", "Rear Brake":
					this.selectPitstopOption(brake)
				default:
					Throw "Unsupported brake """ . brake . """ detected in ACCManager.changeBrakeType..."
			}
				
			switch direction {
				case "Next":
					this.changePitstopOption("Increase")
				case "Previous":
					this.changePitstopOption("Decrease")
				default:
					Throw "Unsupported operation """ . direction . """ detected in ACCManager.changeBrakeType..."
			}
		}
		
		updateACCManagerState() {
			if isACCRunning() {
				pitstopLabel := getFileName("ACC\PITSTOP.jpg", kUserScreenImagesDirectory, kScreenImagesDirectory)
				
				ImageSearch x, y, 0, 0, A_ScreenWidth, A_ScreenHeight, *50 %pitstopLabel%
				
				if x is Integer
					this.iPSIsOpen := true
				else
					this.iPSIsOpen := false
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
	if !inList(["Change Tires", "Change Brakes", "Repair Bodywork" "Repair Suspension"], activity)
		logMessage(kLogWarn, translate("Unsupported pit stop activity """) . activity . translate(""" detected in togglePitstopActivity - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.toggleActivity(activity)
	}
	finally {
		protectionOff()
	}
}

changePitstopStrategy(direction, steps := 1) {
	if !inList(["Next", "Previous"], direction)
		logMessage(kLogWarn, translate("Unsupported strategy selection """) . direction . translate(""" detected in changePitstopStrategy - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeStrategy(direction, steps)
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

changePitstopTirePressure(tire, direction, increments := 1) {
	if !inList(["Around", "Front Left", "Front Right" "Rear Left", "Rear Right"], tire)
		logMessage(kLogWarn, translate("Unsupported tire position """) . tire . translate(""" detected in changePitstopTirePressure - please check the configuration"))
		
	if !inList(["Increase", "Decrease"], direction)
		logMessage(kLogWarn, translate("Unsupported pressure change """) . direction . translate(""" detected in changePitstopTirePressure - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeTirePressure(tire, direction, increments)
	}
	finally {
		protectionOff()
	}
}

changePitstopBrakeType(brake, direction) {
	if !inList(["Front Brake", "Rear Brake"], direction)
		logMessage(kLogWarn, translate("Unsupported brake unit """) . brake . translate(""" detected in changePitstopBrakeType - please check the configuration"))
	
	if !inList(["Next", "Previous"], direction)
		logMessage(kLogWarn, translate("Unsupported brake selection """) . direction . translate(""" detected in changePitstopBrakeType - please check the configuration"))
	
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.changeBrakeType(brake, direction)
	}
	finally {
		protectionOff()
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

updateACCManagerState() {
	protectionOn()
	
	try {
		SimulatorController.Instance.findPlugin(kACCPlugin).Manager.updateACCManagerState()
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
