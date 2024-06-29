﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Assistant Booster Editor        ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2024) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                          Local Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Libraries\LLMConnector.ahk"
#Include "..\..\Libraries\RuleEngine.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Framework\Framework.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Libraries\SpeechSynthesizer.ahk"
#Include "..\..\Libraries\LLMConnector.ahk"
#Include "..\..\Libraries\JSON.ahk"
#Include "ConfigurationEditor.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; AssistantBoosterEditor                                                  ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class AssistantBoosterEditor extends ConfiguratorPanel {
	iResult := false

	iAssistant := false

	iWindow := false

	iProviderConfigurations := CaseInsenseMap()
	iCurrentProvider := false

	iInstructions := newMultiMap()

	Assistant {
		Get {
			return this.iAssistant
		}
	}

	Window {
		Get {
			return this.iWindow
		}
	}

	Providers {
		Get {
			return LLMConnector.Providers
		}
	}

	Models[provider] {
		Get {
			try {
				return LLMConnector.%StrReplace(provider, A_Space, "")%Connector.Models
			}
			catch Any {
				return []
			}
		}
	}

	__New(assistant, configuration := false) {
		this.iAssistant := assistant

		super.__New(configuration)
	}

	createGui(configuration) {
		local choices := []
		local chosen := 0
		local x := 8
		local width := 460
		local editorGui, x0, x1, x2, w1, w2, x3, w3, x4, w4
		local x0, x1, x2, x3, x4, x5, x6, w1, w2, w3, w4, lineX, lineW

		validatePercentage(field, *) {
			local value

			field := this.Control[field]
			value := field.Text

			if (!isInteger(value) || (value < 0) || (value > 100)) {
				field.Text := (field.HasProp("ValidText") ? field.ValidText : "")

				loop 10
					SendInput("{Right}")
			}
			else
				field.ValidText := field.Text

			this.updateState()
		}

		validateTokens(*) {
			local field := this.Control["viMaxTokensEdit"]
			local value := field.Text

			if (!isInteger(value) || (value < 32)) {
				field.Text := (field.HasProp("ValidText") ? field.ValidText : "200")

				loop 10
					SendInput("{Right}")
			}
			else
				field.ValidText := field.Text
		}

		chooseProvider(*) {
			this.saveProviderConfiguration()

			this.loadProviderConfiguration(editorGui["viProviderDropDown"].Text)

			this.updateState()
		}

		editInstructions(type, title, *) {
			this.editInstructions(type, title)
		}

		editEvents(*) {
			this.editEvents(this.Assistant)
		}

		editActions(type, *) {
			this.editActions(this.Assistant, type)
		}

		loadModels(*) {
			local provider := this.iCurrentProvider
			local configuration

			if provider {
				configuration := this.iProviderConfigurations[provider]

				this.loadModels(provider, this.Control["viServiceURLEdit"].Text
										, this.Control["viServiceKeyEdit"].Text
										, this.Control["viModelDropDown"].Text)
			}
			else
				this.loadModels(false)
		}

		editorGui := Window({Descriptor: "Booster Editor", Options: "0x400000"})

		this.iWindow := editorGui

		editorGui.SetFont("Bold", "Arial")

		editorGui.Add("Text", "w468 H:Center Center", translate("Modular Simulator Controller System")).OnEvent("Click", moveByMouse.Bind(editorGui, "Booster Editor"))

		editorGui.SetFont("Norm", "Arial")

		editorGui.Add("Documentation", "x178 YP+20 w128 H:Center Center", translate("Assistant Booster")
					, "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#boosting-conversation-with-an-llm")

		editorGui.SetFont("Norm", "Arial")

		editorGui.Add("Text", "x8 yp+30 w468 W:Grow 0x10")

		x0 := x + 8
		x1 := x + 132
		x2 := x + 172
		x3 := x + 176

		w1 := width - (x1 - x + 8)
		w3 := width - (x3 - x + 16) + 10

		w2 := w1 - 24
		x4 := x1 + w2 + 1

		w4 := w1 - 24
		x6 := x1 + w4 + 1

		editorGui.SetFont("Italic", "Arial")
		widget1 := editorGui.Add("Text", "x" . x0 . " yp+10 w105 h23", translate("Service "))
		widget2 := editorGui.Add("Text", "x100 yp+7 w" . (width + 8 - 100) . " 0x10 W:Grow")
		editorGui.SetFont("Norm", "Arial")

		widget3 := editorGui.Add("Text", "x" . x0 . " yp+20 w105 h23 +0x200", translate("Provider / URL"))

		widget4 := editorGui.Add("DropDownList", "x" . x1 . " yp w100 Choose1 vviProviderDropDown", concatenate([translate("None")], this.Providers))
		widget4.OnEvent("Change", chooseProvider)

		widget5 := editorGui.Add("Edit", "x" . (x1 + 102) . " yp w" . (w1 - 102) . " h23 vviServiceURLEdit")
		widget5.OnEvent("Change", loadModels)

		widget6 := editorGui.Add("Text", "x" . x0 . " yp+24 w105 h23 +0x200", translate("Service Key"))
		widget7 := editorGui.Add("Edit", "x" . x1 . " yp w" . w1 . " h23 Password vviServiceKeyEdit")
		widget7.OnEvent("Change", loadModels)

		widget8 := editorGui.Add("Text", "x" . x0 . " yp+30 w105 h23 +0x200", translate("Model / # Tokens"))
		widget9 := editorGui.Add("ComboBox", "x" . x1 . " yp w" . (w1 - 64) . " vviModelDropDown")
		widget10 := editorGui.Add("Edit", "x" . (x1 + (w1 - 60)) . " yp-1 w60 h23 Number vviMaxTokensEdit")
		widget10.OnEvent("Change", validateTokens)
		widget11 := editorGui.Add("UpDown", "x" . (x1 + (w1 - 60)) . " yp w60 h23 Range32-131072")

		editorGui.SetFont("Italic", "Arial")
		widget12 := editorGui.Add("Checkbox", "x" . x0 . " yp+36 w105 h23 vviSpeakerCheck", translate("Rephrasing"))
		widget12.OnEvent("Click", (*) => this.updateState())
		widget13 := editorGui.Add("Text", "x100 yp+11 w" . (width + 8 - 100) . " 0x10 W:Grow")
		editorGui.SetFont("Norm", "Arial")

		widget14 := editorGui.Add("Text", "x" . x0 . " yp+20 w105 h23 +0x200", translate("Activation"))
		widget15 := editorGui.Add("Edit", "x" . x1 . " yp w60 Number Limit3 vviSpeakerProbabilityEdit")
		widget15.OnEvent("Change", validatePercentage.Bind("viSpeakerProbabilityEdit"))
		widget16 := editorGui.Add("UpDown", "x" . x1 . " yp w60 h23 Range0-100")
		widget17 := editorGui.Add("Text", "x" . (x1 + 65) . " yp w100 h23 +0x200", translate("%"))

		widget40 := editorGui.Add("Button", "x" . (width + 8 - 100) . " yp w100 h23 X:Move vviSpeakerInstructionsButton", translate("Instructions..."))
		widget40.OnEvent("Click", editInstructions.Bind("Speaker", translate("Rephrasing")))

		widget18 := editorGui.Add("Text", "x" . x0 . " yp+24 w105 h23 +0x200", translate("Creativity"))
		widget19 := editorGui.Add("Edit", "x" . x1 . " yp w60 Number Limit3 vviSpeakerTemperatureEdit")
		widget19.OnEvent("Change", validatePercentage.Bind("viSpeakerTemperatureEdit"))
		widget20 := editorGui.Add("UpDown", "x" . x1 . " yp w60 h23 Range0-100")
		widget21 := editorGui.Add("Text", "x" . (x1 + 65) . " yp w100 h23 +0x200", translate("%"))

		editorGui.SetFont("Italic", "Arial")
		widget22 := editorGui.Add("Checkbox", "x" . x0 . " yp+36 w105 h23 vviListenerCheck", translate("Understanding"))
		widget22.OnEvent("Click", (*) => this.updateState())
		widget23 := editorGui.Add("Text", "x100 yp+11 w" . (width + 8 - 100) . " 0x10 W:Grow")
		editorGui.SetFont("Norm", "Arial")

		widget24 := editorGui.Add("Text", "x" . x0 . " yp+20 w105 h23 +0x200", translate("Activation"))
		widget25:= editorGui.Add("DropDownList", "x" . x1 . " yp w100 Choose1 vviListenerModeDropDown", collect(["Always", "Unrecognized"], translate))
		widget25.OnEvent("Change", (*) => this.updateState())

		widget41 := editorGui.Add("Button", "x" . (width + 8 - 100) . " yp w100 h23 X:Move vviListenerInstructionsButton", translate("Instructions..."))
		widget41.OnEvent("Click", editInstructions.Bind("Listener", translate("Understanding")))

		widget26 := editorGui.Add("Text", "x" . x0 . " yp+24 w105 h23 +0x200", translate("Creativity"))
		widget27 := editorGui.Add("Edit", "x" . x1 . " yp w60 Number Limit3 vviListenerTemperatureEdit")
		widget27.OnEvent("Change", validatePercentage.Bind("viListenerTemperatureEdit"))
		widget28 := editorGui.Add("UpDown", "x" . x1 . " yp w60 h23 Range0-100")
		widget29 := editorGui.Add("Text", "x" . (x1 + 65) . " yp w100 h23 +0x200", translate("%"))

		editorGui.SetFont("Italic", "Arial")
		widget30 := editorGui.Add("Checkbox", "x" . x0 . " yp+36 w105 h23 vviConversationCheck", translate("Conversation"))
		widget30.OnEvent("Click", (*) => this.updateState())
		widget31 := editorGui.Add("Text", "x100 yp+11 w" . (width + 8 - 100) . " 0x10 W:Grow")
		editorGui.SetFont("Norm", "Arial")

		widget32 := editorGui.Add("Text", "x" . x0 . " yp+24 w105 h23 +0x200", translate("Memory"))
		widget33 := editorGui.Add("Edit", "x" . x1 . " yp w60 h23 Number Limit2 vviConversationMaxHistoryEdit")
		widget34 := editorGui.Add("UpDown", "x" . x1 . " yp w60 h23 Range1-10")
		widget35 := editorGui.Add("Text", "x" . (x1 + 65) . " yp w100 h23 +0x200", translate("Conversations"))

		widget43 := editorGui.Add("Button", "x" . (width + 8 - 100) . " yp w100 h23 X:Move vviConversationInstructionsButton", translate("Instructions..."))
		widget43.OnEvent("Click", editInstructions.Bind("Conversation", translate("Conversation")))

		widget36 := editorGui.Add("Text", "x" . x0 . " yp+24 w105 h23 +0x200", translate("Creativity"))
		widget37 := editorGui.Add("Edit", "x" . x1 . " yp w60 Number Limit3 vviConversationTemperatureEdit")
		widget37.OnEvent("Change", validatePercentage.Bind("viConversationTemperatureEdit"))
		widget38 := editorGui.Add("UpDown", "x" . x1 . " yp w60 h23 Range0-100")
		widget39 := editorGui.Add("Text", "x" . (x1 + 65) . " yp w100 h23 +0x200", translate("%"))

		widget40 := editorGui.Add("Text", "x" . x0 . " yp+24 w105 h23 +0x200", translate("Actions"))
		widget41 := editorGui.Add("DropDownList", "x" . x1 . " yp w60 vviConversationActionsDropdown", collect(["Yes", "No"], translate))
		widget41.OnEvent("Change", (*) => this.updateState())
		widget42 := editorGui.Add("Button", "x" . (x1 + 61) . " yp-1 w23 h23 X:Move Center +0x200 vviConversationEditActionsButton")
		widget42.OnEvent("Click", editActions.Bind("Conversation.Actions"))
		setButtonIcon(widget42, kIconsDirectory . "Pencil.ico", 1, "L4 T4 R4 B4")

		editorGui.SetFont("Italic", "Arial")
		widget44 := editorGui.Add("Checkbox", "x" . x0 . " yp+36 w105 h23 vviAgentCheck", translate("Behavior"))
		widget44.OnEvent("Click", (*) => this.updateState())
		widget45 := editorGui.Add("Text", "x100 yp+11 w" . (width + 8 - 100) . " 0x10 W:Grow")
		editorGui.SetFont("Norm", "Arial")

		widget46 := editorGui.Add("Button", "x" . x0 . " yp+24 w100 h23 vviAgentEventsButton", translate("Events..."))
		widget46.OnEvent("Click", editEvents)

		widget47 := editorGui.Add("Button", "x" . x0 + Round((width / 2) - 50) . " yp w100 h23 vviAgentActionsButton X:Move(0.5)", translate("Actions..."))
		widget47.OnEvent("Click", editActions.Bind("Agent.Actions"))

		widget48 := editorGui.Add("Button", "x" . (width + 8 - 100) . " yp w100 h23 X:Move vviAgentInstructionsButton", translate("Instructions..."))
		widget48.OnEvent("Click", editInstructions.Bind("Agent", translate("Behavior")))

		editorGui.Add("Text", "x8 yp+35 w468 W:Grow 0x10")

		editorGui.Add("Button", "x160 yp+10 w80 h23 Default", translate("Ok")).OnEvent("Click", (*) => this.iResult := kOk)
		editorGui.Add("Button", "x246 yp w80 h23", translate("&Cancel")).OnEvent("Click", (*) => this.iResult := kCancel)
	}

	loadModels(provider, serviceURL := false, serviceKey := false, model := false) {
		local connector, index, models

		if provider {
			try {
				connector := LLMConnector.%StrReplace(provider, A_Space, "")%Connector(this, model)

				if isInstance(connector, LLMConnector.APIConnector) {
					connector.Connect(serviceURL, serviceKey)

					models := connector.Models
				}
				else
					models := this.Models[provider]
			}
			catch Any as exception {
				models := this.Models[provider]
			}
		}
		else
			models := []

		if model {
			index := inList(models, model)

			if !index {
				index := inList(models, StrReplace(model, A_Space, "-"))

				if index
					model := models[index]
			}

			if !index
				models := concatenate(models, [model])
		}

		this.Control["viModelDropDown"].Delete()
		this.Control["viModelDropDown"].Add(models)

		if model
			this.Control["viModelDropDown"].Choose(inList(models, model))
		else
			this.Control["viModelDropDown"].Choose((models.Length > 0) ? 1 : 0)
	}

	normalizeConfiguration(configuration) {
		local ignore, type, section, values, key, value

		for ignore, type in ["Speaker", "Listener", "Conversation"]
			for section, values in this.getInstructions(type, true)
				for key, value in values
					if (getMultiMapValue(configuration, section, key) = value)
						removeMultiMapValue(configuration, section, key)
	}

	loadFromConfiguration(configuration) {
		local service, ignore, provider, setting, providerConfiguration
		local serviceURL, serviceKey, model

		static defaults := CaseInsenseWeakMap("ServiceURL", false, "Model", "", "MaxTokens", 2048
											, "Speaker", true, "SpeakerTemperature", 0.5, "SpeakerProbability", 0.5
											, "Listener", false, "ListenerMode", "Unknown", "ListenerTemperature", 0.5
											, "Conversation", false, "ConversationMaxHistory", 3, "ConversationTemperature", 0.5
											, "ConversationActions", false
											, "Agent", false)

		super.loadFromConfiguration(configuration)

		service := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".Service", false)

		this.iCurrentProvider := (service ? string2Values("|", service)[1] : false)

		for ignore, provider in this.Providers {
			providerConfiguration := CaseInsenseMap()

			if (provider = this.iCurrentProvider) {
				providerConfiguration["Model"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".Model", defaults["Model"])
				providerConfiguration["MaxTokens"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".MaxTokens", defaults["MaxTokens"])

				providerConfiguration["Speaker"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".Speaker", defaults["Speaker"])
				providerConfiguration["SpeakerProbability"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".SpeakerProbability", defaults["SpeakerProbability"])
				providerConfiguration["SpeakerTemperature"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".SpeakerTemperature", defaults["SpeakerTemperature"])

				providerConfiguration["Listener"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".Listener", defaults["Listener"])
				providerConfiguration["ListenerMode"] := ["Always", "Unknown"][2 - (getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".ListenerMode", defaults["ListenerMode"]) = "Always")]
				providerConfiguration["ListenerTemperature"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".ListenerTemperature", defaults["ListenerTemperature"])

				providerConfiguration["Conversation"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".Conversation", defaults["Conversation"])
				providerConfiguration["ConversationMaxHistory"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".ConversationMaxHistory", defaults["ConversationMaxHistory"])
				providerConfiguration["ConversationTemperature"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".ConversationTemperature", defaults["ConversationTemperature"])
				providerConfiguration["ConversationActions"] := getMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".ConversationActions", defaults["ConversationActions"])

				providerConfiguration["Agent"] := getMultiMapValue(configuration, "Agent Booster", this.Assistant . ".Agent", defaults["Agent"])

				if (provider = "LLM Runtime") {
					providerConfiguration["ServiceURL"] := ""
					providerConfiguration["ServiceKey"] := ""
				}
				else {
					providerConfiguration["ServiceURL"] := string2Values("|", service)[2]
					providerConfiguration["ServiceKey"] := string2Values("|", service)[3]
				}
			}
			else {
				for ignore, setting in ["ServiceURL", "ServiceKey", "Model", "MaxTokens"]
					providerConfiguration[setting] := getMultiMapValue(configuration, "Conversation Booster", provider . "." . setting, defaults[setting])

				try {
					LLMConnector.%StrReplace(provider, A_Space, "")%Connector.GetDefaults(&serviceURL, &serviceKey, &model)
				}
				catch Any {
					serviceURL := ""
					serviceKey := ""
					model := ""
				}

				if !providerConfiguration["ServiceURL"]
					providerConfiguration["ServiceURL"] := serviceURL

				if !providerConfiguration["ServiceKey"]
					providerConfiguration["ServiceKey"] := serviceKey

				if (providerConfiguration["Model"] = "")
					providerConfiguration["Model"] := model

				for ignore, setting in ["Speaker", "SpeakerProbability", "SpeakerTemperature"
									  , "Listener", "ListenerMode", "ListenerTemperature"
									  , "Conversation", "ConversationMaxHistory", "ConversationTemperature", "ConversationActions"
									  , "Agent"]
					providerConfiguration[setting] := getMultiMapValue(configuration, "Conversation Booster", provider . "." . setting, defaults[setting])
			}

			this.iProviderConfigurations[provider] := providerConfiguration
		}
	}

	saveToConfiguration(configuration) {
		local ignore, provider, reference, setting, value

		super.saveToConfiguration(configuration)

		this.saveProviderConfiguration()

		addMultiMapValues(configuration, this.iInstructions)

		this.normalizeConfiguration(configuration)

		for ignore, provider in this.Providers {
			providerConfiguration := this.iProviderConfigurations[provider]

			for ignore, setting in ["ServiceURL", "ServiceKey", "Model", "MaxTokens"]
				setMultiMapValue(configuration, "Conversation Booster", provider . "." . setting, providerConfiguration[setting])

			for ignore, setting in ["Speaker", "SpeakerProbability", "SpeakerTemperature"
								  , "Listener", "ListenerMode", "ListenerTemperature"
								  , "Conversation", "ConversationMaxHistory", "ConversationTemperature", "ConversationActions"] {
				setMultiMapValue(configuration, "Conversation Booster", provider . "." . setting, providerConfiguration[setting])

				if (provider = this.iCurrentProvider)
					setMultiMapValue(configuration, "Conversation Booster", this.Assistant . "." . setting, providerConfiguration[setting])
			}

			setMultiMapValue(configuration, "Agent Booster", provider . ".Agent", providerConfiguration["Agent"])

			if (provider = this.iCurrentProvider)
				setMultiMapValue(configuration, "Agent Booster", this.Assistant . ".Agent", providerConfiguration["Agent"])
		}

		provider := this.iCurrentProvider

		if provider {
			providerConfiguration := this.iProviderConfigurations[provider]

			for ignore, reference in ["Conversation Booster", "Agent Booster"] {
				setMultiMapValue(configuration, reference, this.Assistant . ".Model", providerConfiguration["Model"])

				if (reference = "Conversation Booster")
					setMultiMapValue(configuration, reference, this.Assistant . ".MaxTokens", providerConfiguration["MaxTokens"])

				if (provider = "LLM Runtime")
					setMultiMapValue(configuration, reference, this.Assistant . ".Service", provider)
				else
					setMultiMapValue(configuration, reference, this.Assistant . ".Service"
												  , values2String("|", provider, Trim(providerConfiguration["ServiceURL"])
																			   , Trim(providerConfiguration["ServiceKey"])))
			}
		}
		else {
			setMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".SpeakerProbability", false)
			setMultiMapValue(configuration, "Conversation Booster", this.Assistant . ".SpeakerTemperature", false)

			for ignore, reference in ["Conversation Booster", "Agent Booster"] {
				setMultiMapValue(configuration, reference, this.Assistant . ".Model", false)
				setMultiMapValue(configuration, reference, this.Assistant . ".Service", false)
			}
		}
	}

	loadProviderConfiguration(provider) {
		local configuration

		this.Control["viProviderDropDown"].Choose(inList(this.Providers, provider) + 1)

		if (this.Control["viProviderDropDown"].Value = 1) {
			this.iCurrentProvider := false

			for ignore, setting in ["ServiceURL", "ServiceKey", "MaxTokens", "SpeakerProbability", "SpeakerTemperature", "ListenerTemperature", "ConversationMaxHistory", "ConversationTemperature"]
				this.Control["vi" . setting . "Edit"].Text := ""

			for ignore, setting in ["Speaker", "Listener", "Conversation"]
				this.Control["vi" . setting . "Check"].Value := 0

			this.Control["viConversationActionsDropDown"].Choose(0)
			this.Control["viListenerModeDropDown"].Choose(0)
		}
		else {
			this.iCurrentProvider := this.Control["viProviderDropDown"].Text

			if this.iProviderConfigurations.Has(this.iCurrentProvider)
				configuration := this.iProviderConfigurations[this.iCurrentProvider]

			for ignore, setting in ["ServiceURL", "ServiceKey", "MaxTokens"]
				this.Control["vi" . setting . "Edit"].Text := configuration[setting]

			if ((provider = "GPT4All") && (Trim(this.Control["viServiceKeyEdit"].Text) = ""))
				this.Control["viServiceKeyEdit"].Text := "Any text will do the job"

			if ((provider = "Ollama") && (Trim(this.Control["viServiceKeyEdit"].Text) = ""))
				this.Control["viServiceKeyEdit"].Text := "Ollama"

			for ignore, setting in ["Speaker", "Listener", "Conversation", "Agent"]
				this.Control["vi" . setting . "Check"].Value := configuration[setting]

			this.Control["viSpeakerProbabilityEdit"].Text := (isNumber(configuration["SpeakerProbability"]) ? Round(configuration["SpeakerProbability"] * 100) : "")
			this.Control["viSpeakerTemperatureEdit"].Text := (isNumber(configuration["SpeakerTemperature"]) ? Round(configuration["SpeakerTemperature"] * 100) : "")

			this.Control["viListenerModeDropDown"].Choose(2 - (configuration["ListenerMode"] = "Always"))
			this.Control["viListenerTemperatureEdit"].Text := (isNumber(configuration["ListenerTemperature"]) ? Round(configuration["ListenerTemperature"] * 100) : "")

			this.Control["viConversationMaxHistoryEdit"].Text := configuration["ConversationMaxHistory"]
			this.Control["viConversationTemperatureEdit"].Text := (isNumber(configuration["ConversationTemperature"]) ? Round(configuration["ConversationTemperature"] * 100) : "")
			this.Control["viConversationActionsDropDown"].Choose(1 + (configuration["ConversationActions"] = false))
		}

		if this.iCurrentProvider
			this.loadModels(this.iCurrentProvider, configuration["ServiceURL"]
												 , configuration["ServiceKey"]
												 , configuration["Model"])
		else
			this.loadModels(false)
	}

	saveProviderConfiguration() {
		if this.iCurrentProvider {
			local providerConfiguration := this.iProviderConfigurations[this.iCurrentProvider]
			local value, ignore, setting

			providerConfiguration["ServiceURL"] := Trim(this.Control["viServiceURLEdit"].Text)
			providerConfiguration["ServiceKey"] := Trim(this.Control["viServiceKeyEdit"].Text)

			value := this.Control["viModelDropDown"].Text

			providerConfiguration["Model"] := ((Trim(value) != "") ? Trim(value) : false)
			providerConfiguration["MaxTokens"] := this.Control["viMaxTokensEdit"].Text

			if (this.Control["viSpeakerCheck"].Value = 1) {
				providerConfiguration["Speaker"] := true
				providerConfiguration["SpeakerProbability"] := Round(this.Control["viSpeakerProbabilityEdit"].Text / 100, 2)
				providerConfiguration["SpeakerTemperature"] := Round(this.Control["viSpeakerTemperatureEdit"].Text / 100, 2)
			}
			else {
				providerConfiguration["Speaker"] := false
				providerConfiguration["SpeakerProbability"] := ""
				providerConfiguration["SpeakerTemperature"] := ""
			}

			if (this.Control["viListenerCheck"].Value = 1) {
				providerConfiguration["Listener"] := true
				providerConfiguration["ListenerMode"] := ["Always", "Unknown"][this.Control["viListenerModeDropDown"].Value]
				providerConfiguration["ListenerTemperature"] := Round(this.Control["viListenerTemperatureEdit"].Text / 100, 2)
			}
			else {
				providerConfiguration["Listener"] := false
				providerConfiguration["ListenerMode"] := ""
				providerConfiguration["ListenerTemperature"] := ""
			}

			if (this.Control["viConversationCheck"].Value = 1) {
				providerConfiguration["Conversation"] := true
				providerConfiguration["ConversationMaxHistory"] := this.Control["viConversationMaxHistoryEdit"].Text
				providerConfiguration["ConversationTemperature"] := Round(this.Control["viConversationTemperatureEdit"].Text / 100, 2)
				providerConfiguration["ConversationActions"] := (this.Control["viConversationActionsDropDown"].Value = 1)
			}
			else {
				providerConfiguration["Conversation"] := false
				providerConfiguration["ConversationMaxHistory"] := ""
				providerConfiguration["ConversationTemperature"] := ""
				providerConfiguration["ConversationActions"] := false
			}

			if (this.Control["viAgentCheck"].Value = 1)
				providerConfiguration["Agent"] := true
			else
				providerConfiguration["Agent"] := false
		}
	}

	loadConfigurator(configuration, simulators := false) {
		this.loadFromConfiguration(configuration)

		this.loadProviderConfiguration(this.iCurrentProvider)

		this.updateState()
	}

	editBooster(owner := false) {
		local window, x, y, w, h, configuration

		this.createGui(this.Configuration)

		window := this.Window

		if owner
			window.Opt("+Owner" . owner.Hwnd)

		if getWindowPosition("Booster Editor", &x, &y)
			window.Show("x" . x . " y" . y)
		else
			window.Show()

		this.loadConfigurator(this.Configuration)

		loop
			Sleep(200)
		until this.iResult

		try {
			if (this.iResult = kOk) {
				configuration := newMultiMap()

				this.saveToConfiguration(configuration)

				return configuration
			}
			else
				return false
		}
		finally {
			window.Destroy()
		}
	}

	updateState() {
		local ignore, setting

		if this.iCurrentProvider {
			this.Control["viServiceURLEdit"].Enabled := (this.Control["viProviderDropDown"].Text != "LLM Runtime")
			this.Control["viServiceKeyEdit"].Enabled := !inList(["GPT4All", "Ollama", "LLM Runtime"], this.Control["viProviderDropDown"].Text)

			this.Control["viSpeakerCheck"].Enabled := true
			this.Control["viListenerCheck"].Enabled := true
			this.Control["viConversationCheck"].Enabled := true
			this.Control["viAgentCheck"].Enabled := true

			this.Control["viModelDropDown"].Enabled := true
			this.Control["viMaxTokensEdit"].Enabled := true
		}
		else {
			for ignore, setting in ["ServiceURL", "ServiceKey"]
				this.Control["vi" . setting . "Edit"].Enabled := false

			this.Control["viSpeakerCheck"].Enabled := false
			this.Control["viListenerCheck"].Enabled := false
			this.Control["viConversationCheck"].Enabled := false
			this.Control["viAgentCheck"].Enabled := false
			this.Control["viSpeakerCheck"].Value := 0
			this.Control["viListenerCheck"].Value := 0
			this.Control["viConversationCheck"].Value := 0

			this.Control["viModelDropDown"].Enabled := false
			this.Control["viMaxTokensEdit"].Enabled := false
		}

		if (this.Control["viSpeakerCheck"].Value = 0) {
			this.Control["viSpeakerProbabilityEdit"].Enabled := false
			this.Control["viSpeakerTemperatureEdit"].Enabled := false
			this.Control["viSpeakerProbabilityEdit"].Text := ""
			this.Control["viSpeakerTemperatureEdit"].Text := ""
			this.Control["viSpeakerInstructionsButton"].Enabled := false
		}
		else {
			this.Control["viSpeakerProbabilityEdit"].Enabled := true
			this.Control["viSpeakerTemperatureEdit"].Enabled := true

			if (this.Control["viSpeakerProbabilityEdit"].Text = "")
				this.Control["viSpeakerProbabilityEdit"].Text := 50

			if (this.Control["viSpeakerTemperatureEdit"].Text = "")
				this.Control["viSpeakerTemperatureEdit"].Text := 50

			this.Control["viSpeakerInstructionsButton"].Enabled := true
		}

		if (this.Control["viListenerCheck"].Value = 0) {
			this.Control["viListenerModeDropDown"].Enabled := false
			this.Control["viListenerTemperatureEdit"].Enabled := false
			this.Control["viListenerModeDropDown"].Choose(0)
			this.Control["viListenerTemperatureEdit"].Text := ""
			this.Control["viListenerInstructionsButton"].Enabled := false
		}
		else {
			this.Control["viListenerModeDropDown"].Enabled := true
			this.Control["viListenerTemperatureEdit"].Enabled := true

			if (this.Control["viListenerModeDropDown"].Value = 0)
				this.Control["viListenerModeDropDown"].Choose(2)

			if (this.Control["viListenerTemperatureEdit"].Text = "")
				this.Control["viListenerTemperatureEdit"].Text := 50

			this.Control["viListenerInstructionsButton"].Enabled := true
		}

		if (this.Control["viConversationCheck"].Value = 0) {
			this.Control["viConversationMaxHistoryEdit"].Enabled := false
			this.Control["viConversationTemperatureEdit"].Enabled := false
			this.Control["viConversationActionsDropDown"].Enabled := false
			this.Control["viConversationEditActionsButton"].Enabled := false
			this.Control["viConversationMaxHistoryEdit"].Text := ""
			this.Control["viConversationTemperatureEdit"].Text := ""
			this.Control["viConversationActionsDropDown"].Choose(0)
			this.Control["viConversationInstructionsButton"].Enabled := false
		}
		else {
			this.Control["viConversationMaxHistoryEdit"].Enabled := true
			this.Control["viConversationTemperatureEdit"].Enabled := true
			this.Control["viConversationActionsDropDown"].Enabled := true

			if (this.Control["viConversationMaxHistoryEdit"].Text = "")
				this.Control["viConversationMaxHistoryEdit"].Text := 3

			if (this.Control["viConversationTemperatureEdit"].Text = "")
				this.Control["viConversationTemperatureEdit"].Text := 50

			if (this.Control["viConversationActionsDropDown"].Value = 0)
				this.Control["viConversationActionsDropDown"].Choose(2)

			this.Control["viConversationInstructionsButton"].Enabled := true
			this.Control["viConversationEditActionsButton"].Enabled := (this.Control["viConversationActionsDropDown"].Value = 1)
		}

		if (this.Control["viAgentCheck"].Value = 0) {
			this.Control["viAgentEventsButton"].Enabled := false
			this.Control["viAgentActionsButton"].Enabled := false
			this.Control["viAgentInstructionsButton"].Enabled := false
		}
		else {
			this.Control["viAgentEventsButton"].Enabled := true
			this.Control["viAgentActionsButton"].Enabled := true
			this.Control["viAgentInstructionsButton"].Enabled := true
		}
	}

	getOriginalInstruction(language, type, key) {
		if (type = "Agent")
			return getMultiMapValue(this.getInstructions(type, true), "Agent Booster", "Instructions." . type . "." . key . "." . language, "")
		else
			return getMultiMapValue(this.getInstructions(type, true), "Conversation Booster", "Instructions." . type . "." . key . "." . language, "")
	}

	getInstructions(type, original := false) {
		local instructions := newMultiMap()
		local reference := ((type = "Agent") ? "Agent Booster" : "Conversation Booster")
		local key, value, ignore, directory, configuration, language

		for ignore, directory in [kTranslationsDirectory, kUserTranslationsDirectory]
			loop Files (directory . reference . ".instructions.*") {
				SplitPath A_LoopFilePath, , , &language

				for key, value in getMultiMapValues(readMultiMap(A_LoopFilePath), type . ".Instructions")
					setMultiMapValue(instructions, reference, "Instructions." . type . "." . key . "." . language, value)
			}

		if !original
			for ignore, configuration in [this.Configuration, this.iInstructions]
				for key, value in getMultiMapValues(configuration, reference)
					if (InStr(key, "Instructions." . type) = 1)
						setMultiMapValue(instructions, reference, key, value)

		return instructions
	}

	setInstructions(type, instructions) {
		addMultiMapValues(this.iInstructions, instructions)
	}

	editInstructions(type, title) {
		local window := this.Window
		local instructions

		window.Block()

		try {
			instructions := editInstructions(this, type, title, this.getInstructions(type), window)

			if instructions
				this.setInstructions(type, instructions)
		}
		finally {
			window.Unblock()
		}
	}

	editEvents(assistant) {
		local window := this.Window

		window.Block()

		try {
			return EventsEditor(this, "Agent.Events").editEvents(window)
		}
		finally {
			window.Unblock()
		}
	}

	editActions(assistant, type) {
		local window := this.Window

		window.Block()

		try {
			return ActionsEditor(this, type).editActions(window)
		}
		finally {
			window.Unblock()
		}
	}
}

class CallbacksEditor {
	iEditor := false
	iType := false

	iWindow := false
	iResult := false

	iCallbacksListView := false
	iParametersListView := false
	iCallableField := false
	iPhraseField := false
	iScriptEditor := false

	iCallbacks := []
	iSelectedCallback := false
	iSelectedParameter := false

	Editor {
		Get {
			return this.iEditor
		}
	}

	Type {
		Get {
			return this.iType
		}
	}

	Assistant {
		Get {
			return this.Editor.Assistant
		}
	}

	Window {
		Get {
			return this.iWindow
		}
	}

	Control[name] {
		Get {
			return this.Window[name]
		}
	}

	CallbacksListView {
		Get {
			return this.iCallbacksListView
		}
	}

	ParametersListView {
		Get {
			return this.iParametersListView
		}
	}

	PhraseField {
		Get {
			return this.iPhraseField
		}
	}

	CallableField {
		Get {
			return this.iCallableField
		}
	}

	ScriptEditor {
		Get {
			return this.iScriptEditor
		}
	}

	Callbacks[key?] {
		Get {
			return (isSet(key) ? this.iCallbacks[key] : this.iCallbacks)
		}

		Set {
			return (isSet(key) ? (this.iCallbacks[key] := value) : (this.iCallbacks := value))
		}
	}

