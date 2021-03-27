﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Simulator Configuration Tool    ;;;
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

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Configuration.ico
;@Ahk2Exe-ExeName Simulator Configuration.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Local Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\SpeechGenerator.ahk
#Include ..\Libraries\SpeechRecognizer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kApply = "apply"
global kOk = "ok"
global kCancel = "cancel"

global kEmptySpaceDescriptor = "Button;" . kButtonBoxImagesDirectory . "Empty.png;52 x 52"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vResult = false

global vShowKeyDetector = false
global vKeyDetectorReturnHotkey = false

global vItemLists = Object()


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class ConfigurationItemTab extends ConfigurationItem {
	__New(configuration) {
		base.__New(configuration)
		
		this.createControls(configuration)
	}
	
	createControls(configuration) {
	}
}

class ConfigurationItemList extends ConfigurationItem {
	iListHandle := false
	iAddButton := ""
	iDeleteButton := ""
	iUpdateButton := ""
	iUpButton := false
	iDownButton := false
	
	iItemsList := []
	iCurrentItemIndex := 0
	
	ListHandle[] {
		Get {
			return this.iListHandle
		}
	}
	
	__New(configuration, listHandle, listVariable, addButton := false, deleteButton := false, updateButton := false, upButton := false, downButton := false) {
		this.iListHandle := listHandle
		this.iAddButton := addButton
		this.iDeleteButton := deleteButton
		this.iUpdateButton := updateButton
		this.iUpButton := upButton
		this.iDownButton := downButton
		
		registerList(listVariable, this)
		
		if addButton
			registerList(addButton, this)
		
		if deleteButton
			registerList(deleteButton, this)
		
		if updateButton
			registerList(updateButton, this)
		
		if upButton
			registerList(upButton, this)
		
		if downButton
			registerList(downButton, this)
		
		base.__New(configuration)
		
		this.loadList(this.iItemsList)
		this.updateState()
	}
	
	saveToConfiguration(configuration) {
		if ConfigurationEditor.Instance.AutoSave {
			if (this.iCurrentItemIndex != 0) {
				this.updateItem()
			}
		}
	}
	
	createControls(configuration) {
	}
	
	loadList(items) {
		Throw "Virtual method ConfigurationItemList.loadList must be implemented in a subclass..."
	}
	
	updateState() {
		if (this.iCurrentItemIndex != 0) {
			if (this.iDeleteButton != false)
				GuiControl Enable, % this.iDeleteButton
			if (this.iUpdateButton != false)
				GuiControl Enable, % this.iUpdateButton
			
			if (this.iUpButton != false)
				if (this.iCurrentItemIndex > 1)
					GuiControl Enable, % this.iUpButton
				else
					GuiControl Disable, % this.iUpButton
			
			if (this.iDownButton != false)
				if (this.iCurrentItemIndex < this.iItemsList.Length())
					GuiControl Enable, % this.iDownButton
				else
					GuiControl Disable, % this.iDownButton
		}
		else {
			if (this.iUpButton != false)
				GuiControl Disable, % this.iUpButton
			
			if (this.iDownButton != false)
				GuiControl Disable, % this.iDownButton
			
			if (this.iDeleteButton != false)
				GuiControl Disable, % this.iDeleteButton
			if (this.iUpdateButton != false)
				GuiControl Disable, % this.iUpdateButton
		}
	}
	
	loadEditor(item) {
		Throw "Virtual method ConfigurationItemList.loadEditor must be implemented in a subclass..."
	}
	
	clearEditor() {
		Throw "Virtual method ConfigurationItemList.clearEditor must be implemented in a subclass..."
	}
	
	buildItemFromEditor(isNew := false) {
		Throw "Virtual method ConfigurationItemList.buildItemFromEditor must be implemented in a subclass..."
	}
	
	openEditor(itemNumber) {
		if ConfigurationEditor.Instance.AutoSave {
			if (this.iCurrentItemIndex != 0)
				this.updateItem()
				
			this.selectItem(itemNumber)
		}
		
		this.iCurrentItemIndex := itemNumber
		
		this.loadEditor(this.iItemsList[this.iCurrentItemIndex])
		
		this.updateState()
	}
	
	selectItem(itemNumber) {
		this.iCurrentItemIndex := itemNumber
		
		Gui ListView, % this.ListHandle
			
		if itemNumber
			LV_Modify(itemNumber, "Vis +Select +Focus")
		
		this.updateState()
	}
	
	addItem() {
		item := this.buildItemFromEditor(true)
		
		if item {
			this.iItemsList.Push(item)
		
			this.loadList(this.iItemsList)
			
			this.selectItem(inList(this.iItemsList, item))
		}
	}
	
	deleteItem() {
		this.iItemsList.RemoveAt(this.iCurrentItemIndex)
		
		this.loadList(this.iItemsList)
		
		this.clearEditor()
		
		this.iCurrentItemIndex := 0
		
		this.updateState()
	}

	updateItem() {
		static recurse := false
		
		if recurse
			return
		else {
			recurse := true
		
			try {
				item := this.buildItemFromEditor()
				
				if item {
					this.iItemsList[this.iCurrentItemIndex] := item
					
					this.loadList(this.iItemsList)
					
					this.selectItem(this.iCurrentItemIndex)
				}
			}
			finally {
				recurse := false
			}
		}
	}

	upItem() {
		item := this.iItemsList[this.iCurrentItemIndex]
		
		this.iItemsList[this.iCurrentItemIndex] := this.iItemsList[this.iCurrentItemIndex - 1]
		this.iItemsList[this.iCurrentItemIndex - 1] := item
		
		this.loadList(this.iItemsList)
			
		this.selectItem(this.iCurrentItemIndex - 1)
		
		this.updateState()
	}

	downItem() {
		item := this.iItemsList[this.iCurrentItemIndex]
		
		this.iItemsList[this.iCurrentItemIndex] := this.iItemsList[this.iCurrentItemIndex + 1]
		this.iItemsList[this.iCurrentItemIndex + 1] := item
		
		this.loadList(this.iItemsList)
			
		this.selectItem(this.iCurrentItemIndex + 1)
		
		this.updateState()
	}
}

registerList(listVariable, itemList) {
	vItemLists[listVariable] := itemList
}

listEvent() {
	local event
	
	info := ErrorLevel
	editor := (A_GuiControl . "." . A_EventInfo)
	
	Critical
	
	static lastEvent := false
	static lastEditor := false
	
	event := (A_GuiEvent . " " . A_GuiControl . " " . A_EventInfo)

	if ((event = lastEvent) && (true || !inList(["controlsListView", "labelsListView", "layoutsListView"], A_GuiControl)))
		return
	else
		lastEvent := event
	
	protectionOn()
	
	try {
		if (A_GuiEvent == "DoubleClick") {
			if (editor != lastEditor)
				vItemLists[A_GuiControl].openEditor(A_EventInfo)
		}
		else if (A_GuiEvent == "Normal") {
			if (A_GuiControl == "simulatorsListBox") {
				GuiControlGet simulatorsListBox
				
				vItemLists[A_GuiControl].openEditor(inList(SimulatorsList.Instance.iItemsList, simulatorsListBox))
			}
			else if (A_GuiControl == "buttonBoxesListBox") {
				GuiControlGet buttonBoxesListBox
				
				index := false
				
				for ignore, candidate in ButtonBoxesList.Instance.iItemsList
					if (buttonBoxesListBox = candidate[1]) {
						index := A_Index
					
						break
					}
				
				vItemLists[A_GuiControl].openEditor(index)
			}
			else if (editor != lastEditor)
				vItemLists[A_GuiControl].openEditor(A_EventInfo)
		}
		else if ((A_GuiEvent == "I") && (true || !inList(["controlsListView", "labelsListView", "layoutsListView"], A_GuiControl))) {
			if (InStr(info, "S", true) && (editor != lastEditor))
				vItemLists[A_GuiControl].openEditor(A_EventInfo)
		}
	}
	finally {
		protectionOff()
	}
	
	lastEditor := editor
}

addItem() {
	protectionOn()
	
	try{
		vItemLists[A_GuiControl].addItem()
	}
	finally {
		protectionOff()
	}
}

deleteItem() {
	protectionOn()
	
	try{
		vItemLists[A_GuiControl].deleteItem()
	}
	finally {
		protectionOff()
	}
}

updateItem() {
	protectionOn()
	
	try{
		vItemLists[A_GuiControl].updateItem()
	}
	finally {
		protectionOff()
	}
}

upItem() {
	protectionOn()
	
	try{
		vItemLists[A_GuiControl].upItem()
	}
	finally {
		protectionOff()
	}
}

