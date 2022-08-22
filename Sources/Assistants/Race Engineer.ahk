﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Race Engineer                   ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                       Global Declaration Section                        ;;;
;;;-------------------------------------------------------------------------;;;

#SingleInstance Force			; Ony one instance allowed
#NoEnv							; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn							; Enable warnings to assist with detecting common errors.

SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.

SetBatchLines -1				; Maximize CPU utilization
ListLines Off					; Disable execution history

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Artificial Intelligence.ico
;@Ahk2Exe-ExeName Race Engineer.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\Task.ahk
#Include ..\Libraries\Messages.ahk
#Include ..\Libraries\RuleEngine.ahk
#Include ..\Assistants\Libraries\RaceEngineer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

showLogo(name) {
	local info := kVersion . " - 2022, Oliver Juwig`nCreative Commons - BY-NC-SA"
	local logo := kResourcesDirectory . "Rotating Brain.gif"
	local image := "1:" . logo
	local mainScreen, mainScreenTop, mainScreenLeft, mainScreenRight, mainScreenBottom, x, y, title1, title2, html

	static videoPlayer

	SysGet mainScreen, MonitorWorkArea

	x := mainScreenRight - 299
	y := mainScreenBottom - 234

	title1 := translate("Modular Simulator Controller System")
	title2 := substituteVariables(translate("%name% - The Virtual Race Engineer"), {name: name})
	SplashImage %image%, B FS8 CWD0D0D0 w299 x%x% y%y% ZH155 ZW279, %info%, %title1%`n%title2%

	Gui Logo:-Border -Caption
	Gui Logo:Add, ActiveX, x0 y0 w279 h155 VvideoPlayer, shell explorer

	videoPlayer.Navigate("about:blank")

	html := "<html><body style='background-color: transparent' style='overflow:hidden' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><img src='" . logo . "' width=279 height=155 border=0 padding=0></body></html>"

	videoPlayer.document.write(html)

	x += 10
	y += 40

	Gui Logo:Margin, 0, 0
	Gui Logo:+AlwaysOnTop
	Gui Logo:Show, AutoSize x%x% y%y%
}

hideLogo() {
	Gui Logo:Destroy
	SplashImage 1:Off
}

checkRemoteProcessAlive(pid) {
	Process Exist, %pid%

	if !ErrorLevel
		ExitApp 0
}

startRaceEngineer() {
	local icon := kIconsDirectory . "Artificial Intelligence.ico"
	local remotePID := false
	local engineerName := "Jona"
	local engineerLogo := false
	local engineerLanguage := false
	local engineerSynthesizer := true
	local engineerSpeaker := false
	local engineerSpeakerVocalics := false
	local engineerRecognizer := true
	local engineerListener := false
	local debug := false
	local voiceServer, index, engineer, label, callback

	Menu Tray, Icon, %icon%, , 1
	Menu Tray, Tip, Race Engineer

	Process Exist, Voice Server.exe

	voiceServer := ErrorLevel

	index := 1

	while (index < A_Args.Length()) {
		switch A_Args[index] {
			case "-Remote":
				remotePID := A_Args[index + 1]
				index += 2
			case "-Name":
				engineerName := A_Args[index + 1]
				index += 2
			case "-Logo":
				engineerLogo := (((A_Args[index + 1] = kTrue) || (A_Args[index + 1] = true) || (A_Args[index + 1] = "On")) ? true : false)
				index += 2
			case "-Language":
				engineerLanguage := A_Args[index + 1]
				index += 2
			case "-Synthesizer":
				engineerSynthesizer := A_Args[index + 1]
				index += 2
			case "-Speaker":
				engineerSpeaker := A_Args[index + 1]
				index += 2
			case "-SpeakerVocalics":
				engineerSpeakerVocalics := A_Args[index + 1]
				index += 2
			case "-Recognizer":
				engineerRecognizer := A_Args[index + 1]
				index += 2
			case "-Listener":
				engineerListener := A_Args[index + 1]
				index += 2
			case "-Voice":
				voiceServer := A_Args[index + 1]
				index += 2
			case "-Debug":
				debug := (((A_Args[index + 1] = kTrue) || (A_Args[index + 1] = true)) ? true : false)
				index += 2
			default:
				index += 1
		}
	}

	if (engineerSpeaker = kTrue)
		engineerSpeaker := true
	else if (engineerSpeaker = kFalse)
		engineerSpeaker := false

	if (engineerListener = kTrue)
		engineerListener := true
	else if (engineerListener = kFalse)
		engineerListener := false

	if debug
		setDebug(true)

	engineer := new RaceEngineer(kSimulatorConfiguration
							   , remotePID ? new RaceEngineer.RaceEngineerRemoteHandler(remotePID) : false
							   , engineerName, engineerLanguage
							   , engineerSynthesizer, engineerSpeaker, engineerSpeakerVocalics
							   , engineerRecognizer, engineerListener, voiceServer)

	RaceEngineer.Instance := engineer

	Menu SupportMenu, Insert, 1&

	label := translate("Debug Knowledgebase")
	callback := ObjBindMethod(engineer, "toggleDebug", kDebugKnowledgeBase)

	Menu SupportMenu, Insert, 1&, %label%, %callback%

	if engineer.Debug[kDebugKnowledgebase]
		Menu SupportMenu, Check, %label%

	registerMessageHandler("Race Engineer", "handleEngineerMessage")

	if (debug && engineerSpeaker) {
		engineer.getSpeaker()

		engineer.updateDynamicValues({KnowledgeBase: RaceEngineer.Instance.createKnowledgeBase({})})
	}

	if (engineerLogo && !kSilentMode)
		showLogo(engineerName)

	if remotePID
		Task.startTask(Func("checkRemoteProcessAlive").Bind(remotePID), 10000, kLowPriority)

	return
}


;;;-------------------------------------------------------------------------;;;
;;;                         Message Handler Section                         ;;;
;;;-------------------------------------------------------------------------;;;

shutdownRaceEngineer(shutdown := false) {
	if shutdown
		ExitApp 0

	if (RaceEngineer.Instance.Session == kSessionFinished)
		Task.startTask(Func("shutdownRaceEngineer").Bind(true), 10000, kLowPriority)
	else
		Task.startTask("shutdownRaceEngineer", 1000, kLowPriority)

	return false
}

handleEngineerMessage(category, data) {
	if InStr(data, ":") {
		data := StrSplit(data, ":", , 2)

		if (data[1] = "Shutdown") {
			Task.startTask("shutdownRaceEngineer", 20000, kLowPriority)

			return true
		}
		else
			return withProtection(ObjBindMethod(RaceEngineer.Instance, data[1]), string2Values(";", data[2])*)
	}
	else if (data = "Shutdown")
		Task.startTask("shutdownRaceEngineer", 20000, kLowPriority)
	else
		return withProtection(ObjBindMethod(RaceEngineer.Instance, data))
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

startRaceEngineer()