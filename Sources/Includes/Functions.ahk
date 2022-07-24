﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Global Functions                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Constants.ahk
#Include ..\Includes\Variables.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kUninstallKey = "SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\SimulatorController"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vDetachedInstallation = false

global vDebug = false
global vLogLevel = kLogWarn

global vTargetLanguageCode = "en"

global vSplashCounter = 0
global vLastImage
global vVideoPlayer
global vSongIsPlaying = false

global vProgressIsOpen = false
global vProgressBar
global vProgressTitle
global vProgressMessage

global vEventHandlers = Object()
global vIncomingMessages = []
global vOutgoingMessages = []
global vDispatching = false

global vPendingTrayMessages = []
global vTrayMessageDuration = 1500


;;;-------------------------------------------------------------------------;;;
;;;                    Private Function Declaration Section                 ;;;
;;;-------------------------------------------------------------------------;;;

moveHTMLViewer() {
	moveByMouse("HV")
}

dismissHTMLViewer() {
	viewHTML(false)
}

createMessageReceiver() {
	; Gui MR:-Border -Caption
	Gui MR:New, , % A_ScriptName
	Gui MR:Color, D0D0D0, D8D8D8
	Gui MR:Add, Text, X10 Y10, % translate("Modular Simulator Controller System")
	Gui MR:Add, Text, , % A_ScriptName

	Gui MR:Margin, 10, 10
	Gui MR:Show, X0 Y0 Hide AutoSize
}

consentDialog(id, consent := false) {
	static tyrePressuresConsentDropDown
	static carSetupsConsentDropDown
	static closed

	if (id = "Close") {
		closed := true

		return
	}
	else
		closed := false

	language := getLanguage()

	if ((language != "en") && (language != "de"))
		language := "en"

	texts := readConfiguration(kTranslationsDirectory . "Consent.ini")

	Gui CNS:-Border ; -Caption
	Gui CNS:Color, D0D0D0, D8D8D8
	Gui CNS:Font, s10 Bold
	Gui CNS:Add, Text, x0 y8 w800 +0x200 +0x1 BackgroundTrans gmoveConsentDialog, % translate("Modular Simulator Controller System")
	Gui CNS:Font, Norm, Arial
	Gui CNS:Add, Text, x0 y32 w800 h23 +0x200 +0x1 BackgroundTrans, % translate("Declaration of consent")

	Gui CNS:Add, Text, x8 y70 w784 h180 -VScroll +Wrap ReadOnly, % StrReplace(StrReplace(getConfigurationValue(texts, language, "Introduction"), "``n", "`n"), "\<>", "=")

	Gui CNS:Add, Text, x8 y260 w450 h23 +0x200, % translate("Your database identification key is:")
	Gui CNS:Add, Edit, x460 y260 w332 h23 -VScroll ReadOnly Center, % id

	Gui CNS:Add, Text, x8 y300 w450 h23 +0x200, % translate("Do you want to share your local tyre pressure data?")

	chosen := inList(["Yes", "No", "Undecided"], getConfigurationValue(consent, "Consent", "Share Tyre Pressures", "Undecided"))
	Gui CNS:Add, DropDownList, x460 y300 w332 AltSubmit Choose%chosen% VtyrePressuresConsentDropDown, % values2String("|", map(["Yes", "No", "Ask again later..."], "translate")*)

	Gui CNS:Add, Text, x8 y324 w450 h23 +0x200, % translate("Do you want to share your local car setup data?")

	chosen := inList(["Yes", "No", "Undecided"], getConfigurationValue(consent, "Consent", "Share Car Setups", "Undecided"))
	Gui CNS:Add, DropDownList, x460 y324 w332 AltSubmit Choose%chosen% VcarSetupsConsentDropDown, % values2String("|", map(["Yes", "No", "Ask again later..."], "translate")*)

	Gui CNS:Add, Text, x8 y364 w784 h60 -VScroll +Wrap ReadOnly, % StrReplace(StrReplace(getConfigurationValue(texts, language, "Information"), "``n", "`n"), "\<>", "=")

	Gui CNS:Add, Link, x8 y434 w784 h60 cRed -VScroll +Wrap ReadOnly, % StrReplace(StrReplace(getConfigurationValue(texts, language, "Warning"), "``n", "`n"), "\<>", "=")

	Gui CNS:Add, Button, x368 y490 w80 h23 Default gcloseConsentDialog, % translate("Save")

	Gui CNS:+AlwaysOnTop
	Gui CNS:Show, Center AutoSize

	Gui CNS:Default

	Loop
		Sleep 100
	until closed

	GuiControlGet tyrePressuresConsentDropDown
	GuiControlGet carSetupsConsentDropDown

	Gui CNS:Destroy

	return {TyrePressures: ["Yes", "No", "Retry"][tyrePressuresConsentDropDown], CarSetups: ["Yes", "No", "Retry"][carSetupsConsentDropDown]}
}

closeConsentDialog() {
	consentDialog("Close")
}

moveConsentDialog() {
	moveByMouse("CNS")
}

changeProtection(up, critical := false, block := false) {
	static level := 0

	level += (up ? 1 : -1)

	if (level > 0) {
		if critical
			Critical 100

		if block
			BlockInput On
	}
	else if (level == 0) {
		if block
			BlockInput Off

		if critical
			Critical Off
	}
	else if (level <= 0)
		Throw "Nesting error detected in changeProtection..."
}

playThemeSong(songFile) {
	songFile := getFileName(songFile, kUserSplashMediaDirectory, kSplashMediaDirectory)

	if FileExist(songFile)
		SoundPlay %songFile%
}

readLanguage(targetLanguageCode) {
	translations := {}

	Loop Read, % getFileName("Translations." . targetLanguageCode, kUserTranslationsDirectory, kTranslationsDirectory)
	{
		translation := StrSplit(A_LoopReadLine, "=>")

		if (translation[1] = targetLanguageCode)
			return translation[2]
	}

	Throw "Inconsistent translation encountered for """ . targetLanguageCode . """ in readLanguage..."
}

receivePipeMessage() {
	result := false

	for event, handler in vEventHandlers {
		if (event = "*")
			continue

		pipeName := "\\.\pipe\SC." . event

		if DllCall("WaitNamedPipe", "Str", pipeName, "UInt", 0xF)
			Loop Read, %pipeName%
			{
				data := StrSplit(A_LoopReadLine, ":", , 2)
				event := data[1]

				eventHandler := vEventHandlers[event]

				if (!eventHandler)
					eventHandler := vEventHandlers["*"]

				logMessage(kLogInfo, translate("Dispatching event """) . event . (data[2] ? translate(""": ") . data[2] : translate("""")))

				vIncomingMessages.Push(Array(eventHandler, event, data[2]))

				result := true
			}
	}

	return result
}

sendPipeMessage(event, data) {
	static ERROR_PIPE_CONNECTED := 535
	static ERROR_PIPE_LISTENING := 536
	static ptr

	pipeName := "\\.\pipe\SC." . event

	pipe := DllCall("CreateNamedPipe", "str", pipeName, "uint", 2, "uint", 0, "uint", 255, "uint", 1024, "uint", 1024, "uint", 0, ptr, 0)

	DllCall("ConnectNamedPipe", ptr, pipe, ptr, 0)

	if (true || (A_LastError = ERROR_PIPE_CONNECTED)) {
		message := (A_IsUnicode ? chr(0xfeff) : chr(239) chr(187) chr(191)) . (event := event . ":" . data)

		DllCall("WriteFile", ptr, pipe, "str", message, "uint", (StrLen(message) + 1) * (A_IsUnicode ? 2 : 1), "uint*", 0, ptr, 0)

		DllCall("CloseHandle", ptr, pipe)

		return true
	}
	else
		return false
}

receiveWindowMessage(wParam, lParam) {
	;---------------------------------------------------------------------------
    ; retrieve info from COPYDATASTRUCT
    ;---------------------------------------------------------------------------
    dwData := NumGet(lParam + A_PtrSize * 0)    ; DWORD encoded request
    cbData := NumGet(lParam + A_PtrSize * 1)    ; length of DATA string (incl ZERO)
    lpData := NumGet(lParam + A_PtrSize * 2)    ; pointer to DATA string

	;---------------------------------------------------------------------------
    ; interpret available info
    ;---------------------------------------------------------------------------
    request := decodeDWORD(dwData)              ; 4-char decoded request

	if (request = "EVNT") {
		length  := (cbData - 1) / (A_IsUnicode + 1) ; length of DATA string (excl ZERO)
		data    := StrGet(lpData, length)           ; DATA string from pointer
	}
	else if ((request = "RS") || (request = "SD")) {
		length  := (cbData - 1)						; length of DATA string (excl ZERO)
		data    := StrGet(lpData, length, "")       ; DATA string from pointer
	}
	else
		Throw % "Unhandled message received: " . request . " in dispatchEvent..."

	data := StrSplit(data, ":", , 2)
	event := data[1]

	eventHandler := vEventHandlers[event]

	if (!eventHandler)
		eventHandler := vEventHandlers["*"]

	logMessage(kLogInfo, translate("Dispatching event """) . event . (data[2] ? translate(""": ") . data[2] : translate("""")))

	if (request = "RS")
		withProtection(eventHandler, event, data[2])
	else
		vIncomingMessages.Push(Array(eventHandler, event, data[2]))
}

sendWindowMessage(target, event, data) {
	curDetectHiddenWindows := A_DetectHiddenWindows
	curTitleMatchMode := A_TitleMatchMode

	event := event . ":" . data

	;---------------------------------------------------------------------------
	; construct the message to send
	;---------------------------------------------------------------------------
	dwData := encodeDWORD("EVNT")
	cbData := StrLen(event) * (A_IsUnicode + 1) + 1 ; length of DATA string (incl. ZERO)
	lpData := &event                                ; pointer to DATA string

	;---------------------------------------------------------------------------
	; put the message in a COPYDATASTRUCT
	;---------------------------------------------------------------------------
	VarSetCapacity(struct, A_PtrSize * 3, 0)        ; initialize COPYDATASTRUCT
	NumPut(dwData, struct, A_PtrSize * 0, "UInt")   ; DWORD
	NumPut(cbData, struct, A_PtrSize * 1, "UInt")   ; DWORD
	NumPut(lpData, struct, A_PtrSize * 2, "UInt")   ; 32bit pointer

	;---------------------------------------------------------------------------
	; parameters for SendMessage command
	;---------------------------------------------------------------------------
	message := 0x4a     ; WM_COPYDATA
	wParam  := ""       ; not used
	lParam  := &struct  ; COPYDATASTRUCT
	control := ""       ; not needed

	SetTitleMatchMode 2 ; match part of the title
	DetectHiddenWindows On ; needed for sending messages

	try {
		SendMessage %message%, %wParam%, %lParam%, %control%, %target%

		return (ErrorLevel != "FAIL")
	}
	catch exception {
		return false
	}
	finally {
		DetectHiddenWindows %curDetectHiddenWindows%
		SetTitleMatchMode %curTitleMatchMode%
	}
}

receiveFileMessage() {
	result := false

	Process Exist

	pid := ErrorLevel

	fileName := kTempDirectory . "Messages\" . pid . ".msg"

	if FileExist(fileName) {
		file := false

		try {
			file := FileOpen(fileName, "rw-rwd")
		}
		catch exception {
			return false
		}

		while !file.AtEOF {
			line := Trim(file.ReadLine(), " `t`n`r")

			if (StrLen(line) == 0)
				break

			data := StrSplit(line, ":", , 2)
			event := data[1]

			eventHandler := vEventHandlers[event]

			if (!eventHandler)
				eventHandler := vEventHandlers["*"]

			logMessage(kLogInfo, translate("Dispatching event """) . event . (data[2] ? translate(""": ") . data[2] : translate("""")))

			vIncomingMessages.Push(Array(eventHandler, event, data[2]))

			result := true
		}

		file.Length := 0

		file.Close()
	}

	return result
}

sendFileMessage(pid, event, data) {
	text := event . ":" . data . "`n"

	try {
		FileAppend %text%, % kTempDirectory . "Messages\" . pid . ".msg"
	}
	catch exception {
		return false
	}

	return true
}

receiveMessage() {
	return (receiveFileMessage() || receivePipeMessage())
}

sendMessage() {
	if (vOutgoingMessages.Length() > 0) {
		handler := vOutgoingMessages[1]

		if %handler%()
			vOutgoingMessages.RemoveAt(1)
	}
}

messageDispatcher() {
	if vDispatching
		return
	else {
		vDispatching := true

		try {
			while (vIncomingMessages.Length() > 0) {
				descriptor := vIncomingMessages.RemoveAt(1)

				withProtection(descriptor[1], descriptor[2], descriptor[3])
			}
		}
		finally {
			vDispatching := false

			SetTimer messageDispatcher, -200
		}
	}
}

messageQueue() {
	protectionOn()

	try {
		if !receiveMessage()
			sendMessage()
	}
	finally {
		protectionOff()

		SetTimer messageQueue, -100

		messageDispatcher()
	}
}

trayMessageQueue() {
	if (vPendingTrayMessages.Length() > 0) {
		protectionOn()

		try {
			if (vPendingTrayMessages.Length() = 0)
				return
			else {
				message := vPendingTrayMessages.RemoveAt(1)

				protectionOff()

				try {
					duration := message[3]
					title := StrReplace(message[1], "`n", A_Space)
					message := StrReplace(message[2], "`n", A_Space)

					TrayTip %title%, %message%

					Sleep %duration%

					TrayTip

					if SubStr(A_OSVersion,1,3) = "10." {
						Menu Tray, NoIcon
						Sleep 200  ; It may be necessary to adjust this sleep...
						Menu Tray, Icon
					}
				}
				finally {
					protectionOn()
				}
			}
		}
		finally {
			protectionOff()

			SetTimer trayMessageQueue, -500
		}
	}
	else
		SetTimer trayMessageQueue, -500
}

encodeDWORD(string) {
	result := 0

	Loop % StrLen(string) {
        result <<= 8
        result += Asc(SubStr(string, A_Index, 1))
    }

    return result
}

decodeDWORD(data) {
	result := ""

    Loop 4 {
        result := Chr(data & 0xFF) . result
        data >>= 8
    }

    return result
}

unknownEventHandler(event, data) {
	logMessage(kLogCritical, translate("Unhandled event """) . event . translate(""": ") . data)

	raiseEvent(kLocalMessage, event, data)
}

stopMessageManager() {
	Process Exist

	pid := ErrorLevel

	if FileExist(kTempDirectory . "Messages\" . pid . ".msg")
		FileDelete %kTempDirectory%Messages\%pid%.msg

	return false
}

startMessageManager() {
	FileCreateDir %kTempDirectory%Messages

	OnMessage(0x4a, "receiveWindowMessage")

	registerEventHandler("*", "unknownEventHandler")

	Process Exist

	pid := ErrorLevel

	if FileExist(kTempDirectory . "Messages\" . pid . ".msg")
		FileDelete %kTempDirectory%Messages\%pid%.msg

	OnExit("stopMessageManager")

	SetTimer messageQueue, -2000
	SetTimer messageDispatcher, -4000
}

logError(exception) {
	if IsObject(exception)
		logMessage(kLogCritical, translate("Unhandled exception encountered in ") . exception.File . translate(" at line ") . exception.Line . translate(": ") . exception.Message)
	else
		logMessage(kLogCritical, translate("Unhandled exception encountered: ") . exception)

	return (isDebug() ? false : true)
}

initializeLoggingSystem() {
	OnError("logError")
}

startTrayMessageManager() {
	SetTimer trayMessageQueue, -1000
}

requestShareSessionDatabaseConsent() {
	if !inList(A_Args, "-Install") {
		if inList(["Simulator Startup", "Simulator Configuration", "Simulator Settings", "Session Database", "Simulator Setup"], StrSplit(A_ScriptName, ".")[1]) {
			idFileName := kUserConfigDirectory . "ID"

			FileReadLine id, %idFileName%, 1

			consent := readConfiguration(kUserConfigDirectory . "CONSENT")

			request := ((consent.Count() == 0) || (id != getConfigurationValue(consent, "General", "ID")) || getConfigurationValue(consent, "General", "ReNew", false))

			if !request {
				countdown := getConfigurationValue(consent, "General", "Countdown", kUndefined)

				if (countdown != kUndefined) {
					if (--countdown <= 0)
						request := true
					else {
						setConfigurationValue(consent, "General", "Countdown", countdown)

						writeConfiguration(kUserConfigDirectory . "CONSENT", consent)
					}
				}
			}

			if request {
				newConsent := newConfiguration()

				setConfigurationValue(newConsent, "General", "ID", id)
				setConfigurationValue(newConsent, "Consent", "Date", A_MM . "/" . A_DD . "/" . A_YYYY)

				if FileExist(kTranslationsDirectory . "Consent.ini")
					result := consentDialog(id, consent)
				else {
					result := {}

					result["TyrePressures"] := "Retry"
					result["CarSetups"] := "Retry"
				}

				switch result["TyrePressures"] {
					case "Yes":
						setConfigurationValue(newConsent, "Consent", "Share Tyre Pressures", "Yes")
					case "No":
						setConfigurationValue(newConsent, "Consent", "Share Tyre Pressures", "No")
					case "Retry":
						setConfigurationValue(newConsent, "Consent", "Share Tyre Pressures", "Undecided")
						setConfigurationValue(newConsent, "General", "Countdown", 10)
				}

				switch result["CarSetups"] {
					case "Yes":
						setConfigurationValue(newConsent, "Consent", "Share Car Setups", "Yes")
					case "No":
						setConfigurationValue(newConsent, "Consent", "Share Car Setups", "No")
					case "Retry":
						setConfigurationValue(newConsent, "Consent", "Share Car Setups", "Undecided")
						setConfigurationValue(newConsent, "General", "Countdown", 10)
				}

				writeConfiguration(kUserConfigDirectory . "CONSENT", newConsent)
			}
		}
	}
}

shareSessionDatabase() {
	if inList(["Simulator Startup", "Simulator Configuration", "Simulator Settings", "Session Database"], StrSplit(A_ScriptName, ".")[1]) {
		idFileName := kUserConfigDirectory . "ID"

		FileReadLine ID, %idFileName%, 1

		dbIDFileName := kDatabaseDirectory . "ID"

		FileReadLine dbID, %dbIDFileName%, 1

		if (ID = dbID) {
			consent := readConfiguration(kUserConfigDirectory . "CONSENT")

			shareTyrePressures := (getConfigurationValue(consent, "Consent", "Share Tyre Pressures", "No") = "Yes")
			shareCarSetups := (getConfigurationValue(consent, "Consent", "Share Car Setups", "No") = "Yes")

			if (shareTyrePressures || shareCarSetups) {
				options := ("-ID " . ID)

				if shareTyrePressures
					options .= " -Pressures"

				if shareCarSetups
					options .= " -Setups"

				try {
					Run %kBinariesDirectory%Database Synchronizer.exe %options%
				}
				catch exception {
					logMessage(kLogCritical, translate("Cannot start Database Synchronizer - please rebuild the applications..."))

					showMessage(translate("Cannot start Database Synchronizer - please rebuild the applications...")
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}
			}
		}
	}
}

checkForNews() {
	if vDetachedInstallation
		return

	if inList(kForegroundApps, StrSplit(A_ScriptName, ".")[1]) {
		check := !FileExist(kUserConfigDirectory . "NEWS")

		if !check {
			FileGetTime lastModified, %kUserConfigDirectory%NEWS, M

			EnvAdd lastModified, 1, Days

			check := (lastModified < A_Now)
		}

		if check {
			try {
				URLDownloadToFile https://www.dropbox.com/s/3zfsgiepo85ufw3/NEWS?dl=1, %kTempDirectory%NEWS

				if ErrorLevel
					Throw "Error while downloading NEWS..."
			}
			catch exception {
				check := false
			}
		}

		if check {
			news := readConfiguration(kUserConfigDirectory . "NEWS")

			for nr, html in getConfigurationSectionValues(readConfiguration(kTempDirectory . "NEWS"), "News")
				if !getConfigurationValue(news, "News", nr, false)
					try {
						URLDownloadToFile %html%, %kTempDirectory%NEWS.htm

						if ErrorLevel
							Throw "Error while downloading NEWS..."

						setConfigurationValue(news, "News", nr, true)

						writeConfiguration(kUserConfigDirectory . "NEWS", news)

						viewHTML(kTempDirectory . "NEWS.htm")
					}
					catch exception {
						; ignore
					}
		}
	}
}

checkForUpdates() {
	if vDetachedInstallation
		return

	if inList(kForegroundApps, StrSplit(A_ScriptName, ".")[1]) {
		check := !FileExist(kUserConfigDirectory . "VERSION")

		if !check {
			FileGetTime lastModified, %kUserConfigDirectory%VERSION, M

			EnvAdd lastModified, 1, Days

			check := (lastModified < A_Now)
		}

		if check {
			try {
				URLDownloadToFile https://www.dropbox.com/s/txa8muw9j3g66tl/VERSION?dl=1, %kUserConfigDirectory%VERSION

				if ErrorLevel
					Throw "Error while checking VERSION..."
			}
			catch exception {
				check := false
			}
		}

		if check {
			release := readConfiguration(kUserConfigDirectory . "VERSION")
			version := getConfigurationValue(release, "Release", "Version", getConfigurationValue(release, "Version", "Release", false))

			if version {
				version := StrSplit(version, "-", , 2)
				current := StrSplit(kVersion, "-", , 2)

				versionPostfix := version[2]
				currentPostfix := current[2]

				version := string2Values(".", version[1])
				current := string2Values(".", current[1])

				while (version.Length() < current.Length())
					version.Push("0")

				while (current.Length() < version.Length())
					current.Push("0")

				version := values2String("", version*)
				current := values2String("", current*)

				if ((version > current) || ((version = current) && (versionPostfix != currentPostfix))) {
					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
					title := translate("Update")
					MsgBox 262436, %title%, % translate("A newer version of Simulator Controller is available. Do you want to download it now?")
					OnMessage(0x44, "")

					IfMsgBox Yes
					{
						automaticUpdates := getConfigurationValue(readConfiguration(kUserConfigDirectory . "Simulator Controller.install"), "Updates", "Automatic", true)

						if automaticUpdates
							Run *RunAs %kBinariesDirectory%Simulator Download.exe -NoUpdate -Download -Update -Start "%A_ScriptFullPath%"
						else
							Run https://github.com/SeriousOldMan/Simulator-Controller#latest-release-builds

						ExitApp 0
					}
					else if FileExist(kUserConfigDirectory . "VERSION")
						FileSetTime A_Now, %kUserConfigDirectory%VERSION
				}
			}
		}
	}

	toolTargets := readConfiguration(getFileName("Simulator Tools.targets", kConfigDirectory))

	userToolTargetsFile := getFileName("Simulator Tools.targets", kUserConfigDirectory)
	userToolTargets := readConfiguration(userToolTargetsFile)

	if (userToolTargets.Count() > 0) {
		setConfigurationSectionValues(userToolTargets, "Update", getConfigurationSectionValues(toolTargets, "Update", Object()))

		writeConfiguration(userToolTargetsFile, userToolTargets)
	}

	if (!inList(A_Args, "-NoUpdate") && inList(kForegroundApps, StrSplit(A_ScriptName, ".")[1])) {
		updates := readConfiguration(getFileName("UPDATES", kUserConfigDirectory))
restartUpdate:
		for target, arguments in getConfigurationSectionValues(toolTargets, "Update", Object())
			if !getConfigurationValue(updates, "Processed", target, false) {
				/*
				SoundPlay *32

				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No", "Never"]))
				title := translate("Update")
				MsgBox 262179, %title%, % translate("The local configuration database needs an update. Do you want to run the update now?")
				OnMessage(0x44, "")

				IfMsgBox Cancel
				{
					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
					title := translate("Update")
					MsgBox 262436, %title%, % translate("Are you really sure, you want to skip the automated update procedure?")
					OnMessage(0x44, "")

					IfMsgBox Yes
					{
						for target, arguments in getConfigurationSectionValues(toolTargets, "Update", Object())
							setConfigurationValue(updates, "Processed", target, true)

						writeConfiguration(getFileName("UPDATES", kUserConfigDirectory), updates)

						break
					}

					Goto restartUpdate
				}

				IfMsgBox Yes
				{
					RunWait % kBinariesDirectory . "Simulator Tools.exe -Update"

					loadSimulatorConfiguration()

					break
				}

				IfMsgBox No
				{
					break
				}
				*/

				RunWait % kBinariesDirectory . "Simulator Tools.exe -Update"

				loadSimulatorConfiguration()

				break
			}
	}
}

loadSimulatorConfiguration() {
	kSimulatorConfiguration := readConfiguration(kSimulatorConfigurationFile)

	if !FileExist(getFileName(kSimulatorConfigurationFile, kUserConfigDirectory))
		vTargetLanguageCode := getSystemLanguage()
	else
		vTargetLanguageCode := getConfigurationValue(kSimulatorConfiguration, "Configuration", "Language", getSystemLanguage())

	vTargetLanguageCode := getConfigurationValue(kSimulatorConfiguration, "Configuration", "Language", getSystemLanguage())

	version := readConfiguration(kHomeDirectory . "VERSION")
	section := getConfigurationValue(version, "Current", "Type", false)

	if section
		kVersion := getConfigurationValue(version, section, "Version", "0.0.0-dev")
	else
		kVersion := getConfigurationValue(version, "Current", "Version", getConfigurationValue(version, "Version", "Current", "0.0.0-dev"))

	Process Exist

	pid := ErrorLevel

	logMessage(kLogCritical, "---------------------------------------------------------------")
	logMessage(kLogCritical, translate("      Running ") . StrSplit(A_ScriptName, ".")[1] . " (" . kVersion . ") [" . pid . "]")
	logMessage(kLogCritical, "---------------------------------------------------------------")

	if (kSimulatorConfiguration.Count() == 0)
		logMessage(kLogCritical, translate("No configuration found - please run the configuration tool"))

	path := getConfigurationValue(readConfiguration(kUserConfigDirectory . "Session Database.ini"), "Database", "Path")
	if path {
		kDatabaseDirectory := path . "\"

		FileCreateDir %kDatabaseDirectory%Community
		FileCreateDir %kDatabaseDirectory%User

		logMessage(kLogInfo, translate("Session database path set to ") . path)
	}

    /*
	path := getConfigurationValue(kSimulatorConfiguration, "Configuration", "Home Path")
	if path {
		kHomeDirectory := path . "\"

		logMessage(kLogInfo, translate("Installation path set to ") . path)
	}
	else
		logMessage(kLogWarn, translate("Installation path not set"))
	*/

	logMessage(kLogInfo, translate("Installation path set to ") . kHomeDirectory)

	path := getConfigurationValue(kSimulatorConfiguration, "Configuration", "AHK Path")
	if path {
		kAHKDirectory := path . "\"

		logMessage(kLogInfo, translate("AutoHotkey path set to ") . path)
	}
	else
		logMessage(kLogWarn, translate("AutoHotkey path not set"))

	path := getConfigurationValue(kSimulatorConfiguration, "Configuration", "MSBuild Path")
	if path {
		kMSBuildDirectory := path . "\"

		logMessage(kLogInfo, translate("MSBuild path set to ") . path)
	}
	else
		logMessage(kLogWarn, translate("MSBuild path not set"))

	path := getConfigurationValue(kSimulatorConfiguration, "Configuration", "NirCmd Path")
	if path {
		kNirCmd := path . "\NirCmd.exe"

		logMessage(kLogInfo, translate("NirCmd executable set to ") . kNirCmd)
	}
	else
		logMessage(kLogWarn, translate("NirCmd executable not configured"))

	path := getConfigurationValue(kSimulatorConfiguration, "Voice Control", "SoX Path")
	if path {
		kSoX := path . "\sox.exe"

		logMessage(kLogInfo, translate("SoX executable set to ") . kSox)
	}
	else
		logMessage(kLogWarn, translate("SoX executable not configured"))

	kSilentMode := getConfigurationValue(kSimulatorConfiguration, "Configuration", "Silent Mode", false)

	if (!A_IsCompiled || getConfigurationValue(kSimulatorConfiguration, "Configuration", "Debug", false))
		setDebug(true)

	vLogLevel := inList(["Info", "Warn", "Critical", "Off"], getConfigurationValue(kSimulatorConfiguration, "Configuration", "Log Level", "Warn"))
}

initializeEnvironment() {
	"".base.__Get := "".base.__Set := "".base.__Call := Func("reportNonObjectUsage")

	if A_IsCompiled {
		if FileExist(kConfigDirectory . "Simulator Controller.install") {
			installOptions := readConfiguration(kConfigDirectory . "Simulator Controller.install")
			installLocation := getConfigurationValue(installOptions, "Install", "Location", "..\")

			if ((installLocation = "*") || (installLocation = "..\"))
				vDetachedInstallation := true
		}

		if !vDetachedInstallation {
			RegRead installLocation, HKLM, %kUninstallKey%, InstallLocation

			installOptions := readConfiguration(kUserConfigDirectory . "Simulator Controller.install")
			installLocation := getConfigurationValue(installOptions, "Install", "Location", installLocation)

			install := (installLocation && (installLocation != "") && (InStr(kHomeDirectory, installLocation) != 1))
			install := (install || !installLocation || (installLocation = ""))

			if (install && !inList(["Simulator Tools", "Simulator Download", "Database Update"], StrSplit(A_ScriptName, ".")[1])) {
				kSimulatorConfiguration := readConfiguration(kSimulatorConfigurationFile)

				if !FileExist(getFileName(kSimulatorConfigurationFile, kUserConfigDirectory))
					vTargetLanguageCode := getSystemLanguage()
				else
					vTargetLanguageCode := getConfigurationValue(kSimulatorConfiguration, "Configuration", "Language", getSystemLanguage())

				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
				title := translate("Installation")
				MsgBox 262436, %title%, % translate("You have to install Simulator Controller before starting any of the applications. Do you want run the Setup now?")
				OnMessage(0x44, "")

				IfMsgBox Yes
					Run *RunAs %kBinariesDirectory%Simulator Tools.exe

				ExitApp 0
			}
		}
	}

	FileCreateDir %A_MyDocuments%\Simulator Controller
	FileCreateDir %kUserHomeDirectory%Config
	FileCreateDir %kUserHomeDirectory%Rules
	FileCreateDir %kUserHomeDirectory%Advisor
	FileCreateDir %kUserHomeDirectory%Advisor\Definitions
	FileCreateDir %kUserHomeDirectory%Advisor\Rules
	FileCreateDir %kUserHomeDirectory%Advisor\Definitions\Cars
	FileCreateDir %kUserHomeDirectory%Advisor\Rules\Cars
	FileCreateDir %kUserHomeDirectory%Validators
	FileCreateDir %kUserHomeDirectory%Logs
	FileCreateDir %kUserHomeDirectory%Splash Media
	FileCreateDir %kUserHomeDirectory%Screen Images
	FileCreateDir %kUserHomeDirectory%Plugins
	FileCreateDir %kUserHomeDirectory%Translations
	FileCreateDir %kUserHomeDirectory%Grammars
	FileCreateDir %kUserHomeDirectory%Simulator Data
	FileCreateDir %kUserHomeDirectory%Temp
	FileCreateDir %kDatabaseDirectory%Community
	FileCreateDir %kDatabaseDirectory%User

	if FileExist(kResourcesDirectory . "Templates") {
		if !FileExist(A_MyDocuments . "\Simulator Controller\Plugins\Controller Plugins.ahk")
			FileCopy %kResourcesDirectory%Templates\Controller Plugins.ahk, %A_MyDocuments%\Simulator Controller\Plugins

		if !FileExist(A_MyDocuments . "\Simulator Controller\Plugins\Configuration Plugins.ahk")
			FileCopy %kResourcesDirectory%Templates\Configuration Plugins.ahk, %A_MyDocuments%\Simulator Controller\Plugins

		if !FileExist(kUserConfigDirectory . "Race.settings")
			FileCopy %kResourcesDirectory%Templates\Race.settings, %kUserConfigDirectory%
	}

	newID := !FileExist(kUserConfigDirectory . "ID")

	if !newID {
		idFileName := kUserConfigDirectory . "ID"

		FileReadLine id, %idFileName%, 1

		newID := ((id = false) || (Trim(id) = ""))
	}

	if newID {
		ticks := A_TickCount

		Random wait, 0, 100

		Random, , % Min(4294967295, A_TickCount)
		Random major, 0, 10000

		Sleep %wait%

		Random, , % Min(4294967295, A_TickCount)
		Random minor, 0, 10000

		id := values2String(".", A_TickCount, major, minor)

		try {
			FileDelete %kUserConfigDirectory%ID
		}
		catch exception {
			; ignore
		}

		FileAppend %id%, % kUserConfigDirectory . "ID"
	}

	if !FileExist(kDatabaseDirectory . "ID")
		FileCopy %kUserConfigDirectory%ID, %kDatabaseDirectory%ID

	if (!FileExist(kUserConfigDirectory . "UPDATES") && FileExist(kResourcesDirectory . "Templates"))
		FileCopy %kResourcesDirectory%Templates\UPDATES, %kUserConfigDirectory%
}

getControllerActionDefinitions(type) {
	fileName := ("Controller Action " . type . "." . getLanguage())

	if (!FileExist(kTranslationsDirectory . fileName) && !FileExist(kUserTranslationsDirectory . fileName))
		fileName := ("Controller Action " . type . ".en")

	definitions := readConfiguration(kTranslationsDirectory . fileName)

	for section, values in readConfiguration(kUserTranslationsDirectory . fileName)
		for key, value in values
			setConfigurationValue(definitions, section, key, value)

	return definitions
}


;;;-------------------------------------------------------------------------;;;
;;;                    Public Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

viewHTML(fileName, title := false, x := "Center", y := "Center", width := 800, height := 400) {
	static htmlViewer
	static dismissed := false

	if !title
		title := translate("News && Updates")

	dismissed := false

	if !fileName {
		dismissed := true

		return
	}

	FileRead html, %fileName%

	innerWidth := width - 16

	Gui HV:-Border -Caption
	Gui HV:Color, D0D0D0, D8D8D8
	Gui HV:Font, s10 Bold
	Gui HV:Add, Text, x8 y8 W%innerWidth% +0x200 +0x1 BackgroundTrans gmoveHTMLViewer, % translate("Modular Simulator Controller System")
	Gui HV:Font
	Gui HV:Add, Text, x8 yp+26 W%innerWidth% +0x200 +0x1 BackgroundTrans, %title%

	editHeight := height - 102

	Gui HV:Add, ActiveX, X8 YP+26 W%innerWidth% H%editHeight% vhtmlViewer, shell.explorer

	htmlViewer.Navigate("about:blank")

	htmlViewer.Document.open()
	htmlViewer.Document.write(html)
	htmlViewer.Document.close()

	SysGet mainScreen, MonitorWorkArea

	if x is not integer
		switch x {
			case "Left":
				x := 25
			case "Right":
				x := mainScreenRight - width - 25
			default:
				x := "Center"
		}

	if y is not integer
		switch y {
			case "Top":
				y := 25
			case "Bottom":
				y := mainScreenBottom - height - 25
			default:
				y := "Center"
		}

	buttonX := Round(width / 2) - 40

	Gui HV:Add, Button, Default X%buttonX% y+10 w80 gdismissHTMLViewer, % translate("Ok")

	Gui HV:+AlwaysOnTop
	Gui HV:Show, X%x% Y%y% W%width% H%height% NoActivate

	while !dismissed
		Sleep 100

	Gui HV:Destroy
}

showSplash(image, alwaysOnTop := true, video := false) {
	image := getFileName(image, kUserSplashMediaDirectory, kSplashMediaDirectory)

	lastSplash := vSplashCounter
	vSplashCounter += 1
	vLastImage := image

	if (vSplashCounter > 10)
		vSplashCounter := 1

	title := substituteVariables(translate(getConfigurationValue(kSimulatorConfiguration, "Splash Window", "Title", "")))
	subtitle := substituteVariables(translate(getConfigurationValue(kSimulatorConfiguration, "Splash Window", "Subtitle", "")))

	SplitPath image, , , extension

	Gui %vSplashCounter%:-Border -Caption
	Gui %vSplashCounter%:Color, D0D0D0, D8D8D8

	Gui %vSplashCounter%:Font, s10 Bold, Arial
	Gui %vSplashCounter%:Add, Text, x10 w780 Center, %title%

	if (extension = "GIF") {
		Gui %vSplashCounter%:Add, ActiveX, x10 y30 w780 h439 vvVideoPlayer, shell explorer

		vVideoPlayer.Navigate("about:blank")

		html := "<html><body style='background-color: #000000' style='overflow:hidden' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><img src='" . image . "' width=780 height=438 border=0 padding=0></body></html>"

		vVideoPlayer.document.write(html)
	}
	else
		Gui %vSplashCounter%:Add, Picture, x10 y30 w780 h439, %image%

	Gui %vSplashCounter%:Font, s8 Norm, Arial
	Gui %vSplashCounter%:Add, Text, x10 y474 w780 Center, %subtitle%

	options := "x" . Round((A_ScreenWidth - 800) / 2) . " y" . Round(A_ScreenHeight / 4)

	if alwaysOnTop
		Gui %vSplashCounter%:+AlwaysOnTop

	Gui %vSplashCounter%:Show, %options% AutoSize NoActivate

	if (lastSplash > 0)
		hideSplash(lastSplash)
}

hideSplash(splashCounter := false) {
	if !splashCounter
		splashCounter := vSplashCounter

	Gui %splashCounter%:Destroy
}

rotateSplash(alwaysOnTop := true) {
	static number := 1
	static images := false
	static numImages := 0

	if !images {
		images := getFileNames("*.jpg", kUserSplashMediaDirectory, kSplashMediaDirectory)

		numImages := images.Length()
	}

	if (number > numImages)
		number := 1

	if (number <= numImages)
		showSplash(images[number++], alwaysOnTop)
}

showSplashTheme(theme := "__Undefined__", songHandler := false, alwaysOnTop := true) {
	static images := false
	static number := 1
	static numImages := 0
	static onTop := false

	vSongIsPlaying := false

	if !songHandler
		songHandler := "playThemeSong"

	if (theme == kUndefined) {
		if (number > numImages)
			number := 1

		if (number <= numImages)
			showSplash(images[number++], onTop)

		return
	}

	song := false
	duration := 3000
	type := getConfigurationValue(kSimulatorConfiguration, "Splash Themes", theme . ".Type", false)

	if (type == "Video") {
		song := getConfigurationValue(kSimulatorConfiguration, "Splash Themes", theme . ".Song", false)
		video := getConfigurationValue(kSimulatorConfiguration, "Splash Themes", theme . ".Video")

		showSplash(video, true)

		if song {
			vSongIsPlaying := true

			%songHandler%(song)
		}

		return
	}
	else if (type == "Picture Carousel") {
		duration := getConfigurationValue(kSimulatorConfiguration, "Splash Themes", theme . ".Duration", 5000)
		song := getConfigurationValue(kSimulatorConfiguration, "Splash Themes", theme . ".Song", false)
		images := string2Values(",", getConfigurationValue(kSimulatorConfiguration, "Splash Themes", theme . ".Images", false))
	}
	else {
		logMessage(kLogCritical, translate("Theme """) . theme . translate(""" not found - please check the configuration"))

		images := getFileNames("*.jpg", kUserSplashMediaDirectory, kSplashMediaDirectory)
	}

	numImages := images.Length()
	onTop := alwaysOnTop

	showSplashTheme()

	SetTimer showSplashTheme, %duration%

	if song {
		vSongIsPlaying := true

		%songHandler%(song)
	}
}

hideSplashTheme() {
	SetTimer showSplashTheme, Off

	if vSongIsPlaying
		try {
			SoundPlay NonExistent.avi
		}
		catch ignore {
			; Ignore
		}

	hideSplash()
}

showProgress(options) {
	if !vProgressIsOpen {
		x := options.X
		y := options.Y

		if options.HasKey("Width")
			w := (options.Width - 20)
		else
			w := 280

		color := options.HasKey("color") ? options.color : "Green"

		Gui Progress:Default
		Gui Progress:-Border ; -Caption
		Gui Progress:Color, D0D0D0, D8D8D8

		Gui Progress:Font, s10 Bold, Arial
		Gui Progress:Add, Text, x10 w%w% Center vvProgressTitle

		Gui Progress:Add, Progress, x10 y30 w%w% h20 c%color% BackgroundGray vvProgressBar, 0

		Gui Progress:Font, s8 Norm, Arial
		Gui Progress:Add, Text, x10 y55 w%w% Center vvProgressMessage

		Gui Progress:+AlwaysOnTop
		Gui Progress:Show, x%x% y%y% AutoSize NoActivate

		vProgressIsOpen := true
	}

	Gui Progress:Default

	if options.HasKey("title")
		GuiControl, , vProgressTitle, % options.title

	if options.HasKey("message")
		GuiControl, , vProgressMessage, % options.message

	if options.HasKey("progress")
		GuiControl, , vProgressBar, % Round(options.progress)

	if options.HasKey("color") {
		color := options.color

		GuiControl +c%color%, vProgressBar
	}

	return "Progress"
}

hideProgress() {
	if vProgressIsOpen {
		Gui Progress:Destroy

		vProgressIsOpen := false
	}
}

getAllThemes(configuration := false) {
	themes := []

	if !configuration
		configuration := kSimulatorConfiguration

	for descriptor, value in getConfigurationSectionValues(configuration, "Splash Themes", Object()) {
		theme := StrSplit(descriptor, ".")[1]

		if !inList(themes, theme)
			themes.Push(theme)
	}

	return themes
}

showMessage(message, title := false, icon := "__Undefined__", duration := 1000
		  , x := "Center", y := "Bottom", width := 400, height := 100) {
	innerWidth := width - 16

	if (icon = kUndefined)
		icon := "Information.png"

	if (!title || (title = ""))
		title := translate("Modular Simulator Controller System")

	Gui SM:-Border -Caption
	Gui SM:Color, D0D0D0, D8D8D8
	Gui SM:Font, s10 Bold
	Gui SM:Add, Text, x8 y8 W%innerWidth% +0x200 +0x1 BackgroundTrans, %title%
	Gui SM:Font

	if icon {
		Gui SM:Add, Picture, w50 h50, % kIconsDirectory . Icon

		innerWidth -= 66

		Gui SM:Add, Text, X74 YP+5 W%innerWidth% H%height%, % message
	}
	else
		Gui SM:Add, Text, X8 YP+30 W%innerWidth% H%height%, % message

	SysGet mainScreen, MonitorWorkArea

	if x is not integer
		switch x {
			case "Left":
				x := 25
			case "Right":
				x := mainScreenRight - width - 25
			default:
				x := "Center"
		}

	if y is not integer
		switch y {
			case "Top":
				y := 25
			case "Bottom":
				y := mainScreenBottom - height - 25
			default:
				y := "Center"
		}

	Gui SM:+AlwaysOnTop
	Gui SM:Show, X%x% Y%y% W%width% H%height% NoActivate

	Sleep %duration%

	Gui SM:Destroy
}

moveByMouse(window) {
	if window is not alpha
		window := A_Gui

	curCoordMode := A_CoordModeMouse

	CoordMode Mouse, Screen

	try {
		MouseGetPos anchorX, anchorY
		WinGetPos winX, winY, w, h, A

		newX := winX
		newY := winY

		while GetKeyState("LButton", "P") {
			MouseGetPos x, y

			newX := winX + (x - anchorX)
			newY := winY + (y - anchorY)

			Gui %window%:Show, X%newX% Y%newY%
		}
	}
	finally {
		CoordMode Mouse, curCoordMode
	}
}

isNull(value) {
	return ((value == "__Null__") || (value = "null"))
}

reportNonObjectUsage(reference, p1 = "", p2 = "", p3 = "", p4 = "") {
	if isDebug()
		showMessage("The literal value " . reference . " was used as an object: " . p1 . "; " . p2 . "; " . p3 . "; " . p4
				  , false, kUndefined, 5000)

	return false
}

isDebug() {
	return vDebug
}

getLogLevel() {
	return vLogLevel
}

logMessage(logLevel, message) {
	if (logLevel >= vLogLevel) {
		level := ""

		switch logLevel {
			case kLogInfo:
				level := "Info    "
			case kLogWarn:
				level := "Warn    "
			case kLogCritical:
				level := "Critical"
			case kLogOff:
				level := "Off     "
			default:
				Throw "Unknown log level (" . logLevel . ") encountered in logMessage..."
		}

		fileName := kLogsDirectory . StrSplit(A_ScriptName, ".")[1] . " Logs.txt"
		message := "[" level . " - " . A_Now . "]: " . message . "`n"

		SplitPath fileName, , directory
		FileCreateDir %directory%
		FileAppend %message%, %fileName%, UTF-16
	}
}

availableLanguages() {
	translations := {en: "English"}

	for ignore, fileName in getFileNames("Translations.*", kUserTranslationsDirectory, kTranslationsDirectory) {
		SplitPath fileName, , , languageCode

		translations[languageCode] := readLanguage(languageCode)
	}

	return translations
}

readTranslations(targetLanguageCode, withUserTranslations := true) {
	fileNames := []
	fileName := (kTranslationsDirectory . "Translations." . targetLanguageCode)

	if FileExist(fileName)
		fileNames.Push(fileName)

	if withUserTranslations {
		fileName := (kUserTranslationsDirectory . "Translations." . targetLanguageCode)

		if FileExist(fileName)
			fileNames.Push(fileName)
	}

	translations := {}

	for ignore, fileName in fileNames
		Loop Read, %fileName%
		{
			translation := A_LoopReadLine

			translation := StrReplace(translation, "\=", "=")
			translation := StrReplace(translation, "\\", "\")
			translation := StrReplace(translation, "\n", "`n")

			translation := StrSplit(translation, "=>")
			enString := translation[1]

			if ((SubStr(enString, 1, 1) != "[") && (enString != targetLanguageCode))
				if ((A_Index == 1) && (translations.HasKey(enString) && (translations[enString] != translation[2])))
					Throw "Inconsistent translation encountered for """ . enString . """ in readTranslations..."
				else
					translations[enString] := translation[2]
		}

	return translations
}

writeTranslations(languageCode, languageName, translations) {
	fileName := kUserTranslationsDirectory . "Translations." . languageCode

	stdTranslations := readTranslations(languageCode, false)
	hasValues := false

	for ignore, value in stdTranslations {
		hasValues := true

		break
	}

	if hasValues {
		temp := {}

		for key, value in translations
			if (!stdTranslations.HasKey(key) || (stdTranslations[key] != value))
				temp[key] := value

		translations := temp
	}

	try {
		FileDelete %fileName%
	}
	catch exception {
		; ignore
	}

	curEncoding := A_FileEncoding

	FileEncoding UTF-16

	try {
		FileAppend [Locale]`n, %fileName%
		FileAppend %languageCode%=>%languageName%`n, %fileName%
		FileAppend [Translations], %fileName%

		for original, translation in translations {
			original := StrReplace(original, "\", "\\")
			original := StrReplace(original, "=", "\=")
			original := StrReplace(original, "`n", "\n")

			translation := StrReplace(translation, "\", "\\")
			translation := StrReplace(translation, "=", "\=")
			translation := StrReplace(translation, "`n", "\n")

			FileAppend `n%original%=>%translation%, %fileName%
		}
	}
	finally {
		FileEncoding %curEncoding%
	}
}

translate(string) {
	static currentLanguageCode := "en"
	static translations := false

	if (vTargetLanguageCode != "en") {
		if (vTargetLanguageCode != currentLanguageCode) {
			currentLanguageCode := vTargetLanguageCode

			translations := readTranslations(currentLanguageCode)
		}

		if translations.HasKey(string) {
			translation := translations[string]

			return ((translation != "") ? translation : string)
		}
		else
			return string
	}
	else
		return string
}

setLanguage(languageCode) {
	vTargetLanguageCode := languageCode
}

getLanguageFromLCID(lcid) {
	code := SubStr(lcid, StrLen(lcid) - 1)

	if (code = "07")
		return "DE"
	else if (code = "0c")
		return "FR"
	else if (code = "0a")
		return "ES"
	else if (code = "10")
		return "IT"
	else
		return "EN"
}

getSystemLanguage() {
	return getLanguageFromLCID(A_Language)
}

getLanguage() {
	return vTargetLanguageCode
}

protectionOn(critical := false, block := false) {
	changeProtection(true, critical, block)
}

protectionOff(critical := false, block := false) {
	changeProtection(false, critical, block)
}

withProtection(function, params*) {
	protectionOn()

	try {
		result := %function%(params*)
	}
	finally {
		protectionOff()
	}

	return result
}

isInstance(object, root) {
	if IsObject(object) {
		candidate := object.base

		while IsObject(candidate)
			if (candidate == root)
				return true
			else {
				classVar := (candidate.base ? candidate.base.__Class : false)

				if (classVar && (classVar != "")) {
					if InStr(classVar, ".") {
						classVar := StrSplit(classVar, ".")
						outerClassVar := classVar[1]

						candidate := %outerClassVar%[classVar[2]]
					}
					else
						candidate := %classVar%
				}
				else
					return false
			}
	}

	return false
}

getFileName(fileName, directories*) {
	fileName := substituteVariables(fileName)

	SplitPath fileName, , , , , driveName

	if (driveName && (driveName != ""))
		return fileName
	else {
		for ignore, directory in directories
			if FileExist(directory . fileName)
				return (directory . fileName)

		if (directories.Length() > 0)
			return (directories[1] . fileName)
		else
			return fileName
	}
}

getFileNames(filePattern, directories*) {
	files := []

	for ignore, directory in directories {
		pattern := directory . filePattern

		Loop Files, %pattern%, FD
			files.Push(A_LoopFileLongPath)
	}

	return files
}

normalizeFilePath(filePath) {
	Loop {
		position := InStr(filePath, "\..")

		if position {
			index := position - 1

			Loop {
				if (index == 0)
					return filePath
				else if (SubStr(filePath, index, 1) == "\") {
					filePath := StrReplace(filePath, SubStr(filePath, index, position + 3 - index), "")

					break
				}

				index -= 1
			}
		}
		else
			return filePath
	}
}

substituteVariables(string, values := false) {
	local variable

	result := string

	Loop {
		startPos := InStr(result, "%")

		if startPos {
			startPos += 1
			endPos := InStr(result, "%", false, startPos)

			if endPos {
				variable := Trim(SubStr(result, startPos, endPos - startPos))

				value := (values && values.HasKey(variable)) ? values[variable] : %variable%

				result := StrReplace(result, "%" . variable . "%", value)
			}
			else
				Throw "Second % not found while scanning (" . string . ") for variables in substituteVariables..."
		}
		else
			break
	}

	return result
}

string2Values(delimiter, string, count := false) {
	return (count ? StrSplit(Trim(string), delimiter, " `t", count) : StrSplit(Trim(string), delimiter, " `t"))
}

values2String(delimiter, values*) {
	result := ""

	for index, value in values {
		if (index > 1)
			result .= delimiter

		result .= value
	}

	return result
}

inList(list, value) {
	for index, candidate in list
		if (candidate = value)
			return index

	return false
}

listEqual(list1, list2) {
	if (list1.Length() != list2.Length())
		return false
	else
		for index, value in list1
			if (list2[index] != value)
				return false

	return true
}

concatenate(arrays*) {
	result := []

	for ignore, array in arrays
		for ignore, value in array
			result.Push(value)

	return result
}

reverse(list) {
	newList := []
	length := list.Length()

	Loop %length%
		newList.Push(list[length - (A_Index - 1)])

	return newList
}

map(list, function) {
	result := []

	for ignore, value in list
		result.Push(%function%(value))

	return result
}

remove(list, object) {
	result := []

	for ignore, value in list
		if (value != object)
			result.Push(value)

	return result
}

removeDuplicates(list) {
	result := []

	for ignore, value in list
		if !inList(result, value)
			result.Push(value)

	return result
}

getKeys(map) {
	keys := []

	for key, ignore in map
		keys.Push(key)

	return keys
}

getValues(map) {
	values := []

	for ignore, value in map
		values.Push(value)

	return values
}

greaterComparator(a, b) {
	return (a > b)
}

bubbleSort(ByRef array, comparator := "greaterComparator") {
	n := array.Length()

	while (n > 1) {
		newN := 1
		i := 0

		while (++i < n) {
			j := i + 1

			if %comparator%(lineI := array[i], lineJ := array[j]) {
				array[i] := lineJ
				array[J] := lineI

				newN := j
			}
		}

		n := newN
	}
}

functionEventHandler(event, data) {
	if InStr(data, ":") {
		data := StrSplit(data, ":", , 2)

		return withProtection(data[1], string2Values(";", data[2])*)
	}
	else
		return withProtection(data)
}

registerEventHandler(event, handler) {
	vEventHandlers[event] := handler
}

raiseEvent(messageType, event, data, target := false) {
	switch messageType {
		case kLocalMessage:
			logMessage(kLogInfo, translate("Raising event """) . event . (data ? translate(""": ") . data : translate("""")) . translate(" in current process"))

			eventHandler := vEventHandlers[event]

			if (!eventHandler)
				eventHandler := vEventHandlers["*"]

			logMessage(kLogInfo, translate("Dispatching event """) . event . (data ? translate(""": ") . data : translate("""")))

			vIncomingMessages.Push(Array(eventHandler, event, data))
		case kWindowMessage:
			logMessage(kLogInfo, translate("Raising event """) . event . (data ? translate(""": ") . data : translate("""")) . translate(" in target ") . target)

			vOutgoingMessages.Push(Func("sendWindowMessage").Bind(target, event, data))
		case kPipeMessage:
			logMessage(kLogInfo, translate("Raising event """) . event . (data ? translate(""": ") . data : translate("""")))

			vOutgoingMessages.Push(Func("sendPipeMessage").Bind(event, data))
		case kFileMessage:
			logMessage(kLogInfo, translate("Raising event """) . event . (data ? translate(""": ") . data : translate("""")) . translate(" in target ") . target)

			vOutgoingMessages.Push(Func("sendFileMessage").Bind(target, event, data))
		default:
			Throw "Unknown message type (" . messageType . ") detected in raiseEvent..."
	}
}

trayMessage(title, message, duration := false) {
	title := StrReplace(title, "`n", A_Space)
	message := StrReplace(message, "`n", A_Space)

	if !duration
		duration := vTrayMessageDuration

	if duration {
		protectionOn()

		try {
			vPendingTrayMessages.Push(Array(title, message, duration))
		}
		finally {
			protectionOff()
		}
	}
}

disableTrayMessages() {
	vTrayMessageDuration := false
}

enableTrayMessages(duration := 1500) {
	vTrayMessageDuration := duration
}

translateMsgBoxButtons(buttonLabels) {
	curDetectHiddenWindows := A_DetectHiddenWindows

    DetectHiddenWindows, On

	try {
		Process, Exist

		If (WinExist("ahk_class #32770 ahk_pid " . ErrorLevel)) {
			for index, label in buttonLabels
				try {
					ControlSetText Button%index%, % translate(label)
				}
				catch exception {
					; ignore
				}
		}
	}
	finally {
		DetectHiddenWindows %curDetectHiddenWindows%
	}
}

readConfiguration(configFile) {
	configFile := getFileName(configFile, kUserConfigDirectory, kConfigDirectory)

	configuration := Object()
	section := false

	Loop Read, %configFile%
	{
		currentLine := LTrim(A_LoopReadLine)

		if (StrLen(currentLine) == 0)
			continue

		firstChar := SubStr(currentLine, 1, 1)

		if (firstChar = ";")
			continue
		else if (firstChar = "[") {
			section := StrReplace(StrReplace(RTrim(currentLine), "[", ""), "]", "")

			configuration[section] := {}
		}
		else if section {
			keyValue := LTrim(A_LoopReadLine)

			if ((SubStr(keyValue, 1, 2) != "//") && (SubStr(keyValue, 1, 1) != ";")) {
				keyValue := StrSplit(StrReplace(StrReplace(StrReplace(keyValue, "\=", "_#_EQ-#_"), "\\", "_#_AC-#_"), "\n", "_#_CR-#_")
								   , "=", "", 2)

				key := StrReplace(StrReplace(StrReplace(keyValue[1], "_#_EQ-#_", "="), "_#_AC-#_", "\\"), "_#_CR-#_", "`n")
				value := StrReplace(StrReplace(StrReplace(keyValue[2], "_#_EQ-#_", "="), "_#_AC-#_", "\"), "_#_CR-#_", "`n")

				configuration[section][keyValue[1]] := ((value = kTrue) ? true : ((value = kFalse) ? false : value))
			}
		}
	}

	return configuration
}

parseConfiguration(text) {
	Random postfix, 1, 100000

	fileName := (kTempDirectory . "Config " . postFix . ".ini")

	FileAppend %text%, %fileName%, UTF-16

	configuration := readConfiguration(fileName)

	try {
		FileDelete %fileName%
	}
	catch exception {
		; ignore
	}

	return configuration
}

writeConfiguration(configFile, configuration) {
	configFile := getFileName(configFile, kUserConfigDirectory)

	try {
		FileDelete %configFile%
	}
	catch exception {
		; ignore
	}

	SplitPath configFile, , directory
	FileCreateDir %directory%

	for section, keyValues in configuration {
		pairs := ""

		for key, value in keyValues {
			value := StrReplace(value, "\", "\\")
			value := StrReplace(value, "=", "\=")
			value := StrReplace(value, "`n", "\n")

			pairs := (pairs . "`n" . key . "=" . ((value == true) ? kTrue : ((value == false) ? kFalse : value)))
		}

		section := "[" . section . "]" . pairs . "`n"

		FileAppend %section%, %configFile%, UTF-16
	}
}

printConfiguration(configuration) {
	Random postfix, 1, 100000

	fileName := (kTempDirectory . "Config " . postFix . ".ini")

	writeConfiguration(fileName, configuration)

	text := ""

	try {
		FileRead text, %fileName%
		FileDelete %fileName%
	}
	catch exception {
		; ignore
	}

	return text
}

getConfigurationValue(configuration, section, key, default := false) {
	if configuration.HasKey(section) {
		value := configuration[section]

		if value.HasKey(key)
			return value[key]
	}

	return default
}

getConfigurationSectionValues(configuration, section, default := false) {
	return configuration.HasKey(section) ? configuration[section].Clone() : default
}

newConfiguration() {
	return Object()
}

setConfigurationValue(configuration, section, key, value) {
	configuration[section, key] := value
}

setConfigurationSectionValues(configuration, section, values) {
	for key, value in values
		setConfigurationValue(configuration, section, key, value)
}

setConfigurationValues(configuration, otherConfiguration) {
	for section, values in otherConfiguration
		setConfigurationSectionValues(configuration, section, values)
}

removeConfigurationValue(configuration, section, key) {
	if configuration.HasKey(section)
		configuration[section].Delete(key)
}

removeConfigurationSection(configuration, section) {
	if configuration.HasKey(section)
		configuration.Delete(section)
}

getControllerConfiguration(configuration := false) {
	Process Exist, Simulator Controller.exe

	pid := ErrorLevel

	if (pid && !configuration && !FileExist(kUserConfigDirectory . "Simulator Controller.config")) {
		raiseEvent(kFileMessage, "Controller", "writeControllerConfiguration", pid)

		tries := 10

		while (tries > 0) {
			Sleep 200

			if FileExist(kUserConfigDirectory . "Simulator Controller.config")
				break
		}
	}
	else if (!pid && (configuration || !FileExist(kUserConfigDirectory . "Simulator Controller.config")))
		try {
			if configuration {
				writeConfiguration(kTempDirectory . "Simulator Configuration.ini", configuration)

				options := (" -Configuration """ . kTempDirectory . "Simulator Configuration.ini" . """")
			}
			else
				options := ""

			exePath := ("""" . kBinariesDirectory . "Simulator Controller.exe"" -NoStartup -NoUpdate" .  options)

			Run %exePath%, %kBinariesDirectory%, , pid

			Sleep 1000

			tries := 30

			while (tries > 0) {
				Sleep 200

				Process Exist, %pid%

				if !ErrorLevel
					break
			}

			if configuration
				FileDelete %kTempDirectory%Simulator Configuration.ini
		}
		catch exception {
			logMessage(kLogCritical, translate("Cannot start Simulator Controller (") . exePath . translate(") - please rebuild the applications in the binaries folder (") . kBinariesDirectory . translate(")"))

			showMessage(substituteVariables(translate("Cannot start Simulator Controller (%kBinariesDirectory%Simulator Controller.exe) - please rebuild the applications..."))
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}


	return readConfiguration(kUserConfigDirectory . "Simulator Controller.config")
}

getControllerActionLabels() {
	return getControllerActionDefinitions("Labels")
}

getControllerActionIcons() {
	icons := getControllerActionDefinitions("Icons")

	for section, values in icons
		for key, value in values
			values[key] := substituteVariables(value)

	return icons
}


;;;-------------------------------------------------------------------------;;;
;;;                        Controller Action Section                        ;;;
;;;-------------------------------------------------------------------------;;;

setDebug(debug) {
	vDebug := debug

	title := translate("Modular Simulator Controller System")
	state := (debug ? translate("Enabled") : translate("Disabled"))

	TrayTip %title%, Debug: %state%
}

setLogLevel(level) {
	switch level {
		case "Info":
			level := kLogInfo
		case "Warn":
			level := kLogWarn
		case "Critical":
			level := kLogCritical
		case "Off":
			level := kLogOff
	}

	vLogLevel := Min(kLogOff, Max(level, kLogInfo))

	state := translate("Unknown")

	switch vLogLevel {
		case kLogInfo:
			state := translate("Info")
		case kLogWarn:
			state := translate("Warn")
		case kLogCritical:
			state := translate("Critical")
		case kLogOff:
			state := translate("Off")
	}

	title := translate("Modular Simulator Controller System")

	TrayTip %title%, % translate("Log Level: ") . state
}

increaseLogLevel() {
	setLogLevel(getLogLevel() - 1)
}

decreaseLogLevel() {
	setLogLevel(getLogLevel() + 1)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeEnvironment()
loadSimulatorConfiguration()

if !vDetachedInstallation {
	checkForUpdates()
	requestShareSessionDatabaseConsent()
	shareSessionDatabase()
	checkForNews()
}

initializeLoggingSystem()
startMessageManager()
startTrayMessageManager()
createMessageReceiver()