downItem() {
	protectionOn()
	
	try{
		vItemLists[A_GuiControl].downItem()
	}
	finally {
		protectionOff()
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ConfigurationEditor                                                     ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global saveModeDropDown

class ConfigurationEditor extends ConfigurationItem {
	iGeneralTab := false
	iVoiceControlTab := false
	iPluginsTab := false
	iApplicationsTab := false
	iControllerTab := false
	iLaunchpadTab := false
	iChatMessagesTab := false
	
	iDevelopment := false
	iSaveMode := false
	
	AutoSave[] {
		Get {
			return (this.iSaveMode = "Auto")
		}
	}
	
	__New(development, configuration) {
		this.iDevelopment := development
		
		base.__New(configuration)
		
		ConfigurationEditor.Instance := this
		
		this.createControls(configuration)
	}
	
	createControls(configuration) {
		Gui SE:Default
	
		Gui SE:-Border ; -Caption
		Gui SE:Color, D0D0D0

		Gui SE:Font, Bold, Arial

		Gui SE:Add, Text, w478 Center gmoveConfigurationEditor, % translate("Modular Simulator Controller System") 
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic Underline, Arial

		Gui SE:Add, Text, YP+20 w478 cBlue Center gopenConfigurationDocumentation, % translate("Configuration")

		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Button, x232 y528 w80 h23 Default gsaveAndExit, % translate("Save")
		Gui SE:Add, Button, x320 y528 w80 h23 gcancelAndExit, % translate("&Cancel")
		Gui SE:Add, Button, x408 y528 w77 h23 gsaveAndStay, % translate("&Apply")
		
		choices := ["Auto", "Manual"]
		chosen := inList(choices, saveModeDropDown)
		
		Gui SE:Add, Text, x8 y528 w55 h23 +0x200, % translate("Save")
		Gui SE:Add, DropDownList, x63 y528 w75 AltSubmit Choose%chosen% gupdateSaveMode VsaveModeDropDown, % values2String("|", map(choices, "translate")*)

		tabs := map(["General", "Voice Control", "Plugins", "Applications", "Controller", "Launchpad", "Chat"], "translate")
			   
		Gui SE:Add, Tab3, x8 y48 w478 h472 -Wrap, % values2String("|", tabs*)
		
		tab := 1
		
		Gui SE:Tab, % tab++
		
		this.iGeneralTab := new GeneralTab(this.iDevelopment, configuration)
		
		Gui SE:Tab, % tab++
		
		this.iVoiceControlTab := new VoiceControlTab(configuration)
		
		Gui SE:Tab, % tab++
		
		this.iPluginsTab := new PluginsTab(configuration)
		
		Gui SE:Tab, % tab++
		
		this.iApplicationsTab := new ApplicationsTab(configuration)
		
		Gui SE:Tab, % tab++
		
		this.iControllerTab := new ControllerTab(configuration)
		
		Gui SE:Tab, % tab++
		
		this.iLaunchpadTab := new LaunchpadTab(configuration)
		
		Gui SE:Tab, % tab++
		
		this.iChatMessagesTab := new ChatMessagesTab(configuration)
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		this.iSaveMode := getConfigurationValue(configuration, "General", "Save", "Manual")
		
		saveModeDropDown := this.iSaveMode
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		GuiControlGet saveModeDropDown
		
		this.iSaveMode := ["Auto", "Manual"][saveModeDropDown]
		
		setConfigurationValue(configuration, "General", "Save", this.iSaveMode)
		
		this.iGeneralTab.saveToConfiguration(configuration)
		
		if this.iDevelopment
			this.iDevelopmentTab.saveToConfiguration(configuration)
			
		this.iVoiceControlTab.saveToConfiguration(configuration)
		this.iPluginsTab.saveToConfiguration(configuration)
		this.iApplicationsTab.saveToConfiguration(configuration)
		this.iControllerTab.saveToConfiguration(configuration)
		this.iLaunchpadTab.saveToConfiguration(configuration)
		this.iChatMessagesTab.saveToConfiguration(configuration)
	}
	
	show() {
		Gui SE:Show, AutoSize Center
	}
	
	hide() {
		Gui SE:Hide
	}
	
	close() {
		Gui SE:Destroy
	}
}

saveAndExit() {
	vResult := kOk
}

cancelAndExit() {
	vResult := kCancel
}

saveAndStay() {
	vResult := kApply
}

moveConfigurationEditor() {
	moveByMouse("SE")
}

updateSaveMode() {
	GuiControlGet saveModeDropDown
	
	ConfigurationEditor.Instance.iSaveMode := ["Auto", "Manual"][saveModeDropDown]
}

openConfigurationDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#configuration
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; GeneralTab                                                              ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global nirCmdPathEdit
global homePathEdit

global languageDropDown
global startWithWindowsCheck
global silentModeCheck

global ahkPathEdit
global debugEnabledCheck
global logLevelDropDown

class GeneralTab extends ConfigurationItemTab {
	iSimulatorsList := false
	iDevelopment := false
	iSplashThemesConfiguration := false
	
	__New(development, configuration) {
		this.iDevelopment := development
		
		base.__New(configuration)
		
		GeneralTab.Instance := this
	}
	
	createControls(configuration) {
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y80 w458 h70, % translate("Installation")
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Text, x24 y97 w160 h23 +0x200, % translate("Installation Folder (optional)")
		Gui SE:Add, Edit, x224 y97 w214 h21 VhomePathEdit, %homePathEdit%
		Gui SE:Add, Button, x440 y96 w23 h23 gchooseHomePath, % translate("...")
		
		Gui SE:Add, Text, x24 y121 w160 h23 +0x200, % translate("NirCmd Folder (optional)")
		Gui SE:Add, Edit, x224 y121 w214 h21 VnirCmdPathEdit, %nirCmdPathEdit%
		Gui SE:Add, Button, x440 y120 w23 h23 gchooseNirCmdPath, % translate("...")
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y160 w458 h95, % translate("Settings")
		
		Gui SE:Font, Norm, Arial
		
		choices := []
		chosen := 0
		enIndex := 0
		
		for code, language in availableLanguages() {
			choices.Push(language)
			
			if (language == languageDropDown)
				chosen := A_Index
				
			if (code = "en")
				enIndex := A_Index
		}
		
		if (chosen == 0)
			chosen := enIndex
			
		Gui SE:Add, Text, x24 y176 w86 h23 +0x200, % translate("Language")
		Gui SE:Add, DropDownList, x224 y176 w214 Choose%chosen% VlanguageDropDown, % values2String("|", choices*)
		Gui SE:Add, Button, x440 y175 w23 h23 gopenTranslationsEditor, % translate("...")
		
		Gui SE:Add, CheckBox, x24 y200 w242 h23 Checked%startWithWindowsCheck% VstartWithWindowsCheck, % translate("Start with Windows")
		Gui SE:Add, CheckBox, x24 y224 w242 h23 Checked%silentModeCheck% VsilentModeCheck, % translate("Silent mode (no splash screen, no sound)")
		
		Gui SE:Add, Button, x363 y224 w100 h23 GopenThemesEditor, % translate("Themes Editor...")
	
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y265 w458 h115, % translate("Simulators")
		
		Gui SE:Font, Norm, Arial
		
		this.iSimulatorsList := new SimulatorsList(configuration)
		
		if this.iDevelopment {
			Gui SE:Font, Norm, Arial
			Gui SE:Font, Italic, Arial
			
			Gui SE:Add, GroupBox, x16 y410 w458 h95, % translate("Development")
			
			Gui SE:Font, Norm, Arial
			
			Gui SE:Add, Text, x24 y427 w160 h23 +0x200, % translate("AutoHotkey Folder")
			Gui SE:Add, Edit, x224 y427 w214 h21 VahkPathEdit, %ahkPathEdit%
			Gui SE:Add, Button, x440 y426 w23 h23 gchooseAHKPath, % translate("...")
			
			Gui SE:Add, Text, x24 y451 w160 h23 +0x200, % translate("Debug")
			Gui SE:Add, CheckBox, x224 y451 w242 h23 Checked%debugEnabledCheck% VdebugEnabledCheck, % translate("Enabled?")
			
			Gui SE:Add, Text, x24 y475 w160 h23 +0x200, % translate("Log Level")
			
			choices := ["Info", "Warn", "Critical", "Off"]
			
			chosen := inList(choices, logLevelDropDown)
			
			if !chosen
				chosem := 2
				
			Gui SE:Add, DropDownList, x224 y475 w91 Choose%chosen% VlogLevelDropDown, % values2String("|", map(choices, "translate")*)
		}
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		nirCmdPathEdit := getConfigurationValue(configuration, "Configuration", "NirCmd Path", "")
		homePathEdit := getConfigurationValue(configuration, "Configuration", "Home Path", "")
		
		languageDropDown := availableLanguages()[getConfigurationValue(configuration, "Configuration", "Language", getLanguage())]
		startWithWindowsCheck := getConfigurationValue(configuration, "Configuration", "Start With Windows", true)
		silentModeCheck := getConfigurationValue(configuration, "Configuration", "Silent Mode", false)
		
		if this.iDevelopment {
			ahkPathEdit := getConfigurationValue(configuration, "Configuration", "AHK Path", "")
			debugEnabledCheck := getConfigurationValue(configuration, "Configuration", "Debug", false)
			logLevelDropDown := getConfigurationValue(configuration, "Configuration", "Log Level", "Warn")
		}
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		GuiControlGet nirCmdPathEdit
		GuiControlGet homePathEdit
		
		GuiControlGet languageDropDown
		GuiControlGet startWithWindowsCheck
		GuiControlGet silentModeCheck
		
		setConfigurationValue(configuration, "Configuration", "NirCmd Path", nirCmdPathEdit)
		setConfigurationValue(configuration, "Configuration", "Home Path", homePathEdit)
		
		languageCode := "en"
		
		for code, language in availableLanguages()
			if (language = languageDropDown) {
				languageCode := code
				
				break
			}
			
		setConfigurationValue(configuration, "Configuration", "Language", languageCode)
		setConfigurationValue(configuration, "Configuration", "Start With Windows", startWithWindowsCheck)
		setConfigurationValue(configuration, "Configuration", "Silent Mode", silentModeCheck)
		
		if this.iSplashThemesConfiguration
			setConfigurationValues(configuration, this.iSplashThemesConfiguration)
		else {
			setConfigurationSectionValues(configuration, "Splash Window", getConfigurationSectionValues(this.Configuration, "Splash Window", Object()))
			setConfigurationSectionValues(configuration, "Splash Themes", getConfigurationSectionValues(this.Configuration, "Splash Themes", Object()))
		}
		
		if this.iDevelopment {
			GuiControlGet ahkPathEdit
			GuiControlGet debugEnabledCheck
			GuiControlGet logLevelDropDown
		
			setConfigurationValue(configuration, "Configuration", "AHK Path", ahkPathEdit)
			setConfigurationValue(configuration, "Configuration", "Debug", debugEnabledCheck)
			
			choices := ["Info", "Warn", "Critical", "Off"]
			
			setConfigurationValue(configuration, "Configuration", "Log Level", choices[inList(map(choices, "translate"), logLevelDropDown)])
		}
		
		this.iSimulatorsList.saveToConfiguration(configuration)
	}
	
	openTranslationsEditor() {
		GuiControlGet languageDropDown
		
		ConfigurationEditor.Instance.hide()
		
		if (new TranslationsEditor(this.Configuration)).editTranslations() {
			ConfigurationEditor.Instance.show()
			
			Gui SE:Default
			
			choices := []
			chosen := 0
			enIndex := 1
			
			for code, language in availableLanguages() {
				choices.Push(language)
				
				if (language == languageDropDown)
					chosen := A_Index
				
				if (code = "en")
					enIndex := A_Index
			}
			
			if (chosen == 0) {
				chosen := enIndex
				languageDropDown := "English"
			}
			
			GuiControl, , languageDropDown, % "|" . values2String("|", choices*)
			GuiControl Choose, languageDropDown, %chosen%
		}
		else
			ConfigurationEditor.Instance.show()
	}
	
	openThemesEditor() {
		ConfigurationEditor.Instance.hide()
		
		this.iSplashThemesConfiguration := (new ThemesEditor(this.iSplashThemesConfiguration ? this.iSplashThemesConfiguration : this.Configuration)).editThemes()
		
		ConfigurationEditor.Instance.show()
	}
}

chooseHomePath() {
	protectionOn()
	
	try{
		FileSelectFolder directory, *%homePathEdit%, 0, % translate("Select Installation folder...")
	
		if (directory != "")
			GuiControl Text, homePathEdit, %directory%
	}
	finally {
		protectionOff()
	}
}

chooseNirCmdPath() {
	protectionOn()
	
	try{
		FileSelectFolder directory, *%nirCmdPathEdit%, 0, % translate("Select NirCmd folder...")
	
		if (directory != "")
			GuiControl Text, nirCmdPathEdit, %directory%
	}
	finally {
		protectionOff()
	}
}

chooseAHKPath() {
	protectionOn()
	
	try{
		FileSelectFolder directory, *%ahkPathEdit%, 0, % translate("Select AutoHotkey folder...")
	
		if (directory != "")
			GuiControl Text, ahkPathEdit, %directory%
	}
	finally {
		protectionOff()
	}
}

openTranslationsEditor() {
	GeneralTab.Instance.openTranslationsEditor()
}

openThemesEditor() {
	GeneralTab.Instance.openThemesEditor()
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; SimulatorsList                                                          ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global simulatorsListBox := "|"

global simulatorEdit = ""

global simulatorUpButton
global simulatorDownButton

global simulatorAddButton
global simulatorDeleteButton
global simulatorUpdateButton
		
class SimulatorsList extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "simulatorsListBox"
				 , "simulatorAddButton", "simulatorDeleteButton", "simulatorUpdateButton", "simulatorUpButton", "simulatorDownButton")
				 
		SimulatorsList.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListBox, x24 y284 w194 h96 HwndsimulatorsListBoxHandle VsimulatorsListBox glistEvent, %simulatorsListBox%
		
		Gui SE:Add, Edit, x224 y284 w239 h21 VsimulatorEdit, %simulatorEdit%
		
		Gui SE:Add, Button, x385 y309 w38 h23 Disabled VsimulatorUpButton gupItem, % translate("Up")
		Gui SE:Add, Button, x425 y309 w38 h23 Disabled VsimulatorDownButton gdownItem, % translate("Down")
		
		Gui SE:Add, Button, x264 y349 w46 h23 VsimulatorAddButton gaddItem, % translate("Add")
		Gui SE:Add, Button, x312 y349 w50 h23 Disabled VsimulatorDeleteButton gdeleteItem, % translate("Delete")
		Gui SE:Add, Button, x408 y349 w55 h23 Disabled VsimulatorUpdateButton gupdateItem, % translate("&Save")
		
		return simulatorsListBoxHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		this.iItemsList := string2Values("|", getConfigurationValue(configuration, "Configuration", "Simulators", ""))
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		setConfigurationValue(configuration, "Configuration", "Simulators", values2String("|", this.iItemsList*))	
	}
	
	loadList(items) {
		simulatorsListBox := values2String("|", this.iItemsList*)
	
		GuiControl, , simulatorsListBox, % "|" . simulatorsListBox
	}
	
	selectItem(itemNumber) {
		this.iCurrentItemIndex := itemNumber
		
		if itemNumber
			GuiControl Choose, simulatorsListBox, %itemNumber%
		
		this.updateState()
	}
	
	loadEditor(item) {
		simulatorEdit := item
			
		GuiControl Text, simulatorEdit, %simulatorEdit%
	}
	
	clearEditor() {
		this.loadEditor("")
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet simulatorEdit
		
		return simulatorEdit
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; VoiceControlTab                                                         ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global voiceLanguageDropDown
global speakerDropDown
global speakerVolumeSlider
global speakerPitchSlider
global speakerSpeedSlider
global listenerDropDown
global pushToTalkEdit = ""

class VoiceControlTab extends ConfigurationItemTab {
	__New(configuration) {
		base.__New(configuration)
		
		VoiceControlTab.Instance := this
	}
	
	createControls(configuration) {
		Gui SE:Font, Norm, Arial
		
		choices := []
		chosen := 0
		enIndex := 0
		
		languages := availableLanguages()
		
		for ignore, grammarFile in getFileNames("Race Engineer.grammars.*", kUserConfigDirectory, kConfigDirectory) {
			SplitPath grammarFile, , , languageCode
		
			if languages.HasKey(languageCode)
				language := languages[languageCode]
			else
				language := languageCode
			
			choices.Push(language)
			
			if (language == voiceLanguageDropDown)
				chosen := A_Index
				
			if (languageCode = "en")
				enIndex := A_Index
		}
		
		if (chosen == 0)
			chosen := enIndex
			
		Gui SE:Add, Text, x16 y80 w100 h23 +0x200, % translate("Language")
		Gui SE:Add, DropDownList, x134 y80 w135 Choose%chosen% VvoiceLanguageDropDown, % values2String("|", choices*)
		
		voices := new SpeechGenerator().Voices.Clone()
		
		voices.InsertAt(1, translate("Deactivated"))
		voices.InsertAt(1, translate("Automatic"))
		
		chosen := inList(voices, speakerDropDown)
		
		if (chosen == 0)
			chosen := 1
		
		Gui SE:Add, Text, x16 y112 w100 h23 +0x200, % translate("Speech Generator")
		Gui SE:Add, DropDownList, x134 y112 w340 Choose%chosen% VspeakerDropDown, % values2String("|", voices*)
		
		Gui SE:Add, Text, x16 y136 w100 h23 +0x200, % translate("Volume")
		Gui SE:Add, Slider, x134 y136 w135 Range0-100 ToolTip VspeakerVolumeSlider, % speakerVolumeSlider
		
		Gui SE:Add, Text, x16 y160 w100 h23 +0x200, % translate("Pitch")
		Gui SE:Add, Slider, x134 y160 w135 Range-10-10 ToolTip VspeakerPitchSlider, % speakerPitchSlider
		
		Gui SE:Add, Text, x16 y184 w100 h23 +0x200, % translate("Speed")
		Gui SE:Add, Slider, x134 y184 w135 Range-10-10 ToolTip VspeakerSpeedSlider, % speakerSpeedSlider
		
		recognizers := new SpeechRecognizer().getRecognizerList().Clone()
		
		Loop % recognizers.Length()
			recognizers[A_Index] := recognizers[A_Index].Name
		
		recognizers.InsertAt(1, translate("Deactivated"))
		recognizers.InsertAt(1, translate("Automatic"))
		
		chosen := inList(recognizers, listenerDropDown)
		
		if (chosen == 0)
			chosen := 1
		
		Gui SE:Add, Text, x16 y216 w100 h23 +0x200, % translate("Speech Recognizer")
		Gui SE:Add, DropDownList, x134 y216 w340 Choose%chosen% VlistenerDropDown, % values2String("|", recognizers*)
		
		Gui SE:Add, Text, x16 y240 w70 h23 +0x200, % translate("Push To Talk")
		Gui SE:Add, Edit, x134 y240 w110 h21 VpushToTalkEdit, %pushToTalkEdit%
		Gui SE:Add, Button, x246 y239 w23 h23 ggetPTTHotkey HwnddetectPTTButtonHandle
		setButtonIcon(detectPTTButtonHandle, kIconsDirectory . "Key.ico", 1)
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		languageCode := getConfigurationValue(configuration, "Voice Control", "Language", getLanguage())
		languages := availableLanguages()
		
		if languages.HasKey(languageCode)
			voiceLanguageDropDown := languages[languageCode]
		else
			voiceLanguageDropDown := languageCode
		
		speakerDropDown := getConfigurationValue(configuration, "Voice Control", "Speaker", true)
		speakerVolumeSlider := getConfigurationValue(configuration, "Voice Control", "SpeakerVolume", 100)
		speakerPitchSlider := getConfigurationValue(configuration, "Voice Control", "SpeakerPitch", 0)
		speakerSpeedSlider := getConfigurationValue(configuration, "Voice Control", "SpeakerSpeed", 0)
		
		listenerDropDown := getConfigurationValue(configuration, "Voice Control", "Listener", false)
		pushToTalkEdit := getConfigurationValue(configuration, "Voice Control", "PushToTalk", false)
		
		if (pushToTalkEdit = false)
			pushToTalkEdit := ""
		
		if (speakerDropDown == true)
			speakerDropDown := translate("Automatic")
		else if (speakerDropDown == false)
			speakerDropDown := translate("Deactivated")
		
		if (listenerDropDown == true)
			listenerDropDown := translate("Automatic")
		else if (listenerDropDown == false)
			listenerDropDown := translate("Deactivated")
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		GuiControlGet voiceLanguageDropDown
		GuiControlGet speakerDropDown
		GuiControlGet speakerVolumeSlider
		GuiControlGet speakerPitchSlider
		GuiControlGet speakerSpeedSlider
		GuiControlGet listenerDropDown
		GuiControlGet pushToTalkEdit
		
		languageCode := "en"
		languages := availableLanguages()
		
		for ignore, grammarFile in getFileNames("Race Engineer.grammars.*", kUserConfigDirectory, kConfigDirectory) {
			SplitPath grammarFile, , , grammarLanguageCode
		
			if languages.HasKey(grammarLanguageCode)
				language := languages[grammarLanguageCode]
			else
				language := grammarLanguageCode
			
			if (language = voiceLanguageDropDown) {
				languageCode := grammarLanguageCode
				
				break
			}
		}
		
		if (speakerDropDown = translate("Automatic"))
			speakerDropDown := true
		else if ((speakerDropDown = translate("Deactivated")) || (speakerDropDown = " "))
			speakerDropDown := false
		
		if (listenerDropDown = translate("Automatic"))
			listenerDropDown := true
		else if ((listenerDropDown = translate("Deactivated")) || (listenerDropDown = " "))
			listenerDropDown := false
		
		setConfigurationValue(configuration, "Voice Control", "Language", languageCode)
		setConfigurationValue(configuration, "Voice Control", "Speaker", speakerDropDown)
		setConfigurationValue(configuration, "Voice Control", "SpeakerVolume", speakerVolumeSlider)
		setConfigurationValue(configuration, "Voice Control", "SpeakerPitch", speakerPitchSlider)
		setConfigurationValue(configuration, "Voice Control", "SpeakerSpeed", speakerSpeedSlider)
		setConfigurationValue(configuration, "Voice Control", "Listener", listenerDropDown)
		setConfigurationValue(configuration, "Voice Control", "PushToTalk", (Trim(pushToTalkEdit) = "") ? false : pushToTalkEdit)
	}
}

setPTTHotkey() {
	if vKeyDetectorReturnHotkey is not integer
	{
		SetTimer setPTTHotkey, Off
		
		pushToTalkEdit := vKeyDetectorReturnHotkey
		
		Gui SE:Default
		GuiControl Text, pushToTalkEdit, %pushToTalkEdit%
		
		vShowKeyDetector := false
		vKeyDetectorReturnHotkey := false
	}
	
	if !vShowKeyDetector
		SetTimer setPTTHotkey, Off
}

getPTTHotkey() {
	if !vShowKeyDetector {
		vKeyDetectorReturnHotkey := true
	
		SetTimer setPTTHotkey, 100
	}
	
	toggleKeyDetector()
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; PluginsTab                                                              ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global pluginsListView = false

global pluginEdit = ""
global pluginActivatedCheck = false
global pluginActivatedCheckHandle
global pluginSimulatorsEdit = ""
global pluginArgumentsEdit = ""

global pluginAddButton
global pluginDeleteButton
global pluginUpdateButton
		
class PluginsTab extends ConfigurationItemList {
	Plugins[] {
		Get {
			result := []
			
			for index, thePlugin in this.iItemsList
				result.Push(thePlugin[2])
				
			return result
		}
	}
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "pluginsListView", "pluginAddButton", "pluginDeleteButton", "pluginUpdateButton")
				 
		PluginsTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w457 h205 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndpluginsListViewHandle VpluginsListView glistEvent
							, % values2String("|", map(["Active?", "Plugin", "Simulator(s)", "Arguments"], "translate")*)
		
		Gui SE:Add, Text, x16 y295 w86 h23 +0x200, % translate("Plugin")
		Gui SE:Add, Edit, x110 y295 w154 h21 VpluginEdit, %pluginEdit%
		
		Gui SE:Add, CheckBox, x110 y319 w120 h23 VpluginActivatedCheck HwndpluginActivatedCheckHandle, % translate("Activated?")
		
		Gui SE:Add, Text, x16 y343 w89 h23 +0x200, % translate("Simulator(s)")
		Gui SE:Add, Edit, x110 y343 w363 h21 VpluginSimulatorsEdit, %pluginSimulatorsEdit%
		
		Gui SE:Font, Underline, Arial
		
		Gui SE:Add, Text, x16 y368 w86 h23 +0x200 cBlue gopenPluginsModesDocumentation, % translate("Arguments")
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Edit, x110 y368 w363 h113 VpluginArgumentsEdit, %pluginArgumentsEdit%
		
		Gui SE:Add, Button, x16 y490 w92 h23 gopenLabelsEditor, % translate("Edit Labels...")
		
		Gui SE:Add, Button, x264 y490 w46 h23 VpluginAddButton gaddItem, % translate("Add")
		Gui SE:Add, Button, x312 y490 w50 h23 Disabled VpluginDeleteButton gdeleteItem, % translate("Delete")
		Gui SE:Add, Button, x418 y490 w55 h23 Disabled VpluginUpdateButton gupdateItem, % translate("&Save")
		
		return pluginsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
	
		for name, arguments in getConfigurationSectionValues(configuration, "Plugins", Object())
			this.iItemsList.Push(new Plugin(name, configuration))
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		for ignore, thePlugin in this.iItemsList
			thePlugin.saveToConfiguration(configuration)
	}
	
	updateState() {
		base.updateState()
		
		if (this.iCurrentItemIndex != 0) {
			if (pluginEdit = "System") {
				GuiControl Disable, pluginEdit
				GuiControl Disable, pluginActivatedCheck
				GuiControl Disable, pluginSimulatorsEdit
		
				GuiControl Disable, pluginDeleteButton
			}
			else {
				GuiControl Enable, pluginEdit
				GuiControl Enable, pluginActivatedCheck
				GuiControl Enable, pluginSimulatorsEdit
			
				GuiControl Enable, pluginDeleteButton
			}
		}
		else {
			GuiControl Enable, pluginEdit
			GuiControl Enable, pluginActivatedCheck
			GuiControl Enable, pluginSimulatorsEdit
		}
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		bubbleSort(items, "comparePlugins")
		
		this.iItemsList := items
	
		count := LV_GetCount()
		
		for index, thePlugin in items {
			name := thePlugin.Plugin
			active := thePlugin.Active
		
			if (index <= count)
				LV_Modify(index, "", thePlugin.Active ? ((name = translate("System")) ? translate("Always") : translate("Yes")) : translate("No")
						, name, values2String(", ", thePlugin.Simulators*), thePlugin.Arguments[true])
			else
				LV_Add("", thePlugin.Active ? ((name = translate("System")) ? translate("Always") : translate("Yes")) : translate("No")
					 , name, values2String(", ", thePlugin.Simulators*), thePlugin.Arguments[true])
		}
		
		if (items.Length() < count)
			Loop % count - items.Length()
				LV_Delete(count - A_Index - 1)
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(1, "Center AutoHdr")
			LV_ModifyCol(2, 100)
			LV_ModifyCol(3, 120)
			
			first := false
		}
	}
	
	selectItem(itemNumber) {
		Gui ListView, % this.ListHandle
		
		if (itemNumber && (itemNumber != this.iCurrentItemIndex))
			LV_Modify(itemNumber, "Vis +Select +Focus")
		
		this.iCurrentItemIndex := itemNumber
			
		this.updateState()
	}
	
	loadEditor(item) {
		pluginEdit := item.Plugin
		pluginSimulatorsEdit := values2String(", ", item.Simulators*)
		pluginArgumentsEdit := item.Arguments[true]
		pluginActivatedCheck := item.Active
		
		GuiControl Text, pluginEdit, %pluginEdit%

		if pluginActivatedCheck
			Control Check, , , ahk_id %pluginActivatedCheckHandle%
		else
			Control Uncheck, , , ahk_id %pluginActivatedCheckHandle%
		
		GuiControl, , pluginActivatedCheck, %pluginActivatedCheck%
			
		GuiControl Text, pluginSimulatorsEdit, %pluginSimulatorsEdit%
		GuiControl Text, pluginArgumentsEdit, %pluginArgumentsEdit%
	}
	
	clearEditor() {
		pluginEdit := ""
		pluginSimulatorsEdit := ""
		pluginArgumentsEdit := ""
		pluginActivatedCheck := false
		
		Control Uncheck, , , ahk_id %pluginActivatedCheckHandle%
		GuiControl Text, pluginEdit, %pluginEdit%
		GuiControl Text, pluginSimulatorsEdit, %pluginSimulatorsEdit%
		GuiControl Text, pluginArgumentsEdit, %pluginArgumentsEdit%
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet pluginEdit
		GuiControlGet pluginSimulatorsEdit
		GuiControlGet pluginArgumentsEdit
		GuiControlGet pluginActivatedCheck
		
		return new Plugin(pluginEdit, false, pluginActivatedCheck != 0, pluginSimulatorsEdit, pluginArgumentsEdit)
	}
}

comparePlugins(p1, p2) {
	if (p1.Plugin = translate("System"))
		return false
	else if (p2.Plugin = translate("System"))
		return true
	else
		return (p1.Plugin >= p2.Plugin)
}

openLabelsEditor() {
	Run % "notepad.exe " . """" . kUserConfigDirectory . "Controller Plugin Labels.ini"""
}

openPluginsModesDocumentation() {
	GuiControlGet pluginEdit
	
	switch pluginEdit {
		case "System":
			Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#configuration
		case "Tactile Feedback":
			Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#configuration-1
		case "Motion Feedback":
			Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#configuration-2
		case "Pedal Calibration":
			Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#configuration-3
		case "ACC":
			Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes#configuration-4
		default:
			Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Plugins-&-Modes
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ApplicationsTab                                                         ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global applicationsListView = false

global applicationNameEdit = ""
global applicationExePathEdit = ""
global applicationWorkingDirectoryPathEdit = ""
global applicationWindowTitleEdit = ""
global applicationStartupEdit = ""
global applicationShutdownEdit = ""
global applicationIsRunningEdit = ""

global applicationAddButton
global applicationDeleteButton
global applicationUpdateButton
		
class ApplicationsTab extends ConfigurationItemList {
	Applications[types := false] {
		Get {
			result := []
			
			for index, theApplication in this.iItemsList
				if !types
					result.Push(theApplication[2])
				else if inList(types, theApplication[1])
					result.Push(theApplication[2])
				
			return result
		}
	}
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "applicationsListView", "applicationAddButton", "applicationDeleteButton", "applicationUpdateButton")
				 
		ApplicationsTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w457 h205 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndapplicationsListViewHandle VapplicationsListView glistEvent
							, % values2String("|", map(["Type", "Name", "Executable", "Window Title", "Working Directory"], "translate")*)
		
		Gui SE:Add, Text, x16 y295 w141 h23 +0x200, % translate("Name")
		Gui SE:Add, Edit, x180 y295 w268 h21 VapplicationNameEdit, %applicationNameEdit%
		
		Gui SE:Add, Text, x16 y319 w138 h23 +0x200, % translate("Executable")
		Gui SE:Add, Edit, x180 y319 w268 h21 VapplicationExePathEdit, %applicationExePathEdit%
		Gui SE:Add, Button, x451 y318 w23 h23 gchooseApplicationExePath, % translate("...")
		
		Gui SE:Add, Text, x16 y343 w138 h23 +0x200, % translate("Working Directory (optional)")
		Gui SE:Add, Edit, x180 y343 w268 h21 VapplicationWorkingDirectoryPathEdit, %applicationWorkingDirectoryPathEdit%
		Gui SE:Add, Button, x451 y342 w23 h23 gchooseApplicationWorkingDirectoryPath, % translate("...")
		
		Gui SE:Add, Text, x16 y367 w140 h23 +0x200, % translate("Window Title (optional)")
		Gui SE:Font, c505050 s8
		Gui SE:Add, Text, x24 y385 w133 h23, % translate("(Use AHK WinTitle Syntax)")
		Gui SE:Font
		Gui SE:Add, Edit, x180 y367 w268 h21 VapplicationWindowTitleEdit, %applicationWindowTitleEdit%
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y411 w458 h71, % translate("Function Hooks (optional)")
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Text, x20 y427 w136 h23 +0x200 +Center, % translate("Startup")
		Gui SE:Add, Edit, x20 y451 w136 h21 VapplicationStartupEdit, %applicationStartupEdit%
		
		Gui SE:Add, Text, x177 y427 w136 h23 +0x200 +Center, % translate("Shutdown ")
		Gui SE:Add, Edit, x177 y451 w136 h21 VapplicationShutdownEdit, %applicationShutdownEdit%
		
		Gui SE:Add, Text, x334 y427 w136 h23 +0x200 +Center, % translate("Running?")
		Gui SE:Add, Edit, x334 y451 w136 h21 VapplicationIsRunningEdit, %applicationIsRunningEdit%

		Gui SE:Add, Button, x264 y490 w46 h23 VapplicationAddButton gaddItem, % translate("Add")
		Gui SE:Add, Button, x312 y490 w50 h23 Disabled VapplicationDeleteButton gdeleteItem, % translate("Delete")
		Gui SE:Add, Button, x418 y490 w55 h23 Disabled VapplicationUpdateButton gupdateItem, % translate("&Save")
		
		return applicationsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
	
		for descriptor, name in getConfigurationSectionValues(configuration, "Applications", Object())
			this.iItemsList.Push(Array(translate(ConfigurationItem.splitDescriptor(descriptor)[1]), new Application(name, configuration)))
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		count := 0
		lastType := ""
		
		for index, theApplication in this.iItemsList {
			type := theApplication[1]
			theApplication := theApplication[2]
			
			if (type != lastType) {
				count := 1
				lastType := type
			}
			else
				count += 1
		
			types := ["Core", "Feedback", "Other"]
			
			setConfigurationValue(configuration, "Applications"
								, ConfigurationItem.descriptor(types[inList(map(types, "translate"), type)], count), theApplication.Application)
		
			theApplication.saveToConfiguration(configuration)
		}
	}
	
	updateState() {
		base.updateState()
		
		if (this.iCurrentItemIndex != 0) {
			theApplication := this.iItemsList[this.iCurrentItemIndex]
			
			type := theApplication[1]
			
			if (type != translate("Other")) {
				GuiControl Disable, applicationNameEdit
				GuiControl Disable, applicationDeleteButton
			}
			else {
				GuiControl Enable, applicationNameEdit
				GuiControl Enable, applicationDeleteButton
			}
			
			GuiControl Enable, applicationUpdateButton
		}
		else {
			GuiControl Enable, applicationNameEdit
			GuiControl Disable, applicationDeleteButton
			GuiControl Disable, applicationUpdateButton
		}
		
		LaunchpadTab.Instance.loadApplicationChoices(true)
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		for index, theApplication in items {
			type := theApplication[1]
			theApplication := theApplication[2]
			
			LV_Add("", type, theApplication.Application, theApplication.ExePath, theApplication.WindowTitle, theApplication.WorkingDirectory)
		}
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(1, "Center AutoHdr")
			LV_ModifyCol(2, 120)
			LV_ModifyCol(3, 80)
			LV_ModifyCol(4, 80)
			
			first := false
		}
	}
	
	loadEditor(item) {
		theApplication := item[2]
		
		applicationNameEdit := theApplication.Application
		applicationExePathEdit := theApplication.ExePath
		applicationWorkingDirectoryPathEdit := theApplication.WorkingDirectory
		applicationWindowTitleEdit := theApplication.WindowTitle
		applicationStartupEdit := (theApplication.SpecialStartup ? theApplication.SpecialStartup : "")
		applicationShutdownEdit := (theApplication.SpecialShutdown ? theApplication.SpecialShutdown : "")
		applicationIsRunningEdit := (theApplication.SpecialIsRunning ? theApplication.SpecialIsRunning : "")
		
		GuiControl Text, applicationNameEdit, %applicationNameEdit%
		GuiControl Text, applicationExePathEdit, %applicationExePathEdit%
		GuiControl Text, applicationWorkingDirectoryPathEdit, %applicationWorkingDirectoryPathEdit%
		GuiControl Text, applicationWindowTitleEdit, %applicationWindowTitleEdit%
		GuiControl Text, applicationStartupEdit, %applicationStartupEdit%
		GuiControl Text, applicationShutdownEdit, %applicationShutdownEdit%
		GuiControl Text, applicationIsRunningEdit, %applicationIsRunningEdit%
	}
	
	clearEditor() {
		applicationNameEdit := ""
		applicationExePathEdit := ""
		applicationWorkingDirectoryPathEdit := ""
		applicationWindowTitleEdit := ""
		applicationStartupEdit := ""
		applicationShutdownEdit := ""
		applicationIsRunningEdit := ""
		
		GuiControl Text, applicationNameEdit, %applicationNameEdit%
		GuiControl Text, applicationExePathEdit, %applicationExePathEdit%
		GuiControl Text, applicationWorkingDirectoryPathEdit, %applicationWorkingDirectoryPathEdit%
		GuiControl Text, applicationWindowTitleEdit, %applicationWindowTitleEdit%
		GuiControl Text, applicationStartupEdit, %applicationStartupEdit%
		GuiControl Text, applicationShutdownEdit, %applicationShutdownEdit%
		GuiControl Text, applicationIsRunningEdit, %applicationIsRunningEdit%
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet applicationNameEdit
		GuiControlGet applicationExePathEdit
		GuiControlGet applicationWorkingDirectoryPathEdit
		GuiControlGet applicationWindowTitleEdit
		GuiControlGet applicationStartupEdit
		GuiControlGet applicationShutdownEdit
		GuiControlGet applicationIsRunningEdit
		
		return Array(isNew ? translate("Other") : this.iItemsList[this.iCurrentItemIndex][1]
				   , new Application(applicationNameEdit, false, applicationExePathEdit, applicationWorkingDirectoryPathEdit, applicationWindowTitleEdit
				   , applicationStartupEdit, applicationShutdownEdit, applicationIsRunningEdit))
	}
}

chooseApplicationExePath() {
	protectionOn()
	
	try {
		FileSelectFile file, *%applicationExePathEdit%, 0, % translate("Select application executable...")
		
		if (file != "")
			GuiControl Text, applicationExePathEdit, %file%
	}
	finally {
		protectionOff()
	}
}

chooseApplicationWorkingDirectoryPath() {
	protectionOn()
	
	try {
		FileSelectFolder directory, *%applicationWorkingDirectoryPathEdit%, 0, % translate("Select working directory...")
	
		if (directory != "")
			GuiControl Text, applicationWorkingDirectoryPathEdit, %directory%
	}
	finally {
		protectionOff()
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ControllerTab                                                           ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ControllerTab extends ConfigurationItemTab {
	iButtonBoxesList := false
	iFunctionsist := false
	
	__New(configuration) {
		base.__New(configuration)
		
		ControllerTab.Instance := this
	}
	
	createControls(configuration) {
		this.iButtonBoxesList := new ButtonBoxesList(configuration)
		
		this.iFunctionsList := new FunctionsList(configuration)
		
		Gui SE:Add, Button, x16 y490 w100 h23 gtoggleKeyDetector, % translate("Key Detector...")
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		this.iButtonBoxesList.saveToConfiguration(configuration)
		this.iFunctionsList.saveToConfiguration(configuration)
	}
}

toggleKeyDetector() {
	vShowKeyDetector := !vShowKeyDetector
	
	if vShowKeyDetector
		SetTimer showKeyDetector, -100
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ButtonBoxesList                                                         ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global buttonBoxesListBox := "|"

global buttonBoxEdit = ""
global buttonBoxLayoutDropDown = 0
global openButtonBoxEditorButton

global buttonBoxUpButton
global buttonBoxDownButton

global buttonBoxAddButton
global buttonBoxDeleteButton
global buttonBoxUpdateButton
		
class ButtonBoxesList extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "buttonBoxesListBox"
				 , "buttonBoxAddButton", "buttonBoxDeleteButton", "buttonBoxUpdateButton", "buttonBoxUpButton", "buttonBoxDownButton")
				 
		ButtonBoxesList.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y80 w457 h115, % translate("Button Boxes")
		
		Gui SE:Font, Norm, Arial
		Gui SE:Add, ListBox, x24 y99 w194 h96 HwndbuttonBoxesListBoxHandle VbuttonBoxesListBox glistEvent, %buttonBoxesListBox%
		
		Gui SE:Add, Edit, x224 y99 w104 h21 VbuttonBoxEdit, %buttonBoxEdit%
		Gui SE:Add, DropDownList, x330 y99 w108 Choose%buttonBoxLayoutDropDown% VbuttonBoxLayoutDropDown, % values2String("|", this.computeLayoutChoices()*)
		Gui SE:Add, Button, x440 y98 w23 h23 gopenButtonBoxEditor VopenButtonBoxEditorButton, % translate("...")
		
		Gui SE:Add, Button, x385 y124 w38 h23 Disabled VbuttonBoxUpButton gupItem, % translate("Up")
		Gui SE:Add, Button, x425 y124 w38 h23 Disabled VbuttonBoxDownButton gdownItem, % translate("Down")
		
		Gui SE:Add, Button, x265 y164 w46 h23 VbuttonBoxAddButton gaddItem, % translate("Add")
		Gui SE:Add, Button, x313 y164 w50 h23 Disabled VbuttonBoxDeleteButton gdeleteItem, % translate("Delete")
		Gui SE:Add, Button, x409 y164 w55 h23 Disabled VbuttonBoxUpdateButton gupdateItem, % translate("Save")
		
		return buttonBoxesListBoxHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		items := []
		
		for ignore, controller in string2Values("|", getConfigurationValue(configuration, "Controller Layouts", "Button Boxes", ""))
			items.Push(string2Values(":", controller))
			
		this.iItemsList := items
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		controller := []
		
		for ignore, item in this.iItemsList
			controller.Push(values2String(":", item*))
		
		setConfigurationValue(configuration, "Controller Layouts", "Button Boxes", values2String("|", controller*))	
	}
	
	loadList(items) {
		controller := []
		
		for ignore, item in this.iItemsList
			controller.Push(item[1])
		
		buttonBoxesListBox := values2String("|", controller*)
	
		GuiControl, , buttonBoxesListBox, % "|" . buttonBoxesListBox
	}
	
	selectItem(itemNumber) {
		this.iCurrentItemIndex := itemNumber
		
		if itemNumber
			GuiControl Choose, buttonBoxesListBox, %itemNumber%
		
		this.updateState()
	}
	
	loadEditor(item) {
		buttonBoxEdit := item[1]
		buttonBoxLayoutDropDown := item[2]
			
		GuiControl Text, buttonBoxEdit, %buttonBoxEdit%
		
		try {
			GuiControl Choose, buttonBoxLayoutDropDown, %buttonBoxLayoutDropDown%
		}
		catch exception {
			GuiControl Choose, buttonBoxLayoutDropDown, 0
		}
	}
	
	clearEditor() {
		this.loadEditor(Array("", ""))
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet buttonBoxEdit
		GuiControlGet buttonBoxLayoutDropDown
		
		if ((buttonBoxEdit = "") || (buttonBoxLayoutDropDown = "") || !buttonBoxLayoutDropDown) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
			OnMessage(0x44, "")
			
			return false
		}
		else
			return Array(buttonBoxEdit, buttonBoxLayoutDropDown)
	}
	
	computeLayoutChoices(configuration := false) {
		if !configuration
			configuration := readConfiguration(getFileName("Button Box Configuration.ini", kUserConfigDirectory, kConfigDirectory))
		
		layouts := []
		
		for descriptor, definition in getConfigurationSectionValues(configuration, "Layouts", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			
			if !inList(layouts, descriptor[1])
				layouts.Push(descriptor[1])
		}
		
		return layouts
	}
	
	openButtonBoxEditor() {
		GuiControlGet buttonBoxEdit
		GuiControlGet buttonBoxLayoutDropDown
		
		ConfigurationEditor.Instance.hide()
		
		result := (new ButtonBoxesEditor(buttonBoxEdit, readConfiguration(getFileName("Button Box Configuration.ini", kUserConfigDirectory, kConfigDirectory)))).editButtonBox()
		
		if result
			writeConfiguration(getFileName("Button Box Configuration.ini", kUserConfigDirectory), result)
		
		Gui SE:Default
		
		choices := this.computeLayoutChoices(result)
		
		GuiControl Text, buttonBoxLayoutDropDown, % "|" . values2String("|", choices*)
		
		if inList(choices, buttonBoxLayoutDropDown)
			GuiControl Choose, buttonBoxLayoutDropDown, %buttonBoxLayoutDropDown%
		else
			GuiControl Choose, buttonBoxLayoutDropDown, %A_Space%
		
		ConfigurationEditor.Instance.show()
	}
}

openButtonBoxEditor() {
	ButtonBoxesList.Instance.openButtonBoxEditor()
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; FunctionsList                                                           ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global functionsListView

global functionTypeDropDown = 0
global functionNumberEdit = ""
global functionOnHotkeysEdit = ""
global functionOnActionEdit = ""
global functionOffHotkeysEdit = ""
global functionOffActionEdit = ""

global functionAddButton
global functionDeleteButton
global functionUpdateButton

class FunctionsList extends ConfigurationItemList {
	iFunctions := {}
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "functionsListView", "functionAddButton", "functionDeleteButton", "functionUpdateButton")
		
		FunctionsList.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y200 w457 h150 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndfunctionsListViewHandle VfunctionsListView glistEvent
							, % values2String("|", map(["Function", "Number", "Hotkey(s) & Action(s)"], "translate")*)
	
		Gui SE:Add, Text, x16 y360 w86 h23 +0x200, % translate("Function")
		Gui SE:Add, DropDownList, x124 y360 w91 AltSubmit Choose%functionTypeDropDown% VfunctionTypeDropDown gupdateFunctionEditorState
								, % values2String("|", map(["1-way Toggle", "2-way Toggle", "Button", "Dial", "Custom"], "translate")*)
		Gui SE:Add, Edit, x220 y360 w40 h21 Number VfunctionNumberEdit, %functionNumberEdit%
		Gui SE:Add, UpDown, x260 y360 w17 h21, 1
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y392 w457 h91, % translate("Bindings")
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Text, x124 y400 w160 h23 +0x200 +Center, % translate("On or Increase")
		Gui SE:Add, Text, x303 y400 w160 h23 +0x200 +Center, % translate("Off or Decrease")
		
		Gui SE:Font, Underline, Arial
		
		Gui SE:Add, Text, x24 y424 w83 h23 +0x200 cBlue gopenHotkeysDocumentation, % translate("Hotkey(s)")
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Edit, x124 y424 w160 h21 VfunctionOnHotkeysEdit, %functionOnHotkeysEdit%
		Gui SE:Add, Edit, x303 y424 w160 h21 VfunctionOffHotkeysEdit, %functionOffHotkeysEdit%
		
		Gui SE:Font, Underline, Arial
		
		Gui SE:Add, Text, x24 y450 w83 h23 cBlue gopenActionsDocumentation, % translate("Action (optional)")
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Edit, x124 y448 w160 h21 VfunctionOnActionEdit, %functionOnActionEdit%
		Gui SE:Add, Edit, x303 y448 w160 h21 VfunctionOffActionEdit, %functionOffActionEdit%
		
		Gui SE:Add, Button, x264 y490 w46 h23 VfunctionAddButton gaddItem, % translate("Add")
		Gui SE:Add, Button, x312 y490 w50 h23 Disabled VfunctionDeleteButton gdeleteItem, % translate("Delete")
		Gui SE:Add, Button, x418 y490 w55 h23 Disabled VfunctionUpdateButton gupdateItem, % translate("&Save")
		
		return functionsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
	
		for descriptor, arguments in getConfigurationSectionValues(configuration, "Controller Functions", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			descriptor := ConfigurationItem.descriptor(descriptor[1], descriptor[2])
			
			if !this.iFunctions.HasKey(descriptor) {
				func := Function.createFunction(descriptor, configuration)
				
				this.iFunctions[descriptor] := func
				this.iItemsList.Push(func)
			}
		}
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		for ignore, theFunction in this.iItemsList
			theFunction.saveToConfiguration(configuration)
	}
	
	updateState() {
		base.updateState()
	
		GuiControlGet functionType, , functionTypeDropDown
	
		if (functionType < 5) {
			GuiControl Disable, functionOnActionEdit
			GuiControl Disable, functionOffActionEdit
		}
		else {
			GuiControl Enable, functionOnActionEdit
			GuiControl Enable, functionOffActionEdit
		}
			
		if ((functionType == 2) || (functionType == 4))
			GuiControl Enable, functionOffHotkeysEdit
		else {
			functionOffHotkeysEdit := ""
			functionOffActionEdit := ""
			
			GuiControl Text, functionOffHotkeysEdit, %functionOffHotkeysEdit%
			GuiControl Text, functionOffActionEdit, %functionOffActionEdit%
			
			GuiControl Disable, functionOffHotkeysEdit
			GuiControl Disable, functionOffActionEdit
		}
	}

	computeFunctionType(functionType) {
		if (functionType == k1WayToggleType)
			return "1-way Toggle"
		else if (functionType == k2WayToggleType)
			return "2-way Toggle"
		else
			return functionType
	}

	computeHotkeysAndActionText(hotkeys, action) {
		if (hotKeys && (hotkeys != ""))
			return hotkeys . ((action == "") ? "" : (" => " . action))
		else
			return ""
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		this.iItemsList := Array()
		
		LV_Delete()
		
		round := 0
		
		Loop {
			if (++round > 2)
				break
				
			for qualifier, theFunction in this.iFunctions 
				if (((round == 1) && (theFunction.Type != kCustomType)) || ((round == 2) && (theFunction.Type == kCustomType))) {
					hotkeysAndActions := ""

					for index, trigger in theFunction.Trigger {
						hotkeys := theFunction.Hotkeys[trigger, true]
						action := theFunction.Actions[trigger, true]
						
						nextHKA := this.computeHotkeysAndActionText(hotkeys, action)
						
						if ((index > 1) && (hotkeysAndActions != "") && (nextHKA != ""))
							hotkeysAndActions := hotkeysAndActions . ", "
							
						hotkeysAndActions := hotkeysAndActions . nextHKA
					}
						
					LV_Add("", translate(this.computeFunctionType(theFunction.Type)), theFunction.Number, hotkeysAndActions)
					
					this.iItemsList.Push(theFunction)
				}
		}
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(2, "Center AutoHdr")
			
			first := false
		}
	}
	
	loadEditor(item) {
		functionType := item.Type
		onKey := false
		offKey := false
		
		switch item.Type {
			case k1WayToggleType:
				functionTypeDropDown := 1
				onKey := "On"
			case k2WayToggleType:
				functionTypeDropDown := 2
				onKey := "On"
				offKey := "Off"
			case kButtonType:
				functionTypeDropDown := 3
				onKey := "Push"
			case kDialType:
				functionTypeDropDown := 4
				onKey := "Increase"
				offKey := "Decrease"
			case kCustomType:
				functionTypeDropDown := 5
				onKey := "Call"
			default:
				Throw "Unknown function type (" . functionType . ") detected in FunctionsList.loadEditor..."
		}
		
		functionNumberEdit := item.Number
		functionOnHotkeysEdit := item.Hotkeys[onKey, true]
		functionOnActionEdit := item.Actions[onKey, true]
		
		if offKey {
			functionOffHotkeysEdit := item.Hotkeys[offKey, true]
			functionOffActionEdit := item.Actions[offKey, true]
		}
		
		GuiControl Choose, functionTypeDropDown, %functionTypeDropDown%
		GuiControl Text, functionNumberEdit, %functionNumberEdit%
		GuiControl Text, functionOnHotkeysEdit, %functionOnHotkeysEdit%
		GuiControl Text, functionOnActionEdit, %functionOnActionEdit%
		GuiControl Text, functionOffHotkeysEdit, %functionOffHotkeysEdit%
		GuiControl Text, functionOffActionEdit, %functionOffActionEdit%
	}
	
	clearEditor() {
		functionTypeDropDown := 0
		functionNumberEdit := 0
		functionOnHotkeysEdit := ""
		functionOnActionEdit := ""
		functionOffHotkeysEdit := ""
		functionOffActionEdit := ""
		
		GuiControl Choose, functionTypeDropDown, %functionTypeDropDown%
		GuiControl Text, functionNumberEdit, %functionNumberEdit%
		GuiControl Text, functionOnHotkeysEdit, %functionOnHotkeysEdit%
		GuiControl Text, functionOnActionEdit, %functionOnActionEdit%
		GuiControl Text, functionOffHotkeysEdit, %functionOffHotkeysEdit%
		GuiControl Text, functionOffActionEdit, %functionOffActionEdit%
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet functionTypeDropDown
		GuiControlGet functionNumberEdit
		GuiControlGet functionOnHotkeysEdit
		GuiControlGet functionOnActionEdit
		GuiControlGet functionOffHotkeysEdit
		GuiControlGet functionOffActionEdit
		
		functionType := [false, k1WayToggleType, k2WayToggleType, kButtonType, kDialType, kCustomType][functionTypeDropDown + 1]
		
		if (functionType && (functionNumberEdit >= 0)) {
			if ((functionType != k2WayToggleType) && (functionType != kDialType)) {
				functionOffHotkeysEdit := ""
				functionOffActionEdit := ""
			}
			
			return Function.createFunction(ConfigurationItem.descriptor(functionType, functionNumberEdit), false, functionOnHotkeysEdit, functionOnActionEdit, functionOffHotkeysEdit, functionOffActionEdit)
		}
		else {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
			OnMessage(0x44, "")
			
			return false
		}
	}
	
	addItem() {
		local function := this.buildItemFromEditor(true)
	
		if function
			if this.iFunctions.HasKey(function.Descriptor) {
				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
				title := translate("Error")
				MsgBox 262160, %title%, % translate("This function already exists - please use different values...")
				OnMessage(0x44, "")
			}
			else {
				this.iFunctions[function.Descriptor] := function
				
				base.addItem()
				
				this.selectItem(inList(this.iItemsList, function))
			}
	}
	
	deleteItem() {
		this.iFunctions.Delete(this.iItemsList[this.iCurrentItemIndex].Descriptor)
		
		base.deleteItem()
	}
	
	updateItem() {
		local function := this.buildItemFromEditor()
	
		if function
			if (function.Descriptor != this.iItemsList[this.iCurrentItemIndex].Descriptor) {
				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
				title := translate("Error")
				MsgBox 262160, %title%, % translate("The type and number of an existing function may not be changed...")
				OnMessage(0x44, "")
			}
			else {
				this.iFunctions[function.Descriptor] := function
				
				base.updateItem()
			}
	}
}

updateFunctionEditorState() {
	protectionOn()
	
	try {
		vItemLists["functionsListView"].updateState()
	}
	finally {
		protectionOff()
	}
}

openHotkeysDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#hotkeys
}

openActionsDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#actions
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; LaunchpadTab                                                            ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global launchpadListView = false
global launchpadNumberEdit = 1
global launchpadLabelEdit = ""
global launchpadApplicationDropDown = 0
global launchpadAddButton
global launchpadDeleteButton
global launchpadUpdateButton
		
class LaunchpadTab extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "launchpadListView"
				 , "launchpadAddButton", "launchpadDeleteButton", "launchpadUpdateButton")
				 
		LaunchpadTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w457 h205 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndlaunchpadListViewHandle VlaunchpadListView glistEvent
							, % values2String("|", map(["#", "Label", "Application"], "translate")*)
		
		Gui SE:Add, Text, x16 y295 w86 h23 +0x200, % translate("Button")
		Gui SE:Add, Text, x95 y295 w23 h23 +0x200, % translate("#")
		Gui SE:Add, Edit, x110 y295 w40 h21 Number VlaunchpadNumberEdit, %launchpadNumberEdit%
		Gui SE:Add, UpDown, x150 y295 w17 h21, 1
		
		Gui SE:Add, Text, x16 y319 w86 h23 +0x200, % translate("Label")
		Gui SE:Add, Edit, x110 y319 w80 h21 VlaunchpadLabelEdit, %launchpadLabelEdit%
		
		Gui SE:Add, Text, x16 y343 w86 h23 +0x200, % translate("Application")
		Gui SE:Add, DropDownList, x110 y343 w363 h21 R10 Choose%launchpadApplicationDropDown% VlaunchpadApplicationDropDown
		
		Gui SE:Add, Button, x264 y490 w46 h23 VlaunchpadAddButton gaddItem, % translate("Add")
		Gui SE:Add, Button, x312 y490 w50 h23 Disabled VlaunchpadDeleteButton gdeleteItem, % translate("Delete")
		Gui SE:Add, Button, x418 y490 w55 h23 Disabled VlaunchpadUpdateButton gupdateItem, % translate("&Save")
		
		return launchpadListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		for descriptor, launchpad in getConfigurationSectionValues(configuration, "Launchpad", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			launchpad := string2Values("|", launchpad)

			this.iItemsList.Push(Array(descriptor[2], launchpad[1], launchpad[2]))
		}
		
		this.loadApplicationChoices()
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		for ignore, launchpadApplication in this.iItemsList
			setConfigurationValue(configuration, "Launchpad", ConfigurationItem.descriptor("Button", launchpadApplication[1]), values2String("|", launchpadApplication[2], launchpadApplication[3]))	
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		bubbleSort(items, "compareLaunchApplications")
		
		this.iItemsList := items
		
		for ignore, launchpadApplication in items
			LV_Add("", launchpadApplication[1], launchpadApplication[2], launchpadApplication[3])
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(2, "AutoHdr")
			
			first := false
		}
	}
	
	loadApplicationChoices(application := false) {
		launchpadApplicationsList := []
		currentApplication := false
	
		if this.iCurrentItemIndex
			currentApplication := this.iItemsList[this.iCurrentItemIndex][3]
		
		for ignore, launchpadApplication in ApplicationsTab.Instance.Applications[[translate("Other")]]
			launchpadApplicationsList.Push(launchpadApplication.Application)
		
		launchpadApplicationDropDown := (application ? inList(launchpadApplicationsList, application) : 0)
		
		GuiControl Text, launchpadApplicationDropDown, % "|" . values2String("|", launchpadApplicationsList*)
		
		if (application && (application != true))
			GuiControl Choose, launchpadApplicationDropDown, %application%
		else if (currentApplication && (application == true))
			GuiControl Choose, launchpadApplicationDropDown, %currentApplication%
	}
	
	loadEditor(item) {
		launchpadNumberEdit := item[1]
		launchpadLabelEdit := item[2]
		
		GuiControl Text, launchpadNumberEdit, %launchpadNumberEdit%
		GuiControl Text, launchpadLabelEdit, %launchpadLabelEdit%
		
		this.loadApplicationChoices(item[3])
	}
	
	clearEditor() {
		launchpadNumberEdit := 1
		launchpadLabelEdit := ""
		
		GuiControl Text, launchpadNumberEdit, %launchpadNumberEdit%
		GuiControl Text, launchpadLabelEdit, %launchpadLabelEdit%
		
		this.loadApplicationChoices()
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet launchpadNumberEdit
		GuiControlGet launchpadLabelEdit
		GuiControlGet launchpadApplicationDropDown
		
		if ((launchpadLabelEdit = "") || (launchpadApplicationDropDown = "")) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
			OnMessage(0x44, "")
			
			return false
		}
		else if isNew
			for ignore, item in this.iItemsList
				if (item[1] = launchpadNumberEdit) {
					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					title := translate("Error")
					MsgBox 262160, %title%, % translate("An application launcher for this button already exists - please use different values...")
					OnMessage(0x44, "")
			
					return false
				}
		
		return Array(launchpadNumberEdit, launchpadLabelEdit, launchpadApplicationDropDown)
	}
	
	updateItem() {
		launchApplication := this.buildItemFromEditor()
	
		if (launchApplication && (launchApplication[1] != this.iItemsList[this.iCurrentItemIndex][1])) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("The button number of an existing application launcher may not be changed...")
			OnMessage(0x44, "")
		}
		else
			base.updateItem()
	}
}

compareLaunchApplications(a1, a2) {
	return (a1[1] >= a2[1])
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ChatMessagesTab                                                         ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global chatMessagesListView = false
global chatMessageNumberEdit = 1
global chatMessageLabelEdit = ""
global chatMessageMessageEdit = ""
global chatMessageAddButton
global chatMessageDeleteButton
global chatMessageUpdateButton
		
class ChatMessagesTab extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "chatMessagesListView"
				 , "chatMessageAddButton", "chatMessageDeleteButton", "chatMessageUpdateButton")
				 
		ChatMessagesTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w457 h205 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndchatMessagesListViewHandle VchatMessagesListView glistEvent
							, % values2String("|", map(["#", "Label", "Text"], "translate")*)
		
		Gui SE:Add, Text, x16 y295 w86 h23 +0x200, % translate("Button")
		Gui SE:Add, Text, x95 y295 w23 h23 +0x200, % translate("#")
		Gui SE:Add, Edit, x110 y295 w40 h21 Number VchatMessageNumberEdit, %chatMessageNumberEdit%
		Gui SE:Add, UpDown, x150 y295 w17 h21, 1
		
		Gui SE:Add, Text, x16 y319 w86 h23 +0x200, % translate("Label")
		Gui SE:Add, Edit, x110 y319 w80 h21 VchatMessageLabelEdit, %chatMessageLabelEdit%
		
		Gui SE:Add, Text, x16 y343 w86 h23 +0x200, % translate("Message")
		Gui SE:Add, Edit, x110 y343 w363 h21 VchatMessageMessageEdit, %chatMessageMessageEdit%
		
		Gui SE:Add, Button, x264 y490 w46 h23 VchatMessageAddButton gaddItem, % translate("Add")
		Gui SE:Add, Button, x312 y490 w50 h23 Disabled VchatMessageDeleteButton gdeleteItem, % translate("Delete")
		Gui SE:Add, Button, x418 y490 w55 h23 Disabled VchatMessageUpdateButton gupdateItem, % translate("&Save")
		
		return chatMessagesListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		for descriptor, chatMessage in getConfigurationSectionValues(configuration, "Chat Messages", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			chatMessage := string2Values("|", chatMessage)

			this.iItemsList.Push(Array(descriptor[2], chatMessage[1], chatMessage[2]))
		}
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		for ignore, chatMessage in this.iItemsList
			setConfigurationValue(configuration, "Chat Messages", ConfigurationItem.descriptor("Button", chatMessage[1]), values2String("|", chatMessage[2], chatMessage[3]))	
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		bubbleSort(items, "compareChatMessages")
		
		this.iItemsList := items
		
		for ignore, chatMessage in items
			LV_Add("", chatMessage[1], chatMessage[2], chatMessage[3])
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(2, "AutoHdr")
			
			first := false
		}
	}
	
	loadEditor(item) {
		chatMessageNumberEdit := item[1]
		chatMessageLabelEdit := item[2]
		chatMessageMessageEdit := item[3]
			
		GuiControl Text, chatMessageNumberEdit, %chatMessageNumberEdit%
		GuiControl Text, chatMessageLabelEdit, %chatMessageLabelEdit%
		GuiControl Text, chatMessageMessageEdit, %chatMessageMessageEdit%
	}
	
	clearEditor() {
		chatMessageNumberEdit := 1
		chatMessageLabelEdit := ""
		chatMessageMessageEdit := ""
		
		GuiControl Text, chatMessageNumberEdit, %chatMessageNumberEdit%
		GuiControl Text, chatMessageLabelEdit, %chatMessageLabelEdit%
		GuiControl Text, chatMessageMessageEdit, %chatMessageMessageEdit%
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet chatMessageNumberEdit
		GuiControlGet chatMessageLabelEdit
		GuiControlGet chatMessageMessageEdit
		
		if ((chatMessageLabelEdit = "") || (chatMessageMessageEdit = "")) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
			OnMessage(0x44, "")
			
			return false
		}
		else if isNew
			for ignore, item in this.iItemsList
				if (item[1] = chatMessageNumberEdit) {
					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					title := translate("Error")
					MsgBox 262160, %title%, % translate("A chat message for this button already exists - please use different values...")
					OnMessage(0x44, "")
			
					return false
				}
		
		return Array(chatMessageNumberEdit, chatMessageLabelEdit, chatMessageMessageEdit)
	}
	
	updateItem() {
		chatMessage := this.buildItemFromEditor()
	
		if (chatMessage && (chatMessage[1] != this.iItemsList[this.iCurrentItemIndex][1])) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("The button number of an existing chat message may not be changed...")
			OnMessage(0x44, "")
		}
		else
			base.updateItem()
	}
}

