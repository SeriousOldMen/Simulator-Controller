;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Race Engineer Plugin            ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\Task.ahk
#Include ..\Plugins\Libraries\RaceAssistantPlugin.ahk
#Include ..\Assistants\Libraries\TyresDatabase.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kRaceEngineerPlugin := "Race Engineer"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RaceEngineerPlugin extends RaceAssistantPlugin  {
	static kLapDataSchemas := {Pressures: ["Lap", "Simulator", "Car", "Track", "Weather", "Temperature.Air", "Temperature.Track"
										 , "Compound", "Compound.Color", "Pressures.Cold", "Pressures.Hot", "Pressures.Losses"]}

	iPitstopPending := false

	iLapDatabase := false

	class DriverSwapTask extends Task {
		iPlugin := false

		iStartTime := false

		Plugin[] {
			Get {
				return this.iPlugin
			}
		}

		__New(plugin) {
			this.iPlugin := plugin

			this.iStartTime := A_TickCount

			base.__New(false, 1000, kLowPriority)
		}

		run() {
			local teamServer := this.Plugin.TeamServer
			local driverSwapPlan, requestDriver

			if (teamServer && teamServer.SessionActive) {
				try {
					driverSwapPlan := teamServer.getSessionValue(this.Plugin.Plugin . " Driver Swap Plan")

					if (driverSwapPlan && (driverSwapPlan != "")) {
						driverSwapPlan := parseConfiguration(driverSwapPlan)

						requestDriver := getConfigurationValue(driverSwapPlan, "Pitstop", "Driver", false)
						requestDriver := (requestDriver ? [requestDriver] : [])

						this.Plugin.RaceEngineer.planDriverSwap(getConfigurationValue(driverSwapPlan, "Pitstop", "Lap", 0)
															  , "!" . getConfigurationValue(driverSwapPlan, "Pitstop", "Refuel", 0)
															  , "!" . getConfigurationValue(driverSwapPlan, "Pitstop", "Tyre.Change", false)
															  , getConfigurationValue(driverSwapPlan, "Pitstop", "Tyre.Set", 0)
															  , getConfigurationValue(driverSwapPlan, "Pitstop", "Tyre.Compound", "Dry")
															  , getConfigurationValue(driverSwapPlan, "Pitstop", "Tyre.Compound.Color", "Black")
															  , getConfigurationValue(driverSwapPlan, "Pitstop", "Tyre.Pressures", "26.1,26.1,26.1,26.1")
															  , getConfigurationValue(driverSwapPlan, "Pitstop", "Repair.Bodywork", false)
															  , getConfigurationValue(driverSwapPlan, "Pitstop", "Repair.Suspension", false)
															  , getConfigurationValue(driverSwapPlan, "Pitstop", "Repair.Engine", false)
															  , requestDriver*)
					}
				}
				catch exception {
					logError(exception)
				}

				if (A_TickCount > (this.iStartTime + 20000)) {
					this.Plugin.RaceEngineer.planDriverSwap(false)

					return false
				}
				else
					return this
			}
			else {
				this.Plugin.RaceEngineer.planDriverSwap(false)

				return false
			}
		}
	}

	class RemoteRaceEngineer extends RaceAssistantPlugin.RemoteRaceAssistant {
		__New(plugin, remotePID) {
			base.__New(plugin, "Race Engineer", remotePID)
		}

		planPitstop(arguments*) {
			this.callRemote("callPlanPitstop", arguments*)
		}

		planDriverSwap(arguments*) {
			this.callRemote("callPlanDriverSwap", arguments*)
		}

		preparePitstop(arguments*) {
			this.callRemote("callPreparePitstop", arguments*)
		}

		pitstopOptionChanged(arguments*) {
			this.callRemote("pitstopOptionChanged", arguments*)
		}
	}

	class RaceEngineerAction extends RaceAssistantPlugin.RaceAssistantAction {
		fireAction(function, trigger) {
			if (this.Plugin.RaceEngineer && (this.Action = "PitstopPlan"))
				this.Plugin.planPitstop()
			if (this.Plugin.RaceEngineer && (this.Action = "DriverSwapPlan"))
				this.Plugin.planDriverSwap()
			else if (this.Plugin.RaceEngineer && (this.Action = "PitstopPrepare"))
				this.Plugin.preparePitstop()
			else
				base.fireAction(function, trigger)
		}
	}

	RaceEngineer[] {
		Get {
			return this.RaceAssistant
		}
	}

	LapDatabase[] {
		Get {
			if !this.iLapDatabase
				this.iLapDatabase := new Database(false, this.kLapDataSchemas)

			return this.iLapDatabase
		}
	}

	PitstopPending[] {
		Get {
			return this.iPitstopPending
		}
	}

	createRaceAssistantAction(controller, action, actionFunction, arguments*) {
		local function, descriptor

		if inList(["PitstopPlan", "DriverSwapPlan", "PitstopPrepare"], action) {
			function := controller.findFunction(actionFunction)

			if (function != false) {
				descriptor := ConfigurationItem.descriptor(action, "Activate")

				action := new this.RaceEngineerAction(this, function, this.getLabel(descriptor, action), this.getIcon(descriptor), action)

				this.registerAction(action)
			}
			else
				this.logFunctionNotFound(actionFunction)
		}
		else
			return base.createRaceAssistantAction(controller, action, actionFunction, arguments*)
	}

	createRaceAssistant(pid) {
		return new this.RemoteRaceEngineer(this, pid)
	}

	prepareSettings(data) {
		local settings := base.prepareSettings(data)
		local tyresDB := new TyresDatabase()
		local simulator := getConfigurationValue(data, "Session Data", "Simulator")
		local car := getConfigurationValue(data, "Session Data", "Car")
		local track := getConfigurationValue(data, "Session Data", "Track")
		local simulatorName := tyresDB.getSimulatorName(simulator)
		local duration := Round((getConfigurationValue(data, "Stint Data", "LapLastTime") - getConfigurationValue(data, "Session Data", "SessionTimeRemaining")) / 1000)
		local weather := getConfigurationValue(data, "Weather Data", "Weather", "Dry")
		local compound := getConfigurationValue(data, "Car Data", "TyreCompound", "Dry")
		local compoundColor := getConfigurationValue(data, "Car Data", "TyreCompoundColor", "Black")
		local tpSetting := getConfigurationValue(this.Configuration, "Race Engineer Startup", simulatorName . ".LoadTyrePressures", "Default")
		local airTemperature, trackTemperature, pressures, certainty

		if ((tpSetting = "TyresDatabase") || (tpSetting = "SetupDatabase")) {
			trackTemperature := getConfigurationValue(data, "Track Data", "Temperature", 23)
			airTemperature := getConfigurationValue(data, "Weather Data", "Temperature", 27)

			compound := false
			compoundColor := false
			pressures := {}
			certainty := 1.0

			if tyresDB.getTyreSetup(simulatorName, car, track, weather, airTemperature, trackTemperature, compound, compoundColor, pressures, certainty, true) {
				setConfigurationValue(settings, "Session Setup", "Tyre.Compound", compound)
				setConfigurationValue(settings, "Session Setup", "Tyre.Compound.Color", compoundColor)

				setConfigurationValue(settings, "Session Setup", "Tyre." . compound . ".Pressure.FL", Round(pressures[1], 1))
				setConfigurationValue(settings, "Session Setup", "Tyre." . compound . ".Pressure.FR", Round(pressures[2], 1))
				setConfigurationValue(settings, "Session Setup", "Tyre." . compound . ".Pressure.RL", Round(pressures[3], 1))
				setConfigurationValue(settings, "Session Setup", "Tyre." . compound . ".Pressure.RR", Round(pressures[4], 1))
			}
		}
		else if (tpSetting = "Import") {
			writeConfiguration(kTempDirectory . "Race Engineer.settings", settings)

			openRaceSettings(true, true, false, kTempDirectory . "Race Engineer.settings")

			settings := readConfiguration(kTempDirectory . "Race Engineer.settings")
		}

		return settings
	}

	startSession(settings, data) {
		base.startSession(settings, data)

		this.iLapDatabase := false
	}

	joinSession(settings, data) {
		if getConfigurationValue(settings, "Assistant.Engineer", "Join.Late", false)
			this.startSession(settings, data)
	}

	checkPitstopPlan() {
		local pitstopSettings, requestDriver

		if (this.TeamSession && this.RaceEngineer) {
			pitstopSettings := this.TeamServer.getSessionValue("Pitstop Plan", false)

			if (pitstopSettings && (pitstopSettings != "")) {
				this.TeamServer.setSessionValue("Pitstop Plan", "")

				pitstopSettings := this.TeamServer.getLapValue(pitstopSettings, "Pitstop Plan")

				if (pitstopSettings && (pitstopSettings != "")) {
					pitstopSettings := parseConfiguration(pitstopSettings)

					requestDriver := getConfigurationValue(pitstopSettings, "Pitstop", "Driver", false)
					requestDriver := (requestDriver ? [requestDriver] : [])

					this.RaceEngineer.planPitstop(getConfigurationValue(pitstopSettings, "Pitstop", "Lap", 0)
												, "!" . getConfigurationValue(pitstopSettings, "Pitstop", "Refuel", 0)
												, "!" . getConfigurationValue(pitstopSettings, "Pitstop", "Tyre.Change", false)
												, getConfigurationValue(pitstopSettings, "Pitstop", "Tyre.Set", 0)
												, getConfigurationValue(pitstopSettings, "Pitstop", "Tyre.Compound", "Dry")
												, getConfigurationValue(pitstopSettings, "Pitstop", "Tyre.Compound.Color", "Black")
												, getConfigurationValue(pitstopSettings, "Pitstop", "Tyre.Pressures", "26.1,26.1,26.1,26.1")
												, getConfigurationValue(pitstopSettings, "Pitstop", "Repair.Bodywork", false)
												, getConfigurationValue(pitstopSettings, "Pitstop", "Repair.Suspension", false)
												, getConfigurationValue(pitstopSettings, "Pitstop", "Repair.Engine", false)
												, requestDriver*)
				}
			}
		}
	}

	addLap(lap, running, data) {
		base.addLap(lap, running, data)

		this.checkPitstopPlan()
	}

	updateLap(lap, running, data) {
		base.updateLap(lap, running, data)

		this.checkPitstopPlan()
	}

	requestInformation(arguments*) {
		if (this.RaceEngineer && inList(["Time", "LapsRemaining", "FuelRemaining", "Weather"
									   , "TyrePressures", "TyrePressuresCold", "TyrePressuresSetup", "TyreTemperatures", "TyreWear"
									   , "BrakeTemperatures", "BrakeWear"], arguments[1])) {
			this.RaceEngineer.requestInformation(arguments*)

			return true
		}
		else
			return false
	}

	planPitstop() {
		if this.RaceEngineer
			this.RaceEngineer.planPitstop()
	}

	planDriverSwap(lap := "__Undefined__") {
		local teamServer

		if this.RaceEngineer {
			if (lap = kUndefined)
				this.RaceEngineer.planDriverSwap()
			else {
				teamServer := this.TeamServer

				if (teamServer && teamServer.SessionActive) {
					teamServer.setSessionValue(this.Plugin . " Driver Swap Plan", "")
					teamServer.setSessionValue(this.Plugin . " Driver Swap Request", lap)

					new this.DriverSwapTask(this).start()
				}
				else
					this.RaceEngineer.planDriverSwap(false)
			}
		}
	}

	preparePitstop(lap := false) {
		if this.RaceEngineer
			this.RaceEngineer.preparePitstop(lap)
	}

	performPitstop(lapNumber) {
		base.performPitstop(lapNumber)

		this.iPitstopPending := false

		RaceAssistantPlugin.CollectorTask.Sleep := 10000
	}

	pitstopOptionChanged(option, values*) {
		if this.RaceEngineer
			this.RaceEngineer.pitstopOptionChanged(option, values*)
	}

	pitstopPlanned(pitstopNumber, plannedLap := false) {
		this.Simulator.pitstopPlanned(pitstopNumber, plannedLap := false)
	}

	pitstopPrepared(pitstopNumber) {
		this.iPitstopPending := true

		this.Simulator.pitstopPrepared(pitstopNumber)

		RaceAssistantPlugin.CollectorTask.Sleep := 5000
	}

	pitstopFinished(pitstopNumber) {
		this.iPitstopPending := false

		this.Simulator.pitstopFinished(pitstopNumber)

		RaceAssistantPlugin.CollectorTask.Sleep := 10000
	}

	updateTyreSet(pitstopNumber, driver, laps, compound, compoundColor, set, flWear, frWear, rlWear, rrWear) {
		local data := newConfiguration()

		setConfigurationValue(data, "Pitstop Data", "Pitstop", pitstopNumber)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Driver", driver)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Laps", laps)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Compound", compound)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Compound.Color", compoundColor)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Set", set)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Wear.Front.Left", flWear)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Wear.Front.Right", frWear)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Wear.Rear.Left", rlWear)
		setConfigurationValue(data, "Pitstop Data", "Tyre.Wear.Rear.Right", rrWear)

		writeConfiguration(kTempDirectory . "Pitstop " . pitstopNumber . ".ini", data)

		this.updatePitstopState(data)
	}

	startPitstopSetup(pitstopNumber) {
		this.Simulator.startPitstopSetup(pitstopNumber)
	}

	finishPitstopSetup(pitstopNumber) {
		this.Simulator.finishPitstopSetup(pitstopNumber)
	}

	setPitstopRefuelAmount(pitstopNumber, liters) {
		this.Simulator.setPitstopRefuelAmount(pitstopNumber, liters)
	}

	setPitstopTyreSet(pitstopNumber, compound, compoundColor, set := false) {
		this.Simulator.setPitstopTyreSet(pitstopNumber, compound, compoundColor, set)
	}

	setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
		this.Simulator.setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR)
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork, repairEngine) {
		this.Simulator.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork, repairEngine)
	}

	requestPitstopDriver(pitstopNumber, driver) {
		this.Simulator.requestPitstopDriver(pitstopNumber, driver)
	}

	updatePitstopState(data) {
		local teamServer := this.TeamServer

		if (teamServer && teamServer.SessionActive) {
			teamServer.setLapValue(this.LastLap, this.Plugin . " Pitstop State", printConfiguration(data))

			teamServer.setSessionValue(this.Plugin . " Pitstop State", this.LastLap)
		}
	}

	savePressureData(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
				   , compound, compoundColor, coldPressures, hotPressures, pressuresLosses) {
		local teamServer := this.TeamServer

		if (teamServer && teamServer.SessionActive)
			teamServer.setLapValue(lapNumber, this.Plugin . " Pressures"
								 , values2String(";", simulator, car, track, weather, airTemperature, trackTemperature, compound, compoundColor
													, coldPressures, hotPressures, pressuresLosses))
		else
			this.LapDatabase.add("Pressures", {Lap: lapNumber, Simulator: simulator, Car: car, Track: track
											 , Weather: weather, "Temperature.Air": airTemperature, "Temperature.Track": trackTemperature
											 , "Compound": compound, "Compound.Color": compoundColor
											 , "Pressures.Cold": coldPressures, "Pressures.Hot": hotPressures, "Pressures.Losses": pressuresLosses})
	}

	updateTyresDatabase() {
		local tyresDB := new TyresDatabase()
		local teamServer := this.TeamServer
		local session := this.TeamSession
		local first := true
		local stint, lastStint, newStint, driverID, lapPressures, ignore, lapData
		local coldPressures, pressureLosses

		try {
			if (teamServer && teamServer.Active && session) {
				lastStint := false
				driverID := kNull

				loop % teamServer.getCurrentLap(session)
					try {
						stint := teamServer.getLapStint(A_Index, session)
						newStint := (stint != lastStint)

						if newStint {
							lastStint := stint

							driverID := teamServer.getStintValue(stint, "ID", session)
						}

						lapPressures := teamServer.getLapValue(A_Index, this.Plugin . " Pressures", session)

						if (!lapPressures || (lapPressures == ""))
							continue

						lapPressures := string2Values(";", lapPressures)

						if (newStint && driverID)
							tyresDB.registerDriver(lapPressures[1], driverID, teamServer.getStintDriverName(stint))

						if first {
							first := false

							tyresDB.lock(lapPressures[1], lapPressures[2], lapPressures[3])
						}

						coldPressures := string2Values(",", lapPressures[9])
						pressureLosses := string2Values(",", lapPressures[11])

						loop 4
							coldPressures[A_Index] -= pressureLosses[A_Index]

						tyresDB.updatePressures(lapPressures[1], lapPressures[2], lapPressures[3], lapPressures[4], lapPressures[5], lapPressures[6]
											  , lapPressures[7], lapPressures[8], coldPressures, string2Values(",", lapPressures[10]), false, driverID)
					}
					catch exception {
						logError(exception)

						break
					}
			}
			else
				try {
					for ignore, lapData in this.LapDatabase.Tables["Pressures"] {
						if first {
							first := false

							tyresDB.lock(lapData.Simulator, lapData.Car, lapData.Track)
						}

						coldPressures := string2Values(",", lapData["Pressures.Cold"])
						pressureLosses := string2Values(",", lapData["Pressures.Losses"])

						loop 4
							coldPressures[A_Index] -= pressureLosses[A_Index]

						tyresDB.updatePressures(lapData.Simulator, lapData.Car, lapData.Track, lapData.Weather
											  , lapData["Temperature.Air"], lapData["Temperature.Track"]
											  , lapData.Compound, lapData["Compound.Color"]
											  , coldPressures, string2Values(",", lapData["Pressures.Hot"]), false)
					}
				}
				catch exception {
					logError(exception)
				}
		}
		finally {
			try {
				tyresDB.unlock()
			}
			catch exception {
				logError(exception)
			}
		}
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                         Controller Action Section                       ;;;
;;;-------------------------------------------------------------------------;;;

planPitstop() {
	local plugin := SimulatorController.Instance.findPlugin(kRaceEngineerPlugin)

	protectionOn()

	try {
		if SimulatorController.Instance.isActive(plugin)
			plugin.planPitstop()
	}
	finally {
		protectionOff()
	}
}

planDriverSwap() {
	local plugin := SimulatorController.Instance.findPlugin(kRaceEngineerPlugin)

	protectionOn()

	try {
		if SimulatorController.Instance.isActive(plugin)
			plugin.planDriverSwap()
	}
	finally {
		protectionOff()
	}
}

preparePitstop() {
	local plugin := SimulatorController.Instance.findPlugin(kRaceEngineerPlugin)

	protectionOn()

	try {
		if SimulatorController.Instance.isActive(plugin)
			plugin.preparePitstop()
	}
	finally {
		protectionOff()
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeRaceEngineerPlugin() {
	local controller := SimulatorController.Instance

	new RaceEngineerPlugin(controller, kRaceEngineerPlugin, controller.Configuration)
}

;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeRaceEngineerPlugin()