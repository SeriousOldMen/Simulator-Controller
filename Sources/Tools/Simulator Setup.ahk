﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Simulator Configuration Tool    ;;;
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
#Warn LocalSameAsGlobal, Off

SendMode Input					; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%		; Ensures a consistent starting directory.

SetBatchLines -1				; Maximize CPU utilization
ListLines Off					; Disable execution history

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Setup.ico
;@Ahk2Exe-ExeName Simulator Setup.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kApply = "apply"
global kOk = "ok"
global kCancel = "cancel"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vResult = false

global vShowKeyDetector = false

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
	
	__New(configuration, listHandle, listVariable, addButton, deleteButton, updateButton, upButton := false, downButton := false) {
		this.iListHandle := listHandle
		this.iAddButton := addButton
		this.iDeleteButton := deleteButton
		this.iUpdateButton := updateButton
		this.iUpButton := upButton
		this.iDownButton := downButton
		
		registerList(listVariable, this)
		
		registerList(addButton, this)
		registerList(deleteButton, this)
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
		Throw "Virtual method ConfigurationItemList.saveToConfiguration must be overriden in a subclass..."
	}
	
	createControls(configuration) {
	}
	
	loadList(items) {
		Throw "Virtual method ConfigurationItemList.loadList must be overriden in a subclass..."
	}
	
	updateState() {
		if (this.iCurrentItemIndex != 0) {
			GuiControl Enable, % this.iDeleteButton
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
			
			GuiControl Disable, % this.iDeleteButton
			GuiControl Disable, % this.iUpdateButton
		}
	}
	
	loadEditor(item) {
		Throw "Virtual method ConfigurationItemList.loadEditor must be overriden in a subclass..."
	}
	
	clearEditor() {
		Throw "Virtual method ConfigurationItemList.clearEditor must be overriden in a subclass..."
	}
	
	buildItemFromEditor(isNew := false) {
		Throw "Virtual method ConfigurationItemList.buildItemFromEditor must be overriden in a subclass..."
	}
	
	openEditor(itemNumber) {
		this.iCurrentItemIndex := itemNumber
		
		this.loadEditor(this.iItemsList[this.iCurrentItemIndex])
		
		this.updateState()
	}
	
	selectItem(itemNumber) {
		this.iCurrentItemIndex := itemNumber
		
		if itemNumber
			LV_Modify(itemNumber, "Vis +Select +Focus")
		
		this.updateState()
	}
	
	addItem() {
		item := this.buildItemFromEditor(true)
		
		if item {
			this.iItemsList.Push(item)
		
			this.loadList(this.iItemsList)
			
			this.selectItem(this.iItemsList.Length())
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
		item := this.buildItemFromEditor()
		
		if item {
			this.iItemsList[this.iCurrentItemIndex] := item
			
			this.loadList(this.iItemsList)
			
			this.selectItem(this.iCurrentItemIndex)
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
	if (A_GuiEvent == "DoubleClick")
		vItemLists[A_GuiControl].openEditor(A_EventInfo)	
}

addItem() {
	vItemLists[A_GuiControl].addItem()
}

deleteItem() {
	vItemLists[A_GuiControl].deleteItem()
}

updateItem() {
	vItemLists[A_GuiControl].updateItem()
}

upItem() {
	vItemLists[A_GuiControl].upItem()
}

downItem() {
	vItemLists[A_GuiControl].downItem()
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; SetupEditor                                                             ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class SetupEditor extends ConfigurationItem {
	iGeneralTab := false
	iPluginsTab := false
	iApplicationsTab := false
	iControllerTab := false
	iLaunchpadTab := false
	iChatMessagesTab := false
	
	iDevelopment := false
	
	__New(development, configuration) {
		this.iDevelopment := development
		
		base.__New(configuration)
		
		this.createControls(configuration)
	}
	
	createControls(configuration) {
		Gui SE:Default
	
		Gui SE:-border -Caption
		Gui SE:Color, D0D0D0

		Gui SE:Font, Bold, Arial

		Gui SE:Add, Text, w398 Center, Modular Simulator Controller System 
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial

		Gui SE:Add, Text, YP+20 w398 Center, Setup

		Gui SE:Font, Norm, Arial

		Gui SE:Add, Button, x8 y528 w100 h23 gtoggleKeyDetector, Key Detector...
		
		Gui SE:Add, Button, x152 y528 w80 h23 Default gsaveAndExit, Ok
		Gui SE:Add, Button, x240 y528 w80 h23 gcancelAndExit, Cancel
		Gui SE:Add, Button, x328 y528 w77 h23 gsaveAndStay, Apply

		Gui SE:Add, Tab3, x8 y48 w398 h472, General|Plugins|Applications|Controller|Launchpad|Chat
		
		tab := 1
		
		Gui SE:Tab, % tab++
		
		this.iGeneralTab := new GeneralTab(this.iDevelopment, configuration)
		
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
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		this.iGeneralTab.saveToConfiguration(configuration)
		
		if this.iDevelopment
			this.iDevelopmentTab.saveToConfiguration(configuration)
			
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
	
}

toggleKeyDetector() {
	vShowKeyDetector := !vShowKeyDetector
	
	if vShowKeyDetector
		SetTimer showKeyDetector, 100
	else
		ToolTip, , , 1
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

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; GeneralTab                                                              ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global nirCmdPathEdit
global homePathEdit

global startWithWindowsCheck
global silentModeCheck

global ahkPathEdit
global debugEnabledCheck
global logLevelDropdown

class GeneralTab extends ConfigurationItemTab {
	iSimulatorsList := false
	iDevelopment := false
	
	__New(development, configuration) {
		this.iDevelopment := development
		
		base.__New(configuration)
		
		GeneralTab.Instance := this
	}
	
	createControls(configuration) {
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y80 w377 h70, Installation Folders
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Text, x24 y97 w160 h23 +0x200, Home (optional)
		Gui SE:Add, Edit, x184 y97 w174 h21 VhomePathEdit, %homePathEdit%
		Gui SE:Add, Button, x360 y96 w23 h23 gchooseHomePath, ...
		
		Gui SE:Add, Text, x24 y121 w160 h23 +0x200, NirCmd (optional)
		Gui SE:Add, Edit, x184 y121 w174 h21 VnirCmdPathEdit, %nirCmdPathEdit%
		Gui SE:Add, Button, x360 y120 w23 h23 gchooseNirCmdPath, ...
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y160 w378 h70, Startup
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, CheckBox, x24 y176 w242 h23 Checked%startWithWindowsCheck% VstartWithWindowsCheck, Start with Windows
		Gui SE:Add, CheckBox, x24 y200 w242 h23 Checked%silentModeCheck% VsilentModeCheck, Silent mode (no splash screen, no sound)
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y240 w378 h120, Simulators
		
		Gui SE:Font, Norm, Arial
		
		this.iSimulatorsList := new SimulatorsList(configuration)
		
		if this.iDevelopment {
			Gui SE:Font, Norm, Arial
			Gui SE:Font, Italic, Arial
			
			Gui SE:Add, GroupBox, x16 y410 w377 h95, Development
			
			Gui SE:Font, Norm, Arial
			
			Gui SE:Add, Text, x24 y427 w160 h23 +0x200, AutoHotkey
			Gui SE:Add, Edit, x184 y427 w174 h21 VahkPathEdit, %ahkPathEdit%
			Gui SE:Add, Button, x360 y426 w23 h23 gchooseAHKPath, ...
			
			Gui SE:Add, Text, x24 y451 w160 h23 +0x200, Debug
			Gui SE:Add, CheckBox, x184 y451 w242 h23 Checked%debugEnabledCheck% VdebugEnabledCheck, Enabled?
			
			Gui SE:Add, Text, x24 y475 w160 h23 +0x200, Log Level
			
			choices := ["Info", "Warn", "Critical", "Off"]
			
			chosen := inList(choices, logLevelDropdown)
			if !chosen
				chosem := 2
				
			Gui SE:Add, DropDownList, x184 y475 w91 Choose%chosen% VlogLevelDropdown, % values2String("|", choices*)
		
		}
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		nirCmdPathEdit := getConfigurationValue(configuration, "Configuration", "NirCmd Path", "")
		homePathEdit := getConfigurationValue(configuration, "Configuration", "Home Path", "")
		
		startWithWindowsCheck := getConfigurationValue(configuration, "Configuration", "Start With Windows", true)
		silentModeCheck := getConfigurationValue(configuration, "Configuration", "Silent Mode", false)
		
		if this.iDevelopment {
			ahkPathEdit := getConfigurationValue(configuration, "Configuration", "AHK Path", "")
			debugEnabledCheck := getConfigurationValue(configuration, "Configuration", "Debug", false)
			logLevelDropdown := getConfigurationValue(configuration, "Configuration", "Log Level", "Warn")
		}
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		GuiControlGet nirCmdPathEdit
		GuiControlGet homePathEdit
		
		GuiControlGet startWithWindowsCheck
		GuiControlGet silentModeCheck
		
		setConfigurationValue(configuration, "Configuration", "NirCmd Path", nirCmdPathEdit)
		setConfigurationValue(configuration, "Configuration", "Home Path", homePathEdit)
		
		setConfigurationValue(configuration, "Configuration", "Start With Windows", startWithWindowsCheck)
		setConfigurationValue(configuration, "Configuration", "Silent Mode", silentModeCheck)
		
		if this.iDevelopment {
			GuiControlGet ahkPathEdit
			GuiControlGet debugEnabledCheck
			GuiControlGet logLevelDropdown
		
			setConfigurationValue(configuration, "Configuration", "AHK Path", ahkPathEdit)
			setConfigurationValue(configuration, "Configuration", "Debug", debugEnabledCheck)
			setConfigurationValue(configuration, "Configuration", "Log Level", logLevelDropdown)
		}
		
		this.iSimulatorsList.saveToConfiguration(configuration)
	}
}

chooseHomePath() {
	FileSelectFolder, directory, *%homePathEdit%, 0, Select Simulator Controller folder...
	
	if (directory != "")
		GuiControl Text, homePathEdit, %directory%
}

chooseNirCmdPath() {
	FileSelectFolder, directory, *%nirCmdPathEdit%, 0, Select NirCmd folder...
	
	if (directory != "")
		GuiControl Text, nirCmdPathEdit, %directory%
}

chooseAHKPath() {
	FileSelectFolder, directory, *%ahkPathEdit%, 0, Select AutoHotkey folder...
	
	if (directory != "")
		GuiControl Text, ahkPathEdit, %directory%
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
		Gui SE:Add, ListBox, x24 y264 w154 h96 HwndsimulatorsListBoxHandle VsimulatorsListBox glistEvent, %simulatorsListBox%
		
		Gui SE:Add, Edit, x184 y264 w199 h21 VsimulatorEdit, %simulatorEdit%
		
		Gui SE:Add, Button, x305 y288 w38 h23 Disabled VsimulatorUpButton gupItem, Up
		Gui SE:Add, Button, x345 y288 w38 h23 Disabled VsimulatorDownButton gdownItem, Down
		
		Gui SE:Add, Button, x184 y329 w46 h23 VsimulatorAddButton gaddItem, Add
		Gui SE:Add, Button, x232 y329 w50 h23 Disabled VsimulatorDeleteButton gdeleteItem, Delete
		Gui SE:Add, Button, x328 y329 w55 h23 Disabled VsimulatorUpdateButton gupdateItem, Update
		
		return simulatorsListBoxHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		this.iItemsList := string2Values("|", getConfigurationValue(configuration, "Configuration", "Simulators", ""))
	}
		
	saveToConfiguration(configuration) {
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
			local plugin
			
			result := []
			
			for index, plugin in this.iItemsList
				result.Push(plugin[2])
				
			return result
		}
	}
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "pluginsListView", "pluginAddButton", "pluginDeleteButton", "pluginUpdateButton")
				 
		PluginsTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w377 h270 -Multi -LV0x10 NoSort NoSortHdr HwndpluginsListViewHandle VpluginsListView glistEvent, Active|Plugin|Simulator(s)|Arguments
		
		Gui SE:Add, Text, x16 y360 w86 h23 +0x200, Plugin
		Gui SE:Add, Edit, x110 y360 w154 h21 VpluginEdit, %pluginEdit%
		
		Gui SE:Add, CheckBox, x110 y384 w120 h23 VpluginActivatedCheck HwndpluginActivatedCheckHandle, Activated?
		
		Gui SE:Add, Text, x16 y408 w89 h23 +0x200, Simulator(s)
		Gui SE:Add, Edit, x110 y408 w285 h21 VpluginSimulatorsEdit, %pluginSimulatorsEdit%
		
		Gui SE:Add, Text, x16 y432 w86 h23 +0x200, Arguments
		Gui SE:Add, Edit, x110 y432 w285 h48 VpluginArgumentsEdit, %pluginArgumentsEdit%
		
		Gui SE:Add, Button, x16 y490 w92 h23 gopenLabelsEditor, Edit Labels...
		
		Gui SE:Add, Button, x184 y490 w46 h23 VpluginAddButton gaddItem, Add
		Gui SE:Add, Button, x232 y490 w50 h23 Disabled VpluginDeleteButton gdeleteItem, Delete
		Gui SE:Add, Button, x340 y490 w55 h23 Disabled VpluginUpdateButton gupdateItem, Update
		
		return pluginsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
	
		for name, arguments in getConfigurationSectionValues(configuration, "Plugins", Object())
			this.iItemsList.Push(new Plugin(name, configuration))
	}
		
	saveToConfiguration(configuration) {
		local plugin
		
		for ignore, plugin in this.iItemsList
			plugin.saveToConfiguration(configuration)
	}
	
	updateState() {
		local plugin
		
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
		local plugin
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		bubbleSort(items, "comparePlugins")
	
		for ignore, plugin in items {
			name := plugin.Plugin
			active := plugin.Active
			
			LV_Add("", plugin.Active ? ((name = "System") ? "Always" : "Yes") : "", name, values2String(", ", plugin.Simulators*), plugin.Arguments[true])
		}
		
		LV_ModifyCol()
		LV_ModifyCol(1, "Center AutoHdr")
		LV_ModifyCol(2, 100)
		LV_ModifyCol(3, 100)
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
	if (p1.Plugin = "System")
		return false
	else if (p2.Plugin = "System")
		return true
	else
		return (p1.Plugin >= p2.Plugin)
}

openLabelsEditor() {
	Run % "notepad.exe " . """" . kConfigDirectory . "Controller Plugin Labels.ini"""
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
			local application
			
			result := []
			
			for index, application in this.iItemsList
				if !types
					result.Push(application[2])
				else if inList(types, application[1])
					result.Push(application[2])
				
			return result
		}
	}
	
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "applicationsListView", "applicationAddButton", "applicationDeleteButton", "applicationUpdateButton")
				 
		ApplicationsTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w377 h205 -Multi -LV0x10 NoSort NoSortHdr HwndapplicationsListViewHandle VapplicationsListView glistEvent, Type|Application|Executable|Window Title|Working Directoy
		
		Gui SE:Add, Text, x16 y295 w141 h23 +0x200, Application
		Gui SE:Add, Edit, x160 y295 w208 h21 VapplicationNameEdit, %applicationNameEdit%
		
		Gui SE:Add, Text, x16 y319 w138 h23 +0x200, Executable
		Gui SE:Add, Edit, x160 y319 w208 h21 VapplicationExePathEdit, %applicationExePathEdit%
		Gui SE:Add, Button, x371 y318 w23 h23 gchooseApplicationExePath, ...
		
		Gui SE:Add, Text, x16 y343 w138 h23 +0x200, Working Directory (optional)
		Gui SE:Add, Edit, x160 y343 w208 h21 VapplicationWorkingDirectoryPathEdit, %applicationWorkingDirectoryPathEdit%
		Gui SE:Add, Button, x371 y342 w23 h23 gchooseApplicationWorkingDirectoryPath, ...
		
		Gui SE:Add, Text, x16 y367 w140 h23 +0x200, Window Title (optional)
		Gui SE:Font, cGray
		Gui SE:Add, Text, x24 y385 w133 h23, (Use AHK WinTitle Syntax)
		Gui SE:Font
		Gui SE:Add, Edit, x160 y367 w208 h21 VapplicationWindowTitleEdit, %applicationWindowTitleEdit%
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y411 w378 h71, Function Hooks (optional)
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Text, x20 y427 w116 h23 +0x200 +Center, Startup
		Gui SE:Add, Edit, x20 y451 w116 h21 VapplicationStartupEdit, %applicationStartupEdit%
		
		Gui SE:Add, Text, x147 y427 w116 h23 +0x200 +Center, Shutdown
		Gui SE:Add, Edit, x147 y451 w116 h21 VapplicationShutdownEdit, %applicationShutdownEdit%
		
		Gui SE:Add, Text, x274 y427 w116 h23 +0x200 +Center, Running?
		Gui SE:Add, Edit, x274 y451 w116 h21 VapplicationIsRunningEdit, %applicationIsRunningEdit%

		Gui SE:Add, Button, x184 y490 w46 h23 VapplicationAddButton gaddItem, Add
		Gui SE:Add, Button, x232 y490 w50 h23 Disabled VapplicationDeleteButton gdeleteItem, Delete
		Gui SE:Add, Button, x340 y490 w55 h23 Disabled VapplicationUpdateButton gupdateItem, Update
		
		return applicationsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
	
		for descriptor, name in getConfigurationSectionValues(configuration, "Applications", Object())
			this.iItemsList.Push(Array(ConfigurationItem.splitDescriptor(descriptor)[1], new Application(name, configuration)))
	}
		
	saveToConfiguration(configuration) {
		local application
	
		count := 0
		lastType := ""
		
		for index, application in this.iItemsList {
			type := application[1]
			application := application[2]
			
			if (type != lastType) {
				count := 1
				lastType := type
			}
			else
				count += 1
		
			setConfigurationValue(configuration, "Applications", ConfigurationItem.descriptor(type, count), application.Application)
		
			application.saveToConfiguration(configuration)
		}
	}
	
	updateState() {
		local application
		
		base.updateState()
		
		if (this.iCurrentItemIndex != 0) {
			application := this.iItemsList[this.iCurrentItemIndex]
			
			type := application[1]
			
			if (type != "Other") {
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
	}
	
	loadList(items) {
		local application
		
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		for index, application in items {
			type := application[1]
			application := application[2]
			
			LV_Add("", type, application.Application, application.ExePath, application.WindowTitle, application.WorkingDirectory)
		}
		
		LV_ModifyCol()
		LV_ModifyCol(1, "Center AutoHdr")
		LV_ModifyCol(2, 120)
		LV_ModifyCol(3, 80)
		LV_ModifyCol(4, 80)
	}
	
	loadEditor(item) {
		local application := item[2]
		
		applicationNameEdit := application.Application
		applicationExePathEdit := application.ExePath
		applicationWorkingDirectoryPathEdit := application.WorkingDirectory
		applicationWindowTitleEdit := application.WindowTitle
		applicationStartupEdit := (application.SpecialStartup ? application.SpecialStartup : "")
		applicationShutdownEdit := (application.SpecialShutdown ? application.SpecialShutdown : "")
		applicationIsRunningEdit := (application.SpecialIsRunning ? application.SpecialIsRunning : "")
		
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
		
		return Array(isNew ? "Other" : this.iItemsList[this.iCurrentItemIndex][1]
				   , new Application(applicationNameEdit, false, applicationExePathEdit, applicationWorkingDirectoryPathEdit, applicationWindowTitleEdit
				   , applicationStartupEdit, applicationShutdownEdit, applicationIsRunningEdit))
	}
}

chooseApplicationExePath() {
	FileSelectFolder, directory, *%applicationExePathEdit%, 0, Select application executable...
	
	if (directory != "")
		GuiControl Text, applicationExePathEdit, %directory%
}

chooseApplicationWorkingDirectoryPath() {
	FileSelectFolder, directory, *%applicationWorkingDirectoryPathEdit%, 0, Select working directory...
	
	if (directory != "")
		GuiControl Text, applicationWorkingDirectoryPathEdit, %directory%
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ControllerTab                                                           ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global oneWayTogglesEdit
global twoWayTogglesEdit
global buttonsEdit
global dialsEdit

class ControllerTab extends ConfigurationItemTab {
	iFunctionsist := false
	
	__New(configuration) {
		base.__New(configuration)
		
		ControllerTab.Instance := this
	}
	
	createControls(configuration) {
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y80 w377 h71, Functions
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Text, x24 y96 w104 h23 +0x200, # 1-Way Toggles
		Gui SE:Add, Edit, x128 y96 w39 h21 Number VoneWayTogglesEdit, %oneWayTogglesEdit%
		Gui SE:Add, UpDown, x168 y96 w18 h21, %oneWayTogglesEdit%
		
		Gui SE:Add, Text, x24 y120 w104 h23 +0x200, # 2-Way Toggles
		Gui SE:Add, Edit, x128 y120 w39 h21 Number VtwoWayTogglesEdit, %twoWayTogglesEdit%
		Gui SE:Add, UpDown, x168 y120 w18 h21, %twoWayTogglesEdit%
		
		Gui SE:Add, Text, x208 y96 w104 h23 +0x200, # Buttons
		Gui SE:Add, Edit, x312 y96 w39 h21 Number VbuttonsEdit, %buttonsEdit%
		Gui SE:Add, UpDown, x352 y96 w18 h21, %buttonsEdit%
		
		Gui SE:Add, Text, x208 y120 w104 h23 +0x200, # Dials
		Gui SE:Add, Edit, x312 y120 w39 h21 Number VdialsEdit, %dialsEdit%
		Gui SE:Add, UpDown, x352 y120 w18 h21, %dialsEdit%
		
		this.iFunctionsList := new FunctionsList(configuration)
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		oneWayTogglesEdit := getConfigurationValue(configuration, "Controller Layout", "1WayToggles", 0)
		twoWayTogglesEdit := getConfigurationValue(configuration, "Controller Layout", "2WayToggles", 0)
		buttonsEdit := getConfigurationValue(configuration, "Controller Layout", "Buttons", 0)
		dialsEdit := getConfigurationValue(configuration, "Controller Layout", "Dials", 0)
	}
	
	saveToConfiguration(configuration) {
		base.saveToConfiguration(configuration)
		
		GuiControlGet oneWayTogglesEdit
		GuiControlGet twoWayTogglesEdit
		GuiControlGet buttonsEdit
		GuiControlGet dialsEdit
		
		setConfigurationValue(configuration, "Controller Layout", "1WayToggles", oneWayTogglesEdit)
		setConfigurationValue(configuration, "Controller Layout", "2WayToggles", twoWayTogglesEdit)
		setConfigurationValue(configuration, "Controller Layout", "Buttons", buttonsEdit)
		setConfigurationValue(configuration, "Controller Layout", "Dials", dialsEdit)
		
		this.iFunctionsList.saveToConfiguration(configuration)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; FunctionsList                                                           ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global functionsListView

global functionTypeDropdown = 0
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
		Gui SE:Add, ListView, x16 y158 w377 h192 -Multi -LV0x10 NoSort NoSortHdr HwndfunctionsListViewHandle VfunctionsListView glistEvent, Function|Number|Hotkey(s) & Action(s)
	
		Gui SE:Add, Text, x16 y360 w86 h23 +0x200, Function
		Gui SE:Add, DropDownList, x104 y360 w91 AltSubmit Choose%functionTypeDropdown% VfunctionTypeDropdown gupdateEditorState, 1-way Toggle|2-way Toggle|Button|Dial|Custom
		Gui SE:Add, Edit, x200 y360 w40 h21 Number VfunctionNumberEdit, %functionNumberEdit%
		Gui SE:Add, UpDown, x240 y360 w17 h21, 1
		
		Gui SE:Font, Norm, Arial
		Gui SE:Font, Italic, Arial
		
		Gui SE:Add, GroupBox, x16 y392 w378 h91, Bindings
		
		Gui SE:Font, Norm, Arial
		
		Gui SE:Add, Text, x104 y400 w135 h23 +0x200 +Center, On/Increase/Push/Call
		Gui SE:Add, Text, x248 y400 w135 h23 +0x200 +Center, Off/Decrease
		
		Gui SE:Add, Text, x24 y424 w83 h23 +0x200, Hotkey(s)
		Gui SE:Add, Edit, x104 y424 w135 h21 VfunctionOnHotkeysEdit, %functionOnHotkeysEdit%
		Gui SE:Add, Edit, x248 y424 w135 h21 VfunctionOffHotkeysEdit, %functionOffHotkeysEdit%
		
		Gui SE:Add, Text, x24 y448 w83 h23, Action (optional)
		Gui SE:Add, Edit, x104 y448 w135 h21 VfunctionOnActionEdit, %functionOnActionEdit%
		Gui SE:Add, Edit, x248 y448 w135 h21 VfunctionOffActionEdit, %functionOffActionEdit%
		
		Gui SE:Add, Button, x184 y490 w46 h23 VfunctionAddButton gaddItem, Add
		Gui SE:Add, Button, x232 y490 w50 h23 Disabled VfunctionDeleteButton gdeleteItem, Delete
		Gui SE:Add, Button, x340 y490 w55 h23 Disabled VfunctionUpdateButton gupdateItem, Update
		
		return functionsListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
	
		for descriptor, arguments in getConfigurationSectionValues(configuration, "Controller Functions", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			descriptor := ConfigurationItem.descriptor(descriptor[1], descriptor[2])
			
			if !this.iFunctions.HasKey(descriptor) {
				function := ControllerFunction.createControllerFunction(descriptor, configuration)
				
				this.iFunctions[descriptor] := function
				this.iItemsList.Push(function)
			}
		}
	}
		
	saveToConfiguration(configuration) {
		for ignore, function in this.iItemsList
			function.saveToConfiguration(configuration)
	}
	
	updateState() {
		base.updateState()
	
		GuiControlGet functionType, , functionTypeDropdown
	
		if ((functionType == 2) || (functionType == 4)) {
			GuiControl Enable, functionOffHotkeysEdit
			GuiControl Enable, functionOffActionEdit
		}
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
		Gui ListView, % this.ListHandle
	
		this.iItemsList := Array()
		
		LV_Delete()
		
		round := 0
		
		Loop {
			if (++round > 2)
				break
				
			for qualifier, function in this.iFunctions 
				if (((round == 1) && (function.Type != kCustomType)) || ((round == 2) && (function.Type == kCustomType))) {
					hotkeysAndActions := ""

					for index, trigger in function.Trigger {
						hotkeys := function.Hotkeys[trigger, true]
						action := function.Actions[trigger, true]
						
						nextHKA := this.computeHotkeysAndActionText(hotkeys, action)
						
						if ((index > 1) && (hotkeysAndActions != "") && (nextHKA != ""))
							hotkeysAndActions := hotkeysAndActions . ", "
							
						hotkeysAndActions := hotkeysAndActions . nextHKA
					}
						
					LV_Add("", this.computeFunctionType(function.Type), function.Number, hotkeysAndActions)
					
					this.iItemsList.Push(function)
				}
		}
		
		LV_ModifyCol()
		LV_ModifyCol(2, "Center AutoHdr")
	}
	
	loadEditor(item) {
		functionType := item.Type
		onKey := false
		offKey := false
		
		switch item.Type {
			case k1WayToggleType:
				functionTypeDropdown := 1
				onKey := "On"
			case k2WayToggleType:
				functionTypeDropdown := 2
				onKey := "On"
				offKey := "Off"
			case kButtonType:
				functionTypeDropdown := 3
				onKey := "Push"
			case kDialType:
				functionTypeDropdown := 4
				onKey := "Increase"
				offKey := "Decrease"
			case kCustomType:
				functionTypeDropdown := 5
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
		
		GuiControl Choose, functionTypeDropdown, %functionTypeDropdown%
		GuiControl Text, functionNumberEdit, %functionNumberEdit%
		GuiControl Text, functionOnHotkeysEdit, %functionOnHotkeysEdit%
		GuiControl Text, functionOnActionEdit, %functionOnActionEdit%
		GuiControl Text, functionOffHotkeysEdit, %functionOffHotkeysEdit%
		GuiControl Text, functionOffActionEdit, %functionOffActionEdit%
	}
	
	clearEditor() {
		functionTypeDropdown := 0
		functionNumberEdit := 0
		functionOnHotkeysEdit := ""
		functionOnActionEdit := ""
		functionOffHotkeysEdit := ""
		functionOffActionEdit := ""
		
		GuiControl Choose, functionTypeDropdown, %functionTypeDropdown%
		GuiControl Text, functionNumberEdit, %functionNumberEdit%
		GuiControl Text, functionOnHotkeysEdit, %functionOnHotkeysEdit%
		GuiControl Text, functionOnActionEdit, %functionOnActionEdit%
		GuiControl Text, functionOffHotkeysEdit, %functionOffHotkeysEdit%
		GuiControl Text, functionOffActionEdit, %functionOffActionEdit%
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet functionTypeDropdown
		GuiControlGet functionNumberEdit
		GuiControlGet functionOnHotkeysEdit
		GuiControlGet functionOnActionEdit
		GuiControlGet functionOffHotkeysEdit
		GuiControlGet functionOffActionEdit
		
		functionType := [false, k1WayToggleType, k2WayToggleType, kButtonType, kDialType, kCustomType][functionTypeDropdown + 1]
		
		if (functionType && (functionNumberEdit >= 0)) {
			if ((functionType != k2WayToggleType) && (functionType != kDialType)) {
				functionOffHotkeysEdit := ""
				functionOffActionEdit := ""
			}
			
			return ControllerFunction.createControllerFunction(ConfigurationItem.descriptor(functionType, functionNumberEdit), false, functionOnHotkeysEdit, functionOnActionEdit, functionOffHotkeysEdit, functionOffActionEdit)
		}
		else {
			OnMessage(0x44, "translateMsgBoxButtons")
			MsgBox 262160, Error, Invalid values detected - please correct...
			OnMessage(0x44, "")
			
			return false
		}
	}
	
	addItem() {
		function := this.buildItemFromEditor(true)
	
		if function
			if this.iFunctions.HasKey(function.Descriptor) {
				OnMessage(0x44, "translateMsgBoxButtons")
				MsgBox 262160, Error, This function already exists - please use different values...
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
		function := this.buildItemFromEditor()
	
		if function
			if (function.Descriptor != this.iItemsList[this.iCurrentItemIndex].Descriptor) {
				OnMessage(0x44, "translateMsgBoxButtons")
				MsgBox 262160, Error, The type and number of an existing function may not be changed...
				OnMessage(0x44, "")
			}
			else {
				this.iFunctions[function.Descriptor] := function
				
				base.updateItem()
			}
	}
}

updateEditorState() {
	vItemLists["functionsListView"].updateState()
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; LaunchpadTab                                                            ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global launchpadListView = false
global launchpadLabelEdit = ""
global launchpadApplicationDropdown = 0
global launchpadUpButton
global launchpadDownButton
global launchpadAddButton
global launchpadDeleteButton
global launchpadUpdateButton
		
class LaunchpadTab extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "launchpadListView"
				 , "launchpadAddButton", "launchpadDeleteButton", "launchpadUpdateButton", "launchpadUpButton", "launchpadDownButton")
				 
		LaunchpadTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w377 h190 -Multi -LV0x10 NoSort NoSortHdr HwndlaunchpadListViewHandle VlaunchpadListView glistEvent, #|Label|Application
	
		Gui SE:Add, Button, x316 y272 w38 h23 Disabled VlaunchpadUpButton gupItem, Up
		Gui SE:Add, Button, x356 y272 w38 h23 Disabled VlaunchpadDownButton gdownItem, Down
		
		Gui SE:Add, Text, x16 y280 w86 h23 +0x200, Label
		Gui SE:Add, Edit, x110 y280 w80 h21 VlaunchpadLabelEdit, %launchpadLabelEdit%
		
		Gui SE:Add, Text, x16 y304 w86 h23 +0x200, Application
		Gui SE:Add, DropDownList, x110 y304 w284 h21 R10 Choose%launchpadApplicationDropdown% VlaunchpadApplicationDropdown
		
		Gui SE:Add, Button, x184 y490 w46 h23 VlaunchpadAddButton gaddItem, Add
		Gui SE:Add, Button, x232 y490 w50 h23 Disabled VlaunchpadDeleteButton gdeleteItem, Delete
		Gui SE:Add, Button, x340 y490 w55 h23 Disabled VlaunchpadUpdateButton gupdateItem, Update
		
		return launchpadListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		for category, launchpad in getConfigurationSectionValues(configuration, "Launchpad", Object()) {
			launchpad := string2Values("|", launchpad)

			this.iItemsList.Push(Array(launchpad[1], launchpad[2]))
		}
		
		this.loadApplicationChoices()
	}
		
	saveToConfiguration(configuration) {
		for index, launchpadApplication in this.iItemsList
			setConfigurationValue(configuration, "Launchpad", ConfigurationItem.descriptor("Button", index), values2String("|", launchpadApplication[1], launchpadApplication[2]))	
	}
	
	loadList(items) {
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		for index, launchpadApplication in items {
			LV_Add("", index, launchpadApplication[1], launchpadApplication[2])
		}
		
		LV_ModifyCol()
	}
	
	loadApplicationChoices(application := false) {
		launchpadApplicationsList := []
		
		for ignore, launchpadApplication in ApplicationsTab.Instance.Applications[["Other"]]
			launchpadApplicationsList.Push(launchpadApplication.Application)
		
		launchpadApplicationDropdown := (application ? inList(launchpadApplicationsList, application) : 0)
		
		GuiControl Text, launchpadApplicationDropdown, % "|" . values2String("|", launchpadApplicationsList*)
		GuiControl Choose, launchpadApplicationDropdown, % application ? application : ""
	}
	
	loadEditor(item) {
		launchpadLabelEdit := item[1]
		
		GuiControl Text, launchpadLabelEdit, %launchpadLabelEdit%
		
		this.loadApplicationChoices(item[2])
	}
	
	clearEditor() {
		launchpadLabelEdit := ""
		
		GuiControl Text, launchpadLabelEdit, %launchpadLabelEdit%
		
		this.loadApplicationChoices()
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet launchpadLabelEdit
		GuiControlGet launchpadApplicationDropdown
		
		return Array(launchpadLabelEdit, launchpadApplicationDropdown)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ChatMessagesTab                                                         ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global chatMessagesListView = false
global chatMessageLabelEdit = ""
global chatMessageMessageEdit = ""
global chatMessageUpButton
global chatMessageDownButton
global chatMessageAddButton
global chatMessageDeleteButton
global chatMessageUpdateButton
		
class ChatMessagesTab extends ConfigurationItemList {
	__New(configuration) {
		base.__New(configuration, this.createControls(configuration), "chatMessagesListView"
				 , "chatMessageAddButton", "chatMessageDeleteButton", "chatMessageUpdateButton", "chatMessageUpButton", "chatMessageDownButton")
				 
		ChatMessagesTab.Instance := this
	}
					
	createControls(configuration) {
		Gui SE:Add, ListView, x16 y80 w377 h190 -Multi -LV0x10 NoSort NoSortHdr HwndchatMessagesListViewHandle VchatMessagesListView glistEvent, #|Label|Message
		
		Gui SE:Add, Button, x316 y272 w38 h23 Disabled VchatMessageUpButton gupItem, Up
		Gui SE:Add, Button, x356 y272 w38 h23 Disabled VchatMessageDownButton gdownItem, Down
		
		Gui SE:Add, Text, x16 y280 w86 h23 +0x200, Label
		Gui SE:Add, Edit, x110 y280 w80 h21 VchatMessageLabelEdit, %chatMessageLabelEdit%
		
		Gui SE:Add, Text, x16 y304 w86 h23 +0x200, Message
		Gui SE:Add, Edit, x110 y304 w284 h21 VchatMessageMessageEdit, %chatMessageMessageEdit%
		
		Gui SE:Add, Button, x184 y490 w46 h23 VchatMessageAddButton gaddItem, Add
		Gui SE:Add, Button, x232 y490 w50 h23 Disabled VchatMessageDeleteButton gdeleteItem, Delete
		Gui SE:Add, Button, x340 y490 w55 h23 Disabled VchatMessageUpdateButton gupdateItem, Update
		
		return chatMessagesListViewHandle
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		for category, chatMessage in getConfigurationSectionValues(configuration, "Chat Messages", Object()) {
			chatMessage := string2Values("|", chatMessage)

			this.iItemsList.Push(Array(chatMessage[1], chatMessage[2]))
		}
	}
		
	saveToConfiguration(configuration) {
		for index, chatMessagesApplication in this.iItemsList
			setConfigurationValue(configuration, "Chat Messages", ConfigurationItem.descriptor("Button", index), values2String("|", chatMessagesApplication[1], chatMessagesApplication[2]))	
	}
	
	loadList(items) {
		Gui ListView, % this.ListHandle
	
		LV_Delete()
		
		for index, chatMessage in items {
			LV_Add("", index, chatMessage[1], chatMessage[2])
		}
		
		LV_ModifyCol()
	}
	
	loadEditor(item) {
		chatMessageLabelEdit := item[1]
		chatMessageMessageEdit := item[2]
			
		GuiControl Text, chatMessageLabelEdit, %chatMessageLabelEdit%
		GuiControl Text, chatMessageMessageEdit, %chatMessageMessageEdit%
	}
	
	clearEditor() {
		chatMessageLabelEdit := ""
		chatMessageMessageEdit := ""
		
		GuiControl Text, chatMessageLabelEdit, %chatMessageLabelEdit%
		GuiControl Text, chatMessageMessageEdit, %chatMessageMessageEdit%
	}
	
	buildItemFromEditor(isNew := false) {
		GuiControlGet chatMessageLabelEdit
		GuiControlGet chatMessageMessageEdit
		
		return Array(chatMessageLabelEdit, chatMessageMessageEdit)
	}
}

;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

showKeyDetector() {
	joystickNumbers := []

	SetTimer showKeyDetector, Off

	Loop 16 { ; Query each joystick number to find out which ones exist.
		GetKeyState joyName, %A_Index%JoyName
	
		if (joyName != "")
			joystickNumbers.Push(A_Index)
	}

	if (joystickNumbers.Length() == 0) {
		OnMessage(0x44, "translateMsgBoxButtons")
		MsgBox 262192, Warning, No joysticks detected...
		OnMessage(0x44, "")
		
		vShowKeyDetector := false
	}

	if vShowKeyDetector {
		found := false
		joystickNumber := joystickNumbers[1]
		
		joystickNumbers.RemoveAt(1)
		joystickNumbers.Push(joystickNumber)
		
		Loop {
			SetFormat Float, 03  ; Omit decimal point from axis position percentages.
		
			GetKeyState joy_buttons, %joystickNumber%JoyButtons
			GetKeyState joy_name, %joystickNumber%JoyName
			GetKeyState joy_info, %joystickNumber%JoyInfo

			if !vShowKeyDetector 
				break
			
			buttons_down := ""
			
			Loop %joy_buttons%
			{
				GetKeyState joy%A_Index%, %joystickNumber%joy%A_Index%
		
				if (joy%A_Index% = "D") {
					buttons_down = %buttons_down%%A_Space%%A_Index%
					
					found := true
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
			
			ToolTip %joy_name% (#%joystickNumber%):`n%axis_info%`nButtons Down: %buttons_down%, , , 1
						
			if found {
				found := false
				
				Sleep 1000
			}
			else				
				Sleep 100
			
			if vResult
				break
		}
	}
}

saveConfiguration(configurationFile, editor) {
	configuration := newConfiguration()

	editor.saveToConfiguration(configuration)

	writeConfiguration(configurationFile, configuration)
	
	EnvGet startupShortCut, appdata
	
	startupShortCut := startupShortCut . "\Microsoft\Windows\Start Menu\Programs\Startup\Simulator Startup.lnk"
	
	if getConfigurationValue(configuration, "Configuration", "Start With Windows", false) {
		startupExe := kBinariesDirectory . "Simulator Startup.exe"
		
		FileCreateShortCut %startupExe%, %startupShortCut%, %kBinariesDirectory%
	}
	else
		FileDelete %startupShortCut%
}

editSetup() {
	editor := new SetupEditor(FileExist("C:\Program Files\AutoHotkey") || GetKeyState("Shift"), GetKeyState("Ctrl") ? newConfiguration() : kSimulatorConfiguration)
	
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

setupSimulator() {
	icon := kIconsDirectory . "Setup.ico"
	
	Menu Tray, Icon, %icon%, , 1
	
	if editSetup()
		ExitApp 1
	else
		ExitApp 0
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

setupSimulator()