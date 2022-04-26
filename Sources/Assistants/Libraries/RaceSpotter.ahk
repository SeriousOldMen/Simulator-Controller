;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - AI Race Spotter                 ;;;
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

class RaceSpotter extends RaceAssistant {
	iSpotterPID := false
	
	iSessionDataActive := false
	
	iGridPosition := false
	
	iLastDistanceInformationLap := false
	iPositionInfo := {}
	
	iRaceStartSummarized := true
	iFinalLapsAnnounced := false
	
	iDriverUpdate := 0
	
	class SpotterVoiceAssistant extends RaceAssistant.RaceVoiceAssistant {		
		iFastSpeechSynthesizer := false
			
		getSpeaker(fast := false) {
			if fast {
				if !this.iFastSpeechSynthesizer {
					this.iFastSpeechSynthesizer := new this.LocalSpeaker(this, this.Synthesizer, this.Speaker, this.Language
																	   , this.buildFragments(this.Language), this.buildPhrases(this.Language))
				
					this.iFastSpeechSynthesizer.setVolume(this.SpeakerVolume)
					this.iFastSpeechSynthesizer.setPitch(this.SpeakerPitch)
					this.iFastSpeechSynthesizer.setRate(this.SpeakerSpeed)
				}
			
				return this.iFastSpeechSynthesizer
			}
			else
				return base.getSpeaker()
		}
	}
	
	class RaceSpotterRemoteHandler extends RaceAssistant.RaceAssistantRemoteHandler {
		__New(remotePID) {
			base.__New("Race Spotter", remotePID)
		}
	}
	
	SessionDataActive[] {
		Get {
			return this.iSessionDataActive
		}
	}
	
	SpotterSpeaking[] {
		Get {
			return this.getSpeaker(true).Speaking
		}
		
		Set {
			return (this.getSpeaker(true).Speaking := value)
		}
	}
	
	GridPosition[] {
		Get {
			return this.iGridPosition
		}
	}
	
	PositionInfo {
		Get {
			return this.iPositionInfo
		}
	}
	
	__New(configuration, remoteHandler, name := false, language := "__Undefined__"
		, synthesizer := false, speaker := false, vocalics := false, recognizer := false, listener := false, voiceServer := false) {
		base.__New(configuration, "Race Spotter", remoteHandler, name, language, synthesizer, speaker, vocalics, recognizer, listener, voiceServer)
		
		OnExit(ObjBindMethod(this, "shutdownSpotter"))
	}
	
	createVoiceAssistant(name, options) {
		return new this.SpotterVoiceAssistant(this, name, options)
	}
	
	updateSessionValues(values) {
		base.updateSessionValues(values)
		
		if (this.Session == kSessionFinished) {
			this.iLastDistanceInformationLap := false
			this.iPositionInfo := {}
			
			this.iRaceStartSummarized := false
			this.iFinalLapsAnnounced := false
		}
	}
	
	updateDynamicValues(values) {
		base.updateDynamicValues(values)
	}
	
	handleVoiceCommand(grammar, words) {
		switch grammar {
			case "Position":
				this.positionRecognized(words)
			case "LapTimes":
				this.lapTimesRecognized(words)
			case "GapToFront":
				this.gapToFrontRecognized(words)
			case "GapToBehind":
				this.gapToBehindRecognized(words)
			case "GapToLeader":
				this.gapToLeaderRecognized(words)
			default:
				base.handleVoiceCommand(grammar, words)
		}
	}
	
	positionRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		speaker := this.getSpeaker(true)
		position := Round(knowledgeBase.getValue("Position", 0))
		
