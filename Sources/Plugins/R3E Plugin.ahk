;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - R3E Plugin                      ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Plugins\Libraries\SimulatorPlugin.ahk
#Include ..\Libraries\JSON.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kR3EApplication = "RaceRoom Racing Experience"

global kR3EPlugin = "R3E"


;;;-------------------------------------------------------------------------;;;
;;;                         Private Constant Section                        ;;;
;;;-------------------------------------------------------------------------;;;

global kBinaryOptions = ["Serve Penalty", "Change Front Tyres", "Change Rear Tyres", "Repair Bodywork", "Repair Front Aero", "Repair Rear Aero", "Repair Suspension", "Request Pitstop"]

global kUseImageRecognition = true


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class R3EPlugin extends RaceAssistantSimulatorPlugin {
	iCommandMode := "Event"
	
	iOpenPitstopMFDHotkey := false
	iClosePitstopMFDHotkey := false
	
	iPreviousOptionHotkey := false
	iNextOptionHotkey := false
	iPreviousChoiceHotkey := false
	iNextChoiceHotkey := false
	iAcceptChoiceHotkey := false
	
	iPSImageSearchArea := false
	iPitstopOptions := []
	iPitstopOptionStates := []
	
	OpenPitstopMFDHotkey[] {
		Get {
			return this.iOpenPitstopMFDHotkey
		}
	}
	
	ClosePitstopMFDHotkey[] {
		Get {
			return this.iClosePitstopMFDHotkey
		}
	}
	
	PreviousOptionHotkey[] {
		Get {
			return this.iPreviousOptionHotkey
		}
	}
	
	NextOptionHotkey[] {
		Get {
			return this.iNextOptionHotkey
		}
	}
	
	PreviousChoiceHotkey[] {
		Get {
			return this.iPreviousChoiceHotkey
		}
	}
	
	NextChoiceHotkey[] {
		Get {
			return this.iNextChoiceHotkey
		}
	}
	
	AcceptChoiceHotkey[] {
		Get {
			return this.iAcceptChoiceHotkey
		}
	}
	
	__New(controller, name, simulator, configuration := false) {
		base.__New(controller, name, simulator, configuration)
		
		this.iCommandMode := this.getArgumentValue("pitstopMFDMode", "Event")
		
		this.iOpenPitstopMFDHotkey := this.getArgumentValue("openPitstopMFD", false)
		this.iClosePitstopMFDHotkey := this.getArgumentValue("closePitstopMFD", false)
		
		this.iPreviousOptionHotkey := this.getArgumentValue("previousOption", "W")
		this.iNextOptionHotkey := this.getArgumentValue("nextOption", "S")
		this.iPreviousChoiceHotkey := this.getArgumentValue("previousChoice", "A")
		this.iNextChoiceHotkey := this.getArgumentValue("nextChoice", "D")
		this.iAcceptChoiceHotkey := this.getArgumentValue("acceptChoice", "{Enter}")
		
		SetKeyDelay 5, 15
	}
	
	getPitstopActions(ByRef allActions, ByRef selectActions) {
		allActions := {Strategy: "Strategy", Refuel: "Refuel", TyreChange: "Change Tyres", BodyworkRepair: "Repair Bodywork", SuspensionRepair: "Repair Suspension"}
		selectActions := []
	}
	
	activateR3EWindow() {
		window := this.Simulator.WindowTitle
		
		if !WinActive(window)
			WinActivate %window%
	}
	
	sendPitstopCommand(command) {
		switch this.iCommandMode {
			case "Event":
				SendEvent %command%
			case "Input":
				SendInput %command%
			case "Play":
				SendPlay %command%
			case "Raw":
				SendRaw %command%
			default:
				Send %command%
		}
	}
	
	pitstopMFDIsOpen() {
		if (this.OpenPitstopMFDHotkey != "Off") {
			this.activateR3EWindow()
			
			return this.searchMFDImage("PITSTOP 1", "PITSTOP 2")
		}
		else
			return false
	}
		
	openPitstopMFD(descriptor := false) {
		static first := true
		static reported := false
		
		if !this.OpenPitstopMFDHotkey {
			if !reported {
				reported := true
			
				logMessage(kLogCritical, translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration"))
			
				showMessage(translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration...")
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
			
			return false
		}

		if (this.OpenPitstopMFDHotkey != "Off") {
			this.activateR3EWindow()

			secondTry := false
			
			if first
				this.sendPitstopCommand(this.OpenPitstopMFDHotkey)
				
			if !this.pitstopMFDIsOpen() {
				this.sendPitstopCommand(this.OpenPitstopMFDHotkey)
				
				secondTry := true
			}
			
			if (first && secondTry)
				this.pitstopMFDIsOpen()
			
			first := false
			
			return true
		}
		else
			return false
	}
	
	closePitstopMFD() {
		static reported := false
		
		this.activateR3EWindow()

		if this.pitstopMFDIsOpen() {
			if this.ClosePitstopMFDHotkey {
				this.sendPitstopCommand(this.ClosePitstopMFDHotkey)
				
				Sleep 50
			}
			else if !reported {
				reported := true
			
				logMessage(kLogCritical, translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration"))
			
				showMessage(translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration...")
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
		}
	}
	
	requirePitstopMFD() {
		if this.openPitstopMFD() {
			this.analyzePitstopMFD()
		
			return true
		}
		else
			return false
	}
	
	analyzePitstopMFD() {
		if (this.OpenPitstopMFDHotkey = "Off")
			return
		
		this.iPitstopOptions := []
		this.iPitstopOptionStates := []
		
		this.activateR3EWindow()

		Loop 15
			this.sendPitstopCommand(this.NextOptionHotkey)
			
		if kUseImageRecognition {
			if this.searchMFDImage("Strategy") {
				this.iPitstopOptions.Push("Strategy")
				this.iPitstopOptionStates.Push(true)
			}
			
			if this.searchMFDImage("Refuel") {
				this.iPitstopOptions.Push("Refuel")
				this.iPitstopOptionStates.Push(true)
			}
			else if (this.searchMFDImage("No Refuel")) {
				this.iPitstopOptions.Push("Refuel")
				this.iPitstopOptionStates.Push(false)
			}
			
			if this.searchMFDImage("Front Tyre Change") {
				this.iPitstopOptions.Push("Change Front Tyres")
				this.iPitstopOptionStates.Push(true)
			}
			else { ; if this.searchMFDImage("No Front Tyre Change") {
				this.iPitstopOptions.Push("Change Front Tyres")
				this.iPitstopOptionStates.Push(false)
			}
			
			if this.searchMFDImage("Rear Tyre Change") {
				this.iPitstopOptions.Push("Change Rear Tyres")
				this.iPitstopOptionStates.Push(true)
			}
			else { ; if this.searchMFDImage("No Rear Tyre Change") {
				this.iPitstopOptions.Push("Change Rear Tyres")
				this.iPitstopOptionStates.Push(false)
			}
			
			if this.searchMFDImage("Bodywork Damage") {
				this.iPitstopOptions.Push("Repair Bodywork")
				this.iPitstopOptionStates.Push(this.searchMFDImage("Bodywork Damage Selected") != false)
			}
			
			if this.searchMFDImage("Front Damage") {
				this.iPitstopOptions.Push("Repair Front Aero")
				this.iPitstopOptionStates.Push(this.searchMFDImage("Front Damage Selected") != false)
			}
			
			if this.searchMFDImage("Rear Damage") {
				this.iPitstopOptions.Push("Repair Rear Aero")
				this.iPitstopOptionStates.Push(this.searchMFDImage("Rear Damage Selected") != false)
			}
			
			if this.searchMFDImage("Suspension Damage") {
				this.iPitstopOptions.Push("Repair Suspension")
				this.iPitstopOptionStates.Push(this.searchMFDImage("Suspension Damage Selected") != false)
			}
			
			if this.searchMFDImage("PIT REQUEST") {
				this.iPitstopOptions.Push("Request Pitstop")
				this.iPitstopOptionStates.Push(true)
			}
			else {
				this.iPitstopOptions.Push("Request Pitstop")
				this.iPitstopOptionStates.Push(false)
			}
		}
		else {
			pitMenuState := getConfigurationSectionValues(readSimulatorData(this.Code), "Pit Menu State")
		
			if (pitMenuState["Strategy"] != "Unavailable") {
				this.iPitstopOptions.Push("Strategy")
				this.iPitstopOptionStates.Push(pitMenuState["Strategy"])
			}
			
			if (pitMenuState["Serve Penalty"] != "Unavailable") {
				this.iPitstopOptions.Push("Serve Penalty")
				this.iPitstopOptionStates.Push(pitMenuState["Serve Penalty"])
			}
			
			if (pitMenuState["Driver"] != "Unavailable") {
				this.iPitstopOptions.Push("Driver")
				this.iPitstopOptionStates.Push(pitMenuState["Driver"])
			}
			
			if (pitMenuState["Refuel"] != "Unavailable") {
				this.iPitstopOptions.Push("Refuel")
				this.iPitstopOptionStates.Push(pitMenuState["Refuel"])
			}
			
			if (pitMenuState["Change Front Tyres"] != "Unavailable") {
				this.iPitstopOptions.Push("Change Front Tyres")
				this.iPitstopOptionStates.Push(pitMenuState["Change Front Tyres"])
			}
			
			if (pitMenuState["Change Rear Tyres"] != "Unavailable") {
				this.iPitstopOptions.Push("Change Rear Tyres")
				this.iPitstopOptionStates.Push(pitMenuState["Change Rear Tyres"])
			}
			
			if true {
				if this.searchMFDImage("Bodywork Damage") {
					this.iPitstopOptions.Push("Repair Bodywork")
					this.iPitstopOptionStates.Push(this.searchMFDImage("Bodywork Damage Selected") != false)
				}
			}
			else {
				if (pitMenuState["Repair Bodywork"] != "Unavailable") {
					this.iPitstopOptions.Push("Repair Bodywork")
					this.iPitstopOptionStates.Push(pitMenuState["Repair Bodywork"])
				}
			}
			
			if (pitMenuState["Repair Front Aero"] != "Unavailable") {
				this.iPitstopOptions.Push("Repair Front Aero")
				this.iPitstopOptionStates.Push(pitMenuState["Repair Front Aero"])
			}
			
			if (pitMenuState["Repair Rear Aero"] != "Unavailable") {
				this.iPitstopOptions.Push("Repair Rear Aero")
				this.iPitstopOptionStates.Push(pitMenuState["Repair Rear Aero"])
			}
			
			if (pitMenuState["Repair Suspension"] != "Unavailable") {
				this.iPitstopOptions.Push("Repair Suspension")
				this.iPitstopOptionStates.Push(pitMenuState["Repair Suspension"])
			}
			
			if (pitMenuState["Bottom Button"] != "Unavailable") {
				this.iPitstopOptions.Push("Request Pitstop")
				this.iPitstopOptionStates.Push(pitMenuState["Bottom Button"])
			}
		}
	}
	
	optionAvailable(option) {
		return (this.optionIndex(option) != 0)
	}
	
	optionChosen(option) {
		index := this.optionIndex(option)
			
		return (index ? this.iPitstopOptionStates[index] : false)
	}
	
	optionIndex(option) {
		return inList(this.iPitstopOptions, option)
	}
	
	dialPitstopOption(option, action, steps := 1) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			this.activateR3EWindow()

			switch action {
				case "Accept":
					this.sendPitstopCommand(this.AcceptChoiceHotkey)
				case "Increase":
					Loop %steps%
						this.sendPitstopCommand(this.NextChoiceHotkey)
				case "Decrease":
					Loop %steps%
						this.sendPitstopCommand(this.PreviousChoiceHotkey)
				default:
					Throw "Unsupported change operation """ . action . """ detected in R3EPlugin.dialPitstopOption..."
			}
		}
	}
	
	selectPitstopOption(option) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			if (option = "Repair Bodywork")
				return (this.optionAvailable("Repair Bodywork") || this.optionAvailable("Repair Front Aero") || this.optionAvailable("Repair Rear Aero"))
			else if (option = "Change Tyres")
				return (this.optionAvailable("Change Front Tyres") || this.optionAvailable("Change Rear Tyres"))
			else {
				this.activateR3EWindow()
				
				index := this.optionIndex(option)
				
				if index {
					this.activateR3EWindow()

					Loop 15
						this.sendPitstopCommand(this.PreviousOptionHotkey)
					
					index -= 1
					
					if index
						Loop %index%
							this.sendPitstopCommand(this.NextOptionHotkey)
					
					return true
				}
				else
					return false
			}
		}
	}
	
	changePitstopOption(option, action, steps := 1) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			if (option = "Strategy")
				this.dialPitstopOption(option, action, steps)
			else if (option = "Refuel")
				this.changeFuelAmount(action, steps, false, false)
			else if (option = "Change Tyres") {
				this.toggleActivity("Change Front Tyres", false, true)
				this.toggleActivity("Change Rear Tyres", false, true)
			}
			else if (option = "Repair Bodywork") {
				this.toggleActivity("Repair Bodywork", false, true)
				this.toggleActivity("Repair Front Aero", false, true)
				this.toggleActivity("Repair Rear Aero", false, true)
			}
			else if (option = "Repair Suspension")
				this.toggleActivity("Repair Suspension", false, false)
			else
				Throw "Unsupported change operation """ . action . """ detected in R3EPlugin.changePitstopOption..."
		}
	}
	
	toggleActivity(activity, require := true, select := true) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			if inList(kBinaryOptions, activity) {
				if (!require || this.requirePitstopMFD())
					if  (!select || this.selectPitstopOption(activity))
						this.dialPitstopOption(activity, "Accept")
			}
			else
				Throw "Unsupported activity """ . activity . """ detected in R3EPlugin.toggleActivity..."
		}
	}

	changeFuelAmount(direction, litres := 5, require := true, select := true, accept := true) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			if (!require || this.requirePitstopMFD())
				if (!select || this.selectPitstopOption("Refuel")) {
					if (accept && this.optionChosen("Refuel"))
						this.sendPitstopCommand(this.AcceptChoiceHotkey)
					
					this.dialPitstopOption("Refuel", direction, litres)

					if accept
						this.sendPitstopCommand(this.AcceptChoiceHotkey)
				}
		}
	}
	
	supportsPitstop() {
		return true
	}
	
	supportsSetupImport() {
		return true
	}
	
	startPitstopSetup(pitstopNumber) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			this.requirePitstopMFD()
		
			if this.optionChosen("Request Pitstop")
				this.toggleActivity("Request Pitstop", false, true)
		}
	}

	finishPitstopSetup(pitstopNumber) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			this.activateR3EWindow()

			Loop 10
				this.sendPitstopCommand(this.NextOptionHotkey)
			
			this.sendPitstopCommand(this.AcceptChoiceHotkey)
		}
	}

	setPitstopRefuelAmount(pitstopNumber, litres) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			if this.optionAvailable("Refuel") {
				if this.optionChosen("Refuel")
					this.sendPitstopCommand(this.AcceptChoiceHotkey)
				
				this.changeFuelAmount("Decrease", 120, false, true, false)
				
				this.changeFuelAmount("Increase", litres + 3, false, false, false)
				
				this.sendPitstopCommand(this.AcceptChoiceHotkey)
			}
		}
	}
	
	setPitstopTyreSet(pitstopNumber, compound, compoundColor := false, set := false) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			if this.optionAvailable("Change Front Tyres")
				if (compound && !this.chosenOption("Change Front Tyres"))
					this.toggleActivity("Change Front Tyres", false, true)
				else if (!compound && this.chosenOption("Change Front Tyres"))
					this.toggleActivity("Change Front Tyres", false, true)

			if this.optionAvailable("Change Rear Tyres")
				if (compound && !this.chosenOption("Change Rear Tyres"))
					this.toggleActivity("Change Rear Tyres", false, true)
				else if (!compound && this.chosenOption("Change Rear Tyres"))
					this.toggleActivity("Change Rear Tyres", false, true)
		}
	}

	setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			if this.optionAvailable("Repair Suspension")
				if (repairSuspension != this.chosenOption("Repair Suspension"))
					this.toggleActivity("Repair Suspension", false, true)
			
			if this.optionAvailable("Repair Bodywork")
				if (repairBodywork != this.chosenOption("Repair Bodywork"))
					this.toggleActivity("Repair Bodywork", false, true)
			
			if this.optionAvailable("Repair Front Aero")
				if (repairBodywork != this.chosenOption("Repair Front Aero"))
					this.toggleActivity("Repair Front Aero", false, true)
			
			if this.optionAvailable("Repair Rear Aero")
				if (repairBodywork != this.chosenOption("Repair Rear Aero"))
					this.toggleActivity("Repair Rear Aero", false, true)
		}
	}
	
	getCarName(carID) {
		static carDB := false
		static lastCarID := false
		static lastCarName := false
		
		if !carDB {
			FileRead script, %kResourcesDirectory%Simulator Data\R3E\r3e-data.json
			
			carDB := JSON.parse(script)["cars"]
		}
		
		if (carID != lastCarID) {
			lastCarID := carID
			lastCarName := (carDB.HasKey(carID) ? carDB[carID]["Name"] : "Unknown")
		}
			
		return lastCarName
	}
	
	updatePositionsData(data) {
		standings := readSimulatorData(this.Code, "-Standings")
		
		Loop {
			carID := getConfigurationValue(standings, "Position Data", "Car." . A_Index . ".Car", kUndefined)
		
			if (carID == kUndefined)
				break
			else
				setConfigurationValue(standings, "Position Data", "Car." . A_Index . ".Car", this.getCarName(carID))
		}
		
		setConfigurationSectionValues(data, "Position Data", getConfigurationSectionValues(standings, "Position Data"))
	}
	
	updateSessionData(data) {
		setConfigurationValue(data, "Session Data", "Car", this.getCarName(getConfigurationValue(data, "Session Data", "Car", "")))
	}
	
	getImageFileNames(imageNames*) {
		fileNames := []
		
		for ignore, imageName in imageNames {
			imageName := ("R3E\" . imageName)
			fileName := getFileName(imageName . ".png", kUserScreenImagesDirectory)
			
			if FileExist(fileName)
				fileNames.Push(fileName)
			
			fileName := getFileName(imageName . ".jpg", kUserScreenImagesDirectory)
			
			if FileExist(fileName)
				fileNames.Push(fileName)
			
			fileName := getFileName(imageName . ".png", kScreenImagesDirectory)
			
			if FileExist(fileName)
				fileNames.Push(fileName)
			
			fileName := getFileName(imageName . ".jpg", kScreenImagesDirectory)
			
			if FileExist(fileName)
				fileNames.Push(fileName)
		}
		
		if (fileNames.Length() == 0)
			Throw "Unknown image '" . imageName . "' detected in R3EPlugin.getLabelFileName..."
		else {
			if isDebug()
				showMessage("Labels: " . values2String(", ", imageNames*) . "; Images: " . values2String(", ", fileNames*), "Pitstop MFD Image Search", "Information.png", 5000)
			
			return fileNames
		}
	}
	
	searchMFDImage(imageNames*) {
		static kSearchAreaLeft := 0
		static kSearchAreaRight := 400
		
		Loop % imageNames.Length()
		{
			imageName := imageNames[A_Index]
			pitstopImages := this.getImageFileNames(imageName)
			
			this.activateR3EWindow()
			
			curTickCount := A_TickCount
			
			imageX := kUndefined
			imageY := kUndefined
			
			Loop % pitstopImages.Length()
			{
				pitstopImage := pitstopImages[A_Index]
				
				if !this.iPSImageSearchArea {
					ImageSearch imageX, imageY, 0, 0, A_ScreenWidth, A_ScreenHeight, *100 %pitstopImage%

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, substituteVariables(translate("Full search for '%image%' took %ticks% ms"), {image: imageName, ticks: A_TickCount - curTickCount}))
					
					if imageX is Integer
						if ((imageName = "PITSTOP 1") || (imageName = "PITSTOP 2"))
							this.iPSImageSearchArea := [Max(0, imageX - kSearchAreaLeft), 0, Min(imageX + kSearchAreaRight, A_ScreenWidth), A_ScreenHeight]
				}
				else {
					ImageSearch imageX, imageY, this.iPSImageSearchArea[1], this.iPSImageSearchArea[2], this.iPSImageSearchArea[3], this.iPSImageSearchArea[4], *100 %pitstopImage%

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, substituteVariables(translate("Fast search for '%image%' took %ticks% ms"), {image: imageName, ticks: A_TickCount - curTickCount}))
				}
				
				if imageX is Integer
				{
					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, substituteVariables(translate("'%image%' found at %x%, %y%"), {image: imageName, x: imageX, y: imageY}))
					
					return true
				}
			}
		}
		
		if (getLogLevel() <= kLogInfo)
			logMessage(kLogInfo, substituteVariables(translate("'%image%' not found"), {image: imageName}))
		
		return false
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                     Function Hook Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

startR3E() {
	return SimulatorController.Instance.startSimulator(SimulatorController.Instance.findPlugin(kR3EPlugin).Simulator, "Simulator Splash Images\R3E Splash.jpg")
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeR3EPlugin() {
	local controller := SimulatorController.Instance
	
	new R3EPlugin(controller, kR3EPlugin, kR3EApplication, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeR3EPlugin()
