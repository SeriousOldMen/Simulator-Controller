;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Voice Control Configuration     ;;;
;;;                                         Plugin                          ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                          Local Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\SpeechSynthesizer.ahk
#Include ..\Libraries\SpeechRecognizer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; VoiceControlConfigurator                                                ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global voiceLanguageDropDown = 1
global voiceSynthesizerDropDown = 1

global windowsSpeakerLabel
global windowsSpeakerDropDown
global windowsSpeakerVolumeLabel
global speakerVolumeSlider = 100
global windowsSpeakerPitchLabel
global speakerPitchSlider = 0
global windowsSpeakerSpeedLabel
global speakerSpeedSlider = 0

global azureSubscriptionKeyLabel
global azureSubscriptionKeyEdit = ""
global azureTokenIssuerLabel
global azureTokenIssuerEdit = ""
global azureSpeakerLabel
global azureSpeakerDropDown

global soXPathLabel1
global soXPathLabel2
global soXPathEdit = ""
global soXPathButton
global listenerLabel
global listenerDropDown = ""
global pushToTalkLabel
global pushToTalkEdit = ""
global pushToTalkButton
global activationCommandLabel
global activationCommandEdit = ""

class VoiceControlConfigurator extends ConfigurationItem {
	iEditor := false
	
	iLanguages := []
	iRecognizers := []
	
	iMode := false
	
	iTopWidgets := []
	iWindowsVoiceWidgets := []
	iAzureVoiceWidgets := []
	iOtherWidgets := []
	
	iCorrection := 0
	
	Editor[] {
		Get {
			return this.iEditor
		}
	}
	
	__New(editor, configuration := false) {
		this.iEditor := editor
		
		base.__New(configuration)
		
		VoiceControlConfigurator.Instance := this
	}
	
	createGui(editor, x, y, width, height, correction := 71) {
		this.iCorrection := correction
		
		window := editor.Window
		
		Gui %window%:Font, Norm, Arial
		
		choices := []
		chosen := 0
		enIndex := 0
		languageCode := "en"
		
		languages := availableLanguages()
		
		for code, language in languages {
			choices.Push(language)
			
			if (language == voiceLanguageDropDown) {
				chosen := A_Index
				languageCode := code
			}
				
			if (code = "en")
				enIndex := A_Index
		}
			
		for ignore, grammarFile in getFileNames("Race Engineer.grammars.*", kUserGrammarsDirectory, kGrammarsDirectory) {
			SplitPath grammarFile, , , code
		
			if !languages.HasKey(code) {
				choices.Push(code)
				
				if (code == voiceLanguageDropDown) {
					chosen := choices.Length()
					languageCode := code
				}
					
				if (code = "en")
					enIndex := choices.Length()
			}
		}
		
		this.iLanguages := choices
		
		if (chosen == 0)
			chosen := enIndex
		
		x0 := x + 8
		x1 := x + 118
		x2 := x + 230
		
		w1 := width - (x1 - x)
		w2 := w1 - 26
		
		x3 := x1 + w2 + 2
		
		Gui %window%:Add, Text, x%x% y%y% w110 h23 +0x200 HWNDwidget1 Hidden, % translate("Language")
		Gui %window%:Add, DropDownList, x%x1% yp w160 Choose%chosen% HWNDwidget2 VvoiceLanguageDropDown GupdateVoices Hidden, % values2String("|", choices*)
		
		choices := ["Windows Speech (Win32)", "Windows Speech (.NET)", "Azure Cognitive Services"]
		chosen := voiceSynthesizerDropDown
		
		Gui %window%:Add, Text, x%x% yp+32 w110 h23 +0x200 HWNDwidget3 Section Hidden, % translate("Speech Synthesizer")
		Gui %window%:Add, DropDownList, AltSubmit x%x1% yp w160 Choose%chosen% HWNDwidget4 gchooseVoiceSynthesizer VvoiceSynthesizerDropDown Hidden, % values2String("|", map(choices, "translate")*)
		
		this.iTopWidgets := [[widget1, widget2], [widget3, widget4]]
		
		voices := [translate("Automatic"), translate("Deactivated")]
		
		Gui %window%:Add, Text, x%x% ys+24 w110 h23 +0x200 HWNDwidget5 VwindowsSpeakerLabel Hidden, % translate("Voice")
		Gui %window%:Add, DropDownList, x%x1% yp w%w1% HWNDwidget6 VwindowsSpeakerDropDown Hidden, % values2String("|", voices*)
		
		Gui %window%:Add, Text, x%x% ys+24 w110 h23 +0x200 HWNDwidget6 VwindowsSpeakerVolumeLabel Hidden, % translate("Volume")
		Gui %window%:Add, Slider, x%x1% yp w135 0x10 Range0-100 ToolTip HWNDwidget7 VspeakerVolumeSlider Hidden, % speakerVolumeSlider
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget8 VwindowsSpeakerPitchLabel Hidden, % translate("Pitch")
		Gui %window%:Add, Slider, x%x1% yp w135 0x10 Range-10-10 ToolTip HWNDwidget9 VspeakerPitchSlider Hidden, % speakerPitchSlider
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget10 VwindowsSpeakerSpeedLabel Hidden, % translate("Speed")
		Gui %window%:Add, Slider, x%x1% yp w135 0x10 Range-10-10 ToolTip HWNDwidget11 VspeakerSpeedSlider Hidden, % speakerSpeedSlider
		
		this.iWindowsVoiceWidgets := [["windowsSpeakerLabel", "windowsSpeakerDropDown"]]
		
		Gui %window%:Add, Text, x%x% yp+24 w140 h23 +0x200 HWNDwidget12 VsoXPathLabel1 Hidden, % translate("SoX Folder (optional)")
		Gui %window%:Font, c505050 s8
		Gui %window%:Add, Text, x%x0% yp+18 w133 h23 HWNDwidget13 VsoXPathLabel2 Hidden, % translate("(Post Processing)")
		Gui %window%:Font
		Gui %window%:Add, Edit, x%x1% yp-19 w%w2% h21 HWNDwidget14 VsoXPathEdit Hidden, %soXPathEdit%
		Gui %window%:Add, Button, x%x3% yp w23 h23 gchooseSoXPath HWNDwidget15 VsoXPathButton Hidden, % translate("...")

		recognizers := new SpeechRecognizer(false, false, true).getRecognizerList().Clone()
		
		Loop % recognizers.Length()
			recognizers[A_Index] := recognizers[A_Index].Name
		
		recognizers.InsertAt(1, translate("Deactivated"))
		recognizers.InsertAt(1, translate("Automatic"))
		
		chosen := inList(recognizers, listenerDropDown)
		
		this.iRecognizers := recognizers
		
		if (chosen == 0)
			chosen := 1
		
		Gui %window%:Add, Text, x%x% yp+42 w110 h23 +0x200 HWNDwidget16 VlistenerLabel Hidden, % translate("Speech Recognizer")
		Gui %window%:Add, DropDownList, x%x1% yp w%w1% Choose%chosen% HWNDwidget17 VlistenerDropDown Hidden, % values2String("|", recognizers*)
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget18 VpushToTalkLabel Hidden, % translate("Push To Talk")
		Gui %window%:Add, Edit, x%x1% yp w110 h21 HWNDwidget19 VpushToTalkEdit Hidden, %pushToTalkEdit%
		Gui %window%:Add, Button, x%x2% yp-1 w23 h23 HWNDwidget20 ggetPTTHotkey VpushToTalkButton Hidden
		setButtonIcon(widget20, kIconsDirectory . "Key.ico", 1)
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget21 VactivationCommandLabel Hidden, % translate("Activation Command")
		Gui %window%:Add, Edit, x%x1% yp w135 h21 HWNDwidget22 VactivationCommandEdit Hidden, %activationCommandEdit%
		
		this.iOtherWidgets := [["windowsSpeakerVolumeLabel", "speakerVolumeSlider"]
							 , ["windowsSpeakerPitchLabel", "speakerPitchSlider"]
							 , ["windowsSpeakerSpeedLabel", "speakerSpeedSlider"]
							 , ["soXPathLabel1", "soXPathLabel2", "soXPathEdit", "soXPathButton"]
							 , ["listenerLabel", "listenerDropDown"], ["pushToTalkLabel", "pushToTalkEdit", "pushToTalkButton"],
							 , ["activationCommandLabel", "activationCommandEdit"]]
		
		Gui %window%:Add, Text, x%x% ys+24 w140 h23 +0x200 HWNDwidget23 VazureSubscriptionKeyLabel Hidden, % translate("Subscription Key")
		Gui %window%:Add, Edit, x%x1% yp w%w1% h21 HWNDwidget24 VazureSubscriptionKeyEdit GupdateAzureVoices Hidden, %azureSubscriptionKeyEdit%
		
		Gui %window%:Add, Text, x%x% yp+24 w140 h23 +0x200 HWNDwidget25 VazureTokenIssuerLabel Hidden, % translate("Token Issuer Endpoint")
		Gui %window%:Add, Edit, x%x1% yp w%w1% h21 HWNDwidget26 VazureTokenIssuerEdit GupdateAzureVoices Hidden, %azureTokenIssuerEdit%
		
		voices := [translate("Automatic"), translate("Deactivated")]
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget27 VazureSpeakerLabel Hidden, % translate("Voice")
		Gui %window%:Add, DropDownList, x%x1% yp w%w1% HWNDwidget28 VazureSpeakerDropDown Hidden, % values2String("|", voices*)
		
		this.iAzureVoiceWidgets := [["azureSubscriptionKeyLabel", "azureSubscriptionKeyEdit"], ["azureTokenIssuerLabel", "azureTokenIssuerEdit"], ["azureSpeakerLabel", "azureSpeakerDropDown"]]

		this.updateVoices()
		
		Loop 28
			editor.registerWidget(this, widget%A_Index%)
		
		hideWidgets(this.iTopWidgets)
		hideWidgets(this.iWindowsVoiceWidgets)
		hideWidgets(this.iAzureVoiceWidgets)
		hideWidgets(this.iOtherWidgets)
		
		if (voiceSynthesizerDropDown == 1)
			this.showWindowsVoiceEditor()
		else if (voiceSynthesizerDropDown == 2)
			this.showDotNETVoiceEditor()
		else
			this.showAzureVoiceEditor()
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		languageCode := getConfigurationValue(configuration, "Voice Control", "Language", getLanguage())
		languages := availableLanguages()
		
		if languages.HasKey(languageCode)
			voiceLanguageDropDown := languages[languageCode]
		else
			voiceLanguageDropDown := languageCode
		
		voiceSynthesizerDropDown := inList(["Windows", "dotNET", "Azure"], getConfigurationValue(configuration, "Voice Control", "Synthesizer", "dotNET"))
		
		azureSpeakerDropDown := getConfigurationValue(configuration, "Voice Control", "Speaker.Azure", true)
		windowsSpeakerDropDown := getConfigurationValue(configuration, "Voice Control", "Speaker.Windows",  getConfigurationValue(configuration, "Voice Control", "Speaker", true))
		
		azureSubscriptionKeyEdit := getConfigurationValue(configuration, "Voice Control", "SubscriptionKey", "")
		azureTokenIssuerEdit := getConfigurationValue(configuration, "Voice Control", "TokenIssuer", "")
		
		speakerVolumeSlider := getConfigurationValue(configuration, "Voice Control", "SpeakerVolume", 100)
		speakerPitchSlider := getConfigurationValue(configuration, "Voice Control", "SpeakerPitch", 0)
		speakerSpeedSlider := getConfigurationValue(configuration, "Voice Control", "SpeakerSpeed", 0)
		
		soXPathEdit := getConfigurationValue(configuration, "Voice Control", "SoX Path", "")
		
		listenerDropDown := getConfigurationValue(configuration, "Voice Control", "Listener", true)
		pushToTalkEdit := getConfigurationValue(configuration, "Voice Control", "PushToTalk", false)
		activationCommandEdit := getConfigurationValue(configuration, "Voice Control", "ActivationCommand", false)
		
		if (pushToTalkEdit = false)
			pushToTalkEdit := ""
		
		if (activationCommandEdit = false)
			activationCommandEdit := ""
		
		if (windowsSpeakerDropDown == true)
			windowsSpeakerDropDown := translate("Automatic")
		else if (windowsSpeakerDropDown == false)
			windowsSpeakerDropDown := translate("Deactivated")

		if this.Configuration
			if (listenerDropDown == true)
				listenerDropDown := translate("Automatic")
			else if (listenerDropDown == false)
				listenerDropDown := translate("Deactivated")
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)

		window := this.Editor.Window
		
		Gui %window%:Default

		setConfigurationValue(configuration, "Voice Control", "Language", this.getCurrentLanguage())
			
		GuiControlGet voiceSynthesizerDropDown
		
		setConfigurationValue(configuration, "Voice Control", "Synthesizer", ["Windows", "dotNET", "Azure"][voiceSynthesizerDropDown])
		
		GuiControlGet windowsSpeakerDropDown
		GuiControlGet azureSpeakerDropDown
		GuiControlGet azureSubscriptionKeyEdit
		GuiControlGet azureTokenIssuerEdit
		
		if (windowsSpeakerDropDown = translate("Automatic"))
			windowsSpeakerDropDown := true
		else if ((windowsSpeakerDropDown = translate("Deactivated")) || (windowsSpeakerDropDown = A_Space))
			windowsSpeakerDropDown := false

		if (voiceSynthesizerDropDown = 1) {
			setConfigurationValue(configuration, "Voice Control", "Speaker.Windows", windowsSpeakerDropDown)
			setConfigurationValue(configuration, "Voice Control", "Speaker.dotNET", true)
		}
		else if (voiceSynthesizerDropDown = 2) {
			setConfigurationValue(configuration, "Voice Control", "Speaker.Windows", true)
			setConfigurationValue(configuration, "Voice Control", "Speaker.dotNET", windowsSpeakerDropDown)
		}
		
		if (azureSpeakerDropDown = translate("Automatic"))
			azureSpeakerDropDown := true
		else if ((azureSpeakerDropDown = translate("Deactivated")) || (azureSpeakerDropDown = A_Space))
			azureSpeakerDropDown := false
		
		setConfigurationValue(configuration, "Voice Control", "Speaker.Azure", azureSpeakerDropDown)
		
		if (voiceSynthesizerDropDown == 1) {
			setConfigurationValue(configuration, "Voice Control", "Service", "Windows")
			setConfigurationValue(configuration, "Voice Control", "Speaker", windowsSpeakerDropDown)
		}
		else if (voiceSynthesizerDropDown == 2) {
			setConfigurationValue(configuration, "Voice Control", "Service", "dotNET")
			setConfigurationValue(configuration, "Voice Control", "Speaker", windowsSpeakerDropDown)
		}
		else {
			setConfigurationValue(configuration, "Voice Control", "Service", "Azure|" . azureTokenIssuerEdit . "|" . azureSubscriptionKeyEdit)
			setConfigurationValue(configuration, "Voice Control", "Speaker", azureSpeakerDropDown)
		}

		setConfigurationValue(configuration, "Voice Control", "SubscriptionKey", azureSubscriptionKeyEdit)
		setConfigurationValue(configuration, "Voice Control", "TokenIssuer", azureTokenIssuerEdit)

		GuiControlGet speakerVolumeSlider
		GuiControlGet speakerPitchSlider
		GuiControlGet speakerSpeedSlider
		GuiControlGet soXPathEdit
		GuiControlGet listenerDropDown
		GuiControlGet pushToTalkEdit
		GuiControlGet activationCommandEdit
		
		setConfigurationValue(configuration, "Voice Control", "SpeakerVolume", speakerVolumeSlider)
		setConfigurationValue(configuration, "Voice Control", "SpeakerPitch", speakerPitchSlider)
		setConfigurationValue(configuration, "Voice Control", "SpeakerSpeed", speakerSpeedSlider)
		setConfigurationValue(configuration, "Voice Control", "SoX Path", soXPathEdit)
				
		if (listenerDropDown = translate("Automatic"))
			listenerDropDown := true
		else if ((listenerDropDown = translate("Deactivated")) || (listenerDropDown = A_Space))
			listenerDropDown := false
		
