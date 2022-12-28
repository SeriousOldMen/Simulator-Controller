;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Team Session Log Program        ;;;
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
#Warn LocalSameAsGlobal, Off

SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.

SetBatchLines -1				; Maximize CPU utilization
ListLines Off					; Disable execution history

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Engine.ico
;@Ahk2Exe-ExeName Team Session Logger.exe

global vBuildConfiguration := "Development"


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Framework\Application.ahk


;;;-------------------------------------------------------------------------;;;
;;;                    Public Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

readSimulatorData(simulator, options := "", protocol := "SHM") {
	exePath := kBinariesDirectory . simulator . A_Space . protocol . " Provider.exe"

	FileCreateDir %kTempDirectory%%simulator% Data

	dataFile := temporaryFileName(simulator . " Data\" . protocol, "data")

	try {
		RunWait %ComSpec% /c ""%exePath%" %options% > "%dataFile%"", , Hide
	}
	catch exception {
		logMessage(kLogCritical, substituteVariables(translate("Cannot start %simulator% %protocol% Provider ("), {simulator: simulator, protocol: protocol})
												   . exePath . translate(") - please rebuild the applications in the binaries folder (")
												   . kBinariesDirectory . translate(")"))

		showMessage(substituteVariables(translate("Cannot start %simulator% %protocol% Provider (%exePath%) - please check the configuration...")
									  , {exePath: exePath, simulator: simulator, protocol: protocol})
				  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
	}

	data := readConfiguration(dataFile)

	deleteFile(dataFile)

	setConfigurationValue(data, "Session Data", "Simulator", simulator)

	return data
}

runTeamSessionLogger() {
	icon := kIconsDirectory . "Engine.ico"

	Menu Tray, Icon, %icon%, , 1
	Menu Tray, Tip, Team Session Logger

	deleteFile(kTempDirectory . "Team Session.log")

	loop {
		data := readSimulatorData("ACC")

		info := values2String("; ", A_Now,
								  , getConfigurationValue(data, "Session Data", "Active", "?")
								  , getConfigurationValue(data, "Session Data", "Paused", "?")
								  , getConfigurationValue(data, "Session Data", "Session", "?")
								  , getConfigurationValue(data, "Stint Data", "Laps", "?")
								  , getConfigurationValue(data, "Stint Data", "InPit", "?")
								  , getConfigurationValue(data, "Stint Data", "DriverForname", "?")
								  , getConfigurationValue(data, "Stint Data", "DriverSurname", "?")
								  , getConfigurationValue(data, "Stint Data", "DriverNickName", "?")
								  , getConfigurationValue(data, "Stint Data", "DriverTimeRemaining", "?")
								  , getConfigurationValue(data, "Stint Data", "StintTimeRemaining", "?")) . "`n"

		FileAppend %info%, %kTempDirectory%Team Session.log

		Sleep 10000
	}

	return
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

runTeamSessionLogger()