	SelectedCallback {
		Get {
			return this.iSelectedCallback
		}
	}

	SelectedParameter {
		Get {
			return this.iSelectedParameter
		}
	}

	__New(editor, type) {
		this.iEditor := editor
		this.iType := type
	}

	createGui() {
		local editorGui

		chooseCallback(listView, line, *) {
			this.selectCallback(line ? this.Callbacks[line] : false)
		}

		chooseParameter(listView, line, *) {
			this.selectParameter(line ? this.SelectedCallback.Parameters[line] : false)
		}

		editorGui := Window({Descriptor: (this.Type . " Editor"), Resizeable: true, Options: "0x400000"})

		this.iWindow := editorGui

		editorGui.SetFont("Bold", "Arial")

		editorGui.Add("Text", "w848 H:Center Center", translate("Modular Simulator Controller System")).OnEvent("Click", moveByMouse.Bind(editorGui, "Actions Editor"))

		editorGui.SetFont("Norm", "Arial")

		if ((this.Type = "Conversation.Actions") || (this.Type = "Agent.Actions"))
			editorGui.Add("Documentation", "x368 YP+20 w128 H:Center Center", translate("Conversation Actions")
						, "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#managing-booster-actions")
		else
			editorGui.Add("Documentation", "x368 YP+20 w128 H:Center Center", translate("Behavior Events")
						, "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Installation-&-Configuration#managing-booster-events")

		editorGui.SetFont("Norm", "Arial")

		editorGui.Add("Text", "x8 yp+30 w848 W:Grow 0x10")

		this.iCallbacksListView := editorGui.Add("ListView", "x16 y+10 w832 h140 W:Grow H:Grow(0.25) -Multi -LV0x10 AltSubmit NoSort NoSortHdr"
											   , collect([(this.Type != "Agent.Events") ? "Action" : "Event", "Active", "Description"], translate))

		this.iCallbacksListView.OnEvent("Click", chooseCallback)
		this.iCallbacksListView.OnEvent("DoubleClick", chooseCallback)

		editorGui.Add("Button", "x800 yp+142 w23 h23 Center +0x200 X:Move Y:Move(0.25) vaddCallbackButton").OnEvent("Click", (*) => this.addCallback())
		setButtonIcon(editorGui["addCallbackButton"], kIconsDirectory . "Plus.ico", 1, "L4 T4 R4 B4")
		editorGui.Add("Button", "x824 yp w23 h23 Center +0x200 X:Move Y:Move(0.25) vdeleteCallbackButton").OnEvent("Click", (*) => this.deleteCallback())
		setButtonIcon(editorGui["deleteCallbackButton"], kIconsDirectory . "Minus.ico", 1, "L4 T4 R4 B4")

		if (this.Type = "Agent.Events")
			editorGui.Add("Text", "x16 yp+28 w70 h23 +0x200 Section Y:Move(0.25)", translate("Event"))
		else
			editorGui.Add("Text", "x16 yp+28 w70 h23 +0x200 Section Y:Move(0.25)", translate("Action"))

		editorGui.Add("CheckBox", "x90 yp h23 w23 Y:Move(0.25) vcallbackActiveCheck")

		if (this.Type = "Agent.Events")
			editorGui.Add("DropDownList", "x110 yp w127 Y:Move(0.25) vcallbackTypeDropDown", collect(["Event Class", "Event Rule"], translate)).OnEvent("Change", (*) => this.updateState())
		else
			editorGui.Add("DropDownList", "x110 yp w127 Y:Move(0.25) vcallbackTypeDropDown", collect(["Assistant Method", "Assistant Rule", "Controller Method", "Controller Function"], translate)).OnEvent("Change", (*) => this.updateState())

		editorGui.Add("Edit", "x241 yp h23 w177 W:Grow(0.34) Y:Move(0.25) vcallbackNameEdit")

		editorGui.Add("Text", "x16 yp+28 w90 h23 +0x200 Y:Move(0.25)", translate("Description"))
		editorGui.Add("Edit", "x110 yp h96 w308 W:Grow(0.34) Y:Move(0.25) vcallbackDescriptionEdit")

		editorGui.Add("Text", "x16 yp+100 w90 h23 +0x200 Y:Move(0.25)", translate("Learning Phase")).Visible := (this.Type != "Agent.Events")
		editorGui.Add("DropDownList", "x110 yp w90 Y:Move(0.25) vcallbackInitializationDropDown", collect(["Yes", "No"], translate)).OnEvent("Change", (*) => this.updateState())
		editorGui["callbackInitializationDropDown"].Visible := (this.Type != "Agent.Events")

		editorGui.Add("Text", "x16 yp w90 h23 +0x200 Y:Move(0.25)", translate("Signal")).Visible := (this.Type = "Agent.Events")
		editorGui.Add("Edit", "x110 yp w127 Y:Move(0.25) vcallbackEventEdit").Visible := (this.Type = "Agent.Events")

		editorGui.Add("Text", "x16 yp+24 w90 h23 +0x200 Y:Move(0.25)", translate("Confirmation")).Visible := (this.Type != "Agent.Events")
		editorGui.Add("DropDownList", "x110 yp w90 Y:Move(0.25) vcallbackConfirmationDropDown", collect(["Yes", "No"], translate)).OnEvent("Change", (*) => this.updateState())
		editorGui["callbackConfirmationDropDown"].Visible := (this.Type != "Agent.Events")

		this.iPhraseField := [editorGui.Add("Text", "x16 yp w90 h23 +0x200 Y:Move(0.25)", translate("Phrase"))
							, editorGui.Add("Edit", "x110 yp w308 Y:Move(0.25) vcallbackPhraseEdit")]

		this.iPhraseField[1].Visible := (this.Type = "Agent.Events")
		this.iPhraseField[2].Visible := (this.Type = "Agent.Events")

		this.iCallableField := [editorGui.Add("Text", "x16 yp+28 w90 h23 +0x200 Y:Move(0.25)", translate("Call"))
							  , editorGui.Add("Edit", "x110 yp w308 h140 H:Grow(0.75) W:Grow(0.34) Y:Move(0.25)")]

		editorGui.SetFont("Norm", "Courier New")

		this.iScriptEditor := editorGui.Add("Edit", "x16 yp w832 h140 T14 WantTab W:Grow Y:Move(0.25) H:Grow(0.75)")

		editorGui.SetFont("Norm", "Arial")

		editorGui.Add("Text", "x8 yp+150 w848 Y:Move W:Grow 0x10")

		editorGui.SetFont("Norm", "Arial")

		editorGui.Add("Button", "x350 yp+10 w80 h23 Default X:Move(0.5) Y:Move", translate("Ok")).OnEvent("Click", (*) => (GetKeyState("Ctrl") && (this.Type != "Agent.Events"))? this.showCallbacks() : (this.iResult := kOk))
		editorGui.Add("Button", "x436 yp w80 h23 X:Move(0.5) Y:Move", translate("&Cancel")).OnEvent("Click", (*) => this.iResult := kCancel)

		this.iParametersListView := editorGui.Add("ListView", "x430 ys w418 h96 X:Move(0.34) W:Grow(0.66) Y:Move(0.25) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", collect(["Parameter", "Description"], translate))
		this.iParametersListView.OnEvent("Click", chooseParameter)
		this.iParametersListView.OnEvent("DoubleClick", chooseParameter)

		editorGui.Add("Button", "x800 yp+100 w23 h23 Center +0x200 X:Move Y:Move(0.25) vaddParameterButton").OnEvent("Click", (*) => this.addParameter())
		setButtonIcon(editorGui["addParameterButton"], kIconsDirectory . "Plus.ico", 1, "L4 T4 R4 B4")
		editorGui.Add("Button", "x824 yp w23 h23 Center +0x200 X:Move Y:Move(0.25) vdeleteParameterButton").OnEvent("Click", (*) => this.deleteParameter())
		setButtonIcon(editorGui["deleteParameterButton"], kIconsDirectory . "Minus.ico", 1, "L4 T4 R4 B4")

		editorGui.Add("Text", "x430 yp+28 w90 h23 +0x200 X:Move(0.34) Y:Move(0.25)", translate("Name / Type"))
		editorGui.Add("Edit", "x536 yp h23 w127 Y:Move(0.25) X:Move(0.34) vparameterNameEdit")
		editorGui.Add("DropDownList", "x665 yp w90 Y:Move(0.25) X:Move(0.34) vparameterTypeDropDown", collect(["String", "Integer", "Boolean"], translate)).OnEvent("Change", (*) => this.updateState())
		editorGui.Add("DropDownList", "x758 yp w90 Y:Move(0.25) X:Move(0.34) vparameterOptionalDropDown", collect(["Required", "Optional"], translate)).OnEvent("Change", (*) => this.updateState())

		editorGui.Add("Text", "x430 yp+24 w90 h23 +0x200 Y:Move(0.25) X:Move(0.34)", translate("Description"))
		editorGui.Add("Edit", "x536 yp h23 w312 Y:Move(0.25) X:Move(0.34) W:Grow(0.66) vparameterDescriptionEdit")

		this.updateState()
	}

	editCallbacks(owner := false) {
		local window, x, y, w, h

		this.createGui()

		window := this.Window

		if owner
			window.Opt("+Owner" . owner.Hwnd)

		if getWindowPosition(this.Type . " Editor", &x, &y)
			window.Show("x" . x . " y" . y)
		else
			window.Show()

		if getWindowSize(this.Type . " Editor", &w, &h)
			window.Resize("Initialize", w, h)

		this.loadCallbacks()

		try {
			loop {
				loop
					Sleep(200)
				until this.iResult

				if (this.iResult = kOk) {
					this.iResult := this.saveCallbacks()

					if this.iResult
						return this.iResult
					else
						this.iResult := false
				}
				else
					return false
			}
		}
		finally {
			window.Destroy()
		}
	}

	updateState() {
		local type

		this.Control["addCallbackButton"].Enabled := true

		if this.SelectedCallback {
			this.Control["callbackActiveCheck"].Enabled := true

			if this.SelectedCallback.Builtin {
				this.Control["addParameterButton"].Enabled := false
				this.Control["deleteParameterButton"].Enabled := false

				this.Control["deleteCallbackButton"].Enabled := false

				this.ScriptEditor.Opt("+ReadOnly")
				this.CallableField[2].Enabled := false

				this.Control["callbackNameEdit"].Enabled := false
				this.Control["callbackDescriptionEdit"].Enabled := false
				this.Control["callbackTypeDropDown"].Enabled := false
				this.Control["callbackEventEdit"].Enabled := false
				this.PhraseField[2].Enabled := false
				this.Control["callbackInitializationDropDown"].Enabled := false
				this.Control["callbackConfirmationDropDown"].Enabled := false
			}
			else {
				this.Control["deleteCallbackButton"].Enabled := true
				this.Control["addParameterButton"].Enabled := true
				this.Control["deleteParameterButton"].Enabled := (this.SelectedParameter != false)

				this.ScriptEditor.Opt("-ReadOnly")
				this.CallableField[2].Enabled := true

				this.Control["callbackNameEdit"].Enabled := true
				this.Control["callbackDescriptionEdit"].Enabled := true
				this.Control["callbackTypeDropDown"].Enabled := true
				this.Control["callbackEventEdit"].Enabled := true
				this.PhraseField[2].Enabled := true
				this.Control["callbackInitializationDropDown"].Enabled := true
				this.Control["callbackConfirmationDropDown"].Enabled := true
			}

			if (this.Control["callbackTypeDropDown"].Value != 0) {
				if (this.Type = "Agent.Events")
					type := ["Class", "Rule"][this.Control["callbackTypeDropDown"].Value]
				else
					type := ["Method", "Rule", "Method", "Function"][this.Control["callbackTypeDropDown"].Value]
			}
			else
				type := "Rule"

			if (type = "Rule") {
				this.ScriptEditor.Visible := true
				this.CallableField[1].Visible := false
				this.CallableField[2].Visible := false
				this.PhraseField[1].Visible := (this.Type = "Agent.Events")
				this.PhraseField[2].Visible := (this.Type = "Agent.Events")
			}
			else {
				this.ScriptEditor.Visible := false
				this.CallableField[1].Visible := true
				this.CallableField[2].Visible := true
				this.PhraseField[1].Visible := false
				this.PhraseField[2].Visible := false

				this.CallableField[1].Text := translate(type . ((this.Type != "Agent.Events") ? "(s)" : ""))
			}
		}
		else {
			this.Control["deleteCallbackButton"].Enabled := false
			this.Control["addParameterButton"].Enabled := false
			this.Control["deleteParameterButton"].Enabled := false

			this.ScriptEditor.Text := ""
			this.CallableField[2].Text := ""
			this.Control["callbackNameEdit"].Text := ""
			this.Control["callbackDescriptionEdit"].Text := ""
			this.Control["callbackActiveCheck"].Value := 0
			this.Control["callbackTypeDropDown"].Choose(0)
			this.Control["callbackEventEdit"].Text := ""
			this.PhraseField[2].Text := ""
			this.Control["callbackInitializationDropDown"].Choose(0)
			this.Control["callbackConfirmationDropDown"].Choose(0)

			this.ScriptEditor.Opt("+ReadOnly")
			this.ScriptEditor.Visible := true
			this.CallableField[1].Visible := false
			this.CallableField[2].Visible := false
			this.Control["callbackNameEdit"].Enabled := false
			this.Control["callbackDescriptionEdit"].Enabled := false
			this.Control["callbackActiveCheck"].Enabled := false
			this.Control["callbackTypeDropDown"].Enabled := false
			this.Control["callbackEventEdit"].Enabled := false
			this.PhraseField[2].Enabled := false
			this.Control["callbackInitializationDropDown"].Enabled := false
			this.Control["callbackConfirmationDropDown"].Enabled := false
		}

		if this.SelectedParameter {
			if this.SelectedCallback.Builtin {
				this.Control["parameterNameEdit"].Enabled := false
				this.Control["parameterDescriptionEdit"].Enabled := false
				this.Control["parameterTypeDropDown"].Enabled := false
				this.Control["parameterOptionalDropDown"].Enabled := false
			}
			else {
				this.Control["parameterNameEdit"].Enabled := true
				this.Control["parameterDescriptionEdit"].Enabled := true
				this.Control["parameterTypeDropDown"].Enabled := true
				this.Control["parameterOptionalDropDown"].Enabled := true
			}
		}
		else {
			this.Control["parameterNameEdit"].Text := ""
			this.Control["parameterDescriptionEdit"].Text := ""
			this.Control["parameterTypeDropDown"].Choose(0)
			this.Control["parameterOptionalDropDown"].Choose(0)

			this.Control["parameterNameEdit"].Enabled := false
			this.Control["parameterDescriptionEdit"].Enabled := false
			this.Control["parameterTypeDropDown"].Enabled := false
			this.Control["parameterOptionalDropDown"].Enabled := false
		}
	}

