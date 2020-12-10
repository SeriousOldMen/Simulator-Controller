﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Build & Maintenance Tool        ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2020) Creative Commons - BY-NC-SA                        ;;;
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

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Tools.ico
;@Ahk2Exe-ExeName Simulator Tools.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kToolsConfigurationFile = kConfigDirectory . "Simulator Tools.ini"
global kToolsTargetsFile = kConfigDirectory . "Simulator Tools.targets"

global kCompiler = kAHKDirectory . "Compiler\ahk2exe.exe"

global kSave = "save"
global kRevert = "revert"
global kCancel = "cancel"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vCleanupTargets = []
global vBuildTargets = []

global vCleanupSettings = Object()
global vBuildSettings = Object()


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

checkFileDependency(file, modification) {
	logMessage(kLogInfo, "Checking file " . file . " for modification")
	
	FileGetTime lastModified, %file%, M
	
	if (lastModified > modification) {
		logMessage(kLogInfo, "File " . file . " found more recent than " . modification)
	
		return true
	}
	else
		return false
}

checkDirectoryDependency(directory, modification) {
	logMessage(kLogInfo, "Checking all files in " . directory)
	
	files := []
	
	Loop Files, % directory . "*.ahk", R
	{
		files.Push(A_LoopFilePath)
	}
	
	for ignore, file in files
		if checkFileDependency(file, modification)
			return true
	
	return false
}

checkDependencies(dependencies, modification) {
	for ignore, fileOrFolder in dependencies {
		attributes := FileExist(fileOrFolder)
	
		if InStr(attributes, "D") {
			if checkDirectoryDependency(fileOrFolder, modification)
				return true
		}
		else if attributes {
			if checkFileDependency(fileOrFolder, modification)
				return true
		}
	}
	
	return false
}

readToolsConfiguration(ByRef cleanupSettings, ByRef buildSettings) {
	targets := readConfiguration(kToolsTargetsFile)
	configuration := readConfiguration(kToolsConfigurationFile)
	
	cleanupSettings := Object()
	buildSettings := Object()
	
	for target, rule in getConfigurationSectionValues(targets, "Cleanup", Object())
		cleanupSettings[target] := getConfigurationValue(configuration, "Cleanup", target, InStr(target, "*.ahk") ? true : false)
	
	for target, rule in getConfigurationSectionValues(targets, "Build", Object())
		buildSettings[target] := getConfigurationValue(configuration, "Build", target, true)
	
	if A_IsCompiled
		buildSettings["Simulator Tools"] := false
}

writeToolsConfiguration(cleanupSettings, buildSettings) {
	configuration := newConfiguration()
	
	for target, setting in cleanupSettings
		setConfigurationValue(configuration, "Cleanup", target, setting)
		
	for target, setting in buildSettings
		setConfigurationValue(configuration, "Build", target, setting)
	
	writeConfiguration(kToolsConfigurationFile, configuration)
}

saveTargets() {
	editTargets(kSave)
}

cancelTargets() {
	editTargets(kCancel)
}

