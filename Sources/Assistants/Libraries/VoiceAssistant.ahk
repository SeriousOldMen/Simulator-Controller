;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Voice Chat Assistant            ;;;
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

#Include ..\Libraries\SpeechGenerator.ahk
#Include ..\Libraries\SpeechRecognizer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kDebugOff := 0
global kDebugGrammars := 1
global kDebugPhrases := 2
global kDebugRecognitions := 4


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class VoiceAssistant {
	iDebug := kDebugOff
	
	iLanguage := "en"
	
	iName := false	
	iSpeaker := false
	iSpeakerVolume := 100
	iSpeakerPitch := 0
	iSpeakerSpeed := 0
	iListener := false
	
	iVoiceServer := false
	
	iPushToTalk := false
	
	iSpeechGenerator := false
	iSpeechRecognizer := false
	iIsSpeaking := false
	iIsListening := false
	
	iContinuation := false
	
	class RemoteSpeaker {
		iAssistant := false
		iFragments := {}
		iPhrases := {}
		
		iSpeaker := false
		iLanguage := false
		
		Assistant[] {
			Get {
				return this.iAssistant
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
		
		__New(assistant, speaker, language, fragments, phrases) {
			this.iAssistant := assistant
			this.iFragments := fragments
			this.iPhrases := phrases
			
			this.iSpeaker := speaker
			this.iLanguage := language
		}
		
		speak(text) {
			raiseEvent(kFileMessage, "Voice", "speakWith:" . values2String(";", this.iSpeaker, this.iLanguage, text), this.Assistant.VoiceServer)
		}
		
		speakPhrase(phrase, variables := false) {
			phrases := this.Phrases
			
			if phrases.HasKey(phrase) {
				phrases := phrases[phrase]
				
				Random index, 1, % phrases.Length()
				
				phrase := phrases[Round(index)]
				
				if variables {
					variables := variables.Clone()
					
					variables["Name"] := this.Assistant.Name
					variables["user"] := this.Assistant.User
				}
				else
					variables := {name: this.Assistant.Name, driver: this.Assistant.User}
				
				phrase := substituteVariables(phrase, variables)
			}
			
			if phrase
				this.speak(phrase)
		}
	}
	
	class LocalSpeaker extends SpeechGenerator {
		iAssistant := false
		iFragments := {}
		iPhrases := {}
		
		Assistant[] {
			Get {
				return this.iAssistant
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
		
		__New(assistant, speaker, language, fragments, phrases) {
			this.iAssistant := assistant
			this.iFragments := fragments
			this.iPhrases := phrases
			
			base.__New(speaker, language)
		}
		
		speak(text) {
			stopped := this.Assistant.stopListening()
			
			try {
				this.iIsSpeaking := true
			
				try {
					base.speak(text, true)
				}
				finally {
					this.iIsSpeaking := false
				}
			}
			finally {
				if (stopped && !this.Assistant.PushToTalk)
					this.Assistant.startListening()
			}
		}
		
		speakPhrase(phrase, variables := false) {
			phrases := this.Phrases
			
			if phrases.HasKey(phrase) {
				phrases := phrases[phrase]
				
				Random index, 1, % phrases.Length()
				
				phrase := substituteVariables(phrases[Round(index)], this.Assistant.getPhraseVariables(variables))
			}
			
			if phrase
				this.speak(phrase)
		}
	}
	
	Debug[option] {
		Get {
			return (this.iDebug & option)
		}
	}
	
	VoiceServer[] {
		Get {
			return this.iVoiceServer
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
	
	Speaking[] {
		Get {
			return this.iIsSpeaking
		}
	}
	
	Listener[] {
		Get {
			return this.iListener
		}
	}
	
	Listening[] {
		Get {
			return this.iIsListening
		}
	}
	
	PushToTalk[] {
		Get {
			return this.iPushToTalk
		}
	}
	
	User[] {
		Get {
			Throw "Virtual property VoiceAssistant.User must be implemented in a subclass..."
		}
	}
	
	Continuation[] {
		Get {
			return this.iContinuation
		}
	}
	
	__New(name, options) {
		this.iName := name
		
		this.initialize(options)
		
		if !this.Speaker
			this.iListener := false
			
		if (this.VoiceServer && (this.Language != getConfigurationValue(configuration, "Voice Control", "Language", getLanguage())))
			this.iVoiceServer := false

		registerEventHandler("Voice", ObjBindMethod(this, "handleVoiceCalls"))
		
		if (!this.VoiceServer && this.PushToTalk) {
			listen := ObjBindMethod(this, "listen")
			
			SetTimer %listen%, 100
		}
	}
	
	initialize(options) {
		if options.HasKey("Language")
			this.iLanguage := options["Language"]
		
		if options.HasKey("Speaker")
			this.iSpeaker := options["Speaker"]
		
		if options.HasKey("SpeakerVolume")
			this.iSpeakerVolume := options["SpeakerVolume"]
		
		if options.HasKey("SpeakerPitch")
			this.iSpeakerPitch := options["SpeakerPitch"]
		
		if options.HasKey("SpeakerSpeed")
			this.iSpeakerSpeed := options["SpeakerSpeed"]
		
		if options.HasKey("Listener")
			this.iListener := options["Listener"]
		
		if options.HasKey("PushToTalk")
			this.iPushToTalk := options["PushToTalk"]
		
		if options.HasKey("VoiceServer")
			this.iVoiceServer := options["VoiceServer"]
	}
	
	listen() {
		theHotkey := this.PushToTalk
		
		if !this.Speaking && GetKeyState(theHotKey, "P")
			this.startListening()
		else if !GetKeyState(theHotKey, "P")
			this.stopListening()
	}
	
	setDebug(option, enabled) {
		if enabled
			this.iDebug := (this.iDebug | option)
		else if (this.Debug[option] == option)
			this.iDebug := (this.iDebug - option)
	}
	
	getPhraseVariables(variables := false) {
		if variables {
			variables := variables.Clone()
			
			variables["Name"] := this.Name
			variables["User"] := this.User
			
			return variables
		}
		else
			return {Name: this.Name, User: this.User}
	}
		
	getSpeaker() {
		if (this.Speaker && !this.iSpeechGenerator) {
			if this.VoiceServer
				this.iSpeechGenerator := new this.RemoteSpeaker(this, this.Speaker, this.Language
																	  , this.buildFragments(this.Language), this.buildPhrases(this.Language))
			else {
				this.iSpeechGenerator := new this.LocalSpeaker(this, this.Speaker, this.Language
																	 , this.buildFragments(this.Language), this.buildPhrases(this.Language))
			
				this.iSpeechGenerator.setVolume(this.iSpeakerVolume)
				this.iSpeechGenerator.setPitch(this.iSpeakerPitch)
				this.iSpeechGenerator.setRate(this.iSpeakerSpeed)
			}
				
			this.startListener()
		}
		
		return this.iSpeechGenerator
	}
	
	startListener() {
		static initialized := false
		
		if (!initialized && this.Listener && !this.iSpeechRecognizer) {
			initialized := true
			
			if this.VoiceServer
				this.buildGrammars(false, this.Language)
			else {
				recognizer := new SpeechRecognizer(this.Listener, this.Language)
				
				this.buildGrammars(recognizer, this.Language)
				
				if !this.PushToTalk
					recognizer.startRecognizer()
				
				this.iSpeechRecognizer := recognizer
			}
		}
	}
	
	startListening(retry := true) {
		local function
		
		if this.iSpeechRecognizer && !this.Listening
			if !this.iSpeechRecognizer.startRecognizer() {
				if retry {
					callback := ObjBindMethod(this, "startListening", true)
					
					SetTimer %callback%, -200
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
		
		if this.iSpeechRecognizer && this.Listening
			if !this.iSpeechRecognizer.stopRecognizer() {
				if retry {
					callback := ObjBindMethod(this, "stopListening", true)
					
					SetTimer %callback%, -200
				}
				
				return false
			}
			else {
				this.iIsListening := false
			
				return true
			}
	}
	
	getGrammars(language) {
		Throw "Virtual method VoiceAssistant.getGrammars must be implemented in a subclass..."
	}
	
	buildFragments(language) {
		fragments := {}
		
		grammars := this.getGrammars(language)
		
		for fragment, word in getConfigurationSectionValues(grammars, "Fragments", {})
			fragments[fragment] := word
		
		return fragments
	}
	
	buildPhrases(language) {
		phrases := {}
		
		grammars := this.getGrammars(language)
		
		for key, value in getConfigurationSectionValues(grammars, "Speaker Phrases", {}) {
			key := ConfigurationItem.splitDescriptor(key)[1]
		
			if phrases.HasKey(key)
				phrases[key].Push(value)
			else
				phrases[key] := Array(value)
		}
		
		return phrases
	}
	
	buildGrammars(speechRecognizer, language) {
		grammars := this.getGrammars(language)
		
		for name, choices in getConfigurationSectionValues(grammars, "Choices", {})
			if speechRecognizer
				speechRecognizer.setChoices(name, choices)
			else
				raiseEvent(kFileMessage, "Voice", "registerChoices:" . values2String(";", name, string2Values(",", choices)*), this.VoiceServer)
		
		Process Exist
		
		processID := ErrorLevel
		
		for grammar, definition in getConfigurationSectionValues(grammars, "Listener Grammars", {}) {
			definition := substituteVariables(definition, {name: this.Name})
		
			if this.Debug[kDebugGrammars] {
				nextCharIndex := 1
				
				showMessage("Register phrase grammar: " . new GrammarCompiler(speechRecognizer).readGrammar(definition, nextCharIndex).toString())
			}
			
			if speechRecognizer
				speechRecognizer.loadGrammar(grammar, speechRecognizer.compileGrammar(definition), ObjBindMethod(this, "raisePhraseRecognized"))
			else
				raiseEvent(kFileMessage, "Voice", "registerVoiceCommand:" . values2String(";", grammar, definition, processID, "remotePhraseRecognized"), this.VoiceServer)
		}
	}

	handleVoiceCalls(event, data) {
		if InStr(data, ":") {
			data := StrSplit(data, ":", , 2)

			return withProtection(ObjBindMethod(this, data[1]), string2Values(";", data[2])*)
		}
		else
			return withProtection(ObjBindMethod(this, data))
	}
	
	raisePhraseRecognized(grammar, words) {
		raiseEvent(kLocalMessage, "Voice", "localPhraseRecognized:" . values2String(";", grammar, words*))
	}
	
	localPhraseRecognized(grammar, words*) {
		this.phraseRecognized(grammar, words)
	}
	
	remotePhraseRecognized(grammar, command, words*) {
		this.phraseRecognized(grammar, words)
	}
	
	phraseRecognized(grammar, words) {
		if this.Debug[kDebugRecognitions]
			showMessage("Phrase " . grammar . " recognized: " . values2String(" ", words*))
		
		protectionOn()
		
		try {
			switch grammar {
				case "Yes":
					continuation := this.Continuation
					
					this.clearContinuation()
					
					if continuation {
						this.getSpeaker().speakPhrase("Confirm")

						%continuation%()
					}
				case "No":
					continuation := this.Continuation
					
					this.clearContinuation()
					
					if continuation
						this.getSpeaker().speakPhrase("Okay")
				case "Call", "Harsh":
					this.nameRecognized(words)
				case "Catch":
					this.getSpeaker().speakPhrase("Repeat")
				default:
					this.handleVoiceCommand(grammar, words)
			}
		}
		finally {
			protectionOff()
		}
	}
	
	setContinuation(continuation) {
		if continuation
			this.iContinuation := continuation
		else
			this.clearContinuation()
	}
	
	clearContinuation() {
		this.iContinuation := false
	}
	
	nameRecognized(words) {
		this.getSpeaker().speakPhrase("IHearYou")
	}
	
	handleVoiceCommand(phrase, words) {
		Throw "Virtual method VoiceAssistant.handleVoiceCommand must be implemented in a subclass..."
	}
}