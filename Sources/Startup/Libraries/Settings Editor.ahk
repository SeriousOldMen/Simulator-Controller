﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Settings Editor                 ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                   Public Constant Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

global kSave = "Save"
global kContinue = "Continue"
global kCancel = "Cancel"
global kEditModes = "Edit"


;;;-------------------------------------------------------------------------;;;
;;;                   Private Variable Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global vRestart = false

global trayTipEnabled
global trayTipDurationInput
global trayTipSimulationEnabled
global trayTipSimulationDurationInput
global buttonBoxEnabled
global buttonBoxDurationInput
global buttonBoxSimulationEnabled
global buttonBoxSimulationDurationInput


;;;-------------------------------------------------------------------------;;;
;;;                    Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;
			
initializePicturesList(pictures := "") {
	Gui ListView, % picturesListViewHandle
		
	LV_Delete()
	
	pictures := string2Values(",", pictures)
	
	picturesListViewImages := IL_Create(pictures.Length())
		
	for ignore, picture in pictures
		IL_Add(picturesListViewImages, LoadPicture(getFileName(picture, kUserSplashMediaDirectory, kSplashMediaDirectory), "W32 H32"), 0xFFFFFF, false)
	
	LV_SetImageList(picturesListViewImages)
	
	Loop % pictures.Length()
		LV_Add("Check Icon" . A_Index, pictures[A_Index])
		
	LV_ModifyCol()
}

loadEditor(item) {
	themeTypeDropDown := (item[1] == "Picture Carousel") ? 1 : 2
	themeNameEdit := item[2]
	soundFilePathEdit := item[4]
		
	GuiControl Choose, themeTypeDropDown, %themeTypeDropDown%
	GuiControl Text, themeNameEdit, %themeNameEdit%
	GuiControl Text, soundFilePathEdit, %soundFilePathEdit%
	
	if (themeTypeDropDown == 2)
		videoFilePathEdit := item[3]
	else
		videoFilePathEdit := ""
		
	GuiControl Text, videoFilePathEdit, %videoFilePathEdit%
	
	if (themeTypeDropDown == 1) {
		this.initializePicturesList(item[3])
		
		picturesDurationEdit := item[5]
		
		GuiControl Text, picturesDurationEdit, %picturesDurationEdit%
	}
	else
		this.initializePicturesList("")
	
	this.updateEditor()
}

saveModes() {
	editModes(kSave)
}

cancelModes() {
	editModes(kCancel)
}

saveSettings() {
	editSettings(kSave)
}

continueSettings() {
	editSettings(kContinue)
}

cancelSettings() {
	editSettings(kCancel)
}

setInputState(input, enabled) {
	if enabled
		GuiControl Enable, %input%
	else {
		GuiControl Disable, %input%
		GuiControl Text, %input%, 0
	}
}

startConfiguration() {
	try {
		RunWait % kBinariesDirectory . "Simulator Configuration.exe"
	}
	catch exception {
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
		error := translate("Error")
		MsgBox 262160, %error%, % translate("Cannot start the configuration tool - please check the installation...")
		OnMessage(0x44, "")
	}
	
	if ErrorLevel
		vRestart := true
}

checkTrayTipDuration() {
	setInputState(trayTipDurationInput, (trayTipEnabled := !trayTipEnabled))
}

checkTrayTipSimulationDuration() {
	setInputState(trayTipSimulationDurationInput, (trayTipSimulationEnabled := !trayTipSimulationEnabled))
}

checkButtonBoxDuration() {
	setInputState(buttonBoxDurationInput, (buttonBoxEnabled := !buttonBoxEnabled))
}

checkButtonBoxSimulationDuration() {
	setInputState(buttonBoxSimulationDurationInput, (buttonBoxSimulationEnabled := !buttonBoxSimulationEnabled))
}

computeStartupSongs() {
	files := concatenate(getFileNames("*.wav", kUserSplashMediaDirectory, kSplashMediaDirectory), getFileNames("*.mp3", kUserSplashMediaDirectory, kSplashMediaDirectory))
	
	for index, fileName in files {
		SplitPath fileName, soundFile
		
		files[index] := soundFile
	}
	
	return files
}

moveSettingsEditor() {
	moveByMouse("SE")
}

moveModesEditor() {
	moveByMouse("ME")
}

openModesEditor() {
	editSettings(kEditModes)
}

openSettingsDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Using-Simulator-Controller#startup-process--settings
}

editModes(ByRef settingsOrCommand) {
	static newSettings
	static result := false
	
	static modeContextDropDown
	static modesListView
	static modesListViewHandle
	
	if (settingsOrCommand = kSave) {
		; saveModesList(newSettings)
		
		Gui ME:Destroy
		
		result := kSave
	}
	else if (settingsOrCommand = kCancel) {
		Gui ME:Destroy
	
		result := kCancel
	}
	else {
		newSettings := newConfiguration()
	
		setConfigurationSectionValues(newSettings, "Modes", getConfigurationSectionValues(settingsOrCommand, "Modes"))
		
		Gui ME:Default
				
		Gui ME:-Border ; -Caption
		Gui ME:Color, D0D0D0

		Gui ME:Font, Bold, Arial

		Gui ME:Add, Text, w410 Center gmoveModesEditor, % translate("Modular Simulator Controller System") 

		Gui ME:Font, Norm, Arial
		Gui ME:Font, Italic Underline, Arial

		Gui ME:Add, Text, YP+20 w410 cBlue Center gopenSettingsDocumentation, % translate("Controller Modes")

		Gui ME:Font, Norm, Arial
				
		Gui ME:Add, Button, x128 y450 w80 h23 Default gsaveModes, % translate("Ok")
		Gui ME:Add, Button, x226 y450 w80 h23 gcancelModes, % translate("&Cancel")
		
		Gui ME:Add, Text, x16 y80 w86 h23 +0x200, % translate("Context")
		Gui ME:Add, DropDownList, x110 y80 w140 AltSubmit VmodeContextDropDown, % "Menus"
		
		Gui ME:Add, Text, x16 y110 w80 h23 +0x200, % translate("Modes")
		Gui ME:Add, ListView, x110 y110 w284 h112 -Multi -LV0x10 Checked -Hdr NoSort NoSortHdr HwndmodesListViewHandle VmodesListView, % translate("Plugin") . "|" . translate("Mode")
		
		Gui ME:Margin, 10, 10
		Gui ME:Show, AutoSize Center
		
		Loop {
			Sleep 1000
		} until result
		
		if (result == kSave)
			settingsOrCommand := newSettings
		
		return result
	}
}

