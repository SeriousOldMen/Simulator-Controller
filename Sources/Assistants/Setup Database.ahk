﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Setup Database Tool             ;;;
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

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Wrench.ico
;@Ahk2Exe-ExeName Setup Database.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Assistants\Libraries\SettingsDatabase.ahk
#Include ..\Assistants\Libraries\TyresDatabase.ahk


;;;-------------------------------------------------------------------------;;;
;;;                   Private Constant Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global kClose = "Close"

global kSetupNames = {DQ: "Qualification (Dry)", DR: "Race (Dry)", WQ: "Qualification (Wet)", WR: "Race (Wet)"}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Variable Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global vRequestorPID := false


;;;-------------------------------------------------------------------------;;;
;;;                         Public Classes Section                          ;;;
;;;-------------------------------------------------------------------------;;;

global simulatorDropDown
global carDropDown
global trackDropDown
global weatherDropDown

global notesEdit

global settingsTab

global settingsTab1
global settingsTab2
global settingsTab3

global settingsListView

global settingGroupDropDown

global addSettingGroupButton
global deleteSettingGroupButton

global addSettingButton
global deleteSettingButton

global setupTypeDropDown
global uploadSetupButton
global downloadSetupButton
global deleteSetupButton

global dryQualificationDropDown
global uploadDryQualificationButton
global downloadDryQualificationButton
global deleteDryQualificationButton
global dryRaceDropDown
global uploadDryRaceButton
global downloadDryRaceButton
global deleteDryRaceButton
global wetQualificationDropDown
global uploadWetQualificationButton
global downloadWetQualificationButton
global deleteWetQualificationButton
global wetRaceDropDown
global uploadWetRaceButton
global downloadWetRaceButton
global deleteWetRaceButton

global tyreCompoundDropDown
global airTemperatureEdit
global trackTemperatureEdit

global flPressure1
global flPressure2
global flPressure3
global flPressure4
global flPressure5

global frPressure1
global frPressure2
global frPressure3
global frPressure4
global frPressure5

global rlPressure1
global rlPressure2
global rlPressure3
global rlPressure4
global rlPressure5

global rrPressure1
global rrPressure2
global rrPressure3
global rrPressure4
global rrPressure5

global transferPressuresButton

class SessionDatabaseEditor extends ConfigurationItem {
	iSessionDatabase := new SessionDatabase()
	
	iSelectedSimulator := false
	iSelectedCar := true
	iSelectedTrack := true
	iSelectedWeather := "Dry"
	
	iAirTemperature := 27
	iTrackTemperature := 31
	iTyreCompound := "Dry"
	iTyreCompoundColor := "Black"
	
	iAvailableModules := {Settings: false, Setups: false, Pressures: false}
	iSelectedModule := false

	iSelectedSetupType := false
	
	iSelectedSettingGroup := false
	
	iDataListView := false
	iSettingsListView := false
	iSetupListView := false
	
	Window[] {
		Get {
			return "SDE"
		}
	}
	
	SessionDatabase[] {
		Get {
			return this.iSessionDatabase
		}
	}
	
	SelectedSimulator[label := false] {
		Get {
			if (label = "*")
				return ((this.iSelectedSimulator == true) ? "*" : this.iSelectedSimulator)
			else if label
				return this.iSelectedSimulator
			else
				return this.iSelectedSimulator
		}
	}
	
	SelectedCar[label := false] {
		Get {
			if ((label = "*") && (this.iSelectedCar == true))
				return "*"
			else if (label && (this.iSelectedCar == true))
				return translate("All")
			else
				return this.iSelectedCar
		}
	}
	
	SelectedTrack[label := false] {
		Get {
			if ((label = "*") && (this.iSelectedTrack == true))
				return "*"
			else if (label && (this.iSelectedTrack == true))
				return translate("All")
			else
				return this.iSelectedTrack
		}
	}
	
	SelectedWeather[] {
		Get {
			return this.iSelectedWeather
		}
	}
	
	SelectedModule[] {
		Get {
			return this.iSelectedModule
		}
	}
	
	SelectedSettingGroup[] {
		Get {
			return this.iSelectedSettingGroup
		}
	}
	
	SelectedSetupType[] {
		Get {
			return this.iSelectedSetupType
		}
	}
	
	DataListView[] {
		Get {
			return this.iDataListView
		}
	}
	
	SettingsListView[] {
		Get {
			return this.iSettingsListView
		}
	}
	
	SetupListView[] {
		Get {
			return this.iSetupListView
		}
	}
	
	__New(simulator := false, car := false, track := false
		, weather := false, airTemperature := false, trackTemperature := false, compound := false, compoundColor := false) {
		if simulator {
			this.iSelectedSimulator := simulator
			this.iSelectedCar := car
			this.iSelectedTrack := track
			this.iSelectedWeather := weather
			this.iAirTemperature := airTemperature
			this.iTrackTemperature := trackTemperature
			this.iTyreCompound := compound
			this.iTyreCompoundColor := compoundColor
		}
		
		base.__New(kSimulatorConfiguration)
		
		SessionDatabaseEditor.Instance := this
	}
	