compareChatMessages(c1, c2) {
	return (c1[1] >= c2[1])
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ThemesEditor                                                            ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global windowTitleEdit = ""
global windowSubtitleEdit = ""

class ThemesEditor extends ConfigurationItem {
	iClosed := false
	iThemesList := false
	
	__New(configuration) {
		base.__New(configuration)
		
		ThemesEditor.Instance := this
		
		this.createControls(configuration)
	}
	
	createControls(configuration) {
		Gui TE:Default
	
		Gui TE:-Border ; -Caption
		Gui TE:Color, D0D0D0

		Gui TE:Font, Bold, Arial

		Gui TE:Add, Text, w388 Center gmoveThemesEditor, % translate("Modular Simulator Controller System") 
		
		Gui TE:Font, Norm, Arial
		Gui TE:Font, Italic Underline, Arial

		Gui TE:Add, Text, YP+20 w388 cBlue Center gopenThemesDocumentation, % translate("Themes")

		Gui TE:Font, Norm, Arial
		
		Gui TE:Add, Text, x16 y48 w160 h23 +0x200, % translate("Upper Title")
		Gui TE:Add, Edit, x110 y48 w284 h21 VwindowTitleEdit, %windowTitleEdit%
		
		Gui TE:Add, Text, x16 y72 w160 h23 +0x200, % translate("Lower Title")
		Gui TE:Add, Edit, x110 y72 w284 h21 VwindowSubtitleEdit, %windowSubtitleEdit%
		
		Gui TE:Add, Text, x50 y106 w310 0x10
		
		this.iThemesList := new ThemesList(configuration)
		
		Gui TE:Add, Text, x50 y+10 w310 0x10
		
		Gui TE:Add, Button, x126 yp+10 w80 h23 Default GsaveThemesEditor, % translate("Save")
		Gui TE:Add, Button, x214 yp w80 h23 GcancelThemesEditor, % translate("&Cancel")
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		windowTitleEdit := getConfigurationValue(configuration, "Splash Window", "Title", "")
		windowSubtitleEdit := getConfigurationValue(configuration, "Splash Window", "Subtitle", "")
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		setConfigurationValue(configuration, "Splash Window", "Title", windowTitleEdit)
		setConfigurationValue(configuration, "Splash Window", "Subtitle", windowSubtitleEdit)
		
		this.iThemesList.saveToConfiguration(configuration)
	}
	
	editThemes() {
		this.iThemesList.clearEditor()
		
		Gui TE:Show, AutoSize Center
		
		Loop
			Sleep 200
		until this.iClosed
		
		try {
			if (this.iClosed == kOk) {
				configuration := newConfiguration()
				
				this.saveToConfiguration(configuration)
			
				return configuration
			}
			else
				return false
		}
		finally {
			Gui TE:Destroy
		}
	}
	
	closeEditor(save) {
		if save
			Gui TE:Submit
		
		this.iThemesList.togglePlaySoundFile(true)
		
		this.iClosed := (save ? kOk : kCancel)
	}
}

saveThemesEditor() {
	protectionOn()
	
	try {
		ThemesEditor.Instance.closeEditor(true)
	}
	finally {
		protectionOff()
	}
}

cancelThemesEditor() {
	protectionOn()
	
	try {
		ThemesEditor.Instance.closeEditor(false)
	}
	finally {
		protectionOff()
	}
}

moveThemesEditor() {
	moveByMouse("TE")
}

openThemesDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#themes-editor
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ThemesList                                                              ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global themesListView = false
global themeNameEdit = ""
global themeTypeDropDown = 0

global playSoundButtonHandle
global soundFilePathEdit = ""

global videoFilePathLabel
global videoFilePathEdit = ""
global videoFilePathButton

global picturesListLabel
global addPictureButton
global picturesListView
global picturesListViewHandle
global picturesListViewImages
global picturesDurationLabel
global picturesDurationEdit = 3000
global picturesDurationPostfix

global themeAddButton
global themeDeleteButton
global themeUpdateButton
		
class ThemesList extends ConfigurationItemList {
	iSoundIsPlaying := false
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "themesListView"
				 , "themeAddButton", "themeDeleteButton", "themeUpdateButton")
				 
		ThemesList.Instance := this
	}
					
	createControls(configuration) {
		Gui TE:Add, ListView, x16 y120 w377 h140 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndthemesListViewHandle VthemesListView glistEvent
							, % values2String("|", map(["Theme", "Media", "Sound File"], "translate")*)
		
		Gui TE:Add, Text, x16 y270 w86 h23 +0x200, % translate("Theme")
		Gui TE:Add, Edit, x110 y270 w140 h21 VthemeNameEdit, %themeNameEdit%
		
		Gui TE:Add, Text, x16 y294 w86 h23 +0x200, % translate("Type")
		Gui TE:Add, DropDownList, x110 y294 w140 AltSubmit VthemeTypeDropDown gupdateThemesEditorState, % translate("Picture Carousel") . "|" . translate("Video")
		
		Gui TE:Add, Text, x16 y318 w160 h23 +0x200, % translate("Sound File")
		Gui TE:Add, Button, x85 y317 w23 h23 HwndplaySoundButtonHandle gtogglePlaySoundFile
		setButtonIcon(playSoundButtonHandle, kIconsDirectory . "Start.ico", 1, "L2 T2 R2 B2")
		Gui TE:Add, Edit, x110 y318 w259 h21 VsoundFilePathEdit, %soundFilePathEdit%
		Gui TE:Add, Button, x371 y317 w23 h23 gchooseSoundFilePath, % translate("...")
		
		Gui TE:Add, Text, x16 y342 w80 h23 +0x200 VvideoFilePathLabel, % translate("Video")
		Gui TE:Add, Edit, x110 y342 w259 h21 VvideoFilePathEdit, %videoFilePathEdit%
		Gui TE:Add, Button, x371 y341 w23 h23 VvideoFilePathButton gchooseVideoFilePath, % translate("...")
		
		Gui TE:Add, Text, x16 y342 w80 h23 +0x200 VpicturesListLabel, % translate("Pictures")
		Gui TE:Add, Button, x85 y342 w23 h23 HwndaddPictureButtonHandle VaddPictureButton gaddThemePicture
		setButtonIcon(addPictureButtonHandle, kIconsDirectory . "Plus.ico", 1)
		Gui TE:Add, ListView, x110 y342 w284 h112 -Multi -LV0x10 Checked -Hdr NoSort NoSortHdr HwndpicturesListViewHandle VpicturesListView, % translate("Picture")	
		
		Gui TE:Add, Text, x16 y456 w80 h23 +0x200 VpicturesDurationLabel, % translate("Display Duration")
		Gui TE:Add, Edit, x110 y456 w40 h21 Limit5 Number VpicturesDurationEdit, %picturesDurationEdit%
		
		Gui TE:Font, Norm, Arial
		
		Gui TE:Add, Text, x154 y459 w40 h23 VpicturesDurationPostfix, % translate("ms")
	
		Gui TE:Add, Button, x184 y490 w46 h23 VthemeAddButton gaddItem, % translate("Add")
		Gui TE:Add, Button, x232 y490 w50 h23 Disabled VthemeDeleteButton gdeleteItem, % translate("Delete")
		Gui TE:Add, Button, x340 y490 w55 h23 Disabled VthemeUpdateButton gupdateItem, % translate("&Save")
		
		return themesListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		splashThemes := getConfigurationSectionValues(configuration, "Splash Themes", Object())
		themes := {}
		
		for descriptor, value in splashThemes {
			theme := StrSplit(descriptor, ".")[1]
			
			if !themes.HasKey(theme) {
				type := splashThemes[theme . ".Type"]
				media := ((type == ("Picture Carousel")) ? splashThemes[theme . ".Images"] : splashThemes[theme . ".Video"])
				duration := ((type == ("Picture Carousel")) ? splashThemes[theme . ".Duration"] : false)
				songFile := (splashThemes.HasKey(theme . ".Song") ? splashThemes[theme . ".Song"] : false)
				
				if !songFile
					songFile := ""
					
				themes[theme] := theme
				
				this.iItemsList.Push(Array(type, theme, media, songFile, duration))
			}
		}
	}
		
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		for index, theme in this.iItemsList {
			name := theme[2]
			type := theme[1]
			songFile := theme[4]
			
			setConfigurationValue(configuration, "Splash Themes", name . ".Type", type)
			
			if (songFile && (songFile != ""))
				setConfigurationValue(configuration, "Splash Themes", name . ".Song", songFile)
				
			if (type == "Picture Carousel") {
				setConfigurationValue(configuration, "Splash Themes", name . ".Images", theme[3])
				setConfigurationValue(configuration, "Splash Themes", name . ".Duration", theme[5])
			}
			else
				setConfigurationValue(configuration, "Splash Themes", name . ".Video", theme[3])
		}
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		for ignore, theme in items {
			songFile := theme[4]
			
			if (songFile != "") {
				SplitPath songFile, , , , nameNoExt

				songFile := nameNoExt
			}
			
			mediaFiles := []
			
			for ignore, mediaFile in string2Values(",", theme[3]) {
				SplitPath mediaFile, , , , nameNoExt

				mediaFiles.Push(nameNoExt)
			}
			
			LV_Add("", theme[2], values2String(", ", mediaFiles*), songFile)
		}
		
		if first {
			LV_ModifyCol(1, 100)
			LV_ModifyCol(2, 180)
			LV_ModifyCol(3, 100)
			
			first := false
		}
	}
	
	updateState() {
		base.updateState()
		
		GuiControlGet themeTypeDropDown
		
		if (themeTypeDropDown == 1) {
			GuiControl Show, picturesListLabel
			GuiControl Show, addPictureButton
			GuiControl Show, picturesListView
			GuiControl Show, picturesDurationLabel
			GuiControl Show, picturesDurationEdit
			GuiControl Show, picturesDurationPostfix
		}
		else {
			GuiControl Hide, picturesListLabel
			GuiControl Hide, addPictureButton
			GuiControl Hide, picturesListView
			GuiControl Hide, picturesDurationLabel
			GuiControl Hide, picturesDurationEdit
			GuiControl Hide, picturesDurationPostfix
		}
		
		if (themeTypeDropDown == 2) {
			GuiControl Show, videoFilePathLabel
			GuiControl Show, videoFilePathEdit
			GuiControl Show, videoFilePathButton
		}
		else {
			GuiControl Hide, videoFilePathLabel
			GuiControl Hide, videoFilePathEdit
			GuiControl Hide, videoFilePathButton
		}
	}
	
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
	
	clearEditor() {
		themeTypeDropDown := 0
		themeNameEdit := ""
		soundFilePathEdit := ""
		videoFilePathEdit := ""
		picturesDurationEdit := 3000
			
		GuiControl Choose, themeTypeDropDown, %themeTypeDropDown%
		GuiControl Text, themeNameEdit, %themeNameEdit%
		GuiControl Text, soundFilePathEdit, %soundFilePathEdit%
		GuiControl Text, videoFilePathEdit, %videoFilePathEdit%
		GuiControl Text, picturesDurationEdit, %picturesDurationEdit%
		
		this.initializePicturesList("")
		
		this.updateEditor()
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet themeNameEdit
		GuiControlGet themeTypeDropDown
		GuiControlGet soundFilePathEdit
		GuiControlGet picturesDurationEdit
		
		type := ""
		media := ""
		
		if (themeTypeDropDown == 1) {
			type := "Picture Carousel"
			pictures := []
			
			Gui ListView, % picturesListViewHandle
			
			rowNumber := 0
			
			Loop {
				rowNumber := LV_GetNext(rowNumber, "C")
				
				if !rowNumber
					break
					
				LV_GetText(fileName, rowNumber)
				
				pictures.Push(StrReplace(StrReplace(fileName, kUserSplashMediaDirectory, ""), kSplashMediaDirectory, ""))
			}
			
			media := values2String(", ", pictures*)
		}
		else if (themeTypeDropDown == 2) {
			type := "Video"
			
			GuiControlGet videoFilePathEdit
		
			media := videoFilePathEdit
		}
		else
			Goto error
		
		return Array(type, themeNameEdit, media, soundFilePathEdit, picturesDurationEdit)
		
error:
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
		title := translate("Error")
		MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
		OnMessage(0x44, "")
		
		return false
	}
	
	togglePlaySoundFile(stop := false) {
		if (stop || this.iSoundIsPlaying) {
			try {
				SoundPlay NonExistent.avi
			}
			catch ignore {
				; Ignore
			}
			
			setButtonIcon(playSoundButtonHandle, kIconsDirectory . "Start.ico", 1, "L2 T2 R2 B2")
			
			this.iSoundIsPlaying := false
		}
		else if !this.iSoundIsPlaying {
			try {
				songFile := getFileName(soundFilePathEdit, kUserSplashMediaDirectory, kSplashMediaDirectory)
				
				if FileExist(songFile) {
					SoundPlay %songFile%
				
					setButtonIcon(playSoundButtonHandle, kIconsDirectory . "Pause.ico", 1, "L7 T2 R2 B2")
					
					this.iSoundIsPlaying := true
				}
			}
			catch exception {
				; Ignore
			}
		}
	}
}

updateThemesEditorState() {
	protectionOn()
	
	try {
		vItemLists["themesListView"].updateState()
	}
	finally {
		protectionOff()
	}
}

togglePlaySoundFile() {
	protectionOn()
	
	try {
		ThemesList.Instance.togglePlaySoundFile()
	}
	finally {
		protectionOff()
	}
}

addThemePicture() {
	protectionOn()
	
	try {
		title := translate("Select Image...")
	
		FileSelectFile pictureFile, 1, , %title%, Image (*.jpg; *.gif)
		
		if (pictureFile != "") {
			Gui ListView, % picturesListViewHandle
			
			IL_Add(picturesListViewImages, LoadPicture(pictureFile, "W32 H32"), 0xFFFFFF, false)
			
			LV_Add("Check Icon" . (LV_GetCount() + 1), StrReplace(StrReplace(pictureFile, kUserSplashMediaDirectory, ""), kSplashMediaDirectory, ""))
			
			LV_ModifyCol()
			LV_Modify(LV_GetCount(), "Vis")
		}
	}
	finally {
		protectionOff()
	}
}

chooseSoundFilePath() {
	protectionOn()
	
	try {
		GuiControlGet soundFilePathEdit
		
		path := soundFilePathEdit
	
		if (path && (path != ""))
			path := getFileName(path, kUserSplashMediaDirectory, kSplashMediaDirectory)
		else
			path := SubStr(kUserSplashMediaDirectory, 1, StrLen(kUserSplashMediaDirectory) - 1)
		
		title := translate("Select Sound File...")
		
		FileSelectFile soundFile, 1, *%path%, %title%, Audio (*.wav; *.mp3)
		
		if (soundFile != "") {
			soundFilePathEdit := soundFile
			
			GuiControl Text, soundFilePathEdit, %soundFilePathEdit%
		}
	}
	finally {
		protectionOff()
	}
}

chooseVideoFilePath() {
	protectionOn()
	
	try {
		GuiControlGet videoFilePathEdit
		
		path := videoFilePathEdit
	
		if (path && (path != ""))
			path := getFileName(path, kUserSplashMediaDirectory, kSplashMediaDirectory)
		else
			path := SubStr(kUserSplashMediaDirectory, 1, StrLen(kUserSplashMediaDirectory) - 1)
		
		title := translate("Select Video (GIF) File...")
		
		FileSelectFile videoFile, 1, *%path%, %title%, Video (*.gif)
		
		if (videoFile != "") {
			videoFilePathEdit := videoFile
			
			GuiControl Text, videoFilePathEdit, %videoFilePathEdit%
		}
	}
	finally {
		protectionOff()
	}
}

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

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; TranslationsEditor                                                      ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global translationLanguageDropDown
global addLanguageButton
global deleteLanguageButton

global isoCodeEdit = ""
global languageNameEdit = ""

class TranslationsEditor extends ConfigurationItem {
	iLanguagesChanged := false
	iTranslationsList := false
	iClosed := false
	
	TranslationsList[] {
		Get {
			return this.iTranslationsList
		}
	}
	
	__New(configuration) {
		base.__New(configuration)
		
		TranslationsEditor.Instance := this
		
		this.createControls(configuration)
	}
	
	createControls(configuration) {
		Gui TE:Default
	
		Gui TE:-Border ; -Caption
		Gui TE:Color, D0D0D0

		Gui TE:Font, Bold, Arial

		Gui TE:Add, Text, w388 Center gmoveTranslationsEditor, % translate("Modular Simulator Controller System") 
		
		Gui TE:Font, Norm, Arial
		Gui TE:Font, Italic Underline, Arial

		Gui TE:Add, Text, YP+20 w388 cBlue Center gopenTranslationsDocumentation, % translate("Translations")

		Gui TE:Font, Norm, Arial
		
		Gui TE:Add, Text, x50 y+10 w310 0x10
		
		choices := []
		chosen := 0
		
		for code, language in availableLanguages() {
			choices.Push(language)
			
			if (language == languageDropDown) {
				chosen := A_Index
				
				isoCodeEdit := code
				languageNameEdit := language
			}
		}
			
		Gui TE:Add, Text, x16 w160 h23 +0x200, % translate("Language")
		Gui TE:Add, DropDownList, x184 yp w158 Choose%chosen% VtranslationLanguageDropDown gchooseTranslationLanguage, % values2String("|", choices*)
		Gui TE:Add, Button, x343 yp-1 w23 h23 HwndaddLanguageButtonHandle VaddLanguageButton gaddLanguage
		Gui TE:Add, Button, x368 yp w23 h23 HwnddeleteLanguageButtonHandle VdeleteLanguageButton gdeleteLanguage
		setButtonIcon(addLanguageButtonHandle, kIconsDirectory . "Plus.ico", 1)
		setButtonIcon(deleteLanguageButtonHandle, kIconsDirectory . "Minus.ico", 1)
		
		Gui TE:Add, Text, x16 w160 h23 +0x200, % translate("ISO Code / Identifier")
		Gui TE:Add, Edit, x184 yp w40 h21 Disabled VisoCodeEdit, %isoCodeEdit%
		Gui TE:Add, Edit, x236 yp w155 h21 Disabled VlanguageNameEdit, %languageNameEdit%
	
		this.iTranslationsList := new TranslationsList(configuration)
		
		Gui TE:Add, Text, x50 y+10 w310 0x10
		
		Gui TE:Add, Button, x166 yp+10 w80 h23 Default GcloseTranslationsEditor, % translate("Close")
	}
	
	editTranslations() {
		Gui TE:Show, AutoSize Center
		
		GuiControlGet isoCodeEdit
		
		this.iTranslationsList.loadTranslations((isoCodeEdit != "") ? isoCodeEdit : "en")
		
		Loop
			Sleep 200
		until this.iClosed
		
		try {
			return this.iLanguagesChanged
		}
		finally {
			Gui TE:Destroy
		}
	}
	
	saveTranslations() {
		if this.iTranslationsList.saveTranslations() {
			GuiControlGet isoCodeEdit
			GuiControlGet languageNameEdit
			
			choices := []
			chosen := 0
			found := false
			
			for code, language in availableLanguages() {
				choices.Push(language)
				
				if (code = isoCodeEdit) {
					chosen := A_Index
					found := true
				}
			}
			
			if !found {
				choices.Push(languageNameEdit)
				chosen := choices.Length()
			}
			
			GuiControl, , translationLanguageDropDown, % "|" . values2String("|", choices*)
			GuiControl Choose, translationLanguageDropDown, % chosen
		}
	}
	
	closeEditor() {
		this.saveTranslations()
		
		this.iClosed := true
	}
	
	addLanguage() {
		this.iLanguagesChanged := true
		this.saveTranslations()
		
		choices := []
		
		for ignore, language in availableLanguages()
			choices.Push(language)
		
		isoCodeEdit := "XX"
		languageNameEdit := translate("New Language")
		
		choices.Push(languageNameEdit)
			
		GuiControl, , translationLanguageDropDown, % "|" . values2String("|", choices*)
		GuiControl Choose, translationLanguageDropDown, % choices.Length()
		
		GuiControl Text, isoCodeEdit, %isoCodeEdit%
		GuiControl Text, languageNameEdit, %languageNameEdit%
		
		GuiControl Enable, isoCodeEdit
		GuiControl Enable, languageNameEdit
		
		this.iTranslationsList.newTranslations()
	}
	
	deleteLanguage() {
		GuiControlGet translationLanguageDropDown
		
		SoundPlay *32
	
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
		title := translate("Delete")
		MsgBox 262436, %title%, % translate("Do you really want to delete this translation?")
		OnMessage(0x44, "")

		IfMsgBox Yes
		{
			this.iLanguagesChanged := true
			
			languageCode := kUndefined

			for code, language in availableLanguages()
				if ((language = translationLanguageDropDown) && (code != "en"))
					languageCode := code
			
			if (languageCode != kUndefined)
				for ignore, fileName in getFileNames("Translations." . languageCode, kUserConfigDirectory, kConfigDirectory)
					try {
						FileDelete %fileName%
					}
					catch exception {
						; ignore
					}
			
			this.chooseLanguage("en")
		}
	}
	
	chooseLanguage(languageCode := false) {
		this.iTranslationsList.saveTranslations()
		
		availableLanguages := availableLanguages()
		
		if !languageCode {
			GuiControlGet translationLanguageDropDown
			
			for code, language in availableLanguages
				if (language = translationLanguageDropDown) {
					languageCode := code
					
					break
				}
		}
	
		choices := []
		
		for code, language in availableLanguages {
			choices.Push(language)
		
			if (code = languageCode) {
				isoCodeEdit := code
				languageNameEdit := language
		
				chosen := A_Index
			}
		}
				
		GuiControl, , translationLanguageDropDown, % "|" . values2String("|", choices*)
		GuiControl Choose, translationLanguageDropDown, %chosen%
		
		GuiControl Text, isoCodeEdit, %isoCodeEdit%
		GuiControl Text, languageNameEdit, %languageNameEdit%
		
		GuiControl Disable, isoCodeEdit
		GuiControl Disable, languageNameEdit
		
		this.iTranslationsList.loadTranslations(isoCodeEdit)
	}
}

addLanguage(){
	protectionOn()
	
	try {
		TranslationsEditor.Instance.addLanguage()
	}
	finally {
		protectionOff()
	}
}

deleteLanguage() {
	protectionOn()
	
	try {
		TranslationsEditor.Instance.deleteLanguage()
	}
	finally {
		protectionOff()
	}
}

closeTranslationsEditor() {
	protectionOn()
	
	try {
		TranslationsEditor.Instance.closeEditor()
	}
	finally {
		protectionOff()
	}
}

moveTranslationsEditor() {
	moveByMouse("TE")
}

chooseTranslationLanguage() {
	protectionOn()
	
	try {
		TranslationsEditor.Instance.chooseLanguage()
	}
	finally {
		protectionOff()
	}
}

openTranslationsDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#translations-editor
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; TranslationsList                                                        ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global translationsListView

global originalTextEdit = ""
global translationTextEdit = ""

global nextUntranslatedButtonHandle
		
class TranslationsList extends ConfigurationItemList {
	iChanged := false
	iLanguageCode := ""
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "translationsListView")
				 
		TranslationsList.Instance := this
	}
					
	createControls(configuration) {
		Gui TE:Add, ListView, x16 y+10 w377 h140 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndtranslationsListViewHandle VtranslationsListView glistEvent
							, % values2String("|", map(["Original", "Translation"], "translate")*)
		
		Gui TE:Add, Text, x16 w86 h23 +0x200, % translate("Original")
		Gui TE:Add, Edit, x110 yp w283 h80 Disabled VoriginalTextEdit, %originalTextEdit%
	
		Gui TE:Add, Text, x16 w86 h23 +0x200, % translate("Translation")
		Gui TE:Add, Button, x85 yp w23 h23 Default HwndnextUntranslatedButtonHandle gnextUntranslated
		setButtonIcon(nextUntranslatedButtonHandle, kIconsDirectory . "Down Arrow.ico", 1)
		Gui TE:Add, Edit, x110 yp w283 h80 VtranslationTextEdit, %translationTextEdit%
		
		return translationsListViewHandle
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
		
		count := LV_GetCount()
		
		for index, translation in this.iItemsList
			if (index <= count)
				LV_Modify(index, "", translation[1], translation[2])
			else
				LV_Add("", translation[1], translation[2])
		
		if (items.Length() < count)
			Loop % count - items.Length()
				LV_Delete(count - A_Index - 1)
			
		if (first || (this.iLanguageCode = "en")) {
			LV_ModifyCol()
			LV_ModifyCol(1, 150)
			LV_ModifyCol(2, 300)
			
			first := false
		}
	}
	
	updateState() {
		base.updateState()
	}
	
	loadEditor(item) {
		originalTextEdit := item[1]
		translationTextEdit := item[2]
		
		if (translationTextEdit == "")
			translationTextEdit := originalTextEdit
		
		GuiControl Text, originalTextEdit, %originalTextEdit%
		GuiControl Text, translationTextEdit, %translationTextEdit%
	}
	
	clearEditor() {
		originalTextEdit := ""
		translationTextEdit := ""
		
		GuiControl Text, originalTextEdit, %originalTextEdit%
		GuiControl Text, translationTextEdit, %translationTextEdit%
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet originalTextEdit
		GuiControlGet translationTextEdit
		
		translationTextEdit := (translationTextEdit == originalTextEdit) ? "" : translationTextEdit
		
		if isNew
			this.iChanged := true
		else
			this.iChanged := this.iChanged || (this.iItemsList[this.iCurrentItemIndex][2] != translationTextEdit)
		
		return Array(originalTextEdit, translationTextEdit)
	}
	
	openEditor(itemIndex) {
		if (this.iCurrentItemIndex != 0) {
			GuiControlGet translationTextEdit
			
			if (this.iItemsList[this.iCurrentItemIndex][2] != translationTextEdit)
				this.updateItem()
		}
			
		base.openEditor(itemIndex)
	}
	
	findNextUntranslated() {
		for index, translation in this.iItemsList
			if ((index > this.iCurrentItemIndex) && (translation[2] = ""))
				return index
		
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
		title := translate("Information")
		MsgBox 262192, %title%, % translate("There is no missing translation...")
		OnMessage(0x44, "")
		
		return false
	}
	
	newTranslations() {
		this.loadTranslations("en")
		
		this.iChanged := true
	}
	
	loadTranslations(languageCode) {
		this.iLanguageCode := languageCode
		
		this.iItemsList := []
		
		for original, translation in readTranslations(this.iLanguageCode)
			this.iItemsList.Push(Array(original, translation))
			
		this.loadList(this.iItemsList)
		this.clearEditor()
		
		this.iCurrentItemIndex := 0
		this.iChanged := false
	}
	
	saveTranslations() {
		if (this.iCurrentItemIndex != 0)
			this.updateItem()

		if this.iChanged {
			SoundPlay *32
		
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
			title := translate("Save")
			MsgBox 262436, %title%, % translate("Do you want to save your changes? Any existing translations will be overwritten.")
			OnMessage(0x44, "")

			IfMsgBox Yes
			{
				this.iChanged := false
				
				translations := {}
				
				GuiControlGet isoCodeEdit
				GuiControlGet languageNameEdit
				
				this.iLanguageCode := isoCodeEdit
				
				for ignore, item in this.iItemsList {
					original := item[1]
					translated := item[2]
				
					if (translations.HasKey(original) && (translated != translations[original])) {
						OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
						title := translate("Error")
						MsgBox 262160, %title%, % translate("Inconsistent translations detected - please correct...")
						OnMessage(0x44, "")
						
						return false
					}
						
					translations[original] := translated
				}
				
				writeTranslations(isoCodeEdit, languageNameEdit, translations)
				
				return true
			}
		}
		
		return false
	}
}

nextUntranslated() {
	protectionOn()
	
	try {
		list := TranslationsEditor.Instance.TranslationsList
		untranslated := list.findNextUntranslated()
		
		if untranslated
			list.openEditor(untranslated)
	}
	finally {
		protectionOff()
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ButtonBoxesEditor                                                       ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ButtonBoxesEditor extends ConfigurationItem {
	iControlsList := false
	iLabelsList := false
	iLayoutsList := false
	
	iName := ""
	iClosed := false
	
	iButtonBoxPreview := false
	iButtonBoxConfiguration := false
	
	iButtonBoxPreviewCenterX := 0
	iButtonBoxPreviewCenterY := 0
	
	ButtonBoxPreview[] {
		Get {
			return this.iButtonBoxPreview
		}
	}
	
	Name[] {
		Get {
			return this.iName
		}
	}
	
	ButtonBoxConfiguration[] {
		Get {
			return this.iButtonBoxConfiguration
		}
	}
	
	ButtonBoxPreviewCenterX[] {
		Get {
			return this.iButtonBoxPreviewCenterX
		}
	}
	
	ButtonBoxPreviewCenterY[] {
		Get {
			return this.iButtonBoxPreviewCenterY
		}
	}
	
	__New(name, configuration) {
		this.iName := name
		
		base.__New(configuration)
		
		ButtonBoxesEditor.Instance := this
		
		this.iButtonBoxConfiguration := readConfiguration(getFileName("Button Box Configuration.ini", kUserConfigDirectory, kConfigDirectory))
		
		this.createControls(this.iButtonBoxConfiguration)
	}
	
	saveToConfiguration(configuration, save := true) {
		if save
			base.saveToConfiguration(configuration)
		
		this.iControlsList.saveToConfiguration(configuration, save)
		this.iLabelsList.saveToConfiguration(configuration, save)
		this.iLayoutsList.saveToConfiguration(configuration, save)
	}
	
	createControls(configuration) {
		Gui BBE:Default
	
		Gui BBE:-Border ; -Caption
		
		Gui BBE:Color, D0D0D0
		Gui BBE:Font, Bold, Arial

		Gui BBE:Add, Text, x0 w432 Center gmoveButtonBoxesEditor, % translate("Modular Simulator Controller System") 
		
		Gui BBE:Font, Norm, Arial
		Gui BBE:Font, Italic Underline, Arial

		Gui BBE:Add, Text, x0 YP+20 w432 cBlue Center gopenButtonBoxesDocumentation, % translate("Button Box Layouts")
		
		this.iControlsList := new ControlsList(configuration)
		
		this.iLabelsList := new LabelsList(configuration)
		
		this.iLayoutsList := new LayoutsList(configuration)
		
		
		Gui BBE:Add, Text, x50 y615 w332 0x10
		
		Gui BBE:Add, Button, x130 y630 w80 h23 Default GsaveButtonBoxesEditor, % translate("Save")
		Gui BBE:Add, Button, x230 y630 w80 h23 GcancelButtonBoxesEditor, % translate("Cancel")
	}
	
	setButtonBoxPreviewPosition(centerX, centerY) {
		this.iButtonBoxPreviewCenterX := centerX
		this.iButtonBoxPreviewCenterY := centerY
	}
	
	editButtonBox() {
		Gui BBE:Show, AutoSize Center
		
		Loop
			Sleep 200
		until this.iClosed
		
		Gui BBE:Destroy
	}
	
	closeEditor(save) {
		if save {
			configuration := newConfiguration()
		
			this.saveToConfiguration(configuration)
			
			writeConfiguration(getFileName("Button Box Configuration.ini", kUserConfigDirectory), configuration)
		}
			
		this.saveButtonBox()
		
		if this.ButtonBoxPreview {
			this.ButtonBoxPreview.close()
			
			this.iButtonBoxPreview := false
		}
		
		this.iClosed := true
	}
	
	updateButtonBoxPreview(name) {
		configuration := newConfiguration()
		
		this.saveToConfiguration(configuration, false)
		
		this.iButtonBoxConfiguration := configuration
		
		oldPreview := this.ButtonBoxPreview
		
		if name {
			this.iButtonBoxPreview := new ButtonBoxPreview(this, name, configuration)
		
			this.ButtonBoxPreview.open()
		}
		else
			this.iButtonBoxPreview := false
		
		if oldPreview
			oldPreview.close()
	}
}

saveButtonBoxesEditor() {
	protectionOn()
	
	try {
		ButtonBoxesEditor.Instance.closeEditor(true)
	}
	finally {
		protectionOff()
	}
}

cancelButtonBoxesEditor() {
	protectionOn()
	
	try {
		ButtonBoxesEditor.Instance.closeEditor(false)
	}
	finally {
		protectionOff()
	}
}

moveButtonBoxesEditor() {
	moveByMouse("BBE")
}

openButtonBoxesDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#button-box-layouts
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ControlsList                                                            ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global controlsListView := "|"

global controlNameEdit = ""
global controlTypeDropDown = 0
global imageFilePathEdit = ""
global imageWidthEdit = 0
global imageHeightEdit = 0

global controlAddButton
global controlDeleteButton
global controlUpdateButton
		
class ControlsList extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "controlsListView"
				 , "controlAddButton", "controlDeleteButton", "controlUpdateButton")
				 
		ControlsList.Instance := this
		
		this.clearEditor()
	}
					
	createControls(configuration) {
		Gui BBE:Font, Norm, Arial
		Gui BBE:Font, Italic, Arial
		
		Gui BBE:Add, GroupBox, x8 y60 w424 h138, % translate("Controls")
		
		Gui BBE:Font, Norm, Arial
		Gui BBE:Add, ListView, x16 y79 w134 h108 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndcontrolsListViewHandle VcontrolsListView glistEvent
							 , % values2String("|", map(["Name", "Function", "Size"], "translate")*)
							
		Gui BBE:Add, Text, x164 y79 w80 h23 +0x200, % translate("Name")
		Gui BBE:Add, Edit, x214 y80 w101 h21 VcontrolNameEdit, %controlNameEdit%
		Gui BBE:Add, DropDownList, x321 y79 w105 AltSubmit Choose%controlTypeDropDown% VcontrolTypeDropDown, % values2String("|", map(["1-way Toggle", "2-way Toggle", "Button", "Dial"], "translate")*)
		;426 400 
		Gui BBE:Add, Text, x164 y103 w80 h23 +0x200, % translate("Image")
		Gui BBE:Add, Edit, x214 y103 w186 h21 VimageFilePathEdit, %imageFilePathEdit%
		Gui BBE:Add, Button, x403 y103 w23 h23 gchooseImageFilePath, % translate("...")
		
		Gui BBE:Add, Text, x164 y127 w80 h23 +0x200, % translate("Size")
		Gui BBE:Add, Edit, x214 y127 w40 h21 Limit3 Number VimageWidthEdit, %imageWidthEdit%
		Gui BBE:Add, Text, x254 y127 w21 h23 +0x200 Center, % translate("x")
		Gui BBE:Add, Edit, x275 y127 w40 h21 Limit3 Number VimageHeightEdit, %imageHeightEdit%
		
		Gui BBE:Add, Button, x226 y164 w46 h23 VcontrolAddButton gaddItem, % translate("Add")
		Gui BBE:Add, Button, x275 y164 w50 h23 Disabled VcontrolDeleteButton gdeleteItem, % translate("Delete")
		Gui BBE:Add, Button, x371 y164 w55 h23 Disabled VcontrolUpdateButton gupdateItem, % translate("Save")
		
		return controlsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		controls := []
		
		for name, definition in getConfigurationSectionValues(configuration, "Controls", Object())
			controls.Push(Array(name, string2Values(";", definition)*))
		
		this.iItemsList := controls
	}
		
	saveToConfiguration(configuration, save := true) {
		if save
			base.saveToConfiguration(configuration)
		
		controls := {}
		
		for ignore, control in this.iItemsList
			controls[control[1]] := values2String(";", control[2], control[3], control[4])
		
		setConfigurationSectionValues(configuration, "Controls", controls)	
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		this.iItemsList := items
		
		for ignore, control in items
			LV_Add("", control[1], control[2], control[4])
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(1, "AutoHdr")
			LV_ModifyCol(2, "AutoHdr")
			LV_ModifyCol(3, "AutoHdr")
			
			first := false
		}
		
		ButtonBoxesEditor.Instance.updateButtonBoxPreview(LayoutsList.Instance.CurrentButtonBox)
	}
	
	loadEditor(item) {
		controlNameEdit := item[1]
		imageFilePathEdit := item[3]
		
		size := string2Values("x", item[4])
		
		imageWidthEdit := size[1]
		imageHeightEdit := size[2]
			
		controlTypeDropDown := inList([k1WayToggleType, k2WayToggleType, kButtonType, kDialType], item[2])
		
		GuiControl Text, controlNameEdit, %controlNameEdit%
		GuiControl Choose, controlTypeDropDown, %controlTypeDropDown%
		GuiControl Text, imageFilePathEdit, %imageFilePathEdit%
		GuiControl Text, imageWidthEdit, %imageWidthEdit%
		GuiControl Text, imageHeightEdit, %imageHeightEdit%
	}
	
	clearEditor() {
		this.loadEditor(Array("", "", "", ""))
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet controlNameEdit
		GuiControlGet controlTypeDropDown
		GuiControlGet imageFilePathEdit
		GuiControlGet imageWidthEdit
		GuiControlGet imageHeightEdit
		
		if ((controlNameEdit = "") || !inList([1, 2, 3, 4], controlTypeDropDown) || (imageFilePathEdit = "")  || (imageWidthEdit = 0) || (imageHeightEdit = 0)) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
			OnMessage(0x44, "")
			
			return false
		}
		else
			return Array(controlNameEdit, [k1WayToggleType, k2WayToggleType, kButtonType, kDialType][controlTypeDropDown], imageFilePathEdit, imageWidthEdit . " x " . imageHeightEdit)
	}
	
	getControls() {
		if ConfigurationEditor.Instance.AutoSave {
			if (this.iCurrentItemIndex != 0) {
				this.updateItem()
			}
		}
		
		controls := {}
		
		for ignore, control in this.iItemsList
			controls[control[1]] := values2String(";", control[2], control[3], control[4])
		
		return controls
	}
}

