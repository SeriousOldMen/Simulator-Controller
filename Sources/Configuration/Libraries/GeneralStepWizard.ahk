﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - General Step Wizard             ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; GeneralStepWizard                                                       ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class GeneralStepWizard extends ButtonBoxPreviewStepWizard {
	iVoiceControlConfigurator := false
	
	iLanguage := getLanguage()
	iModeSelectors := []
	
	iModeSelectorsLabelHandle := false
	iModeSelectorsListHandle := false
	
	Pages[] {
		Get {
			return 1
		}
	}
	
	createGui(wizard, x, y, width, height) {
		static generalInfoText
		
		window := this.Window
		
		Gui %window%:Default
		
		generalIconHandle := false
		generalLabelHandle := false
		generalInfoTextHandle := false
		
		labelWidth := width - 30
		labelX := x + 45
		labelY := y + 8
		
		Gui %window%:Font, s10 Bold, Arial
		
		Gui %window%:Add, Picture, x%x% y%y% w30 h30 HWNDgeneralIconHandle Hidden, %kResourcesDirectory%Setup\Images\Gears.ico
		Gui %window%:Add, Text, x%labelX% y%labelY% w%labelWidth% h26 HWNDgeneralLabelHandle Hidden, % translate("Global Configuration")
		
		Gui %window%:Font, s8 Norm, Arial
		
		modeSelectorsLabelHandle := false
		modeSelectorsListHandle := false
	
		secondX := x + 105
		secondWidth := width - 105
		
		Gui %window%:Add, Text, x%x% yp+30 w105 h23 +0x200 HWNDmodeSelectorsLabelHandle Hidden, % translate("Mode Selector")
		
		Gui %window%:Font, s8 Bold, Arial
		
		Gui %window%:Add, ListBox, x%secondX% yp w120 h60 Disabled HWNDmodeSelectorsListHandle Hidden
		
		Gui %window%:Font, s8 Norm, Arial
		
		configurator := new VoiceControlConfigurator(this)
		
		this.iVoiceControlConfigurator := configurator
		
		configurator.createGui(this, secondX + 140, labelY + 33, width - 140 - secondX + x, height, 0)
		configurator.hideWidgets()
		
		info := substituteVariables(getConfigurationValue(this.SetupWizard.Definition, "Setup.General", "General.General.Info." . getLanguage()))
		info := "<div style='font-family: Arial, Helvetica, sans-serif' style='font-size: 11px'>" . info . "</div>"

		Gui %window%:Add, ActiveX, x%x% yp+30 w%width% h180 HWNDgeneralInfoTextHandle VgeneralInfoText Hidden, shell explorer

		html := "<html><body style='background-color: #D0D0D0' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>" . info . "</body></html>"

		generalInfoText.Navigate("about:blank")
		generalInfoText.Document.Write(html)
		
		this.iModeSelectorsLabelHandle := modeSelectorsLabelHandle
		this.iModeSelectorsListHandle := modeSelectorsListHandle
		
		this.registerWidgets(1, generalIconHandle, generalLabelHandle, modeSelectorsLabelHandle, modeSelectorsListHandle, generalInfoTextHandle)
	}
	
	registerWidget(page, widget) {
		if (page = this.iVoiceControlConfigurator)
			base.registerWidget(1, widget)
		else
			base.registerWidget(page, widget)
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		wizard := this.SetupWizard
		
		setConfigurationSectionValues(configuration, "Splash Window", getConfigurationSectionValues(this.SetupWizard.Definition, "Splash Window"))
		setConfigurationSectionValues(configuration, "Splash Themes", getConfigurationSectionValues(this.SetupWizard.Definition, "Splash Themes"))
		
		setConfigurationValue(configuration, "Configuration", "Start With Windows", false)
		setConfigurationValue(configuration, "Configuration", "Log Level", "Warn")
		setConfigurationValue(configuration, "Configuration", "Debug", false)
		
		setConfigurationValue(configuration, "Configuration", "Silent Mode", false)
		setConfigurationValue(configuration, "Configuration", "Language", this.iLanguage)
		
		if wizard.isSoftwareInstalled("NirCmd")
			setConfigurationValue(configuration, "Configuration", "NirCmd Path", wizard.softwarePath("NirCmd"))
		
		if wizard.isModuleSelected("Voice Control") {
			voiceControlConfiguration := readConfiguration(kUserHomeDirectory . "Install\Voice Control Configuration.ini")
		
			for ignore, section in ["Voice Control"] {
				subConfiguration := getConfigurationSectionValues(voiceControlConfiguration, section, false)
				
				if subConfiguration
					setConfigurationSectionValues(configuration, section, subConfiguration)
			}
		}
		
		arguments := ""
		
		if (this.iModeSelectors.Length() > 0)
			arguments := ("modeSelectors: " . values2String(A_Space, this.iModeSelectors*))
		
		new Plugin("System", false, true, "", arguments).saveToConfiguration(configuration)
	}
	
	reset() {
		base.reset()
		
		this.iVoiceControlConfigurator := false
		this.iModeSelectorsLabelHandle := false
		this.iModeSelectorsListHandle := false
		this.iModeSelectors := []
	}
	
	showPage(page) {
		base.showPage(page)
		
		this.iModeSelectors := this.SetupWizard.getModeSelectors()
		
		this.iVoiceControlConfigurator.hideWidgets()
			
		if this.SetupWizard.isModuleSelected("Voice Control") {
			configuration := this.SetupWizard.getSimulatorConfiguration()
			voiceControlConfiguration := readConfiguration(kUserHomeDirectory . "Install\Voice Control Configuration.ini")
		
			for ignore, section in ["Voice Control"] {
				subConfiguration := getConfigurationSectionValues(voiceControlConfiguration, section, false)
				
				if subConfiguration
					setConfigurationSectionValues(configuration, section, subConfiguration)
			}
		
			this.iVoiceControlConfigurator.loadConfigurator(configuration)
			this.iVoiceControlConfigurator.showWidgets()
		}
			
		if this.SetupWizard.isModuleSelected("Button Box") {
			listBox := this.iModeSelectorsListHandle
			
			GuiControl Disable, %listBox%
			GuiControl, , %listBox%, % "|" . values2String("|", this.iModeSelectors*)
		}
		else {
			GuiControl Hide, % this.iModeSelectorsLabelHandle
			GuiControl Hide, % this.iModeSelectorsListHandle
		}
	}
	
	hidePage(page) {
		this.iVoiceControlConfigurator.hideWidgets()
			
		if base.hidePage(page) {
			this.SetupWizard.setModeSelectors(this.iModeSelectors)
			
			configuration := newConfiguration()
			
			this.iVoiceControlConfigurator.saveToConfiguration(configuration)
			
			voiceControlConfiguration := newConfiguration()
	
			for ignore, section in ["Voice Control"] {
				subConfiguration := getConfigurationSectionValues(configuration, section, false)
				
				if subConfiguration
					setConfigurationSectionValues(voiceControlConfiguration, section, subConfiguration)
			}
				
			writeConfiguration(kUserHomeDirectory . "Install\Voice Control Configuration.ini", voiceControlConfiguration)
			
			return true
		}
		else
			return false
	}
	
	addModeSelector(preview, function, control, row, column) {
		if !inList(this.iModeSelectors, function) {
			this.iModeSelectors.Push(function)
			
			SoundPlay %kResourcesDirectory%Sounds\Activated.wav
			
			listBox := this.iModeSelectorsListHandle
			
			GuiControl, , %listBox%, % "|" . values2String("|", this.iModeSelectors*)
			
			this.SetupWizard.addControllerStaticFunction("System", function, translate("Mode Selector"))
			
			preview.setLabel(row, column, translate("Mode Selector"))
		}
	}
			
	removeModeSelector(preview, function, control, row, column) {
		index := inList(this.iModeSelectors, function)
		
		if index {
			this.iModeSelectors.RemoveAt(index)
			
			SoundPlay %kResourcesDirectory%Sounds\Activated.wav
			
			listBox := this.iModeSelectorsListHandle
			
			GuiControl, , %field%, % "|" . values2String("|", this.iModeSelectors*)
			
			this.SetupWizard.removeControllerStaticFunction("System", function)
			
			preview.setLabel(row, column, ConfigurationItem.splitDescriptor(control)[2])
			
			for ignore, function in this.SetupWizard.getControllerStaticFunctions()
				if preview.findFunction(function[1], row, column)
					preview.setLabel(row, column, function[2])
		}
	}
	
	controlClick(preview, element, function, row, column, isEmpty) {
		if (element[1] = "Control") {
			menuItem := (translate(element[1] . ": ") . element[2] . " (" . row . " x " . column . ")")
				
			try {
				Menu ContextMenu, DeleteAll
			}
			catch exception {
				; ignore
			}
			
			window := SetupWizard.Instance.WizardWindow
			
			Gui %window%:Default
			
			Menu ContextMenu, Add, %menuItem%, menuIgnore
			Menu ContextMenu, Disable, %menuItem%
			Menu ContextMenu, Add
			
			menuItem := translate("Set Mode Selector")
			handler := ObjBindMethod(this, "addModeSelector", preview, function, element[2], row, column)
			
			Menu ContextMenu, Add, %menuItem%, %handler%
			
			if inList(this.iModeSelectors, function)
				Menu ContextMenu, Disable, %menuItem%
			
			menuItem := translate("Clear Mode Selector")
			handler := ObjBindMethod(this, "removeModeSelector", preview, function, element[2], row, column)
			
			Menu ContextMenu, Add, %menuItem%, %handler%
			
			if !inList(this.iModeSelectors, function)
				Menu ContextMenu, Disable, %menuItem%
			
			Menu ContextMenu, Show
		}
	}
	
	toggleTriggerDetector(callback := false) {
		this.SetupWizard.toggleTriggerDetector(callback)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeGeneralStepWizard() {
	SetupWizard.Instance.registerStepWizard(new GeneralStepWizard(SetupWizard.Instance, "General", kSimulatorConfiguration))
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeGeneralStepWizard()