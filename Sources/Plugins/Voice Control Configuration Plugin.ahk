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
global voiceRecognizerLabel
global voiceRecognizerDropDown = 1
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
	
	iSynthesizerMode := false
	iRecognizerMode := false
	
	iTopWidgets := []
	iBottomWidgets := []
	iWindowsSynthesizerWidgets := []
	iAzureSynthesizerWidgets := []
	iAzureRecognizerWidgets := []
	iOtherWidgets := []
	
	iTopAzureCredentialsVisible := false
	iBottomAzureCredentialsVisible := false
	
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
		x4 := x2 + 24 + 8
		w4 := width - (x4 - x)
		
		Gui %window%:Add, Text, x%x% y%y% w110 h23 +0x200 HWNDwidget1 Hidden, % translate("Language")
		Gui %window%:Add, DropDownList, x%x1% yp w160 Choose%chosen% HWNDwidget2 VvoiceLanguageDropDown GupdateVoices Hidden, % values2String("|", choices*)
		
		choices := ["Windows (Win32)", "Windows (.NET)", "Azure Cognitive Services"]
		chosen := voiceSynthesizerDropDown
		
		Gui %window%:Add, Text, x%x% yp+32 w110 h23 +0x200 HWNDwidget3 Section Hidden, % translate("Speech Synthesizer")
		Gui %window%:Add, DropDownList, AltSubmit x%x1% yp w160 Choose%chosen% HWNDwidget4 gchooseVoiceSynthesizer VvoiceSynthesizerDropDown Hidden, % values2String("|", choices*)
		
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
		
		this.iWindowsSynthesizerWidgets := [["windowsSpeakerLabel", "windowsSpeakerDropDown"]]
		
		Gui %window%:Add, Text, x%x% yp+28 w140 h23 +0x200 HWNDwidget12 VsoXPathLabel1 Hidden, % translate("SoX Folder (optional)")
		Gui %window%:Font, c505050 s8
		Gui %window%:Add, Text, x%x0% yp+18 w133 h23 HWNDwidget13 VsoXPathLabel2 Hidden, % translate("(Post Processing)")
		Gui %window%:Font
		Gui %window%:Add, Edit, x%x1% yp-19 w%w2% h21 HWNDwidget14 VsoXPathEdit Hidden, %soXPathEdit%
		Gui %window%:Add, Button, x%x3% yp w23 h23 gchooseSoXPath HWNDwidget15 VsoXPathButton Hidden, % translate("...")

		choices := ["Windows (Server)", "Windows (Desktop)", "Azure Cognitive Services"]
		chosen := voiceRecognizerDropDown
		
		Gui %window%:Add, Text, x%x% yp+42 w110 h23 +0x200 HWNDwidget21 vvoiceRecognizerLabel Hidden, % translate("Speech Recognizer")
		Gui %window%:Add, DropDownList, AltSubmit x%x1% yp w160 Choose%chosen% HWNDwidget29 gchooseVoiceRecognizer VvoiceRecognizerDropDown Hidden, % values2String("|", choices*)
		
		if (voiceRecognizerDropDown = 3)
			recognizers := new SpeechRecognizer("Azure|" . azureTokenIssuerEdit . "|" . azureSubscriptionKeyEdit, false, this.getCurrentLanguage(), true).getRecognizerList().Clone()
		else
			recognizers := new SpeechRecognizer((voiceRecognizerDropDown = 1) ? "Server" : "Desktop", false, this.getCurrentLanguage(), true).getRecognizerList().Clone()
		
		Loop % recognizers.Length()
			recognizers[A_Index] := recognizers[A_Index].Name
		
		recognizers.InsertAt(1, translate("Deactivated"))
		recognizers.InsertAt(1, translate("Automatic"))
		
		chosen := inList(recognizers, listenerDropDown)
		
		this.iRecognizers := recognizers
		
		if (chosen == 0)
			chosen := 1
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget16 VlistenerLabel Hidden, % translate("Recognizer Engine")
		Gui %window%:Add, DropDownList, x%x1% yp w%w1% Choose%chosen% HWNDwidget17 VlistenerDropDown Hidden, % values2String("|", recognizers*)
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget18 VpushToTalkLabel Hidden, % translate("P2T / Activation")
		Gui %window%:Add, Edit, x%x1% yp w110 h21 HWNDwidget19 VpushToTalkEdit Hidden, %pushToTalkEdit%
		Gui %window%:Add, Button, x%x2% yp-1 w23 h23 HWNDwidget20 ggetPTTHotkey VpushToTalkButton Hidden
		setButtonIcon(widget20, kIconsDirectory . "Key.ico", 1)
		Gui %window%:Add, Edit, x%x4% yp+1 w%w4% h21 HWNDwidget22 VactivationCommandEdit Hidden, %activationCommandEdit%
		
		this.iBottomWidgets := [["listenerLabel", "listenerDropDown"]
							  , ["pushToTalkLabel", "pushToTalkEdit", "pushToTalkButton", "activationCommandEdit"]]
		this.iOtherWidgets := [["windowsSpeakerVolumeLabel", "speakerVolumeSlider"]
							 , ["windowsSpeakerPitchLabel", "speakerPitchSlider"]
							 , ["windowsSpeakerSpeedLabel", "speakerSpeedSlider"]
							 , ["soXPathLabel1", "soXPathLabel2", "soXPathEdit", "soXPathButton"]
							 , ["voiceRecognizerLabel", "voiceRecognizerDropDown"], ["listenerLabel", "listenerDropDown"]
							 , ["pushToTalkLabel", "pushToTalkEdit", "pushToTalkButton", "activationCommandEdit"]]
		
		Gui %window%:Add, Text, x%x% ys+24 w140 h23 +0x200 HWNDwidget23 VazureSubscriptionKeyLabel Hidden, % translate("Subscription Key")
		Gui %window%:Add, Edit, x%x1% yp w%w1% h21 HWNDwidget24 VazureSubscriptionKeyEdit GupdateAzureVoices Hidden, %azureSubscriptionKeyEdit%
		
		Gui %window%:Add, Text, x%x% yp+24 w140 h23 +0x200 HWNDwidget25 VazureTokenIssuerLabel Hidden, % translate("Token Issuer Endpoint")
		Gui %window%:Add, Edit, x%x1% yp w%w1% h21 HWNDwidget26 VazureTokenIssuerEdit GupdateAzureVoices Hidden, %azureTokenIssuerEdit%
		
		voices := [translate("Automatic"), translate("Deactivated")]
		
		Gui %window%:Add, Text, x%x% yp+24 w110 h23 +0x200 HWNDwidget27 VazureSpeakerLabel Hidden, % translate("Voice")
		Gui %window%:Add, DropDownList, x%x1% yp w%w1% HWNDwidget28 VazureSpeakerDropDown Hidden, % values2String("|", voices*)
		
		this.iAzureSynthesizerWidgets := [["azureSubscriptionKeyLabel", "azureSubscriptionKeyEdit"], ["azureTokenIssuerLabel", "azureTokenIssuerEdit"], ["azureSpeakerLabel", "azureSpeakerDropDown"]]
		this.iAzureRecognizerWidgets := [["azureSubscriptionKeyLabel", "azureSubscriptionKeyEdit"], ["azureTokenIssuerLabel", "azureTokenIssuerEdit"]]

		this.updateVoices()
		
		Loop 28
			editor.registerWidget(this, widget%A_Index%)
		
		hideWidgets(this.iTopWidgets)
		hideWidgets(this.iWindowsSynthesizerWidgets)
		hideWidgets(this.iAzureSynthesizerWidgets)
		hideWidgets(this.iOtherWidgets)
		
		if (voiceSynthesizerDropDown == 1)
			this.showWindowsSynthesizerEditor()
		else if (voiceSynthesizerDropDown == 2)
			this.showDotNETSynthesizerEditor()
		else
			this.showAzureSynthesizerEditor()
		
		if (voiceRecognizerDropDown == 1)
			this.showServerRecognizerEditor()
		else if (voiceRecognizerDropDown== 2)
			this.showDesktopRecognizerEditor()
		else
			this.showAzureRecognizerEditor()
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		languageCode := getConfigurationValue(configuration, "Voice Control", "Language", getLanguage())
		languages := availableLanguages()
		
		if languages.HasKey(languageCode)
			voiceLanguageDropDown := languages[languageCode]
		else
			voiceLanguageDropDown := languageCode
		
		synthesizer := getConfigurationValue(configuration, "Voice Control", "Synthesizer", "dotNET")
		if (InStr(synthesizer, "Azure") == 1)
			synthesizer := "Azure"
		
		recognizer := getConfigurationValue(configuration, "Voice Control", "Recognizer", "Desktop")
		if (InStr(recognizer, "Azure") == 1)
			recognizer := "Azure"
		
		voiceSynthesizerDropDown := inList(["Windows", "dotNET", "Azure"], synthesizer)
		voiceRecognizerDropDown := inList(["Server", "Desktop", "Azure"], recognizer)
		
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
		
		if this.Configuration {
			if (windowsSpeakerDropDown == true)
				windowsSpeakerDropDown := translate("Automatic")
			else if (windowsSpeakerDropDown == false)
				windowsSpeakerDropDown := translate("Deactivated")
			
			if (azureSpeakerDropDown == true)
				azureSpeakerDropDown := translate("Automatic")
			else if (azureSpeakerDropDown == false)
				azureSpeakerDropDown := translate("Deactivated")
		
			if (listenerDropDown == true)
				listenerDropDown := translate("Automatic")
			else if (listenerDropDown == false)
				listenerDropDown := translate("Deactivated")
		}
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)

		window := this.Editor.Window
		
		Gui %window%:Default

		setConfigurationValue(configuration, "Voice Control", "Language", this.getCurrentLanguage())
			
		GuiControlGet voiceSynthesizerDropDown
		GuiControlGet voiceRecognizerDropDown
		GuiControlGet windowsSpeakerDropDown
		GuiControlGet azureSpeakerDropDown
		GuiControlGet azureSubscriptionKeyEdit
		GuiControlGet azureTokenIssuerEdit
		
		if (windowsSpeakerDropDown = translate("Automatic"))
			windowsSpeakerDropDown := true
		else if ((windowsSpeakerDropDown = translate("Deactivated")) || (windowsSpeakerDropDown = A_Space))
			windowsSpeakerDropDown := false

		if (azureSpeakerDropDown = translate("Automatic"))
			azureSpeakerDropDown := true
		else if ((azureSpeakerDropDown = translate("Deactivated")) || (azureSpeakerDropDown = A_Space))
			azureSpeakerDropDown := false
		
		if (voiceSynthesizerDropDown = 1) {
			setConfigurationValue(configuration, "Voice Control", "Synthesizer", "Windows")
			setConfigurationValue(configuration, "Voice Control", "Speaker", windowsSpeakerDropDown)
			setConfigurationValue(configuration, "Voice Control", "Speaker.Windows", windowsSpeakerDropDown)
			setConfigurationValue(configuration, "Voice Control", "Speaker.dotNET", true)
		}
		else if (voiceSynthesizerDropDown = 2) {
			setConfigurationValue(configuration, "Voice Control", "Synthesizer", "dotNET")
			setConfigurationValue(configuration, "Voice Control", "Speaker", windowsSpeakerDropDown)
			setConfigurationValue(configuration, "Voice Control", "Speaker.Windows", true)
			setConfigurationValue(configuration, "Voice Control", "Speaker.dotNET", windowsSpeakerDropDown)
		}
		else {
			setConfigurationValue(configuration, "Voice Control", "Synthesizer", "Azure|" . azureTokenIssuerEdit . "|" . azureSubscriptionKeyEdit)
			setConfigurationValue(configuration, "Voice Control", "Speaker", azureSpeakerDropDown)
			setConfigurationValue(configuration, "Voice Control", "Speaker.Windows", true)
			setConfigurationValue(configuration, "Voice Control", "Speaker.dotNET", true)
		}
		
		setConfigurationValue(configuration, "Voice Control", "Speaker.Azure", azureSpeakerDropDown)
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
		
		if (voiceRecognizerDropDown <= 2)
			setConfigurationValue(configuration, "Voice Control", "Recognizer", ["Server", "Desktop"][voiceRecognizerDropDown])
		else
			setConfigurationValue(configuration, "Voice Control", "Recognizer", "Azure|" . azureTokenIssuerEdit . "|" . azureSubscriptionKeyEdit)
		
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
		GuiControl Choose, voiceRecognizerDropDown, %voiceRecognizerDropDown%
		
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

		if (voiceRecognizerDropDown = 3)
			recognizers := new SpeechRecognizer("Azure|" . azureTokenIssuerEdit . "|" . azureSubscriptionKeyEdit, false, this.getCurrentLanguage(), true).getRecognizerList().Clone()
		else
			recognizers := new SpeechRecognizer((voiceRecognizerDropDown = 1) ? "Server" : "Desktop", false, this.getCurrentLanguage(), true).getRecognizerList().Clone()
		
		Loop % recognizers.Length()
			recognizers[A_Index] := recognizers[A_Index].Name
		
		recognizers.InsertAt(1, translate("Deactivated"))
		recognizers.InsertAt(1, translate("Automatic"))
		
		chosen := inList(recognizers, listenerDropDown)
		
		if (chosen == 0)
			chosen = 1
		
		GuiControl, , listenerDropDown, % "|" . values2String("|", recognizers*)
		GuiControl Choose, listenerDropDown, % chosen
		
		GuiControl, , pushToTalkEdit, %pushToTalkEdit%
		GuiControl, , activationCommandEdit, %activationCommandEdit%
	}
	
	showWidgets() {
		GuiControlGet voiceSynthesizerDropDown
		
		if !voiceSynthesizerDropDown
			voiceSynthesizerDropDown := 1
		
		if (voiceSynthesizerDropDown == 1)
			this.showWindowsSynthesizerEditor()
		else if (voiceSynthesizerDropDown == 2)
			this.showDotNETSynthesizerEditor()
		else
			this.showAzureSynthesizerEditor()
		
		GuiControlGet voiceRecognizerDropDown
		
		if !voiceRecognizerDropDown
			voiceRecognizerDropDown := 1
		
		if (voiceRecognizerDropDown == 1)
			this.showServerRecognizerEditor()
		else if (voiceRecognizerDropDown == 2)
			this.showDesktopRecognizerEditor()
		else
			this.showAzureRecognizerEditor()
	}
	
	hideWidgets() {
		if (this.iSynthesizerMode = "Windows")
			this.hideWindowsSynthesizerEditor()
		else if (this.iSynthesizerMode = "dotNET")
			this.hideDotNETSynthesizerEditor()
		else if (this.iSynthesizerMode = "Azure")
			this.hideAzureSynthesizerEditor()
		else {
			hideWidgets(this.iTopWidgets)
			hideWidgets(this.iWindowsSynthesizerWidgets)
			hideWidgets(this.iAzureSynthesizerWidgets)
			hideWidgets(this.iOtherWidgets)
		}
		
		if (this.iRecognizerMode = "Server")
			this.hideServerRecognizerEditor()
		else if (this.iRecognizerMode = "Desktop")
			this.hideDesktopRecognizerEditor()
		else if (this.iRecognizerMode = "Azure")
			this.hideAzureRecognizerEditor()
	
		this.iTopAzureCredentialsVisible := false
		this.iBottomAzureCredentialsVisible := false
	}
	
	showWindowsSynthesizerEditor() {
		showWidgets(this.iTopWidgets)
		showWidgets(this.iWindowsSynthesizerWidgets)

		if (this.iSynthesizerMode == false)
			transposeWidgets(this.iOtherWidgets, 24 * this.iWindowsSynthesizerWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.showWindowsSynthesizerEditor..."
		
		showWidgets(this.iOtherWidgets)
		
		this.iSynthesizerMode := "Windows"
	}
	
	showDotNETSynthesizerEditor() {
		this.showWindowsSynthesizerEditor()
		
		this.iSynthesizerMode := "dotNET"
	}
	
	hideWindowsSynthesizerEditor() {
		hideWidgets(this.iTopWidgets)
		hideWidgets(this.iWindowsSynthesizerWidgets)
		hideWidgets(this.iOtherWidgets)
		
		if ((this.iSynthesizerMode == "Windows") || (this.iSynthesizerMode == "dotNET"))
			transposeWidgets(this.iOtherWidgets, -24 * this.iWindowsSynthesizerWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.hideWindowsSynthesizerEditor..."
		
		this.iSynthesizerMode := false
	}
	
	hideDotNETSynthesizerEditor() {
		this.hideWindowsSynthesizerEditor()
	}
	
	showAzureSynthesizerEditor() {
		wasOpen := false
		
		if this.iBottomAzureCredentialsVisible {
			wasOpen := true
			
			this.hideAzureRecognizerEditor()
		}
		
		showWidgets(this.iTopWidgets)
		showWidgets(this.iAzureSynthesizerWidgets)
		
		this.iTopAzureCredentialsVisible := true
		
		if (this.iSynthesizerMode == false)
			transposeWidgets(this.iOtherWidgets, 24 * this.iAzureSynthesizerWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.showAzureSynthesizerEditor..."
		
		if wasOpen
			this.showAzureRecognizerEditor()
		
		showWidgets(this.iOtherWidgets)
		
		this.iSynthesizerMode := "Azure"
	}
	
	hideAzureSynthesizerEditor() {
		wasOpen := false
		
		if (this.iRecognizerMode = "Azure") {
			wasOpen := true
			
			this.hideAzureRecognizerEditor()
		}
		
		hideWidgets(this.iTopWidgets)
		hideWidgets(this.iAzureSynthesizerWidgets)
		hideWidgets(this.iOtherWidgets)
		
		this.iTopAzureCredentialsVisible := false
		
		if (this.iSynthesizerMode == "Azure")
			transposeWidgets(this.iOtherWidgets, -24 * this.iAzureSynthesizerWidgets.Length(), this.iCorrection)
		else
			Throw "Internal error detected in VoiceControlConfigurator.hideAzureSynthesizerEditor..."
		
		if wasOpen
			this.showAzureRecognizerEditor()
		
		this.iSynthesizerMode := false
	}
	
	showServerRecognizerEditor() {
		this.iRecognizerMode := "Server"
	}
	
	hideServerRecognizerEditor() {
		this.iRecognizerMode := false
	}
	
	showDesktopRecognizerEditor() {
		this.iRecognizerMode := "Desktop"
	}
	
	hideDesktopRecognizerEditor() {
		this.iRecognizerMode := false
	}
	
	showAzureRecognizerEditor() {
		if !this.iTopAzureCredentialsVisible {
			if (this.iRecognizerMode == false) {
				transposeWidgets(this.iAzureRecognizerWidgets, (24 * 7) - 3, this.iCorrection)
				showWidgets(this.iAzureRecognizerWidgets)
				transposeWidgets(this.iBottomWidgets, 24 * this.iAzureRecognizerWidgets.Length(), this.iCorrection)
			}
			else
				Throw "Internal error detected in VoiceControlConfigurator.showAzureRecognizerEditor..."
			
			this.iBottomAzureCredentialsVisible := true
		}
		
		this.iRecognizerMode := "Azure"
	}
	
	hideAzureRecognizerEditor() {
		if !this.iTopAzureCredentialsVisible {
			if (this.iRecognizerMode == "Azure") {
				hideWidgets(this.iAzureRecognizerWidgets)
				transposeWidgets(this.iAzureRecognizerWidgets, (-24 * 7) + 3, this.iCorrection)
				transposeWidgets(this.iBottomWidgets, -24 * this.iAzureRecognizerWidgets.Length(), this.iCorrection)
			}
			else
				Throw "Internal error detected in VoiceControlConfigurator.hideAzureRecognizerEditor..."
			
			this.iBottomAzureCredentialsVisible := false
		}
		
		this.iRecognizerMode := false
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
	configurator := VoiceControlConfigurator.Instance
	oldChoice := voiceSynthesizerDropDown
	
	GuiControlGet voiceSynthesizerDropDown
	
	if (oldChoice == 1)
		configurator.hideWindowsSynthesizerEditor()
	else if (oldChoice == 2)
		configurator.hideDotNETSynthesizerEditor()
	else
		configurator.hideAzureSynthesizerEditor()
	
	if (voiceSynthesizerDropDown == 1)
		configurator.showWindowsSynthesizerEditor()
	else if (voiceSynthesizerDropDown == 2)
		configurator.showDotNETSynthesizerEditor()
	else
		configurator.showAzureSynthesizerEditor()
	
	if ((oldChoice <= 2) && (voiceSynthesizerDropDown <= 2))
		configurator.updateVoices()
}

chooseVoiceRecognizer() {
	configurator := VoiceControlConfigurator.Instance
	oldChoice := voiceRecognizerDropDown
	
	GuiControlGet voiceRecognizerDropDown
	
	if (oldChoice == 1)
		configurator.hideServerRecognizerEditor()
	else if (oldChoice == 2)
		configurator.hideDesktopRecognizerEditor()
	else
		configurator.hideAzureRecognizerEditor()
	
	if (voiceRecognizerDropDown == 1)
		configurator.showServerRecognizerEditor()
	else if (voiceRecognizerDropDown == 2)
		configurator.showDesktopRecognizerEditor()
	else {
		GuiControlGet azureSubscriptionKeyEdit
		GuiControlGet azureTokenIssuerEdit
		
		recognizers := new SpeechRecognizer("Azure|" . azureTokenIssuerEdit . "|" . azureSubscriptionKeyEdit, false, configurator.getCurrentLanguage(), true).getRecognizerList().Clone()
		
		configurator.showAzureRecognizerEditor()
	}
	
	if (voiceRecognizerDropDown <= 2)
		recognizers := new SpeechRecognizer((voiceRecognizerDropDown = 1) ? "Server" : "Desktop", false, configurator.getCurrentLanguage(), true).getRecognizerList().Clone()
			
	Loop % recognizers.Length()
		recognizers[A_Index] := recognizers[A_Index].Name
	
	recognizers.InsertAt(1, translate("Deactivated"))
	recognizers.InsertAt(1, translate("Automatic"))
	
	chosen := 1
	
	GuiControl, , listenerDropDown, % "|" . values2String("|", recognizers*)
	GuiControl Choose, listenerDropDown, 1
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