	createGui(configuration) {
		window := this.Window
		
		Gui %window%:Default
	
		Gui %window%:-Border ; -Caption
		Gui %window%:Color, D0D0D0, D8D8D8

		Gui %window%:Font, s10 Bold, Arial

		Gui %window%:Add, Text, w664 Center gmoveSessionDatabaseEditor, % translate("Modular Simulator Controller System") 
		
		Gui %window%:Font, s9 Norm, Arial
		Gui %window%:Font, Italic Underline, Arial

		Gui %window%:Add, Text, YP+20 w664 cBlue Center gopenSessionDatabaseEditorDocumentation, % translate("Session Database")
		
		Gui %window%:Add, Text, x8 yp+30 w670 0x10
		
		Gui %window%:Font, Norm
		Gui %window%:Font, s10 Bold, Arial
			
		Gui %window%:Add, Picture, x16 yp+12 w30 h30 Section, %kIconsDirectory%Road.ico
		Gui %window%:Add, Text, x50 yp+5 w120 h26, % translate("Selection")
		
		Gui %window%:Font, s8 Norm, Arial
		
		Gui %window%:Add, Text, x16 yp+32 w80 h23 +0x200, % translate("Simulator")
		
		car := this.SelectedCar
		track := this.SelectedTrack
		weather := this.SelectedWeather
		
		simulators := this.getSimulators()
		simulator := 0
		
		if (simulators.Length() > 0) {
			if this.SelectedSimulator
				simulator := inList(simulators, this.SelectedSimulator)

			if (simulator == 0)
				simulator := 1
		}
	
		Gui %window%:Add, DropDownList, x100 yp w160 Choose%simulator% vsimulatorDropDown gchooseSimulator, % values2String("|", simulators*)
		
		if (simulator > 0)
			simulator := simulators[simulator]
		else
			simulator := false
		
		Gui %window%:Add, Text, x16 yp+24 w80 h23 +0x200, % translate("Car")
		Gui %window%:Add, DropDownList, x100 yp w160 Choose1 vcarDropDown gchooseCar, % translate("All")
		
		Gui %window%:Add, Text, x16 yp+24 w80 h23 +0x200, % translate("Track")
		Gui %window%:Add, DropDownList, x100 yp w160 Choose1 vtrackDropDown gchooseTrack, % translate("All")
		
		Gui %window%:Add, Text, x16 yp+24 w80 h23 +0x200, % translate("Conditions")
		
		choices := map(kWeatherOptions, "translate")
		choices.InsertAt(1, translate("All"))
		chosen := inList(kWeatherOptions, weather)
		
		if (!chosen && (choices.Length() > 0)) {
			weather := choices[1]
			chosen := 1
		}
		
		Gui %window%:Add, DropDownList, x100 yp w160 AltSubmit Choose%chosen% gchooseWeather vweatherDropDown, % values2String("|", choices*)
		
		Gui %window%:Font, Norm
		Gui %window%:Font, s10 Bold, Arial
		
		Gui %window%:Add, Picture, x280 ys w30 h30 Section, %kIconsDirectory%Report.ico
		Gui %window%:Add, Text, xp+34 yp+5 w120 h26, % translate("Notes")
		
		Gui %window%:Font, s8 Norm, Arial
		
		Gui %window%:Add, Edit, x280 yp+32 w390 h94 -Background gupdateNotes vnotesEdit

		Gui %window%:Add, Text, x16 yp+104 w654 0x10
		
		Gui %window%:Font, Norm
		Gui %window%:Font, s10 Bold, Arial
			
		Gui %window%:Add, Picture, x16 yp+12 w30 h30 Section gchooseTab1, %kIconsDirectory%Report Settings.ico
		Gui %window%:Add, Text, x50 yp+5 w220 h26 vsettingsTab1 gchooseTab1, % translate("Race Settings")
		
		Gui %window%:Add, Text, x16 yp+32 w267 0x10
		
		Gui %window%:Font, Norm
		Gui %window%:Font, s10 Bold cGray, Arial
			
		Gui %window%:Add, Picture, x16 yp+10 w30 h30 gchooseTab2, %kIconsDirectory%Tools BW.ico
		Gui %window%:Add, Text, x50 yp+5 w220 h26 vsettingsTab2 gchooseTab2, % translate("Setup Repository")
		
		Gui %window%:Add, Text, x16 yp+32 w267 0x10
		
		Gui %window%:Font, Norm
		Gui %window%:Font, s10 Bold cGray, Arial
			
		Gui %window%:Add, Picture, x16 yp+10 w30 h30 gchooseTab3, %kIconsDirectory%Pressure.ico
		Gui %window%:Add, Text, x50 yp+5 w220 h26 vsettingsTab3 gchooseTab3, % translate("Tyre Pressure Advisor")
		
		Gui %window%:Add, Text, x16 yp+32 w267 0x10
		
		Gui %window%:Font, s8 Norm cBlack, Arial
		
		Gui %window%:Add, GroupBox, x280 ys-8 w390 h372 
		
		tabs := map(["Tyres", "Setup", "Settings"], "translate")

		Gui %window%:Add, Tab2, x296 ys+16 w0 h0 -Wrap vsettingsTab Section, % values2String("|", tabs*)

		Gui Tab, 1
		
		Gui %window%:Add, Text, x296 ys w80 h23 +0x200, % translate("Group")
		Gui %window%:Add, DropDownList, xp+90 yp w218 vsettingGroupDropDown gchooseSettingGroup
		
		Gui %window%:Add, Button, xp+220 yp w23 h23 HWNDaddSettingButtonHandle gaddSettingGroup vaddSettingGroupButton
		Gui %window%:Add, Button, xp+25 yp w23 h23 HwnddeleteSettingButtonHandle gdeleteSettingGroup vdeleteSettingGroupButton
		setButtonIcon(addSettingButtonHandle, kIconsDirectory . "Plus.ico", 1)
		setButtonIcon(deleteSettingButtonHandle, kIconsDirectory . "Minus.ico", 1)
		
		Gui %window%:Add, ListView, x296 yp+24 w360 h198 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndsettingsListViewHandle gchooseSetting, % values2String("|", map(["Setting", "Label", "Value"], "translate")*)
		
		this.iSettingsListView := settingsListViewHandle
		
		Gui %window%:Add, Button, xp+310 yp+200 w23 h23 HWNDaddSettingButtonHandle gaddSetting vaddSettingButton
		Gui %window%:Add, Button, xp+25 yp w23 h23 HwnddeleteSettingButtonHandle gdeleteSetting vdeleteSettingButton
		setButtonIcon(addSettingButtonHandle, kIconsDirectory . "Plus.ico", 1)
		setButtonIcon(deleteSettingButtonHandle, kIconsDirectory . "Minus.ico", 1)
		
		/*
		Gui %window%:Add, Button, x281 yp+165 w23 h23 HwndaddSettingsButtonHandle gaddSettings vaddSettingsButton
		Gui %window%:Add, Button, x306 yp w23 h23 HwndeditSettingsButtonHandle geditSettings veditSettingsButton
		Gui %window%:Add, Button, x331 yp w23 h23 HwndduplicateSettingsButtonHandle VduplicateSettingsButton gduplicateSettings
		Gui %window%:Add, Button, x356 yp w23 h23 HwnddeleteSettingsButtonHandle VdeleteSettingsButton gdeleteSettings
		setButtonIcon(addSettingsButtonHandle, kIconsDirectory . "Plus.ico", 1)
		setButtonIcon(editSettingsButtonHandle, kIconsDirectory . "Pencil.ico", 1)
		setButtonIcon(duplicateSettingsButtonHandle, kIconsDirectory . "Copy.ico", 1)
		setButtonIcon(deleteSettingsButtonHandle, kIconsDirectory . "Minus.ico", 1)
		*/
		
		Gui Tab, 2

		Gui %window%:Add, Text, x296 ys w80 h23 +0x200, % translate("Purpose")
		Gui %window%:Add, DropDownList, xp+90 yp w270 AltSubmit Choose2 vsetupTypeDropDown gchooseSetupType, % values2String("|", map(["Qualification (Dry)", "Race (Dry)", "Qualification (Wet)", "Race (Wet)"], "translate")*)
		
		Gui %window%:Add, ListView, x296 yp+24 w360 h198 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistViewHandle gchooseSetup, % values2String("|", map(["Source", "Name"], "translate")*)
		
		this.iSetupListView := listViewHandle
		this.iSelectedSetupType := kDryRaceSetup
		
		Gui %window%:Add, Button, xp+285 yp+200 w23 h23 HwnduploadSetupButtonHandle guploadSetup vuploadSetupButton
		Gui %window%:Add, Button, xp+25 yp w23 h23 HwnddownloadSetupButtonHandle gdownloadSetup vdownloadSetupButton
		Gui %window%:Add, Button, xp+25 yp w23 h23 HwnddeleteSetupButtonHandle gdeleteSetup vdeleteSetupButton
		setButtonIcon(uploadSetupButtonHandle, kIconsDirectory . "Upload.ico", 1)
		setButtonIcon(downloadSetupButtonHandle, kIconsDirectory . "Download.ico", 1)
		setButtonIcon(deleteSetupButtonHandle, kIconsDirectory . "Minus.ico", 1)
		
		Gui Tab, 3
		
		Gui %window%:Add, Text, x296 ys w85 h23 +0x200, % translate("Compound")
		
		compound := this.iTyreCompound
		
		if (this.iTyreCompoundColor != "Black")
			compound := (compound . " (" . this.iTyreCompoundColor . ")")
		
		choices := map(kQualifiedTyreCompounds, "translate")
		chosen := inList(kQualifiedTyreCompounds, compound)
		if (!chosen && (choices.Length() > 0)) {
			compound := choices[1]
			chosen := 1
		}
		
		Gui %window%:Add, DropDownList, x386 yp w100 AltSubmit Choose%chosen%  gloadPressures vtyreCompoundDropDown, % values2String("|", choices*)
		
		Gui %window%:Add, Edit, x494 yp w40 -Background gloadPressures vairTemperatureEdit
		Gui %window%:Add, UpDown, xp+32 yp-2 w18 h20, % this.iAirTemperature
		Gui %window%:Add, Text, xp+42 yp+2 w120 h23 +0x200, % translate("Temp. Air (Celsius)")
		
		Gui %window%:Add, Edit, x494 yp+24 w40 -Background gloadPressures vtrackTemperatureEdit
		Gui %window%:Add, UpDown, xp+32 yp-2 w18 h20, % this.iTrackTemperature
		Gui %window%:Add, Text, xp+42 yp+2 w120 h23 +0x200, % translate("Temp. Track (Celsius)")

		Gui %window%:Font, Norm, Arial
		Gui %window%:Font, Bold Italic, Arial

		Gui %window%:Add, Text, x342 yp+30 w267 0x10
		Gui %window%:Add, Text, x296 yp+10 w370 h20 Center BackgroundTrans, % translate("Pressures (PSI)")

		Gui %window%:Font, Norm, Arial
		
		Gui %window%:Add, Text, x296 yp+30 w85 h23 +0x200, % translate("Front Left")
		Gui %window%:Add, Edit, xp+90 yp w50 Disabled Center vflPressure1, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vflPressure2, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Center +Background vflPressure3, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vflPressure4, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vflPressure5, 0.0
		
		Gui %window%:Add, Text, x296 yp+30 w85 h23 +0x200, % translate("Front Right")
		Gui %window%:Add, Edit, xp+90 yp w50 Disabled Center vfrPressure1, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vfrPressure2, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Center +Background vfrPressure3, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vfrPressure4, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vfrPressure5, 0.0
		
		Gui %window%:Add, Text, x296 yp+30 w85 h23 +0x200, % translate("Rear Left")
		Gui %window%:Add, Edit, xp+90 yp w50 Disabled Center vrlPressure1, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vrlPressure2, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Center +Background vrlPressure3, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vrlPressure4, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vrlPressure5, 0.0
		
		Gui %window%:Add, Text, x296 yp+30 w85 h23 +0x200, % translate("Rear Right")
		Gui %window%:Add, Edit, xp+90 yp w50 Disabled Center vrrPressure1, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vrrPressure2, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Center +Background vrrPressure3, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vrrPressure4, 0.0
		Gui %window%:Add, Edit, xp+54 yp w50 Disabled Center vrrPressure5, 0.0
		
		if vRequestorPID
			Gui %window%:Add, Button, x440 yp+50 w80 h23 gtransferPressures vtransferPressuresButton, % translate("Load")

		Gui Tab

		Gui %window%:Add, Text, x16 ys+126 w120 h23 +0x200, % translate("Available Data")
		
		Gui %window%:Add, ListView, x16 ys+150 w244 h198 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistViewHandle gnoSelect, % values2String("|", map(["Source", "Type", "#"], "translate")*)
		
		this.iDataListView := listViewHandle
		
		Gui %window%:Add, Text, x8 y596 w670 0x10
		
		Gui %window%:Add, Button, x304 y604 w80 h23 GcloseSessionDatabaseEditor, % translate("Close")
		
		this.loadSimulator(simulator, true)
		this.loadCar(car, true)
		this.loadTrack(track, true)
		this.loadWeather(weather, true)
		
		GuiControl Choose, settingsTab, 0
		
		this.updateState()
		
		this.selectModule("Settings")
	}
	
