﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Configuration Editor            ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2020) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                   Private Constant Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;



;;;-------------------------------------------------------------------------;;;
;;;                   Public Constant Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

global kSave = "Save"
global kContinue = "Continue"
global kCancel = "Cancel"


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
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

saveConfiguration() {
	editConfiguration(kSave)
}

continueConfiguration() {
	editConfiguration(kContinue)
}

cancelConfiguration() {
	editConfiguration(kCancel)
}

setInputState(input, enabled) {
	if enabled
		GuiControl Enable, %input%
	else {
		GuiControl Disable, %input%
		GuiControl Text, %input%, 0
	}
}

runSetup() {
	try {
		RunWait % kBinariesDirectory . "Simulator Setup.exe"
	}
	catch exception {
		OnMessage(0x44, "translateMsgBoxButtons")
		MsgBox 262160, Error, Cannot start setup application - please check the installation...
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


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

computeStartupSongs() {
	files := []
	
	Loop Files, % kSplashMediaDirectory . "*.wav"
	{
		SplitPath A_LoopFilePath, soundFile
		
		files.Push(soundFile)
	}
	
	Loop Files, % kSplashMediaDirectory . "*.mp3"
	{
		SplitPath A_LoopFilePath, soundFile
		
		files.Push(soundFile)
	}
	
	Loop Files, % A_MyDocuments . "\Simulator Controller\Splash Media\*.wav"
	{
		SplitPath A_LoopFilePath, soundFile
		
		files.Push(soundFile)
	}
	
	Loop Files, % A_MyDocuments . "\Simulator Controller\Splash Media\*.mp3"
	{
		SplitPath A_LoopFilePath, soundFile
		
		files.Push(soundFile)
	}
	
	return files
}

editConfiguration(ByRef configurationOrCommand, withCancel := false) {
	static result
	static newConfiguration
	
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
	
	static startup
	static startOption
	
	static visualsOption
	
	static playSong
	static songOption
	
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
	if (configurationOrCommand == kSave) {
		Gui CE:Submit
		
		newConfiguration := newConfiguration()
		
		for index, coreDescriptor in coreSettings {
			if (index > 1) {
				coreVariable := "coreVariable" . index
			
				setConfigurationValue(newConfiguration, "Core", coreDescriptor[1], %coreVariable%)
			}
		}
		
		for index, feedbackDescriptor in feedbackSettings {
			feedbackVariable := "feedbackVariable" . index
			
			setConfigurationValue(newConfiguration, "Feedback", feedbackDescriptor[1], %feedbackVariable%)
		}
		
		setConfigurationValue(newConfiguration, "Controller", "Tray Tip Duration", (trayTip ? trayTipDuration : false))
		setConfigurationValue(newConfiguration, "Controller", "Tray Tip Simulation Duration", (trayTipSimulation ? trayTipSimulationDuration : false))
		setConfigurationValue(newConfiguration, "Controller", "Button Box Duration", (buttonBox ? buttonBoxDuration : false))
		setConfigurationValue(newConfiguration, "Controller", "Button Box Simulation Duration", (buttonBoxSimulation ? buttonBoxSimulationDuration : false))
		setConfigurationValue(newConfiguration, "Controller", "Button Box Position", buttonBoxPosition)
		
		setConfigurationValue(newConfiguration, "Startup", "Video", (visualsOption == "Pictures Carousel") ? false : visualsOption)
		setConfigurationValue(newConfiguration, "Startup", "Song", (playSong ? songOption : false))
		
		setConfigurationValue(newConfiguration, "Startup", "Simulator", (startup ? startOption : false))
		
		Gui CE:Destroy
		
		result := configurationOrCommand
	}
	else if (configurationOrCommand == kContinue) {
		Gui CE:Destroy
		
		result := configurationOrCommand
	}
	else if (configurationOrCommand == kCancel) {
		Gui CE:Destroy
		
		result := configurationOrCommand
	}
	else {
		result := false
		
		Gui CE:-Border -Caption
		Gui CE:Color, D0D0D0
	
		Gui CE:Font, Bold, Arial
	
		Gui CE:Add, Text, w220 Center, Modular Simulator Controller System 
		
		Gui CE:Font, Norm, Arial
		Gui CE:Font, Italic, Arial
	
		Gui CE:Add, Text, YP+20 w220 Center, Configuration
	
		coreSettings := [["Simulator Controller", true, false]]
		feedbackSettings := []		
		
		for descriptor, applicationName in getConfigurationSectionValues(kSimulatorConfiguration, "Applications", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			enabled := (getConfigurationValue(kSimulatorConfiguration, applicationName, "Exe Path", "") != "")
			
			if (descriptor[1] == "Core")
				coreSettings.Push(Array(applicationName, getConfigurationValue(configurationOrCommand, "Core", applicationName, true), enabled))
			else if (descriptor[1] == "Feedback")
				feedbackSettings.Push(Array(applicationName, getConfigurationValue(configurationOrCommand, "Feedback", applicationName, true), enabled))
		}
		
		if (coreSettings.Length() > 8)
			Throw "Too many Core Components detected in editConfiguration..."
		
		if (feedbackSettings.Length() > 8)
			Throw "Too many Feedback Components detected in editConfiguration..."
		
		coreHeight := 20 + (coreSettings.Length() * 20)
		
		Gui CE:Font, Norm, Arial
		Gui CE:Font, Italic, Arial
	
		Gui CE:Add, GroupBox, YP+30 w220 h%coreHeight%, Core System
	
		Gui CE:Font, Norm, Arial
	
		for index, coreDescriptor in coreSettings {
			coreOption := coreDescriptor[3] ? "" : "Disabled"
			coreLabel := coreDescriptor[1]
			checked := coreDescriptor[2]
			
			if (index == 1)
				coreOption := coreOption . " YP+20 XP+10"
				
			Gui CE:Add, CheckBox, %coreOption% Checked%checked% vcoreVariable%index%, %coreLabel%
		}
	
		if (feedbackSettings.Length() > 0) {
			feedbackHeight := 20 + (feedbackSettings.Length() * 20)
		
			Gui CE:Font, Norm, Arial
			Gui CE:Font, Italic, Arial
	
			Gui CE:Add, GroupBox, XP-10 YP+30 w220 h%feedbackHeight%, Feedback System
	
			Gui CE:Font, Norm, Arial
	
			for index, feedbackDescriptor in feedbackSettings {
				feedbackOption := feedbackDescriptor[3] ? "" : "Disabled"
				feedbackLabel := feedbackDescriptor[1]
				checked := feedbackDescriptor[2]
				
				if (index == 1)
					feedbackOption := feedbackOption . " YP+20 XP+10"
					
				Gui CE:Add, CheckBox, %feedbackOption% Checked%checked% vfeedbackVariable%index%, %feedbackLabel%
			}
		}
	
		trayTipDuration := getConfigurationValue(configurationOrCommand, "Controller", "Tray Tip Duration", false)
		trayTipSimulationDuration := getConfigurationValue(configurationOrCommand, "Controller", "Tray Tip Simulation Duration", 1500)
		buttonBoxDuration := getConfigurationValue(configurationOrCommand, "Controller", "Button Box Duration", 10000)
		buttonBoxSimulationDuration := getConfigurationValue(configurationOrCommand, "Controller", "Button Box Simulation Duration", false)
		buttonBoxPosition := getConfigurationValue(configurationOrCommand, "Controller", "Button Box Position", "Bottom Left")
		
		trayTip := (trayTipDuration != 0) ? true : false
		trayTipSimulation := (trayTipSimulationDuration != 0) ? true : false
		buttonBox := (buttonBoxDuration != 0) ? true : false
		buttonBoxSimulation := (buttonBoxSimulationDuration != 0) ? true : false
		
		trayTipEnabled := trayTip
		trayTipSimulationEnabled := trayTipSimulation
		buttonBoxEnabled := buttonBox
		buttonBoxSimulationEnabled := buttonBoxSimulation
		
		Gui CE:Font, Norm, Arial
		Gui CE:Font, Italic, Arial
	
		Gui CE:Add, GroupBox, XP-10 YP+30 w220 h135, Controller Notifications
	
		Gui CE:Font, Norm, Arial
	
		Gui CE:Add, CheckBox, YP+20 XP+10 Checked%trayTip% vtrayTip gcheckTrayTipDuration, Tray Tips
		disabled := !trayTip ? "Disabled" : ""
		Gui CE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vtrayTipDuration HwndtrayTipDurationInput, %trayTipDuration%
		Gui CE:Add, Text, X205 YP+5, ms
		Gui CE:Add, CheckBox, X20 YP+20 Checked%trayTipSimulation% vtrayTipSimulation gcheckTrayTipSimulationDuration, Tray Tips (Simulation)
		disabled := !trayTipSimulation ? "Disabled" : ""
		Gui CE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vtrayTipSimulationDuration HwndtrayTipSimulationDurationInput, %trayTipSimulationDuration%
		Gui CE:Add, Text, X205 YP+5, ms
		Gui CE:Add, CheckBox, X20 YP+20 Checked%buttonBox% vbuttonBox gcheckButtonBoxDuration, Button Box
		disabled := !buttonBox ? "Disabled" : ""
		Gui CE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vbuttonBoxDuration HwndbuttonBoxDurationInput, %buttonBoxDuration%
		Gui CE:Add, Text, X205 YP+5, ms
		Gui CE:Add, CheckBox, X20 YP+20 Checked%buttonBoxSimulation% vbuttonBoxSimulation gcheckButtonBoxSimulationDuration, Button Box (Simulation)
		disabled := !buttonBoxSimulation ? "Disabled" : ""
		Gui CE:Add, Edit, X160 YP-5 w40 h20 Limit5 Number %disabled% vbuttonBoxSimulationDuration HwndbuttonBoxSimulationDurationInput, %buttonBoxSimulationDuration%
		Gui CE:Add, Text, X205 YP+5, ms
		Gui CE:Add, Text, X20 YP+30, Button Box Position
		
		choices := ["Top Left", "Top Right", "Bottom Left", "Bottom Right"]
		chosen := inList(choices, buttonBoxPosition)
		if !chosen
			chosen := 4
			
		Gui CE:Add, DropDownList, X120 YP-5 w100 Choose%chosen% vbuttonBoxPosition, % values2String("|", choices*)
		
		video := getConfigurationValue(configurationOrCommand, "Startup", "Video", false)
		
		videos := []
		
		Loop Files, % kSplashMediaDirectory . "*.gif"
			videos.Push(A_LoopFileName)
		
		chosen := (video ? (inList(videos, video) + 1) : 1)
		
		visualsOption := ((chosen == 1) ? "Pictures Carousel" : videos[chosen - 1])
		options := "Pictures Carousel"
		
		if (videos.Length() > 0)
			options := (options . "|" . values2String("|", videos*))
		
		Gui CE:Add, Text, X10 Y+20, Splash Screen
		Gui CE:Add, DropDownList, X90 YP-5 w140 Choose%chosen% vvisualsOption, %options%
		
		songOption := getConfigurationValue(configurationOrCommand, "Startup", "Song", false)
		playSong := (songOption != false)
		
		Gui CE:Add, CheckBox, X10 Checked%playSong% vplaySong, Play song
		
		songs := computeStartupSongs()
		
		chosen := inList(songs, songOption)
		
		if (!chosen && (songs.Length() > 0))
			chosen := 1
			
		Gui CE:Add, DropDownList, X90 YP-5 w140 Choose%chosen% vsongOption, % values2String("|", songs*)
	
		startupOption := getConfigurationValue(configurationOrCommand, "Startup", "Simulator", false)
		startup := (startupOption != false)
		
		Gui CE:Add, CheckBox, Y+20 X10 Checked%startup% vstartup, Start
		
		simulators := string2Values("|", getConfigurationValue(kSimulatorConfiguration, "Configuration", "Simulators", ""))
		
		chosen := inList(simulators, startupOption)
		
		if ((chosen == 0) && (simulators.Length() > 0))
			chosen := 1
		
		Gui CE:Add, DropDownList, X90 YP-5 w140 Choose%chosen% vstartOption, % values2String("|", simulators*)
	 
		Gui CE:Add, Button, X10 Y+20 w220 grunSetup, Setup...
		
		margin := (withCancel ? "Y+20" : "")
		
		Gui CE:Add, Button, Default X10 %margin% w100 gsaveConfiguration, &Save
		Gui CE:Add, Button, X+20 w100 gcancelConfiguration, &Cancel
		
		if withCancel
			Gui CE:Add, Button, X10 w220 gcontinueConfiguration, % withCancel ? "Co&ntinue" : "&Cancel"
	
		Gui CE:Margin, 10, 10
		Gui CE:Show, AutoSize Center
		
		if (readConfiguration(kSimulatorConfigurationFile).Count() == 0)
			runSetup()
			
		Loop {
			Sleep 1000
		} until (result || vRestart)
		
		if vRestart {
			vRestart := false
			
			Gui CE:Destroy
			
			loadSimulatorConfiguration()
			
			Goto restart
		}
		
		if (result == kSave)
			configurationOrCommand := newConfiguration
		
		return result
	}
}
