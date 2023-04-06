﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Debug Functions                 ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global gDebug := (kBuildConfiguration = "Development")
global gLogLevel := ((kBuildConfiguration = "Development") ? kLogDebug : kLogWarn)


;;;-------------------------------------------------------------------------;;;
;;;                        Public Constants Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global SupportMenu := Menu()
global LogMenu := Menu()


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Framework\Constants.ahk"
#Include "..\Framework\Variables.ahk"
#Include "..\Framework\Files.ahk"
#Include "..\Framework\Strings.ahk"
#Include "..\Framework\Localization.ahk"
#Include "..\Framework\TrayMenu.ahk"
#Include "..\Framework\Message.ahk"
#Include "..\Libraries\Messages.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                        Public Constants Section                         ;;;
;;;-------------------------------------------------------------------------;;;

/* Must be defined in Constants.ahk due to circular loading problems...
global kLogDebug := 1
global kLogInfo := 2
global kLogWarn := 3
global kLogCritical := 4
global kLogOff := 5

global kLogLevels := {Off: kLogOff, Debug: kLogDebug, Info: kLogInfo, Warn: kLogWarn, Critical: kLogCritical}
global kLogLevelNames := ["Debug", "Info", "Warn", "Critical", "Off"]
*/


;;;-------------------------------------------------------------------------;;;
;;;                    Private Function Declaration Section                 ;;;
;;;-------------------------------------------------------------------------;;;

reportNonObjectUsage(reference, p1 := "", p2 := "", p3 := "", p4 := "") {
	if isDebug() {
		showMessage(StrSplit(A_ScriptName, ".")[1] . ": The literal value " . String(reference) . " was used as an object: "
												   . String(p1) . "; " . String(p2) . "; " . String(p3) . "; " . String(p4)
				  , false, kUndefined, 5000)

		if isDevelopment()
			ListLines()
	}

	return false
}

initializeDebugging() {
	String.__Call := reportNonObjectUsage
	String.__Get := reportNonObjectUsage
	String.__Set := reportNonObjectUsage
	Number.__Get := reportNonObjectUsage
	Number.__Call := reportNonObjectUsage
	Number.__Set := reportNonObjectUsage

	OnError(logUnhandledError)
}

logUnhandledError(error, *) {
	return logError(error, true)
}


;;;-------------------------------------------------------------------------;;;
;;;                    Public Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

isDebug() {
	global gDebug

	return gDebug
}

isLogLevel(logLevel) {
	return (logLevel >= gLogLevel)
}

isDevelopment() {
	global kBuildConfiguration

	return (kBuildConfiguration = "Development")
}

getLogLevel() {
	global gLogLevel

	return gLogLevel
}

logMessage(logLevel, message) {
	global gLogLevel

	local script := StrSplit(A_ScriptName, ".")[1]
	local time := A_Now
	local level, fileName, directory, tries, logTime, logLine, pid

	static sending := false

	if isLogLevel(logLevel) {
		level := ""

		switch logLevel {
			case kLogDebug:
				level := "Debug   "
			case kLogInfo:
				level := "Info    "
			case kLogWarn:
				level := "Warn    "
			case kLogCritical:
				level := "Critical"
			case kLogOff:
				level := "Off     "
			default:
				throw "Unknown log level (" . logLevel . ") encountered in logMessage..."
		}

		logTime := FormatTime(time, "dd.MM.yy hh:mm:ss tt")

		fileName := kLogsDirectory . script . " Logs.txt"
		logLine := "[" level . " - " . logTime . "]: " . message . "`n"

		SplitPath(fileName, , &directory)
		DirCreate(directory)

		tries := 5

		while (tries > 0)
			try {
				FileAppend(logLine, fileName, "UTF-16")

				break
			}
			catch Any as exception {
				Sleep(1)

				tries -= 1
			}

		if (!sending && (script != "System Monitor")) {
			pid := ProcessExist("System Monitor.exe")

			if pid {
				sending := true

				try {
					messageSend(kFileMessage, "Monitoring", "logMessage:" . values2String(";", script, time, logLevel, message), pid)
				}
				finally {
					sending := false
				}
			}
		}
	}
}

logError(exception, unhandled := false, report := true) {
	local debug := (isDevelopment() && isDebug())
	local handle, message

	if isObject(exception) {
		message := exception.Message

		if !isNumber(message)
			logMessage(unhandled ? kLogCritical : kLogDebug
					 , translate(unhandled ? "Unhandled exception encountered in " : "Handled exception encountered in ")
					 . exception.File . translate(" at line ") . exception.Line . translate(": ") . message)
	}
	else if !isNumber(exception)
		logMessage(unhandled ? kLogCritical : kLogDebug
				 , translate(unhandled ? "Unhandled exception encountered: " : "Handled exception encountered: ") . exception)

	if ((unhandled || report) && debug && (true || !A_IsCompiled))
		if isObject(exception)
			MsgBox(translate(unhandled ? "Unhandled exception encountered in " : "Handled exception encountered in ")
				 . exception.File . translate(" at line ") . exception.Line . translate(": ") . exception.Message
				 . (exception.HasProp("Stack") ? ("`n`nStack:`n`n" . exception.Stack) : ""))
		else
			MsgBox(translate(unhandled ? "Unhandled exception encountered: " : "Handled exception encountered: ") . exception)

	if debug
		return (A_IsCompiled ? -1 : false)
	else
		return -1
}


;;;-------------------------------------------------------------------------;;;
;;;                        Controller Action Section                        ;;;
;;;-------------------------------------------------------------------------;;;

toggleDebug(*) {
	setDebug(!isDebug())
}

setDebug(debug, *) {
	global gDebug
	local title, state

	if hasTrayMenu()
		if debug
			SupportMenu.Check(translate("Debug"))
		else
			SupportMenu.Uncheck(translate("Debug"))

	if (gDebug || debug) {
		title := translate("Modular Simulator Controller System")
		state := (debug ? translate("Enabled") : translate("Disabled"))

		TrayTip(title, "Debug: " . state)
	}

	gDebug := debug
}

setLogLevel(level, *) {
	global gLogLevel

	local ignore, title, state

	if hasTrayMenu()
		for ignore, label in ["Off", "Info", "Warn", "Critical"]
			LogMenu.Uncheck(translate(label))

	switch level, false {
		case "Debug":
			level := kLogDebug
		case "Info":
			level := kLogInfo
		case "Warn":
			level := kLogWarn
		case "Critical":
			level := kLogCritical
		case "Off":
			level := kLogOff
		default:
			if !isInteger(level)
				level := kLogWarn
	}

	level := Min(kLogOff, Max(level, kLogDebug))

	state := translate("Unknown")

	switch level {
		case kLogDebug:
			state := translate("Debug")
		case kLogInfo:
			state := translate("Info")
		case kLogWarn:
			state := translate("Warn")
		case kLogCritical:
			state := translate("Critical")
		case kLogOff:
			state := translate("Off")
	}

	if (gLogLevel != level) {
		gLogLevel := level

		title := translate("Modular Simulator Controller System")

		TrayTip(title, translate("Log Level: ") . state)
	}

	if hasTrayMenu()
		LogMenu.Check(state)
}

increaseLogLevel(*) {
	setLogLevel(getLogLevel() - 1)
}

decreaseLogLevel(*) {
	setLogLevel(getLogLevel() + 1)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeDebugging()