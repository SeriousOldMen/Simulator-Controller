;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - RF2 Plugin                      ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Plugins\Libraries\SimulatorPlugin.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kRF2Application = "rFactor 2"

global kRF2Plugin = "RF2"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RF2Plugin extends RaceAssistantSimulatorPlugin {
	iCommandMode := "Event"

	iOpenPitstopMFDHotkey := false
	iClosePitstopMFDHotkey := false

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

		this.iCommandMode := this.getArgumentValue("pitstopMFDMode", "Event")

		this.iOpenPitstopMFDHotkey := this.getArgumentValue("openPitstopMFD", false)
		this.iClosePitstopMFDHotkey := this.getArgumentValue("closePitstopMFD", false)
	}

	getPitstopActions(ByRef allActions, ByRef selectActions) {
		allActions := {Refuel: "Refuel", TyreCompound: "Tyre Compound", TyreAllAround: "All Around"
					 , TyreFrontLeft: "Front Left", TyreFrontRight: "Front Right", TyreRearLeft: "Rear Left", TyreRearRight: "Rear Right"
					 , DriverSelect: "Driver", RepairRequest: "Repair"}
		selectActions := []
	}

	sendPitstopCommand(command, operation := false, message := false, arguments*) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			simulator := this.Code
			arguments := values2String(";", arguments*)

			exePath := kBinariesDirectory . simulator . " SHM Provider.exe"

			try {
				if operation
					RunWait %ComSpec% /c ""%exePath%" -%command% "%operation%:%message%:%arguments%"", , Hide
				else
					RunWait %ComSpec% /c ""%exePath%" -%command%", , Hide
			}
			catch exception {
				logMessage(kLogCritical, substituteVariables(translate("Cannot start %simulator% %protocol% Provider ("), {simulator: simulator, protocol: "SHM"})
														   . exePath . translate(") - please rebuild the applications in the binaries folder (")
														   . kBinariesDirectory . translate(")"))

				showMessage(substituteVariables(translate("Cannot start %simulator% %protocol% Provider (%exePath%) - please check the configuration...")
											  , {exePath: exePath, simulator: simulator, protocol: "SHM"})
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
		}
	}

	activateRF2Window() {
		if (this.OpenPitstopMFDHotkey != "Off") {
			window := this.Simulator.WindowTitle

			if !WinActive(window)
				WinActivate %window%
		}
	}

	sendWindowCommand(command) {
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

		Sleep 20
	}

	openPitstopMFD(descriptor := false) {
		static reported := false

		if this.OpenPitstopMFDHotkey {
			if (this.OpenPitstopMFDHotkey != "Off") {
				this.activateRF2Window()

				this.sendWindowCommand(this.OpenPitstopMFDHotkey)

				return true
			}
			else
				return false
		}
		else if !reported {
			reported := true

			logMessage(kLogCritical, translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration"))

			showMessage(translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)

			return false
		}
	}

	closePitstopMFD() {
		static reported := false

		if this.ClosePitstopMFDHotkey {
			if (this.OpenPitstopMFDHotkey != "Off") {
				this.activateRF2Window()

				this.sendWindowCommand(this.ClosePitstopMFDHotkey)
			}
		}
		else if !reported {
			reported := true

			logMessage(kLogCritical, translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration"))

			showMessage(translate("The hotkeys for opening and closing the Pitstop MFD are undefined - please check the configuration...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}
	}

	requirePitstopMFD() {
		return true
	}

	selectPitstopOption(option) {
		actions := false
		ignore := false

		this.getPitstopActions(actions, ignore)

		for ignore, candidate in actions
			if (candidate = option)
				return true

		return false
	}

	changePitstopOption(option, action, steps := 1) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			switch option {
				case "Refuel":
					this.sendPitstopCommand("Pitstop", action, "Refuel", Round(steps))
				case "Tyre Compound":
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
	}

	supportsPitstop() {
		return true
	}

	supportsSetupImport() {
		return true
	}

	getPitstopOptionValues(option) {
		if (this.OpenPitstopMFDHotkey != "Off") {
			switch option {
				case "Refuel":
					data := readSimulatorData(this.Code, "-Setup")

					return [getConfigurationValue(data, "Setup Data", "FuelAmount", 0)]
				case "Tyre Pressures":
					data := readSimulatorData(this.Code, "-Setup")

					return [getConfigurationValue(data, "Setup Data", "TyrePressureFL", 26.1), getConfigurationValue(data, "Setup Data", "TyrePressureFR", 26.1)
						  , getConfigurationValue(data, "Setup Data", "TyrePressureRL", 26.1), getConfigurationValue(data, "Setup Data", "TyrePressureRR", 26.1)]
				case "Tyre Compound":
					data := readSimulatorData(this.Code, "-Setup")

					return [getConfigurationValue(data, "Setup Data", "TyreCompound", 0), getConfigurationValue(data, "Setup Data", "TyreCompoundColor", 0)]
				case "Repair Suspension":
					data := readSimulatorData(this.Code, "-Setup")

					return [getConfigurationValue(data, "Setup Data", "RepairSuspension", false)]
				case "Repair Bodywork":
					data := readSimulatorData(this.Code, "-Setup")

					return [getConfigurationValue(data, "Setup Data", "RepairBodywork", false)]
				default:
					return base.getPitstopOptionValues(option)
			}
		}
		else
			return false
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

	requestPitstopDriver(pitstopNumber, driver) {
		if driver {
			driver := string2Values("|", driver)

			delta := (string2Values(":", driver[2])[2] - string2Values(":", driver[1])[2])

			Loop % Abs(delta)
				this.changePitstopOption("Driver", (delta < 0) ? "Decrease" : "Increase")
		}
	}

	updatePositionsData(data) {
		base.updatePositionsData(data)

		standings := readSimulatorData(this.Code, "-Standings")

		setConfigurationSectionValues(data, "Position Data", getConfigurationSectionValues(standings, "Position Data"))
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                     Function Hook Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

startRF2() {
	return SimulatorController.Instance.startSimulator(SimulatorController.Instance.findPlugin(kRF2Plugin).Simulator
													 , "Simulator Splash Images\RF2 Splash.jpg")
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
