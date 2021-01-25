﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Race Engineer                   ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
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

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Artificial Intelligence.ico
;@Ahk2Exe-ExeName Race Engineer.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\RuleEngine.ahk
#Include ..\Libraries\RaceEngineer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vRemotePID = 0


;;;-------------------------------------------------------------------------;;;
;;;                         Private Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RemotePitstopHandler {
	iRemotePID := false
	
	RemotePID[] {
		Get {
			return this.iRemotePID
		}
	}
	
	__New(remotePID) {
		this.iRemotePID := remotePID
	}
		
	callRemote(function, arguments*) {
		return raiseEvent("Pitstop", function . ":" . values2String(";", arguments*))
	}
	
	pitstopPlanned() {
		return this.callRemote("pitstopPlanned")
	}
	
	pitstopPrepared() {
		return his.callRemote("pitstopPrepared")
	}
	
	pitstopFinished() {
		return this.callRemote("pitstopFinished")
	}
	
	startPitstopSetup() {
		return this.callRemote("startPitstopSetup")
	}

	finishPitstopSetup() {
		return this.callRemote("finishPitstopSetup")
	}

	setPitstopRefuelAmount(litres) {
		return this.callRemote("setPitstopRefuelAmount", litres)
	}
	
	setPitstopTyreSet(compound, set := false) {
		return this.callRemote("setPitstopTyreSet", compound, set)
	}

	setPitstopTyrePressures(pressureFLIncrement, pressureFRIncrement, pressureRLIncrement, pressureRRIncrement) {
		return this.callRemote("setPitstopTyrePressures", pressureFLIncrement, pressureFRIncrement, pressureRLIncrement, pressureRRIncrement)
	}

	requestPitstopRepairs(repairSuspension, repairBodywork) {
		return this.callRemote("requestPitstopRepairs", repairSuspension, repairBodywork)
	}
}

;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

checkRemoteProcessAlive() {
	Process Exist, %vRemotePID%
	
	if !ErrorLevel
		ExitApp 0
}

startRaceEngineer() {
	icon := kIconsDirectory . "Artificial Intelligence.ico"
	
	Menu Tray, Icon, %icon%, , 1
	
	remotePID := 0
	remoteHandle := false
	engineerName := "Jona"
	engineerSpeaker := false
	engineerListener:= false
	raceSettingsFile := getFileName("Race Engineer.settings", kUserConfigDirectory, kConfigDirectory)
	
	index := 1
	while (index < A_Args.Length()) {
		switch A_Args[index] {
			case "-Remote":
				remotePID := A_Args[index + 1]
				index += 2
			case "-Name":
				engineerName := A_Args[index + 1]
				index += 2
			case "-Speaker":
				engineerSpeaker := A_Args[index + 1]
				index += 2
			case "-Listener":
				engineerListener := A_Args[index + 1]
				index += 2
			case "-Settings":
				raceSettingsFile := A_Args[index + 1]
				index += 2
		}
	}
	
	registerEventHandler("Race", "handleRemoteCalls")
	
	RaceEngineer.Instance := new RaceEngineer(false, readConfiguration(raceSettingsFile), remotePID ? new RemotePitstopHandler(remotePID) : false, engineerName, engineerSpeaker, engineerListener)
	
	if (remotePID != 0) {
		vRemotePID := remotePID
		
		SetTimer checkRemoteProcessAlive, 10000
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                          Event Handler Section                          ;;;
;;;-------------------------------------------------------------------------;;;

handleRemoteCalls(event, data) {
	local function
	
	if InStr(data, ":") {
		data := StrSplit(data, ":", , 2)
		
		if (data[1] = "Shutdown") {
			Sleep 30000
			
			ExitApp 0
		}
	
		function := ObjBindMethod(RaceEngineer.Instance, data[1])
		arguments := string2Values(";", data[2])
		
		return withProtection(function, arguments*)
	}
	else if (data = "Shutdown") {
		Sleep 30000
		
		ExitApp 0
	}
	else
		return withProtection(ObjBindMethod(RaceEngineer.Instance, data))
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

startRaceEngineer()