editSettings(ByRef settingsOrCommand, withContinue := false) {
	static modeSettings
	
	static result
	static newSettings
	
	static voiceRecognition
	static faceRecognition
	static viewTracking
	static simulatorController
	static tactileFeedback
	static motionFeedback
	static trayTip
	static trayTipDuration
	static trayTipSimulation
	static trayTipSimulationDuration
	static buttonBox
	static buttonBoxDuration
	static buttonBoxSimulation
	static buttonBoxSimulationDuration
	static buttonBoxPosition
	static lastPositions
	
	static startup
	static startOption
	
	static splashTheme
	
	static coreSettings
	static feedbackSettings
	
	static coreVariable1
	static coreVariable2
	static coreVariable3
	static coreVariable4
	static coreVariable5
	static coreVariable6
	static coreVariable7
	static coreVariable8
	
	static feedbackVariable1
	static feedbackVariable2
	static feedbackVariable3
	static feedbackVariable4
	static feedbackVariable5
	static feedbackVariable6
	static feedbackVariable7
	static feedbackVariable8

restart:
	if (settingsOrCommand == kSave) {
		Gui SE:Submit
		
		newSettings := newConfiguration()
		
		for index, coreDescriptor in coreSettings {
			if (index > 1) {
				coreVariable := "coreVariable" . index
			
				setConfigurationValue(newSettings, "Core", coreDescriptor[1], %coreVariable%)
			}
		}
		
		for index, feedbackDescriptor in feedbackSettings {
			feedbackVariable := "feedbackVariable" . index
			
			setConfigurationValue(newSettings, "Feedback", feedbackDescriptor[1], %feedbackVariable%)
		}
		
		setConfigurationValue(newSettings, "Tray Tip", "Tray Tip Duration", (trayTip ? trayTipDuration : false))
		setConfigurationValue(newSettings, "Tray Tip", "Tray Tip Simulation Duration", (trayTipSimulation ? trayTipSimulationDuration : false))
		setConfigurationValue(newSettings, "Button Box", "Button Box Duration", (buttonBox ? buttonBoxDuration : false))
		setConfigurationValue(newSettings, "Button Box", "Button Box Simulation Duration", (buttonBoxSimulation ? buttonBoxSimulationDuration : false))
		
		positions := ["Top Left", "Top Right", "Bottom Left", "Bottom Right", "Secondary Screen", "Last Position"]
		
		setConfigurationValue(newSettings, "Button Box", "Button Box Position", positions[inList(map(positions, "translate"), buttonBoxPosition)])
		
		for descriptor, value in lastPositions
			setConfigurationValue(newSettings, "Button Box", descriptor, value)
		
		setConfigurationValue(newSettings, "Startup", "Splash Theme", (splashTheme == translate("None")) ? false : splashTheme)
		setConfigurationValue(newSettings, "Startup", "Simulator", (startup ? startOption : false))
		
		Gui SE:Destroy
	
		setConfigurationSectionValues(newSettings, "Modes", getConfigurationSectionValues(modeSettings, "Modes"))
		
		result := settingsOrCommand
	}
	else if (settingsOrCommand == kContinue) {
		Gui SE:Destroy
		
		result := settingsOrCommand
	}
	else if (settingsOrCommand == kCancel) {
		Gui SE:Destroy
		
		result := settingsOrCommand
	}
	else if (settingsOrCommand == kEditModes) {
		Gui SE:Hide
		
		editModes(modeSettings)
		
		Gui SE:Show
	}
	else {
		modeSettings := newConfiguration()
	
		setConfigurationSectionValues(modeSettings, "Modes", getConfigurationSectionValues(settingsOrCommand, "Modes", Object()))
	
		result := false
		
		Gui SE:-Border ; -Caption
		Gui SE:Color, D0D0D0
	
		Gui SE:Font, Bold, Arial
	
		Gui SE:Add, Text, w220 Center gmoveSettingsEditor, % translate("Modular Simulator Controller System") 
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic Underline, Arial
	
		Gui SE:Add, Text, YP+20 w220 cBlue Center gopenSettingsDocumentation, % translate("Settings")
	
		coreSettings := [["Simulator Controller", true, false]]
		feedbackSettings := []		
		
		for descriptor, applicationName in getConfigurationSectionValues(kSimulatorConfiguration, "Applications", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			enabled := (getConfigurationValue(kSimulatorConfiguration, applicationName, "Exe Path", "") != "")
			
			if (descriptor[1] == "Core")
				coreSettings.Push(Array(applicationName, getConfigurationValue(settingsOrCommand, "Core", applicationName, true), enabled))
			else if (descriptor[1] == "Feedback")
				feedbackSettings.Push(Array(applicationName, getConfigurationValue(settingsOrCommand, "Feedback", applicationName, true), enabled))
		}
		
		if (coreSettings.Length() > 8)
			Throw "Too many Core Components detected in editSettings..."
		
		if (feedbackSettings.Length() > 8)
			Throw "Too many Feedback Components detected in editSettings..."
			
		coreHeight := 20 + (coreSettings.Length() * 20)
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
	
		Gui SE:Add, GroupBox, YP+30 w220 h%coreHeight%, % translate("Core System")
	
		Gui SE:Font, Norm, Arial
	
		for index, coreDescriptor in coreSettings {
			coreOption := coreDescriptor[3] ? "" : "Disabled"
			coreLabel := coreDescriptor[1]
			checked := coreDescriptor[2]
			
			if (index == 1)
				coreOption := coreOption . " YP+20 XP+10"
				
			Gui SE:Add, CheckBox, %coreOption% Checked%checked% vcoreVariable%index%, %coreLabel%
		}
	
		if (feedbackSettings.Length() > 0) {
			feedbackHeight := 20 + (feedbackSettings.Length() * 20)
		
			Gui SE:Font, Norm, Arial
			Gui SE:Font, Italic, Arial
	
			Gui SE:Add, GroupBox, XP-10 YP+30 w220 h%feedbackHeight%, % translate("Feedback System")
	
			Gui SE:Font, Norm, Arial
	
			for index, feedbackDescriptor in feedbackSettings {
				feedbackOption := feedbackDescriptor[3] ? "" : "Disabled"
				feedbackLabel := feedbackDescriptor[1]
				checked := feedbackDescriptor[2]
				
				if (index == 1)
					feedbackOption := feedbackOption . " YP+20 XP+10"
					
				Gui SE:Add, CheckBox, %feedbackOption% Checked%checked% vfeedbackVariable%index%, %feedbackLabel%
			}
		}
	
		trayTipDuration := getConfigurationValue(settingsOrCommand, "Tray Tip", "Tray Tip Duration", false)
		trayTipSimulationDuration := getConfigurationValue(settingsOrCommand, "Tray Tip", "Tray Tip Simulation Duration", 1500)
		buttonBoxDuration := getConfigurationValue(settingsOrCommand, "Button Box", "Button Box Duration", 10000)
		buttonBoxSimulationDuration := getConfigurationValue(settingsOrCommand, "Button Box", "Button Box Simulation Duration", false)
		buttonBoxPosition := getConfigurationValue(settingsOrCommand, "Button Box", "Button Box Position", "Bottom Right")
		
		lastPositions := {}
		
		for descriptor, value in getConfigurationSectionValues(settingsOrCommand, "Button Box", Object())
			if InStr(descriptor, ".Position.")
				lastPositions[descriptor] := value
			
		trayTip := (trayTipDuration != 0) ? true : false
		trayTipSimulation := (trayTipSimulationDuration != 0) ? true : false
		buttonBox := (buttonBoxDuration != 0) ? true : false
		buttonBoxSimulation := (buttonBoxSimulationDuration != 0) ? true : false
		
		trayTipEnabled := trayTip
		trayTipSimulationEnabled := trayTipSimulation
		buttonBoxEnabled := buttonBox
		buttonBoxSimulationEnabled := buttonBoxSimulation
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
	
		Gui SE:Add, GroupBox, XP-10 YP+30 w220 h135, % translate("Controller Notifications")
	
		Gui SE:Font, Norm, Arial
	
		Gui SE:Add, CheckBox, YP+20 XP+10 Checked%trayTip% vtrayTip gcheckTrayTipDuration, % translate("Tray Tips")
		disabled := !trayTip ? "Disabled" : ""
		Gui SE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vtrayTipDuration HwndtrayTipDurationInput, %trayTipDuration%
		Gui SE:Add, Text, X205 YP+5, % translate("ms")
		Gui SE:Add, CheckBox, X20 YP+20 Checked%trayTipSimulation% vtrayTipSimulation gcheckTrayTipSimulationDuration, % translate("Tray Tips (Simulation)")
		disabled := !trayTipSimulation ? "Disabled" : ""
		Gui SE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vtrayTipSimulationDuration HwndtrayTipSimulationDurationInput, %trayTipSimulationDuration%
		Gui SE:Add, Text, X205 YP+5, % translate("ms")
		Gui SE:Add, CheckBox, X20 YP+20 Checked%buttonBox% vbuttonBox gcheckButtonBoxDuration, % translate("Button Box")
		disabled := !buttonBox ? "Disabled" : ""
		Gui SE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vbuttonBoxDuration HwndbuttonBoxDurationInput, %buttonBoxDuration%
		Gui SE:Add, Text, X205 YP+5, % translate("ms")
		Gui SE:Add, CheckBox, X20 YP+20 Checked%buttonBoxSimulation% vbuttonBoxSimulation gcheckButtonBoxSimulationDuration, % translate("Button Box (Simulation)")
		disabled := !buttonBoxSimulation ? "Disabled" : ""
		Gui SE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vbuttonBoxSimulationDuration HwndbuttonBoxSimulationDurationInput, %buttonBoxSimulationDuration%
		Gui SE:Add, Text, X205 YP+5, % translate("ms")
		Gui SE:Add, Text, X20 YP+30, % translate("Button Box Position")
		
		choices := ["Top Left", "Top Right", "Bottom Left", "Bottom Right", "Secondary Screen", "Last Position"]
		chosen := inList(choices, buttonBoxPosition)
		
		if !chosen
			chosen := 4
		
		Gui SE:Add, DropDownList, X120 YP-5 w100 Choose%chosen% vbuttonBoxPosition, % values2String("|", map(choices, "translate")*)
		
		Gui SE:Add, Button, X10 Y+15 w220 gopenModesEditor, % translate("Controller Modes...")
		
		splashTheme := getConfigurationValue(settingsOrCommand, "Startup", "Splash Theme", false)	
	 
		themes := getAllThemes()
		chosen := (splashTheme ? inList(themes, splashTheme) + 1 : 1)
		themes := translate("None") "|" + values2String("|", themes*)
		
		Gui SE:Add, Text, X10 Y+20, % translate("Theme")
		Gui SE:Add, DropDownList, X90 YP-5 w140 Choose%chosen% vsplashTheme, %themes%
	
		startupOption := getConfigurationValue(settingsOrCommand, "Startup", "Simulator", false)
		startup := (startupOption != false)
		
		Gui SE:Add, CheckBox, X10 Checked%startup% vstartup, % translate("Start")
		
		simulators := string2Values("|", getConfigurationValue(kSimulatorConfiguration, "Configuration", "Simulators", ""))
		
		chosen := inList(simulators, startupOption)
		
		if ((chosen == 0) && (simulators.Length() > 0))
			chosen := 1
		
		Gui SE:Add, DropDownList, X90 YP-5 w140 Choose%chosen% vstartOption, % values2String("|", simulators*)
	 
		Gui SE:Add, Button, X10 Y+20 w220 gstartConfiguration, % translate("Configuration...")
		
		margin := (withContinue ? "Y+20" : "")
		
		Gui SE:Add, Button, Default X10 %margin% w100 gsaveSettings, % translate("Save")
		Gui SE:Add, Button, X+20 w100 gcancelSettings, % translate("&Cancel")
		
		if withContinue
			Gui SE:Add, Button, X10 w220 gcontinueSettings, % translate("Co&ntinue w/o Save")
	
		Gui SE:Margin, 10, 10
		Gui SE:Show, AutoSize Center
		
		if (readConfiguration(kSimulatorConfigurationFile).Count() == 0)
			startConfiguration()
			
		Loop {
			Sleep 1000
		} until (result || vRestart)
		
		if vRestart {
			vRestart := false
			
			Gui SE:Destroy
			
			loadSimulatorConfiguration()
			
			Goto restart
		}
		
		if (result == kSave)
			settingsOrCommand := newSettings
		
		return result
	}
}
