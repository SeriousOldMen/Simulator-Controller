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

#Include ..\Libraries\Task.ahk
#Include ..\Libraries\Math.ahk
#Include ..\Libraries\RuleEngine.ahk
#Include ..\Assistants\Libraries\RaceAssistant.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Public Constant Section                          ;;;
;;;-------------------------------------------------------------------------;;;

global kDebugPositions := 4


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class CarInfo {
	iNr := false
	iCar := false
	iDriver := false

	iLastLap := false
	iLastSector := false

	iPosition := false

	iPitstops := []
	iLastPitstop := false
	iInPit := false

	iLapTimes := []

	iDeltas := {}
	iLastDeltas := {}

	iInvalidLaps := false
	iIncidents := false

	Nr[] {
		Get {
			return this.iNr
		}
	}

	Car[] {
		Get {
			return this.iCar
		}
	}

	Driver[] {
		Get {
			return this.iDriver
		}
	}

	LastLap[] {
		Get {
			return this.iLastLap
		}
	}

	Position[] {
		Get {
			return this.iPosition
		}
	}

	Pitstops[key := false] {
		Get {
			return (key ? this.iPitstops[key] : this.iPitstops)
		}
	}

	LastPitstop[] {
		Get {
			return this.iLastPitstop
		}
	}

	InPit[] {
		Get {
			return this.iInPit
		}
	}

	LapTimes[key := false] {
		Get {
			return (key ? this.iLapTimes[key] : this.iLapTimes)
		}

		Set {
			return (key ? (this.iLapTimes[key] := value) : (this.iLapTimes := value))
		}
	}

	LastLapTime[] {
		Get {
			local numLapTimes := this.LapTimes.Length()

			if (numLapTimes > 0)
				return this.LapTimes[numLapTimes]
			else
				return false
		}
	}

	AverageLapTime[count := 3] {
		Get {
			local lapTimes := []
			local numLapTimes := this.LapTimes.Length()

			loop % Min(count, numLapTimes)
				lapTimes.Push(this.LapTimes[numLapTimes - A_Index + 1])

			return Round(average(lapTimes), 1)
		}
	}

	LapTime[average := false] {
		Get {
			return (average ? this.AverageLapTime : this.LastLapTime)
		}
	}

	Deltas[sector := false, key := false] {
		Get {
			if sector {
				if this.iDeltas.HasKey(sector)
					return (key ? this.iDeltas[sector][key] : this.iDeltas[sector])
				else
					return []
			}
			else
				return this.iDeltas
		}
	}

	LastDelta[sector] {
		Get {
			return (this.iLastDeltas.HasKey(sector) ? this.iLastDeltas[sector] : false)
		}
	}

	AverageDelta[sector, count := 3] {
		Get {
			local deltas := []
			local numDeltas, sDeltas

			if sector {
				numDeltas := this.Deltas[sector].Length()

				loop % Min(count, numDeltas)
					deltas.Push(this.Deltas[sector][numDeltas - A_Index + 1])
			}
			else
				for sector, sDeltas in this.Deltas {
					numDeltas := sDeltas.Length()

					loop % Min(count, numDeltas)
						deltas.Push(sDeltas[numDeltas - A_Index + 1])
				}

			return Round(average(deltas), 1)
		}
	}

	Delta[sector, average := false, count := 3] {
		Get {
			if sector
				return (average ? this.AverageDelta[sector] : this.LastDelta[sector])
			else
				return (average ? this.AverageDelta[false, count] : this.LastDelta[sector])
		}
	}

	InvalidLaps[] {
		Get {
			return this.iInvalidLaps
		}
	}

	Incidents[] {
		Get {
			return this.iIncidents
		}
	}

	__New(nr, car) {
		this.iNr := nr
		this.iCar := car
	}

	reset() {
		this.iDeltas := {}
		this.iLastDeltas := {}
		this.iLapTimes := []
	}

	update(driver, position, lastLap, sector, lapTime, invalidLaps, incidents, delta, inPit) {
		local avgLapTime := this.AverageLapTime
		local result := true
		local deltas

		if (avgLapTime && (Abs((lapTime - avgLapTime) / avgLapTime) > 0.02)) {
			this.reset()

			result := false
		}

		this.iDriver := driver
		this.iPosition := position

		if ((lastLap > this.LastLap) && (lapTime > 0)) {
			this.LapTimes.Push(lapTime)

			if (this.LapTimes.Length() > 5)
				this.LapTimes.RemoveAt(1)

			this.iLastLap := lastLap
		}

		this.iInvalidLaps := invalidLaps
		this.iIncidents := incidents

		if (sector != this.iLastSector) {
			this.iLastSector := sector

			if this.iDeltas.HasKey(sector)
				deltas := this.iDeltas[sector]
			else {
				deltas := []

				this.iDeltas[sector] := deltas
			}

			deltas.Push(delta)

			if (deltas.Length() > 5)
				deltas.RemoveAt(1)

			this.iLastDeltas[sector] := delta
		}

		if inPit {
			if !inList(this.Pitstops, lastLap) {
				this.Pitstops.Push(lastLap)
				this.iLastPitstop := lastLap
			}

			this.iInPit := true
		}
		else
			this.iInPit := false

		return result
	}

	hasDelta(sector := false) {
		if sector
			return (this.Deltas[sector].Count() > 0)
		else
			return (this.Deltas.Count() > 0)
	}

	isFaster(sector) {
		local xValues := []
		local yValues := []
		local index, delta, a, b

		for index, delta in this.Deltas[sector] {
			xValues.Push(index)
			yValues.Push(delta)
		}

		a := false
		b := false

		linRegression(xValues, yValues, a, b)

		return (b > 0)
	}
}

class PositionInfo {
	iSpotter := false
	iCar := false

	iBaseLap := false
	iObserved := ""
	iInitialDeltas := {}

	iReported := false

	Type[] {
		Get {
			throw "Virtual property PositionInfo.Type must be implemented in a subclass..."
		}
	}

	Spotter[] {
		Get {
			return this.iSpotter
		}
	}

	Car[] {
		Get {
			return this.iCar
		}
	}

	OpponentType[] {
		Get {
			local knowledgeBase := this.Spotter.KnowledgeBase
			local lastLap := knowledgeBase.getValue("Lap")
			local position := knowledgeBase.getValue("Position")
			local nearBy := ((Abs(this.Delta[false, true, 1]) * 2) < this.DriverCar.LapTime[true])

			if ((lastLap > this.Car.LastLap) && !nearBy)
				return "LapDown"
			else if ((lastLap < this.Car.LastLap) && !nearBy)
				return "LapUp"
			else if (Abs(position - this.Car.Position) == 1)
				return "Position"
			else
				return "Position"
		}
	}

	Observed[] {
		Get {
			return this.iObserved
		}
	}

	InitialDelta[sector] {
		Get {
			local delta

			if this.iInitialDeltas.HasKey(sector)
				return this.iInitialDeltas[sector]
			else {
				delta := this.Delta[sector]

				this.iInitialDeltas[sector] := delta

				return delta
			}
		}
	}

	Delta[sector, average := false, count := 3] {
		Get {
			return this.Car.Delta[sector, average, count]
		}
	}

	DeltaDifference[sector] {
		Get {
			return (this.Delta[sector] - this.InitialDelta[sector])
		}
	}

	LapTimeDifference[average := false] {
		Get {
			return (this.Spotter.DriverCar.LapTime[average] - this.Car.LapTime[average])
		}
	}

	Reported[] {
		Get {
			return this.iReported
		}

		Set {
			return (this.iReported := value)
		}
	}

	__New(spotter, car) {
		this.iSpotter := spotter
		this.iCar := car
	}

	inDelta(sector, threshold := 2.0) {
		return (Abs(this.Delta[false, true, 1]) <= threshold)
	}

	isFaster(sector) {
		; return ((this.InitialDelta[sector] - this.Delta[Sector]) > 0)

		; return this.Car.isFaster(sector)

		return (this.LapTimeDifference[true] > 0)
	}

	hasDelta(sector) {
		return this.Car.hasDelta(sector)
	}