	show() {
		window := this.Window
			
		Gui %window%:Show
	}
	
	getSimulators() {
		return this.SessionDatabase.getSimulators()
	}
	
	getCars(simulator) {
		return this.SessionDatabase.getCars(simulator)
	}
	
	getTracks(simulator, car) {
		return this.SessionDatabase.getTracks(simulator, car)
	}
	
	getCarName(simulator, car) {
		return this.SessionDatabase.getCarName(simulator, car)
	}
	
	loadSimulator(simulator, force := false) {
		if (force || (simulator != this.SelectedSimulator)) {
			window := this.Window
		
			Gui %window%:Default
			
			this.iSelectedSimulator := simulator
			
			GuiControl Choose, simulatorDropDown, % inList(this.getSimulators(), simulator)
			
			choices := this.getCars(simulator)
			
			for index, car in choices
				choices[index] := this.getCarName(simulator, car)
			
			choices.InsertAt(1, translate("All"))
			
			GuiControl, , carDropDown, % "|" . values2String("|", choices*)
			
			this.loadCar(true, true)
		}
	}
	
	loadCar(car, force := false) {
		if (force || (car != this.SelectedCar)) {
			this.iSelectedCar := car
			
			window := this.Window
		
			Gui %window%:Default
			
			if (car == true)
				GuiControl Choose, carDropDown, 1
			else
				GuiControl Choose, carDropDown, % inList(this.getCars(this.SelectedSimulator), car) + 1
			
			if (car && (car != true)) {
				choices := this.getTracks(this.SelectedSimulator, car)
				choices.InsertAt(1, translate("All"))
			
				GuiControl, , trackDropDown, % "|" . values2String("|", choices*)
				
				this.loadTrack(true, true)
			}
			else
				this.updateModules()
		}
	}
	