	selectCallback(callback, force := false, save := true) {
		if (force || (this.SelectedCallback != callback)) {
			if (save && this.SelectedCallback)
				if !this.saveCallback(this.SelectedCallback) {
					this.CallbacksListView.Modify(inList(this.Callbacks, this.SelectedCallback), "Select Vis")

					return
				}

			this.iSelectedCallback := callback

			if callback
				this.CallbacksListView.Modify(inList(this.Callbacks, callback), "Select Vis")

			this.loadCallback(callback)

			this.updateState()
		}
	}

	selectParameter(parameter, force := false, save := true) {
		if (force || (this.SelectedParameter != parameter)) {
			if (save && this.SelectedParameter)
				if !this.saveParameter(this.SelectedParameter) {
					this.ParametersListView.Modify(inList(this.SelectedCallback.Parameters, this.SelectedParameter), "Select Vis")

					return
				}

			this.iSelectedParameter := parameter

			if parameter
				this.ParametersListView.Modify(inList(this.SelectedCallback.Parameters, parameter), "Select Vis")

			this.loadParameter(parameter)

			this.updateState()
		}
	}

	addCallback() {
		local callback

		if this.SelectedCallback
			if !this.saveCallback(this.SelectedCallback) {
				this.CallbacksListView.Modify(inList(this.Callbacks, this.SelectedCallback), "Select Vis")

				return
			}

		if (this.Type = "Agent.Events")
			callback := {Name: "", Type: "Assistant.Rule", Active: true, Description: "", Parameters: []
					   , Builtin: false, Event: "", Phrase: "", Definition: "", Script: ""}
		else
			callback := {Name: "", Type: "Controller.Function", Active: true, Description: "", Parameters: []
					   , Builtin: false, Initialized: true, Confirm: true, Definition: ""}

		this.Callbacks.Push(callback)

		this.CallbacksListView.Add("", "", translate("x"), "")

		this.selectCallback(callback, true, false)
	}

	deleteCallback() {
		local index := inList(this.Callbacks, this.SelectedCallback)

		this.CallbacksListView.Delete(index)

		this.Callbacks.RemoveAt(index)

		this.selectCallback(false, true, false)
	}

	loadCallback(callback) {
		local ignore, parameter

		this.ParametersListView.Delete()
		this.selectParameter(false, true, false)

		if callback {
			this.Control["callbackNameEdit"].Text := callback.Name

			if (this.Type = "Agent.Events") {
				this.Control["callbackEventEdit"].Text := callback.Event
				this.PhraseField[2].Text := callback.Phrase
				this.Control["callbackTypeDropDown"].Choose(inList(["Assistant.Class", "Assistant.Rule"], callback.Type))
			}
			else {
				this.Control["callbackInitializationDropDown"].Choose(1 + (!callback.Initialized ? 1 : 0))
				this.Control["callbackConfirmationDropDown"].Choose(1 + (!callback.Confirm ? 1 : 0))
				this.Control["callbackTypeDropDown"].Choose(inList(["Assistant.Method", "Assistant.Rule", "Controller.Method", "Controller.Function"], callback.Type))
			}

			this.Control["callbackActiveCheck"].Value := !!callback.Active
			this.Control["callbackDescriptionEdit"].Text := callback.Description

			if (callback.Type = "Assistant.Rule") {
				this.ScriptEditor.Text := callback.Script

				this.CallableField[2].Text := ""
			}
			else {
				this.ScriptEditor.Text := ""

				this.CallableField[2].Text := callback.Definition
			}

			for ignore, parameter in callback.Parameters
				this.ParametersListView.Add("", parameter.Name, parameter.Description)

			this.ParametersListView.ModifyCol()

			loop this.ParametersListView.GetCount("Col")
				this.ParametersListView.ModifyCol(A_Index, "AutoHdr")
		}
		else {
			this.Control["callbackNameEdit"].Text := ""
			this.Control["callbackTypeDropDown"].Choose(0)
			this.Control["callbackActiveCheck"].Value := 0
			this.Control["callbackDescriptionEdit"].Text := ""
			this.Control["callbackEventEdit"].Text := ""
			this.PhraseField[2].Text := ""
			this.Control["callbackInitializationDropDown"].Choose(0)
			this.Control["callbackConfirmationDropDown"].Choose(0)

			this.ScriptEditor.Text := ""
		}

		this.updateState()
	}

	saveCallback(callback) {
		local valid := true
		local name := this.Control["callbackNameEdit"].Text
		local errorMessage := ""
		local ignore, other, type

		if this.SelectedParameter
			if !this.saveParameter(this.SelectedParameter)
				return false

		if (Trim(name) = "") {
			errorMessage .= ("`n" . translate("Error: ") . "Name cannot be empty...")

			valid := false
		}

		for ignore, other in this.Callbacks
			if ((other != callback) && (name = other.Name)) {
				errorMessage .= ("`n" . translate("Error: ") . "Name must be unique...")

				valid := false
			}

		if (this.Type = "Agent.Events")
			type := ["Assistant.Class", "Assistant.Rule"][this.Control["callbackTypeDropDown"].Value]
		else
			type := ["Assistant.Method", "Assistant.Rule", "Controller.Method", "Controller.Function"][this.Control["callbackTypeDropDown"].Value]

		if (type = "Assistant.Rule")
			try {
				RuleCompiler().compileRules(this.ScriptEditor.Text, &ignore := false, &ignore := false)
			}
			catch Any as exception {
				errorMessage .= ("`n" . translate("Error: ") . (isObject(exception) ? exception.Message : exception))

				valid := false
			}

		if valid {
			callback.Name := name
			callback.Active := Trim(this.Control["callbackActiveCheck"].Value)
			callback.Description := Trim(this.Control["callbackDescriptionEdit"].Text)
			callback.Type := type

			if (this.Type = "Agent.Events") {
				callback.Event := Trim(this.Control["callbackEventEdit"].Text)
				callback.Phrase := Trim(this.PhraseField[2].Text)
			}
			else {
				callback.Initialized := (this.Control["callbackInitializationDropDown"].Value = 1)
				callback.Confirm := (this.Control["callbackConfirmationDropDown"].Value = 1)
			}

			if (callback.Type = "Assistant.Rule")
				callback.Script := this.ScriptEditor.Text
			else
				callback.Definition := this.CallableField[2].Value

			this.CallbacksListView.Modify(inList(this.Callbacks, callback), "", callback.Name, callback.Active ? translate("x") : "", callback.Description)
		}
		else {
			if (StrLen(errorMessage) > 0)
				errorMessage := ("`n" . errorMessage)

			OnMessage(0x44, translateOkButton)
			withBlockedWindows(MsgBox, translate("Invalid values detected - please correct...") . errorMessage, translate("Error"), 262160)
			OnMessage(0x44, translateOkButton, 0)
		}

		return valid
	}

	addParameter() {
		local parameter

		if this.SelectedParameter
			if !this.saveParameter(this.SelectedParameter) {
				this.ParametersListView.Modify(inList(this.SelectedCallback.Parameters, this.SelectedParameter), "Select Vis")

				return
			}

		parameter := {Name: "", Type: "String", Enumeration: [], Required: false, Description: ""}

		this.SelectedCallback.Parameters.Push(parameter)

		this.ParametersListView.Add("", "", "")

		this.selectParameter(parameter, true, false)
	}

	deleteParameter() {
		local index := inList(this.SelectedCallback.Parameters, this.SelectedParameter)

		this.ParametersListView.Delete(index)

		this.SelectedCallback.Parameters.RemoveAt(index)

		this.selectParameter(false, true, false)
	}

	loadParameter(parameter) {
		if parameter {
			this.Control["parameterNameEdit"].Text := parameter.Name
			this.Control["parameterTypeDropDown"].Choose(inList(["String", "Integer", "Boolean"], parameter.Type))
			this.Control["parameterDescriptionEdit"].Text := parameter.Description
			this.Control["parameterOptionalDropDown"].Choose(1 + (!parameter.Required ? 1 : 0))
		}
		else {
			this.Control["parameterNameEdit"].Text := ""
			this.Control["parameterTypeDropDown"].Choose(0)
			this.Control["parameterDescriptionEdit"].Text := ""
			this.Control["parameterOptionalDropDown"].Choose(0)
		}

		this.updateState()
	}

	saveParameter(parameter) {
		local valid := true
		local name := this.Control["parameterNameEdit"].Text
		local errorMessage := ""
		local ignore, other

		if (Trim(name) = "") {
			errorMessage .= ("`n" . translate("Error: ") . "Name cannot be empty...")

			valid := false
		}

		for ignore, other in this.SelectedCallback.Parameters
			if ((other != parameter) && (name = other.Name)) {
				errorMessage .= ("`n" . translate("Error: ") . "Name must be unique...")

				valid := false
			}

		if valid {
			parameter.Name := name
			parameter.Description := Trim(this.Control["parameterDescriptionEdit"].Text)
			parameter.Type := ["String", "Integer", "Boolean"][this.Control["parameterTypeDropDown"].Value]
			parameter.Required := (this.Control["parameterOptionalDropDown"].Value = 1)

			this.ParametersListView.Modify(inList(this.SelectedCallback.Parameters, parameter), "", parameter.Name, parameter.Description)
		}
		else {
			if (StrLen(errorMessage) > 0)
				errorMessage := ("`n" . errorMessage)

			OnMessage(0x44, translateOkButton)
			withBlockedWindows(MsgBox, translate("Invalid values detected - please correct...") . errorMessage, translate("Error"), 262160)
			OnMessage(0x44, translateOkButton, 0)
		}

		return valid
	}

	showCallbacks() {
		local callbacks := []
		local ignore, callback, index, parameter, parameters

		if this.SelectedCallback
			if !this.saveCallback(this.SelectedCallback) {
				this.CallbacksListView.Modify(inList(this.Callbacks, this.SelectedCallback), "Select Vis")

				return false
			}

		for ignore, callback in this.Callbacks {
			if callback.Active {
				parameters := []

				for ignore, parameter in callback.Parameters
					parameters.Push(LLMTool.Function.Parameter(parameter.Name, parameter.Description
															 , parameter.Type, parameter.Enumeration, parameter.Required))

				callbacks.Push(LLMTool.Function(callback.Name, callback.Description, parameters))
			}
		}

		deleteFile(kTempDirectory . "LLM Callbacks.json")

		FileAppend(JSON.print(collect(callbacks, (callback) => callback.Descriptor), "`t"), kTempDirectory . "LLM Callbacks.json")

		Run("notepad.exe `"" . kTempDirectory . "LLM Callbacks.json`"")
	}

	loadCallbacks() {
		local extension := ((this.Type = "Agent.Events") ? ".events" : ".actions")
		local configuration := readMultiMap(kResourcesDirectory . "Actions\" . this.Assistant . extension)
		local callbacks := []
		local active, ignore, type, callback, descriptor, parameters, theCallback

		addMultiMapValues(configuration, readMultiMap(kUserHomeDirectory . "Actions\" . this.Assistant . extension))

		active := string2Values(",", getMultiMapValue(configuration, this.Type, "Active", ""))

		for ignore, type in [this.Type . ".Builtin", this.Type . ".Custom"]
			for callback, descriptor in getMultiMapValues(configuration, type) {
				descriptor := string2Values("|", descriptor)

				parameters := []

				loop descriptor[5] {
					parameter := string2Values("|", getMultiMapValue(configuration, this.Type . ".Parameters", ConfigurationItem.descriptor(callback, A_Index)))

					parameters.Push({Name: parameter[1], Type: parameter[2], Enumeration: string2Values(",", parameter[3])
								   , Required: ((parameter[4] = kTrue) ? true : ((parameter[4] = kFalse) ? false : parameter[4]))
								   , Description: parameter[5]})
				}

				if (this.Type = "Agent.Events")
					theCallback := {Name: callback, Active: inList(active, callback), Type: descriptor[1], Definition: descriptor[2]
								  , Description: descriptor[6], Parameters: parameters, Builtin: (type = (this.Type . ".Builtin"))
								  , Event: descriptor[3], Phrase: descriptor[4]}
				else
					theCallback := {Name: callback, Active: inList(active, callback), Type: descriptor[1], Definition: descriptor[2]
								  , Description: descriptor[6], Parameters: parameters, Builtin: (type = (this.Type . ".Builtin"))
								  , Initialized: ((descriptor[3] = kTrue) ? true : ((descriptor[3] = kFalse) ? false : descriptor[3]))
								  , Confirm: ((descriptor[4] = kTrue) ? true : ((descriptor[4] = kFalse) ? false : descriptor[4]))}

				if (theCallback.Type = "Assistant.Rule") {
					theCallback.Script := FileRead(getFileName(descriptor[2], kResourcesDirectory . "Actions\", kUserHomeDirectory . "Actions\"))

					theCallback.Definition := ""
				}

				this.Callbacks.Push(theCallback)
			}

		this.CallbacksListView.Delete()

		for ignore, callback in this.Callbacks
			this.CallbacksListView.Add("", callback.Name, callback.Active ? translate("x") : "", callback.Description)

		this.CallbacksListView.ModifyCol()

		loop this.CallbacksListView.GetCount("Col")
			this.CallbacksListView.ModifyCol(A_Index, "AutoHdr")
	}

	saveCallbacks(save := true) {
		local active := []
		local configuration, ignore, callback, index, parameter

		if this.SelectedCallback
			if !this.saveCallback(this.SelectedCallback) {
				this.CallbacksListView.Modify(inList(this.Callbacks, this.SelectedCallback), "Select Vis")

				return false
			}

		configuration := newMultiMap()

		for ignore, callback in this.Callbacks {
			if callback.Active
				active.Push(callback.Name)

			if !callback.Builtin {
				if (save && (callback.Type = "Assistant.Rule")) {
					callback.Definition := (this.Assistant . "." . callback.Name . ".rules")

					deleteFile(kUserHomeDirectory . "Actions\" . callback.Definition)

					FileAppend(callback.Script, kUserHomeDirectory . "Actions\" . callback.Definition)
				}

				if (this.Type = "Agent.Events")
					setMultiMapValue(configuration, this.Type . ".Custom", callback.Name
												  , values2String("|", callback.Type, callback.Definition, callback.Event, callback.Phrase
																	 , callback.Parameters.Length, callback.Description))
				else
					setMultiMapValue(configuration, this.Type . ".Custom", callback.Name
												  , values2String("|", callback.Type, callback.Definition, callback.Initialized, callback.Confirm
																	 , callback.Parameters.Length, callback.Description))

				for index, parameter in callback.Parameters
					setMultiMapValue(configuration, this.Type . ".Parameters", callback.Name . "." . index
												  , values2String("|", parameter.Name, parameter.Type
																	 , values2String(",", parameter.Enumeration*)
																	 , parameter.Required, parameter.Description))
			}
		}

		setMultiMapValue(configuration, this.Type, "Active", values2String(",", active*))

		if save
			writeMultiMap(kUserHomeDirectory . "Actions\" . this.Assistant . ((this.Type = "Agent.Events") ? ".events" : ".actions")
						, configuration)

		return configuration
	}
}

class EventsEditor extends CallbacksEditor {
	editEvents(owner := false) {
		this.editCallbacks(owner)
	}
}

class ActionsEditor extends CallbacksEditor {
	editActions(owner := false) {
		this.editCallbacks(owner)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                        Private Functions Section                        ;;;
;;;-------------------------------------------------------------------------;;;

editInstructions(editorOrCommand, type := false, title := false, originalInstructions := false, owner := false) {
	local choices, key, value, descriptor, reloadAll

	static reference, editor, instructions, instructionsGui, result, instructionEdit

	rephrase(key) {
		if (key = "RephraseTranslate")
			return "Rephrase & Translate"
		else
			return key
	}

	if (editorOrCommand == kOk)
		result := kOk
	else if (editorOrCommand == kCancel)
		result := kCancel
	else if (editorOrCommand == "Reload") {
		reloadALL := GetKeyState("Ctrl")

		for key, value in getMultiMapValues(instructions, reference)
			if (reloadAll || (instructionsGui["instructionsDropDown"].Value = A_Index)) {
				descriptor := ConfigurationItem.splitDescriptor(key)

				value := editor.getOriginalInstruction(descriptor[4], descriptor[2], descriptor[3])

				setMultiMapValue(instructions, reference, key, value)

				if (instructionsGui["instructionsDropDown"].Value = A_Index)
					instructionsGui["instructionEdit"].Value := value

				if !reloadAll
					break
			}
	}
	else if (editorOrCommand == "Load") {
		for key, value in getMultiMapValues(instructions, reference)
			if (instructionsGui["instructionsDropDown"].Value = A_Index) {
				instructionsGui["instructionEdit"].Value := value

				break
			}
	}
	else if (editorOrCommand == "Update") {
		for key, value in getMultiMapValues(instructions, reference)
			if (instructionsGui["instructionsDropDown"].Value = A_Index) {
				setMultiMapValue(instructions, reference, key, instructionsGui["instructionEdit"].Value)

				break
			}
	}
	else {
		reference := ((type = "Agent") ? "Agent Booster" : "Conversation Booster")

		editor := editorOrCommand
		result := false

		instructions := originalInstructions.Clone()

		instructionsGui := Window({Options: "0x400000"}, title)

		instructionsGui.SetFont("Norm", "Arial")

		choices := []

		for key, value in getMultiMapValues(instructions, reference) {
			key := ConfigurationItem.splitDescriptor(key)

			choices.Push(translate(rephrase(key[3])) . translate(" (") . StrUpper(key[4]) . translate(")"))
		}

		instructionsGui.Add("Text", "x16 y16 w90 h23 +0x200", translate("Instructions"))
		instructionsGui.Add("DropDownList", "x110 yp w180 vinstructionsDropDown", choices).OnEvent("Change", (*) => editInstructions("Load"))

		widget1 := instructionsGui.Add("Button", "x447 yp w23 h23")
		widget1.OnEvent("Click", (*) => editInstructions("Reload"))
		setButtonIcon(widget1, kIconsDirectory . "Renew.ico", 1)

		instructionEdit := instructionsGui.Add("Edit", "x110 yp+24 w360 h200 Multi vinstructionEdit")
		instructionEdit.OnEvent("Change", (*) => editInstructions("Update"))

		instructionsGui.Add("Button", "x160 yp+210 w80 h23 Default", translate("Ok")).OnEvent("Click", editInstructions.Bind(kOk))
		instructionsGui.Add("Button", "x246 yp w80 h23", translate("&Cancel")).OnEvent("Click", editInstructions.Bind(kCancel))

		instructionsGui.Opt("+Owner" . owner.Hwnd)

		instructionsGui.Show("AutoSize Center")

		instructionsGui["instructionsDropDown"].Choose(1)

		editInstructions("Load")

		while !result
			Sleep(100)

		try {
			if (result == kCancel)
				return false
			else if (result == kOk) {
				return instructions
			}
		}
		finally {
			instructionsGui.Destroy()
		}
	}
}