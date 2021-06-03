;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - AI Race Strategist              ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                        Global Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\RuleEngine.ahk
#Include ..\Assistants\Libraries\RaceAssistant.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RaceStrategist extends RaceAssistant {
	EnoughData[] {
		Get {
			return true
		}
	}
	
	__New(configuration, strategistSettings, name := false, language := "__Undefined__", speaker := false, listener := false, voiceServer := false) {
		base.__New(configuration, "Race Strategist", strategistSettings, name, language, speaker, listener, voiceServer)
	}
	
	createSession(data) {
		local facts
		
		settings := this.Settings
		
		simulator := getConfigurationValue(data, "Session Data", "Simulator", "Unknown")
		simulatorName := this.SetupDatabase.getSimulatorName(simulator)
		
		switch getConfigurationValue(data, "Session Data", "Session", "Practice") {
			case "Practice":
				session := kSessionPractice
			case "Qualification":
				session := kSessionQualification
			case "Race":
				session := kSessionRace
			default:
				session := kSessionOther
		}
		
		this.updateSessionValues({Simulator: simulatorName, Session: session
								, Driver: getConfigurationValue(data, "Stint Data", "DriverForname", this.DriverName)})
		
		lapTime := getConfigurationValue(data, "Stint Data", "LapLastTime", 0)
		
		sessionFormat := getConfigurationValue(data, "Session Data", "SessionFormat", "Time")
		sessionTimeRemaining := getConfigurationValue(data, "Session Data", "SessionTimeRemaining", 0)
		sessionLapsRemaining := getConfigurationValue(data, "Session Data", "SessionLapsRemaining", 0)
		
		dataDuration := Round((sessionTimeRemaining + lapTime) / 1000)
		
		if (sessionFormat = "Time")
			duration := dataDuration
		else {
			settingsDuration := getConfigurationValue(settings, "Session Settings", "Duration", dataDuration)
			
			if ((Abs(settingsDuration - dataDuration) / dataDuration) >  0.05)
				duration := dataDuration
			else
				duration := settingsDuration
		}
		
		facts := {"Session.Simulator": simulator
				, "Session.Car": getConfigurationValue(data, "Session Data", "Car", "")
				, "Session.Track": getConfigurationValue(data, "Session Data", "Track", "")
				, "Session.Duration": duration
				, "Session.Format": sessionFormat
				, "Session.Time.Remaining": sessionTimeRemaining
				, "Session.Lap.Remaining": sessionLapsRemaining
				, "Session.Settings.Lap.Formation": getConfigurationValue(settings, "Session Settings", "Lap.Formation", true)
				, "Session.Settings.Lap.PostRace": getConfigurationValue(settings, "Session Settings", "Lap.PostRace", true)
				, "Session.Settings.Fuel.Max": getConfigurationValue(data, "Session Data", "FuelAmount", 0)
				, "Session.Settings.Fuel.AvgConsumption": getConfigurationValue(settings, "Session Settings", "Fuel.AvgConsumption", 0)
				, "Session.Settings.Pitstop.Delta": getConfigurationValue(settings, "Session Settings", "Pitstop.Delta", 30)
				, "Session.Settings.Fuel.SafetyMargin": getConfigurationValue(settings, "Session Settings", "Fuel.SafetyMargin", 5)
				, "Session.Settings.Lap.AvgTime": getConfigurationValue(settings, "Session Settings", "Lap.AvgTime", 0)
				, "Session.Settings.Lap.History.Considered": getConfigurationValue(kSimulatorConfiguration, "Race Strategist Analysis", simulatorName . ".ConsideredHistoryLaps", 5)
				, "Session.Settings.Lap.History.Damping": getConfigurationValue(kSimulatorConfiguration, "Race Strategist Analysis", simulatorName . ".HistoryLapsDamping", 0.2)}
				
		return facts
	}
	
	updateSession(settings) {
		local knowledgeBase := this.KnowledgeBase
		local facts
		
		if knowledgeBase {
			if !IsObject(settings)
				settings := readConfiguration(settings)
			
			this.updateConfigurationValues({Settings: settings})
			
			simulatorName := this.Simulator
		
			facts := {"Session.Settings.Lap.Formation": getConfigurationValue(settings, "Session Settings", "Lap.Formation", true)
					, "Session.Settings.Lap.PostRace": getConfigurationValue(settings, "Session Settings", "Lap.PostRace", true)
					, "Session.Settings.Fuel.AvgConsumption": getConfigurationValue(settings, "Session Settings", "Fuel.AvgConsumption", 0)
					, "Session.Settings.Pitstop.Delta": getConfigurationValue(settings, "Session Settings", "Pitstop.Delta", 30)
					, "Session.Settings.Lap.AvgTime": getConfigurationValue(settings, "Session Settings", "Lap.AvgTime", 0)
					, "Session.Settings.Fuel.SafetyMargin": getConfigurationValue(settings, "Session Settings", "Fuel.SafetyMargin", 5)
					, "Session.Settings.Lap.History.Considered": getConfigurationValue(kSimulatorConfiguration, "Race Engineer Analysis", simulatorName . ".ConsideredHistoryLaps", 5)
					, "Session.Settings.Lap.History.Damping": getConfigurationValue(kSimulatorConfiguration, "Race Engineer Analysis", simulatorName . ".HistoryLapsDamping", 0.2)}
			
			for key, value in facts
				knowledgeBase.setValue(key, value)
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(knowledgeBase)
		}
	}
	
	startSession(data) {
		if !IsObject(data)
			data := readConfiguration(data)
		
		simulatorName := this.Simulator
		
		this.updateConfigurationValues({})
		
		this.updateDynamicValues({KnowledgeBase: this.createKnowledgeBase(this.createSession(data))})
		
		if this.Speaker
			this.getSpeaker().speak("")
		
		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(this.KnowledgeBase)
	}
	
	finishSession() {
		this.updateDynamicValues({KnowledgeBase: false})
		
		this.updateSessionValues({Simulator: "", Session: kSessionFinished})
	}
	
	addLap(lapNumber, data) {
		local knowledgeBase
		
		static baseLap := false
		
		if !IsObject(data)
			data := readConfiguration(data)
		
		if !this.KnowledgeBase
			this.startSession(data)
		
		knowledgeBase := this.KnowledgeBase
		
		if (lapNumber == 1)
			knowledgeBase.addFact("Lap", 1)
		else
			knowledgeBase.setValue("Lap", lapNumber)
			
		if !this.InitialFuelAmount
			baseLap := lapNumber
		
		this.updateDynamicValues({EnoughData: (lapNumber > (baseLap + (this.LearningLaps - 1)))})
		
		knowledgeBase.setFact("Session.Time.Remaining", getConfigurationValue(data, "Session Data", "SessionTimeRemaining", 0))
		knowledgeBase.setFact("Session.Lap.Remaining", getConfigurationValue(data, "Session Data", "SessionLapsRemaining", 0))
		
		driverForname := getConfigurationValue(data, "Stint Data", "DriverForname", this.DriverName)
		driverSurname := getConfigurationValue(data, "Stint Data", "DriverSurname", "Doe")
		driverNickname := getConfigurationValue(data, "Stint Data", "DriverNickname", "JD")
		
		this.updateSessionValues({Driver: driverForname})
			
		knowledgeBase.addFact("Lap." . lapNumber . ".Driver.Forname", driverForname)
		knowledgeBase.addFact("Lap." . lapNumber . ".Driver.Surname", driverSurname)
		knowledgeBase.addFact("Lap." . lapNumber . ".Driver.Nickname", driverNickname)
		
		knowledgeBase.setFact("Driver.Forname", driverForname)
		knowledgeBase.setFact("Driver.Surname", driverSurname)
		knowledgeBase.setFact("Driver.Nickname", driverNickname)
		
		timeRemaining := getConfigurationValue(data, "Session Data", "SessionTimeRemaining", 0)
		
		knowledgeBase.setFact("Driver.Time.Remaining", getConfigurationValue(data, "Stint Data", "DriverTimeRemaining", timeRemaining))
		knowledgeBase.setFact("Driver.Time.Stint.Remaining", getConfigurationValue(data, "Stint Data", "StintTimeRemaining", timeRemaining))
		
		airTemperature := Round(getConfigurationValue(data, "Weather Data", "Temperature", 0))
		trackTemperature := Round(getConfigurationValue(data, "Track Data", "Temperature", 0))
		
		if (airTemperature = 0)
			airTemperature := Round(getConfigurationValue(data, "Car Data", "AirTemperature", 0))
		
		if (trackTemperature = 0)
			trackTemperature := Round(getConfigurationValue(data, "Car Data", "RoadTemperature", 0))
		
		weatherNow := getConfigurationValue(data, "Weather Data", "Weather", "Dry")
		weather10Min := getConfigurationValue(data, "Weather Data", "Weather10Min", "Dry")
		weather30Min := getConfigurationValue(data, "Weather Data", "Weather30Min", "Dry")
		
		knowledgeBase.setFact("Weather.Temperature.Air", airTemperature)
		knowledgeBase.setFact("Weather.Temperature.Track", trackTemperature)
		knowledgeBase.setFact("Weather.Weather.Now", weatherNow)
		knowledgeBase.setFact("Weather.Weather.10Min", weather10Min)
		knowledgeBase.setFact("Weather.Weather.30Min", weather30Min)
		
		lapTime := getConfigurationValue(data, "Stint Data", "LapLastTime", 0)
		
		if ((lapNumber <= 2) && knowledgeBase.getValue("Session.Settings.Lap.Time.Adjust", false)) {
			settingsLapTime := (getConfigurationValue(this.Settings, "Session Settings", "Lap.AvgTime", lapTime / 1000) * 1000)
			
			if ((lapTime / settingsLapTime) > 2)
				lapTime := settingsLapTime
		}
		
		if (this.iLapTime = 0)
			this.iLapTime := lapTime
		else
			this.iLapTime := Min(this.iLapTime, lapTime)
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Time", lapTime)
		knowledgeBase.addFact("Lap." . lapNumber . ".Time.Start", this.OverallTime)
		
		overallTime := (this.OverallTime + lapTime)
		
		this.updateDynamicValues({OverallTime: overallTime})
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Time.End", overallTime)
		
		fuelRemaining := getConfigurationValue(data, "Car Data", "FuelRemaining", 0)
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.Remaining", Round(fuelRemaining, 2))
		
		if (lapNumber == 1) {
			this.updateDynamicValues({LastFuelAmount: fuelRemaining, InitialFuelAmount: fuelRemaining, AvgFuelConsumption: 0})
			
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.AvgConsumption", 0)
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.Consumption", 0)
		}
		else if (!this.InitialFuelAmount || (fuelRemaining > this.LastFuelAmount)) {
			; This is the case after a pitstop
			this.updateDynamicValues({LastFuelAmount: fuelRemaining, InitialFuelAmount: fuelRemaining, AvgFuelConsumption: 0})
			
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.AvgConsumption", knowledgeBase.getValue("Lap." . (lapNumber - 1) . ".Fuel.AvgConsumption", 0))
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.Consumption", knowledgeBase.getValue("Lap." . (lapNumber - 1) . ".Fuel.Consumption", 0))
		}
		else {
			avgFuelConsumption := Round((this.InitialFuelAmount - fuelRemaining) / (lapNumber - baseLap), 2)
			
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.AvgConsumption", avgFuelConsumption)
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.Consumption", Round(this.LastFuelAmount - fuelRemaining, 2))
			
			this.updateDynamicValues({LastFuelAmount: fuelRemaining, AvgFuelConsumption: avgFuelConsumption})
		}
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Weather", weatherNow)
		knowledgeBase.addFact("Lap." . lapNumber . ".Grip", getConfigurationValue(data, "Track Data", "Grip", "Green"))
		knowledgeBase.addFact("Lap." . lapNumber . ".Temperature.Air", airTemperature)
		knowledgeBase.addFact("Lap." . lapNumber . ".Temperature.Track", trackTemperature)
		
		result := knowledgeBase.produce()
		
		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(this.KnowledgeBase)
		
		return result
	}
}