	loadTrack(track, force := false) {
		if (force || (track != this.SelectedTrack)) {
			this.iSelectedTrack := track
			
			window := this.Window
		
			Gui %window%:Default
			
			if (track == true)
				GuiControl Choose, trackDropDown, 1
			else
				GuiControl Choose, trackDropDown, % inList(this.getTracks(this.SelectedSimulator, this.SelectedCar), track) + 1
		
			this.updateModules()
		}
	}
	
	loadWeather(weather, force := false) {
		if (force || (weather != this.SelectedWeather)) {
			this.iSelectedWeather := weather
			
			window := this.Window
		
			Gui %window%:Default
			
			if (weather == true)
				GuiControl Choose, weatherDropDown, 1
			else
				GuiControl Choose, weatherDropDown, % inList(kWeatherOptions, weather) + 1
		
			this.updateModules()
		}
	}
	
	loadSetups(setupType, force := false) {
		if (force || (setupType != this.SelectedSetupType)) {
			window := this.Window
		
			Gui %window%:Default
			
			Gui ListView, % this.SetupListView
			
			LV_Delete()

			this.SelectedSetupType := setupType
			
			GuiControl Choose, setupTypeDropDown, % inList(kSetupTypes, setupType)

			userSetups := true
			communitySetups := true
			
			this.SessionDatabase.getSetupNames(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, userSetups, communitySetups)
			
			for type, setups in userSetups
				if (type = setupType)
					for ignore, name in setups
						LV_Add("", translate("Local"), name)
			
			for type, setups in communitySetups
				if (type = setupType)
					for ignore, name in setups
						LV_Add("", translate("Community"), name)
			
			LV_ModifyCol()
			
			Loop 2
				LV_ModifyCol(A_Index, "AutoHdr")
		
			this.updateState()
		}
	}
	
	loadSettings() {
		window := this.Window
	
		Gui %window%:Default
		
		Gui ListView, % this.SettingsListView
		
		LV_Delete()
		
		userSettings := true
		communitySettings := false
		
		new SettingsDatabase().querySettings(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, this.SelectedWeather
										   , userSettings, communitySettings)
		
		for type, setting in userSettings
			LV_Add("", translate("Local"), name)
		
		LV_ModifyCol()
		
		Loop 3
			LV_ModifyCol(A_Index, "AutoHdr")
	
		this.updateState()
	}
	
	selectSettings() {
		Gui ListView, % this.DataListView
			
		LV_Delete()
		
		while LV_DeleteCol(1)
			ignore := 1
		
		this.loadSettings()
	}
	
	selectSetups() {
		Gui ListView, % this.DataListView
			
		LV_Delete()
		
		while LV_DeleteCol(1)
			ignore := 1
		
		for ignore, column in map(["Source", "Type", "#"], "translate")
			LV_InsertCol(A_Index, "", column)
		
		userSetups := true
		communitySetups := true
		
		this.SessionDatabase.getSetupNames(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, userSetups, communitySetups)
		
		for type, setups in userSetups
			LV_Add("", translate("Local"), translate(kSetupNames[type]), setups.Length())
		
		for type, setups in communitySetups
			LV_Add("", translate("Community"), translate(kSetupNames[type]), setups.Length())
	
		LV_ModifyCol()
		
		Loop 3
			LV_ModifyCol(A_Index, "AutoHdr")
		
		this.loadSetups(this.SelectedSetupType, true)
	}
	
	selectPressures() {
		Gui ListView, % this.DataListView
			
		LV_Delete()
		
		while LV_DeleteCol(1)
			ignore := 1
		
		for ignore, column in map(["Source", "Weather", "T Air", "T Track", "Compound", "#"], "translate")
			LV_InsertCol(A_Index, "", column)
			
		for ignore, info in new TyresDatabase().getPressureInfo(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, this.SelectedWeather)
			LV_Add("", translate((info.Source = "User") ? "Local" : "Community"), translate(info.Weather), info.AirTemperature, info.TrackTemperature
					 , translate(info.Compound), info.Count)
	
		LV_ModifyCol()
		
		Loop 6
			LV_ModifyCol(A_Index, "AutoHdr")
		
		this.loadPressures()
	}
	
	moduleAvailable(module) {
		return this.iAvailableModules[module]
	}
	
	selectModule(module, force := false) {
		if this.moduleAvailable(module) {
			if (force || (this.SelectedModule != module)) {
				this.iSelectedModule := module
				
				switch module {
					case "Settings":
						this.selectSettings()
					case "Setups":
						this.selectSetups()
					case "Pressures":
						this.selectPressures()
				}
				
				this.updateState()
			}
		}
	}
	
	updateModules() {
		window := this.Window
		
		Gui %window%:Default
		Gui %window%:Color, D0D0D0, D8D8D8
		
		GuiControl, , notesEdit, % this.SessionDatabase.readNotes(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack)
		
		this.selectModule(this.SelectedModule, true)
	}
	
	updateNotes(notes) {
		this.SessionDatabase.writeNotes(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, notes)
	}
	
	updateState() {
		window := this.Window
	
		Gui %window%:Default
		
		simulator := this.SelectedSimulator
		car := this.SelectedCar
		track := this.SelectedTrack
		
		if simulator {
			this.iAvailableModules["Settings"] := true
			
			if ((car && (car != true)) && (track && (track != true))) {
				this.iAvailableModules["Setups"] := true
				this.iAvailableModules["Pressures"] := true
			}
			else {
				this.iAvailableModules["Setups"] := false
				this.iAvailableModules["Pressures"] := false
				
				if ((this.SelectedModule = "Setups") || (this.SelectedModule = "Pressures"))
					this.selectModule("Settings")
			}
		}
		else {
			this.iAvailableModules["Settings"] := false
			this.iAvailableModules["Setups"] := false
			this.iAvailableModules["Pressures"] := false
			
			GuiControl Choose, settingsTab, 0
		}
		
		if this.moduleAvailable("Settings")
			Gui Font, s10 Bold cGray, Arial
		else
			Gui Font, s10 Bold cSilver, Arial
		
		GuiControl Font, settingsTab1
		
		if this.moduleAvailable("Setups")
			Gui Font, s10 Bold cGray, Arial
		else
			Gui Font, s10 Bold cSilver, Arial
		
		GuiControl Font, settingsTab2
		
		if this.moduleAvailable("Pressures")
			Gui Font, s10 Bold cGray, Arial
		else
			Gui Font, s10 Bold cSilver, Arial
		
		GuiControl Font, settingsTab3
		
		Gui Font, s10 Bold cBlack, Arial
		
		switch this.SelectedModule {
			case "Settings":
				GuiControl Font, settingsTab1
				GuiControl Choose, settingsTab, 1
			case "Setups":
				GuiControl Font, settingsTab2
				GuiControl Choose, settingsTab, 2
			case "Pressures":
				GuiControl Font, settingsTab3
				GuiControl Choose, settingsTab, 3
		}
		
		Gui ListView, % this.SetupListView
		
		selected := LV_GetNext(0)
		
		if selected {
			GuiControl Enable, downloadSetupButton
			GuiControl Enable, deleteSetupButton
		}
		else {
			GuiControl Disable, downloadSetupButton
			GuiControl Disable, deleteSetupButton
		}
		
		if this.SelectedSettingGroup {
			GuiControl Enable, deleteSettingGroupButton
			GuiControl Enable, addSettingButton
		}
		else {
			GuiControl Disable, deleteSettingGroupButton
			GuiControl Disable, addSettingButton
		}
		
		Gui ListView, % this.SettingGroupListView
		
		selected := LV_GetNext(0)
		
		if selected
			GuiControl Enable, deleteSettingButton
		else
			GuiControl Disable, deleteSettingButton
	}

	loadPressures() {
		tyresDB := new TyresDatabase()
		
		window := this.Window
		
		Gui %window%:Default
			
		Gui ListView, % this.DataListView
			
		static lastColor := "D0D0D0"

		try {
			GuiControlGet airTemperatureEdit
			GuiControlGet trackTemperatureEdit
			GuiControlGet tyreCompoundDropDown

			compound := string2Values(A_Space, kQualifiedTyreCompounds[tyreCompoundDropDown])
			
			if (compound.Length() == 1)
				compoundColor := "Black"
			else
				compoundColor := SubStr(compound[2], 2, StrLen(compound[2]) - 2)
			
			pressureInfos := tyresDB.getPressures(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, this.SelectedWeather
												, airTemperatureEdit, trackTemperatureEdit, compound[1], compoundColor)

			if (pressureInfos.Count() == 0) {
				for ignore, tyre in ["fl", "fr", "rl", "rr"]
					for ignore, postfix in ["1", "2", "3", "4", "5"] {
						GuiControl Text, %tyre%Pressure%postfix%, 0.0
						GuiControl +Background, %tyre%Pressure%postfix%
						GuiControl Disable, %tyre%Pressure%postfix%
					}

				if vRequestorPID
					GuiControl Disable, transferPressuresButton
			}
			else {
				for tyre, pressureInfo in pressureInfos {
					pressure := pressureInfo["Pressure"]
					trackDelta := pressureInfo["Delta Track"]
					airDelta := pressureInfo["Delta Air"] + Round(trackDelta * 0.49)
					
					pressure -= 0.2
					
					if ((airDelta == 0) && (trackDelta == 0))
						color := "Green"
					else if (airDelta == 0)
						color := "Lime"
					else
						color := "Yellow"
					
					if (true || (color != lastColor)) {
						lastColor := color
						
						Gui %window%:Color, D0D0D0, %color%
					}
					
					for index, postfix in ["1", "2", "3", "4", "5"] {
						pressure := Format("{:.1f}", pressure)
					
						GuiControl Text, %tyre%Pressure%postfix%, %pressure%
						
						if (index = (3 + airDelta)) {
							GuiControl +Background, %tyre%Pressure%postfix%
							GuiControl Enable, %tyre%Pressure%postfix%
						}
						else {
							GuiControl -Background, %tyre%Pressure%postfix%
							GuiControl Disable, %tyre%Pressure%postfix%
						}
					
						pressure += 0.1
					}
				
					if vRequestorPID
						GuiControl Enable, transferPressuresButton
				}
			}
		}
		catch exception {
			; ignore
		}
	}

	uploadSetup(setupType) {
		window := this.Window
		
		Gui %window%:Default
			
		GuiControlGet simulatorDropDown
		GuiControlGet carDropDown
		GuiControlGet trackDropDown

		title := translate("Upload Setup File...")
					
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Load", "Cancel"]))
		FileSelectFile fileName, 1, , %title%
		OnMessage(0x44, "")

		if (fileName != "") {
			oldEncoding := A_FileEncoding
			
			try {
				FileEncoding
				
				FileRead setup, %fileName%
			}
			finally {
				FileEncoding %oldEncoding%
			}
			
			SplitPath fileName, fileName
			
			this.SessionDatabase.writeSetup(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, setupType, fileName, setup)
		
			this.loadSetups(this.SelectedSetupType, true)
		}
	}

	downloadSetup(setupType, setupName) {
		window := this.Window
		
		Gui %window%:Default
			
		GuiControlGet simulatorDropDown
		GuiControlGet carDropDown
		GuiControlGet trackDropDown

		title := translate("Download Setup File...")
					
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Save", "Cancel"]))
		FileSelectFile fileName, S16, %setupName%, %title%
		OnMessage(0x44, "")
		
		if (fileName != "") {
			setupData := this.SessionDatabase.readSetup(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, setupType, setupName)
			
			try {
				FileDelete %fileName%
			}
			catch exception {
				; ignore
			}
			
			FileAppend %setupData%, %fileName%
		}
	}

