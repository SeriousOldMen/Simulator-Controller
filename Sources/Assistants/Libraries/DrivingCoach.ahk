﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - AI Driving Coach                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2024) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                        Global Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Framework\Framework.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Libraries\Task.ahk"
#Include "..\..\Libraries\JSON.ahk"
#Include "..\..\Libraries\HTTP.ahk"
#Include "..\..\Libraries\LLMConnector.ahk"
#Include "RaceAssistant.ahk"
#Include "..\..\Database\Libraries\SessionDatabase.ahk"
#Include "..\..\Database\Libraries\TelemetryCollector.ahk"
#Include "..\..\Garage\Libraries\IssueCollector.ahk"
#Include "..\..\Garage\Libraries\IRCIssueCollector.ahk"
#Include "..\..\Garage\Libraries\R3EIssueCollector.ahk"
#Include "TelemetryAnalyzer.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class DrivingCoach extends GridRaceAssistant {
	iConnector := false
	iConnectionState := "Active"

	iTemplates := false

	iInstructions := CaseInsenseWeakMap()

	iLaps := Map()
	iLapsHistory := 0

	iStandings := []

	iIssueCollector := false

	iTranscript := false

	iCoachingActive := false
	iAvailableTelemetry := CaseInsenseMap()

	iTelemetryAnalyzer := false
	iTelemetryCollector := false
	iCollectorTask := false

	iCornerTriggerPID := false

	class CoachVoiceManager extends RaceAssistant.RaceVoiceManager {
	}

	class DrivingCoachRemoteHandler extends RaceAssistant.RaceAssistantRemoteHandler {
		__New(remotePID) {
			super.__New("Driving Coach", remotePID)
		}

		serviceState(arguments*) {
			this.callRemote("serviceState", arguments*)
		}
	}

	Knowledge {
		Get {
			static knowledge := choose(super.Knowledge, (t) => !inList(["Standings", "Positions"], t))

			return knowledge
		}
	}

	CollectorClass {
		Get {
			switch SessionDatabase.getSimulatorCode(this.Simulator), false {
				case "IRC":
					return "IRCIssueCollector"
				case "R3E":
					return "R3EIssueCollector"
				default:
					return "IssueCollector"
			}
		}
	}

	Providers {
		Get {
			return LLMConnector.Providers
		}
	}

	Templates[language?] {
		Get {
			local templates, fileName, code, ignore

			if !this.iTemplates {
				templates := CaseInsenseMap()

				for code, ignore in availableLanguages() {
					fileName := getFileName("Driving Coach.instructions." . code, kTranslationsDirectory)

					if FileExist(fileName) {
						templates[code] := readMultiMap(fileName)

						fileName := getFileName("Driving Coach.instructions." . code, kUserTranslationsDirectory)

						if FileExist(fileName)
							addMultiMapValues(templates[code], readMultiMap(fileName))
					}
					else {
						fileName := getFileName("Driving Coach.instructions." . code, kUserTranslationsDirectory)

						if FileExist(fileName)
							templates[code] := readMultiMap(fileName)
					}
				}

				this.iTemplates := templates
			}

			return (isSet(language) ? this.iTemplates[language] : this.iTemplates)
		}
	}

	Instructions[type?] {
		Get {
			if isSet(type) {
				if (type == true)
					return ["Character", "Simulation", "Session", "Stint", "Knowledge", "Handling", "Coaching", "Coaching.Lap", "Coaching.Corner", "Coaching.Corner.Short"]
				else
					return (this.iInstructions.Has(type) ? this.iInstructions[type] : false)
			}
			else
				return this.iInstructions
		}

		Set {
			return (isSet(type) ? (this.iInstructions[type] := value) : (this.iInstructions := value))
		}
	}

	Connector {
		Get {
			return this.iConnector
		}
	}

	ConnectionState {
		Get {
			return this.iConnectionState
		}

		Set {
			return (this.iConnectionState := value)
		}
	}

	Transcript {
		Get {
			return this.iTranscript
		}
	}

	Laps[lapNumber?] {
		Get {
			if isSet(lapNumber) {
				lapNumber := (lapNumber + 0)

				return (this.iLaps.Has(lapNumber) ? this.iLaps[lapNumber] : false)
			}
			else
				return this.iLaps
		}

		Set {
			if isSet(lapNumber) {
				lapNumber := (lapNumber + 0)

				return (this.iLaps[lapNumber] := value)
			}
			else
				return this.iLaps := value
		}
	}

	LapsHistory {
		Get {
			return this.iLapsHistory
		}
	}

	Standings[position?] {
		Get {
			return (isSet(position) ? this.iStandings[position] : this.iStandings)
		}

		Set {
			return (isSet(position) ? (this.iStandings[position] := value) : (this.iStandings := value))
		}
	}

	CoachingActive {
		Get {
			return this.iCoachingActive
		}
	}

	AvailableTelemetry {
		Get {
			return this.iAvailableTelemetry
		}
	}

	TelemetryAnalyzer {
		Get {
			return this.iTelemetryAnalyzer
		}
	}

	TelemetryCollector {
		Get {
			return this.iTelemetryCollector
		}
	}

	CollectorTask {
		Get {
			return this.iCollectorTask
		}
	}

	__New(configuration, remoteHandler, name := false, language := kUndefined
		, synthesizer := false, speaker := false, vocalics := false, speakerBooster := false
		, recognizer := false, listener := false, listenerBooster := false, conversationBooster := false, agentBooster := false
		, muted := false, voiceServer := false) {
		super.__New(configuration, "Driving Coach", remoteHandler, name, language, synthesizer, speaker, vocalics, speakerBooster
												  , recognizer, listener, listenerBooster, conversationBooster, agentBooster
												  , muted, voiceServer)

		this.updateConfigurationValues({Announcements: {SessionInformation: true, StintInformation: false, HandlingInformation: false}})

		DirCreate(this.Options["Driving Coach.Archive"])

		OnExit(ObjBindMethod(this, "stopIssueCollector"))
		OnExit((*) {
			if this.TelemetryCollector
				this.TelemetryCollector.shutdown()
		})
		OnExit(ObjBindMethod(this, "shutdownCornerTrigger", true))
	}

	loadFromConfiguration(configuration) {
		local options, laps, ignore, instruction

		super.loadFromConfiguration(configuration)

		options := this.Options

		options["Driving Coach.Archive"] := getMultiMapValue(configuration, "Driving Coach Conversations", "Archive", kTempDirectory . "Conversations")

		if (!options["Driving Coach.Archive"] || (options["Driving Coach.Archive"] = ""))
			options["Driving Coach.Archive"] := (kTempDirectory . "Conversations")

		options["Driving Coach.Service"] := getMultiMapValue(configuration, "Driving Coach Service", "Service", getMultiMapValue(configuration, "Driving Coach", "Service", false))
		options["Driving Coach.Model"] := getMultiMapValue(configuration, "Driving Coach Service", "Model", false)
		options["Driving Coach.MaxTokens"] := getMultiMapValue(configuration, "Driving Coach Service", "MaxTokens", 2048)
		options["Driving Coach.Temperature"] := getMultiMapValue(configuration, "Driving Coach Personality", "Temperature", 0.5)

		if (string2Values("|", options["Driving Coach.Service"])[1] = "LLM Runtime")
			options["Driving Coach.GPULayers"] := getMultiMapValue(configuration, "Driving Coach Service", "GPULayers", 0)

		options["Driving Coach.MaxHistory"] := getMultiMapValue(configuration, "Driving Coach Personality", "MaxHistory", 3)
		options["Driving Coach.Confirmation"] := getMultiMapValue(configuration, "Driving Coach Personality", "Confirmation", true)

		for ignore, instruction in this.Instructions[true]
			if (getMultiMapValue(configuration, "Driving Coach Personality", "Instructions." . instruction, kUndefined) != kUndefined)
				options["Driving Coach.Instructions." . instruction] := getMultiMapValue(configuration, "Driving Coach Personality", "Instructions." . instruction, false)
			else
				options["Driving Coach.Instructions." . instruction] := getMultiMapValue(this.Templates[options["Language"]], "Instructions", instruction)

		laps := InStr(options["Driving Coach.Instructions.Stint"], "%laps:")

		if laps {
			laps := SubStr(options["Driving Coach.Instructions.Stint"], laps + 1, InStr(options["Driving Coach.Instructions.Stint"], "%", false, laps + 1) - laps - 1)

			options["Driving Coach.Instructions.Stint"] := StrReplace(options["Driving Coach.Instructions.Stint"], laps, "laps")

			this.iLapsHistory := string2Values(":", laps)[2]
		}
	}

	createVoiceManager(name, options) {
		return DrivingCoach.CoachVoiceManager(this, name, options)
	}

	updateSessionValues(values) {
		super.updateSessionValues(values)

		if values.HasProp("Laps")
			this.iLaps := values.Laps
		else if values.HasProp("Standings")
			this.iStandings := values.Standings

		if (values.HasProp("Session") && (values.Session == kSessionFinished) && (this.Session != kSessionFinished))
			if this.CoachingActive
				this.shutdownCoaching()
	}

	connectorState(state, reason := false, arguments*) {
		local oldState := this.ConnectionState

		if (state = "Active")
			this.ConnectionState := state
		else if (state = "Error")
			this.ConnectionState := (state . (reason ? (":" . reason) : ""))
		else
			this.ConnectionState := "Unknown"

		if ((oldState != this.ConnectionState) && this.RemoteHandler)
			this.RemoteHandler.serviceState((this.ConnectionState = "Active") ? "Available" : this.ConnectionState)
	}

	getInstruction(category) {
		local knowledgeBase := this.KnowledgeBase
		local settingsDB := this.SettingsDatabase
		local simulator, car, track, position, hasSectorTimes, laps, lapData, ignore, carData, standingsData
		local collector, issues, handling, ignore, type, speed, where, issue, index
		local key, value, text, filter

		static sessions := false

		if !sessions {
			sessions := ["Other", "Practice", "Qualifying", "Race"]

			sessions.Default := "Other"
		}

		switch category, false {
			case "Character":
				return substituteVariables(this.Instructions["Character"], {name: this.VoiceManager.Name})
			case "Simulation":
				if knowledgeBase {
					simulator := knowledgeBase.getValue("Session.Simulator")
					car := knowledgeBase.getValue("Session.Car")
					track := knowledgeBase.getValue("Session.Track")

					if (simulator && car && track)
						return substituteVariables(this.Instructions["Simulation"]
												 , {name: this.VoiceManager.Name
												  , driver: this.DriverForName
												  , simulator: settingsDB.getSimulatorName(simulator)
												  , car: settingsDB.getCarName(simulator, car)
												  , track: settingsDB.getTrackName(simulator, track)})
				}
			case "Session":
				if (knowledgeBase && this.Announcements["SessionInformation"]) {
					position := this.GridPosition

					if (position != 0)
						return substituteVariables(this.Instructions["Session"]
												 , {session: translate(sessions[this.Session])
												  , carNumber: this.getNr()
												  , classPosition: this.GridPosition["Class"], overallPosition: position})
				}
			case "Stint":
				if (knowledgeBase && this.Announcements["StintInformation"]) {
					position := this.getPosition(false, "Class")

					if ((position != 0) && (this.Laps.Count > 0)) {
						lapData := ""

						laps := bubbleSort(&laps := getKeys(this.Laps))

						hasSectorTimes := false

						for ignore, lap in laps
							if this.Laps[lap].SectorTimes {
								hasSectorTimes := true

								break
							}

						if hasSectorTimes
							lapData .= (values2String(";", collect(["Lap", "Position (Overall)", "Position (Class)", "Sector Times", "Lap Time"], translate)*) . "`n")
						else
							lapData .= (values2String(";", collect(["Lap", "Position (Overall)", "Position (Class)", "Lap Time"], translate)*) . "`n")

						for ignore, lap in laps {
							carData := this.Laps[lap]

							if (A_Index > 1)
								lapData .= "`n"

							if hasSectorTimes
								lapData .= values2String(";", lap, carData.OverallPosition, carData.ClassPosition
																 , carData.SectorTimes ? values2String(",", carData.SectorTimes*) : "", carData.LapTime)
							else
								lapData .= values2String(";", lap, carData.OverallPosition, carData.ClassPosition, carData.LapTime)
						}

						standingsData := ""

						hasSectorTimes := false

						for position, carData in this.Standings
							if carData.SectorTimes {
								hasSectorTimes := true

								break
							}

						if hasSectorTimes
							standingsData .= (values2String(";", collect(["Position (Overall)", "Position (Class)", "Race Number", "Class", "Sector Times", "Lap Time"], translate)*) . "`n")
						else
							standingsData .= (values2String(";", collect(["Position (Overall)", "Position (Class)", "Race Number", "Class", "Lap Time"], translate)*) . "`n")

						for ignore, carData in this.Standings {
							if (A_Index > 1)
								standingsData .= "`n"

							if hasSectorTimes
								standingsData .= values2String(";", carData.OverallPosition, carData.ClassPosition, carData.Nr, carData.Class
																  , carData.SectorTimes ? values2String(",", carData.SectorTimes*) : "", carData.LapTime)
							else
								standingsData .= values2String(";", carData.OverallPosition, carData.ClassPosition, carData.Nr, carData.Class, carData.LapTime)
						}

						return substituteVariables(this.Instructions["Stint"], {lap: knowledgeBase.getValue("Lap"), position: position, carNumber: this.getNr()
																			  , laps: lapData, standings: standingsData})
					}
				}
			case "Knowledge":
				if knowledgeBase
					return substituteVariables(this.Instructions["Knowledge"], {knowledge: StrReplace(JSON.print(this.getKnowledge("Conversation")), "%", "\%")})
			case "Handling":
				if (knowledgeBase && this.Announcements["HandlingInformation"]) {
					collector := this.iIssueCollector

					if collector {
						issues := collector.Handling

						handling := ""
						index := 0

						for ignore, type in ["Oversteer", "Understeer"]
							for ignore, speed in ["Slow", "Fast"]
								for ignore, where in ["Entry", "Apex", "Exit"]
									for ignore, issue in issues[type . ".Corner." . where . "." . speed] {
										if (++index > 1)
											handling .= "`n"

										handling .= ("- " . substituteVariables(translate("%severity% %type% at %speed% corner %where%")
																			  , {severity: translate(issue.Severity . A_Space)
																			   , type: translate(type . A_Space), speed: translate(speed . A_Space)
																			   , where: where . A_Space}))
									}

						if index
							return substituteVariables(this.Instructions["Handling"], {handling: handling})
					}
				}
			case "Coaching":
				if ((knowledgeBase || isDebug()) && this.CoachingActive)
					return substituteVariables(this.Instructions["Coaching"], {name: this.VoiceManager.Name})
		}

		return false
	}

	getInstructions() {
		return choose(collect(this.Instructions[true], ObjBindMethod(this, "getInstruction"))
					, (instruction) => (instruction && (Trim(instruction) != "")))
	}

	getTools() {
		return []
	}

	startConversation() {
		local service := this.Options["Driving Coach.Service"]
		local ignore, instruction

		this.iTranscript := (normalizeDirectoryPath(this.Options["Driving Coach.Archive"]) . "\" . translate("Conversation ") . A_Now . ".txt")

		if service {
			service := string2Values("|", service)

			if !inList(this.Providers, service[1])
				throw "Unsupported service detected in DrivingCoach.startConversation..."

			if (service[1] = "LLM Runtime")
				this.iConnector := LLMConnector.LLMRuntimeConnector(this, this.Options["Driving Coach.Model"]
																		, this.Options["Driving Coach.GPULayers"])
			else
				try {
					this.iConnector := LLMConnector.%StrReplace(service[1], A_Space, "")%Connector(this, this.Options["Driving Coach.Model"])

					this.Connector.Connect(service[2], service[3])

					this.connectorState("Active")
				}
				catch Any as exception {
					logError(exception)

					this.connectorState("Error", "Configuration")

					throw "Unsupported service detected in DrivingCoach.startConversation..."
				}

			this.Connector.MaxTokens := this.Options["Driving Coach.MaxTokens"]
			this.Connector.Temperature := this.Options["Driving Coach.Temperature"]
			this.Connector.MaxHistory := this.Options["Driving Coach.MaxHistory"]

			for ignore, instruction in this.Instructions[true] {
				this.Instructions[instruction] := this.Options["Driving Coach.Instructions." . instruction]

				if !this.Instructions[instruction]
					this.Instructions[instruction] := ""
			}
		}
		else
			throw "Unsupported service detected in DrivingCoach.startConversation..."
	}

	restartConversation() {
		if this.Connector
			this.Connector.Restart()
	}

	handleVoiceCommand(grammar, words) {
		switch grammar, false {
			case "CoachingStart":
				this.coachingStartRecognized(words)
			case "CoachingFinish":
				this.coachingFinishRecognized(words)
			case "ReviewCorner":
				if this.CoachingActive
					this.reviewCornerRecognized(words)
				else
					this.handleVoiceText("TEXT", values2String(A_Space, words*))
			case "ReviewLap":
				if this.CoachingActive
					this.reviewLapRecognized(words)
				else
					this.handleVoiceText("TEXT", values2String(A_Space, words*))
			case "LiveCoachingStart":
				if this.CoachingActive
					this.liveCoachingStartRecognized(words)
				else
					this.handleVoiceText("TEXT", values2String(A_Space, words*))
			case "LiveCoachingFinish":
				if this.CoachingActive
					this.liveCoachingFinishRecognized(words)
				else
					this.handleVoiceText("TEXT", values2String(A_Space, words*))
			default:
				super.handleVoiceCommand(grammar, words)
		}
	}

	coachingStartRecognized(words) {
		this.getSpeaker().speakPhrase("ConfirmCoaching")

		this.iCoachingActive := true
	}

	coachingFinishRecognized(words) {
		this.getSpeaker().speakPhrase("Roger")

		this.shutdownCoaching()
	}

	reviewCornerRecognized(words) {
		local corner := this.getNumber(words)
		local telemetry := this.getLapsTelemetry(3, corner)

		if (this.TelemetryAnalyzer && (telemetry.Length > 0))
			this.handleVoiceText("TEXT", substituteVariables(this.Instructions["Coaching.Corner"]
														   , {telemetry: values2String("`n`n", collect(telemetry, (t) => t.JSON)*)
															, corner: corner}))
		else
			this.getSpeaker().speakPhrase("Later")
	}

	reviewLapRecognized(words) {
		local telemetry := this.getLapsTelemetry(3)

		if (this.TelemetryAnalyzer && (telemetry.Length > 0))
			this.handleVoiceText("TEXT", substituteVariables(this.Instructions["Coaching.Lap"]
														   , {telemetry: values2String("`n`n", collect(telemetry, (t) => t.JSON)*)}))
		else
			this.getSpeaker().speakPhrase("Later")
	}

	liveCoachingStartRecognized(words) {
		if this.startupCornerTrigger()
			this.getSpeaker().speakPhrase("Roger")
		else
			this.getSpeaker().speakPhrase("Later")
	}

	liveCoachingFinishRecognized(words) {
		this.getSpeaker().speakPhrase("Okay")

		this.shutdownCornerTrigger()
	}

	handleVoiceText(grammar, text, reportError := true) {
		local answer := false
		local ignore, part

		static report := true

		try {
			if (this.Speaker && this.Options["Driving Coach.Confirmation"] && (this.ConnectionState = "Active"))
				this.getSpeaker().speakPhrase("Confirm", false, false, false, {Noise: false})

			if !this.Connector
				this.startConversation()

			answer := this.Connector.Ask(text)

			if answer
				report := true
			else if (this.Speaker && report) {
				if reportError
					this.getSpeaker().speakPhrase("Later", false, false, false, {Noise: false})

				report := false
			}
		}
		catch Any as exception {
			if report {
				if (this.Speaker && reportError)
					this.getSpeaker().speakPhrase("Later", false, false, false, {Noise: false})

				report := false

				logError(exception, true)

				logMessage(kLogCritical, substituteVariables(translate("Cannot connect to GPT service (%service%) - please check the configuration")
														   , {service: this.Options["Driving Coach.Service"]}))

				showMessage(substituteVariables(translate("Cannot connect to GPT service (%service%) - please check the configuration...")
											  , {service: this.Options["Driving Coach.Service"]})
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
		}

		if answer {
			answer := StrReplace(answer, "*", "")

			if this.Speaker
				if this.VoiceManager.UseTalking
					this.getSpeaker().speak(answer, false, false, {Noise: false, Rephrase: false})
				else
					for ignore, part in string2Values(". ", answer)
						this.getSpeaker().speak(part . ".", false, false, {Noise: false, Rephrase: false, Click: (A_Index = 1)})

			if this.Transcript
				FileAppend(translate("-- Driver --------") . "`n`n" . text . "`n`n" . translate("-- Coach ---------") . "`n`n" . answer . "`n`n", this.Transcript, "UTF-16")
		}
	}

	stopIssueCollector(arguments*) {
		if ((arguments.Length > 0) && inList(["Logoff", "Shutdown"], arguments[1]))
			return false

		this.stopIssueAnalyzer()

		if this.iIssueCollector {
			this.iIssueCollector.deleteSamples()

			this.iIssueCollector := false
		}

		return false
	}

	startIssueAnalyzer() {
		local knowledgeBase := this.KnowledgeBase

		this.stopIssueCollector()

		if knowledgeBase {
			this.iIssueCollector := %this.CollectorClass%(this.Simulator, knowledgeBase.getValue("Session.Car"), knowledgeBase.getValue("Session.Track")
															, {Handling: true, Frequency: 5000})

			this.iIssueCollector.loadFromSettings()

			this.iIssueCollector.startIssueCollector()
		}

		return this.iIssueCollector
	}

	stopIssueAnalyzer() {
		if this.iIssueCollector
			this.iIssueCollector.stopIssueCollector()
	}

	startCoaching() {
		this.coachingStartRecognized([])
	}

	finishCoaching() {
		this.coachingFinishRecognized([])
	}

	startupCoaching() {
		local state

		if !this.TelemetryCollector {
			this.startupTelemetryCollector()

			state := newMultiMap()

			setMultiMapValue(state, "Coaching", "Active", true)

			writeMultiMap(kTempDirectory . "Coaching.state", state)
		}
	}

	shutdownCoaching() {
		local state := newMultiMap()

		this.shutdownCornerTrigger()

		if this.TelemetryCollector
			this.shutdownTelemetryCollector()

		this.iCoachingActive := false
		this.iAvailableTelemetry := CaseInsenseMap()

		setMultiMapValue(state, "Coaching", "Active", true)

		writeMultiMap(kTempDirectory . "Coaching.state", state)
	}

	telemetryAvailable(laps) {
		local ignore, lap

		if (this.AvailableTelemetry.Count = 0)
			this.getSpeaker().speakPhrase("CoachingReady", false, true)

		for ignore, lap in laps
			this.AvailableTelemetry[lap] := true
	}

	getLapsTelemetry(numLaps, corner := false) {
		local result := []
		local laps := getKeys(this.AvailableTelemetry)
		local ignore, lap, found

		for ignore, lap in bubbleSort(&laps, (a, b) => (a < b)) {
			if ((A_Index > laps.Length) || (result.Length >= numLaps))
				break

			if (this.AvailableTelemetry[lap] == true)
				this.AvailableTelemetry[lap] := this.TelemetryAnalyzer.createTelemetry(lap, kTempDirectory . "Driving Coach\Telemetry\Lap " . lap . ".telemetry")

			if corner {
				lap := this.AvailableTelemetry[lap].Clone()

				found := false

				lap.Sections := choose(lap.Sections, (section) {
									if ((section.Type = "Corner") && (section.Nr = corner)) {
										found := true

										return true
									}
									else if found {
										found := false

										return true
									}
									else
										return false
								})

				result.Push(lap)
			}
			else
				result.Push(this.AvailableTelemetry[lap])
		}

		return result
	}

	startupTelemetryCollector() {
		local loadedLaps

		updateTelemetry() {
			local newLaps := []
			local lap

			loop Files, kTempDirectory . "Driving Coach\Telemetry\*.telemetry" {
				lap := StrReplace(StrReplace(A_LoopFileName, "Lap ", ""), ".telemetry", "")

				if !loadedLaps.Has(lap) {
					newLaps.Push(lap)

					loadedLaps[lap] := true
				}
			}

			if (newLaps.Length > 0) {
				bubbleSort(&newLaps)

				this.telemetryAvailable(newLaps)
			}
		}

		if (!this.TelemetryCollector && this.Simulator && this.Track && ((this.TrackLength > 0) || isDebug())) {
			DirCreate(kTempDirectory . "Driving Coach")
			DirCreate(kTempDirectory . "Driving Coach\Telemetry")

			if !isDebug()
				deleteDirectory(kTempDirectory . "Driving Coach\Telemetry")

			this.iTelemetryAnalyzer := TelemetryAnalyzer(this.Simulator, this.Track)
			this.iTelemetryCollector := TelemetryCollector(kTempDirectory . "Driving Coach\Telemetry", this.Simulator, this.Track, this.TrackLength)

			this.iTelemetryCollector.startup()

			loadedLaps := CaseInsenseMap()

			this.iCollectorTask := PeriodicTask(updateTelemetry, 10000, kLowPriority)

			this.iCollectorTask.start()
		}
	}

	shutdownTelemetryCollector() {
		if this.TelemetryCollector
			this.TelemetryCollector.shutdown()

		if this.iCollectorTask
			this.iCollectorTask.stop()

		this.iTelemetryAnalyzer := false
		this.iTelemetryCollector := false
		this.iCollectorTask := false
	}

	startupCornerTrigger() {
		local sections, positions, simulator, track, sessionDB, code, data, exePath, pid
		local lastSection, index, section

		if (!this.iCornerTriggerPID && this.Simulator && this.TelemetryAnalyzer) {
			sections := this.TelemetryAnalyzer.TrackSections

			if (sections && (sections.Length > 0)) {
				positions := ""

				for index, section in sections
					if (section.Type = "Corner") {
						if (index = 1)
							lastSection := sections[sections.Length]
						else if (index = sections.Length)
							lastSection := sections[1]
						else
							lastSection := sections[index - 1]

						if (lastSection.Length > 200)
							positions .= (A_Space . lastSection.X . A_Space . lastSection.Y)
						else
							positions .= (A_Space . -32700 . A_Space . -32700)
					}
					else
						positions .= (A_Space . -32700 . A_Space . -32700)

				simulator := this.Simulator
				track := this.Track

				sessionDB := SessionDatabase()

				code := sessionDB.getSimulatorCode(simulator)
				data := sessionDB.getTrackData(simulator, track)

				exePath := (kBinariesDirectory . "Providers\" . code . " SHM Spotter.exe")
				pid := false

				try {
					if !FileExist(exePath)
						throw "File not found..."

					if data
						Run("`"" . exePath . "`" -Trigger `"" . data . "`" " . positions, kBinariesDirectory, "Hide", &pid)
					else
						Run("`"" . exePath . "`" -Trigger " . positions, kBinariesDirectory, "Hide", &pid)
				}
				catch Any as exception {
					logError(exception, true)

					logMessage(kLogCritical, substituteVariables(translate("Cannot start %simulator% %protocol% Spotter (")
															   , {simulator: code, protocol: "SHM"})
										   . exePath . translate(") - please rebuild the applications in the binaries folder (")
										   . kBinariesDirectory . translate(")"))

					showMessage(substituteVariables(translate("Cannot start %simulator% %protocol% Spotter (%exePath%) - please check the configuration...")
												  , {exePath: exePath, simulator: code, protocol: "SHM"})
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}

				if pid
					this.iCornerTriggerPID := pid
			}
		}

		return (this.iCornerTriggerPID != false)
	}

	shutdownCornerTrigger(force := false, arguments*) {
		local pid := this.iCornerTriggerPID
		local tries

		if ((arguments.Length > 0) && inList(["Logoff", "Shutdown"], arguments[1]))
			return false

		if pid {
			ProcessClose(pid)

			if (force && ProcessExist(pid)) {
				Sleep(500)

				tries := 5

				while (tries-- > 0) {
					pid := ProcessExist(pid)

					if pid {
						ProcessClose(pid)

						Sleep(500)
					}
					else
						break
				}
			}

			this.iCornerTriggerPID := false
		}

		return false
	}

	prepareSession(&settings, &data, formationLap := true) {
		local prepared := this.Prepared
		local announcements := false
		local facts

		if !prepared {
			if formationLap {
				this.updateDynamicValues({KnowledgeBase: false
										, OverallTime: 0, BestLapTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false})
				this.updateSessionValues({Simulator: "", Car: "", Track: "", Session: kSessionFinished, SessionTime: false, Laps: Map(), Standings: []})
			}

			this.restartConversation()
		}

		facts := super.prepareSession(&settings, &data, formationLap)

		if (!prepared && settings) {
			this.updateConfigurationValues({UseTalking: getMultiMapValue(settings, "Assistant.Coach", "Voice.UseTalking", true)})

			if (this.Session = kSessionPractice)
				announcements := {SessionInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Practice.Session", true)
								, StintInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Practice.Stint", true)
								, HandlingInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Practice.Handling", true)}
			else if (this.Session = kSessionQualification)
				announcements := {SessionInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Qualification.Session", true)
								, StintInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Qualification.Stint", true)
								, HandlingInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Qualification.Handling", false)}
			else if (this.Session = kSessionRace)
				announcements := {SessionInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Race.Session", true)
								, StintInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Race.Stint", true)
								, HandlingInformation: getMultiMapValue(settings, "Assistant.Coach", "Data.Race.Handling", false)}

			if announcements
				this.updateConfigurationValues({Announcements: announcements})
		}

		if this.CoachingActive
			this.startupCoaching()

		return facts
	}

	startSession(settings, data) {
		local facts := this.prepareSession(&settings, &data, false)

		this.updateConfigurationValues({LearningLaps: 1, AdjustLapTime: true, SaveSettings: false})

		this.updateDynamicValues({KnowledgeBase: this.createKnowledgeBase(facts)
								, BestLapTime: 0, OverallTime: 0, LastFuelAmount: 0
								, InitialFuelAmount: 0, EnoughData: false})

		this.updateSessionValues({Standings: [], Laps: Map()})

		; this.initializeGridPosition(data)

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledgeBase(this.KnowledgeBase)

		if this.Announcements["HandlingInformation"]
			this.startIssueAnalyzer()
	}

	finishSession(shutdown := true) {
		this.stopIssueAnalyzer()
		this.updateDynamicValues({Prepared: false})
	}

	updateLaps(lapNumber, data) {
		local knowledgeBase := this.KnowledgeBase
		local driver := knowledgeBase.getValue("Driver.Car", false)
		local standingsData := CaseInsenseWeakMap()
		local standings := []
		local keys, ignore, car, carData, sectorTimes

		if driver {
			sectorTimes := this.getSectorTimes(driver)

			if sectorTimes {
				sectorTimes := sectorTimes.Clone()

				loop sectorTimes.Length
					sectorTimes[A_Index] := Round(sectorTimes[A_Index] / 1000, 1)
			}
			else
				sectorTimes := false

			this.Laps[lapNumber] := {Class: this.getClass(driver), OverallPosition: this.getPosition(driver), ClassPosition: this.getPosition(driver, "Class")
								   , SectorTimes: sectorTimes, LapTime: Round(this.getLapTime(driver) / 1000, 1)}

			for ignore, car in this.getCars() {
				sectorTimes := this.getSectorTimes(car)

				if sectorTimes {
					sectorTimes := sectorTimes.Clone()

					loop sectorTimes.Length
						sectorTimes[A_Index] := Round(sectorTimes[A_Index] / 1000, 1)
				}
				else
					sectorTimes := false

				carData := {Nr: this.getNr(car), Class: this.getClass(car)
						  , OverallPosition: this.getPosition(car), ClassPosition: this.getPosition(car, "Class")
						  , SectorTimes: sectorTimes, LapTime: Round(this.getLapTime(car) / 1000, 1)}

				standingsData[carData.OverallPosition] := carData
			}

			loop standingsData.Count
				if standingsData.Has(A_Index)
					standings.Push(standingsData[A_Index])

			this.Standings := standings
		}
	}

	addLap(lapNumber, &data) {
		local result := super.addLap(lapNumber, &data)

		this.updateLaps(lapNumber, data)

		if this.CoachingActive
			this.startupCoaching()

		return result
	}

	updateLap(lapNumber, &data, arguments*) {
		local result := super.updateLap(lapNumber, &data, arguments*)

		if this.CoachingActive
			this.startupCoaching()

		return result
	}

	positionTrigger(cornerNr, positionX, positionY) {
		local telemetry

		static lastRecommendation := false

		if ((Round(positionX) = -32700) && (Round(positionY) = -32700))
			return

		if (A_TickCount < (lastRecommendation + 20000))
			return

		telemetry := this.getLapsTelemetry(3, cornerNr)

		if (this.TelemetryAnalyzer && (telemetry.Length > 0))
			this.handleVoiceText("TEXT", substituteVariables(this.Instructions["Coaching.Corner.Short"]
														   , {telemetry: values2String("`n`n", collect(telemetry, (t) => t.JSON)*)
															, corner: cornerNr})
									   , false)
	}
}