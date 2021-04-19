;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - RF2 Plugin                      ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Plugins\Libraries\Simulator Plugin.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kRF2Application = "rFactor 2"

global kRF2Plugin = "RF2"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RF2Plugin extends RaceEngineerSimulatorPlugin {
	iOpenPitstopMFDHotkey := false
	iClosePitstopMFDHotkey := false
	
	iPitstopMFDIsOpen := false
	
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
	
	__New(controller, name, simulator, configuration := false) {
		base.__New(controller, name, simulator, configuration)
		
		this.iPitstopMode := this.findMode(kPitstopMode)
		
		this.iOpenPitstopMFDHotkey := this.getArgumentValue("openPitstopMFD", false)
		this.iClosePitstopMFDHotkey := this.getArgumentValue("closePitstopMFD", false)
	
		controller.registerPlugin(this)
	}
	
	getPitstopActions(ByRef allActions, ByRef selectActions) {
		allActions := {Refuel: "Refuel", TyreCompound: "Compound", TyreAllAround: "All Around"
					 , TyreFrontLeft: "Front Left", TyreFrontRight: "Front Right", TyreRearLeft: "Rear Left", TyreRearRight: "Rear Right"
					 , DriverSelect: "Driver", RepairRequest: "Repair"}
	}
	
	sendPitstopCommand(command, operation := false, message := false, arguments*) {
		simulator := this.Code
		arguments := values2String(";", arguments*)
		
		exePath := kBinariesDirectory . this.Code . " SHM Reader.exe"
	
		try {
			if operation
				RunWait %ComSpec% /c ""%exePath%" -%command% "%operation%:%message%:%arguments%"", , Hide
			else
				RunWait %ComSpec% /c ""%exePath%" -%command%", , Hide
		}
		catch exception {
			logMessage(kLogCritical, substituteVariables(translate("Cannot start %simulator% SHM Reader ("), {simulator: simulator})
													   . exePath . translate(") - please rebuild the applications in the binaries folder (")
													   . kBinariesDirectory . translate(")"))
				
			showMessage(substituteVariables(translate("Cannot start %simulator% SHM Reader (%exePath%) - please check the configuration...")
										  , {exePath: exePath, simulator: simulator})
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}
	}
	
	activateRF2Window() {
		window := this.Simulator.WindowTitle
		
		if !WinActive(window)
			WinActivate %window%
		
		WinWaitActive %window%, , 2
	}
		
	openPitstopMFD() {
		static reported := false
		
		if !this.iPitstopMFDIsOpen {
			this.activateRF2Window()

			if this.OpenPitstopMFDHotkey {
				SendEvent % this.OpenPitstopMFDHotkey
				
				this.iPitstopMFDIsOpen := true
				
				return true
			}
			else if !reported {
				reported := true
			
				logMessage(kLogCritical, translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration"))
			
				showMessage(translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration...")
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
						  
				return false
			}
		}
		else
			return true
	}
	
	closePitstopMFD() {
		static reported := false
		
		if this.iPitstopMFDIsOpen {
			this.activateRF2Window()

			if this.ClosePitstopMFDHotkey {
				SendEvent % this.ClosePitstopMFDHotkey
			
				this.iPitstopMFDIsOpen := false
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
		this.openPitstopMFD()
		
		return true
	}
	
	selectPitstopOption(option) {
		options := false
		ignore := false
		
		this.getPitstopActions(options, ignore)
		
		return inList(options, option)
	}
	
	changePitstopOption(option, action, steps := 1) {
		switch option {
			case "Refuel":
				this.sendPitstopCommand("Pitstop", action, "Refuel", Round(steps))
			case "Compound":
				this.sendPitstopCommand("Pitstop", action, "Tyre Compound", Round(steps))
			case "All Around":
				this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", Round(steps * 0.1, 1), Round(steps * 0.1, 1), Round(steps * 0.1, 1), Round(steps * 0.1, 1))
			case "Front Left":
				this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", Round(steps * 0.1, 1), 0.0, 0.0, 0.0)
			case "Front Right":
				this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", 0.0, Round(steps * 0.1, 1), 0.0, 0.0)
			case "Rear Left":
				this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", 0.0, 0.0, Round(steps * 0.1, 1), 0.0)
			case "Rear Right":
				this.sendPitstopCommand("Pitstop", action, "Tyre Pressure", 0.0, 0.0, 0.0, Round(steps * 0.1, 1))
			case "Driver", "Repair":
				this.sendPitstopCommand("Pitstop", action, option, Round(steps))
		}
	}
	
	supportsPitstop() {
		return true
	}
	
	startPitstopSetup(pitstopNumber) {
		this.sendPitstopCommand("Setup")
	}

	finishPitstopSetup(pitstopNumber) {
		this.sendPitstopCommand("Setup")
	}
	
	setPitstopRefuelAmount(pitstopNumber, litres) {
		this.sendPitstopCommand("Pitstop", "Set", "Refuel", Round(litres))
	}
	
	setPitstopTyreSet(pitstopNumber, compound, compoundColor := false, set := false) {
		if compound {
			this.sendPitstopCommand("Pitstop", "Set", "Tyre Compound", compound, compoundColor)
			
			if set
				this.sendPitstopCommand("Pitstop", "Set", "Tyre Set", Round(set))
		}
		else
			this.sendPitstopCommand("Pitstop", "Set", "Tyre Compound", "None")
	}

	setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
		this.sendPitstopCommand("Pitstop", "Set", "Tyre Pressure", Round(pressureFL, 1), Round(pressureFR, 1), Round(pressureRL, 1), Round(pressureRR, 1))
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork) {
		if (repairBodywork && repairSuspension)
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Both")
		else if repairSuspension
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Suspension")
		else if repairBodywork
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Bodywork")
		else
			this.sendPitstopCommand("Pitstop", "Set", "Repair", "Nothing")
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                     Function Hook Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

startRF2() {
	return SimulatorController.Instance.startSimulator(SimulatorController.Instance.findPlugin(kRF2Plugin).Simulator, "Simulator Splash Images\RF2 Splash.jpg")
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeRF2Plugin() {
	local controller := SimulatorController.Instance
	
	new RF2Plugin(controller, kRF2Plugin, kRF2Application, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeRF2Plugin()
