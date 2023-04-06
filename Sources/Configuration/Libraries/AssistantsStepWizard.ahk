﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Assistants Step Wizard          ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include Libraries\ControllerStepWizard.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; AssistantsStepWizard                                                    ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class AssistantsStepWizard extends ActionsStepWizard {
	iCurrentAssistant := false

	iControllerWidgets := []

	iActionsListViews := []
	iAssistantConfigurators := []

	iCachedActions := false

	Pages {
		Get {
			local wizard := this.SetupWizard
			local count := 0
			local ignore, assistant

			for ignore, assistant in this.Definition
				if wizard.isModuleSelected(assistant)
					count += 1

			return count
		}
	}

	TransposePage[page] {
		Get {
			local wizard := this.SetupWizard
			local count := 0
			local index, assistant

			for index, assistant in this.Definition
				if (wizard.isModuleSelected(assistant) && (++count == page))
					return index

			return 0
		}
	}

	saveToConfiguration(configuration) {
		local wizard := this.SetupWizard
		local assistantActive := false
		local function, action, ignore, assistant, assistantConfiguration, section, subConfiguration, arguments
		local actions

		super.saveToConfiguration(configuration)

		for ignore, assistant in this.Definition
			if wizard.isModuleSelected(assistant) {
				assistantActive := true

				assistantConfiguration := readMultiMap(kUserHomeDirectory . "Setup\" . assistant . " Configuration.ini")

				for ignore, section in ["Race Assistant Startup", "Race Assistant Shutdown", "Race Engineer Startup", "Race Engineer Shutdown"
									  , "Race Strategist Startup", "Race Strategist Shutdown"
									  , "Race Engineer Analysis", "Race Strategist Analysis", "Race Strategist Reports"
									  , "Race Spotter Analysis", "Race Spotter Announcements"] {
					subConfiguration := getMultiMapValues(assistantConfiguration, section, false)

					if subConfiguration
						setMultiMapValues(configuration, section, subConfiguration)
				}

				if (assistant = "Race Engineer")
					arguments := "raceAssistantName: Jona"
				else if (assistant = "Race Strategist")
					arguments := "raceAssistantName: Khato"
				else if (assistant = "Race Spotter")
					arguments := "raceAssistantName: Elisa"
				else
					throw "Unsupported race assistant detected in AssistantsStepWizard.saveToConfiguration..."

				actions := ""

				for ignore, action in string2Values(",", getMultiMapValue(wizard.Definition, "Setup.Assistants", "Assistants.Actions"))
					if wizard.assistantActionAvailable(assistant, action) {
						function := wizard.getAssistantActionFunction(assistant, action)

						if !isObject(function)
							function := ((function != "") ? Array(function) : [])

						if (function.Length() > 0) {
							if (actions != "")
								actions .= ", "

							actions .= (StrReplace(action, "InformationRequest.", "InformationRequest ") . A_Space . values2String(A_Space, function*))
						}
					}

				if (actions != "")
					arguments .= ("; assistantCommands: " . actions)

				if wizard.isModuleSelected("Voice Control")
					arguments .= "; raceAssistantSpeaker: On; raceAssistantListener: On"
				else
					arguments .= "; raceAssistantSpeaker: Off"

				for ignore, action in string2Values(",", getMultiMapValue(wizard.Definition, "Setup.Assistants", "Assistants.Actions.Special"))
					if wizard.assistantActionAvailable(assistant, action) {
						function := wizard.getAssistantActionFunction(assistant, action)

						if !isObject(function)
							function := ((function != "") ? Array(function) : [])

						if (function.Length() > 0)
							switch action {
								case "RaceAssistant":
									arguments .= ("; raceAssistant: On " . values2String(A_Space, function*))
								case "TeamServer":
									arguments .= ("; teamServer: Off " . values2String(A_Space, function*))
								case "SessionDatabaseOpen", "SetupDatabaseOpen":
									arguments .= ("; openSessionDatabase: " . values2String(A_Space, function*))
								case "RaceSettingsOpen":
									arguments .= ("; openRaceSettings: " . values2String(A_Space, function*))
								case "StrategyWorkbenchOpen":
									arguments .= ("; openStrategyWorkbench: " . values2String(A_Space, function*))
								case "RaceCenterOpen":
									arguments .= ("; openRaceCenter: " . values2String(A_Space, function*))
								case "SetupWorkbenchOpen":
									arguments .= ("; openSetupWorkbench: " . values2String(A_Space, function*))
								case "SetupImport":
									arguments .= ("; importSetup: " . values2String(A_Space, function*))
								default:
									throw "Unsupported special action detected in AssistantsStepWizard.saveToConfiguration..."
							}
					}

				new Plugin(assistant, false, true, "", arguments).saveToConfiguration(configuration)
			}
			else
				new Plugin(assistant, false, false, "", "").saveToConfiguration(configuration)

		new Plugin("Team Server", false, assistantActive, "", "").saveToConfiguration(configuration)
	}

	createGui(wizard, x, y, width, height) {
		local window := this.Window
		local page, assistant, labelWidth, labelX, labelY, label
		local actionsIconHandle, actionsIconLabelHandle, actionsListViewHandle, actionsInfoTextHandle
		local colummLabel1Handle, colummLine1Handle, colummLabel2Handle, colummLine2Handle, listX, listY, listWidth
		local info, html, configurator, colWidth

		static actionsInfoText1
		static actionsInfoText2
		static actionsInfoText3
		static actionsInfoText4
		static actionsInfoText5

		Gui %window%:Default

		for page, assistant in this.Definition {
			actionsIconHandle := false
			actionsIconLabelHandle := false
			actionsListViewHandle := false
			actionsInfoTextHandle := false

			labelWidth := width - 30
			labelX := x + 35
			labelY := y + 8

			Gui %window%:Font, s10 Bold, Arial

			label := substituteVariables(translate("%assistant% Configuration"), {assistant: translate(assistant)})

			Gui %window%:Add, Picture, x%x% y%y% w30 h30 HWNDactionsIconHandle Hidden, %kResourcesDirectory%Setup\Images\Artificial Intelligence.ico
			Gui %window%:Add, Text, x%labelX% y%labelY% w%labelWidth% h26 HWNDactionsLabelHandle Hidden Section, % label

			Gui %window%:Font, s8 Norm, Arial

			colummLabel1Handle := false
			colummLine1Handle := false
			colummLabel2Handle := false
			colummLine2Handle := false

			listX := x + 375
			listY := labelY + 30
			listWidth := width - 375

			Gui %window%:Font, Bold, Arial

			Gui %window%:Add, Text, x%listX% yp+30 w%listWidth% h23 +0x200 HWNDcolumnLabel1Handle Hidden Section, % translate("Actions")
			Gui %window%:Add, Text, yp+20 x%listX% w%listWidth% 0x10 HWNDcolumnLine1Handle Hidden

			Gui %window%:Font, Norm, Arial

			Gui %window%:Add, ListView, x%listX% yp+10 w%listWidth% h347 AltSubmit -Multi -LV0x10 NoSort NoSortHdr HWNDactionsListViewHandle gupdateAssistantActionFunction Hidden, % values2String("|", collect(["Action", "Label", "Function"], "translate")*)

			info := substituteVariables(getMultiMapValue(this.SetupWizard.Definition, "Setup.Assistants", "Assistants.Actions.Info." . getLanguage()))
			info := "<div style='font-family: Arial, Helvetica, sans-serif' style='font-size: 11px'><hr style='width: 90%'>" . info . "</div>"

			Sleep 200

			Gui %window%:Add, ActiveX, x%x% yp+352 w%width% h58 HWNDactionsInfoTextHandle VactionsInfoText%page% Hidden, shell.explorer

			html := "<html><body style='background-color: #D0D0D0' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>" . info . "</body></html>"

			actionsInfoText%page%.Navigate("about:blank")
			actionsInfoText%page%.Document.Write(html)

			this.iActionsListViews.Push(actionsListViewHandle)

			if (assistant = "Race Engineer")
				configurator := RaceEngineerConfigurator(this)
			else if (assistant = "Race Strategist")
				configurator := RaceStrategistConfigurator(this)
			else if (assistant = "Race Spotter")
				configurator := RaceSpotterConfigurator(this)
			else
				configurator := false

			colWidth := 375 - x

			Gui %window%:Font, Bold, Arial

			Gui %window%:Add, Text, x%x% ys w%colWidth% h23 +0x200 HWNDcolumnLabel2Handle Hidden Section, % translate("Configuration")
			Gui %window%:Add, Text, yp+20 x%x% w%colWidth% 0x10 HWNDcolumnLine2Handle Hidden

			Gui %window%:Font, Norm, Arial

			if configurator {
				this.iAssistantConfigurators.Push(configurator)

				configurator.createGui(this, x, listY + 30, colWidth, height)
			}

			this.iControllerWidgets.Push(columnLabel1Handle)
			this.iControllerWidgets.Push(columnLine1Handle)

			this.registerWidgets(page, actionsIconHandle, actionsLabelHandle, actionsListViewHandle, actionsInfoTextHandle, columnLabel1Handle, columnLine1Handle, columnLabel2Handle, columnLine2Handle)
		}
	}

	registerWidget(page, widget) {
		local index := inList(this.iAssistantConfigurators, page)

		if index
			super.registerWidget(index, widget)
		else
			super.registerWidget(page, widget)
	}

	reset() {
		super.reset()

		this.iControllerWidgets := []

		this.iAssistantConfigurators := []
		this.iActionsListViews := []
		this.iCachedActions := false
	}

	showPage(page) {
		local ignore, widget, configuration, assistantConfiguration, section, subConfiguration

		page := this.TransposePage[page]

		this.iCurrentAssistant := this.Definition[page]

		this.setActionsListView(this.iActionsListViews[page])

		super.showPage(page)

		if !this.SetupWizard.isModuleSelected("Controller")
			for ignore, widget in this.iControllerWidgets
				GuiControl Hide, %widget%

		configuration := this.SetupWizard.getSimulatorConfiguration()
		assistantConfiguration := readMultiMap(kUserHomeDirectory . "Setup\" . this.iCurrentAssistant . " Configuration.ini")

		for ignore, section in ["Race Assistant Startup", "Race Assistant Shutdown", "Race Engineer Startup", "Race Engineer Shutdown"
							  , "Race Strategist Startup", "Race Strategist Shutdown"
							  , "Race Engineer Analysis", "Race Strategist Analysis", "Race Strategist Reports"
							  , "Race Spotter Analysis", "Race Spotter Announcements"] {
			subConfiguration := getMultiMapValues(assistantConfiguration, section, false)

			if subConfiguration
				setMultiMapValues(configuration, section, subConfiguration)
		}

		this.iAssistantConfigurators[page].loadConfigurator(configuration, this.getSimulators())
	}

	hidePage(page) {
		local ignore, configurator, configuration, assistantConfiguration, section, subConfiguration

		page := this.TransposePage[page]

		if super.hidePage(page) {
			configurator := this.iAssistantConfigurators[page]

			configuration := newMultiMap()

			configurator.saveToConfiguration(configuration)

			assistantConfiguration := newMultiMap()

			for ignore, section in ["Race Assistant Startup", "Race Assistant Shutdown", "Race Engineer Startup", "Race Engineer Shutdown"
								  , "Race Strategist Startup", "Race Strategist Shutdown"
								  , "Race Engineer Analysis", "Race Strategist Analysis", "Race Strategist Reports"
								  , "Race Spotter Analysis", "Race Spotter Announcements"] {
				subConfiguration := getMultiMapValues(configuration, section, false)

				if subConfiguration
					setMultiMapValues(assistantConfiguration, section, subConfiguration)
			}

			writeMultiMap(kUserHomeDirectory . "Setup\" . this.iCurrentAssistant . " Configuration.ini", assistantConfiguration)

			return true
		}
		else
			return false
	}

	getSimulators() {
		if this.iCurrentAssistant
			return this.SetupWizard.assistantSimulators(this.iCurrentAssistant)
		else
			return []
	}

	getModule() {
		return this.iCurrentAssistant
	}

	getModes() {
		return [false]
	}

	getActions(mode := false) {
		local wizard, actions

		if this.iCachedActions
			return this.iCachedActions
		else {
			wizard := this.SetupWizard

			actions := concatenate(string2Values(",", getMultiMapValue(wizard.Definition, "Setup.Assistants", "Assistants.Actions"))
								 , string2Values(",", getMultiMapValue(wizard.Definition, "Setup.Assistants", "Assistants.Actions.Special")))

			wizard.setModuleAvailableActions(this.iCurrentAssistant, false, actions)

			this.iCachedActions := actions

			return actions
		}
	}

	setAction(row, mode, action, actionDescriptor, label, argument := false) {
		local wizard := this.SetupWizard
		local function, functions, ignore

		super.setAction(row, mode, action, actionDescriptor, label, argument)

		functions := this.getActionFunction(false, action)

		if functions
			for ignore, function in functions
				if (function && (function != ""))
					wizard.addModuleStaticFunction(this.iCurrentAssistant, function, label)
	}

	clearActionFunction(mode, action, function) {
		super.clearActionFunction(mode, action, function)

		this.SetupWizard.removeModuleStaticFunction(this.iCurrentAssistant, function)
	}

	loadActions(load := false) {
		if (this.iCurrentAssistant && this.SetupWizard.isModuleSelected(this.iCurrentAssistant))
			this.loadAssistantActions(this.iCurrentAssistant, load)
	}

	saveActions() {
		if (this.iCurrentAssistant && this.SetupWizard.isModuleSelected(this.iCurrentAssistant))
			this.saveAssistantActions(this.iCurrentAssistant)
	}

	loadAssistantActions(assistant, load := false) {
		local window := this.Window
		local wizard := this.SetupWizard
		local function, ignore, action, subAction, count, pluginLabels, count, isInformationRequest, isBinary, label

		if load {
			this.iCachedActions := false

			this.clearActionFunctions()
		}

		this.clearActions()

		Gui %window%:Default

		Gui ListView, % this.ActionsListView

		pluginLabels := getControllerActionLabels()

		LV_Delete()

		count := 1

		for ignore, action in this.getActions() {
			if wizard.assistantActionAvailable(assistant, action) {
				if load {
					function := wizard.getAssistantActionFunction(assistant, action)

					if (function != "")
						this.setActionFunction(false, action, (isObject(function) ? function : Array(function)))
				}

				subAction := ConfigurationItem.splitDescriptor(action)

				if (subAction[1] = "InformationRequest") {
					subAction := subAction[2]

					isInformationRequest := true
				}
				else {
					subAction := subAction[1]

					isInformationRequest := false
				}

				label := getMultiMapValue(pluginLabels, assistant, subAction . ".Toggle", kUndefined)

				if (label == kUndefined) {
					label := getMultiMapValue(pluginLabels, assistant, subAction . ".Activate", "")

					this.setAction(count, false, action, [isInformationRequest, "Activate"], label)

					isBinary := false
				}
				else {
					if (getMultiMapValue(pluginLabels, assistant, subAction . ".Increase", kUndefined) != kUndefined)
						this.setAction(count, false, action, [isInformationRequest, "Toggle", "Increase", "Decrease"], label)
					else
						this.setAction(count, false, action, [isInformationRequest, "Toggle", false, false], label)

					isBinary := true
				}

				function := this.getActionFunction(false, action)

				if function {
					if (function.Length() == 1)
						function := (!isBinary ? function[1] : (translate("On/Off: ") . function[1]))
					else
						function := (translate("On: ") . function[1] . translate(" | Off: ") . function[2])
				}
				else
					function := ""

				LV_Add("", subAction, StrReplace(label, "`n" , A_Space), function)

				count += 1
			}
		}

		this.loadControllerLabels()

		LV_ModifyCol(1, "AutoHdr")
		LV_ModifyCol(2, "AutoHdr")
		LV_ModifyCol(3, "AutoHdr")
	}

	saveAssistantActions(assistant) {
		local wizard := this.SetupWizard
		local functions := {}
		local function, ignore, action

		for ignore, action in this.getActions()
			if wizard.assistantActionAvailable(assistant, action) {
				function := this.getActionFunction(false, action)

				if (function && (function != ""))
					functions[action] := function
			}

		wizard.setAssistantActionFunctions(assistant, functions)
		wizard.setModuleActionFunctions(assistant, false, functions)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

updateAssistantActionFunction() {
	updateActionFunction(SetupWizard.Instance.StepWizards["Assistants"])
}

initializeAssistantsStepWizard() {
	SetupWizard.Instance.registerStepWizard(AssistantsStepWizard(SetupWizard.Instance, "Assistants", kSimulatorConfiguration))
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeAssistantsStepWizard()