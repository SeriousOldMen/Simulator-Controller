;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Speech Recognizer               ;;;
;;;                                                                         ;;;
;;;   Part of this code is based on work of evilC. See the GitHub page      ;;;
;;;   https://github.com/evilC/HotVoice for mor information.                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\CLR.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kAzureLanguages = {"af-ZA": "Afrikaans (South Africa)"
						, "am-ET": "Amharic (Ethiopia)"
						, "ar-DZ": "Arabic (Algeria)"
						, "ar-BH": "Arabic (Bahrain)"
						, "ar-EG": "Arabic (Egypt)"
						, "ar-IQ": "Arabic (Iraq)"
						, "ar-IL": "Arabic (Israel)"
						, "ar-JO": "Arabic (Jordan)"
						, "ar-KW": "Arabic (Kuwait)"
						, "ar-LB": "Arabic (Lebanon)"
						, "ar-LY": "Arabic (Libya)"
						, "ar-MA": "Arabic (Morocco)"
						, "ar-OM": "Arabic (Oman)"
						, "ar-PS": "Arabic (Palestinian Authority)"
						, "ar-QA": "Arabic (Qatar)"
						, "ar-SA": "Arabic (Saudi Arabia)"
						, "ar-SY": "Arabic (Syria)"
						, "ar-TN": "Arabic (Tunisia)"
						, "ar-AE": "Arabic (United Arab Emirates)"
						, "ar-YE": "Arabic (Yemen)"
						, "bg-BG": "Bulgarian (Bulgaria)"
						, "my-MM": "Burmese (Myanmar)"
						, "ca-ES": "Catalan (Spain)"
						, "zh-HK": "Chinese (Cantonese, Traditional)"
						, "zh-CN": "Chinese (Mandarin, Simplified)"
						, "zh-TW": "Chinese (Taiwanese Mandarin)"
						, "hr-HR": "Croatian (Croatia)"
						, "cs-CZ": "Czech (Czech)"
						, "da-DK": "Danish (Denmark)"
						, "nl-BE": "Dutch (Belgium)"
						, "nl-NL": "Dutch (Netherlands)"
						, "en-AU": "English (Australia)"
						, "en-CA": "English (Canada)"
						, "en-GH": "English (Ghana)"
						, "en-HK": "English (Hong Kong)"
						, "en-IN": "English (India)"
						, "en-IE": "English (Ireland)"
						, "en-KE": "English (Kenya)"
						, "en-NZ": "English (New Zealand)"
						, "en-NG": "English (Nigeria)"
						, "en-PH": "English (Philippines)"
						, "en-SG": "English (Singapore)"
						, "en-ZA": "English (South Africa)"
						, "en-TZ": "English (Tanzania)"
						, "en-GG": "English (United Kingdom)"
						, "en-US": "English (United States)"}