		if (position == 0)
			speaker.speakPhrase("Later")
		else if inList(words, speaker.Fragments["Laps"])
			this.futurePositionRecognized(words)
		else {
			speaker.speakPhrase("Position", {position: position})
			
			if (position <= 3)
				speaker.speakPhrase("Great")
		}
	}
	
	gapToFrontRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		if inList(words, this.getSpeaker(true).Fragments["Car"])
			this.trackGapToFrontRecognized(words)
		else
			this.standingsGapToFrontRecognized(words)
	}
	
	trackGapToFrontRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		speaker := this.getSpeaker(true)
		
		delta := knowledgeBase.getValue("Position.Track.Front.Delta", 0)
		
		if (delta != 0) {
			speaker.speakPhrase("TrackGapToFront", {delta: Format("{:.1f}", Abs(Round(delta / 1000, 1)))})
			
			lap := knowledgeBase.getValue("Lap")
			driverLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Driver.Car") . ".Laps"))
			otherLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Position.Track.Front.Car") . ".Laps"))
			
			if (driverLap < otherLap)
			  speaker.speakPhrase("NotTheSameLap")
		}
		else
			speaker.speakPhrase("NoTrackGap")
	}
	
	standingsGapToFrontRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if (Round(knowledgeBase.getValue("Position", 0)) = 1)
			this.getSpeaker(true).speakPhrase("NoGapToFront")
		else {
			delta := Abs(Round(knowledgeBase.getValue("Position.Standings.Front.Delta", 0) / 1000, 1))
			
			this.getSpeaker(true).speakPhrase("StandingsGapToFront", {delta: Format("{:.1f}", delta)})
		}
	}
	
	gapToBehindRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		if inList(words, this.getSpeaker(true).Fragments["Car"])
			this.trackGapToBehindRecognized(words)
		else
			this.standingsGapToBehindRecognized(words)
	}
	
	trackGapToBehindRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		speaker := this.getSpeaker(true)
		
		delta := knowledgeBase.getValue("Position.Track.Behind.Delta", 0)
		
		if (delta != 0) {
			speaker.speakPhrase("TrackGapToBehind", {delta: Format("{:.1f}", Abs(Round(delta / 1000, 1)))})
			
			lap := knowledgeBase.getValue("Lap")
			driverLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Driver.Car") . ".Laps"))
			otherLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Position.Track.Behind.Car") . ".Laps"))
			
			if (driverLap > (otherLap + 1))
			  speaker.speakPhrase("NotTheSameLap")
		}
		else
			speaker.speakPhrase("NoTrackGap")
	}
	
	standingsGapToBehindRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if (Round(knowledgeBase.getValue("Position", 0)) = Round(knowledgeBase.getValue("Car.Count", 0)))
			this.getSpeaker(true).speakPhrase("NoGapToBehind")
		else {
			delta := Abs(Round(knowledgeBase.getValue("Position.Standings.Behind.Delta", 0) / 1000, 1))
		
			this.getSpeaker(true).speakPhrase("StandingsGapToBehind", {delta: Format("{:.1f}", delta)})
		}
	}
	
	gapToLeaderRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		if (Round(knowledgeBase.getValue("Position", 0)) = 1)
			this.getSpeaker(true).speakPhrase("NoGapToFront")
		else {
			delta := Abs(Round(knowledgeBase.getValue("Position.Standings.Leader.Delta", 0) / 1000, 1))
		
			this.getSpeaker(true).speakPhrase("GapToLeader", {delta: Format("{:.1f}", delta)})
		}
	}
	
	reportLapTime(phrase, driverLapTime, car) {
		lapTime := this.KnowledgeBase.getValue("Car." . car . ".Time", false)
		
		if lapTime {
			lapTime := Round(lapTime / 1000, 1)
			
			speaker := this.getSpeaker(true)
			fragments := speaker.Fragments
			
			speaker.speakPhrase(phrase, {time: Format("{:.1f}", lapTime)})
			
			delta := (driverLapTime - lapTime)
		
			if (Abs(delta) > 0.5)
				this.getSpeaker(true).speakPhrase("LapTimeDelta", {delta: Format("{:.1f}", Abs(delta))
																, difference: (delta > 0) ? fragments["Faster"] : fragments["Slower"]})
		}
	}
	
	lapTimesRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		car := knowledgeBase.getValue("Driver.Car")
		lap := knowledgeBase.getValue("Lap")
		position := Round(knowledgeBase.getValue("Position"))
		cars := Round(knowledgeBase.getValue("Car.Count"))
		
		driverLapTime := Round(knowledgeBase.getValue("Car." . car . ".Time") / 1000, 1)
		
		if (lap == 0)
			this.getSpeaker(true).speakPhrase("Later")
		else {
			this.getSpeaker(true).speakPhrase("LapTime", {time: Format("{:.1f}", driverLapTime)})
		
			if (position > 2)
				this.reportLapTime("LapTimeFront", driverLapTime, knowledgeBase.getValue("Position.Standings.Front.Car", 0))
			
			if (position < cars)
				this.reportLapTime("LapTimeBehind", driverLapTime, knowledgeBase.getValue("Position.Standings.Behind.Car", 0))
			
			if (position > 1)
				this.reportLapTime("LapTimeLeader", driverLapTime, knowledgeBase.getValue("Position.Standings.Leader.Car", 0))
		}
	}
	
	updateAnnouncement(announcement, value) {
		if (value && (announcement = "DistanceInformation")) {
			value := getConfigurationValue(this.Configuration, "Race Spotter Announcements", this.Simulator . ".PerformanceUpdates", 2)
			value := getConfigurationValue(this.Configuration, "Race Spotter Announcements", this.Simulator . ".DistanceInformation", value)
			
			if !value
				value := 2
		}
		
		base.updateAnnouncement(announcement, value)
	}
	
	getSpeaker(fast := false) {
		return this.VoiceAssistant.getSpeaker(fast)
	}
	
	updatePositionInfo(lastLap) {
		local knowledgeBase = this.KnowledgeBase
		
		positionInfo := this.PositionInfo
		
		driver := knowledgeBase.getValue("Driver.Car")
		driverLapTime := Round(knowledgeBase.getValue("Car." . driver . ".Time") / 1000, 1)
		position := Round(knowledgeBase.getValue("Position", 0))
		
		frontStandingsDelta := Round(Abs(knowledgeBase.getValue("Position.Standings.Front.Delta", 0)) / 1000, 1)
		
		if ((frontStandingsDelta = 0) || (position = 1))
			positionInfo.Delete("Front")
		else {
			car := knowledgeBase.getValue("Position.Standings.Front.Car")
			
			if (positionInfo.HasKey("Front") && (positionInfo["Front"].Car != car))
				positionInfo.Delete("Front")
			
			frontLapTime := Round(knowledgeBase.getValue("Car." . car . ".Time") / 1000, 1)
			
			difference := Round(positionInfo.HasKey("Front") ? (positionInfo["Front"].Delta - frontStandingsDelta) : false, 1)
			
			positionInfo["Front"] := {Car: car, Delta: frontStandingsDelta, DeltaDifference: difference, LapTimeDifference: Round(frontLapTime - driverLapTime, 1)}
		}
		
		behindStandingsDelta := Round(Abs(knowledgeBase.getValue("Position.Standings.Behind.Delta", 0)) / 1000, 1)
		
		if ((behindStandingsDelta = 0) || (position = Round(knowledgeBase.getValue("Car.Count", 0))))
			positionInfo.Delete("Behind")
		else {
			car := knowledgeBase.getValue("Position.Standings.Behind.Car")
			
			if (positionInfo.HasKey("Behind") && (positionInfo["Behind"].Car != car))
				positionInfo.Delete("Behind")
			
			behindLapTime := Round(knowledgeBase.getValue("Car." . car . ".Time") / 1000, 1)
			
			difference := Round(positionInfo.HasKey("Behind") ? (positionInfo["Behind"].Delta - behindStandingsDelta) : false, 1)
			
			positionInfo["Behind"] := {Car: car, Delta: behindStandingsDelta, DeltaDifference: difference, LapTimeDifference: Round(behindLapTime - driverLapTime, 1)}
		}
	}

	summarizeRaceStart(lastLap) {
		local knowledgeBase = this.KnowledgeBase
		
		if (this.Session == kSessionRace) {
			speaker := this.getSpeaker(true)
			driver := knowledgeBase.getValue("Driver.Car", false)
			
			if (driver && this.GridPosition) {
				currentPosition := knowledgeBase.getValue("Car." . driver . ".Position")
			
				if (currentPosition = this.GridPosition)
					speaker.speakPhrase("GoodStart")
				else if (currentPosition < this.GridPosition) {
					speaker.speakPhrase("GreatStart")
					
					if (currentPosition = 1)
						speaker.speakPhrase("Leader")
					else
						speaker.speakPhrase("PositionsGained", {positions: Abs(currentPosition - this.GridPosition)})
				}
				else if (currentPosition > this.GridPosition) {
					speaker.speakPhrase("BadStart")
					
					speaker.speakPhrase("PositionsLost", {positions: Abs(currentPosition - this.GridPosition)})
					
					speaker.speakPhrase("Fight")
				}
			}
		}
	}
	
	updatePerformance(lastLap) {
		local knowledgeBase := this.KnowledgeBase
		
		speaker := this.getSpeaker(true)
		positionInfo := this.PositionInfo
		
		cheered := false
		
		if (positionInfo.HasKey("Front") && (positionInfo["Front"].DeltaDifference > 0)) {
			delta := positionInfo["Front"].Delta
			lapTimeDifference := positionInfo["Behind"].LapTimeDifference
			
			if (knowledgeBase.getValue("Session.Lap.Remaining") > (delta / lapTimeDifference)) {
				speaker.speakPhrase((delta < 1) ? "GotHim" : "GainedFront", {delta: (delta > 5) ? Round(delta) : Round(delta, 1)
																		   , gained: Round(positionInfo["Front"].DeltaDifference, 1)
																		   , lapTime: Round(lapTimeDifference, 1)})
			
				if (delta >= 1)
					speaker.speakPhrase("CanDoIt")
			}
			else {
				speaker.speakPhrase("GainedFront", {delta: (delta > 5) ? Round(delta) : Round(delta, 1)
												  , gained: Round(positionInfo["Front"].DeltaDifference, 1)
												  , lapTime: Round(lapTimeDifference, 1)})
			
				speaker.speakPhrase("CantDoIt")
			}
			
			cheered := true
		}
		
		if (positionInfo.HasKey("Behind") && (positionInfo["Behind"].DeltaDifference > 0)) {
			delta := positionInfo["Behind"].Delta
		
			speaker.speakPhrase((delta < 1) ? "ClosingIn" : "LostBehind", {delta: (delta > 5) ? Round(delta) : Round(delta, 1)
																		 , lost: Round(positionInfo["Behind"].DeltaDifference, 1)
																		 , lapTime: Round(positionInfo["Behind"].LapTimeDifference, 1)})
			
			if (!cheered && (delta >= 1))
				speaker.speakPhrase("Focus")
		}
	}
	
	announceFinalLaps(lastLap) {
		local knowledgeBase = this.KnowledgeBase
		
		speaker := this.getSpeaker(true)
		position := Round(knowledgeBase.getValue("Position", 0))
		
		speaker.speakPhrase("LastLaps")
		
		if (position <= 3) {
			if (position == 1)
				speaker.speakPhrase("Leader")
			else 
				speaker.speakPhrase("Position", {position: position})
			
			speaker.speakPhrase("BringItHome")
		}
		else
			speaker.speakPhrase("Focus")
	}
	
	updateDriver() {
		local knowledgeBase = this.KnowledgeBase
		
		if (this.Speaker && (this.Session = kSessionRace)) {
			lastLap := knowledgeBase.getValue("Lap", 0)
					
			this.updatePositionInfo(lastLap)
				
			if !this.SpotterSpeaking {
				this.SpotterSpeaking := true
				
				try {
					if ((lastLap > 5) && this.Warnings["FinalLaps"] && !this.iFinalLapsAnnounced && (knowledgeBase.getValue("Session.Lap.Remaining") <= 3)) {
						this.iFinalLapsAnnounced := true
						
						this.announceFinalLaps(lastLap)
					}
					else if (this.Warnings["StartSummary"] && !this.iRaceStartSummarized && (lastLap = 2)) {
						this.iRaceStartSummarized := true

						if this.Warnings["StartSummary"]
							this.summarizeRaceStart(lastLap)
					}
					else if (lastLap > 2) {
						distanceInformation := this.Warnings["DistanceInformation"]
						
						if (distanceInformation && (lastLap >= (this.iLastDistanceInformationLap + distanceInformation))) {
							this.iLastDistanceInformationLap := lastLap
							
							this.updatePerformance(lastLap)
						}
					}
				}
				finally {
					this.SpotterSpeaking := false
				}
			}
			else
				this.iDriverUpdate := 2
		}
	}
	
	proximityAlert(type, variables := false) {
		if (((type != "Behind") && this.Warnings["SideProximity"]) || ((type = "Behind") && this.Warnings["RearProximity"])) {
			if (variables && !IsObject(variables)) {
				values := {}
				
				for ignore, value in string2Values(",", variables) {
					value := string2Values(":", value)
				
					values[value[1]] := value[2]
				}
				
				variables := values
			}
			
			if (this.Speaker && !this.SpotterSpeaking) {
				this.SpotterSpeaking := true
				
				try {
					this.getSpeaker(true).speakPhrase(type, variables)
				}
				finally {
					this.SpotterSpeaking := false
				}
			}
		}
	}
	
	yellowFlag(type, arguments*) {
		if (this.Warnings["YellowFlags"] && this.Speaker && !this.SpotterSpeaking) {
			this.SpotterSpeaking := true
			
			try {
				switch type {
					case "Full":
						this.getSpeaker(true).speakPhrase("YellowFull")
					case "Sector":
						if (arguments.Length() > 1)
							this.getSpeaker(true).speakPhrase("YellowDistance", {sector: arguments[1], distance: arguments[2]})
						else
							this.getSpeaker(true).speakPhrase("YellowSector", {sector: arguments[1]})
					case "Clear":
						this.getSpeaker(true).speakPhrase("YellowClear")
					case "Ahead":
						this.getSpeaker(true).speakPhrase("YellowAhead")
				}
			}
			finally {
				this.SpotterSpeaking := false
			}
		}
	}
	
	blueFlag() {
		if (this.Warnings["BlueFlags"] && this.Speaker && !this.SpotterSpeaking) {
			this.SpotterSpeaking := true
			
			try {
				delta := this.KnowledgeBase.getValue("Position.Standings.Behind.Delta", false)
				
				if (delta && (delta < 2000))
					this.getSpeaker(true).speakPhrase("BlueForPosition")
				else
					this.getSpeaker(true).speakPhrase("Blue")
			}
			finally {
				this.SpotterSpeaking := false
			}
		}
	}
	
	pitWindow(state) {
		if (this.Warnings["PitWindow"] && this.Speaker && !this.SpotterSpeaking && (this.Session = kSessionRace)) {
			this.SpotterSpeaking := true
			
			try {
				if (state = "Open")
					this.getSpeaker(true).speakPhrase("PitWindowOpen")
				else if (state = "Closed")
					this.getSpeaker(true).speakPhrase("PitWindowClosed")
			}
			finally {
				this.SpotterSpeaking := false
			}
		}
	}
	
	startupSpotter() {
		if !this.iSpotterPID {
			code := this.SettingsDatabase.getSimulatorCode(this.Simulator)
			
			exePath := (kBinariesDirectory . code . " SHM Spotter.exe")
			
			if FileExist(exePath) {
				this.shutdownSpotter()
				
				Run %exePath%, %kBinariesDirectory%, Hide UseErrorLevel, spotterPID
				
				if ((ErrorLevel != "Error") && spotterPID)
					this.iSpotterPID := spotterPID
			}
		}
	}
	
	shutdownSpotter() {
		if this.iSpotterPID {
			spotterPID := this.iSpotterPID
			
			Process Close, %spotterPID%
		}
		
		processName := (this.SettingsDatabase.getSimulatorCode(this.Simulator) . " SHM Spotter.exe")
		
		tries := 5
		
		while (tries-- > 0) {
			Process Exist, %processName%
		
			if ErrorLevel {
				Process Close, %ErrorLevel%
				
				Sleep 500
			}
			else
				break
		}
		
		this.iSpotterPID := false
	}
				
	createSession(settings, data) {
		local facts := base.createSession(settings, data)
		
		simulatorName := this.SettingsDatabase.getSimulatorName(facts["Session.Simulator"])
		configuration := this.Configuration
		settings := this.Settings
		
		facts["Session.Settings.Lap.Learning.Laps"] := getConfigurationValue(configuration, "Race Spotter Analysis", simulatorName . ".LearningLaps", 1)
		facts["Session.Settings.Lap.History.Considered"] := getConfigurationValue(configuration, "Race Spotter Analysis", simulatorName . ".ConsideredHistoryLaps", 5)
		facts["Session.Settings.Lap.History.Damping"] := getConfigurationValue(configuration, "Race Spotter Analysis", simulatorName . ".HistoryLapsDamping", 0.2)
		
		return facts
	}
	
	updateSession(settings) {
		local knowledgeBase := this.KnowledgeBase
		local facts
		
		if knowledgeBase {
			if !IsObject(settings)
				settings := readConfiguration(settings)
			
			facts := {}
			
			for key, value in facts
				knowledgeBase.setFact(key, value)
			
			base.updateSession(settings)
		}
	}
	
	initializeWarnings(data) {
		simulator := getConfigurationValue(data, "Session Data", "Simulator", "Unknown")
		simulatorName := this.SettingsDatabase.getSimulatorName(simulator)
		
		if (!this.Warnings || (this.Warnings.Count() = 0)) {
			configuration := this.Configuration
			
			warnings := {}
			
			for ignore, key in ["SideProximity", "RearProximity", "YellowFlags", "BlueFlags"
							  , "StartSummary", "FinalLaps", "PitWindow"] 
				warnings[key] := getConfigurationValue(configuration, "Race Spotter Announcements", simulatorName . "." . key, true)
				
			default := getConfigurationValue(configuration, "Race Spotter Announcements", this.Simulator . ".PerformanceUpdates", 2)
			
			warnings["DistanceInformation"] := getConfigurationValue(configuration, "Race Spotter Announcements", simulatorName . ".DistanceInformation", default)
			
			this.updateConfigurationValues({Warnings: warnings})
		}
	}
	
	initializeGridPosition(data) {
		driver := getConfigurationValue(data, "Position Data", "Driver.Car", false)
		
		if driver
			this.iGridPosition := getConfigurationValue(data, "Position Data", "Car." . driver . ".Position")
	}
	
	prepareSession(settings, data) {
		base.prepareSession(settings, data)
		
		this.initializeWarnings(data)
		this.initializeGridPosition(data)
		
		if this.Speaker
			this.getSpeaker(true).speakPhrase("Greeting")
		
		callback := ObjBindMethod(this, "startupSpotter")
		
		SetTimer %callback%, -10000
	}
	
	startSession(settings, data) {
		local facts
		
		joined := (!this.Warnings || (this.Warnings.Count() = 0))
		
		if !IsObject(settings)
			settings := readConfiguration(settings)
		
		if !IsObject(data)
			data := readConfiguration(data)
		
		if joined {
			this.initializeWarnings(data)
			
			if this.Speaker
				this.getSpeaker(true).speakPhrase("Greeting")
		}
		
		facts := this.createSession(settings, data)
		
		simulatorName := this.Simulator
		configuration := this.Configuration
		
		Process Exist, Race Engineer.exe
		
		if (ErrorLevel > 0)
			saveSettings := kNever
		else {
			Process Exist, Race Strategist.exe
		
			if (ErrorLevel > 0)
				saveSettings := kNever
			else
				saveSettings := getConfigurationValue(configuration, "Race Assistant Shutdown", simulatorName . ".SaveSettings")
		}
		
		this.updateConfigurationValues({LearningLaps: getConfigurationValue(configuration, "Race Spotter Analysis", simulatorName . ".LearningLaps", 1)
									  , SaveSettings: saveSettings})
		
		this.updateDynamicValues({KnowledgeBase: this.createKnowledgeBase(facts)
							    , BestLapTime: 0, OverallTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0
								, EnoughData: false})
		
		this.iFinalLapsAnnounced := false
		this.iLastDistanceInformationLap := false
		this.iRaceStartSummarized := false
		
		if joined {
			callback := ObjBindMethod(this, "startupSpotter")
		
			SetTimer %callback%, -10000
		}
		else
			this.startupSpotter()
		
		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(this.KnowledgeBase)
	}
	
	finishSession(shutdown := true) {
		local knowledgeBase := this.KnowledgeBase
		
		if knowledgeBase {
			if (shutdown && (knowledgeBase.getValue("Lap", 0) > this.LearningLaps)) {
				this.shutdownSession("Before")
				
				if this.Listener {
					asked := true
					
					if ((this.SaveSettings == kAsk) && (this.Session == kSessionRace))
						this.getSpeaker(true).speakPhrase("ConfirmSaveSettings", false, true)
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
			
			this.shutdownSpotter()
			
			this.updateDynamicValues({KnowledgeBase: false})
		}
		
		this.updateDynamicValues({OverallTime: 0, BestLapTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false})
		this.updateSessionValues({Simulator: "", Session: kSessionFinished, SessionTime: false})
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
	
	prepareData(lapNumber, data) {
		local knowledgeBase
		
		data := base.prepareData(lapNumber, data)
		
		knowledgeBase := this.KnowledgeBase
		
		for key, value in getConfigurationSectionValues(data, "Position Data", Object())
			knowledgeBase.setFact(key, value)
		
		return data
	}
	
	addLap(lapNumber, data) {
		result := base.addLap(lapNumber, data)
		
		if result
			this.iDriverUpdate := 4
	
		return result
	}
	
	updateLap(lapNumber, data) {
		if (this.iDriverUpdate > 0)
			this.iDriverUpdate := (this.iDriverUpdate - 1)
		
		if (this.iDriverUpdate = 1) {
			this.iDriverUpdate := 0
			
			this.KnowledgeBase.addFact("Sector", true)
			
			update := true
		}
		else
			update := false
		
		result := base.updateLap(lapNumber, data)
		
		if update
			this.updateDriver()
		
		return result
	}
	
	requestInformation(category, arguments*) {
		switch category {
			case "Time":
				this.timeRecognized([])
			case "Position":
				this.positionRecognized([])
			case "LapTimes":
				this.lapTimesRecognized([])
			case "GapToFrontStandings":
				this.gapToFrontRecognized([])
			case "GapToFrontTrack":
				this.gapToFrontRecognized(["Car"])
			case "GapToFront":
				this.gapToFrontRecognized(inList(arguments, "Track") ? Array(this.getSpeaker(true).Fragments["Car"]) : [])
			case "GapToBehindStandings":
				this.gapToBehindRecognized([])
			case "GapToBehindTrack":
				this.gapToBehindRecognized(["Car"])
			case "GapToBehind":
				this.gapToBehindRecognized(inList(arguments, "Track") ? Array(this.getSpeaker(true).Fragments["Car"]) : [])
			case "GapToLeader":
				this.gapToLeaderRecognized([])
		}
	}
	
	shutdownSession(phase) {
		this.iSessionDataActive := true
		
		try {
			if ((this.Session == kSessionRace) && (this.SaveSettings = ((phase = "Before") ? kAlways : kAsk)))
				this.saveSessionSettings()
		}
		finally {
			this.iSessionDataActive := false
		}
		
		if (phase = "After") {
			this.updateDynamicValues({KnowledgeBase: false})
			
			this.finishSession()
		}
	}
}