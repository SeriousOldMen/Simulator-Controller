;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - AI Race Strategist              ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
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
	iRaceInfo := false

	iStrategy := false
	iStrategyReported := false

	iSaveTelemetry := kAlways
	iSaveRaceReport := false
	iRaceReview := false

	iHasTelemetryData := false

	iFirstStandingsLap := true

	iSessionReportsDatabase := false
	iSessionDataActive := false

	class RaceStrategistRemoteHandler extends RaceAssistant.RaceAssistantRemoteHandler {
		__New(remotePID) {
			base.__New("Race Strategist", remotePID)
		}

		saveStandingsData(arguments*) {
			this.callRemote("saveStandingsData", arguments*)
		}

		saveTelemetryData(arguments*) {
			this.callRemote("saveTelemetryData", arguments*)
		}

		updateTelemetryDatabase(arguments*) {
			this.callRemote("updateTelemetryDatabase", arguments*)
		}

		saveRaceInfo(arguments*) {
			this.callRemote("saveRaceInfo", arguments*)
		}

		saveRaceLap(arguments*) {
			this.callRemote("saveRaceLap", arguments*)
		}

		createRaceReport(arguments*) {
			this.callRemote("createRaceReport", arguments*)
		}

		reviewRace(arguments*) {
			this.callRemote("reviewRace", arguments*)
		}
	}

	class RaceReviewContinuation extends VoiceManager.VoiceContinuation {
	}

	RaceInfo[] {
		Get {
			return this.iRaceInfo
		}
	}

	Strategy[] {
		Get {
			return this.iStrategy
		}
	}

	StrategyReported[] {
		Get {
			return this.iStrategyReported
		}
	}

	SaveTelemetry[] {
		Get {
			return this.iSaveTelemetry
		}
	}

	SaveRaceReport[] {
		Get {
			return ((this.iSessionReportsDatabase != false) ? this.iSaveRaceReport : kNever)
		}
	}

	RaceReview[] {
		Get {
			return this.iRaceReview
		}
	}

	HasTelemetryData[] {
		Get {
			return this.iHasTelemetryData
		}
	}

	SessionReportsDatabase[] {
		Get {
			return this.iSessionReportsDatabase
		}
	}

	SessionDataActive[] {
		Get {
			return this.iSessionDataActive
		}
	}

	__New(configuration, remoteHandler, name := false, language := "__Undefined__"
		, synthesizer := false, speaker := false, vocalics := false, recognizer := false, listener := false, voiceServer := false) {
		base.__New(configuration, "Race Strategist", remoteHandler, name, language, synthesizer, speaker, vocalics, recognizer, listener, voiceServer)

		this.updateConfigurationValues({Announcements: {WeatherUpdate: true}})
	}

	updateConfigurationValues(values) {
		base.updateConfigurationValues(values)

		if values.HasKey("SessionReportsDatabase")
			this.iSessionReportsDatabase := values["SessionReportsDatabase"]

		if values.HasKey("SaveTelemetry")
			this.iSaveTelemetry := values["SaveTelemetry"]

		if values.HasKey("SaveRaceReport")
			this.iSaveRaceReport := values["SaveRaceReport"]

		if values.HasKey("RaceReview")
			this.iRaceReview := values["RaceReview"]
	}

	updateSessionValues(values) {
		base.updateSessionValues(values)

		if values.HasKey("Strategy")
			this.iStrategy := values["Strategy"]

		if values.HasKey("RaceInfo")
			this.iRaceInfo := values["RaceInfo"]
	}

	updateDynamicValues(values) {
		base.updateDynamicValues(values)

		if values.HasKey("HasTelemetryData")
			this.iHasTelemetryData := values["HasTelemetryData"]

		if values.HasKey("StrategyReported")
			this.iStrategyReported := values["StrategyReported"]
	}

	hasEnoughData(inform := true) {
		if !inform
			return base.hasEnoughData(false)
		else if (this.Session == kSessionRace)
			return base.hasEnoughData(inform)
		else {
			if this.Speaker
				this.getSpeaker().speakPhrase("CollectingData")

			return false
		}
	}

	handleVoiceCommand(grammar, words) {
		switch grammar {
			case "LapsRemaining":
				this.lapsRemainingRecognized(words)
			case "Weather":
				this.weatherRecognized(words)
			case "Position":
				this.positionRecognized(words)
			case "LapTimes":
				this.lapTimesRecognized(words)
			case "FuturePosition":
				this.futurePositionRecognized(words)
			case "GapToAhead", "GapToFront":
				this.gapToAheadRecognized(words)
			case "GapToBehind":
				this.gapToBehindRecognized(words)
			case "GapToLeader":
				this.gapToLeaderRecognized(words)
			case "StrategyOverview":
				this.strategyOverviewRecognized(words)
			case "CancelStrategy":
				this.cancelStrategyRecognized(words)
			case "NextPitstop":
				this.nextPitstopRecognized(words)
			case "PitstopRecommend":
				this.clearContinuation()

				this.getSpeaker().speakPhrase("Confirm")

				sendMessage()

				Loop 10
					Sleep 500

				this.recommendPitstopRecognized(words)
			case "PitstopSimulate":
				this.clearContinuation()

				this.getSpeaker().speakPhrase("Confirm")

				sendMessage()

				Loop 10
					Sleep 500

				this.simulatePitstopRecognized(words)
			default:
				base.handleVoiceCommand(grammar, words)
		}
	}

	lapsRemainingRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if !this.hasEnoughData()
			return

		laps := Round(knowledgeBase.getValue("Lap.Remaining.Fuel", 0))

		if (laps == 0)
			this.getSpeaker().speakPhrase("Later")
		else
			this.getSpeaker().speakPhrase("Laps", {laps: laps})
	}

	weatherRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		weather10Min := (knowledgeBase ? knowledgeBase.getValue("Weather.Weather.10Min", false) : false)

		if !weather10Min
			this.getSpeaker().speakPhrase("Later")
		else if (weather10Min = "Dry")
			this.getSpeaker().speakPhrase("WeatherGood")
		else
			this.getSpeaker().speakPhrase("WeatherRain")
	}

	positionRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if ((this.Session != kSessionRace) && !this.hasEnoughData())
			return

		speaker := this.getSpeaker()
		position := Round(knowledgeBase.getValue("Position", 0))

		if (position == 0)
			speaker.speakPhrase("Later")
		else if inList(words, speaker.Fragments["Laps"])
			this.futurePositionRecognized(words)
		else {
			speaker.startTalk()

			try {
				speaker.speakPhrase("Position", {position: position})

				if (position <= 3)
					speaker.speakPhrase("Great")
			}
			finally {
				speaker.finishTalk()
			}
		}
	}

	futurePositionRecognized(words) {
		local knowledgeBase = this.KnowledgeBase
		local action

		if !this.hasEnoughData()
			return

		speaker := this.getSpeaker()
		fragments := speaker.Fragments

		lapPosition := inList(words, fragments["Laps"])

		if lapPosition {
			lapDelta := words[lapPosition - 1]

			if this.isNumber(lapDelta, lapDelta) {
				currentLap := knowledgeBase.getValue("Lap")
				lap := (currentLap + lapDelta)

				if (lap <= currentLap)
					speaker.speakPhrase("NoFutureLap")
				else {
					car := knowledgeBase.getValue("Driver.Car")

					speaker.speakPhrase("Confirm")

					sendMessage()

					Loop 10
						Sleep 500

					knowledgeBase.setFact("Standings.Extrapolate", lap)

					knowledgeBase.produce()

					if this.Debug[kDebugKnowledgeBase]
						this.dumpKnowledge(this.KnowledgeBase)

					position := knowledgeBase.getValue("Standings.Extrapolated." . lap . ".Car." . car . ".Position", false)

					if position
						speaker.speakPhrase("FuturePosition", {position: position})
					else
						speaker.speakPhrase("NoFuturePosition")
				}

				return
			}
		}

		speaker.speakPhrase("Repeat")
	}

	gapToAheadRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if !this.hasEnoughData()
			return

		if inList(words, this.getSpeaker().Fragments["Car"])
			this.trackGapToAheadRecognized(words)
		else
			this.standingsGapToAheadRecognized(words)
	}

	trackGapToAheadRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		speaker := this.getSpeaker()

		delta := Abs(knowledgeBase.getValue("Position.Track.Ahead.Delta", 0))

		if (delta != 0) {
			speaker.startTalk()

			try {
				speaker.speakPhrase("TrackGapToAhead", {delta: printNumber(delta / 1000, 1)})

				lap := knowledgeBase.getValue("Lap")
				driverLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Driver.Car") . ".Laps"))
				otherLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Position.Track.Ahead.Car") . ".Laps"))

				if (driverLap < otherLap)
				  speaker.speakPhrase("NotTheSameLap")
			}
			finally {
				speaker.finishTalk()
			}
		}
		else
			speaker.speakPhrase("NoTrackGap")
	}

	standingsGapToAheadRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if (Round(knowledgeBase.getValue("Position", 0)) = 1)
			this.getSpeaker().speakPhrase("NoGapToAhead")
		else {
			delta := Abs(knowledgeBase.getValue("Position.Standings.Ahead.Delta", 0) / 1000)

			this.getSpeaker().speakPhrase("StandingsGapToAhead", {delta: printNumber(delta, 1)})
		}
	}

	gapToBehindRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if !this.hasEnoughData()
			return

		if inList(words, this.getSpeaker().Fragments["Car"])
			this.trackGapToBehindRecognized(words)
		else
			this.standingsGapToBehindRecognized(words)
	}

	trackGapToBehindRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		speaker := this.getSpeaker()

		delta := Abs(knowledgeBase.getValue("Position.Track.Behind.Delta", 0))

		if (delta != 0) {
			speaker.startTalk()

			try {
				speaker.speakPhrase("TrackGapToBehind", {delta: printNumber(delta / 1000, 1)})

				lap := knowledgeBase.getValue("Lap")
				driverLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Driver.Car") . ".Laps"))
				otherLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Position.Track.Behind.Car") . ".Laps"))

				if (driverLap > (otherLap + 1))
				  speaker.speakPhrase("NotTheSameLap")
			}
			finally {
				speaker.finishTalk()
			}
		}
		else
			speaker.speakPhrase("NoTrackGap")
	}

	standingsGapToBehindRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if (Round(knowledgeBase.getValue("Position", 0)) = Round(knowledgeBase.getValue("Car.Count", 0)))
			this.getSpeaker().speakPhrase("NoGapToBehind")
		else {
			delta := Abs(knowledgeBase.getValue("Position.Standings.Behind.Delta", 0) / 1000)

			this.getSpeaker().speakPhrase("StandingsGapToBehind", {delta: printNumber(delta, 1)})
		}
	}

	gapToLeaderRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if !this.hasEnoughData()
			return

		if (Round(knowledgeBase.getValue("Position", 0)) = 1)
			this.getSpeaker().speakPhrase("NoGapToAhead")
		else {
			delta := Abs(knowledgeBase.getValue("Position.Standings.Leader.Delta", 0) / 1000)

			this.getSpeaker().speakPhrase("GapToLeader", {delta: printNumber(delta, 1)})
		}
	}

	reportLapTime(phrase, driverLapTime, car) {
		lapTime := this.KnowledgeBase.getValue("Car." . car . ".Time", false)

		if !this.hasEnoughData()
			return

		if lapTime {
			lapTime /= 1000

			speaker := this.getSpeaker()
			fragments := speaker.Fragments

			minute := Floor(lapTime / 60)
			seconds := (lapTime - (minute * 60))

			speaker.speakPhrase(phrase, {time: printNumber(lapTime, 1), minute: minute, seconds: printNumber(seconds, 1)})

			delta := (driverLapTime - lapTime)

			if (Abs(delta) > 0.5)
				this.getSpeaker().speakPhrase("LapTimeDelta", {delta: printNumber(Abs(delta), 1)
															 , difference: (delta > 0) ? fragments["Faster"] : fragments["Slower"]})
		}
	}

	lapTimesRecognized(words) {
		local knowledgeBase := this.KnowledgeBase

		if !this.hasEnoughData()
			return

		car := knowledgeBase.getValue("Driver.Car")
		lap := knowledgeBase.getValue("Lap", 0)
		position := Round(knowledgeBase.getValue("Position"))
		cars := Round(knowledgeBase.getValue("Car.Count"))

		driverLapTime := (knowledgeBase.getValue("Car." . car . ".Time") / 1000)

		if (lap == 0)
			this.getSpeaker().speakPhrase("Later")
		else {
			speaker := this.getSpeaker()

			speaker.startTalk()

			try {
				minute := Floor(driverLapTime / 60)
				seconds := (driverLapTime - (minute * 60))

				speaker.speakPhrase("LapTime", {time: printNumber(driverLapTime, 1), minute: minute, seconds: printNumber(seconds, 1)})

				if (position > 2)
					this.reportLapTime("LapTimeFront", driverLapTime, knowledgeBase.getValue("Position.Standings.Ahead.Car", 0))

				if (position < cars)
					this.reportLapTime("LapTimeBehind", driverLapTime, knowledgeBase.getValue("Position.Standings.Behind.Car", 0))

				if (position > 1)
					this.reportLapTime("LapTimeLeader", driverLapTime, knowledgeBase.getValue("Position.Standings.Leader.Car", 0))
			}
			finally {
				speaker.finishTalk()
			}
		}
	}

	strategyOverviewRecognized(words) {
		if !this.hasEnoughData()
			return

		this.reportStrategy()
	}

	cancelStrategyRecognized(words) {
		if !this.hasEnoughData()
			return

		this.cancelStrategy()
	}

	nextPitstopRecognized(words) {
		if !this.hasEnoughData()
			return

		this.reportStrategy({NextPitstop: true})
	}

	recommendPitstopRecognized(words) {
		if !this.hasEnoughData()
			return

		this.pitstopLapRecognized(words)
	}

	simulatePitstopRecognized(words) {
		if !this.hasEnoughData()
			return

		this.pitstopLapRecognized(words, true)
	}

	pitstopLapRecognized(words, lap := false) {
		if lap {
			lapPosition := inList(words, this.getSpeaker().Fragments["Lap"])

			if lapPosition {
				lap := words[lapPosition + 1]

				if !this.isNumber(lap, lap)
					lap := false
			}
			else
				lap := false
		}

		this.recommendPitstop(lap)
	}

	reviewRace(cars, laps, position, leaderAvgLapTime
			 , driverAvgLapTime, driverMinLapTime, driverMaxLapTime, driverLapTimeStdDev) {
		local knowledgeBase := this.KnowledgeBase

		if ((this.Session = kSessionRace) && this.hasEnoughData(false) && (position != 0)) {
			speaker := this.getSpeaker()

			speaker.startTalk()

			try {
				if (position <= (cars / 5))
					speaker.speakPhrase("GreatRace", {position: position})
				else if (position <= ((cars / 5) * 3))
					speaker.speakPhrase("MediocreRace", {position: position})
				else
					speaker.speakPhrase("CatastrophicRace", {position: position})

				if (position > 1) {
					only := ""

					if (driverAvgLapTime < (leaderAvgLapTime * 1.01))
						only := speaker.Fragments["Only"]

					speaker.speakPhrase("Compare2Leader", {relative: only, seconds: printNumber(Abs(driverAvgLapTime - leaderAvgLapTime), 1)})

					driver := knowledgeBase.getValue("Driver.Car")

					if (((laps - knowledgeBase.getValue("Car." . driver . ".Valid.Laps", laps)) > (laps * 0.08))
					 || (knowledgeBase.getValue("Car." . driver . ".Incidents", 0) > (laps * 0.08)))
						speaker.speakPhrase("InvalidCritics", {conjunction: speaker.Fragments[(only != "") ? "But" : "And"]})

					if (position <= (cars / 3))
						speaker.speakPhrase("PositiveSummary")

					if (driverMinLapTime && driverLapTimeStdDev) {
						goodPace := false

						if (driverMinLapTime <= (leaderAvgLapTime * 1.005)) {
							speaker.speakPhrase("GoodPace")

							goodPace := true
						}
						else if (driverMinLapTime <= (leaderAvgLapTime * 1.01))
							speaker.speakPhrase("MediocrePace")
						else
							speaker.speakPhrase("BadPace")

						if (driverLapTimeStdDev < (driverAvgLapTime * 0.004))
							speaker.speakPhrase("GoodConsistency", {conjunction: speaker.Fragments[goodPace ? "And" : "But"]})
						else if (driverLapTimeStdDev < (driverAvgLapTime * 0.008))
							speaker.speakPhrase("MediocreConsistency", {conjunction: speaker.Fragments[goodPace ? "But" : "And"]})
						else
							speaker.speakPhrase("BadConsistency", {conjunction: speaker.Fragments[goodPace ? "But" : "And"]})
					}
				}
			}
			finally {
				speaker.finishTalk()
			}
		}

		continuation := this.Continuation

		if isInstance(continuation, this.RaceReviewContinuation) {
			this.clearContinuation()

			continuation.continue()
		}
	}

	collectTelemetryData() {
		session := "Other"
		default := false

		switch this.Session {
			case kSessionPractice:
				session := "Practice"
				default := true
			case kSessionQualification:
				session := "Qualification"
			case kSessionRace:
				session := "Race"
				default := true
		}

		return getConfigurationValue(this.Settings, "Session Settings", "Telemetry." . session, default)
	}

	createStrategy(facts, strategy, lap := false) {
		facts["Strategy.Name"] := getConfigurationValue(strategy, "General", "Name")

		facts["Strategy.Weather"] := getConfigurationValue(strategy, "Weather", "Weather")
		facts["Strategy.Weather.Temperature.Air"] := getConfigurationValue(strategy, "Weather", "AirTemperature")
		facts["Strategy.Weather.Temperature.Track"] := getConfigurationValue(strategy, "Weather", "TrackTemperature")

		facts["Strategy.Tyre.Compound"] := getConfigurationValue(strategy, "Setup", "TyreCompound")
		facts["Strategy.Tyre.Compound.Color"] := getConfigurationValue(strategy, "Setup", "TyreCompoundColor")

		facts["Strategy.Map"] := getConfigurationValue(strategy, "Setup", "Map")
		facts["Strategy.TC"] := getConfigurationValue(strategy, "Setup", "TC")
		facts["Strategy.ABS"] := getConfigurationValue(strategy, "Setup", "ABS")

		pitstops := string2Values(", ", getConfigurationValue(strategy, "Strategy", "Pitstops", ""))

		first := true
		count := 0

		for ignore, pitstopLap in pitstops {
			if (lap && (pitstopLap < lap))
				continue

			count += 1

			if first {
				first := false

				facts["Strategy.Pitstop.Next"] := 1
				facts["Strategy.Pitstop.Lap"] := pitstopLap
			}

			facts["Strategy.Pitstop." . A_Index . ".Lap"] := pitstopLap
			facts["Strategy.Pitstop." . A_Index . ".Fuel.Amount"] := getConfigurationValue(strategy, "Pitstop", "RefuelAmount." . pitstopLap)
			facts["Strategy.Pitstop." . A_Index . ".Tyre.Change"] := getConfigurationValue(strategy, "Pitstop", "TyreChange." . pitstopLap)
			facts["Strategy.Pitstop." . A_Index . ".Map"] := getConfigurationValue(strategy, "Pitstop", "Map." . pitstopLap, "n/a")
		}

		facts["Strategy.Pitstop.Count"] := count
	}

	prepareSession(settings, data) {
		this.updateSessionValues({RaceInfo: false})

		base.prepareSession(settings, data)

		raceData := newConfiguration()

		carCount := getConfigurationValue(data, "Position Data", "Car.Count")

		setConfigurationValue(raceData, "Cars", "Count", carCount)
		setConfigurationValue(raceData, "Cars", "Driver", getConfigurationValue(data, "Position Data", "Driver.Car"))

		Loop %carCount% {
			setConfigurationValue(raceData, "Cars", "Car." . A_Index . ".Nr", getConfigurationValue(data, "Position Data", "Car." . A_Index . ".Nr"))
			setConfigurationValue(raceData, "Cars", "Car." . A_Index . ".Position", getConfigurationValue(data, "Position Data", "Car." . A_Index . ".Position"))
		}

		this.updateRaceInfo(raceData)
	}

	createSession(settings, data) {
		local facts := base.createSession(settings, data)

		simulatorName := this.SettingsDatabase.getSimulatorName(facts["Session.Simulator"])

		if ((this.Session == kSessionRace) && FileExist(kUserConfigDirectory . "Race.strategy")) {
			strategy := readConfiguration(kUserConfigDirectory . "Race.strategy")

			applicableStrategy := false

			simulator := getConfigurationValue(strategy, "Session", "Simulator")
			car := getConfigurationValue(strategy, "Session", "Car")
			track := getConfigurationValue(strategy, "Session", "Track")

			if ((simulator = simulatorName) && (car = facts["Session.Car"]) && (track = facts["Session.Track"]))
				applicableStrategy := true

			if applicableStrategy {
				sessionType := getConfigurationValue(strategy, "Session", "SessionType")
				sessionLength := getConfigurationValue(strategy, "Session", "SessionLength")

				if ((sessionType = "Duration") && (facts["Session.Format"] = "Time")) {
					duration := (facts["Session.Duration"] / 60)

					if ((Abs(sessionLength - duration) / duration) >  0.05)
						applicableStrategy := false
				}
				else if ((sessionType = "Laps") && (facts["Session.Format"] = "Lap")) {
					laps := facts["Session.Laps"]

					if ((Abs(sessionLength - laps) / laps) >  0.05)
						applicableStrategy := false
				}

				if applicableStrategy {
					this.createStrategy(facts, strategy)

					this.updateSessionValues({Strategy: strategy})
				}
			}
		}

		configuration := this.Configuration
		settings := this.Settings

		facts["Session.Settings.Pitstop.Delta"] := getConfigurationValue(settings, "Strategy Settings", "Pitstop.Delta", getConfigurationValue(settings, "Session Settings", "Pitstop.Delta", 30))
		facts["Session.Settings.Lap.Learning.Laps"] := getConfigurationValue(configuration, "Race Strategist Analysis", simulatorName . ".LearningLaps", 1)
		facts["Session.Settings.Lap.History.Considered"] := getConfigurationValue(configuration, "Race Strategist Analysis", simulatorName . ".ConsideredHistoryLaps", 5)
		facts["Session.Settings.Lap.History.Damping"] := getConfigurationValue(configuration, "Race Strategist Analysis", simulatorName . ".HistoryLapsDamping", 0.2)
		facts["Session.Settings.Standings.Extrapolation.Laps"] := getConfigurationValue(settings, "Strategy Settings", "Extrapolation.Laps", 2)
		facts["Session.Settings.Standings.Extrapolation.Overtake.Delta"] := Round(getConfigurationValue(settings, "Strategy Settings", "Overtake.Delta", 1) * 1000)
		facts["Session.Settings.Strategy.Traffic.Considered"] := getConfigurationValue(settings, "Strategy Settings", "Traffic.Considered", 5) / 100
		facts["Session.Settings.Pitstop.Service.Refuel"] := getConfigurationValue(settings, "Strategy Settings", "Service.Refuel", 1.5)
		facts["Session.Settings.Pitstop.Service.Order"] := getConfigurationValue(settings, "Strategy Settings", "Service.Order", "Simultaneous")
		facts["Session.Settings.Pitstop.Service.Tyres"] := getConfigurationValue(settings, "Strategy Settings", "Service.Tyres", 30)
		facts["Session.Settings.Pitstop.Strategy.Window.Considered"] := getConfigurationValue(settings, "Strategy Settings", "Strategy.Window.Considered", 2)

		return facts
	}

	updateSession(settings) {
		local knowledgeBase := this.KnowledgeBase
		local facts

		if knowledgeBase {
			if !IsObject(settings)
				settings := readConfiguration(settings)

			facts := {"Session.Settings.Pitstop.Delta": getConfigurationValue(settings, "Strategy Settings", "Pitstop.Delta", getConfigurationValue(settings, "Session Settings", "Pitstop.Delta", 30))
					, "Session.Settings.Standings.Extrapolation.Laps": getConfigurationValue(settings, "Strategy Settings", "Extrapolation.Laps", 2)
					, "Session.Settings.Standings.Extrapolation.Overtake.Delta": Round(getConfigurationValue(settings, "Strategy Settings", "Overtake.Delta", 1) * 1000)
					, "Session.Settings.Strategy.Traffic.Considered": getConfigurationValue(settings, "Strategy Settings", "Traffic.Considered", 5) / 100
					, "Session.Settings.Pitstop.Service.Refuel": getConfigurationValue(settings, "Strategy Settings", "Service.Refuel", 1.5)
					, "Session.Settings.Pitstop.Service.Tyres": getConfigurationValue(settings, "Strategy Settings", "Service.Tyres", 30)
					, "Session.Settings.Pitstop.Service.Order": getConfigurationValue(settings, "Strategy Settings", "Service.Order", "Simultaneous")
					, "Session.Settings.Pitstop.Strategy.Window.Considered": getConfigurationValue(settings, "Strategy Settings", "Strategy.Window.Considered", 2)}

			for key, value in facts
				knowledgeBase.setFact(key, value)

			base.updateSession(settings)
		}
	}

	startSession(settings, data) {
		local facts

		if !IsObject(settings)
			settings := readConfiguration(settings)

		if !IsObject(data)
			data := readConfiguration(data)

		facts := this.createSession(settings, data)

		simulatorName := this.Simulator
		configuration := this.Configuration

		Process Exist, Race Engineer.exe

		raceEngineer := (ErrorLevel > 0)

		if raceEngineer
			saveSettings := kNever
		else {
			deprecated := getConfigurationValue(configuration, "Race Engineer Shutdown", simulatorName . ".SaveSettings", kNever)
			saveSettings := getConfigurationValue(configuration, "Race Assistant Shutdown", simulatorName . ".SaveSettings", deprecated)
		}

		this.iFirstStandingsLap := (getConfigurationValue(data, "Stint Data", "Laps", 0) == 1)

		this.updateConfigurationValues({LearningLaps: getConfigurationValue(configuration, "Race Strategist Analysis", simulatorName . ".LearningLaps", 1)
									  , SessionReportsDatabase: getConfigurationValue(configuration, "Race Strategist Reports", "Database", false)
									  , SaveTelemetry: getConfigurationValue(configuration, "Race Strategist Shutdown", simulatorName . ".SaveTelemetry", kAlways)
									  , SaveRaceReport: getConfigurationValue(configuration, "Race Strategist Shutdown", simulatorName . ".SaveRaceReport", false)
									  , RaceReview: (getConfigurationValue(configuration, "Race Strategist Shutdown", simulatorName . ".RaceReview", "Yes") = "Yes")
									  , SaveSettings: saveSettings})

		this.updateDynamicValues({KnowledgeBase: this.createKnowledgeBase(facts), HasTelemetryData: false
							    , BestLapTime: 0, OverallTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0
								, EnoughData: false, StrategyReported: false})

		if this.Speaker
			this.getSpeaker().speakPhrase(raceEngineer ? "" : "Greeting")

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(this.KnowledgeBase)
	}

	finishSession(shutdown := true, review := true) {
		local knowledgeBase := this.KnowledgeBase

		if knowledgeBase {
			lastLap := knowledgeBase.getValue("Lap", 0)

			if (shutdown && review && this.RaceReview && (this.Session = kSessionRace)
						 && (lastLap > this.LearningLaps)) {
				this.finishSessionWithReview(shutdown)

				return
			}
			else
				review := false

			Process Exist, Race Engineer.exe

			if (shutdown && !review && !ErrorLevel && this.Speaker)
				this.getSpeaker().speakPhrase("Bye")

			if (shutdown && (lastLap > this.LearningLaps)) {
				this.shutdownSession("Before")

				if this.Listener {
					asked := true

					if ((((this.SaveSettings == kAsk) && (this.Session == kSessionRace))
					  || (this.collectTelemetryData() && (this.SaveTelemetry == kAsk) && this.HasTelemetryData))
					 && ((this.SaveRaceReport == kAsk) && (this.Session == kSessionRace)))
						this.getSpeaker().speakPhrase("ConfirmSaveSettingsAndRaceReport", false, true)
					else if ((this.SaveRaceReport == kAsk) && (this.Session == kSessionRace))
						this.getSpeaker().speakPhrase("ConfirmSaveRaceReport", false, true)
					else if (((this.SaveSettings == kAsk) && (this.Session == kSessionRace))
						  || (this.collectTelemetryData() && (this.SaveTelemetry == kAsk) && this.HasTelemetryData))
						this.getSpeaker().speakPhrase("ConfirmSaveSettings", false, true)
					else
						asked := false
				}
				else
					asked := false

				if asked {
					this.setContinuation(ObjBindMethod(this, "shutdownSession", "After"))

					callback := ObjBindMethod(this, "forceFinishSession")

					SetTimer %callback%, -120000

					return
				}
			}

			this.updateDynamicValues({KnowledgeBase: false})
		}

		this.updateDynamicValues({OverallTime: 0, BestLapTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false
								, StrategyReported: false, HasTelemetryData: false})
		this.updateSessionValues({Simulator: "", Session: kSessionFinished, Strategy: false, SessionTime: false})
	}

	forceFinishSession() {
		if !this.SessionDataActive {
			this.updateDynamicValues({KnowledgeBase: false})

			this.finishSession()
		}
		else {
			callback := ObjBindMethod(this, "forceFinishSession")

			SetTimer %callback%, -5000
		}
	}

	finishSessionWithReview(shutdown) {
		if this.RemoteHandler {
			this.RemoteHandler.reviewRace()

			this.setContinuation(new this.RaceReviewContinuation(this, ObjBindMethod(this, "finishSession", shutdown, false)))
		}
		else
			this.finishSession(shutdown, false)
	}

	shutdownSession(phase) {
		this.iSessionDataActive := true

		try {
			if (((phase = "After") && (this.SaveSettings = kAsk)) || ((phase = "Before") && (this.SaveSettings = kAlways)))
				if (this.Session == kSessionRace)
					this.saveSessionSettings()

			if (((phase = "After") && (this.SaveRaceReport = kAsk)) || ((phase = "Before") && (this.SaveRaceReport = kAlways)))
				if (this.Session == kSessionRace)
					this.createRaceReport()

			if (((phase = "After") && (this.SaveTelemetry = kAsk)) || ((phase = "Before") && (this.SaveTelemetry = kAlways)))
				if (this.HasTelemetryData && this.collectTelemetryData())
					this.updateTelemetryDatabase()
		}
		finally {
			this.iSessionDataActive := false
		}

		if (phase = "After") {
			if this.Speaker
				this.getSpeaker().speakPhrase("RaceReportSaved")

			this.updateDynamicValues({KnowledgeBase: false, HasTelemetryData: false})

			this.finishSession()
		}
	}

	prepareData(lapNumber, data) {
		local knowledgeBase

		data := base.prepareData(lapNumber, data)

		knowledgeBase := this.KnowledgeBase

		for key, value in getConfigurationSectionValues(data, "Position Data", Object())
			knowledgeBase.setFact(key, value)

		return data
	}

	addLap(lapNumber, data) {
		local knowledgeBase := this.KnowledgeBase
		local compound
		local driverForname := ""
		local driverSurname := ""
		local driverNickname := ""

		static lastLap := 0

		if (lapNumber <= lastLap)
			lastLap := 0
		else if ((lastLap == 0) && (lapNumber > 1))
			lastLap := (lapNumber - 1)

		if (this.Speaker && (lapNumber > 1)) {
			driverForname := knowledgeBase.getValue("Driver.Forname", "John")
			driverSurname := knowledgeBase.getValue("Driver.Surname", "Doe")
			driverNickname := knowledgeBase.getValue("Driver.Nickname", "JDO")
		}

		result := base.addLap(lapNumber, data)

		if !result
			return false

		knowledgeBase := this.KnowledgeBase

		if (this.Speaker && (lastLap < (lapNumber - 2)) && (computeDriverName(driverForname, driverSurname, driverNickname) != this.DriverFullName)) {
			Process Exist, Race Engineer.exe

			exists := ErrorLevel

			this.getSpeaker().speakPhrase(exists ? "" : "WelcomeBack")
		}

		lastLap := lapNumber

		if (!this.StrategyReported && this.hasEnoughData(false) && this.Strategy) {
			if this.Speaker[false] {
				this.getSpeaker().speakPhrase("ConfirmReportStrategy", false, true)

				this.setContinuation(ObjBindMethod(this, "reportStrategy"))
			}

			this.updateDynamicValues({StrategyReported: lapNumber})
		}

		gapAhead := getConfigurationValue(data, "Stint Data", "GapAhead", kUndefined)

		if (gapAhead != kUndefined) {
			knowledgeBase.setFact("Position.Track.Ahead.Delta", gapAhead)

			if (knowledgeBase.getValue("Position.Track.Ahead.Car", -1) = knowledgeBase.getValue("Position.Standings.Ahead.Car", 0))
				knowledgeBase.setFact("Position.Standings.Ahead.Delta", gapAhead)
		}

		gapBehind := getConfigurationValue(data, "Stint Data", "GapBehind", kUndefined)

		if (gapBehind != kUndefined) {
			knowledgeBase.setFact("Position.Track.Behind.Delta", gapBehind)

			if (knowledgeBase.getValue("Position.Track.Behind.Car", -1) = knowledgeBase.getValue("Position.Standings.Behind.Car", 0))
				knowledgeBase.setFact("Position.Standings.Behind.Delta", gapBehind)
		}

		Loop % knowledgeBase.getValue("Car.Count")
		{
			validLaps := knowledgeBase.getValue("Car." . A_Index . ".Valid.Laps", 0)
			lap := knowledgeBase.getValue("Car." . A_Index . ".Lap", 0)

			if (lap != knowledgeBase.getValue("Car." . A_Index . ".Valid.LastLap", 0)) {
				knowledgeBase.setFact("Car." . A_Index . ".Valid.LastLap", lap)

				if knowledgeBase.getValue("Car." . A_Index . ".Lap.Valid", true)
					knowledgeBase.setFact("Car." . A_Index . ".Valid.Laps", validLaps +  1)
			}
		}

		simulator := knowledgeBase.getValue("Session.Simulator")
		car := knowledgeBase.getValue("Session.Car")
		track := knowledgeBase.getValue("Session.Track")

		pitstop := knowledgeBase.getValue("Pitstop.Last", false)

		if pitstop
			pitstop := (Abs(lapNumber - (knowledgeBase.getValue("Pitstop." . pitstop . ".Lap"))) <= 2)

		if ((this.hasEnoughData(false) || pitstop) && this.collectTelemetryData()) {
			prefix := "Lap." . lapNumber

			validLap := knowledgeBase.getValue(prefix . ".Valid", true)

			if (validLap || pitstop) {
				weather := knowledgeBase.getValue(prefix . ".Weather")
				airTemperature := knowledgeBase.getValue(prefix . ".Temperature.Air")
				trackTemperature := knowledgeBase.getValue(prefix . ".Temperature.Track")
				compound := knowledgeBase.getValue(prefix . ".Tyre.Compound")
				compoundColor := knowledgeBase.getValue(prefix . ".Tyre.Compound.Color")
				fuelConsumption := Round(knowledgeBase.getValue(prefix . ".Fuel.Consumption"), 1)
				fuelRemaining := Round(knowledgeBase.getValue(prefix . ".Fuel.Remaining"), 1)
				lapTime := Round(knowledgeBase.getValue(prefix . ".Time") / 1000, 1)

				map := knowledgeBase.getValue(prefix . ".Map")
				tc := knowledgeBase.getValue(prefix . ".TC")
				abs := knowledgeBase.getValue(prefix . ".ABS")

				pressures := values2String(",", Round(knowledgeBase.getValue(prefix . ".Tyre.Pressure.FL"), 1)
											  , Round(knowledgeBase.getValue(prefix . ".Tyre.Pressure.FR"), 1)
											  , Round(knowledgeBase.getValue(prefix . ".Tyre.Pressure.RL"), 1)
											  , Round(knowledgeBase.getValue(prefix . ".Tyre.Pressure.RR"), 1))

				temperatures := values2String(",", Round(knowledgeBase.getValue(prefix . ".Tyre.Temperature.FL"), 1)
												 , Round(knowledgeBase.getValue(prefix . ".Tyre.Temperature.FR"), 1)
												 , Round(knowledgeBase.getValue(prefix . ".Tyre.Temperature.RL"), 1)
												 , Round(knowledgeBase.getValue(prefix . ".Tyre.Temperature.RR"), 1))

				wear := false

				if (knowledgeBase.getValue(prefix . ".Tyre.Wear.FL", kUndefined) != kUndefined)
					wear := values2String(",", Round(knowledgeBase.getValue(prefix . ".Tyre.Wear.FL"))
											 , Round(knowledgeBase.getValue(prefix . ".Tyre.Wear.FR"))
											 , Round(knowledgeBase.getValue(prefix . ".Tyre.Wear.RL"))
											 , Round(knowledgeBase.getValue(prefix . ".Tyre.Wear.RR")))

				this.saveTelemetryData(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
									 , fuelConsumption, fuelRemaining, lapTime, pitstop, map, tc, abs
									 , compound, compoundColor, pressures, temperatures, wear)
			}
		}

		this.saveStandingsData(lapNumber, simulator, car, track)

		return result
	}

	updateLap(lapNumber, data) {
		static lastSector := 1

		if !IsObject(data)
			data := readConfiguration(data)

		sector := getConfigurationValue(data, "Stint Data", "Sector", 0)

		if (sector != lastSector) {
			lastSector := sector

			this.KnowledgeBase.addFact("Sector", sector)
		}

		result := base.updateLap(lapNumber, data)

		gapAhead := getConfigurationValue(data, "Stint Data", "GapAhead", kUndefined)

		if (gapAhead != kUndefined) {
			knowledgeBase.setFact("Position.Track.Ahead.Delta", gapAhead)

			if (knowledgeBase.getValue("Position.Track.Ahead.Car", -1) = knowledgeBase.getValue("Position.Standings.Ahead.Car", 0))
				knowledgeBase.setFact("Position.Standings.Ahead.Delta", gapAhead)
		}

		gapBehind := getConfigurationValue(data, "Stint Data", "GapBehind", kUndefined)

		if (gapBehind != kUndefined) {
			knowledgeBase.setFact("Position.Track.Behind.Delta", gapBehind)

			if (knowledgeBase.getValue("Position.Track.Behind.Car", -1) = knowledgeBase.getValue("Position.Standings.Behind.Car", 0))
				knowledgeBase.setFact("Position.Standings.Behind.Delta", gapBehind)
		}

		return result
	}

	requestInformation(category, arguments*) {
		switch category {
			case "Time":
				this.timeRecognized([])
			case "LapsRemaining":
				this.lapsRemainingRecognized([])
			case "Weather":
				this.weatherRecognized([])
			case "Position":
				this.positionRecognized([])
			case "LapTimes":
				this.lapTimesRecognized([])
			case "GapToAheadStandings", "GapToFrontStandings":
				this.gapToAheadRecognized([])
			case "GapToAheadTrack", "GapToFrontTrack":
				this.gapToAheadRecognized(Array(this.getSpeaker().Fragments["Car"]))
			case "GapToAhead", "GapToAhead":
				this.gapToAheadRecognized(inList(arguments, "Track") ? Array(this.getSpeaker().Fragments["Car"]) : [])
			case "GapToBehindStandings":
				this.gapToBehindRecognized([])
			case "GapToBehindTrack":
				this.gapToBehindRecognized(Array(this.getSpeaker().Fragments["Car"]))
			case "GapToBehind":
				this.gapToBehindRecognized(inList(arguments, "Track") ? Array(this.getSpeaker().Fragments["Car"]) : [])
			case "GapToLeader":
				this.gapToLeaderRecognized([])
			case "StrategyOverview":
				this.strategyOverviewRecognized([])
			case "NextPitstop":
				this.nextPitstopRecognized([])
		}
	}

	reportStrategy(options := true) {
		local knowledgeBase := this.KnowledgeBase

		if this.Speaker {
			strategyName := knowledgeBase.getValue("Strategy.Name", false)
			speaker := this.getSpeaker()

			if strategyName {
				speaker.startTalk()

				try {
					if ((options == true) || options.Strategy)
						speaker.speakPhrase("Strategy")

					numPitstops := knowledgeBase.getValue("Strategy.Pitstop.Count")

					if ((options == true) || options.Pitstops)
						speaker.speakPhrase("Pitstops", {pitstops: numPitstops})

					nextPitstop := knowledgeBase.getValue("Strategy.Pitstop.Next", false)

					if nextPitstop {
						lap := knowledgeBase.getValue("Strategy.Pitstop." . nextPitstop . ".Lap")
						refuel := Round(knowledgeBase.getValue("Strategy.Pitstop." . nextPitstop . ".Fuel.Amount"))
						tyreChange := knowledgeBase.getValue("Strategy.Pitstop." . nextPitstop . ".Tyre.Change")

						if ((options == true) || options.NextPitstop)
							speaker.speakPhrase("NextPitstop", {pitstopLap: lap})

						if ((options == true) || options.Refuel)
							speaker.speakPhrase((refuel > 0) ? "Refuel" : "NoRefuel", {refuel: refuel})

						if ((options == true) || options.TyreChange)
							speaker.speakPhrase(tyreChange ? "TyreChange" : "NoTyreChange")
					}
					else if ((options == true) || options.NextPitstop || options.Refuel || options.TyreChange)
						speaker.speakPhrase("NoNextPitstop")

					if ((options == true) || options.Map) {
						map := knowledgeBase.getValue("Strategy.Map")

						if ((map != "n/a") && (map != knowledgeBase.getValue("Lap." . knowledgeBase.getValue("Lap") . ".Map", "n/a")))
							speaker.speakPhrase("StrategyMap", {map: map})
					}
				}
				finally {
					speaker.finishTalk()
				}
			}
			else
				speaker.speakPhrase("NoStrategy")

			this.updateDynamicValues({StrategyReported: knowledgeBase.getValue("Lap")})
		}
	}

	cancelStrategy(confirm := true) {
		local knowledgeBase := this.KnowledgeBase
		local fact

		hasStrategy := knowledgeBase.getValue("Strategy.Name", false)

		if (this.Speaker && confirm) {
			if hasStrategy {
				this.getSpeaker().speakPhrase("ConfirmCancelStrategy", false, true)

				this.setContinuation(ObjBindMethod(this, "cancelStrategy", false))
			}
			else
				speaker.speakPhrase("NoStrategy")

			return
		}

		if hasStrategy {
			this.clearStrategy()

			if this.Speaker
				this.getSpeaker().speakPhrase("StrategyCanceled")
		}
	}

	clearStrategy() {
		local knowledgeBase := this.KnowledgeBase

		for ignore, theFact in ["Name", "Weather", "Weather.Temperature.Air", "Weather.Temperature.Track"
							  , "Tyre.Compound", "Tyre.Compound.Color", "Map", "TC", "ABS"
							  , "Pitstop.Count", "Pitstop.Next", "Pitstop.Lap", "Pitstop.Lap.Warning"]
			knowledgeBase.clearFact("Strategy." . theFact)

		Loop % knowledgeBase.getValue("Strategy.Pitstop.Count", 0)
			for index, theFact in [".Lap", ".Fuel.Amount", ".Tyre.Change", ".Map"]
				knowledgeBase.clearFact("Strategy.Pitstop." . index . theFact)

		knowledgeBase.clearFact("Strategy.Pitstop.Count")
	}

	updateStrategy(strategy) {
		local knowledgeBase := this.KnowledgeBase
		local facts
		local fact

		if strategy {
			if (this.Session == kSessionRace) {
				if !IsObject(strategy)
					strategy := readConfiguration(strategy)

				this.clearStrategy()

				facts := {}

				this.createStrategy(facts, strategy, knowledgeBase.getValue("Lap") + 1)

				for fact, value in facts
					knowledgeBase.setFact(fact, value)

				this.dumpKnowledge(knowledgeBase)

				this.updateSessionValues({Strategy: strategy})
			}
		}
		else {
			this.cancelStrategy(false)

			this.updateSessionValues({Strategy: false})
		}

		this.updateDynamicValues({StrategyReported: false})
	}

	recommendPitstop(lap := false) {
		local knowledgeBase := this.KnowledgeBase

		speaker := this.getSpeaker()

		if !this.hasEnoughData()
			return

		if !lap {
			lap := knowledgeBase.getValue("Strategy.Pitstop.Lap", false)

			if (lap && (lap >= (knowledgeBase.getValue("Lap") - knowledgeBase.getValue("Session.Settings.Lap.PitstopWarning"))))
				lap := false
		}

		knowledgeBase.setFact("Pitstop.Strategy.Plan", lap ? lap : true)

		knowledgeBase.produce()

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(this.KnowledgeBase)

		plannedLap := knowledgebase.getValue("Pitstop.Strategy.Lap", kUndefined)

		if (plannedLap == kUndefined)
			speaker.speakPhrase("NoPlannedPitstop")
		else if !plannedLap
			speaker.speakPhrase("NoPitstopNeeded")
		else {
			speaker.startTalk()

			try {
				speaker.speakPhrase("PitstopLap", {lap: plannedLap})

				Process Exist, Race Engineer.exe

				if ErrorLevel {
					speaker.speakPhrase("ConfirmInformEngineer", false, true)

					this.setContinuation(ObjBindMethod(this, "planPitstop", plannedLap))
				}
			}
			finally {
				speaker.finishTalk()
			}
		}
	}

	planPitstop(plannedLap := false, refuel := "__Undefined__", tyreChange := "__Undefined__") {
		sendMessage()

		Loop 10
			Sleep 500

		Process Exist, Race Engineer.exe

		if ErrorLevel
			if plannedLap {
				if (refuel != kUndefined)
					raiseEvent(kFileMessage, "Race Engineer", "planPitstop:" . values2String(";", plannedLap, refuel, tyreChange), ErrorLevel)
				else
					raiseEvent(kFileMessage, "Race Engineer", "planPitstop:" . plannedLap, ErrorLevel)
			}
			else
				raiseEvent(kFileMessage, "Race Engineer", "planPitstop", ErrorLevel)
	}

	performPitstop(lapNumber := false) {
		local knowledgeBase := this.KnowledgeBase

		if (this.Strategy && this.Speaker[false])
			nextPitstop := knowledgeBase.getValue("Strategy.Pitstop.Next", false)
		else
			nextPitstop := false

		this.startPitstop(lapNumber)

		base.performPitstop(lapNumber)

		knowledgeBase.addFact("Pitstop.Lap", lapNumber ? lapNumber : knowledgeBase.getValue("Lap"))

		result := knowledgeBase.produce()

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(knowledgeBase)

		if (nextPitstop && (nextPitstop != knowledgeBase.getValue("Strategy.Pitstop.Next", false))) {
			map := knowledgeBase.getValue("Strategy.Pitstop.", nextPitstop, ".Map", "n/a")

			if ((map != "n/a") && (map != knowledgeBase.getValue("Lap." . knowledgeBase.getValue("Lap") . ".Map", "n/a")))
				this.getSpeaker().speakPhrase("StintMap", {map: map})
		}

		this.finishPitstop(lapNumber)

		return result
	}

	callRecommendPitstop() {
		this.clearContinuation()

		this.getSpeaker().speakPhrase("Confirm")

		sendMessage()

		Loop 10
			Sleep 500

		this.recommendPitstop()
	}

	weatherChangeNotification(change, minutes) {
		local knowledgeBase := this.KnowledgeBase

		if (this.Speaker[false] && (this.Session == kSessionRace) && this.Announcements["WeatherUpdate"]) {
			speaker := this.getSpeaker()

			speaker.speakPhrase(change ? "WeatherChange" : "WeatherNoChange", {minutes: minutes})
		}
	}

	weatherTyreChangeRecommendation(minutes, recommendedCompound) {
		local knowledgeBase := this.KnowledgeBase

		if (knowledgeBase.getValue("Lap.Remaining") > 3)
			if (this.Speaker[false] && (this.Session == kSessionRace)) {
				speaker := this.getSpeaker()
				fragments := speaker.Fragments

				speaker.startTalk()

				try {
					speaker.speakPhrase((recommendedCompound = "Wet") ? "WeatherRainChange" : "WeatherDryChange"
									  , {minutes: minutes, compound: fragments[recommendedCompound]})

					Process Exist, Race Engineer.exe

					if ErrorLevel {
						speaker.speakPhrase("ConfirmInformEngineer", false, true)

						this.setContinuation(ObjBindMethod(this, "planPitstop"))
					}
				}
				finally {
					speaker.finishTalk()
				}
			}
	}

	reportUpcomingPitstop(plannedPitstopLap) {
		local knowledgeBase := this.KnowledgeBase

		if this.Speaker[false] {
			speaker := this.getSpeaker()

			if this.hasEnoughData(false) {
				knowledgeBase.setFact("Pitstop.Strategy.Plan", plannedPitstopLap)

				knowledgeBase.produce()

				if this.Debug[kDebugKnowledgeBase]
					this.dumpKnowledge(this.KnowledgeBase)

				plannedLap := knowledgebase.getValue("Pitstop.Strategy.Lap", kUndefined)

				if (plannedLap && (plannedLap != kUndefined))
					plannedPitstopLap := plannedLap
			}

			laps := (plannedPitstopLap - knowledgeBase.getValue("Lap"))

			speaker.startTalk()

			try {
				speaker.speakPhrase("PitstopAhead", {lap: plannedPitstopLap, laps: laps})

				Process Exist, Race Engineer.exe

				if ErrorLevel {
					speaker.speakPhrase("ConfirmInformEngineer", false, true)

					nextPitstop := knowledgebase.getValue("Strategy.Pitstop.Next")

					refuel := Round(knowledgeBase.getValue("Strategy.Pitstop." . nextPitstop . ".Fuel.Amount"))
					tyreChange := knowledgeBase.getValue("Strategy.Pitstop." . nextPitstop . ".Tyre.Change")

					this.setContinuation(ObjBindMethod(this, "planPitstop", plannedPitstopLap, refuel, tyreChange))
				}
			}
			finally {
				speaker.finishTalk()
			}
		}
	}

	saveLapStandings(lapNumber, simulator, car, track) {
		local knowledgeBase := this.KnowledgeBase

		if this.RemoteHandler {
			Random postfix, 1, 1000000

			driver := knowledgeBase.getValue("Driver.Car")
			carCount := knowledgeBase.getValue("Car.Count")

			if ((driver == 0) || (carCount == 0))
				return

			fileName := (kTempDirectory . "Race Strategist Lap " . postfix . ".standings")
			data := newConfiguration()

			setConfigurationValue(data, "Lap", "Lap", lapNumber)
			setConfigurationValue(data, "Lap", "Driver", driver)
			setConfigurationValue(data, "Lap", "Cars", carCount)

			prefix := ("Standings.Lap." . lapNumber)

			for key, value in knowledgeBase.Facts.Facts
				if (InStr(key, "Position", 1) == 1)
					setConfigurationValue(data, "Position", key, value)
				else if InStr(key, prefix, 1)
					setConfigurationValue(data, "Standings", key, value)

			writeConfiguration(fileName, data)

			this.RemoteHandler.saveStandingsData(lapNumber, fileName)
		}
	}

	updateRaceInfo(raceData) {
		raceInfo := {}

		raceInfo["Driver"] := getConfigurationValue(raceData, "Cars", "Driver")
		raceInfo["Cars"] := getConfigurationValue(raceData, "Cars", "Count")

		grid := []

		Loop % raceInfo["Cars"]
		{
			carNr := getConfigurationValue(raceData, "Cars", "Car." . A_Index . ".Nr")
			carPosition := getConfigurationValue(raceData, "Cars", "Car." . A_Index . ".Position")

			grid.Push(carPosition)

			raceInfo[carNr . ""] := A_Index
		}

		raceInfo["Grid"] := grid

		this.updateSessionValues({RaceInfo: raceInfo})
	}

	saveStandingsData(lapNumber, simulator, car, track) {
		local knowledgeBase := this.KnowledgeBase

		if this.RemoteHandler {
			Random postfix, 1, 1000000

			driver := knowledgeBase.getValue("Driver.Car", 0)
			carCount := knowledgeBase.getValue("Car.Count", 0)

			if ((driver == 0) || (carCount == 0))
				return

			if this.iFirstStandingsLap {
				this.iFirstStandingsLap := false

				data := newConfiguration()

				setConfigurationValue(data, "Session", "Time", this.SessionTime)
				setConfigurationValue(data, "Session", "Simulator", knowledgeBase.getValue("Session.Simulator"))
				setConfigurationValue(data, "Session", "Car", knowledgeBase.getValue("Session.Car"))
				setConfigurationValue(data, "Session", "Track", knowledgeBase.getValue("Session.Track"))
				setConfigurationValue(data, "Session", "Duration", (Round((knowledgeBase.getValue("Session.Duration") / 60) / 5) * 300))
				setConfigurationValue(data, "Session", "Format", knowledgeBase.getValue("Session.Format"))

				setConfigurationValue(data, "Cars", "Count", carCount)
				setConfigurationValue(data, "Cars", "Driver", driver)

				raceInfo := this.RaceInfo
				grid := (raceInfo ? raceInfo["Grid"] : false)

				Loop %carCount% {
					carNr := StrReplace(knowledgeBase.getValue("Car." . A_Index . ".Nr", 0) . "", """", "")

					setConfigurationValue(data, "Cars", "Car." . A_Index . ".Nr", carNr)
					setConfigurationValue(data, "Cars", "Car." . A_Index . ".Car", knowledgeBase.getValue("Car." . A_Index . ".Car"))

					if (grid != false) {
						index := (raceInfo.HasKey(carNr) ? raceInfo[carNr] : A_Index)

						setConfigurationValue(data, "Cars", "Car." . A_Index . ".Position", grid[index + 0])
					}
					else
						setConfigurationValue(data, "Cars", "Car." . A_Index . ".Position", knowledgeBase.getValue("Car." . A_Index . ".Position", A_Index))
				}

				fileName := (kTempDirectory . "Race Strategist Race " . postfix . ".info")

				writeConfiguration(fileName, data)

				this.updateRaceInfo(data)

				this.RemoteHandler.saveRaceInfo(lapNumber, fileName)
			}

			data := newConfiguration()

			pitstop := knowledgeBase.getValue("Pitstop.Last", false)

			if pitstop {
				pitstops := []

				Loop %pitstop%
					pitstops.Push(knowledgeBase.getValue("Pitstop." . A_Index . ".Lap"))

				setConfigurationValue(data, "Pitstop", "Laps", values2String(",", pitstops*))

				pitstop := (lapNumber == (knowledgeBase.getValue("Pitstop." . pitstop . ".Lap") + 1))
			}

			prefix := "Lap." . lapNumber

			setConfigurationValue(data, "Lap", "Lap", lapNumber)

			setConfigurationValue(data, "Lap", prefix . ".Weather", knowledgeBase.getValue("Standings.Lap." . lapNumber . ".Weather"))
			setConfigurationValue(data, "Lap", prefix . ".LapTime", knowledgeBase.getValue(prefix . ".Time"))
			setConfigurationValue(data, "Lap", prefix . ".Compound", knowledgeBase.getValue(prefix . ".Tyre.Compound", "Dry"))
			setConfigurationValue(data, "Lap", prefix . ".CompoundColor", knowledgeBase.getValue(prefix . ".Tyre.Compound.Color", "Black"))
			setConfigurationValue(data, "Lap", prefix . ".Map", knowledgeBase.getValue(prefix . ".Map", "n/a"))
			setConfigurationValue(data, "Lap", prefix . ".TC", knowledgeBase.getValue(prefix . ".TC", "n/a"))
			setConfigurationValue(data, "Lap", prefix . ".ABS", knowledgeBase.getValue(prefix . ".ABS", "n/a"))
			setConfigurationValue(data, "Lap", prefix . ".Consumption", knowledgeBase.getValue(prefix . ".Fuel.Consumption", "n/a"))
			setConfigurationValue(data, "Lap", prefix . ".Pitstop", pitstop)

			raceInfo := this.RaceInfo

			carCount := raceInfo["Cars"]

			times := []
			positions := []
			drivers := []
			laps := []

			Loop %carCount% {
				times.Push("-")
				positions.Push("-")
				drivers.Push("-")
				laps.Push("-")
			}

			Loop {
				carPrefix := ("Standings.Lap." . lapNumber . ".Car." . A_Index)
				carNr := knowledgeBase.getValue(carPrefix . ".Nr", kUndefined)

				if (carNr == kUndefined)
					break

				if raceInfo.HasKey(carNr . "") {
					carIndex := raceInfo[carNr . ""]

					times[carIndex] := knowledgeBase.getValue(carPrefix . ".Time", "-")
					positions[carIndex] := knowledgeBase.getValue(carPrefix . ".Position", "-")
					laps[carIndex] := Floor(knowledgeBase.getValue(carPrefix . ".Laps", "-"))

					driverForname := knowledgeBase.getValue(carPrefix . ".Driver.Forname")
					driverSurname := knowledgeBase.getValue(carPrefix . ".Driver.Surname")
					driverNickname := knowledgeBase.getValue(carPrefix . ".Driver.Nickname")

					drivers[carIndex] := computeDriverName(driverForname, driverSurname, driverNickname)
				}
			}

			setConfigurationValue(data, "Times", lapNumber, values2String(";", times*))
			setConfigurationValue(data, "Positions", lapNumber, values2String(";", positions*))
			setConfigurationValue(data, "Laps", lapNumber, values2String(";", laps*))
			setConfigurationValue(data, "Drivers", lapNumber, values2String(";", drivers*))

			fileName := (kTempDirectory . "Race Strategist Race " . postfix . "." . lapNumber . ".lap")

			writeConfiguration(fileName, data)

			this.RemoteHandler.saveRaceLap(lapNumber, fileName)
		}

		this.saveLapStandings(lapNumber, simulator, car, track)
	}

	restoreRaceInfo(raceInfoFile) {
		this.updateRaceInfo(readConfiguration(raceInfoFile))

		try {
			FileDelete %raceInfoFile%
		}
		catch exception {
			; ignore
		}
	}

	createRaceReport() {
		if this.RemoteHandler
			this.RemoteHandler.createRaceReport()
	}

	saveTelemetryData(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
					, fuelConsumption, fuelRemaining, lapTime, pitstop, map, tc, abs
					, compound, compoundColor, pressures, temperatures, wear) {
		if (this.RemoteHandler && this.collectTelemetryData()) {
			this.updateDynamicValues({HasTelemetryData: true})

			this.RemoteHandler.saveTelemetryData(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
											   , fuelConsumption, fuelRemaining, lapTime, pitstop, map, tc, abs,
											   , compound, compoundColor, pressures, temperatures, wear)
		}
	}

	updateTelemetryDatabase() {
		if (this.RemoteHandler && this.collectTelemetryData())
			this.RemoteHandler.updateTelemetryDatabase()

		this.updateDynamicValues({HasTelemetryData: false})
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

getTime() {
	return A_Now
}

comparePositions(c1, c2) {
	return (c1[2] < c2[2])
}

compareSequences(c1, c2) {
	c1 := c1[2]
	c2 := c2[2]

	return ((c1 - Floor(c1)) < (c2 - Floor(c2)))
}

updatePositions(context, futureLap) {
	local knowledgeBase := context.KnowledgeBase

	cars := []
	count := 0

	Loop % knowledgeBase.getValue("Car.Count", 0)
	{
		laps := knowledgeBase.getValue("Standings.Extrapolated." . futureLap . ".Car." . A_Index . ".Laps", kUndefined)

		if (laps != kUndefined) {
			cars.Push(Array(A_Index, laps))

			count += 1
		}
	}

	bubbleSort(cars, "comparePositions")

	Loop {
		if (A_Index > count)
			break

		knowledgeBase.setFact("Standings.Extrapolated." . futureLap . ".Car." . cars[A_Index][1] . ".Position", A_Index)
	}

	bubbleSort(cars, "compareSequences")

	Loop {
		if (A_Index > count)
			break

		knowledgeBase.setFact("Standings.Extrapolated." . futureLap . ".Car." . cars[A_Index][1] . ".Sequence", A_Index)
	}

	return true
}

weatherChangeNotification(context, change, minutes) {
	context.KnowledgeBase.RaceAssistant.weatherChangeNotification(change, minutes)

	return true
}

weatherTyreChangeRecommendation(context, minutes, recommendedCompound) {
	context.KnowledgeBase.RaceAssistant.weatherTyreChangeRecommendation(minutes, recommendedCompound)

	return true
}

reportUpcomingPitstop(context, lap) {
	context.KnowledgeBase.RaceAssistant.reportUpcomingPitstop(lap)

	return true
}