editTargets(command := "") {
	static result
	
	static cleanupVariable1
	static cleanupVariable2
	static cleanupVariable3
	static cleanupVariable4
	static cleanupVariable5
	static cleanupVariable6
	static cleanupVariable7
	static cleanupVariable8
	
	static buildVariable1
	static buildVariable2
	static buildVariable3
	static buildVariable4
	static buildVariable5
	static buildVariable6
	static buildVariable7
	static buildVariable8
	
	if (command == kSave) {
		Gui TE:Submit
		
		for target, setting in vCleanupSettings {
			cleanupVariable := "cleanupVariable" . A_Index
			
			vCleanupSettings[target] := %cleanupVariable%
		}
		
		for target, setting in vBuildSettings {
			buildVariable := "buildVariable" . A_Index
			
			vBuildSettings[target] := %buildVariable%
		}
		
		writeToolsConfiguration(vCleanupSettings, vBuildSettings)
		
		Gui TE:Destroy
		
		result := 1
	}
	else if (command == kRevert) {
		Gui TE:Destroy
		
		result := 2
	}
	else if (command == kCancel) {
		Gui TE:Destroy
		
		result := 3
	}
	else {
		result := false
		
		if (vCleanupSettings.Length() > 8)
			Throw "Too many cleanup targets detected in editTargets..."
		
		if (vBuildSettings.Length() > 8)
			Throw "Too many build targets detected in editTargets..."
		
		Gui TE:-border -Caption
		Gui TE:Color, D0D0D0
	
		Gui TE:Font, Bold, Arial
	
		Gui TE:Add, Text, w220 Center, Modular Simulator Controller System 
		
		Gui TE:Font, Norm, Arial
		Gui TE:Font, Italic, Arial
	
		Gui TE:Add, Text, YP+20 w220 Center, Build Targets
	
		Gui TE:Font, Norm, Arial
		Gui TE:Font, Italic, Arial
		
		cleanupHeight := 20 + (vCleanupSettings.Count() * 20)
		
		if (cleanupHeight == 20)
			cleanupHeight := 40
			
		Gui TE:Add, GroupBox, YP+30 w220 h%cleanupHeight%, Cleanup
	
		Gui TE:Font, Norm, Arial
	
		if (vCleanupSettings.Count() > 0)
			for target, setting in vCleanupSettings {
				option := ""
				
				if (A_Index == 1)
					option := option . " YP+20 XP+10"
					
				Gui TE:Add, CheckBox, %option% Checked%setting% vcleanupVariable%A_Index%, %target%
			}
		else
			Gui TE:Add, Text, YP+20 XP+10, No targets found...
	
		Gui TE:Font, Norm, Arial
		Gui TE:Font, Italic, Arial
	
		buildHeight := 20 + (vBuildSettings.Count() * 20)
		
		if (buildHeight == 20)
			buildHeight := 40
			
		Gui TE:Add, GroupBox, XP-10 YP+30 w220 h%buildHeight%, Build
	
		Gui TE:Font, Norm, Arial
	
		if (vBuildSettings.Count() > 0)
			for target, setting in vBuildSettings {
				option := ""
				
				if (A_Index == 1)
					option := option . " YP+20 XP+10"
					
				if (target == "Simulator Tools")
					option := option . (A_IsCompiled ? " Disabled" : "")
					
				Gui TE:Add, CheckBox, %option% Checked%setting% vbuildVariable%A_Index%, %target%
			}
		else
			Gui TE:Add, Text, YP+20 XP+10, No targets found...
	 
		Gui TE:Add, Button, Default X10 Y+20 w100 gsaveTargets, &Build
		Gui TE:Add, Button, X+20 w100 gcancelTargets, &Cancel
	
		Gui TE: Margin, 10, 10
		Gui TE: show, AutoSize Center
		
		Loop
			Sleep 1000
		until result
	
		return ((result == 1) || (result == 2))
	}
}

runCleanTargets(ByRef buildProgress) {
	for ignore, target in vCleanupTargets {
		targetName := target[1]
	
		Progress %buildProgress%, % "Cleaning " . targetName . "..."
			
		logMessage(kLogInfo, "Cleaning " . targetName)

		if (target.Length() == 2) {
			fileOrFolder := target[2]
			
			if (InStr(FileExist(fileOrFolder), "D")) {
				currentDirectory := A_WorkingDir
		
				SetWorkingDir %fileOrFolder%
			
				Loop Files, *.*
					FileDelete %A_LoopFilePath%
			
				SetWorkingDir %currentDirectory%
			}
			else if (FileExist(fileOrFolder) != "") {
				FileDelete %fileOrFolder%
			}
		}
		else {
			currentDirectory := A_WorkingDir
			directory := target[2]
			pattern := target[3]
			options := ((target[4] && (target[4] != "")) ? target[4] : "")
			
			SetWorkingDir %directory%
			
			Loop Files, %pattern%, %options%
			{
				FileDelete %A_LoopFilePath%
			
				Progress %buildProgress%, % "Deleting " . A_LoopFileName . "..."
		
				Sleep 100
			}
			
			SetWorkingDir %currentDirectory%
		}
			
		Sleep 1000
				
		buildProgress += Round(100 / (vCleanupTargets.Length() + vBuildTargets.Length() + 1))
			
		Progress %buildProgress%
	}
}

runBuildTargets(ByRef buildProgress) {
	for ignore, target in vBuildTargets {
		targetName := target[1]
	
		Progress %buildProgress%, % "Compiling " . targetName . "..."
			
		logMessage(kLogInfo, "Building " . targetName)

		build := false
		
		targetSource := target[2]
		targetBinary := target[3]
		
		FileGetTime srcLastModified, %targetSource%, M
		FileGetTime binLastModified, %targetBinary%, M
		
		if binLastModified {
			build := (build || (ErrorLevel || (srcLastModified > binLastModified)))
			build := (build || checkDependencies(target[4], binLastModified))
		}
		else
			build := true
		
		if build {
			rotateSplash(false)
			
			logMessage(kLogInfo, targetName . " or dependent files out of date - needs recompile")
			logMessage(kLogInfo, "Compiling " . targetSource)

			try {
				RunWait % kCompiler . " /in """ . targetSource . """"
			}
			catch exception {
				logMessage(kLogCritical, "Cannot compile " . targetSource . " - source file or AHK Compiler (" . kCompiler . ") not found")
			
				SplashTextOn 800, 60, Modular Simulator Controller System - Compiler, Cannot compile %targetSource%: `n`nSource file or AHK Compiler (%kCompiler%) not found...
				
				Sleep 5000
				
				SplashTextOff
			}
			
			SplitPath targetBinary, compiledFile, targetDirectory
			SplitPath targetSource, , sourceDirectory 
			
			compiledFile := sourceDirectory . "\" . compiledFile
			
			FileCreateDir %targetDirectory%
			FileMove %compiledFile%, %targetDirectory%, 1
		}
			
		Sleep 1000
		
		buildProgress += Round(100 / (vCleanupTargets.Length() + vBuildTargets.Length() + 1))
			
		Progress %buildProgress%
	}
}

substituteVariables(string) {
	result := string
	
	Loop {
		startPos := InStr(result, "%")
		
		if startPos {
			startPos += 1
			endPos := InStr(result, "%", false, startPos)
			
			if endPos {
				variable := SubStr(result, startPos, endPos - startPos)
				path := %variable%
				
				result := StrReplace(result, "%" . variable . "%", path)
			}
			else
				Throw "Second % not found while scanning (" . string . ") for variables in substituteVariables..."
		}
		else
			break
	}
		
	return result
}

prepareTargets(ByRef buildProgress) {
	targets := readConfiguration(kToolsTargetsFile)
	
	for target, arguments in getConfigurationSectionValues(targets, "Cleanup", Object()) {
		buildProgress +=1
		build := vCleanupSettings[target]
		
		Progress, %buildProgress%, % target . ": " . (build ? "Yes" : "No")
		
		if build {
			arguments := substituteVariables(arguments)
			
			vCleanupTargets.Push(Array(target, string2Values(",", arguments)))
		}
	
		Sleep 200
	}
	
	for target, arguments in getConfigurationSectionValues(targets, "Build", Object()) {
		buildProgress +=1
		build := vBuildSettings[target]
		
		Progress, %buildProgress%, % target . ": " . (build ? "Yes" : "No")
		
		if build {
			arguments := substituteVariables(arguments)
			
			rule := string2Values("<-", arguments)
			binary := rule[1]
			
			arguments := string2Values(";", rule[2])
			
			source := arguments[1]
			dependencies := string2Values(",", arguments[2])
		
			vBuildTargets.Push(Array(target, source, binary, dependencies))
		}
	
		Sleep 200
	}
}

runTargets() {
	if (!FileExist(kToolsConfigurationFile) || GetKeyState("Ctrl")) {
		readToolsConfiguration(vCleanupSettings, vBuildSettings)
	
		if (!editTargets() && !isDebug())
			ExitApp 0
	}
	else
		readToolsConfiguration(vCleanupSettings, vBuildSettings)
	
	icon := kIconsDirectory . "Tools.ico"
	
	Menu Tray, Icon, %icon%, , 1
	
	rotateSplash(false)
	
	Sleep 1000
	
	x := Round((A_ScreenWidth - 300) / 2)
	y := A_ScreenHeight - 150
	
	Progress 1:B w300 x%x% y%y% FS8 CWD0D0D0 CBGreen, %A_Space%, Preparing Targets

	buildProgress := 0
	
	prepareTargets(buildProgress)
	
	rotateSplash(false)
	
	Progress, , %A_Space%, Running Targets
	
	runCleanTargets(buildProgress)
	runBuildTargets(buildProgress)
		
	Progress 100, Done
	
	Sleep 500
	
	Progress Off
	
	ExitApp 0
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

runTargets()


;;;-------------------------------------------------------------------------;;;
;;;                         Hotkey & Label Section                          ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Escape::                   Cancel Build                                 ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
Escape::
protectionOn()

try {
	SoundPlay *32
	OnMessage(0x44, "translateMsgBoxButtons")
	MsgBox 262180, Simulator Build, Cancel target processing?
	OnMessage(0x44, "")
	
	IfMsgBox Yes
		ExitApp 0
}
finally {
	protectionOff()
}

return