		setConfigurationValue(configuration, "Voice Control", "Listener", listenerDropDown)
		setConfigurationValue(configuration, "Voice Control", "PushToTalk", (Trim(pushToTalkEdit) = "") ? false : pushToTalkEdit)
		setConfigurationValue(configuration, "Voice Control", "ActivationCommand", (Trim(activationCommandEdit) = "") ? false : activationCommandEdit)
	}
	
	loadConfigurator(configuration) {
		this.loadFromConfiguration(configuration)
		
		choices := []
		chosen := 0
		enIndex := 0
		languageCode := "en"
		
		languages := availableLanguages()
		
		for code, language in languages {
			choices.Push(language)
			
			if (language == voiceLanguageDropDown) {
				chosen := A_Index
				languageCode := code
			}
				
			if (code = "en")
				enIndex := A_Index
		}
			
		for ignore, grammarFile in getFileNames("Race Engineer.grammars.*", kUserGrammarsDirectory, kGrammarsDirectory) {
			SplitPath grammarFile, , , code
		
			if !languages.HasKey(code) {
				choices.Push(code)
				
				if (code == voiceLanguageDropDown) {
					chosen := choices.Length()
					languageCode := code
				}
					
				if (code = "en")
					enIndex := choices.Length()
			}
		}
		
		GuiControl Choose, voiceLanguageDropDown, %chosen%
		
		GuiControl Choose, voiceSynthesizerDropDown, %voiceSynthesizerDropDown%
		
		GuiControl, , azureSubscriptionKeyEdit, %azureSubscriptionKeyEdit%
		GuiControl, , azureTokenIssuerEdit, %azureTokenIssuerEdit%
		
		if (voiceSynthesizerDropDown = 1)
			this.updateWindowsVoices(configuration)
		else if (voiceSynthesizerDropDown = 2)
			this.updateDotNETVoices(configuration)
		
		this.updateAzureVoices(configuration)
		
		GuiControl, , speakerVolumeSlider, %speakerVolumeSlider%
		GuiControl, , speakerPitchSlider, %speakerPitchSlider%
		GuiControl, , speakerSpeedSlider, %speakerSpeedSlider%
		
		GuiControl, , soXPathEdit, %soXPathEdit%
		
		listenerDropDown := getConfigurationValue(configuration, "Voice Control", "Listener", true)
		
		if (listenerDropDown == true)
			listenerDropDown := translate("Automatic")
		else if (listenerDropDown == false)
			listenerDropDown := translate("Deactivated")

		chosen := inList(this.iRecognizers, listenerDropDown)
		
		if (chosen == 0)
			chosen = 1
		
		GuiControl Choose, listenerDropDown, % chosen
		
		GuiControl, , pushToTalkEdit, %pushToTalkEdit%
		GuiControl, , activationCommandEdit, %activationCommandEdit%
	}
	
	showWidgets() {
		if !voiceSynthesizerDropDown
			voiceSynthesizerDropDown := 1
		
		if (voiceSynthesizerDropDown == 1)
			this.showWindowsVoiceEditor()
		else if (voiceSynthesizerDropDown == 2)
			this.showDotNETVoiceEditor()
		else
			this.showAzureVoiceEditor()
	}
	
	hideWidgets() {
		if (this.iMode = "Windows")
			this.hideWindowsVoiceEditor()
		else if (this.iMode = "dotNET")
			this.hideDotNETVoiceEditor()
		else if (this.iMode = "Azure")
			this.hideAzureVoiceEditor()
		else {
			hideWidgets(this.iTopWidgets)
			hideWidgets(this.iWindowsVoiceWidgets)
			hideWidgets(this.iAzureVoiceWidgets)
			hideWidgets(this.iOtherWidgets)
		}
	}
	
	showWindowsVoiceEditor() {
		showWidgets(this.iTopWidgets)
		showWidgets(this.iWindowsVoiceWidgets)

		if (this.iMode == false)
			transposeWidgets(this.iOtherWidgets, 24 * this.iWindowsVoiceWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.showWindowsVoiceEditor..."
		
		showWidgets(this.iOtherWidgets)
		
		this.iMode := "Windows"
	}
	
	showDotNETVoiceEditor() {
		this.showWindowsVoiceEditor()
		
		this.iMode := "dotNET"
	}
	
	hideWindowsVoiceEditor() {
		hideWidgets(this.iTopWidgets)
		hideWidgets(this.iWindowsVoiceWidgets)
		hideWidgets(this.iOtherWidgets)
		
		if ((this.iMode == "Windows") || (this.iMode == "dotNET"))
			transposeWidgets(this.iOtherWidgets, -24 * this.iWindowsVoiceWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.hideWindowsVoiceEditor..."
		
		this.iMode := false
	}
	
	hideDotNETVoiceEditor() {
		this.hideWindowsVoiceEditor()
	}
	
	showAzureVoiceEditor() {
		showWidgets(this.iTopWidgets)
		showWidgets(this.iAzureVoiceWidgets)
		
		if (this.iMode == false)
			transposeWidgets(this.iOtherWidgets, 24 * this.iAzureVoiceWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.showAzureVoiceEditor..."
		
		showWidgets(this.iOtherWidgets)
		
		this.iMode := "Azure"
	}
	
	hideAzureVoiceEditor() {
		hideWidgets(this.iTopWidgets)
		hideWidgets(this.iAzureVoiceWidgets)
		hideWidgets(this.iOtherWidgets)
		
		if (this.iMode == "Azure")
			transposeWidgets(this.iOtherWidgets, -24 * this.iAzureVoiceWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.hideAzureVoiceEditor..."
		
		this.iMode := false
	}
	
	getCurrentLanguage() {
		GuiControlGet voiceLanguageDropDown
		
		languageCode := "en"
		languages := availableLanguages()
		
		found := false

		for code, language in availableLanguages()
			if (language = voiceLanguageDropDown) {
				found := true
				
				languageCode := code
			}
			
		if !found
			for ignore, grammarFile in getFileNames("Race Engineer.grammars.*", kUserGrammarsDirectory, kGrammarsDirectory) {
				SplitPath grammarFile, , , grammarLanguageCode
			
				if languages.HasKey(grammarLanguageCode)
					language := languages[grammarLanguageCode]
				else
					language := grammarLanguageCode
				
				if (language = voiceLanguageDropDown) {
					languageCode := grammarLanguageCode
					
					break
				}
			}
		
		return languageCode
	}
	
	updateVoices() {
		window := this.Editor.Window
		
		Gui %window%:Default
		
		GuiControlGet voiceSynthesizerDropDown
		
		if (voiceSynthesizerDropDown = 1)
			this.updateWindowsVoices()
		else if (voiceSynthesizerDropDown = 2)
			this.updateDotNETVoices()
		
		this.updateAzureVoices()
	}
	
	loadVoices(type, configuration) {
		voices := []
		
		language := this.getCurrentLanguage()
			
		voices := new SpeechSynthesizer(type, true, language).Voices[language].Clone()
		
		voices.InsertAt(1, translate("Deactivated"))
		voices.InsertAt(1, translate("Automatic"))
		
		return voices
	}
	
	loadWindowsVoices(configuration) {
		if configuration
			windowsSpeakerDropDown := getConfigurationValue(configuration, "Voice Control", "Speaker.Windows", getConfigurationValue(this.Configuration, "Voice Control", "Speaker", true))
		else {
			GuiControlGet windowsSpeakerDropDown
			
			configuration := this.Configuration
		}
		
		return this.loadVoices("Windows", configuration)
	}
	
	loadDotNETVoices(configuration)	{
		if configuration
			windowsSpeakerDropDown := getConfigurationValue(configuration, "Voice Control", "Speaker.dotNET", true)
		else {
			GuiControlGet windowsSpeakerDropDown
			
			configuration := this.Configuration
		}
	
		return this.loadVoices("dotNET", configuration)
	}
	
	updateWindowsVoices(configuration := false) {
		voices := this.loadWindowsVoices(configuration)
		
		chosen := inList(voices, windowsSpeakerDropDown)
		
		if (chosen == 0)
			chosen := 1
		
		GuiControl, , windowsSpeakerDropDown, % "|" . values2String("|", voices*)
		GuiControl Choose, windowsSpeakerDropDown, % chosen
	}
	
	updateDotNETVoices(configuration := false) {
		voices := this.loadDotNETVoices(configuration)
		
		chosen := inList(voices, windowsSpeakerDropDown)
		
		if (chosen == 0)
			chosen := 1
		
		GuiControl, , windowsSpeakerDropDown, % "|" . values2String("|", voices*)
		GuiControl Choose, windowsSpeakerDropDown, % chosen
	}
	
	updateAzureVoices(configuration := false) {
		voices := []
		
		GuiControlGet azureSubscriptionKeyEdit
		GuiControlGet azureTokenIssuerEdit
		
		if configuration
			azureSpeakerDropDown := getConfigurationValue(configuration, "Voice Control", "Speaker.Azure", true)
		else {
			configuration := this.Configuration
		
			GuiControlGet azureSpeakerDropDown
		}
		
		if (configuration && !azureSpeakerDropDown)
			azureSpeakerDropDown := getConfigurationValue(configuration, "Voice Control", "Speaker.Azure", true)
		
		if ((azureSubscriptionKeyEdit != "") && (azureTokenIssuerEdit)) {
			language := this.getCurrentLanguage()
			
			voices := new SpeechSynthesizer("Azure|" . azureTokenIssuerEdit . "|" . azureSubscriptionKeyEdit, true, language).Voices[language].Clone()
		}
		
		voices.InsertAt(1, translate("Deactivated"))
		voices.InsertAt(1, translate("Automatic"))
		
		chosen := inList(voices, azureSpeakerDropDown)
		
		if (chosen == 0)
			chosen := 1
		
		GuiControl, , azureSpeakerDropDown, % "|" . values2String("|", voices*)
		GuiControl Choose, azureSpeakerDropDown, % chosen
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

updateVoices() {
	VoiceControlConfigurator.Instance.updateVoices()
}

updateAzureVoices() {
	VoiceControlConfigurator.Instance.updateAzureVoices()
}

showWidgets(widgets) {
	for ignore, widget in widgets
		for ignore, widgetPart in widget {
			GuiControl Enable, %widgetPart%
			GuiControl Show, %widgetPart%
		}
}

hideWidgets(widgets) {
	for ignore, widget in widgets
		for ignore, widgetPart in widget {
			GuiControl Disable, %widgetPart%
			GuiControl Hide, %widgetPart%
		}
}

transposeWidgets(widgets, offset, correction) {
	for ignore, widget in widgets
		for ignore, widgetPart in widget {
			GuiControlGet tempPos, Pos, %widgetPart%
		
			tempPosY := tempPosY + offset - correction
			tempPosX := tempPosX
			
			GuiControl Move, %widgetPart%, y%tempPosY%
	}
}

chooseVoiceSynthesizer() {
	oldChoice := voiceSynthesizerDropDown
	
	GuiControlGet voiceSynthesizerDropDown
	
	if (oldChoice == 1)
		VoiceControlConfigurator.Instance.hideWindowsVoiceEditor()
	else if (oldChoice == 2)
		VoiceControlConfigurator.Instance.hideDotNETVoiceEditor()
	else
		VoiceControlConfigurator.Instance.hideAzureVoiceEditor()
	
	if (voiceSynthesizerDropDown == 1)
		VoiceControlConfigurator.Instance.showWindowsVoiceEditor()
	else if (voiceSynthesizerDropDown == 2)
		VoiceControlConfigurator.Instance.showDotNETVoiceEditor()
	else
		VoiceControlConfigurator.Instance.showAzureVoiceEditor()
	
	if ((oldChoice <= 2) && (voiceSynthesizerDropDown <= 2))
		VoiceControlConfigurator.Instance.updateVoices()
}

setPTTHotkey(hotkey) {
	if hotkey is not integer
	{
		pushToTalkEdit := hotkey
		
		window := VoiceControlConfigurator.Instance.Editor.Window
		
		SoundPlay %kResourcesDirectory%Sounds\Activated.wav
		
		Gui %window%:Default
		GuiControl Text, pushToTalkEdit, %pushToTalkEdit%
		
		VoiceControlConfigurator.Instance.Editor.toggleTriggerDetector()
	}
}

getPTTHotkey() {
	protectionOn()
	
	try {
		VoiceControlConfigurator.Instance.Editor.toggleTriggerDetector("setPTTHotkey")
	}
	finally {
		protectionOff()
	}
}

chooseSoXPath() {
	GuiControlGet soXPathEdit
	
	OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Select", "Select", "Cancel"]))
	FileSelectFolder directory, *%soXPathEdit%, 0, % translate("Select SoX folder...")
	OnMessage(0x44, "")
	
	if (directory != "")
		GuiControl Text, soXPathEdit, %directory%
}

initializeVoiceControlConfigurator() {
	if kConfigurationEditor {
		editor := ConfigurationEditor.Instance
		
		editor.registerConfigurator(translate("Voice Control"), new VoiceControlConfigurator(editor, editor.Configuration))
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeVoiceControlConfigurator()