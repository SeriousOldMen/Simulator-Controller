;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - AI Race Engineer                ;;;
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
#Include ..\Libraries\SpeechGenerator.ahk
#Include ..\Libraries\SpeechRecognizer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kAlways = "Always"

global kFront = 0
global kRear = 1
global kLeft = 2
global kRight = 3
global kCenter = 4


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RaceEngineer extends ConfigurationItem {
	iPitstopHandler := false
	iRaceSettings := false
	
	iLanguage := "en"
	
	iName := false	
	iSpeaker := false
	iListener := false
	
	iSpeechGenerator := false
	iSpeechRecognizer := false
	iIsListening := false
	
	iContinuation := false
	
	iEnoughData := false
	
	iKnowledgeBase := false
	iOverallTime := 0
	iLastLap := 0
	iLastFuelAmount := 0
	iInitialFuelAmount := 0
	
	class RaceEngineerSpeaker extends SpeechGenerator {
		iEngineer := false
		iFragments := {}
		iPhrases := {}
		
		Engineer[] {
			Get {
				return this.iEngineer
			}
		}
		
		Phrases[] {
			Get {
				return this.iPhrases
			}
		}
		
		Fragments[] {
			Get {
				return this.iFragments
			}
		}
		
		__New(engineer, speaker, language, fragments, phrases) {
			this.iEngineer := engineer
			this.iFragments := fragments
			this.iPhrases := phrases
			
			base.__New(speaker, language)
		}
		
		speak(text) {
			stopped := this.Engineer.stopListening()
			
			try {
				base.speak(text, true)
			}
			finally {
				if stopped
					this.Engineer.startListening()
			}
		}
		
		speakPhrase(phrase, variables := false) {
			phrases := this.Phrases
			
			if phrases.HasKey(phrase) {
				phrases := phrases[phrase]
				
				Random index, 1, % phrases.Length()
				
				phrase := phrases[Round(index)]
				
				if variables
					phrase := substituteVariables(phrase, variables)
			}
			
			if phrase
				this.speak(phrase)
		}
	}
	
	class RaceKnowledgeBase extends KnowledgeBase {
		iEngineer := false
		
		RaceEngineer[] {
			Get {
				return this.iRaceEngineer
			}
		}
		
		__New(raceEngineer, ruleEngine, facts, rules) {
			this.iRaceEngineer := raceEngineer
			
			base.__New(ruleEngine, facts, rules)
		}
	}
	
	KnowledgeBase[] {
		Get {
			return this.iKnowledgeBase
		}
	}
	
	RaceSettings[] {
		Get {
			return this.iRaceSettings
		}
	}
	
	PitstopHandler[] {
		Get {
			return this.iPitstopHandler
		}
	}
	
	Language[] {
		Get {
			return this.iLanguage
		}
	}
	
	Name[] {
		Get {
			return this.iName
		}
	}
	
	Speaker[] {
		Get {
			return this.iSpeaker
		}
	}
	
	Listener[] {
		Get {
			return this.iListener
		}
	}
	
	Continuation[] {
		Get {
			return this.iContinuation
		}
	}
	
	EnoughData[] {
		Get {
			return this.iEnoughData
		}
	}
	
	OverallTime[] {
		Get {
			return this.iOverallTime
		}
	}
	
	LastLap[] {
		Get {
			return this.iLastLap
		}
	}
	
	InitialFuelAmount[] {
		Get {
			return this.iInitialFuelAmount
		}
	}
	
	LastFuelAmount[] {
		Get {
			return this.iLastFuelAmount
		}
	}
	
	__New(configuration, raceSettings, pitstopHandler := false, name := false, language := false, speaker := false, listener := false) {
		this.iRaceSettings := raceSettings
		this.iPitstopHandler := pitstopHandler
		this.iName := name
		
		listener := ((speaker != false) ? listener : false)
		
		if !language
			language := getLanguage()
		
		this.iLanguage := language
		this.iSpeaker := speaker
		this.iListener := listener
		
		base.__New(configuration)
	}
	
	getSpeaker() {
		if (this.Speaker && !this.iSpeechGenerator) {
			this.iSpeechGenerator := new this.RaceEngineerSpeaker(this, this.Speaker, this.Language, this.buildFragments(this.Language), this.buildPhrases(this.Language))
			
			this.getListener()
		}
		
		return this.iSpeechGenerator
	}
	
	getListener() {
		if (this.Listener && !this.iSpeechRecognizer) {
			if (this.Listener != true)
				recognizer := new SpeechRecognizer(this.Listener, this.Language)
			else
				recognizer := new SpeechRecognizer()
			
			this.buildGrammars(recognizer, this.Language)
			
			recognizer.startRecognizer()
			
			this.iSpeechRecognizer := recognizer
		}
		
		return this.iSpeechRecognizer
	}
	
	startListening(retry := true) {
		local function
		
		if this.iSpeechRecognizer && !this.iIsListening
			if !this.iSpeechRecognizer.startRecognizer() {
				if retry {
					function := ObjBindMethod(this, "startListening", true)
					
					SetTimer %function%, -200
				}
				
				return false
			}
			else {
				this.iIsListening := true
			
				return true
			}
	}
	
	stopListening(retry := false) {
		local function
		
		if this.iSpeechRecognizer && this.iIsListening
			if !this.iSpeechRecognizer.stopRecognizer() {
				if retry {
					function := ObjBindMethod(this, "stopListening", true)
					
					SetTimer %function%, -200
				}
				
				return false
			}
			else {
				this.iIsListening := false
			
				return true
			}
	}
	
	buildFragments(language) {
		fragments := {}
		
		settings := readConfiguration(getFileName("Race Engineer.grammars." . language, kUserConfigDirectory, kConfigDirectory))
		
		if (settings.Count() == 0)
			settings := readConfiguration(getFileName("Race Engineer.grammars.en", kUserConfigDirectory, kConfigDirectory))
		
		for fragment, word in getConfigurationSectionValues(settings, "Fragments", {})
			fragments[fragment] := word
		
		return fragments
	}
	
	buildPhrases(language) {
		phrases := {}
		
		settings := readConfiguration(getFileName("Race Engineer.grammars." . language, kUserConfigDirectory, kConfigDirectory))
		
		if (settings.Count() == 0)
			settings := readConfiguration(getFileName("Race Engineer.grammars.en", kUserConfigDirectory, kConfigDirectory))
		
		for key, value in getConfigurationSectionValues(settings, "Speaker Phrases", {}) {
			key := ConfigurationItem.splitDescriptor(key)[1]
		
			if phrases.HasKey(key)
				phrases[key].Push(value)
			else
				phrases[key] := Array(value)
		}
		
		return phrases
	}
	
	buildGrammars(speechRecognizer, language) {
		settings := readConfiguration(getFileName("Race Engineer.grammars." . language, kUserConfigDirectory, kConfigDirectory))
		
		if (settings.Count() == 0)
			settings := readConfiguration(getFileName("Race Engineer.grammars.en", kUserConfigDirectory, kConfigDirectory))
		
		for name, choices in getConfigurationSectionValues(settings, "Choices", {})
			speechRecognizer.setChoices(name, speechRecognizer.newChoices(string2Values(",", choices)*))
		
		for grammar, definition in getConfigurationSectionValues(settings, "Listener Grammars", {}) {
			definition := substituteVariables(definition, {name: this.Name})
		
			if isDebug() {
				nextCharIndex := 1
				SplashTextOn 400, 100, , % "Register phrase grammar " . new GrammarCompiler(speechRecognizer).readGrammar(definition, nextCharIndex).toString()
				Sleep 1000
				SplashTextOff
			}

			speechRecognizer.loadGrammar(grammar, speechRecognizer.compileGrammar(definition), ObjBindMethod(this, "phraseRecognized"))
		}
	}
	
	phraseRecognized(grammar, words) {
		if true && isDebug() {
			SplashTextOn 400, 100, , % "Phrase " . grammar . " recognized: " . values2String(" ", words*)
			Sleep 1000
			SplashTextOff
		}
		
		protectionOn()
		
		try {
			switch grammar {
				case "Yes":
					continuation := this.iContinuation
					
					this.iContinuation := false
					
					if continuation {
						this.getSpeaker().speakPhrase("Confirm")
									
						Sleep 5000

						%continuation%()
					}
				case "No":
					this.iContinuation := false
					
					this.getSpeaker().speakPhrase("Okay")
				case "Call", "Harsh":
					this.nameRecognized(words)
				case "Catch":
					this.getSpeaker().speakPhrase("Repeat")
				case "LapsRemaining":
					this.lapInfoRecognized(words)
				case "TyreTemperatures":
					this.tyreInfoRecognized(words)
				case "TyrePressures":
					this.tyreInfoRecognized(words)
				case "Weather":
					this.weatherRecognized(words)
				case "PitstopPlan":
					this.iContinuation := false
					
					this.getSpeaker().speakPhrase("Confirm")
			
					Sleep 5000
					
					this.planPitstopRecognized(words)
				case "PitstopPrepare":
					this.iContinuation := false
					
					this.getSpeaker().speakPhrase("Confirm")
			
					Sleep 5000
					
					this.preparePitstopRecognized(words)
				case "PitstopAdjustCompound":
					this.iContinuation := false
					
					this.pitstopAdjustCompoundRecognized(words)
				case "PitstopAdjustPressureUp", "PitstopAdjustPressureDown":
					this.iContinuation := false
					
					this.pitstopAdjustPressureRecognized(words)
				case "PitstopAdjustRepairSuspension":
					this.iContinuation := false
					
					this.pitstopAdjustRepairRecognized("Suspension", words)
				case "PitstopAdjustRepairBodywork":
					this.iContinuation := false
					
					this.pitstopAdjustRepairRecognized("Bodywork", words)
				default:
					Throw "Unknown grammar """ . grammar . """ detected in RaceEngineer.phraseRecognized...."
			}
		}
		finally {
			protectionOff()
		}
	}
	
	nameRecognized(words) {
		this.getSpeaker().speakPhrase("IHearYou")
	}
	
	lapInfoRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		laps := Round(knowledgeBase.getValue("Lap.Remaining"))
		
		if (laps == 0)
			this.getSpeaker().speakPhrase("Later")
		else
			this.getSpeaker().speakPhrase("Laps", {laps: laps})
	}
	
	tyreInfoRecognized(words) {
		local value
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if inList(words, fragments["temperatures"])
			value := "Temperature"
		else if inList(words, fragments["pressures"])
			value := "Pressure"
		else {
			speaker.speakPhrase("Repeat")
		
			return
		}
		
		lap := knowledgeBase.getValue("Lap")
		
		speaker.speakPhrase((value == "Pressure") ? "Pressures" : "Temperatures")
		
		speaker.speakPhrase("TyreFL", {value: Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".FL"), 1)
						  , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
		
		speaker.speakPhrase("TyreFR", {value: Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".FR"), 1)
						  , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
		
		speaker.speakPhrase("TyreRL", {value: Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".RL"), 1)
						  , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
		
		speaker.speakPhrase("TyreRR", {value: Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".RR"), 1)
						  , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
	}
	
	weatherRecognized(words) {
		this.getSpeaker().speakPhrase("Weather")
	}
	
	planPitstopRecognized(words) {
		this.planPitstop()
	}
	
	preparePitstopRecognized(words) {
		this.preparePitstop()
	}
	
	pitstopAdjustCompoundRecognized(words) {
		local action
		local compound
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan")
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			compound := false
		
			if inList(words, fragments["Wet"])
				compound := "Wet"
			else if inList(words, fragments["Dry"])
				compound := "Dry"
			
			if compound {
				speaker.speakPhrase("ConfirmCompoundChange", {compound: compound})
					
				this.setContinuation(ObjBindMethod(this, "updatePitstopTyreCompound", compound))
			}
			else
				speaker.speakPhrase("Repeat")
		}
	}
				
	pitstopAdjustPressureRecognized(words) {
		local action
		
		static tyreTypeFragments := false
		static numberFragmentsLookup := false
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !tyreTypeFragments {
			tyreTypeFragments := {FL: fragments["FrontLeft"], FR: fragments["FrontRight"], RL: fragments["RearLeft"], RR: fragments["RearRight"]}
			numberFragmentsLookup := {}
			
			for index, fragment in ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
				numberFragmentsLookup[fragments[fragment]] := index - 1
		}
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan")
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			tyreType := false
			
			if inList(words, fragments["Front"])
				if inList(words, fragments["Left"])
					tyreType := "FL"
				else if inList(words, fragments["Right"])
					tyreType := "FR"
			else if inList(words, fragments["Rear"])
				if inList(words, fragments["Left"])
					tyreType := "RL"
				else if inList(words, fragments["Right"])
					tyreType := "RR"
			
			if tyreType {
				action := false
				
				if inList(words, fragments["Increase"])
					action := kIncrease
				else if inList(words, fragments["Decrease"])
					action := kDecrease
				
				pointPosition := inList(words, fragments["Point"])
				
				if pointPosition {
					psiValue := numberFragmentsLookup[words[pointPosition - 1]]
					tenthPsiValue := numberFragmentsLookup[words[pointPosition + 1]]
					
					tyre := tyreTypeFragments[tyreType]
					action := fragments[action]
					
					delta := Round(psiValue + (tenthPsiValue / 10), 1)
					
					speaker.speakPhrase("ConfirmPsiChange", {action: action, tyre: tyre, unit: fragments["PSI"], delta: delta})
					
					this.setContinuation(ObjBindMethod(this, "updatePitstopTyrePressure", tyreType, (action == kIncrease) ? delta : (delta * -1)))
					
					return
				}
			}
			
			speaker.speakPhrase("Repeat")
		}
	}
	
	pitstopAdjustRepairRecognized(repairType, words) {
		local action
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan")
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			negation := ""
		
			if inList(words, fragments["Not"])
				negation := fragments["Not"]
			
			speaker.speakPhrase("ConfirmRepairChange", {damage: repairType, negation: negation})
					
			this.setContinuation(ObjBindMethod(this, "updatePitstopRepair", repairType, negation = ""))
		}
	}
	
	updatePitstopTyreCompound(compound) {
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan")
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			this.KnowledgeBase.setValue("Pitstop.Planned.Tyre.Compound", compound)
			
			if isDebug()
				dumpKnowledge(this.KnowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
		}
	}
	
	updatePitstopTyrePressure(tyreType, delta) {
		local knowledgeBase := this.KnowledgeBase
		
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan")
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			targetValue := knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure." . tyreType)
			targetIncrement := knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure." . tyreType . ".Increment")
			
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure." . tyreType, targetValue + delta)
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure." . tyreType . ".Increment", targetValue + delta)
			
			if isDebug()
				dumpKnowledge(this.KnowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
		}
	}
	
	updatePitstopRepair(repairType, repair) {
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan")
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			this.KnowledgeBase.setValue("Pitstop.Planned.Repair." . repairType, repair)
			
			if isDebug()
				dumpKnowledge(this.KnowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
		}
	}
			
	setContinuation(continuation) {
		this.iContinuation := continuation
	}
	
	createRace(data) {
		local facts
		
		settings := this.RaceSettings
		
		duration := Round((getConfigurationValue(data, "Stint Data", "TimeRemaining", 0) + getConfigurationValue(data, "Stint Data", "LapLastTime", 0)) / 1000)
		
		facts := {"Race.Car": getConfigurationValue(data, "Race Data", "Car", "")
				, "Race.Track": getConfigurationValue(data, "Race Data", "Track", "")
				, "Race.Duration": duration
				, "Race.Settings.OutLap": getConfigurationValue(settings, "Race Settings", "OutLap", true)
				, "Race.Settings.InLap": getConfigurationValue(settings, "Race Settings", "InLap", true)
				, "Race.Settings.Fuel.Max": getConfigurationValue(data, "Race Data", "FuelAmount", 0)
				, "Race.Settings.Fuel.AvgConsumption": getConfigurationValue(settings, "Race Settings", "Fuel.AvgConsumption", 0)
				, "Race.Settings.Fuel.SafetyMargin": getConfigurationValue(settings, "Race Settings", "Fuel.SafetyMargin", 5)
				, "Race.Settings.Lap.PitstopWarning": getConfigurationValue(settings, "Race Settings", "Lap.PitstopWarning", 5)
				, "Race.Settings.Lap.AvgTime": getConfigurationValue(settings, "Race Settings", "Lap.AvgTime", 0)
				, "Race.Settings.Lap.Considered": getConfigurationValue(settings, "Race Settings", "Lap.Considered", 5)
				, "Race.Settings.Lap.History.Considered": getConfigurationValue(settings, "Race Settings", "Lap.History.Considered", 5)
				, "Race.Settings.Lap.History.Damping": getConfigurationValue(settings, "Race Settings", "Lap.History.Damping", 0.2)
				, "Race.Settings.Damage.Suspension.Repair": getConfigurationValue(settings, "Race Settings", "Damage.Suspension.Repair", "Always")
				, "Race.Settings.Damage.Suspension.Repair.Threshold": getConfigurationValue(settings, "Race Settings", "Damage.Suspension.Repair.Threshold", 0)
				, "Race.Settings.Damage.Bodywork.Repair": getConfigurationValue(settings, "Race Settings", "Damage.Bodywork.Repair", "Threshold")
				, "Race.Settings.Damage.Bodywork.Repair.Threshold": getConfigurationValue(settings, "Race Settings", "Damage.Bodywork.Repair.Threshold", 20)
				, "Race.Settings.Tyre.Dry.Pressure.Target.FL": getConfigurationValue(settings, "Race Settings", "Tyre.Dry.Pressure.Target.FL", 27.7)
				, "Race.Settings.Tyre.Dry.Pressure.Target.FR": getConfigurationValue(settings, "Race Settings", "Tyre.Dry.Pressure.Target.FR", 27.7)
				, "Race.Settings.Tyre.Dry.Pressure.Target.RL": getConfigurationValue(settings, "Race Settings", "Tyre.Dry.Pressure.Target.RL", 27.7)
				, "Race.Settings.Tyre.Dry.Pressure.Target.RR": getConfigurationValue(settings, "Race Settings", "Tyre.Dry.Pressure.Target.RR", 27.7)
				, "Race.Settings.Tyre.Wet.Pressure.Target.FL": getConfigurationValue(settings, "Race Settings", "Tyre.Wet.Pressure.Target.FL", 30.0)
				, "Race.Settings.Tyre.Wet.Pressure.Target.FR": getConfigurationValue(settings, "Race Settings", "Tyre.Wet.Pressure.Target.FR", 30.0)
				, "Race.Settings.Tyre.Wet.Pressure.Target.RL": getConfigurationValue(settings, "Race Settings", "Tyre.Wet.Pressure.Target.RL", 30.0)
				, "Race.Settings.Tyre.Wet.Pressure.Target.RR": getConfigurationValue(settings, "Race Settings", "Tyre.Wet.Pressure.Target.RR", 30.0)
				, "Race.Settings.Tyre.Pressure.Deviation": getConfigurationValue(settings, "Race Settings", "Tyre.Pressure.Deviation", 0.2)
				, "Race.Settings.Tyre.Set.Fresh": getConfigurationValue(settings, "Race Settings", "Tyre.Set.Fresh", 8)
				, "Race.Setup.Tyre.Compound": getConfigurationValue(settings, "Race Setup", "Tyre.Compound", "Dry")
				, "Race.Setup.Tyre.Set": getConfigurationValue(settings, "Race Setup", "Tyre.Set", 7)
				, "Race.Setup.Tyre.Pressure.FL": getConfigurationValue(settings, "Race Setup", "Tyre.Pressure.FL", 26.1)
				, "Race.Setup.Tyre.Pressure.FR": getConfigurationValue(settings, "Race Setup", "Tyre.Pressure.FR", 26.1)
				, "Race.Setup.Tyre.Pressure.RL": getConfigurationValue(settings, "Race Setup", "Tyre.Pressure.RL", 26.1)
				, "Race.Setup.Tyre.Pressure.RR": getConfigurationValue(settings, "Race Setup", "Tyre.Pressure.RR", 26.1)}
				
		return facts
	}
	
	startRace(data) {
		local facts
		
		if !IsObject(data)
			data := readConfiguration(data)
		
		facts := this.createRace(data)
		
		FileRead engineerRules, % getFileName("Race Engineer.rules", kConfigDirectory, kUserConfigDirectory)
		
		productions := false
		reductions := false

		new RuleCompiler().compileRules(engineerRules, productions, reductions)

		engine := new RuleEngine(productions, reductions, facts)
		
		this.iKnowledgeBase := new this.RaceKnowledgeBase(this, engine, engine.createFacts(), engine.createRules())
		this.iLastLap := 0
		this.iOverallTime := 0
		this.iLastFuelAmount := 0
		this.iInitialFuelAmount := 0
		this.iEnoughData := false
		
		result := this.KnowledgeBase.produce()
			
		if this.Speaker
			this.getSpeaker().speakPhrase("Greeting", {name: this.Name})
		
		if isDebug()
			dumpKnowledge(this.KnowledgeBase)
		
		return result
	}
	
	finishRace() {
		this.iKnowledgeBase := false
		this.iLastLap := 0
		this.iOverallTime := 0
		this.iLastFuelAmount := 0
		this.iInitialFuelAmount := 0
		this.iEnoughData := false
			
		if this.Speaker {
			this.getSpeaker().speakPhrase("Bye")
			
			this.stopListening(true)
		}
	}
	
	addLap(lapNumber, data) {
		local knowledgeBase
		local facts
		
		if !IsObject(data)
			data := readConfiguration(data)
		
		if !this.KnowledgeBase
			this.startRace(data)
		
		knowledgeBase := this.KnowledgeBase
		
		if (lapNumber == 1)
			knowledgeBase.addFact("Lap", 1)
		else {
			knowledgeBase.setValue("Lap", lapNumber)
			
			this.iEnoughData := true
		}
			
		knowledgeBase.addFact("Lap." . lapNumber . ".Driver", getConfigurationValue(data, "Race Data", "DriverName", ""))
		
		lapTime := getConfigurationValue(data, "Stint Data", "LapLastTime", 0)
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Time", lapTime)
		knowledgeBase.addFact("Lap." . lapNumber . ".Time.Start", this.OverallTime)
		
		this.iOverallTime := this.OverallTime + lapTime
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Time.End", this.OverallTime)
		
		fuelRemaining := getConfigurationValue(data, "Car Data", "FuelRemaining", 0)
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.Remaining", Round(fuelRemaining, 2))
		
		if (lapNumber == 1) {
			this.iInitialFuelAmount := fuelRemaining
			this.iLastFuelAmount := fuelRemaining
			
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.AvgConsumption", 0)
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.Consumption", 0)
		}
		else {
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.AvgConsumption", Round((this.InitialFuelAmount - fuelRemaining) / (lapNumber - 1), 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Fuel.Consumption", Round(this.iLastFuelAmount - fuelRemaining, 2))
			
			this.iLastFuelAmount := fuelRemaining
		}
		
		tyrePressures := string2Values(",", getConfigurationValue(data, "Car Data", "TyrePressure", ""))
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Pressure.FL", Round(tyrePressures[1], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Pressure.FR", Round(tyrePressures[2], 2))		
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Pressure.RL", Round(tyrePressures[3], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Pressure.RR", Round(tyrePressures[4], 2))
		
		tyreTemperatures := string2Values(",", getConfigurationValue(data, "Car Data", "TyreTemperature", ""))
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Temperature.FL", Round(tyreTemperatures[1], 1))
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Temperature.FR", Round(tyreTemperatures[2], 1))		
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Temperature.RL", Round(tyreTemperatures[3], 1))
		knowledgeBase.addFact("Lap." . lapNumber . ".Tyre.Temperature.RR", Round(tyreTemperatures[4], 1))
			
		knowledgeBase.addFact("Lap." . lapNumber . ".Weather", 0)
		knowledgeBase.addFact("Lap." . lapNumber . ".Temperature.Air", Round(getConfigurationValue(data, "Car Data", "AirTemperature", 0)))
		knowledgeBase.addFact("Lap." . lapNumber . ".Temperature.Track", Round(getConfigurationValue(data, "Car Data", "RoadTemperature", 0)))
		
		bodyworkDamage := string2Values(",", getConfigurationValue(data, "Car Data", "BodyworkDamage", ""))
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Front", Round(bodyworkDamage[1], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Rear", Round(bodyworkDamage[2], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Left", Round(bodyworkDamage[3], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Right", Round(bodyworkDamage[4], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Center", Round(bodyworkDamage[5], 2))
		
		suspensionDamage := string2Values(",", getConfigurationValue(data, "Car Data", "SuspensionDamage", ""))
		
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.FL", Round(suspensionDamage[1], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.FR", Round(suspensionDamage[2], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.RL", Round(suspensionDamage[3], 2))
		knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.RR", Round(suspensionDamage[4], 2))
		
		result := knowledgeBase.produce()
		
		if isDebug()
			dumpKnowledge(this.KnowledgeBase)
		
		return result
	}
	
	hasEnoughData() {
		if this.EnoughData
			return true
		else if this.Speaker {
			this.getSpeaker().speakPhrase("Later")
			
			return false
		}
	}
	
	hasPlannedPitstop() {
		return this.KnowledgeBase.getValue("Pitstop.Planned", false)
	}
	
	hasPreparedPitstop() {
		return this.KnowledgeBase.getValue("Pitstop.Prepared", false)
	}
	
	planPitstop() {
		local knowledgeBase := this.KnowledgeBase
		local compound
		
		if !this.hasEnoughData()
			return
				
		knowledgeBase.addFact("Pitstop.Plan", true)
		
		result := knowledgeBase.produce()
		
		if isDebug()
			dumpKnowledge(this.KnowledgeBase)
		
		pitstopNumber := knowledgeBase.getValue("Pitstop.Planned.Nr")
		
		if this.Speaker {
			speaker := this.getSpeaker()
			fragments := speaker.Fragments
			
			speaker.speakPhrase("Pitstop", {name: this.Name, number: pitstopNumber})
				
			fuel := knowledgeBase.getValue("Pitstop.Planned.Fuel", 0)
			if (fuel == 0)
				speaker.speakPhrase("NoRefuel")
			else
				speaker.speakPhrase("Refuel", {litres: Round(fuel)})
			
			compound := knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound")
			if (compound = "Dry")
				speaker.speakPhrase("DryTyres", {compound: fragments[compound], set: knowledgeBase.getValue("Pitstop.Planned.Tyre.Set")})
			else
				speaker.speakPhrase("WetTyres", {compound: fragments[compound], set: knowledgeBase.getValue("Pitstop.Planned.Tyre.Set")})
			
			speaker.speakPhrase("NewPressures")
			
			speaker.speakPhrase("TyreFL", {value: Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FL"), 1), unit: fragments["PSI"]})
			speaker.speakPhrase("TyreFR", {value: Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FR"), 1), unit: fragments["PSI"]})
			speaker.speakPhrase("TyreRL", {value: Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RL"), 1), unit: fragments["PSI"]})
			speaker.speakPhrase("TyreRR", {value: Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RR"), 1), unit: fragments["PSI"]})

			if knowledgeBase.getValue("Pitstop.Planned.Repair.Suspension", false)
				speaker.speakPhrase("RepairSuspension")
			else
				speaker.speakPhrase("NoRepairSuspension")

			if knowledgeBase.getValue("Pitstop.Planned.Repair.Bodywork", false)
				speaker.speakPhrase("RepairBodywork")
			else
				speaker.speakPhrase("NoRepairBodywork")
				
			if this.Listener {
				speaker.speakPhrase("ConfirmPrepare")
				
				this.setContinuation(ObjBindMethod(this, "preparePitstop"))
			}
		}
		
		if (result && this.PitstopHandler) {
			this.PitstopHandler.pitstopPlanned(pitstopNumber)
		}
		
		return result
	}
	
	preparePitstop(lap := false) {
		if !this.hasPlannedPitstop() {
			if this.Speaker {
				speaker := this.getSpeaker()

				speaker.speakPhrase("MissingPlan")
				
				if this.Listener {
					speaker.speakPhrase("ConfirmPlan")
				
					this.setContinuation(ObjBindMethod(this, "planPitstop"))
				}
			}
			
			return false
		}
		else {
			if this.Speaker {
				speaker := this.getSpeaker()

				if lap
					speaker.speakPhrase("PrepareLap", {lap: lap})
				else
					speaker.speakPhrase("PrepareNow")
			}
				
			if !lap
				this.KnowledgeBase.addFact("Pitstop.Prepare", true)
			else
				this.KnowledgeBase.addFact("Pitstop.Planned.Lap", lap - 1)
		
			result := this.KnowledgeBase.produce()
			
			if isDebug()
				dumpKnowledge(this.KnowledgeBase)
					
			return result
		}
	}
	
	performPitstop() {
		if this.Speaker
			this.getSpeaker().speakPhrase("Perform")
				
		this.KnowledgeBase.addFact("Pitstop.Lap", this.KnowledgeBase.getValue("Lap"))
		
		result := this.KnowledgeBase.produce()
		
		if isDebug()
			dumpKnowledge(this.KnowledgeBase)
		
		if (result && this.PitstopHandler)
			this.PitstopHandler.pitstopFinished(this.KnowledgeBase.getValue("Pitstop.Last", 0))
		
		return result
	}
	
	lowFuelWarning(remainingLaps) {
		if this.Speaker {
			speaker := this.getSpeaker()
			
			speaker.speakPhrase((remainingLaps <= 2) ? "VeryLowFuel" : "LowFuel", {name: this.Name, laps: remainingLaps})
		
			if this.Listener {
				if !this.hasPlannedPitstop() {
					speaker.speakPhrase("ConfirmPlan")
					
					this.setContinuation(ObjBindMethod(this, "planPitstop"))
				}
				else if !this.hasPreparedPitstop() {
					speaker.speakPhrase("ConfirmPrepare")
					
					this.setContinuation(ObjBindMethod(this, "preparePitstop"))
				}
				else
					speaker.speakPhrase((remainingLaps <= 2) ? "LowComeIn" : "ComeIn")
			}
		}
	}
	
	damageWarning(newSuspensionDamage, newBodyworkDamage) {
		if this.Speaker {
			speaker := this.getSpeaker()
			phrase := false
			
			if (newSuspensionDamage && newBodyworkDamage)
				phrase := "BothDamage"
			else if newSuspensionDamage
				phrase := "SuspensionDamage"
			else if newBodyworkDamage
				phrase := "BodyworkDamage"
			
			speaker.speakPhrase(phrase, {name: this.Name})
	
			speaker.speakPhrase("DamageAnalysis")
		}
	}
	
	startPitstopSetup(pitstopNumber) {
		if this.PitstopHandler
			this.PitstopHandler.startPitstopSetup(pitstopNumber)
	}

	finishPitstopSetup(pitstopNumber) {
		if this.PitstopHandler {
			this.PitstopHandler.finishPitstopSetup(pitstopNumber)
			
			this.PitstopHandler.pitstopPrepared(pitstopNumber)
			
			if this.Speaker
				this.getSpeaker().speakPhrase("CallToPit")
		}
	}

	setPitstopRefuelAmount(pitstopNumber, litres) {
		if this.PitstopHandler
			this.PitstopHandler.setPitstopRefuelAmount(pitstopNumber, Round(litres))
	}

	setPitstopTyreSet(pitstopNumber, compound, set) {
		if this.PitstopHandler
			this.PitstopHandler.setPitstopTyreSet(pitstopNumber, compound, set)
	}

	setPitstopTyrePressures(pitstopNumber, pressureFLIncrement, pressureFRIncrement, pressureRLIncrement, pressureRRIncrement) {
		if this.PitstopHandler
			this.PitstopHandler.setPitstopTyrePressures(pitstopNumber, Round(pressureFLIncrement, 1), Round(pressureFRIncrement, 1)
																	 , Round(pressureRLIncrement, 1), Round(pressureRRIncrement, 1))
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork) {
		if this.PitstopHandler
			this.PitstopHandler.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork)
	}
}

;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

lowFuelWarning(context, remainingLaps) {
	context.KnowledgeBase.RaceEngineer.lowFuelWarning(Round(remainingLaps))
	
	return true
}

damageWarning(context, newSuspensionDamage, newBodyworkDamage) {
	context.KnowledgeBase.RaceEngineer.damageWarning(newSuspensionDamage, newBodyworkDamage)
	
	return true
}

startPitstopSetup(context, pitstopNumber) {
	context.KnowledgeBase.RaceEngineer.startPitstopSetup(pitstopNumber)
	
	return true
}

finishPitstopSetup(context, pitstopNumber) {
	context.KnowledgeBase.RaceEngineer.finishPitstopSetup(pitstopNumber)
	
	return true
}

setPitstopRefuelAmount(context, pitstopNumber, litres) {
	context.KnowledgeBase.RaceEngineer.setPitstopRefuelAmount(pitstopNumber, litres)
	
	return true
}

setPitstopTyreSet(context, pitstopNumber, compound, set) {
	context.KnowledgeBase.RaceEngineer.setPitstopTyreSet(pitstopNumber, compound, set)
	
	return true
}

setPitstopTyrePressures(context, pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
	context.KnowledgeBase.RaceEngineer.setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR)
	
	return true
}

requestPitstopRepairs(context, pitstopNumber, repairSuspension, repairBodywork) {
	context.KnowledgeBase.RaceEngineer.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork)
	
	return true
}

dumpKnowledge(knowledgeBase) {
	try {
		FileDelete %kUserHomeDirectory%Temp\Race Engineer.knowledge
	}
	catch exception {
		; ignore
	}

	for key, value in knowledgeBase.Facts.Facts {
		text := key . " = " . value . "`n"
	
		FileAppend %text%, %kUserHomeDirectory%Temp\Race Engineer.knowledge
	}
}

debugShow(ignore, args*) {
	MsgBox % "Debug: " . values2String(", ", args*)
	
	return true
}