for culture, name in {"et-EE": "Estonian (Estonia)"
					, "fil-PH": "Filipino (Philippines)"
					, "fi-FI": "Finnish (Finland)"
					, "fr-BE": "French (Belgium)"
					, "fr-CA": "French (Canada)"
					, "fr-FR": "French (France)"
					, "fr-CH": "French (Switzerland)"
					, "de-AT": "German (Austria)"
					, "de-DE": "German (Germany)"
					, "de-CH": "German (Switzerland)"
					, "el-GR": "Greek (Greece)"
					, "gu-IN": "Gujarati (Indian)"
					, "he-IL": "Hebrew (Israel)"
					, "hi-IN": "Hindi (India)"
					, "hu-HU": "Hungarian (Hungary)"
					, "is-IS": "Icelandic (Iceland)"
					, "id-ID": "Indonesian (Indonesia)"
					, "ga-IE": "Irish (Ireland)"
					, "it-IT": "Italian (Italy)"
					, "ja-JP": "Japanese (Japan)"
					, "jv-ID": "Javanese (Indonesia)"
					, "kn-IN": "Kannada (India)"
					, "km-KH": "Khmer (Cambodia)"
					, "ko-KR": "Korean (Korea)"
					, "lo-LA": "Lao (Laos)"
					, "lv-LV": "Latvian (Latvia)"
					, "lt-LT": "Lithuanian (Lithuania)"
					, "mk-MK": "Macedonian (North Macedonia)"
					, "ms-MY": "Malay (Malaysia)"
					, "mt-MT": "Maltese (Malta)"
					, "mr-IN": "Marathi (India)"
					, "nb-NO": "Norwegian (Bokmal, Norway)"
					, "fa-IR": "Persian (Iran)"
					, "pl-PL": "Polish (Poland)"
					, "pt-BR": "Portuguese (Brazil)"
					, "pt-PT": "Portuguese (Portugal)"
					, "ro-RO": "Romanian (Romania)"
					, "ru-RU": "Russian (Russia)"
					, "sr-RS": "Serbian (Serbia)"
					, "si-LK": "Sinhala (Sri Lanka)"
					, "sk-SK": "Slovak (Slovakia)"
					, "sl-SI": "Slovenian (Slovenia)"
					, "es-AR": "Spanish (Argentina)"
					, "es-BO": "Spanish (Bolivia)"
					, "es-CL": "Spanish (Chile)"
					, "es-CO": "Spanish (Colombia)"
					, "es-CR": "Spanish (Costa Rica)"
					, "es-CU": "Spanish (Cuba)"
					, "es-DO": "Spanish (Dominican Republic)"
					, "es-EC": "Spanish (Ecuador)"
					, "es-SV": "Spanish (El Salvador)"
					, "es-GQ": "Spanish (Equatorial Guinea)"
					, "es-GT": "Spanish (Guatemala)"
					, "es-HN": "Spanish (Honduras)"
					, "es-MX": "Spanish (Mexico)"
					, "es-NI": "Spanish (Nicaragua)"
					, "es-PA": "Spanish (Panama)"
					, "es-PY": "Spanish (Paraguay)"
					, "es-PE": "Spanish (Peru)"
					, "es-PR": "Spanish (Puerto Rico)"
					, "es-ES": "Spanish (Spain)"
					, "es-UY": "Spanish (Uruguay)"
					, "es-US": "Spanish (USA)"
					, "es-VE": "Spanish (Venezuela)"
					, "sw-KE": "Swahili (Kenya)"
					, "sw-TZ": "Swahili (Tanzania)"
					, "sv-SE": "Swedish (Sweden)"
					, "ta-IN": "Tamil (India)"
					, "te-IN": "Telugu (India)"
					, "th-TH": "Thai (Thailand)"
					, "tr-TR": "Turkish (Turkey)"
					, "uk-UA": "Ukrainian (Ukraine)"
					, "uz-UZ": "Uzbek (Uzbekistan)"
					, "vi-VN": "Vietnamese (Vietnam)"
					, "zu-ZA": "Zulu (South Africa)"}
	kAzureLanguages[culture] := name


;;;-------------------------------------------------------------------------;;;
;;;                          Public Class Section                           ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    SpeechRecognizer                               ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class SpeechRecognizer {
	iEngine := false
	iChoices := {}
	
	_grammarCallbacks := {}
	_grammars := {}
	
	Recognizers[language := false] {
		Get {
			result := []
			
			for ignore, recognizer in this.getRecognizerList()
				if language {
					if (recognizer.Language = language)
						result.Push(recognizer.Name)
				}
				else
					result.Push(recognizer.Name)
			
			return result
		}
	}
	
	__New(engine, recognizer := false, language := false, silent := false) {
		dllName := "Speech.Recognizer.dll"
		dllFile := kBinariesDirectory . dllName
		
		this.iEngine := engine
		this.Instance := false
		this.RecognizerList := []
		
		try {
			if (!FileExist(dllFile)) {
				logMessage(kLogCritical, translate("Speech.Recognizer.dll not found in ") . kBinariesDirectory)
				
				Throw "Unable to find Speech.Recognizer.dll in " . kBinariesDirectory . "..."
			}

			instance := CLR_LoadLibrary(dllFile).CreateInstance("Speech.SpeechRecognizer")
			
			this.Instance := instance
			
			if (InStr(engine, "Azure|") == 1) {
				this.iEngine := "Azure"
				
				engine := string2Values("|", engine)
				
				if !language
					language := "en-US"
				
				if !instance.Connect(engine[2], engine[3], language, ObjBindMethod(this, "_onTextCallback")) {
					logMessage(kLogCritical, translate("Could not communicate with speech recognizer library (") . dllName . translate(")"))
					logMessage(kLogCritical, translate("Try running the Powershell command ""Get-ChildItem -Path '.' -Recurse | Unblock-File"" in the Binaries folder"))
				
					Throw "Could not communicate with speech recognizer library (" . dllName . ")..."
				}
				
				choices := []
				
				Loop 101
					choices.Push((A_Index - 1) . "")
				
				this.setChoices("Number", choices)
				
				choices := []
				
				Loop 11
					choices.Push((A_Index - 1) . "")
				
				this.setChoices("Digit", choices)
			}
			else
				instance.SetEngine(engine)
			
			if (this.Instance.OkCheck() != "OK") {
				logMessage(kLogCritical, translate("Could not communicate with speech recognizer library (") . dllName . translate(")"))
				logMessage(kLogCritical, translate("Try running the Powershell command ""Get-ChildItem -Path '.' -Recurse | Unblock-File"" in the Binaries folder"))
				
				Throw "Could not communicate with speech recognizer library (" . dllName . ")..."
			}
			
			this.RecognizerList := this.createRecognizerList()
			
			if (this.RecognizerList.Length() == 0) {
				logMessage(kLogCritical, translate("No languages found while initializing speech recognition system - please install the speech recognition software"))
				
				if !silent
					showMessage(translate("No languages found while initializing speech recognition system - please install the speech recognition software") . translate("...")
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
			
			found := false
			
			if ((recognizer == true) && language) {
				for ignore, recognizerDescriptor in this.getRecognizerList()
					if (recognizerDescriptor["Language"] = language) {
						recognizer := recognizerDescriptor["ID"]
						
						found := true
						
						break
					}
			}
			else if (recognizer && (recognizer != true))
				for ignore, recognizerDescriptor in this.getRecognizerList()
					if (recognizerDescriptor["Name"] = recognizer) {
						recognizer := recognizerDescriptor["ID"]
						
						found := true
						
						break
					}
			
			if !found
				recognizer := 0

			this.initialize(recognizer)
		}
		catch exception {
			logMessage(kLogCritical, translate("Error while initializing speech recognition module - please install the speech recognition software"))
			
			if !silent
				showMessage(translate("Error while initializing speech recognition module - please install the speech recognition software") . translate("...")
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}
	}

	createRecognizerList() {
		recognizerList := []
		
		if (this.iEngine = "Azure") {
			for culture, name in kAzureLanguages {
				index := A_Index - 1
			
				language := StrSplit(culture, "-")[1]
				
				recognizerList.Push({ID: index, Name: name . " (" . culture . ")", Culture: culture, Language: language})
			}
		}
		else {
			Loop % this.Instance.GetRecognizerCount()
			{
				index := A_Index - 1
				
				recognizer := {ID: index, Culture: this.Instance.GetRecognizerCultureName(index), Language: this.Instance.GetRecognizerTwoLetterISOLanguageName(index)}
				
				if (this.iEngine = "Server")
					recognizer["Name"] := this.Instance.GetRecognizerName(index)
				else
					recognizer["Name"] := (this.Instance.GetRecognizerName(index) . " (" . recognizer["Culture"] . ")")
				
				recognizerList.Push(recognizer)
			}
		}
		
		return recognizerList
	}
	
	initialize(id) {
		if (this.iEngine = "Azure")
			this.Instance.SetLanguage(this.getRecognizerList()[id + 1]["Culture"])
		else if (id > this.Instance.getRecognizerCount() - 1)
			Throw "Invalid recognizer ID (" . id . ") detected in SpeechRecognizer.initialize..."
		else
			return this.Instance.Initialize(id)
	}
	
	startRecognizer() {
		return (this.Instance ? this.Instance.StartRecognizer() : false)
	}
	
	stopRecognizer() {
		return (this.Instance ? this.Instance.StopRecognizer() : false)
	}
	
	getRecognizerList() {
		return this.RecognizerList
	}
	
	getWords(list) {
		result := []
		
		Loop % list.MaxIndex() + 1
			result.Push(list[A_Index - 1])
		
		return result
	}
	
	getChoices(name) {
		if this.iChoices.HasKey(name)
			return this.iChoices[name]
		else if (this.iEngine = "Azure")
			return []
		else
			return (this.Instance ? ((this.iEngine = "Server") ? this.Instance.GetServerChoices(name) : this.Instance.GetDesktopChoices(name)) : [])
	}
	
	setChoices(name, choices) {
		this.iChoices[name] := this.newChoices(choices)
	}
	
	newGrammar() {
		switch this.iEngine {
			case "Desktop":
				return this.Instance.NewDesktopGrammar()
			case "Azure":
				return new Grammar()
			case "Server":
				return this.Instance.NewServerGrammar()
		}
	}
	
	newChoices(choices) {
		switch this.iEngine {
			case "Desktop":
				return this.Instance.NewDesktopChoices(IsObject(choices) ? values2String(", ", choices*) : choices)
			case "Azure":
				return new Grammar.Choices(!IsObject(choices) ? string2Values(",", choices) : choices)
			case "Server":
				return this.Instance.NewServerChoices(IsObject(choices) ? values2String(", ", choices*) : choices)
		}
	}
	
	loadGrammar(name, grammar, callback) {
		if (this._grammarCallbacks.HasKey(name))
			Throw "Grammar " . name . " already exists in SpeechRecognizer.loadGrammar..."
			
		this._grammarCallbacks[name] := callback
			
		if (this.iEngine = "Azure") {
			grammar := {Name: name, Grammar: grammar, Callback: callback}
			
			this._grammars[name] := grammar
			
			return grammar
		}
		else 
			return this.Instance.LoadGrammar(grammar, name, this._onGrammarCallback.Bind(this))
	}
	
	compileGrammar(text) {
		return new GrammarCompiler(this).compileGrammar(text)
	}
	
	allMatches(string, minRating, maxRating, strings*) {
		ratings := []

		for index, value in strings {
			rating := this.Instance.Compare(string, value)
		
			if (rating > minRating) {
				ratings.Push({Rating: rating, Target: value})
				
				if (rating > maxRating)
					break
			}
		}
		
		if (ratings.Length() > 0) {
			bubbleSort(ratings, "compareRating")
			
			return {BestMatch: ratings[1], Ratings: ratings}
		}
		else
			return {Ratings: []}
	}

	bestMatch(string, minRating, maxRating, strings*) {
		highestRating := 0
		bestMatch := false

		for key, value in strings {
			rating := this.Instance.Compare(string, value)
		
			if ((rating > minRating) && (highestRating < rating)) {
				highestRating := rating
				
				bestMatch := value
				
				if (rating > maxRating)
					break
			}
		}
		
		return bestMatch
	}
	
	_onGrammarCallback(name, wordArr) {
		words := this.getWords(wordArr)
		
		this._grammarCallbacks[name].Call(name, words)
	}
	
	_onTextCallback(text) {
		local grammar
		local literal
		
		words := string2Values(A_Space, text)

		for index, literal in words {
			literal := StrReplace(literal, ".", "")
			literal := StrReplace(literal, ",", "")
			literal := StrReplace(literal, ";", "")
			literal := StrReplace(literal, "?", "")
			literal := StrReplace(literal, "-", "")
			
			words[index] := literal
		}
		
		if true {
			bestRating := 0
			bestMatch := false
			
			for name, grammar in this._grammars {
				rating := this.match(text, grammar.Grammar)
			
				if (rating > bestRating) {
					bestRating := rating
					bestMatch := grammar
				}
			}
			
			if bestMatch {
				callback := bestMatch.Callback
				
				%callback%(bestMatch.Name, words)
			}
			else if this._grammars.HasKey("?") {
				callback := this._grammars["?"].Callback
				
				%callback%("?", words)
			}
		}
		else {
			for name, grammar in this._grammars
				if grammar.Grammar.match(words) {
					callback := grammar.Callback
						
					%callback%(name, words)
					
					return
				}

			if this._grammars.HasKey("?") {
				callback := this._grammars["?"].Callback
				
				%callback%("?", words)
			}
		}
	}
	
	match(words, grammar, minRating := 0.7, maxRating := 0.85) {
		matches := this.allMatches(words, minRating, maxRating, grammar.Phrases*)
		
		return (matches.HasKey("BestMatch") ? matches["BestMatch"]["Rating"] : false)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    GrammarCompiler                                ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GrammarCompiler {
	iSpeechRecognizer := false
	
	SpeechRecognizer[] {
		Get {
			return this.iSpeechRecognizer
		}
	}
	
	__New(recognizer) {
		this.iSpeechRecognizer := recognizer
	}
	
	compileGrammars(text) {
		grammars := []
		
		Loop Parse, text, `n, `r
		{
			line := Trim(A_LoopField)
			
			if ((line != "") && this.skipDelimiter(";", line, 1, false))
				line := ""
		
			if (incompleteLine && (line != "")) {
				line := incompleteLine . line
				incompleteLine := false
			}
			
			if ((line != "") && (SubStr(line, StrLen(line), 1) == "\"))
				incompleteLine := SubStr(line, 1, StrLen(line) - 1)
				
			if (!incompleteLine && (line != ""))
				grammars.Push(this.compileGrammar(line))
		}
		
		return grammars
	}
	
	compileGrammar(text) {
		local grammar
		local nextCharIndex := 1
		
		grammar := this.readGrammar(text, nextCharIndex)
		
		if !grammar
			Throw "Syntax error detected in """ . text . """ at 1 in GrammarCompiler.compileGrammar..."
		
		return this.parseGrammar(grammar)
	}
	
	readGrammar(ByRef text, ByRef nextCharIndex, level := 0) {
		this.skipWhiteSpace(text, nextCharIndex)
		
		if (SubStr(text, nextCharIndex, 1) = "[") {
			if (level = 0)
				return this.readGrammars(text, nextCharIndex, level)
			else
				Throw "Syntax error detected in """ . text . """ at " . nextCharIndex . " in GrammarCompiler.readGrammar..."
		}
		else
			return this.readList(text, nextCharIndex)
	}
	
	readGrammars(ByRef text, ByRef nextCharIndex, level := 0) {
		grammars := []
		
		this.skipDelimiter("[", text, nextCharIndex)
		
		Loop {
			grammars.Push(this.readGrammar(text, nextCharIndex, level + 1))
			
			if !this.skipDelimiter(",", text, nextCharIndex, false)
				break
		}

		this.skipDelimiter("]", text, nextCharIndex)
		
		return new GrammarGrammars(grammars)
	}
	
	readList(ByRef text, ByRef nextCharIndex) {
		grammars := []
		
		while !this.isEmpty(text, nextCharIndex) {
			this.skipWhiteSpace(text, nextCharIndex)
		
			if (SubStr(text, nextCharIndex, 1) = "{")
				grammars.Push(this.readChoices(text, nextCharIndex))
			else if (SubStr(text, nextCharIndex, 1) = "(")
				grammars.Push(this.readBuiltinChoices(text, nextCharIndex))
			else {
				literalValue := this.readLiteral(text, nextCharIndex)
			
				if literalValue
					grammars.Push(literalValue)
				else
					break
			}
		}

		return new GrammarList(grammars)
	}
	
	readChoices(ByRef text, ByRef nextCharIndex) {
		grammars := []
		
		this.skipDelimiter("{", text, nextCharIndex)
		
		Loop {
			literalValue := this.readLiteral(text, nextCharIndex)
		
			if literalValue
				grammars.Push(literalValue)
			else
				Throw "Syntax error detected in """ . text . """ at " . nextCharIndex . " in GrammarCompiler.readChoices..."
			
			if !this.skipDelimiter(",", text, nextCharIndex, false)
				break
		}

		this.skipDelimiter("}", text, nextCharIndex)
		
		return new GrammarChoices(grammars)
	}
	
	readBuiltinChoices(ByRef text, ByRef nextCharIndex) {
		builtin := false
		
		this.skipDelimiter("(", text, nextCharIndex)
		
		literalValue := this.readLiteral(text, nextCharIndex)
		
		if literalValue
			builtin := literalValue.Value
		else
			Throw "Syntax error detected in """ . text . """ at " . nextCharIndex . " in GrammarCompiler.readBuiltinChoices..."
			
		this.skipDelimiter(")", text, nextCharIndex)
		
		return new GrammarBuiltinChoices(builtin)
	}
	
	readLiteral(ByRef text, ByRef nextCharIndex, delimiters := "{}[]()`,") {
		local literal
		
		length := StrLen(text)
		
		this.skipWhiteSpace(text, nextCharIndex)
		
		beginCharIndex := nextCharIndex
		
		Loop {
			character := SubStr(text, nextCharIndex, 1)
			
			if (InStr(delimiters, character) || (nextCharIndex > length)) {
				if (beginCharIndex == nextCharIndex)
					return false
				else
					return new GrammarLiteral(SubStr(text, beginCharIndex, nextCharIndex - beginCharIndex))
			}
			else
				nextCharIndex += 1
		}
	}
	
	isEmpty(ByRef text, ByRef nextCharIndex) {
		remainingText := Trim(SubStr(text, nextCharIndex))
		
		if ((remainingText != "") && this.skipDelimiter(";", remainingText, 1, false))
			remainingText := ""
		
		return (remainingText == "")
	}
	
	skipWhiteSpace(ByRef text, ByRef nextCharIndex) {
		length := StrLen(text)
		
		Loop {
			if (nextCharIndex > length)
				return
				
			if InStr(" `t`n`r", SubStr(text, nextCharIndex, 1))
				nextCharIndex += 1
			else
				return
		}
	}
	
	skipDelimiter(delimiter, ByRef text, ByRef nextCharIndex, throwError := true) {
		length := StrLen(delimiter)
		
		this.skipWhiteSpace(text, nextCharIndex)
	
		if (SubStr(text, nextCharIndex, length) = delimiter) {
			nextCharIndex += length
			
			return true
		}
		else if throwError
			Throw "Syntax error detected in """ . text . """ at " . nextCharIndex . " in GrammarCompiler.skipDelimiter..."
		else
			return false
	}
	
	parseGrammar(grammar) {
		return this.createGrammarParser(grammar).parse(grammar)
	}
	
	createGrammarParser(grammar) {
		return new GrammarParser(this)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    Grammar                                        ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class Grammar {
	iParts := []
	iPhrases := false
	
	class Choices {
		iChoices := []
		
		Choices[] {
			Get {
				return this.iChoices
			}
		}
		
		__New(choices) {
			for index, choice in choices
				if !IsObject(choice)
					choices[index] := new Grammar.Words(choice)
				
			this.iChoices := choices
		}
		
		matchWords(words, ByRef index) {
			running := index
			
			for ignore, choice in this.Choices
				if choice.matchWords(words, running) {
					index := running
					
					return true
				}
			
			return false
		}
		
		combinePhrases(phrases) {
			for ignore, choice in this.Choices
				choice.combinePhrases(phrases)
		}
	}
	
	class Words {
		iWords := []
		
		Words[] {
			Get {
				return this.iWords
			}
		}
		
		__New(string) {
			local literal
			
			if !IsObject(string)
				string := string2Values(A_Space, string)
			
			for index, literal in string {
				literal := StrReplace(literal, ".", "")
				literal := StrReplace(literal, ",", "")
				literal := StrReplace(literal, ";", "")
				literal := StrReplace(literal, "?", "")
				literal := StrReplace(literal, "-", "")

				string[index] := literal
			}
			
			this.iWords := string
		}
		
		matchWords(words, ByRef index) {
			running := index
			
			for ignore, word in this.Words
				if (words.Length() < running)
					return false
				else if !this.matchWord(words[running++], word)
					return false
			
			index := running
			
			return true
		}
		
		combinePhrases(phrases) {
			phrases.Push(values2String(A_Space, this.Words*))
		}
		
		matchWord(word1, word2) {
			return (word1 = word2)
		}
	}
	
	Parts[] {
		Get {
			return this.iParts
		}
	}
	
	Phrases[] {
		Get {
			if !this.iPhrases
				this.iPhrases := this.allPhrases()
			
			return this.iPhrases
		}
	}
	
	AppendChoices(choices) {
		this.iParts.Push(choices)
	}
	
	AppendString(string) {
		this.iParts.Push(new this.Words(string))
	}
	
	AppendGrammars(grammars*) {
		this.AppendChoices(new this.Choices(grammars))
	}
	
	match(words) {
		index := 1
		
		return this.matchWords(words, index)
	}
	
	matchWords(words, ByRef index) {
		if (words.Length() < index)
			return true
		else {
			alternatives := false
			running := index
			
			for ignore, part in this.Parts {
				if ((A_Index == 1) && isInstance(part, Grammar))
					alternatives := true
		
				if alternatives {
					if part.matchWords(words, index)
						return true
				}
				else {
					if !part.matchWords(words, running)
						return false
				}
			}
			
			if alternatives
				return false
			else {
				index := running
			
				return true
			}
		}
	}
	
	allPhrases() {
		result := []
		
		this.combinePhrases(result)
		
		return result
	}
	
	combinePhrases(phrases) {
		alternatives := false
		pPhrases := []
		
		for index, part in this.Parts {
			if ((index == 1) && isInstance(part, Grammar))
				alternatives := true
		
			if alternatives
				part.combinePhrases(phrases)
			else {
				temp := []
			
				part.combinePhrases(temp)
				
				pPhrases.Push(temp)
			}
		}
		
		if !alternatives {
			parts := []
			
			for index, pParts in reverse(pPhrases) {
				if (index == 1)
					parts := pParts
				else {
					temp := []
					
					for ignore, p2 in parts
						for ignore, p1 in pParts
							temp.Push(p1 . A_Space . p2)
					
					parts := temp
				}
			}
			
			for ignore, part in parts
				phrases.Push(part)
		}
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    GrammarParser                                  ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GrammarParser {
	iCompiler := false
	
	Compiler[] {
		Get {
			return this.iCompiler
		}
	}
	
	__New(compiler) {
		this.iCompiler := compiler
	}
	
	parse(grammar) {
		if isInstance(grammar, GrammarList)
			return this.parseList(grammar)
		else if isInstance(grammar, GrammarGrammars)
			return grammar.parse(this)
		else if isInstance(grammar, GrammarChoices) {
			newGrammar := this.Compiler.SpeechRecognizer.newGrammar()
			
			newGrammar.AppendChoices(grammar.parse(this))
			
			return newGrammar
		}
		else
			Throw "Grammars may only contain literals, choices or other grammars in GrammarParser.parse..."
	}
	
	parseList(grammarList) {
		local grammar
		
		newGrammar := this.Compiler.SpeechRecognizer.newGrammar()
		
		for ignore, grammar in grammarList.List
			if isInstance(grammar, GrammarLiteral)
				newGrammar.AppendString(grammar.Value)
			else if (isInstance(grammar, GrammarChoices) || isInstance(grammar, GrammarBuiltinChoices))
				newGrammar.AppendChoices(grammar.parse(this))
			else
				Throw "Grammar lists may only contain literals or choices in GrammarParser.parseList..."
		
		return newGrammar
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    GrammarGrammars                                ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GrammarGrammars {
	iGrammarLists := []
	
	GrammarLists[] {
		Get {
			return this.iGrammarLists
		}
	}
	
	__New(grammarLists) {
		this.iGrammarLists := grammarLists
	}
	
	toString() {
		result := "["
			
		for ignore, list in this.GrammarLists {
			if (A_Index > 1)
				result .= ", "
			
			result .= list.toString()
		}
			
		return (result . "]")
	}
	
	parse(parser) {
		local grammar
		
		grammars := []
		
		for ignore, list in this.GrammarLists
			grammars.Push(parser.parseList(list))
		
		grammar := parser.Compiler.SpeechRecognizer.newGrammar()
		
		grammar.AppendGrammars(grammars*)
		
		return grammar
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    GrammarChoices                                 ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GrammarChoices {
	iChoices := []
	
	Choices[] {
		Get {
			return this.iChoices
		}
	}
	
	__New(choices) {
		this.iChoices := choices
	}
	
	toString() {
		result := "{"
			
		for ignore, choice in this.Choices {
			if (A_Index > 1)
				result .= ", "
			
			result .= choice.toString()
		}
			
		return (result . "}")
	}
	
	parse(parser) {
		choices := []
		
		for ignore, choice in this.Choices {
			if !isInstance(choice, GrammarLiteral)
				Throw "Invalid choice (" . choice.toString() . ") detected in GrammarChoices.parse..."
			
			choices.Push(choice.Value)
		}
		
		return parser.Compiler.SpeechRecognizer.newChoices(choices)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    GrammarBuiltinChoices                          ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GrammarBuiltinChoices {
	iBuiltin := false
	
	Builtin[] {
		Get {
			return this.iBuiltin
		}
	}
	
	__New(builtin) {
		this.iBuiltin := builtin
	}
	
	toString() {
		return "(" . this.Builtin . ")"
	}
	
	parse(parser) {
		choices := this.Builtin
		
		; if (choices = "Number")
		; 	choices := "Percent"
		
		return parser.Compiler.SpeechRecognizer.getChoices(choices)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    GrammarList                                    ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GrammarList {
	iList := []
	
	List[] {
		Get {
			return this.iList
		}
	}
	
	__New(list) {
		this.iList := list
	}
	
	toString() {
		result := ""
			
		for ignore, value in this.List {
			if (A_Index > 1)
				result .= A_Space
			
			result .= value.toString()
		}
			
		return result
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                    GrammarLiteral                                 ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GrammarLiteral {
	iValue := []
	
	Value[] {
		Get {
			return this.iValue
		}
	}
	
	__New(value) {
		this.iValue := value
	}
	
	toString() {
		return this.Value
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

compareRating(r1, r2) {
	return (r1.Rating < r2.Rating)
}