	closingIn(sector, threshold := 0.5) {
		local difference := this.DeltaDifference[sector]

		if this.inFront()
			return ((difference < 0) && (Abs(difference) > threshold))
		else
			return ((difference > 0) && (difference > threshold))
	}

	runningAway(sector, threshold := 2) {
		local difference := this.DeltaDifference[sector]

		if this.inFront()
			return ((difference > 0) && (difference > threshold))
		else
			return ((difference < 0) && (Abs(difference) > threshold))
	}

	isLeader() {
		return (this.Car.Position == 1)
	}

	inFront(standings := true) {
		local knowledgeBase := this.Spotter.KnowledgeBase
		local frontCar

		if standings
			return (this.Car.Position < knowledgeBase.getValue("Position"))
		else {
			frontCar := knowledgeBase.getValue("Position.Track.Ahead.Car", false)

			if frontCar
				return (this.Car.Nr = knowledgeBase.getValue("Standings.Lap." . knowledgeBase.getValue("Lap") . ".Car." . frontCar . ".Nr"))
			else
				return false
		}
	}

	atBehind(standings := true) {
		local knowledgeBase := this.Spotter.KnowledgeBase
		local behindCar

		if standings
			return (this.Car.Position > knowledgeBase.getValue("Position"))
		else {
			behindCar := knowledgeBase.getValue("Position.Track.Behind.Car", false)

			if behindCar
				return (this.Car.Nr = knowledgeBase.getValue("Standings.Lap." . knowledgeBase.getValue("Lap") . ".Car." . behindCar . ".Nr"))
			else
				return false
		}
	}

	forPosition() {
		local knowledgeBase := this.Spotter.KnowledgeBase
		local position := knowledgeBase.getValue("Position")

		if ((position - this.Car.Position) == 1)
			return "Ahead"
		else if ((position - this.Car.Position) == -1)
			return "Behind"
		else
			return false
	}

	reset(sector, full := false, inPit := false) {
		if full {
			this.Reported := false
			this.iBaseLap := this.Car.LastLap
		}

		this.iInitialDeltas := {}

		if !inPit
			this.iInitialDeltas[sector] := this.Delta[sector]
	}

	calibrate(sector) {
		if (this.Car.LastLap >= (this.iBaseLap + 3))
			this.reset(sector, true)
		else
			this.iInitialDeltas[sector] := this.Delta[sector]
	}

	checkpoint(sector) {
		local position := this.forPosition()
		local observed := ((this.isLeader() ? "L" : "") . (this.inFront(false) ? "TA" : "") . (this.atBehind(false) ? "TB" : "")
						 . ((position = "Ahead") ? "SA" : "") . ((position = "Behind") ? "SB" : ""))

		if this.Car.InPit {
			if !InStr(this.iObserved, "P")
				this.iObserved .= "P"

			this.reset(sector, true, true)
		}
		else if this.Spotter.DriverCar.InPit {
			this.reset(sector, true, true)

			this.iObserved := observed
		}
		else {
			if (observed != this.Observed) {
				if ((InStr(observed, "B") && InStr(this.Observed, "F")) || (InStr(observed, "F") && InStr(this.Observed, "B")))
					this.reset(sector, true)
				else if ((InStr(observed, "B") || InStr(observed, "F")) && (!InStr(this.Observed, "B") && !InStr(this.Observed, "F")))
					this.reset(sector, true, true)
				else
					this.Reported := false

				this.iObserved := observed
			}
			else if ((observed = "") || (observed = "L"))
				this.calibrate(sector)
		}
	}
}

class RaceSpotter extends RaceAssistant {
	iSpotterPID := false

	iSessionDataActive := false

	iGridPosition := false

	iWasStartDriver := false

	iLastDeltaInformationLap := false
	iPositionInfos := {}
	iTacticalAdvices := {}
	iSessionInfos := {}

	iDriverCar := false
	iOtherCars := {}

	iPendingAlerts := []

	class SpotterVoiceManager extends RaceAssistant.RaceVoiceManager {
		iFastSpeechSynthesizer := false

		class FastSpeaker extends VoiceManager.LocalSpeaker {
			speak(arguments*) {
				if (this.VoiceManager.RaceAssistant.Session >= kSessionPractice)
					base.speak(arguments*)
			}

			speakPhrase(phrase, arguments*) {
				if this.Awaitable {
					this.wait()

					if this.VoiceManager.RaceAssistant.skipAlert(phrase)
						return
				}

				base.speakPhrase(phrase, arguments*)
			}
		}

		getSpeaker(fast := false) {
			local synthesizer

			if fast {
				if !this.iFastSpeechSynthesizer {
					synthesizer := new this.FastSpeaker(this, this.Synthesizer, this.Speaker, this.Language
													  , this.buildFragments(this.Language), this.buildPhrases(this.Language, true))

					this.iFastSpeechSynthesizer := synthesizer

					synthesizer.setVolume(this.SpeakerVolume)
					synthesizer.setPitch(this.SpeakerPitch)
					synthesizer.setRate(this.SpeakerSpeed)

					synthesizer.SpeechStatusCallback := ObjBindMethod(this, "updateSpeechStatus")
				}

				return this.iFastSpeechSynthesizer
			}
			else
				return base.getSpeaker()
		}

		updateSpeechStatus(status) {
			if (status = "Start")
				this.mute()
			else if (status = "Stop")
				this.unmute()
		}

		buildPhrases(language, fast := false) {
			if fast
				return base.buildPhrases(language, "Spotter Phrases")
			else
				return base.buildPhrases(language)
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

	DriverCar[] {
		Get {
			return this.iDriverCar
		}
	}

	OtherCars[key := false] {
		Get {
			return (key ? this.iOtherCars[key] : this.iOtherCars)
		}

		Set {
			return (key ? (this.iOtherCars[key] := value) : (this.iOtherCars := value))
		}
	}

	GridPosition[] {
		Get {
			return this.iGridPosition
		}
	}

	PositionInfos[key := false] {
		Get {
			return (key ? this.iPositionInfos[key] : this.iPositionInfos)
		}

		Set {
			return (key ? (this.iPositionInfos[key] := value) : (this.iPositionInfos := value))
		}
	}

	TacticalAdvices[key := false] {
		Get {
			return (key ? this.iTacticalAdvices[key] : this.iTacticalAdvices)
		}

		Set {
			return (key ? (this.iTacticalAdvices[key] := value) : (this.iTacticalAdvices := value))
		}
	}

	SessionInfos[key := false] {
		Get {
			return (key ? this.iSessionInfos[key] : this.iSessionInfos)
		}

		Set {
			return (key ? (this.iSessionInfos[key] := value) : (this.iSessionInfos := value))
		}
	}

	__New(configuration, remoteHandler, name := false, language := "__Undefined__"
		, synthesizer := false, speaker := false, vocalics := false, recognizer := false, listener := false, voiceServer := false) {
		base.__New(configuration, "Race Spotter", remoteHandler, name, language, synthesizer, speaker, vocalics, recognizer, listener, voiceServer)

		if isDebug() {
			this.setDebug(kDebugKnowledgeBase, true)
			this.setDebug(kDebugPositions, true)
		}

		this.updateConfigurationValues({Announcements: {DeltaInformation: 2, TacticalAdvices: true
													  , SideProximity: true, RearProximity: true
		 											  , YellowFlags: true, BlueFlags: true, PitWindow: true
													  , SessionInformation: true}})

		OnExit(ObjBindMethod(this, "shutdownSpotter", true))
	}

	setDebug(option, enabled) {
		local label := false

		base.setDebug(option, enabled)

		switch option {
			case kDebugPositions:
				label := translate("Debug Positions")
		}

		if label
			if enabled
				Menu SupportMenu, Check, %label%
			else
				Menu SupportMenu, Uncheck, %label%
	}

	createVoiceManager(name, options) {
		return new this.SpotterVoiceManager(this, name, options)
	}

	updateSessionValues(values) {
		base.updateSessionValues(values)

		if (values.HasKey("Session") && (values["Session"] == kSessionFinished)) {
			this.iLastDeltaInformationLap := false

			this.iDriverCar := false
			this.OtherCars := {}
			this.PositionInfos := {}
			this.TacticalAdvices := {}
			this.SessionInfos := {}
		}
	}

	updateDynamicValues(values) {
		if (values.HasKey("BaseLap") && (values["BaseLap"] != this.BaseLap))
			this.SessionInfos.Delete("AirTemperature")

		base.updateDynamicValues(values)
	}

	handleVoiceCommand(grammar, words) {
		switch grammar {
			case "Position":
				this.positionRecognized(words)
			case "LapTimes":
				this.lapTimesRecognized(words)
			case "GapToAhead":
				this.gapToAheadRecognized(words)
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
		local speaker := this.getSpeaker()
		local position := Round(knowledgeBase.getValue("Position", 0))

		if (position == 0)
			speaker.speakPhrase("Later")
		else if inList(words, speaker.Fragments["Laps"])
			this.futurePositionRecognized(words)
		else {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("Position", {position: position})

				if (position <= 3)
					speaker.speakPhrase("Great")
			}
			finally {
				speaker.endTalk()
			}
		}
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
		local speaker := this.getSpeaker()
		local delta := Abs(knowledgeBase.getValue("Position.Track.Ahead.Delta", 0))
		local car := knowledgeBase.getValue("Position.Track.Ahead.Car")
		local lap, driverLap, otherLap

		if ((delta != 0) && !knowledgeBase.getValue("Car." . car . ".InPitLane")) {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("TrackGapToAhead", {delta: printNumber(delta / 1000, 1)})

				lap := knowledgeBase.getValue("Lap")
				driverLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Driver.Car") . ".Laps"))
				otherLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Position.Track.Ahead.Car") . ".Laps"))

				if (driverLap < otherLap)
				  speaker.speakPhrase("NotTheSameLap")
			}
			finally {
				speaker.endTalk()
			}
		}
		else
			speaker.speakPhrase("NoTrackGap")
	}

	standingsGapToAheadRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local delta, lap, car, speaker

		if (Round(knowledgeBase.getValue("Position", 0)) = 1)
			this.getSpeaker().speakPhrase("NoGapToAhead")
		else {
			speaker := this.getSpeaker()

			speaker.beginTalk()

			try {
				lap := knowledgeBase.getValue("Lap")
				delta := Abs(knowledgeBase.getValue("Position.Standings.Ahead.Delta", 0) / 1000)
				car := knowledgeBase.getValue("Position.Standings.Ahead.Car")

				if ((knowledgeBase.getValue("Car." . car . ".Lap") > lap)
					  && (Abs(delta) > (knowledgeBase.getValue("Lap." . lap . ".Time") / 1000)))
					speaker.speakPhrase("StandingsAheadLapped")
				else
					speaker.speakPhrase("StandingsGapToAhead", {delta: printNumber(delta, 1)})

				if knowledgeBase.getValue("Car." . car . ".InPitLane")
					speaker.speakPhrase("GapCarInPit")
			}
			finally {
				speaker.endTalk()
			}
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
		local speaker := this.getSpeaker()
		local delta := Abs(knowledgeBase.getValue("Position.Track.Behind.Delta", 0))
		local car := knowledgeBase.getValue("Position.Track.Behind.Car")
		local lap, driverLap, otherLap

		if ((delta != 0) && !knowledgeBase.getValue("Car." . car . ".InPitLane")) {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("TrackGapToBehind", {delta: printNumber(delta / 1000, 1)})

				lap := knowledgeBase.getValue("Lap")
				driverLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Driver.Car") . ".Laps"))
				otherLap := floor(knowledgeBase.getValue("Standings.Lap." . lap . ".Car." . knowledgeBase.getValue("Position.Track.Behind.Car") . ".Laps"))

				if (driverLap > (otherLap + 1))
				  speaker.speakPhrase("NotTheSameLap")
			}
			finally {
				speaker.endTalk()
			}
		}
		else
			speaker.speakPhrase("NoTrackGap")
	}

	standingsGapToBehindRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local delta, car, speaker, driver, lap, lapped

		if (Round(knowledgeBase.getValue("Position", 0)) = Round(knowledgeBase.getValue("Car.Count", 0)))
			this.getSpeaker().speakPhrase("NoGapToBehind")
		else {
			speaker := this.getSpeaker()

			speaker.beginTalk()

			try {
				lap := knowledgeBase.getValue("Lap")
				delta := Abs(knowledgeBase.getValue("Position.Standings.Behind.Delta", 0) / 1000)
				car := knowledgeBase.getValue("Position.Standings.Behind.Car")
				lapped := false

				if ((knowledgeBase.getValue("Car." . car . ".Lap") < lap)
					  && (Abs(delta) > (knowledgeBase.getValue("Lap." . lap . ".Time") / 1000))) {
					speaker.speakPhrase("StandingsBehindLapped")

					lapped := true
				}
				else
					speaker.speakPhrase("StandingsGapToBehind", {delta: printNumber(delta, 1)})

				if (!lapped && knowledgeBase.getValue("Car." . car . ".InPitLane"))
					speaker.speakPhrase("GapCarInPit")
			}
			finally {
				speaker.endTalk()
			}
		}
	}

	gapToLeaderRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local delta

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
		local lapTime := this.KnowledgeBase.getValue("Car." . car . ".Time", false)
		local speaker, fragments, minute, seconds, delta

		if lapTime {
			lapTime /= 1000

			speaker := this.getSpeaker()
			fragments := speaker.Fragments

			minute := Floor(lapTime / 60)
			seconds := (lapTime - (minute * 60))

			speaker.speakPhrase(phrase, {time: printNumber(lapTime, 1), minute: minute, seconds: printNumber(seconds, 1)})

			delta := (driverLapTime - lapTime)

			if (Abs(delta) > 0.5)
				speaker.speakPhrase("LapTimeDelta", {delta: printNumber(Abs(delta), 1)
												   , difference: (delta > 0) ? fragments["Faster"] : fragments["Slower"]})
		}
	}

	lapTimesRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		local car, lap, position, cars, driverLapTime, speaker, minute, seconds

		if !this.hasEnoughData()
			return

		car := knowledgeBase.getValue("Driver.Car")
		lap := knowledgeBase.getValue("Lap")
		position := Round(knowledgeBase.getValue("Position"))
		cars := Round(knowledgeBase.getValue("Car.Count"))

		driverLapTime := (knowledgeBase.getValue("Car." . car . ".Time") / 1000)
		speaker := this.getSpeaker()

		if (lap == 0)
			speaker.speakPhrase("Later")
		else {
			speaker.beginTalk()

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
				speaker.endTalk()
			}
		}
	}

	updateAnnouncement(announcement, value) {
		if (value && (announcement = "DeltaInformation")) {
			value := getConfigurationValue(this.Configuration, "Race Spotter Announcements", this.Simulator . ".PerformanceUpdates", 2)
			value := getConfigurationValue(this.Configuration, "Race Spotter Announcements", this.Simulator . ".DistanceInformation", value)
			value := getConfigurationValue(this.Configuration, "Race Spotter Announcements", this.Simulator . ".DeltaInformation", value)

			if !value
				value := 2
		}

		base.updateAnnouncement(announcement, value)
	}

	getSpeaker(fast := false) {
		return this.VoiceManager.getSpeaker(fast)
	}

	updateCarInfos(lastLap, sector) {
		local knowledgeBase = this.KnowledgeBase
		local driver, otherCars, carNr, info, lap

		lastLap := knowledgeBase.getValue("Lap", 0)

		if (lastLap > 0) {
			driver := knowledgeBase.getValue("Driver.Car", 0)

			otherCars := this.OtherCars

			loop % knowledgeBase.getValue("Car.Count", 0)
			{
				carNr := knowledgeBase.getValue("Car." . A_Index . ".Nr", false)

				if (A_Index != driver) {
					if otherCars.HasKey(carNr)
						info := otherCars[carNr]
					else {
						info := new CarInfo(carNr, knowledgeBase.getValue("Car." . A_Index . ".Car", "Unknown"))

						otherCars[carNr] := info
					}
				}
				else {
					info := this.DriverCar

					if !info {
						info := new CarInfo(carNr, knowledgeBase.getValue("Car." . A_Index . ".Car", "Unknown"))

						this.iDriverCar := info
					}
				}

				lap := knowledgeBase.getValue("Car." . A_Index . ".Lap", 0)

				if !info.update(computeDriverName(knowledgeBase.getValue("Car." . A_Index . ".Driver.Forname", "John")
												, knowledgeBase.getValue("Car." . A_Index . ".Driver.Surname", "Doe")
												, knowledgeBase.getValue("Car." . A_Index . ".Driver.Nickname", "JD"))
							  , knowledgeBase.getValue("Car." . A_Index . ".Position")
							  , knowledgeBase.getValue("Standings.Lap." . lastLap . ".Car." . A_Index . ".Laps")
							  , sector
							  , Round(knowledgeBase.getValue("Car." . A_Index . ".Time", false) / 1000, 1)
							  , (lap - knowledgeBase.getValue("Car." . A_Index . ".Valid.Laps", lap))
							  , knowledgeBase.getValue("Car." . A_Index . ".Incidents", 0)
							  , Round(knowledgeBase.getValue("Standings.Lap." . lastLap . ".Car." . A_Index . ".Delta") / 1000, 1)
							  , knowledgeBase.getValue("Car." . A_Index . ".InPitlane", false))
					if (A_Index != driver)
						if this.PositionInfos.HasKey(info.Nr)
							this.PositionInfos.reset(sector, true)
			}
		}
	}

	updatePositionInfos(lastLap, sector) {
		local debug := this.Debug[kDebugPositions]
		local positionInfos, position, info
		local nr, car

		this.updateCarInfos(lastLap, sector)

		positionInfos := this.PositionInfos

		if debug
			FileAppend ---------------------------------`n`n, %kTempDirectory%Race Spotter.positions

		for nr, car in this.OtherCars {
			if positionInfos.HasKey(nr)
				position := positionInfos[nr]
			else {
				position := new PositionInfo(this, car)

				positionInfos[nr] := position
			}

			if debug {
				info := values2String(", ", position.Car.Nr, position.Car.Car, position.Car.Driver, position.Car.Position, position.Observed
										  , values2String("|", position.Car.LapTimes*), position.Car.LapTime[true]
										  , values2String("|", position.Car.Deltas[sector]*), position.Delta[sector]
										  , position.inFront(), position.atBehind(), position.inFront(false), position.atBehind(false), position.forPosition()
										  , position.DeltaDifference[sector], position.LapTimeDifference[true]
										  , position.isFaster(sector), position.closingIn(sector, 0.2), position.runningAway(sector, 0.3))

				FileAppend %info%`n, %kTempDirectory%Race Spotter.positions
			}

			position.checkpoint(sector)
		}

		if debug
			FileAppend `n---------------------------------`n`n, %kTempDirectory%Race Spotter.positions
	}

	reviewRaceStart(lastLap) {
		local knowledgeBase = this.KnowledgeBase
		local speaker, driver, currentPosition

		if (this.Session == kSessionRace) {
			speaker := this.getSpeaker(true)
			driver := knowledgeBase.getValue("Driver.Car", false)

			if (driver && this.GridPosition) {
				currentPosition := knowledgeBase.getValue("Car." . driver . ".Position")

				speaker.beginTalk()

				try {
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
				finally {
					speaker.endTalk()
				}

				return true
			}
			else
				return false
		}
		else
			return false
	}

	getPositionInfos(ByRef standingsAhead, ByRef standingsBehind
				   , ByRef trackAhead, ByRef trackBehind, ByRef leader, inpit := false) {
		local nr, observed, candidate, cInpit

		standingsAhead := false
		standingsBehind := false
		trackAhead := false
		trackBehind := false
		leader := false

		for nr, candidate in this.PositionInfos {
			observed := candidate.Observed
			cInPit := InStr(observed, "P")

			if ((!inpit && cInpit) || (inpit && !cInpit))
				continue

			if !cInPit
				if InStr(observed, "TA")
					trackAhead := candidate
				else if InStr(observed, "TB")
					trackBehind := candidate

			if InStr(observed, "SA")
				standingsAhead := candidate
			else if InStr(observed, "SB")
				standingsBehind := candidate

			if InStr(observed, "L")
				leader := candidate
		}
	}

	sessionInformation(lastLap, sector, regular) {
		local knowledgeBase := this.KnowledgeBase
		local speaker := this.getSpeaker(true)
		local airTemperature := Round(knowledgebase.getValue("Weather.Temperature.Air"))
		local trackTemperature := Round(knowledgebase.getValue("Weather.Temperature.Track"))
		local remainingSessionLaps := knowledgeBase.getValue("Lap.Remaining.Session")
		local remainingStintLaps := knowledgeBase.getValue("Lap.Remaining.Stint")
		local remainingSessionTime := Round(knowledgeBase.getValue("Session.Time.Remaining") / 60000)
		local remainingStintTime := Round(knowledgeBase.getValue("Driver.Time.Stint.Remaining") / 60000)
		local situation, remainingFuelLaps, sessionDuration, lapTime, enoughFuel
		local sessionEnding, minute, lastTemperature, stintLaps

		if (lastLap == 2) {
			situation := "StartSummary"

			if !this.SessionInfos.HasKey(situation) {
				this.SessionInfos[situation] := true

				if this.reviewRaceStart(lastLap)
					return true
			}
		}

		if this.hasEnoughData(false) {
			if ((remainingSessionLaps <= 3) && (this.Session = kSessionRace)) {
				situation := "FinalLaps"

				if !this.SessionInfos.HasKey(situation) {
					this.SessionInfos[situation] := true

					this.announceFinalLaps(lastLap)

					return true
				}
			}

			if (sector = 1) {
				stintLaps := Floor(remainingStintLaps)

				if ((this.Session = kSessionRace) && (stintLaps < 4) && (remainingStintLaps < remainingSessionLaps)) {
					if (stintLaps > 0) {
						situation := ("StintEnding " . Ceil(lastLap + stintLaps))

						if !this.SessionInfos.HasKey(situation) {
							this.SessionInfos[situation] := true

							speaker.speakPhrase("StintEnding", {laps: stintLaps})

							return true
						}
					}
				}

				if (this.BestLapTime > 0) {
					if (this.SessionInfos.HasKey("BestLap") && (this.BestLapTime < this.SessionInfos["BestLap"])) {
						lapTime := (this.BestLapTime / 1000)

						minute := Floor(lapTime / 60)

						speaker.speakPhrase("BestLap", {time: printNumber(lapTime, 1)
													  , minute: minute, seconds: printNumber((lapTime - (minute * 60)), 1)})
					}

					this.SessionInfos["BestLap"] := this.BestLapTime
				}
			}

			if !this.SessionInfos.HasKey("AirTemperature") {
				if (lastLap > (this.BaseLap + 1)) {
					this.SessionInfos["AirTemperature"] := airTemperature

					if (this.BaseLap > 1) {
						speaker.speakPhrase("Temperature", {air: airTemperature, track: trackTemperature})

						return true
					}
				}
			}
			else {
				lastTemperature := this.SessionInfos["AirTemperature"]

				this.SessionInfos["AirTemperature"] := airTemperature

				if (lastTemperature < airTemperature) {
					speaker.speakPhrase("TemperatureRising", {air: airTemperature, track: trackTemperature})

					return true
				}

				if (lastTemperature > airTemperature) {
					speaker.speakPhrase("TemperatureFalling", {air: airTemperature, track: trackTemperature})

					return true
				}
			}

			if (this.Session = kSessionRace) {
				if (this.OverAllTime > (this.SessionDuration / 2)) {
					situation := "HalfTime"

					if !this.SessionInfos.HasKey(situation) {
						this.SessionInfos[situation] := true

						speaker.beginTalk()

						try {
							speaker.speakPhrase("HalfTimeIntro", {minutes: remainingSessionTime
																, laps: remainingSessionLaps
																, position: Round(knowledgeBase.getValue("Position", 0))})

							remainingFuelLaps := Floor(knowledgeBase.getValue("Lap.Remaining.Fuel"))

							if (remainingStintTime < remainingSessionTime) {
								speaker.speakPhrase("HalfTimeStint", {minutes: remainingStintTime, laps: Floor(remainingStintLaps)})

								enoughFuel := (remainingStintLaps < remainingFuelLaps)
							}
							else {
								speaker.speakPhrase("HalfTimeSession", {minutes: remainingSessionTime
																	  , laps: Ceil(remainingSessionLaps)})

								enoughFuel := (remainingSessionLaps < remainingFuelLaps)
							}

							speaker.speakPhrase(enoughFuel ? "HalfTimeEnoughFuel" : "HalfTimeNotEnoughFuel"
											  , {laps: Floor(remainingFuelLaps)})
						}
						finally {
							speaker.endTalk()
						}
					}
				}
			}
			else {
				sessionEnding := false

				if ((remainingSessionTime < 5) && !this.SessionInfos.HasKey("5MinAlert")) {
					this.SessionInfos["5MinAlert"] := true
					this.SessionInfos["15MinAlert"] := true
					this.SessionInfos["30MinAlert"] := true

					sessionEnding := true
				}

				if ((remainingSessionTime < 15) && !this.SessionInfos.HasKey("15MinAlert")) {
					this.SessionInfos["15MinAlert"] := true
					this.SessionInfos["30MinAlert"] := true

					sessionEnding := true
				}

				if ((remainingSessionTime < 30) && !this.SessionInfos.HasKey("30MinAlert")) {
					this.SessionInfos["30MinAlert"] := true

					sessionEnding := true
				}

				if sessionEnding {
					speaker.speakPhrase("SessionEnding", {minutes: remainingSessionTime})

					return true
				}
			}
		}

		return false
	}

	tacticalAdvice(lastLap, sector, regular) {
		local speaker := this.getSpeaker(true)
		local standingsAhead := false
		local standingsBehind := false
		local trackAhead := false
		local trackBehind := false
		local leader := false
		local opponentType := this.OpponentType
		local situation

		this.getPositionInfos(standingsAhead, standingsBehind, trackAhead, trackBehind, leader, true)

		if (standingsAhead && (standingsAhead != leader)) {
			situation := ("AheadPitting " . standingsAhead.Car.Nr . A_Space . standingsAhead.Car.LastLap)

			if !this.TacticalAdvices.HasKey(situation) {
				this.TacticalAdvices[situation] := true

				speaker.speakPhrase("AheadPitting")

				return true
			}
		}

		if standingsBehind {
			situation := ("BehindPitting " . standingsBehind.Car.Nr . A_Space . standingsBehind.Car.LastLap)

			if !this.TacticalAdvices.HasKey(situation) {
				this.TacticalAdvices[situation] := true

				speaker.speakPhrase("BehindPitting")

				return true
			}
		}

		if (leader && (leader.Car.Nr != this.DriverCar.Nr)) {
			situation := ("LeaderPitting " . leader.Car.Nr . A_Space . leader.Car.LastLap)

			if !this.TacticalAdvices.HasKey(situation) {
				this.TacticalAdvices[situation] := true

				speaker.speakPhrase("LeaderPitting")

				return true
			}
		}

		this.getPositionInfos(standingsAhead, standingsBehind, trackAhead, trackBehind, leader)

		if (regular && trackAhead && trackAhead.inDelta(sector) && !trackAhead.isFaster(sector)
		 && standingsBehind && (standingsBehind == trackBehind)
		 && trackBehind.hasDelta(sector) && trackAhead.hasDelta(sector)
		 && standingsBehind.inDelta(sector) && standingsBehind.isFaster(sector)) {
			situation := ("ProtectSlower " . trackAhead.Car.Nr . A_Space . trackBehind.Car.Nr)

			if !this.TacticalAdvices.HasKey(situation) {
				this.TacticalAdvices[situation] := true

				speaker.speakPhrase("ProtectSlower")

				return true
			}
		}

		if (sector > 1) {
			if (regular && trackBehind && standingsBehind && (trackBehind != standingsBehind)
			 && trackBehind.hasDelta(sector) && standingsBehind.hasDelta(sector)
			 && trackBehind.inDelta(sector) && trackBehind.isFaster(sector)
			 && standingsBehind.inDelta(sector, 4.0) && standingsBehind.isFaster(sector)
			 && (opponentType = "LapDown")) {
				situation := ("ProtectFaster " . trackBehind.Car.Nr . A_Space . standingsBehind.Car.Nr)

				if !this.TacticalAdvices.HasKey(situation) {
					this.TacticalAdvices[situation] := true

					speaker.speakPhrase("ProtectFaster")

					return true
				}
			}

			if (regular && trackBehind && trackBehind.hasDelta(sector)
			 && trackBehind.isFaster(sector) && ((opponentType = "LapDown") || (opponentType = "LapUp"))) {
				situation := (opponentType . "Faster " . trackBehind.Car.Nr)

				if !this.TacticalAdvices.HasKey(situation) {
					this.TacticalAdvices[situation] := true

					speaker.beginTalk()

					try {
						speaker.speakPhrase(opponentType . "Faster")

						speaker.speakPhrase("Slipstream")
					}
					finally {
						speaker.endTalk()
					}

					return true
				}
			}
		}

		return false
	}

	deltaInformation(lastLap, sector, regular) {
		local knowledgeBase := this.KnowledgeBase
		local standingsAhead, standingsBehind, trackAhead, trackBehind, leader, info, informed
		local opponentType, delta, deltaDifference, lapTimeDifference, car, remaining, speaker

		static lapUpRangeThreshold := "__Undefined__"
		static lapDownRangeThreshold := false
		static frontAttackThreshold := false
		static frontGainThreshold := false
		static frontLostThreshold := false
		static behindAttackThreshold := false
		static behindGainThreshold := false
		static behindLostThreshold := false

		if (lapUpRangeThreshold = kUndefined) {
			lapUpRangeThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "LapUp.Range.Threshold", 1.0)
			lapDownRangeThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "LapDown.Range.Threshold", 2.0)
			frontAttackThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "Front.Attack.Threshold", 0.8)
			frontGainThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "Front.Gain.Threshold", 0.3)
			frontLostThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "Front.Lost.Threshold", 1.0)
			behindAttackThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "Behind.Attack.Threshold", 0.8)
			behindLostThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "Behind.Lost.Threshold", 0.3)
			behindGainThreshold := getDeprecatedConfigurationValue(this.Settings, "Assistant.Spotter", "Spotter Settings", "Behind.Gain.Threshold", 1.5)
		}

		standingsAhead := false
		standingsBehind := false
		trackAhead := false
		trackBehind := false
		leader := false

		this.getPositionInfos(standingsAhead, standingsBehind, trackAhead, trackBehind, leader)

		if this.Debug[kDebugPositions] {
			info := ("=================================`n" . regular . (standingsAhead != false) . (standingsBehind != false) . (trackAhead != false) . (trackBehind != false) . "`n=================================`n`n")

			FileAppend %info%, %kTempDirectory%Race Spotter.positions
		}

		speaker := this.getSpeaker(true)

		informed := false

		speaker.beginTalk()

		try {
			opponentType := (trackAhead ? trackAhead.OpponentType : false)

			if ((sector > 1) && trackAhead && (trackAhead != standingsAhead) && trackAhead.hasDelta(sector)
			 && (opponentType != "Position")
			 && trackAhead.inDelta((opponentType = "LapDown") ? lapDownRangeThreshold : lapUpRangeThreshold)
			 && !trackAhead.isFaster(sector) && !trackAhead.runningAway(sector, frontGainThreshold)) {
				if (!trackAhead.Reported && (sector > 1)) {
					if (opponentType = "LapDown") {
						speaker.speakPhrase("LapDownDriver")

						trackAhead.Reported := true
					}
					else if (opponentType = "LapUp") {
						speaker.speakPhrase("LapUpDriver")

						trackAhead.Reported := true
					}
				}
			}
			else if (standingsAhead  && standingsAhead.hasDelta(sector)) {
				delta := Abs(standingsAhead.Delta[false, true, 1])
				deltaDifference := Abs(standingsAhead.DeltaDifference[sector])
				lapTimeDifference := Abs(standingsAhead.LapTimeDifference)

				if this.Debug[kDebugPositions] {
					info := values2String(", ", values2String("|", this.DriverCar.LapTimes*), this.DriverCar.LapTime[true]
											  , standingsAhead.Car.Nr, standingsAhead.Car.InPit, standingsAhead.Reported
											  , values2String("|", standingsAhead.Car.LapTimes*), standingsAhead.Car.LapTime[true]
											  , values2String("|", standingsAhead.Car.Deltas[sector]*)
											  , standingsAhead.Delta[sector], standingsAhead.Delta[false, true, 1]
											  , standingsAhead.inFront(), standingsAhead.atBehind()
											  , standingsAhead.inFront(false), standingsAhead.atBehind(false), standingsAhead.forPosition()
											  , standingsAhead.DeltaDifference[sector], standingsAhead.LapTimeDifference[true]
											  , standingsAhead.isFaster(sector)
											  , standingsAhead.closingIn(sector, frontGainThreshold)
											  , standingsAhead.runningAway(sector, frontLostThreshold))

					info := ("=================================`n" . info . "`n=================================`n`n")

					FileAppend %info%, %kTempDirectory%Race Spotter.positions
				}

				if ((delta <= frontAttackThreshold) && !standingsAhead.isFaster(sector) && !standingsAhead.Reported) {
					speaker.speakPhrase("GotHim", {delta: printNumber(delta, 1)
												 , gained: printNumber(deltaDifference, 1)
												 , lapTime: printNumber(lapTimeDifference, 1)})

					car := standingsAhead.Car

					if (car.Incidents > 0)
						speaker.speakPhrase("UnsafeDriverFront")
					else if (car.InvalidLaps > 3)
						speaker.speakPhrase("InconsistentDriverFront")

					standingsAhead.Reported := true

					standingsAhead.reset(sector)
				}
				else if (regular && standingsAhead.closingIn(sector, frontGainThreshold) && !standingsAhead.Reported) {
					speaker.speakPhrase("GainedFront", {delta: (delta > 5) ? Round(delta) : printNumber(delta, 1)
													  , gained: printNumber(deltaDifference, 1)
													  , lapTime: printNumber(lapTimeDifference, 1)})

					remaining := Min(knowledgeBase.getValue("Session.Time.Remaining"), knowledgeBase.getValue("Driver.Time.Stint.Remaining"))

					if ((remaining > 0) && (lapTimeDifference > 0))
						if (((remaining / 1000) / this.DriverCar.LapTime[true]) > (delta / lapTimeDifference))
							speaker.speakPhrase("CanDoIt")
						else
							speaker.speakPhrase("CantDoIt")

					informed := true

					standingsAhead.reset(sector)
				}
				else if (regular && standingsAhead.runningAway(sector, frontLostThreshold)) {
					speaker.speakPhrase("LostFront", {delta: (delta > 5) ? Round(delta) : printNumber(delta, 1)
													, lost: printNumber(deltaDifference, 1)
													, lapTime: printNumber(lapTimeDifference, 1)})

					standingsAhead.reset(sector, true)
				}
			}

			if (standingsBehind && standingsBehind.hasDelta(sector)) {
				delta := Abs(standingsBehind.Delta[false, true, 1])
				deltaDifference := Abs(standingsBehind.DeltaDifference[sector])
				lapTimeDifference := Abs(standingsBehind.LapTimeDifference)

				if this.Debug[kDebugPositions] {
					info := values2String(", ", values2String("|", this.DriverCar.LapTimes*), this.DriverCar.LapTime[true]
											  , standingsBehind.Car.Nr, , standingsBehind.Car.InPit, standingsBehind.Reported
											  , values2String("|", standingsBehind.Car.LapTimes*), standingsBehind.Car.LapTime[true]
											  , values2String("|", standingsBehind.Car.Deltas[sector]*)
											  , standingsBehind.Delta[sector], standingsBehind.Delta[false, true, 1]
											  , standingsBehind.inFront(), standingsBehind.atBehind()
											  , standingsBehind.inFront(false), standingsBehind.atBehind(false), standingsBehind.forPosition()
											  , standingsBehind.DeltaDifference[sector], standingsBehind.LapTimeDifference[true]
											  , standingsBehind.isFaster(sector)
											  , standingsBehind.closingIn(sector, behindLostThreshold)
											  , standingsBehind.runningAway(sector, behindGainThreshold))

					info := ("=================================`n" . info . "`n=================================`n`n")

					FileAppend %info%, %kTempDirectory%Race Spotter.positions
				}

				if ((delta <= behindAttackThreshold) && (standingsBehind.isFaster(sector) || standingsBehind.closingIn(sector, behindLostThreshold)) && !standingsBehind.Reported) {
					speaker.speakPhrase("ClosingIn", {delta: printNumber(delta, 1)
													, lost: printNumber(deltaDifference, 1)
													, lapTime: printNumber(lapTimeDifference, 1)})

					car := standingsAhead.Car

					if (car.Incidents > 0)
						speaker.speakPhrase("UnsafeDriveBehind")
					else if (car.InvalidLaps > 3)
						speaker.speakPhrase("InconsistentDriverBehind")

					standingsBehind.Reported := true

					standingsBehind.reset(sector)
				}
				else if (regular && standingsBehind.closingIn(sector, behindLostThreshold) && !standingsBehind.Reported) {
					speaker.speakPhrase("LostBehind", {delta: (delta > 5) ? Round(delta) : printNumber(delta, 1)
													 , lost: printNumber(deltaDifference, 1)
													 , lapTime: printNumber(lapTimeDifference, 1)})

					if !informed
						speaker.speakPhrase("Focus")

					standingsBehind.reset(sector)
				}
				else if (regular && standingsBehind.runningAway(sector, behindGainThreshold)) {
					speaker.speakPhrase("GainedBehind", {delta: (delta > 5) ? Round(delta) : printNumber(delta, 1)
													   , gained: printNumber(deltaDifference, 1)
													   , lapTime: printNumber(lapTimeDifference, 1)})

					standingsBehind.reset(sector, true)
				}
			}
		}
		finally {
			speaker.endTalk()
		}
	}

	announceFinalLaps(lastLap) {
		local knowledgeBase = this.KnowledgeBase
		local speaker := this.getSpeaker(true)
		local position := Round(knowledgeBase.getValue("Position", 0))

		speaker.beginTalk()

		try {
			speaker.speakPhrase("LastLaps")

			if (position <= 5) {
				if (position == 1)
					speaker.speakPhrase("Leader")
				else
					speaker.speakPhrase("Position", {position: position})

				speaker.speakPhrase("BringItHome")
			}
			else
				speaker.speakPhrase("Focus")
		}
		finally {
			speaker.endTalk()
		}
	}

	updateDriver(lastLap, sector) {
		local knowledgeBase = this.KnowledgeBase
		local tacticalAdvices, deltaInformation, regular, sessionInformation

		if this.Speaker[false] {
			if (lastLap > 1)
				this.updatePositionInfos(lastLap, sector)

			if (!this.SpotterSpeaking && !this.DriverCar.InPit) {
				this.SpotterSpeaking := true

				try {
					sessionInformation := this.Announcements["SessionInformation"]

					if (!sessionInformation || !this.sessionInformation(lastLap, sector, true)) {
						if (this.hasEnoughData(false) && (this.Session = kSessionRace)) {
							tacticalAdvices := this.Announcements["TacticalAdvices"]

							if (!tacticalAdvices || !this.tacticalAdvice(lastLap, sector, true)) {
								deltaInformation := this.Announcements["DeltaInformation"]

								if deltaInformation {
									if (deltaInformation = "S")
										regular := "S"
									else {
										regular := (lastLap >= (this.iLastDeltaInformationLap + deltaInformation))

										if regular
											this.iLastDeltaInformationLap := lastLap
									}

									this.deltaInformation(lastLap, sector, regular)
								}
							}
						}
					}
				}
				finally {
					this.SpotterSpeaking := false
				}
			}
		}
	}

	pendingAlert(alert, match := false) {
		local ignore, candidate

		if match {
			for ignore, candidate in this.iPendingAlerts
				if InStr(candidate, alert)
					return true

			return false
		}
		else
			return inList(this.iPendingAlerts, alert)
	}

	pendingAlerts(alerts, match := false) {
		local ignore, alert, candidate

		for ignore, alert in alerts
			if match {
				for ignore, candidate in this.iPendingAlerts
					if InStr(candidate, alert)
						return true
			}
			else
				if inList(this.iPendingAlerts, alert)
					return true

		return false
	}

	skipAlert(alert) {
		if ((alert = "Hold") && this.pendingAlert("Clear", true))
			return true
		else if ((alert = "Left") && (this.pendingAlerts(["ClearAll", "ClearLeft"]) || this.pendingAlerts(["Left", "Three"])))
			return true
		else if ((alert = "Right") && (this.pendingAlerts(["ClearAll", "ClearRight"]) || this.pendingAlerts(["Right", "Three"])))
			return true
		else if ((alert = "Three") && this.pendingAlert("Clear", true))
			return true
		else if ((alert = "Side") && this.pendingAlert("Clear", true))
			return true
		else if (InStr(alert, "Clear") && this.pendingAlerts(["Left", "Right", "Three", "Side", "ClearAll"]))
			return true
		else if (InStr(alert, "Behind") && (this.pendingAlert("Behind", true) || this.pendingAlerts(["Left", "Right", "Three"]) || this.pendingAlert("Clear", true)))
			return true
		else if (InStr(alert, "Yellow") && this.pendingAlert("YellowClear"))
			return true
		else if ((alert = "YellowClear") && this.pendingAlert("Yellow", true))
			return true

		return false
	}

	proximityAlert(alert) {
		local speaker, type
		local oldPriority

		static alerting := false

		if this.Speaker[false] {
			speaker := this.getSpeaker(true)

			if alert {
				this.iPendingAlerts.Push(alert)

				if (alerting || speaker.isSpeaking()) {
					Task.startTask(ObjBindMethod(this, "proximityAlert", false), 1000, kHighPriority)

					return
				}
			}
			else if (alerting || speaker.isSpeaking()) {
				Task.startTask(ObjBindMethod(this, "proximityAlert", false), 100, kHighPriority)

				return
			}

			oldPriority := Task.block(kNormalPriority)
			alerting := true

			try {
				loop {
					if (this.iPendingAlerts.Length() > 0)
						alert := this.iPendingAlerts.RemoveAt(1)
					else
						break

					if (InStr(alert, "Behind") == 1)
						type := "Behind"
					else
						type := alert

					if (((type != "Behind") && this.Announcements["SideProximity"]) || ((type = "Behind") && this.Announcements["RearProximity"])) {
						if (!this.SpotterSpeaking || (type != "Hold")) {
							this.SpotterSpeaking := true

							try {
								speaker.speakPhrase(alert, false, false, alert)
							}
							finally {
								this.SpotterSpeaking := false
							}
						}
					}
				}
			}
			finally {
				Task.unblock(oldPriority)

				alerting := false
			}
		}

		return false
	}

	greenFlag(arguments*) {
		local speaker

		if this.Speaker[false] { ; && !this.SpotterSpeaking) {
			this.SpotterSpeaking := true

			try {
				speaker := this.getSpeaker(true)

				speaker.speakPhrase("Green", false, false, "Green")
			}
			finally {
				this.SpotterSpeaking := false
			}
		}
	}

	yellowFlag(alert, arguments*) {
		local speaker, sectors

		if (this.Announcements["YellowFlags"] && this.Speaker[false]) { ; && !this.SpotterSpeaking) {
			this.SpotterSpeaking := true

			try {
				speaker := this.getSpeaker(true)
				sectors := string2Values(",", speaker.Fragments["Sectors"])

				switch alert {
					case "All":
						speaker.speakPhrase("YellowAll", false, false, "YellowAll")
					case "Sector":
						if (arguments.Length() > 1)
							speaker.speakPhrase("YellowDistance", {sector: sectors[arguments[1]], distance: arguments[2]})
						else
							speaker.speakPhrase("YellowSector", {sector: sectors[arguments[1]]})
					case "Clear":
						speaker.speakPhrase("YellowClear", false, false, "YellowClear")
					case "Ahead":
						speaker.speakPhrase("YellowAhead", false, false, "YellowAhead")
				}
			}
			finally {
				this.SpotterSpeaking := false
			}
		}
	}

	blueFlag() {
		local knowledgeBase := this.KnowledgeBase
		local position, delta

		if (this.Announcements["BlueFlags"] && this.Speaker[false]) { ; && !this.SpotterSpeaking) {
			this.SpotterSpeaking := true

			try {
				position := knowledgeBase.getValue("Position", false)
				delta := Abs(knowledgeBase.getValue("Position.Standings.Behind.Delta", false))

				if (knowledgeBase.getValue("Position.Standings.Behind.Car", false) && delta && (delta < 2000))
					this.getSpeaker(true).speakPhrase("BlueForPosition", false, false, "BlueForPosition")
				else
					this.getSpeaker(true).speakPhrase("Blue", false, false, "Blue")
			}
			finally {
				this.SpotterSpeaking := false
			}
		}
	}

	pitWindow(state) {
		if (this.Announcements["PitWindow"] && this.Speaker[false] && (this.Session = kSessionRace)) { ; && !this.SpotterSpeaking ) {
			this.SpotterSpeaking := true

			try {
				if (state = "Open")
					this.getSpeaker(true).speakPhrase("PitWindowOpen", false, false, "PitWindowOpen")
				else if (state = "Closed")
					this.getSpeaker(true).speakPhrase("PitWindowClosed", false, false, "PitWindowClosed")
			}
			finally {
				this.SpotterSpeaking := false
			}
		}
	}

	startupSpotter(forceShutdown := false) {
		local code, exePath, pid

		if !this.iSpotterPID {
			code := this.SettingsDatabase.getSimulatorCode(this.Simulator)

			exePath := (kBinariesDirectory . code . " SHM Spotter.exe")

			if FileExist(exePath) {
				this.shutdownSpotter(forceShutdown)

				try {
					Run %exePath%, %kBinariesDirectory%, Hide UseErrorLevel, pid
				}
				catch exception {
					logMessage(kLogCritical, substituteVariables(translate("Cannot start %simulator% %protocol% Spotter (")
															   , {simulator: code, protocol: "SHM"})
										   . exePath . translate(") - please rebuild the applications in the binaries folder (")
										   . kBinariesDirectory . translate(")"))

					showMessage(substituteVariables(translate("Cannot start %simulator% %protocol% Spotter (%exePath%) - please check the configuration...")
												  , {exePath: exePath, simulator: code, protocol: "SHM"})
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}

				if ((ErrorLevel != "Error") && pid)
					this.iSpotterPID := pid
			}
		}

		return false
	}

	shutdownSpotter(force := false) {
		local pid := this.iSpotterPID
		local processName, tries

		if pid {
			Process Close, %pid%

			Sleep 500

			Process Exist, %pid%

			if (force && ErrorLevel) {
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
			}
		}

		this.iSpotterPID := false

		return false
	}

	createSession(settings, data) {
		local facts := base.createSession(settings, data)
		local simulatorName := this.SettingsDatabase.getSimulatorName(facts["Session.Simulator"])
		local configuration := this.Configuration

		settings := this.Settings

		facts["Session.Settings.Lap.Learning.Laps"] := getConfigurationValue(configuration, "Race Spotter Analysis", simulatorName . ".LearningLaps", 1)
		facts["Session.Settings.Lap.History.Considered"] := getConfigurationValue(configuration, "Race Spotter Analysis", simulatorName . ".ConsideredHistoryLaps", 5)
		facts["Session.Settings.Lap.History.Damping"] := getConfigurationValue(configuration, "Race Spotter Analysis", simulatorName . ".HistoryLapsDamping", 0.2)

		return facts
	}

	updateSession(settings) {
		local knowledgeBase := this.KnowledgeBase
		local facts, key, value

		if knowledgeBase {
			if !IsObject(settings)
				settings := readConfiguration(settings)

			facts := {}

			for key, value in facts
				knowledgeBase.setFact(key, value)

			base.updateSession(settings)
		}
	}

	initializeAnnouncements(data) {
		local simulator := getConfigurationValue(data, "Session Data", "Simulator", "Unknown")
		local simulatorName := this.SettingsDatabase.getSimulatorName(simulator)
		local configuration := this.Configuration
		local announcements := {}
		local ignore, key, default

		for ignore, key in ["TacticalAdvices", "SideProximity", "RearProximity", "YellowFlags", "BlueFlags"
						  , "PitWindow", "SessionInformation"]
			announcements[key] := getConfigurationValue(configuration, "Race Spotter Announcements", simulatorName . "." . key, true)

		default := getConfigurationValue(configuration, "Race Spotter Announcements", simulatorName . ".PerformanceUpdates", 2)
		default := getConfigurationValue(configuration, "Race Spotter Announcements", simulatorName . ".DistanceInformation", default)

		announcements["DeltaInformation"] := getConfigurationValue(configuration, "Race Spotter Announcements", simulatorName . ".DeltaInformation", default)

		this.updateConfigurationValues({Announcements: announcements})
	}

	initializeGridPosition(data) {
		local driver := getConfigurationValue(data, "Position Data", "Driver.Car", false)

		if driver
			this.iGridPosition := getConfigurationValue(data, "Position Data", "Car." . driver . ".Position")
	}

	prepareSession(settings, data) {
		local speaker := this.getSpeaker()
		local fragments := speaker.Fragments
		local facts, weather, airTemperature, trackTemperature, weatherNow, weather10Min, weather30Min, driver

		base.prepareSession(settings, data)

		this.iWasStartDriver := true

		this.initializeAnnouncements(data)
		this.initializeGridPosition(data)

		facts := this.createSession(settings, data)

		if this.Speaker {
			speaker.beginTalk()

			try {
				speaker.speakPhrase("GreetingIntro")

				airTemperature := Round(getConfigurationValue(data, "Weather Data", "Temperature", 0))
				trackTemperature := Round(getConfigurationValue(data, "Track Data", "Temperature", 0))

				if (airTemperature = 0)
					airTemperature := Round(getConfigurationValue(data, "Car Data", "AirTemperature", 0))

				if (trackTemperature = 0)
					trackTemperature := Round(getConfigurationValue(data, "Car Data", "RoadTemperature", 0))

				weatherNow := getConfigurationValue(data, "Weather Data", "Weather", "Dry")
				weather10Min := getConfigurationValue(data, "Weather Data", "Weather10Min", "Dry")
				weather30Min := getConfigurationValue(data, "Weather Data", "Weather30Min", "Dry")

				if (weatherNow = "Dry") {
					if ((weather10Min = "Dry") || (weather30Min = "Dry"))
						weather := fragments["GreetingDry"]
					else
						weather := fragments["GreetingDry2Wet"]
				}
				else {
					if ((weather10Min = "Dry") || (weather30Min = "Dry"))
						weather := fragments["GreetingWet2Dry"]
					else
						weather := fragments["GreetingWet"]
				}

				speaker.speakPhrase("GreetingWeather", {air: airTemperature, track: trackTemperature, weather: weather})

				if (this.Session = kSessionRace) {
					driver := getConfigurationValue(data, "Position Data", "Driver.Car", false)

					if driver
						speaker.speakPhrase("GreetingPosition"
										  , {position: getConfigurationValue(data, "Position Data", "Car." . driver . ".Position")})

					if (getConfigurationValue(data, "Session Data", "SessionFormat", "Time") = "Time")
						speaker.speakPhrase("GreetingDuration", {minutes: Round(getConfigurationValue(data, "Session Data", "SessionTimeRemaining") / 60000)})
					else
						speaker.speakPhrase("GreetingLaps", {laps: this.SessionLaps})
				}
			}
			finally {
				speaker.endTalk()
			}
		}

		Task.startTask(ObjBindMethod(this, "startupSpotter", true), 20000)
	}

	startSession(settings, data) {
		local facts, joined, simulatorName, configuration, saveSettings

		if this.Debug[kDebugPositions]
			deleteFile(kTempDirectory . "Race Spotter.positions")

		joined := !this.iWasStartDriver

		if !IsObject(settings)
			settings := readConfiguration(settings)

		if !IsObject(data)
			data := readConfiguration(data)

		if joined {
			this.initializeAnnouncements(data)

			if this.Speaker
				this.getSpeaker().speakPhrase("GreetingIntro")
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

		this.iDriverCar := false
		this.OtherCars := {}
		this.PositionInfos := {}
		this.TacticalAdvices := {}
		this.SessionInfos := {}
		this.iLastDeltaInformationLap := false

		if !this.GridPosition
			this.initializeGridPosition(data)

		if joined
			Task.startTask(ObjBindMethod(this, "startupSpotter"), 10000)
		else
			this.startupSpotter()

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledgeBase(this.KnowledgeBase)
	}

	finishSession(shutdown := true) {
		local knowledgeBase := this.KnowledgeBase
		local asked

		if knowledgeBase {
			if (shutdown && (knowledgeBase.getValue("Lap", 0) > this.LearningLaps)) {
				this.shutdownSession("Before")

				if this.Listener {
					asked := true

					if ((this.SaveSettings == kAsk) && (this.Session == kSessionRace))
						this.getSpeaker().speakPhrase("ConfirmSaveSettings", false, true)
					else
						asked := false
				}
				else
					asked := false

				if asked {
					this.setContinuation(ObjBindMethod(this, "shutdownSession", "After"))

					Task.startTask(ObjBindMethod(this, "forceFinishSession"), 120000, kLowPriority)

					return
				}
			}

			this.shutdownSpotter(true)

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
		else
			Task.startTask(ObjBindMethod(this, "forceFinishSession"), 5000, kLowPriority)

		return false
	}

	prepareData(lapNumber, data) {
		local knowledgeBase, key, value

		data := base.prepareData(lapNumber, data)
		knowledgeBase := this.KnowledgeBase

		for key, value in getConfigurationSectionValues(data, "Position Data", Object())
			knowledgeBase.setFact(key, value)

		return data
	}

	addLap(lapNumber, data) {
		local result := base.addLap(lapNumber, data)
		local knowledgeBase := this.KnowledgeBase
		local gapAhead := getConfigurationValue(data, "Stint Data", "GapAhead", kUndefined)
		local gapBehind, validLaps, lap, lastPitstop

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

		loop % knowledgeBase.getValue("Car.Count")
		{
			validLaps := knowledgeBase.getValue("Car." . A_Index . ".Valid.Laps", 0)
			lap := knowledgeBase.getValue("Car." . A_Index . ".Lap", 0)

			if (lap != knowledgeBase.getValue("Car." . A_Index . ".Valid.LastLap", 0)) {
				knowledgeBase.setFact("Car." . A_Index . ".Valid.LastLap", lap)

				if knowledgeBase.getValue("Car." . A_Index . ".Lap.Valid", true)
					knowledgeBase.setFact("Car." . A_Index . ".Valid.Laps", validLaps +  1)
			}
		}

		lastPitstop := knowledgeBase.getValue("Pitstop.Last", false)

		if (lastPitstop && (Abs(lapNumber - lastPitstop) <= 2)) {
			this.PositionInfos := {}
			this.TacticalAdvices := {}
			this.SessionInfos := {}
			this.iLastDeltaInformationLap := false
		}

		if !this.GridPosition
			this.initializeGridPosition(data)

		return result
	}

	updateLap(lapNumber, data) {
		local knowledgeBase := this.KnowledgeBase
		local update, sector, gapAhead, gapBehind, result

		static lastSector := 1

		update := false

		if !IsObject(data)
			data := readConfiguration(data)

		sector := getConfigurationValue(data, "Stint Data", "Sector", 0)

		if (sector != lastSector) {
			lastSector := sector

			update := true

			knowledgeBase.addFact("Sector", sector)
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

		if update
			this.updateDriver(lapNumber, sector)

		return result
	}

	performPitstop(lapNumber := false) {
		local knowledgeBase := this.KnowledgeBase
		local result

		this.PositionInfos := {}
		this.TacticalAdvices := {}
		this.SessionInfos := {}
		this.iLastDeltaInformationLap := false

		this.startPitstop(lapNumber)

		base.performPitstop(lapNumber)

		knowledgeBase.addFact("Pitstop.Lap", lapNumber ? lapNumber : knowledgeBase.getValue("Lap"))

		result := knowledgeBase.produce()

		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledgeBase(knowledgeBase)

		this.finishPitstop(lapNumber)

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


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

getTime() {
	return A_Now
}