chooseImageFilePath() {
	protectionOn()
	
	try {
		GuiControlGet imageFilePathEdit
		
		path := imageFilePathEdit
	
		if (path && (path != ""))
			path := getFileName(path, kButtonBoxImagesDirectory)
		else
			path := SubStr(kButtonBoxImagesDirectory, 1, StrLen(kButtonBoxImagesDirectory) - 1)
		
		title := translate("Select Image...")
	
		FileSelectFile pictureFile, 1, , %title%, Image (*.jpg; *.png; *.gif)
		
		if (pictureFile != "") {
			imageFilePathEdit := pictureFile
			
			GuiControl Text, imageFilePathEdit, %imageFilePathEdit%
		}
	}
	finally {
		protectionOff()
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; LabelsList                                                              ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global labelsListView := "|"

global labelNameEdit = ""
global labelWidthEdit = 0
global labelHeightEdit = 0

global labelAddButton
global labelDeleteButton
global labelUpdateButton
		
class LabelsList extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "labelsListView"
				 , "labelAddButton", "labelDeleteButton", "labelUpdateButton")
				 
		LabelsList.Instance := this
		
		this.clearEditor()
	}
					
	createControls(configuration) {
		Gui BBE:Font, Norm, Arial
		Gui BBE:Font, Italic, Arial
		
		Gui BBE:Add, GroupBox, x8 y205 w424 h115, % translate("Labels")
		
		Gui BBE:Font, Norm, Arial
		Gui BBE:Add, ListView, x16 y224 w134 h84 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndlabelsListViewHandle VlabelsListView glistEvent
							 , % values2String("|", map(["Name", "Size"], "translate")*)
							
		Gui BBE:Add, Text, x164 y224 w80 h23 +0x200, % translate("Name")
		Gui BBE:Add, Edit, x214 y225 w101 h21 VlabelNameEdit, %labelNameEdit%
		
		Gui BBE:Add, Text, x164 y248 w80 h23 +0x200, % translate("Size")
		Gui BBE:Add, Edit, x214 y248 w40 h21 Limit3 Number VlabelWidthEdit, %labelWidthEdit%
		Gui BBE:Add, Text, x254 y248 w21 h23 +0x200 Center, % translate("x")
		Gui BBE:Add, Edit, x275 y248 w40 h21 Limit3 Number VlabelHeightEdit, %labelHeightEdit%
		
		Gui BBE:Add, Button, x226 y285 w46 h23 VlabelAddButton gaddItem, % translate("Add")
		Gui BBE:Add, Button, x275 y285 w50 h23 Disabled VlabelDeleteButton gdeleteItem, % translate("Delete")
		Gui BBE:Add, Button, x371 y285 w55 h23 Disabled VlabelUpdateButton gupdateItem, % translate("Save")
		
		return labelsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		labels := []
		
		for name, definition in getConfigurationSectionValues(configuration, "Labels", Object())
			labels.Push(Array(name, definition))
		
		this.iItemsList := labels
	}
		
	saveToConfiguration(configuration, save := true) {
		if save
			base.saveToConfiguration(configuration)
		
		labels := {}
		
		for ignore, label in this.iItemsList
			labels[label[1]] := label[2]
		
		setConfigurationSectionValues(configuration, "Labels", labels)	
	}
	
	loadList(items) {
		static first := true
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		this.iItemsList := items
		
		for ignore, label in items
			LV_Add("", label[1], label[2])
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(1, "AutoHdr")
			LV_ModifyCol(2, "AutoHdr")
			
			first := false
		}
		
		ButtonBoxesEditor.Instance.updateButtonBoxPreview(LayoutsList.Instance.CurrentButtonBox)
	}
	
	loadEditor(item) {
		labelNameEdit := item[1]
		
		size := string2Values("x", item[2])
		
		labelWidthEdit := size[1]
		labelHeightEdit := size[2]
		
		GuiControl Text, labelNameEdit, %labelNameEdit%
		GuiControl Text, labelWidthEdit, %labelWidthEdit%
		GuiControl Text, labelHeightEdit, %labelHeightEdit%
	}
	
	clearEditor() {
		this.loadEditor(Array("", ""))
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet labelNameEdit
		GuiControlGet labelWidthEdit
		GuiControlGet labelHeightEdit
		
		if ((labelNameEdit = "") || (labelWidthEdit = 0) || (labelHeightEdit = 0)) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
			OnMessage(0x44, "")
			
			return false
		}
		else
			return Array(labelNameEdit, labelWidthEdit . " x " . labelHeightEdit)
	}
	
	getLabels() {
		if ConfigurationEditor.Instance.AutoSave {
			if (this.iCurrentItemIndex != 0) {
				this.updateItem()
			}
		}
		
		labels := {}
		
		for ignore, label in this.iItemsList
			labels[label[1]] := label[2]
		
		return labels
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; LayoutsList                                                             ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global layoutsListView := "|"

global layoutNameEdit = ""

global layoutRowsEdit = ""
global layoutColumnsEdit = ""
global layoutRowMarginEdit = ""
global layoutColumnMarginEdit = ""
global layoutSidesMarginEdit = ""
global layoutBottomMarginEdit = ""

global layoutRowDropDown = 0
global layoutRowEdit = ""

global layoutAddButton
global layoutDeleteButton
global layoutUpdateButton
		
class LayoutsList extends ConfigurationItemList {
	iRowDefinitions := []
	iSelectedRow := false
	
	CurrentButtonBox[] {
		Get {
			return ((this.iCurrentItemIndex != 0) ? this.iItemsList[this.iCurrentItemIndex][1] : false)
		}
	}
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "layoutsListView"
				 , "layoutAddButton", "layoutDeleteButton", "layoutUpdateButton")
				 
		LayoutsList.Instance := this
		
		this.clearEditor()
	}

	createControls(configuration) {
		Gui BBE:Add, ListView, x8 y330 w424 h105 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HwndlayoutsListViewHandle VlayoutsListView glistEvent
							 , % values2String("|", map(["Name", "Grid", "Margins", "Definition"], "translate")*)
		
		Gui BBE:Add, Text, x8 y445 w86 h23 +0x200, % translate("Name")
		Gui BBE:Add, Edit, x102 y445 w110 h21 VlayoutNameEdit, %layoutNameEdit%
		
		Gui BBE:Add, Text, x8 y469 w86 h23 +0x200, % translate("Layout")
		Gui BBE:Font, c505050 s7
		Gui BBE:Add, Text, x16 y490 w133 h21, % translate("(R x C, Margins)")
		Gui BBE:Font
		
		Gui BBE:Add, Edit, x102 y469 w40 h21 Limit1 Number gupdateLayoutRowEditor VlayoutRowsEdit, %layoutRowsEdit%
		Gui BBE:Add, UpDown, x125 y469 w17 h21, 1
		Gui BBE:Add, Text, x147 y469 w20 h23 +0x200 Center, % translate("x")
		Gui BBE:Add, Edit, x172 y469 w40 h21 Limit1 Number gupdateLayoutRowEditor VlayoutColumnsEdit, %layoutColumnsEdit%
		Gui BBE:Add, UpDown, x195 y469 w17 h21, 1
		
		Gui BBE:Font, c505050 s7
		
		Gui BBE:Add, Text, x242 y450 w40 h23 +0x200 Center, % translate("Row")
		Gui BBE:Add, Text, x292 y450 w40 h23 +0x200 Center, % translate("Column")
		Gui BBE:Add, Text, x342 y450 w40 h23 +0x200 Center, % translate("Sides")
		Gui BBE:Add, Text, x392 y450 w40 h23 +0x200 Center, % translate("Bottom")
		
		Gui BBE:Font
		
		Gui BBE:Add, Edit, x242 y469 w40 h21 Limit2 Number gupdateLayoutRowEditor VlayoutRowMarginEdit, %layoutRowMarginEdit%
		Gui BBE:Add, Edit, x292 y469 w40 h21 Limit2 Number gupdateLayoutRowEditor VlayoutColumnMarginEdit, %layoutColumnMarginEdit%
		Gui BBE:Add, Edit, x342 y469 w40 h21 Limit2 Number gupdateLayoutRowEditor VlayoutSidesMarginEdit, %layoutSidesMarginEdit%
		Gui BBE:Add, Edit, x392 y469 w40 h21 Limit2 Number gupdateLayoutRowEditor VlayoutBottomMarginEdit, %layoutBottomMarginEdit%
		
		Gui BBE:Add, DropDownList, x8 y510 w86 AltSubmit Choose0 gupdateLayoutRowEditor VlayoutRowDropDown, |
		
		Gui BBE:Add, Edit, x102 y510 w330 h50 Disabled VlayoutRowEdit, %layoutRowEdit%
		
		Gui BBE:Add, Button, x223 y575 w46 h23 VlayoutAddButton gaddItem, % translate("Add")
		Gui BBE:Add, Button, x271 y575 w50 h23 Disabled VlayoutDeleteButton gdeleteItem, % translate("Delete")
		Gui BBE:Add, Button, x377 y575 w55 h23 Disabled VlayoutUpdateButton gupdateItem, % translate("&Save")
		
		return layoutsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		layouts := {}
		
		for descriptor, definition in getConfigurationSectionValues(configuration, "Layouts", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			name := descriptor[1]
			
			if !layouts.HasKey(name)
				layouts[name] := Object()
			
			if (descriptor[2] = "Layout") {
				definition := string2Values(",", definition)
	
				rowMargin := ((definition.Length() > 1) ? definition[2] : ButtonBoxPreview.kRowMargin)
				columnMargin := ((definition.Length() > 2) ? definition[3] : ButtonBoxPreview.kColumnMargin)
				sidesMargin := ((definition.Length() > 3) ? definition[4] : ButtonBoxPreview.kSidesMargin)
				bottomMargin := ((definition.Length() > 4) ? definition[5] : ButtonBoxPreview.kBottomMargin)
				
				layouts[name]["Grid"] := definition[1]
				layouts[name]["Margins"] := Array(rowMargin, columnMargin, sidesMargin, bottomMargin)
			}
			else
				layouts[name][descriptor[2]] := definition
		}
		
		items := []
		
		for name, definition in layouts
			items.Push(Array(name, definition))
		
		this.iItemsList := items
	}
		
	saveToConfiguration(configuration, save := true) {
		if save
			base.saveToConfiguration(configuration)
		
		for ignore, layout in this.iItemsList {
			grid := layout[2]["Grid"]
			
			setConfigurationValue(configuration, "Layouts", ConfigurationItem.descriptor(layout[1], "Layout")
								, grid . ", " . values2String(", ", layout[2]["Margins"]*))
								
			Loop % string2Values("x", grid)[1]
				setConfigurationValue(configuration, "Layouts", ConfigurationItem.descriptor(layout[1], A_Index), layout[2][A_Index])
		}
	}
	
	loadList(items) {
		static first := true
		static inCall := false
		
		Gui ListView, % this.ListHandle
		
		LV_Delete()
		
		this.iItemsList := items
		
		for ignore, layout in items {
			grid := layout[2]["Grid"]
		
			definition := ""
			
			Loop % string2Values("x", grid)[1]
			{
				if (A_Index > 1)
					definition .= "; "
				
				definition .= (A_Index . ": " . layout[2][A_Index])
			}
			
			LV_Add("", layout[1], grid, values2String(", ", layout[2]["Margins"]*), definition)
		}
		
		if first {
			LV_ModifyCol()
			LV_ModifyCol(1, "AutoHdr")
			LV_ModifyCol(2, "AutoHdr")
			LV_ModifyCol(3, "AutoHdr")
			LV_ModifyCol(4, "AutoHdr")
			
			first := false
		}
		
		ButtonBoxesEditor.Instance.updateButtonBoxPreview(LayoutsList.Instance.CurrentButtonBox)
	}
	
	loadEditor(item) {
		layoutNameEdit := item[1]
		
		size := string2Values("x", item[2]["Grid"])
		
		layoutRowsEdit := size[1]
		layoutColumnsEdit := size[2]
		
		margins := item[2]["Margins"]
		
		layoutRowMarginEdit := margins[1]
		layoutColumnMarginEdit := margins[2]
		layoutSidesMarginEdit := margins[3]
		layoutBottomMarginEdit := margins[4]
		
		GuiControl Text, layoutNameEdit, %layoutNameEdit%
		GuiControl Text, layoutRowsEdit, %layoutRowsEdit%
		GuiControl Text, layoutColumnsEdit, %layoutColumnsEdit%
		GuiControl Text, layoutRowMarginEdit, %layoutRowMarginEdit%
		GuiControl Text, layoutColumnMarginEdit, %layoutColumnMarginEdit%
		GuiControl Text, layoutSidesMarginEdit, %layoutSidesMarginEdit%
		GuiControl Text, layoutBottomMarginEdit, %layoutBottomMarginEdit%
		
		choices := []
		rowDefinitions := []
		
		Loop %layoutRowsEdit% {
			choices.Push(translate("Row ") . A_Index)
		
			rowDefinitions.Push(item[2][A_Index])
		}
		
		this.iRowDefinitions := rowDefinitions
		
		GuiControl Text, layoutRowDropDown, % "|" . values2String("|", choices*)
		
		if (choices.Length() > 0) {
			GuiControl Choose, layoutRowDropDown, 1
			
			layoutRowEdit := (rowDefinitions.HasKey(1) ? rowDefinitions[1] : "")
			
			this.iSelectedRow := 1
		}
		else {
			GuiControl Choose, layoutRowDropDown, 0
		
			layoutRowEdit := ""
			
			this.iSelectedRow := false
		}
			
		GuiControl Text, layoutRowEdit, %layoutRowEdit%
		
		preview := ButtonBoxesEditor.Instance.ButtonBoxPreview
		
		if ((this.CurrentButtonBox != layoutNameEdit) || (!preview && (layoutNameEdit != "")) || (preview && (preview.Name != layoutNameEdit)))
			ButtonBoxesEditor.Instance.updateButtonBoxPreview(layoutNameEdit)
	}
	
	addItem() {
		base.addItem()
		
		GuiControl Text, layoutRowEdit, %layoutRowEdit%
		
		preview := ButtonBoxesEditor.Instance.ButtonBoxPreview
		
		if ((this.CurrentButtonBox != layoutNameEdit) || (!preview && (layoutNameEdit != "")) || (preview && (preview.Name != layoutNameEdit)))
			ButtonBoxesEditor.Instance.updateButtonBoxPreview(this.CurrentButtonBox)
	}
	
	clearEditor() {
		this.loadEditor(Array("", {Grid: "0x0", Margins: [0,0,0,0]}))
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet layoutNameEdit
		GuiControlGet layoutRowsEdit
		GuiControlGet layoutColumnsEdit
		GuiControlGet layoutRowMarginEdit
		GuiControlGet layoutColumnMarginEdit
		GuiControlGet layoutSidesMarginEdit
		GuiControlGet layoutBottomMarginEdit
		
		GuiControlGet layoutRowDropDown
		GuiControlGet layoutRowEdit
		
		if ((layoutNameEdit = "") || (layoutRowsEdit = 0) || (layoutColumnsEdit = 0)) {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			title := translate("Error")
			MsgBox 262160, %title%, % translate("Invalid values detected - please correct...")
			OnMessage(0x44, "")
			
			return false
		}
		else {
			if (layoutRowDropDown > 0)
				this.iRowDefinitions[layoutRowDropDown] := layoutRowEdit
			
			layout := {Grid: layoutRowsEdit . " x " . layoutColumnsEdit
					 , Margins: Array(layoutRowMarginEdit, layoutColumnMarginEdit, layoutSidesMarginEdit, layoutBottomMarginEdit)}
			
			Loop % this.iRowDefinitions.Length()
				layout[A_Index] := this.iRowDefinitions[A_Index]
				
			return Array(layoutNameEdit, layout)
		}
	}
	
	updateLayoutRowEditor(save := true) {
		Gui BBE:Default
		
		GuiControlGet layoutRowsEdit
		GuiControlGet layoutRowDropDown
		GuiControlGet layoutRowEdit
		
		if (save && (this.iSelectedRow > 0))
			this.iRowDefinitions[this.iSelectedRow] := layoutRowEdit
			
		rows := this.iRowDefinitions.Length()
		changed := false
		
		if (layoutRowsEdit > rows) {
			Loop % layoutRowsEdit - rows
				this.iRowDefinitions.Push("")
			
			changed := true
		}
		else if (layoutRowsEdit < rows) {
			this.iRowDefinitions.RemoveAt(layoutRowsEdit + 1, rows - layoutRowsEdit)
			
			changed := true
		}
		
		Loop %layoutRowsEdit%
			this.iRowDefinitions[A_Index] := values2String(";", this.getRowDefinition(A_Index)*)
		
		if (layoutRowDropDown > 0) {
			layoutRowEdit := ((this.iRowDefinitions.Length() >= layoutRowDropDown) ? this.iRowDefinitions[layoutRowDropDown] : "")
			
			this.iSelectedRow := layoutRowDropDown
			
			GuiControl Text, layoutRowEdit, %layoutRowEdit%
		}

		if changed {
			choices := []
		
			Loop %layoutRowsEdit%
				choices.Push(translate("Row ") . A_Index)
		
			GuiControl Text, layoutRowDropDown, % "|" . values2String("|", choices*)
			
			if (layoutRowsEdit > 0) {
				layoutRowDropDown := 1
				
				GuiControl Choose, layoutRowDropDown, 1
				
				layoutRowEdit := this.iRowDefinitions[1]
			}
			else {
				layoutRowDropDown := 0
				
				GuiControl Choose, layoutRowDropDown, 0
				
				layoutRowEdit := ""
			}

			this.iSelectedRow := layoutRowDropDown
			
			GuiControl Text, layoutRowEdit, %layoutRowEdit%
		}
		
		if (save && ConfigurationEditor.Instance.AutoSave) {
			if (this.iCurrentItemIndex != 0) {
				this.updateItem()
			}
		}
	}
	
	getRowDefinition(row) {
		rowDefinition := string2Values(";", this.iRowDefinitions[row])
		
		GuiControlGet layoutColumnsEdit
		
		if (rowDefinition.Length() > layoutColumnsEdit)
			rowDefinition.RemoveAt(layoutColumnsEdit + 1, rowDefinition.Length() - layoutColumnsEdit)
		else
			Loop % layoutColumnsEdit - rowDefinition.Length()
				rowDefinition.Push("")
		
		return rowDefinition
	}
	
	setRowDefinition(row, rowDefinition) {
		this.iRowDefinitions[row] := values2String(";", rowDefinition*)
		
		this.updateLayoutRowEditor(false)
		
		this.updateItem()
		
		ButtonBoxesEditor.Instance.updateButtonBoxPreview(this.CurrentButtonBox)
	}
	
	changeControl(row, column, control, number := false) {
		rowDefinition := this.getRowDefinition(row)
		
		definition := string2Values(",", rowDefinition[column])
		
		if (control = "__Number__") {
			if !number {
				title := translate("Function Number")
				prompt := translate("Please enter a controller function number:")
				number := ConfigurationItem.splitDescriptor(definition[1])[2]
				locale := ((getLanguage() = "en") ? "" : "Locale")
				
				InputBox number, %title%, %prompt%, , 200, 150, , , %locale%, , %number%
			
				if ErrorLevel
					return
			}
			
			if (definition.Length() = 1)
				definition := ConfigurationItem.descriptor(ConfigurationItem.splitDescriptor(definition[1])[1], number)
			else
				definition := (ConfigurationItem.descriptor(ConfigurationItem.splitDescriptor(definition[1])[1], number) . "," . definition[2])
		}
		else if control {
			if (definition.Length() = 0)
				definition := ConfigurationItem.descriptor(control, 1)
			else if (definition.Length() = 1)
				definition := ConfigurationItem.descriptor(control, ConfigurationItem.splitDescriptor(definition[1])[2])
			else
				definition := (ConfigurationItem.descriptor(control, ConfigurationItem.splitDescriptor(definition[1])[2]) . "," . definition[2])
		}
		else
			definition := ""
		
		rowDefinition[column] := definition
		
		this.setRowDefinition(row, rowDefinition)
	}
	
	changeLabel(row, column, label) {
		rowDefinition := this.getRowDefinition(row)
		
		definition := string2Values(",", rowDefinition[column])
		
		if (definition.Length() = 0)
			definition := (label ? ("," . label) : "")
		else if (definition.Length() >= 1)
			definition := (definition[1] . (label ? ("," . label) : ""))
		
		rowDefinition[column] := definition
		
		this.setRowDefinition(row, rowDefinition)
	}
}

updateLayoutRowEditor() {
	protectionOn()
	
	try {
		vItemLists["layoutsListView"].updateLayoutRowEditor()
	}
	catch exception {
		; ignore
	}
	finally {
		protectionOff()
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ButtonBoxPreview                                                        ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ButtonBoxPreview extends ConfigurationItem {
	static kHeaderHeight := 70
	static kLabelMargin := 5
	
	static kRowMargin := 20
	static kColumnMargin := 40
	
	static kSidesMargin := 20
	static kBottomMargin := 15
	
	static sCurrentWindow := 0
	
	iEditor := false
	iName := ""
	
	iWindow := false
	
	iWidth := 0
	iHeight := 0
	
	iRows := 0
	iColumns := 0
	iRowMargin := this.kRowMargin
	iColumnMargin := this.kColumnMargin
	iSidesMargin := this.kSidesMargin
	iBottomMargin := this.kBottomMargin
	
	iRowDefinitions := []
	iControls := {}
	
	Editor[] {
		Get {
			return this.iEditor
		}
	}
	
	Name[] {
		Get {
			return this.iName
		}
	}
	
	Window[] {
		Get {
			return this.iWindow
		}
	}
	
	CurrentWindow[] {
		Get {
			return ("BBP" . ButtonBoxPreview.sCurrentWindow)
		}
	}
	
	Width[] {
		Get {
			return this.iWidth
		}
	}
	
	Height[] {
		Get {
			return this.iHeight
		}
	}
	
	Rows[] {
		Get {
			return this.iRows
		}
	}
	
	Columns[] {
		Get {
			return this.iColumns
		}
	}
	
	RowMargin[] {
		Get {
			return this.iRowMargin
		}
	}
	
	ColumnMargin[] {
		Get {
			return this.iColumnMargin
		}
	}
	
	SidesMargin[] {
		Get {
			return this.iSidesMargin
		}
	}
	
	BottomMargin[] {
		Get {
			return this.iBottomMargin
		}
	}
	
	RowDefinitions[row := false] {
		Get {
			if row
				return this.iRowDefinitions[row]
			else
				return this.iRowDefinitions
		}
	}
	
	__New(editor, name, configuration) {
		this.iEditor := editor
		this.iName := name
		
		ButtonBoxPreview.sCurrentWindow += 1
		
		this.iWindow := this.CurrentWindow
		
		base.__New(configuration)
		
		this.createControls(configuration)
	}
	
	loadFromConfiguration(configuration) {
		layout := string2Values(",", getConfigurationValue(configuration, "Layouts", ConfigurationItem.descriptor(this.Name, "Layout"), ""))
		
		if (layout.Length() > 1)
			this.iRowMargin := layout[2]
		
		if (layout.Length() > 2)
			this.iColumnMargin := layout[3]
		
		if (layout.Length() > 3)
			this.iSidesMargin := layout[4]
		
		if (layout.Length() > 4)
			this.iBottomMargin := layout[5]
		
		layout := string2Values("x", layout[1])
		
		this.iRows := layout[1]
		this.iColumns := layout[2]
		
		rows := []
		
		Loop % this.Rows
			rows.Push(string2Values(";", getConfigurationValue(configuration, "Layouts", ConfigurationItem.descriptor(this.Name, A_Index), "")))
		
		this.iRowDefinitions := rows
	}
	
	createControls(configuration) {
		local function
		
		rowHeights := false
		columnWidths := false
		
		this.computeLayout(rowHeights, columnWidths)
		
		height := 0
		Loop % rowHeights.Length()
			height += rowHeights[A_Index]
		
		width := 0
		Loop % columnWidths.Length()
			width += columnWidths[A_Index]
		
		height += ((rowHeights.Length() - 1) * this.RowMargin) + this.kHeaderHeight + this.BottomMargin
		width += ((columnWidths.Length() - 1) * this.ColumnMargin) + (2 * this.SidesMargin)
		
		window := this.Window
		
		Gui %window%:-Border -Caption
		
		Gui %window%:Add, Picture, x-10 y-10, % kButtonBoxImagesDirectory . "Photorealistic\CF Background.png"
		
		Gui %window%:Font, s12 Bold cSilver
		Gui %window%:Add, Text, x0 y8 w%width% h23 +0x200 +0x1 BackgroundTrans gmoveButtonBoxPreview, % translate("Modular Simulator Controller System")
		Gui %window%:Font, s10 cSilver
		Gui %window%:Add, Text, x0 y28 w%width% h23 +0x200 +0x1 BackgroundTrans gmoveButtonBoxPreview, % translate(this.Name)
		Gui %window%:Color, 0x000000
		Gui %window%:Font, s8 Norm, Arial
		
		vertical := this.kHeaderHeight
		
		Loop % this.Rows
		{
			rowHeight := rowHeights[A_Index]
			rowDefinition := this.RowDefinitions[A_Index]
		
			horizontal := this.SidesMargin
			
			Loop % this.Columns
			{
				columnWidth := columnWidths[A_Index]
			
				descriptor := rowDefinition[A_Index]
				
				if (StrLen(Trim(descriptor)) = 0)
					descriptor := "Empty.0"
				
				descriptor := string2Values(",", descriptor)
			
				if (descriptor.Length() > 1) {
					label := string2Values("x", getConfigurationValue(this.Configuration, "Labels", descriptor[2], ""))
					labelWidth := label[1]
					labelHeight := label[2]
				}
				else {
					labelWidth := 0
					labelHeight := 0
				}
				
				if (descriptor[1] = "Empty.0") {
					descriptor := kEmptySpaceDescriptor
					number := 0
				}
				else {
					descriptor := ConfigurationItem.splitDescriptor(descriptor[1])
					number := descriptor[2]
					
					descriptor := getConfigurationValue(this.Configuration, "Controls", descriptor[1], "")
				}
				
				descriptor := string2Values(";", descriptor)
				
				if (descriptor.Length() > 0) {
					function := descriptor[1]
					image := substituteVariables(descriptor[2])
					
					descriptor := string2Values("x", descriptor[3])
					imageWidth := descriptor[1]
					imageHeight := descriptor[2]
					
					function := ConfigurationItem.descriptor(function, number)

					x := horizontal + Round((columnWidth - imageWidth) / 2)
					y := vertical + Round((rowHeight - (labelHeight + this.kLabelMargin) - imageHeight) / 2)
					
					Gui %window%:Add, Picture, x%x% y%y% w%imageWidth% h%imageHeight% BackgroundTrans gopenControlMenu, %image%

					if ((labelWidth > 0) && (labelHeight > 0)) {
						Gui %window%:Font, s8 Norm cBlack
				
						x := horizontal + Round((columnWidth - labelWidth) / 2)
						y := vertical + rowHeight - labelHeight
						
						Gui %window%:Add, Text, x%x% y%y% w%labelWidth% h%labelHeight% +Border -Background  +0x1000 +0x1 gopenControlMenu, %number%
					}
				}
				
				horizontal += (columnWidth + this.ColumnMargin)
			}
		
			vertical += (rowHeight + this.RowMargin)
		}

		Gui %window%:Add, Picture, x-10 y-10 gmoveButtonBoxPreview 0x4000000, % kButtonBoxImagesDirectory . "Photorealistic\CF Background.png"
		
		this.iWidth := width
		this.iHeight := height
	}
	
	computeLayout(ByRef rowHeights, ByRef columnWidths) {
		columnWidths := []
		rowHeights := []
		
		Loop % this.Columns
			columnWidths.Push(0)
		
		Loop % this.Rows
		{
			rowHeight := 0
		
			rowDefinition := this.RowDefinitions[A_Index]
			
			Loop % this.Columns
			{
				descriptor := rowDefinition[A_Index]
				
				if (StrLen(Trim(descriptor)) = 0)
					descriptor := "Empty.0"
				
				descriptor := string2Values(",", descriptor)
				
				if (descriptor.Length() > 1) {
					label := string2Values("x", getConfigurationValue(this.Configuration, "Labels", descriptor[2], ""))
					labelWidth := label[1]
					labelHeight := label[2]
				}
				else {
					labelWidth := 0
					labelHeight := 0
				}

				if (descriptor[1] = "Empty.0")
					descriptor := kEmptySpaceDescriptor
				else
					descriptor := getConfigurationValue(this.Configuration, "Controls"
													  , ConfigurationItem.splitDescriptor(descriptor[1])[1], "")
				
				descriptor := string2Values(";", descriptor)
				
				if (descriptor.Length() > 0) {
					descriptor := string2Values("x", descriptor[3])
					
					imageWidth := descriptor[1]
					imageHeight := descriptor[2]
				}
				else {
					imageWidth := 0
					imageHeight := 0
				}
				
				rowHeight := Max(rowHeight, imageHeight + ((labelHeight > 0) ? (this.kLabelMargin + labelHeight) : 0))
				
				columnWidths[A_Index] := Max(columnWidths[A_Index], Max(imageWidth, labelWidth))
			}
			
			rowHeights.Push(rowHeight)
		}
	}
	
	getControl(clickX, clickY, ByRef row, ByRef column, ByRef isEmpty) {
		local function
		
		rowHeights := false
		columnWidths := false
		
		this.computeLayout(rowHeights, columnWidths)
		
		height := 0
		Loop % rowHeights.Length()
			height += rowHeights[A_Index]
		
		width := 0
		Loop % columnWidths.Length()
			width += columnWidths[A_Index]
		
		height += ((rowHeights.Length() - 1) * this.RowMargin) + this.kHeaderHeight + this.BottomMargin
		width += ((columnWidths.Length() - 1) * this.ColumnMargin) + (2 * this.SidesMargin)
		
		vertical := this.kHeaderHeight
		
		Loop % this.Rows
		{
			row := A_Index
			
			rowHeight := rowHeights[A_Index]
			rowDefinition := this.RowDefinitions[A_Index]
		
			horizontal := this.SidesMargin
			
			Loop % this.Columns
			{
				column := A_Index
				
				columnWidth := columnWidths[A_Index]
			
				descriptor := rowDefinition[A_Index]
				
				if (StrLen(Trim(descriptor)) = 0) {
					descriptor := "Empty.0"
					
					isEmpty := true
				}
				else
					isEmpty := false
				
				descriptor := string2Values(",", descriptor)
				
				if (descriptor.Length() > 1) {
					label := string2Values("x", getConfigurationValue(this.Configuration, "Labels", descriptor[2], ""))
					labelWidth := label[1]
					labelHeight := label[2]
				}
				else {
					labelWidth := 0
					labelHeight := 0
				}
				
				if (descriptor[1] = "Empty.0") {
					descriptor := kEmptySpaceDescriptor
					name := "Empty"
					number := 0
				}
				else {
					descriptor := ConfigurationItem.splitDescriptor(descriptor[1])
					name := descriptor[1]
					number := descriptor[2]
				
					descriptor := getConfigurationValue(this.Configuration, "Controls", descriptor[1], "")
				}
				
				descriptor := string2Values(";", descriptor)
				
				if (descriptor.Length() > 0) {
					function := descriptor[1]
					image := substituteVariables(descriptor[2])
					
					descriptor := string2Values("x", descriptor[3])
					imageWidth := descriptor[1]
					imageHeight := descriptor[2]
					
					x := horizontal + Round((columnWidth - imageWidth) / 2)
					y := vertical + Round((rowHeight - (labelHeight + this.kLabelMargin) - imageHeight) / 2)
					
					if ((clickX >= x) && (clickX <= (x + imageWidth)) && (clickY >= y) && (clickY <= (y + imageHeight)))
						return ["Control", ConfigurationItem.descriptor(name, number)]
					
					if ((labelWidth > 0) && (labelHeight > 0)) {
						Gui %window%:Font, s8 Norm
				
						x := horizontal + Round((columnWidth - labelWidth) / 2)
						y := vertical + rowHeight - labelHeight
						
						if ((clickX >= x) && (clickX <= (x + labelWidth)) && (clickY >= y) && (clickY <= (y + labelHeight)))
							return ["Label", ConfigurationItem.descriptor(name, number)]
					}
				}
				
				horizontal += (columnWidth + this.ColumnMargin)
			}
		
			vertical += (rowHeight + this.RowMargin)
		}

		return false
	}
	
	open() {
		width := this.Width
		height := this.Height
		
		centerX := this.Editor.ButtonBoxPreviewCenterX
		centerY := this.Editor.ButtonBoxPreviewCenterY
		
		if (centerX && centerY) {
			x := centerX - Round(width / 2)
			y := centerY - Round(height / 2)
		}
		else {
			SysGet mainScreen, MonitorWorkArea

			x := mainScreenRight - width
			y := mainScreenBottom - height
		}
		
		window := this.Window
		
		Gui %window%:Show, x%x% y%y% w%width% h%height% NoActivate
	}
	
	close() {
		window := this.Window
		
		Gui %window%:Destroy
	}
}

moveButtonBoxPreview() {
	window := ButtonBoxPreview.CurrentWindow
	
	moveByMouse(window)
	
	WinGetPos x, y, width, height, A
	
	ButtonBoxesEditor.Instance.setButtonBoxPreviewPosition(x + Round(width / 2), y + Round(height / 2))
}

openControlMenu() {
	curCoordMode := A_CoordModeMouse
	
	CoordMode Mouse, Window
		
	try {	
		MouseGetPos clickX, clickY
		
		row := 0
		column := 0
		isEmpty := false
		
		element := ButtonBoxesEditor.Instance.ButtonBoxPreview.getControl(clickX, clickY, row, column, isEmpty)
		
		if element {
			menuItem := (translate(element[1] . ": ") . element[2] . " (" . row . " x " . column . ")")
			
			try {
				Menu GridElement, DeleteAll
			}
			catch exception {
				; ignore
			}
			
			Gui BBE:Default
			
			Menu GridElement, Add, %menuItem%, menuIgnore
			Menu GridElement, Disable, %menuItem%
			Menu GridElement, Add
			
			try {
				Menu ControlMenu, DeleteAll
			}
			catch exception {
				; ignore
			}
			
			label := translate("Empty")
			handler := ObjBindMethod(LayoutsList.Instance, "changeControl", row, column, false)
			
			Menu ControlMenu, Add, %label%, %handler%
			Menu ControlMenu, Add
			
			for control, definition in ControlsList.Instance.getControls() {
				handler := ObjBindMethod(LayoutsList.Instance, "changeControl", row, column, control)
			
				Menu ControlMenu, Add, %control%, %handler%
			}
			
			if !isEmpty {
				Menu ControlMenu, Add
			
				try {
					Menu NumberMenu, DeleteAll
				}
				catch exception {
					; ignore
				}
				
				label := translate("Input...")
				handler := ObjBindMethod(LayoutsList.Instance, "changeControl", row, column, "__Number__", false)
				
				Menu NumberMenu, Add, %label%, %handler%
				Menu NumberMenu, Add
				
				count := 1
				
				Loop 4 {
					label := (count . " - " . (count + 9))
					
					menu := ("NumSubMenu" . A_Index)
				
					try {
						Menu %menu%, DeleteAll
					}
					catch exception {
						; ignore
					}
					
					Loop 10 {
						handler := ObjBindMethod(LayoutsList.Instance, "changeControl", row, column, "__Number__", count)
						Menu %menu%, Add, %count%, %handler%
						
						count += 1
					}
				
					Menu NumberMenu, Add, %label%, :%menu%
				}
				
				label := translate("Number")
				Menu ControlMenu, Add, %label%, :NumberMenu
			}
			
			label := translate("Control")
			
			Menu GridElement, Add, %label%, :ControlMenu
			
			if !isEmpty {
				try {
					Menu LabelMenu, DeleteAll
				}
				catch exception {
					; ignore
				}
				
				label := translate("Empty")
				handler := ObjBindMethod(LayoutsList.Instance, "changeLabel", row, column, false)
				
				Menu LabelMenu, Add, %label%, %handler%
				Menu LabelMenu, Add
				
				for label, definition in LabelsList.Instance.getLabels() {
					handler := ObjBindMethod(LayoutsList.Instance, "changeLabel", row, column, label)
				
					Menu LabelMenu, Add, %label%, %handler%
				}
				
				label := translate("Label")
				
				Menu GridElement, Add, %label%, :LabelMenu
			}

			Menu GridElement, Show
		}
	}
	finally {
		CoordMode Mouse, curCoordMode
	}
}

menuIgnore() {
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

showKeyDetector() {
	returnHotKey := vKeyDetectorReturnHotkey
	joystickNumbers := []
	
	vKeyDetectorReturnHotkey := false

	Loop 16 { ; Query each joystick number to find out which ones exist.
		GetKeyState joyName, %A_Index%JoyName
		
		if (joyName != "")
			joystickNumbers.Push(A_Index)
	}

	if (joystickNumbers.Length() == 0) {
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
		title := translate("Warning")
		MsgBox 262192, %title%, % translate("No controller detected...")
		OnMessage(0x44, "")
		
		vShowKeyDetector := false
	}

	if vShowKeyDetector {
		found := false
		
		Loop {
			joystickNumber := joystickNumbers[1]
			
			joystickNumbers.RemoveAt(1)
			joystickNumbers.Push(joystickNumber)
		
			SetFormat Float, 03  ; Omit decimal point from axis position percentages.
		
			GetKeyState joy_buttons, %joystickNumber%JoyButtons
			GetKeyState joy_name, %joystickNumber%JoyName
			GetKeyState joy_info, %joystickNumber%JoyInfo

			if !vShowKeyDetector {
				ToolTip, , , 1
				
				break
			}
			
			buttons_down := ""
			
			Loop %joy_buttons%
			{
				GetKeyState joy%A_Index%, %joystickNumber%joy%A_Index%
		
				if (joy%A_Index% = "D") {
					buttons_down = %buttons_down%%A_Space%%A_Index%
					
					found := A_Index
				}
			}
	
			GetKeyState joyX, %joystickNumber%JoyX
			
			axis_info = X%joyX%
			
			GetKeyState joyY, %joystickNumber%JoyY
	
			axis_info = %axis_info%%A_Space%%A_Space%Y%joyY%
	
			IfInString joy_info, Z
			{
				GetKeyState joyZ, %joystickNumber%JoyZ

				axis_info = %axis_info%%A_Space%%A_Space%Z%joyZ%
			}
			
			IfInString joy_info, R
			{
				GetKeyState joyR, %joystickNumber%JoyR
		
				axis_info = %axis_info%%A_Space%%A_Space%R%joyR%
			}
			
			IfInString joy_info, U
			{
				GetKeyState joyU, %joystickNumber%JoyU
		
				axis_info = %axis_info%%A_Space%%A_Space%U%joyU%
			}
			
			IfInString joy_info, V
			{
				GetKeyState joyV, %joystickNumber%JoyV
		
				axis_info = %axis_info%%A_Space%%A_Space%V%joyV%
			}
			
			IfInString joy_info, P
			{
				GetKeyState joyp, %joystickNumber%JoyPOV
				
				axis_info = %axis_info%%A_Space%%A_Space%POV%joyp%
			}
			
			buttonsDown := translate("Buttons Down:")
			
			ToolTip %joy_name% (#%joystickNumber%):`n%axis_info%`n%buttonsDown% %buttons_down%, , , 1
						
			if found {
				if returnHotkey
					vKeyDetectorReturnHotkey := (joystickNumber . "Joy" . found)
				else
					Sleep 2000
				
				found := false
			}
			else				
				Sleep 400
			
			if vResult
				break
		}
	}
}

saveConfiguration(configurationFile, editor) {
	configuration := newConfiguration()

	editor.saveToConfiguration(configuration)

	writeConfiguration(configurationFile, configuration)
	
	startupLink := A_Startup . "\Simulator Startup.lnk"
	
	if getConfigurationValue(configuration, "Configuration", "Start With Windows", false) {
		startupExe := kBinariesDirectory . "Simulator Startup.exe"
		
		FileCreateShortCut %startupExe%, %startupLink%, %kBinariesDirectory%
	}
	else
		try {
			FileDelete %startupLink%
		}
		catch exception {
			; ignore
		}
}

editConfiguration() {
	editor := new ConfigurationEditor(FileExist("C:\Program Files\AutoHotkey") || GetKeyState("Ctrl")
								   || (getConfigurationValue(kSimulatorConfiguration, "Configuration", "AHK Path", "") != "")
								    , (GetKeyState("Ctrl") && GetKeyState("Shift")) ? newConfiguration() : kSimulatorConfiguration)
	
	done := false
	saved := false

	editor.show()
	
	Loop {
		Sleep 200
		
		if (vResult == kApply) {
			saved := true
			vResult := false
			
			saveConfiguration(kSimulatorConfigurationFile, editor)
		}
		else if (vResult == kCancel)
			done := true
		else if (vResult == kOk) {
			saved := true
			done := true
			
			saveConfiguration(kSimulatorConfigurationFile, editor)
		}
	} until done

	editor.hide()
	
	return saved
}

startSimulatorConfiguration() {
	icon := kIconsDirectory . "Configuration.ico"
	
	Menu Tray, Icon, %icon%, , 1
	
	if editConfiguration()
		ExitApp 1
	else
		ExitApp 0
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

startSimulatorConfiguration()