	deleteSetup(setupType, setupName) {
		window := this.Window
		
		Gui %window%:Default
			
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
		title := translate("Delete")
		MsgBox 262436, %title%, % translate("Do you really want to delete the selected setup?")
		OnMessage(0x44, "")
		
		IfMsgBox Yes
		{
			GuiControlGet simulatorDropDown
			GuiControlGet carDropDown
			GuiControlGet trackDropDown
			
			this.SessionDatabase.removeSetup(this.SelectedSimulator, this.SelectedCar, this.SelectedTrack, setupType, setupName)
			
			this.loadSetups(this.SelectedSetupType, true)
		}
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Variable Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;
/*


global settingsListView
global settingsListViewHandle
global addSettingsButton
global editSettingsButton
global duplicateSettingsButton
global deleteSettingsButton
		
global notesEdit

global transferPressuresButton
global queryScopeDropDown

*/


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

/*



getSettings(index := false) {
	Gui ListView, % settingsListViewHandle
	
	if !index
		index := LV_GetNext()
	
	if index {
		if (index <= vLocalSettings.Length())
			return vLocalSettings[index]
		else
			return vGlobalSettings[index - vLocalSettings.Length()]
	}
	else
		return false
}

getIndex(settings) {
	index := inList(vLocalSettings, settings)
	
	if index
		return index
	else {
		index := inList(vGlobalSettings, settings)
	
		if index
			return (index + vLocalSettings.Length())
		else
			return false
	}
}

loadSettings(settings := false) {
	Gui %window%:Default
	Gui ListView, % settingsListViewHandle
	
	GuiControlGet simulatorDropDown
	GuiControlGet carDropDown
	GuiControlGet trackDropDown
		
	if ((simulatorDropDown = "") || (carDropDown = "") || (trackDropDown = "")) {
		GuiControl Disable, addSettingsButton
		GuiControl Disable, editSettingsButton
		GuiControl Disable, duplicateSettingsButton
		GuiControl Disable, deleteSettingsButton
		
		GuiControl +Disabled, settingsListView
		
		LV_Delete()
	}
	else {
		GuiControl Enable, addSettingsButton
		
		if !settings
			settings := getSettings()
	
		vSettingsDatabase.getSettingsNames(simulatorDropDown, vSettingsDatabase.getCars(simulatorDropDown)[carDropDown], trackDropDown, vLocalSettings, vGlobalSettings)
		
		LV_Delete()
		
		for ignore, name in vLocalSettings {
			LV_Add("", name)
		}
		
		for ignore, name in vGlobalSettings {
			LV_Add("", name)
		}
		
		if settings {
			index := getIndex(settings)
			
			if index {
				LV_Modify(index, "+Focus +Select Vis")
				
				GuiControl Enable, duplicateSettingsButton
				
				if (index <= vLocalSettings.Length()) {
					GuiControl Enable, editSettingsButton
					GuiControl Enable, deleteSettingsButton
				}
				else {
					GuiControl Disable, editSettingsButton
					GuiControl Disable, deleteSettingsButton
				}
			}
			else {
				GuiControl Disable, editSettingsButton
				GuiControl Disable, duplicateSettingsButton
				GuiControl Disable, deleteSettingsButton
			}
		}
		else {
			GuiControl Disable, editSettingsButton
			GuiControl Disable, duplicateSettingsButton
			GuiControl Disable, deleteSettingsButton
		}
		
		GuiControl -Disabled, settingsListView
	}
}



openSettings(mode := "New", arguments*) {
	exePath := kBinariesDirectory . "Race Settings.exe"
	fileName := kTempDirectory . "Temp.settings"
				
	Gui %window%:Hide
				
	try {
		switch mode {
			case "New":
				try {
					FileDelete %fileName%
				}
				catch exception {
					; ignore
				}
			case "Edit":
				writeConfiguration(fileName, arguments[1])
		}
				
		options := "-NoTeam -File """ . fileName . """"
		
		RunWait "%exePath%" %options%, %kBinariesDirectory%, , pid
			
		if ErrorLevel
			return readConfiguration(fileName)
		else
			return false
	}
	catch exception {
		logMessage(kLogCritical, translate("Cannot start the Race Settings tool (") . exePath . translate(") - please rebuild the applications in the binaries folder (") . kBinariesDirectory . translate(")"))
			
		showMessage(substituteVariables(translate("Cannot start the Race Settings tool (%exePath%) - please check the configuration..."), {exePath: exePath})
				  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		
		return false
	}
	finally {
		Gui %window%:Show
	}
}

openSettingsEditor(asynchronous := true) {
	if !asynchronous
		SendEvent {F2}
	else {
		callback := Func("openSettingsEditor").Bind(false)
	
		SetTimer %callback%, -500
	}
}

settingsListViewEvent() {
	GuiControlGet simulatorDropDown
	GuiControlGet carDropDown
	GuiControlGet trackDropDown
	
	if (A_GuiEvent = "e") {
		oldName := getSettings(A_EventInfo)
		
		LV_GetText(newName, A_EventInfo)
		
		vSettingsDatabase.renameSettings(simulatorDropDown, vSettingsDatabase.getCars(simulatorDropDown)[carDropDown]
									   , trackDropDown, oldName, newName)
	}
	else {
		index := LV_GetNext()
		
		if index {
			GuiControl Enable, duplicateSettingsButton
			
			if (index <= vLocalSettings.Length()) {
				GuiControl Enable, editSettingsButton
				GuiControl Enable, deleteSettingsButton
			}
			else {
				GuiControl Disable, editSettingsButton
				GuiControl Disable, deleteSettingsButton
			}
			
			if (A_GuiEvent = "DoubleClick")
				openSettingsEditor()
		}
		else {
			GuiControl Disable, editSettingsButton
			GuiControl Disable, duplicateSettingsButton
			GuiControl Disable, deleteSettingsButton
		}
	}
}

addSettings() {
	GuiControlGet simulatorDropDown
	GuiControlGet carDropDown
	GuiControlGet trackDropDown
	
	settings := openSettings("New")
	
	if settings {
		settingsName := translate("New")
		
		vSettingsDatabase.writeSettings(simulatorDropDown, vSettingsDatabase.getCars(simulatorDropDown)[carDropDown]
									  , trackDropDown, settingsName, settings)
	
		loadSettings(settingsName)
		
		openSettingsEditor()
	}
}

editSettings() {
	GuiControlGet simulatorDropDown
	GuiControlGet carDropDown
	GuiControlGet trackDropDown
	
	settingsName := getSettings()
	
	settings := openSettings("Edit", vSettingsDatabase.readSettings(simulatorDropDown, carDropDown, trackDropDown, settingsName))
	
	if settings
		vSettingsDatabase.writeSettings(simulatorDropDown, vSettingsDatabase.getCars(simulatorDropDown)[carDropDown]
									  , trackDropDown, settingsName, settings)
}

duplicateSettings() {
	GuiControlGet simulatorDropDown
	GuiControlGet carDropDown
	GuiControlGet trackDropDown
	
	settingsName := getSettings()
	
	selectedCar := vSettingsDatabase.getCars(simulatorDropDown)[carDropDown]
	
	settings := openSettings("Edit", vSettingsDatabase.readSettings(simulatorDropDown, selectedCar, trackDropDown, settingsName))
	
	if settings {
		settingsName := (settingsName . translate(" Copy"))
		
		vSettingsDatabase.writeSettings(simulatorDropDown, selectedCar, trackDropDown, settingsName, settings)
	
		loadSettings(settingsName)
		
		openSettingsEditor()
	}
}

deleteSettings() {
	OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
	title := translate("Delete")
	MsgBox 262436, %title%, % translate("Do you really want to delete the selected settings?")
	OnMessage(0x44, "")
	
	IfMsgBox Yes
	{
		GuiControlGet simulatorDropDown
		GuiControlGet carDropDown
		GuiControlGet trackDropDown
		
		settingsName := getSettings()
		
		vSettingsDatabase.deleteSettings(simulatorDropDown, vSettingsDatabase.getCars(simulatorDropDown)[carDropDown]
									   , trackDropDown, settingsName)
		
		loadSettings()
	}
}

updateQueryScope() {
	Gui %window%:Default
			
	GuiControlGet queryScopeDropDown
	
	vSettingsDatabase.UseCommunity := (queryScopeDropDown == 2)
	vTyresDatabase.UseCommunity := (queryScopeDropDown == 2)
	
	chooseSimulator()
}

*/


setButtonIcon(buttonHandle, file, index := 1, options := "") {
;   Parameters:
;   1) {Handle} 	HWND handle of Gui button
;   2) {File} 		File containing icon image
;   3) {Index} 		Index of icon in file
;						Optional: Default = 1
;   4) {Options}	Single letter flag followed by a number with multiple options delimited by a space
;						W = Width of Icon (default = 16)
;						H = Height of Icon (default = 16)
;						S = Size of Icon, Makes Width and Height both equal to Size
;						L = Left Margin
;						T = Top Margin
;						R = Right Margin
;						B = Botton Margin
;						A = Alignment (0 = left, 1 = right, 2 = top, 3 = bottom, 4 = center; default = 4)

	RegExMatch(options, "i)w\K\d+", W), (W="") ? W := 16 :
	RegExMatch(options, "i)h\K\d+", H), (H="") ? H := 16 :
	RegExMatch(options, "i)s\K\d+", S), S ? W := H := S :
	RegExMatch(options, "i)l\K\d+", L), (L="") ? L := 0 :
	RegExMatch(options, "i)t\K\d+", T), (T="") ? T := 0 :
	RegExMatch(options, "i)r\K\d+", R), (R="") ? R := 0 :
	RegExMatch(options, "i)b\K\d+", B), (B="") ? B := 0 :
	RegExMatch(options, "i)a\K\d+", A), (A="") ? A := 4 :

	ptrSize := A_PtrSize = "" ? 4 : A_PtrSize, DW := "UInt", Ptr := A_PtrSize = "" ? DW : "Ptr"

	VarSetCapacity(button_il, 20 + ptrSize, 0)

	NumPut(normal_il := DllCall("ImageList_Create", DW, W, DW, H, DW, 0x21, DW, 1, DW, 1), button_il, 0, Ptr)	; Width & Height
	NumPut(L, button_il, 0 + ptrSize, DW)		; Left Margin
	NumPut(T, button_il, 4 + ptrSize, DW)		; Top Margin
	NumPut(R, button_il, 8 + ptrSize, DW)		; Right Margin
	NumPut(B, button_il, 12 + ptrSize, DW)		; Bottom Margin	
	NumPut(A, button_il, 16 + ptrSize, DW)		; Alignment

	SendMessage, BCM_SETIMAGELIST := 5634, 0, &button_il,, AHK_ID %buttonHandle%

	return IL_Add(normal_il, file, index)
}

moveSessionDatabaseEditor() {
	moveByMouse("SDE")
}

closeSessionDatabaseEditor() {
	ExitApp 0
}

openSessionDatabaseEditorDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Engineer#session-database
}

chooseSimulator() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet simulatorDropDown
	
	editor.loadSimulator(simulatorDropDown)
}

chooseCar() {
	editor := SessionDatabaseEditor.Instance
	simulator := editor.SelectedSimulator
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet carDropDown
	
	if (carDropDown = translate("All"))
		editor.loadCar(true)
	else
		for index, car in editor.getCars(simulator)
			if (carDropDown = editor.getCarName(simulator, car)) {
				editor.loadCar(car)
				
				break
			}
}

chooseTrack() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet trackDropDown
	
	editor.loadTrack((trackDropDown = translate("All")) ? true : trackDropDown)
}

chooseWeather() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet weatherDropDown
	
	editor.loadWeather((weatherDropDown == 1) ? true : kWeatherOptions[weatherDropDown - 1])
}

updateNotes() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet notesEdit
	
	editor.updateNotes(notesEdit)
}

chooseSettingGroup() {
}

addSettingGroup() {
	title := translate("Modular Simulator Controller System")
	prompt := translate("Please enter the name of the setting group:")
	
	editor := SessionDatabaseEditor.Instance
	
	window := editor.Window

	Gui %window%:Default
	
	locale := ((getLanguage() = "en") ? "" : "Locale")
	
	InputBox name, %title%, %prompt%, , 300, 150, , , %locale%
	
	if !ErrorLevel
		editor.addSetting(name)
}

deleteSettingGroup() {
}

chooseSetting() {
}

addSetting() {
}

deleteSetting() {
}

chooseSetupType() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet setupTypeDropDown
	
	SessionDatabaseEditor.Instance.loadSetups(kSetupTypes[setupTypeDropDown])
}

chooseSetup() {
	SessionDatabaseEditor.Instance.updateState()
}

uploadSetup() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet setupTypeDropDown
	
	SessionDatabaseEditor.Instance.uploadSetup(kSetupTypes[setupTypeDropDown])
}

downloadSetup() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet setupTypeDropDown
	
	Gui ListView, % editor.SetupListView
	
	LV_GetText(name, LV_GetNext(0), 2)
	
	SessionDatabaseEditor.Instance.downloadSetup(kSetupTypes[setupTypeDropDown], name)
}

deleteSetup() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	GuiControlGet setupTypeDropDown
	
	Gui ListView, % editor.SetupListView
	
	LV_GetText(name, LV_GetNext(0), 2)
	
	SessionDatabaseEditor.Instance.deleteSetup(kSetupTypes[setupTypeDropDown], name)
}

loadPressures() {
	SessionDatabaseEditor.Instance.loadPressures()
}

noSelect() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
	
	Gui ListView, % editor.DataListView
	
	LV_Modify(A_EventInfo, "-Select")
}

chooseTab1() {
	editor := SessionDatabaseEditor.Instance

	if editor.moduleAvailable("Settings")
		editor.selectModule("Settings")
}

chooseTab2() {
	editor := SessionDatabaseEditor.Instance
	
	if editor.moduleAvailable("Setups")
		editor.selectModule("Setups")
}

chooseTab3() {
	editor := SessionDatabaseEditor.Instance
	
	if editor.moduleAvailable("Pressures")
		editor.selectModule("Pressures")
}

transferPressures() {
	editor := SessionDatabaseEditor.Instance
	window := editor.Window
	
	Gui %window%:Default
			
	GuiControlGet airTemperatureEdit
	GuiControlGet trackTemperatureEdit
	GuiControlGet tyreCompoundDropDown
	
	tyrePressures := []
	compound := string2Values(A_Space, kQualifiedTyreCompounds[tyreCompoundDropDown])
	
	if (compound.Length() == 1)
		compoundColor := "Black"
	else
		compoundColor := SubStr(compound[2], 2, StrLen(compound[2]) - 2)
	
	compound := compound[1]
	
	for ignore, pressureInfo in new TyresDatabase().getPressures(editor.SelectedSimulator, editor.SelectedCar, editor.SelectedTrack, editor.SelectedWeather
															   , airTemperatureEdit, trackTemperatureEdit, compound, compoundColor)
		tyrePressures.Push(pressureInfo["Pressure"] + ((pressureInfo["Delta Air"] + Round(pressureInfo["Delta Track"] * 0.49)) * 0.1))
	
	raiseEvent(kFileMessage, "Setup", "setTyrePressures:" . values2String(";", compound, compoundColor, tyrePressures*), vRequestorPID)
}

showSessionDatabaseEditor() {
	icon := kIconsDirectory . "Wrench.ico"
	
	Menu Tray, Icon, %icon%, , 1
	Menu Tray, Tip, Setup Database
	
	simulator := false
	car := false
	track := false
	weather := "Dry"
	airTemperature := 23
	trackTemperature:= 27
	compound := "Dry"
	compoundColor := "Black"
	
	index := 1
	
	while (index < A_Args.Length()) {
		switch A_Args[index] {
			case "-Simulator":
				simulator := A_Args[index + 1]
				index += 2
			case "-Car":
				car := A_Args[index + 1]
				index += 2
			case "-Track":
				track := A_Args[index + 1]
				index += 2
			case "-Weather":
				weather := A_Args[index + 1]
				index += 2
			case "-AirTemperature":
				airTemperature := A_Args[index + 1]
				index += 2
			case "-TrackTemperature":
				trackTemperature := A_Args[index + 1]
				index += 2
			case "-Compound":
				compound := A_Args[index + 1]
				index += 2
			case "-CompoundColor":
				compoundColor := A_Args[index + 1]
				index += 2
			case "-Setup":
				vRequestorPID := A_Args[index + 1]
				index += 2
			default:
				index += 1
		}
	}
	
	if ((airTemperature <= 0) || (trackTemperature <= 0)) {
		airTemperature := false
		trackTemperature := false
	}
	
	editor := new SessionDatabaseEditor(simulator, car, track, weather, airTemperature, trackTemperature, compound, compoundColor)
		
	editor.createGui(editor.Configuration)
	
	editor.show()
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

showSessionDatabaseEditor()