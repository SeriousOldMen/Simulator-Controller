;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - AI Race Engineer                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                        Global Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Assistants\Libraries\RaceAssistant.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class RaceEngineer extends RaceAssistant {
	iPitstopHandler := false
	
	iAdjustLapTime := true
	
	iSaveTyrePressures := kAsk
	
	iSetupData := {}
	iSessionDataActive := false
	
	PitstopHandler[] {
		Get {
			return this.iPitstopHandler
		}
	}
	
	AdjustLapTime[] {
		Get {
			return this.iAdjustLapTime
		}
	}
	
	SaveTyrePressures[] {
		Get {
			return this.iSaveTyrePressures
		}
	}
	
	SetupData[] {
		Get {
			return this.iSetupData
		}
	}
	
	SessionDataActive[] {
		Get {
			return this.iSessionDataActive
		}
	}
	
	__New(configuration, engineerSettings, pitstopHandler := false, name := false, language := "__Undefined__", service := false, speaker := false, listener := false, voiceServer := false) {
		this.iPitstopHandler := pitstopHandler
		
		base.__New(configuration, "Race Engineer", engineerSettings, name, language, service, speaker, listener, voiceServer)
	}
	
	updateConfigurationValues(values) {
		base.updateConfigurationValues(values)
								   
		if values.HasKey("AdjustLapTime")
			this.iAdjustLapTime := values["AdjustLapTime"]
		
		if values.HasKey("SaveTyrePressures")
			this.iSaveTyrePressures := values["SaveTyrePressures"]
	}
	
	updateSessionValues(values) {
		base.updateSessionValues(values)
	}
	
	updateDynamicValues(values) {
		base.updateDynamicValues(values)
		
		if values.HasKey("SetupData")
			this.iSetupData := values["SetupData"]
	}
	
	handleVoiceCommand(grammar, words) {
		switch grammar {
			case "LapsRemaining":
				this.lapInfoRecognized(words)
			case "TyreTemperatures":
				this.tyreInfoRecognized(words)
			case "TyrePressures":
				this.tyreInfoRecognized(words)
			case "Weather":
				this.weatherRecognized(words)
			case "PitstopPlan":
				this.clearContinuation()
				
				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else {
					this.getSpeaker().speakPhrase("Confirm")
				
					sendMessage()
				
					Loop 10
						Sleep 500
					
					this.planPitstopRecognized(words)
				}
			case "PitstopPrepare":
				this.clearContinuation()
				
				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else {
					this.getSpeaker().speakPhrase("Confirm")
				
					sendMessage()
					
					Loop 10
						Sleep 500
					
					this.preparePitstopRecognized(words)
				}
			case "PitstopAdjustFuel":
				this.clearContinuation()
				
				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustFuelRecognized(words)
			case "PitstopAdjustCompound":
				this.clearContinuation()
				
				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustCompoundRecognized(words)
			case "PitstopAdjustPressureUp", "PitstopAdjustPressureDown":
				this.clearContinuation()
				
				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustPressureRecognized(words)
			case "PitstopNoPressureChange":
				this.clearContinuation()
				
				this.pitstopAdjustNoPressureRecognized(words)
			case "PitstopNoTyreChange":
				this.clearContinuation()
				
				this.pitstopAdjustNoTyreRecognized(words)
			case "PitstopAdjustRepairSuspension":
				this.clearContinuation()
				
				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustRepairRecognized("Suspension", words)
			case "PitstopAdjustRepairBodywork":
				this.clearContinuation()
				
				if !this.supportsPitstop()
					this.getSpeaker().speakPhrase("NoPitstop")
				else
					this.pitstopAdjustRepairRecognized("Bodywork", words)
			default:
				base.handleVoiceCommand(grammar, words)
		}
	}
	
	lapInfoRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		laps := Round(knowledgeBase.getValue("Lap.Remaining.Fuel", 0))
		
		if (laps == 0)
			this.getSpeaker().speakPhrase("Later")
		else
			this.getSpeaker().speakPhrase("Laps", {laps: laps})
	}
	
	tyreInfoRecognized(words) {
		local value
		local knowledgeBase := this.KnowledgeBase
		
		if !this.hasEnoughData()
			return
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if inList(words, fragments["Temperatures"])
			value := "Temperature"
		else if inList(words, fragments["Pressures"])
			value := "Pressure"
		else {
			speaker.speakPhrase("Repeat")
		
			return
		}
		
		lap := knowledgeBase.getValue("Lap")
		
		speaker.speakPhrase((value == "Pressure") ? "Pressures" : "Temperatures")
		
		speaker.speakPhrase("TyreFL", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".FL"), 1))
									 , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
		
		speaker.speakPhrase("TyreFR", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".FR"), 1))
									 , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
		
		speaker.speakPhrase("TyreRL", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".RL"), 1))
									 , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
		
		speaker.speakPhrase("TyreRR", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Lap." . lap . ".Tyre." . value . ".RR"), 1))
									 , unit: (value == "Pressure") ? fragments["PSI"] : fragments["Degrees"]})
	}
	
	weatherRecognized(words) {
		local knowledgeBase := this.KnowledgeBase
		
		weather10Min := knowledgeBase.getValue("Weather.Weather.10Min", false)
		
		if !weather10Min
			this.getSpeaker().speakPhrase("Later")
		else if (weather10Min = "Dry")
			this.getSpeaker().speakPhrase("WeatherGood")
		else
			this.getSpeaker().speakPhrase("WeatherRain")
	}
	
	planPitstopRecognized(words) {
		this.planPitstop()
	}
	
	preparePitstopRecognized(words) {
		this.preparePitstop()
	}
	
	pitstopAdjustFuelRecognized(words) {
		local action
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			litresPosition := inList(words, fragments["Litres"])
				
			if litresPosition {
				litres := words[litresPosition - 1]
				
				if litres is number
				{
					speaker.speakPhrase("ConfirmFuelChange", {litres: litres}, true)
					
					this.setContinuation(ObjBindMethod(this, "updatePitstopFuel", litres))
					
					return
				}
			}
			
			speaker.speakPhrase("Repeat")
		}
	}
	
	pitstopAdjustCompoundRecognized(words) {
		local action
		local compound
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			compound := false
		
			if inList(words, fragments["Wet"])
				compound := "Wet"
			else if inList(words, fragments["Dry"])
				compound := "Dry"
			
			if compound {
				speaker.speakPhrase("ConfirmCompoundChange", {compound: fragments[compound]}, true)
					
				this.setContinuation(ObjBindMethod(this, "updatePitstopTyreCompound", compound))
			}
			else
				speaker.speakPhrase("Repeat")
		}
	}
				
	pitstopAdjustPressureRecognized(words) {
		local action
		
		static tyreTypeFragments := false
		static numberFragmentsLookup := false
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !tyreTypeFragments {
			tyreTypeFragments := {FL: fragments["FrontLeft"], FR: fragments["FrontRight"], RL: fragments["RearLeft"], RR: fragments["RearRight"]}
			numberFragmentsLookup := {}
			
			for index, fragment in ["Zero", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"]
				numberFragmentsLookup[fragments[fragment]] := index - 1
		}
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			tyreType := false
			
			if inList(words, fragments["Front"]) {
				if inList(words, fragments["Left"])
					tyreType := "FL"
				else if inList(words, fragments["Right"])
					tyreType := "FR"
			}
			else if inList(words, fragments["Rear"]) {
				if inList(words, fragments["Left"])
					tyreType := "RL"
				else if inList(words, fragments["Right"])
					tyreType := "RR"
			}
			
			if tyreType {
				action := false
				
				if inList(words, fragments["Increase"])
					action := kIncrease
				else if inList(words, fragments["Decrease"])
					action := kDecrease
				
				pointPosition := inList(words, fragments["Point"])
				
				if pointPosition {
					psiValue := words[pointPosition - 1]
					tenthPsiValue := words[pointPosition + 1]
					
					if psiValue is not number
					{
						psiValue := numberFragmentsLookup[psiValue]
						tenthPsiValue := numberFragmentsLookup[tenthPsiValue]
					}
					
					tyre := tyreTypeFragments[tyreType]
					action := fragments[action]
					
					delta := Round(psiValue + (tenthPsiValue / 10), 1)
					
					speaker.speakPhrase("ConfirmPsiChange", {action: action, tyre: tyre, unit: fragments["PSI"], delta: Format("{:.1f}", delta)}, true)
					
					this.setContinuation(ObjBindMethod(this, "updatePitstopTyrePressure", tyreType, (action == kIncrease) ? delta : (delta * -1)))
					
					return
				}
			}
			
			speaker.speakPhrase("Repeat")
		}
	}
	
	pitstopAdjustNoPressureRecognized(words) {
		local action
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			speaker.speakPhrase("ConfirmNoPressureChange", false, true)
					
			this.setContinuation(ObjBindMethod(this, "updatePitstopPressures"))
		}
	}
	
	pitstopAdjustNoTyreRecognized(words) {
		local action
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			speaker.speakPhrase("ConfirmNoTyreChange", false, true)
					
			this.setContinuation(ObjBindMethod(this, "updatePitstopTyreChange"))
		}
	}
	
	pitstopAdjustRepairRecognized(repairType, words) {
		local action
		
		speaker := this.getSpeaker()
		fragments := speaker.Fragments
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			negation := ""
		
			if inList(words, fragments["Not"])
				negation := fragments["Not"]
			
			speaker.speakPhrase("ConfirmRepairChange", {damage: fragments[repairType], negation: negation}, true)
					
			this.setContinuation(ObjBindMethod(this, "updatePitstopRepair", repairType, negation = ""))
		}
	}
	
	updatePitstopFuel(litres) {
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			this.KnowledgeBase.setValue("Pitstop.Planned.Fuel", litres)
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(this.KnowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
			speaker.speakPhrase("MoreChanges", false, true)
		}
	}
	
	updatePitstopTyreCompound(compound, color := "Black") {
		local knowledgeBase
		
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			if (this.KnowledgeBase.getValue("Pitstop.Planned.Tyre.Compound") != compound) {
				speaker.speakPhrase("ConfirmPlanUpdate")
		
				knowledgeBase := this.KnowledgeBase
				
				knowledgeBase.setValue("Tyre.Compound.Target", compound)
				knowledgeBase.setValue("Tyre.Compound.Color.Target", color)
				
				knowledgeBase.clearFact("Pitstop.Planned.Tyre.Compound")
				knowledgeBase.clearFact("Pitstop.Planned.Tyre.Compound.Color")
				
				for ignore, tyreType in ["FL", "FR", "RL", "RR"] {
					knowledgeBase.clearFact("Pitstop.Planned.Tyre.Pressure." . tyreType)
					knowledgeBase.clearFact("Pitstop.Planned.Tyre.Pressure." . tyreType . ".Increment")
				}
				
				knowledgeBase.clearFact("Pitstop.Planned.Tyre.Pressure.Correction")
				
				this.planPitstop({Update: true, Pressures: true, Confirm: false})
				
				speaker.speakPhrase("MoreChanges", false, true)
			}
			else {
				speaker.speakPhrase("ConfirmPlanUpdate")
				speaker.speakPhrase("MoreChanges", false, true)
			}
		}
	}
	
	updatePitstopTyrePressure(tyreType, delta) {
		local knowledgeBase := this.KnowledgeBase
		
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			targetValue := knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure." . tyreType)
			targetIncrement := knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure." . tyreType . ".Increment")
			
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure." . tyreType, targetValue + delta)
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure." . tyreType . ".Increment", targetIncrement + delta)
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(this.KnowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
			speaker.speakPhrase("MoreChanges", false, true)
		}
	}
	
	updatePitstopPressures() {
		local knowledgeBase
		
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			knowledgeBase := this.KnowledgeBase
		
			if (knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound", "Dry") = "Dry") {
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FL", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.FL", 26.1))
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FR", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.FR", 26.1))
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RL", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.RL", 26.1))
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RR", knowledgeBase.getValue("Session.Setup.Tyre.Dry.Pressure.RR", 26.1))
			}
			else {
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FL", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.FL", 26.1))
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FR", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.FR", 26.1))
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RL", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.RL", 26.1))
				knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RR", knowledgeBase.getValue("Session.Setup.Tyre.Wet.Pressure.RR", 26.1))
			}
			
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FL.Increment", 0)
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.FR.Increment", 0)
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RL.Increment", 0)
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Pressure.RR.Increment", 0)
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(knowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
			speaker.speakPhrase("MoreChanges", false, true)
		}
	}
	
	updatePitstopTyreChange() {
		local knowledgeBase
		
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			knowledgeBase := this.KnowledgeBase
		
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Compound", false)
			knowledgeBase.setValue("Pitstop.Planned.Tyre.Compound.Color", false)
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(knowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
			speaker.speakPhrase("MoreChanges", false, true)
		}
	}
	
	updatePitstopRepair(repairType, repair) {
		speaker := this.getSpeaker()
		
		if !this.hasPlannedPitstop() {
			speaker.speakPhrase("NotPossible")
			speaker.speakPhrase("ConfirmPlan", false, true)
			
			this.setContinuation(ObjBindMethod(this, "planPitstop"))
		}
		else {
			this.KnowledgeBase.setValue("Pitstop.Planned.Repair." . repairType, repair)
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(this.KnowledgeBase)

			speaker.speakPhrase("ConfirmPlanUpdate")
			speaker.speakPhrase("MoreChanges", false, true)
		}
	}
	
	createSession(data) {
		local facts := base.createSession(data)
		
		configuration := this.Configuration
		settings := this.Settings
		
		simulatorName := this.SetupDatabase.getSimulatorName(facts["Session.Simulator"])
		
		facts["Session.Settings.Pitstop.Delta"] := getConfigurationValue(settings, "Strategy Settings", "Pitstop.Delta", getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Pitstop.Delta", 30))
		facts["Session.Settings.Lap.Learning.Laps"] := getConfigurationValue(configuration, "Race Engineer Analysis", simulatorName . ".LearningLaps", 1)
			
		facts["Session.Settings.Lap.History.Considered"] := getConfigurationValue(configuration, "Race Engineer Analysis", simulatorName . ".ConsideredHistoryLaps", 5)
		facts["Session.Settings.Lap.History.Damping"] := getConfigurationValue(configuration, "Race Engineer Analysis", simulatorName . ".HistoryLapsDamping", 0.2)
		
		facts["Session.Settings.Damage.Analysis.Laps"] := getConfigurationValue(configuration, "Race Engineer Analysis", simulatorName . ".DamageAnalysisLaps", 1)
		facts["Session.Settings.Damage.Suspension.Repair"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Suspension.Repair", "Always")
		facts["Session.Settings.Damage.Suspension.Repair.Threshold"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Suspension.Repair.Threshold", 0)
		facts["Session.Settings.Damage.Bodywork.Repair"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Bodywork.Repair", "Threshold")
		facts["Session.Settings.Damage.Bodywork.Repair.Threshold"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Bodywork.Repair.Threshold", 20)
		
		facts["Session.Settings.Tyre.Compound.Change"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Compound.Change", "Never")
		facts["Session.Settings.Tyre.Compound.Change.Threshold"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Compound.Change.Threshold", 0)
		facts["Session.Settings.Tyre.Dry.Pressure.Target.FL"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.FL", 27.7)
		facts["Session.Settings.Tyre.Dry.Pressure.Target.FR"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.FR", 27.7)
		facts["Session.Settings.Tyre.Dry.Pressure.Target.RL"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.RL", 27.7)
		facts["Session.Settings.Tyre.Dry.Pressure.Target.RR"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.RR", 27.7)
		facts["Session.Settings.Tyre.Wet.Pressure.Target.FL"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.FL", 30.0)
		facts["Session.Settings.Tyre.Wet.Pressure.Target.FR"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.FR", 30.0)
		facts["Session.Settings.Tyre.Wet.Pressure.Target.RL"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.RL", 30.0)
		facts["Session.Settings.Tyre.Wet.Pressure.Target.RR"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.RR", 30.0)
		facts["Session.Settings.Tyre.Pressure.Deviation"] := getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Pressure.Deviation", 0.2)
		facts["Session.Settings.Tyre.Pressure.Correction.Temperature"] := getConfigurationValue(settings, "Session Settings", "Tyre.Pressure.Correction.Temperature", true)
		facts["Session.Settings.Tyre.Pressure.Correction.Setup"] := getConfigurationValue(settings, "Session Settings", "Tyre.Pressure.Correction.Setup", true)
		
		facts["Session.Setup.Tyre.Set.Fresh"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Set.Fresh", 8)
		facts["Session.Setup.Tyre.Set"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Set", 7)
		facts["Session.Setup.Tyre.Dry.Pressure.FL"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.FL", 26.1)
		facts["Session.Setup.Tyre.Dry.Pressure.FR"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.FR", 26.1)
		facts["Session.Setup.Tyre.Dry.Pressure.RL"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.RL", 26.1)
		facts["Session.Setup.Tyre.Dry.Pressure.RR"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.RR", 26.1)
		facts["Session.Setup.Tyre.Wet.Pressure.FL"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.FL", 28.2)
		facts["Session.Setup.Tyre.Wet.Pressure.FR"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.FR", 28.2)
		facts["Session.Setup.Tyre.Wet.Pressure.RL"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.RL", 28.2)
		facts["Session.Setup.Tyre.Wet.Pressure.RR"] := getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.RR", 28.2)
		facts["Session.Setup.Tyre.Compound"] := getConfigurationValue(data, "Car Data", "TyreCompound", getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Compound", "Dry"))
		facts["Session.Setup.Tyre.Compound.Color"] := getConfigurationValue(data, "Car Data", "TyreCompoundColor", getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Compound.Color", "Black"))
				
		return facts
	}
	
	updateSession(settings) {
		local knowledgeBase := this.KnowledgeBase
		local facts
		
		if knowledgeBase {
			if !IsObject(settings)
				settings := readConfiguration(settings)
			
			facts := {"Session.Settings.Pitstop.Delta": getConfigurationValue(settings, "Strategy Settings", "Pitstop.Delta", getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Pitstop.Delta", 30))
					, "Session.Settings.Damage.Suspension.Repair": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Suspension.Repair", "Always")
					, "Session.Settings.Damage.Suspension.Repair.Threshold": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Suspension.Repair.Threshold", 0)
					, "Session.Settings.Damage.Bodywork.Repair": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Bodywork.Repair", "Threshold")
					, "Session.Settings.Damage.Bodywork.Repair.Threshold": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Damage.Bodywork.Repair.Threshold", 20)
					, "Session.Settings.Tyre.Compound.Change": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Compound.Change", "Never")
					, "Session.Settings.Tyre.Compound.Change.Threshold": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Compound.Change.Threshold", 0)
					, "Session.Settings.Tyre.Pressure.Correction.Temperature": getConfigurationValue(settings, "Session Settings", "Tyre.Pressure.Correction.Temperature", true)
					, "Session.Settings.Tyre.Pressure.Correction.Setup": getConfigurationValue(settings, "Session Settings", "Tyre.Pressure.Correction.Setup", true)
					, "Session.Settings.Tyre.Dry.Pressure.Target.FL": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.FL", 27.7)
					, "Session.Settings.Tyre.Dry.Pressure.Target.FR": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.FR", 27.7)
					, "Session.Settings.Tyre.Dry.Pressure.Target.RL": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.RL", 27.7)
					, "Session.Settings.Tyre.Dry.Pressure.Target.RR": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Dry.Pressure.Target.RR", 27.7)
					, "Session.Settings.Tyre.Wet.Pressure.Target.FL": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.FL", 30.0)
					, "Session.Settings.Tyre.Wet.Pressure.Target.FR": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.FR", 30.0)
					, "Session.Settings.Tyre.Wet.Pressure.Target.RL": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.RL", 30.0)
					, "Session.Settings.Tyre.Wet.Pressure.Target.RR": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Wet.Pressure.Target.RR", 30.0)
					, "Session.Settings.Tyre.Pressure.Deviation": getDeprecatedConfigurationValue(settings, "Session Settings", "Race Settings", "Tyre.Pressure.Deviation", 0.2)
					, "Session.Setup.Tyre.Set.Fresh": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Set.Fresh", 8)
					, "Session.Setup.Tyre.Set": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Set", 7)
					, "Session.Setup.Tyre.Dry.Pressure.FL": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.FL", 26.1)
					, "Session.Setup.Tyre.Dry.Pressure.FR": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.FR", 26.1)
					, "Session.Setup.Tyre.Dry.Pressure.RL": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.RL", 26.1)
					, "Session.Setup.Tyre.Dry.Pressure.RR": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Dry.Pressure.RR", 26.1)
					, "Session.Setup.Tyre.Wet.Pressure.FL": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.FL", 28.2)
					, "Session.Setup.Tyre.Wet.Pressure.FR": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.FR", 28.2)
					, "Session.Setup.Tyre.Wet.Pressure.RL": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.RL", 28.2)
					, "Session.Setup.Tyre.Wet.Pressure.RR": getDeprecatedConfigurationValue(settings, "Session Setup", "Race Setup", "Tyre.Wet.Pressure.RR", 28.2)}
			
			for key, value in facts
				knowledgeBase.setValue(key, value)
			
			base.updateSession(settings)
		}
	}
	
	startSession(data) {
		if !IsObject(data)
			data := readConfiguration(data)
		
		session := this.createSession(data)
		
		simulatorName := this.Simulator
		configuration := this.Configuration
		
		this.updateConfigurationValues({LearningLaps: getConfigurationValue(configuration, "Race Engineer Analysis", simulatorName . ".LearningLaps", 1)
									  , AdjustLapTime: getConfigurationValue(configuration, "Race Engineer Analysis", simulatorName . ".AdjustLapTime", true)
									  , SaveSettings: getConfigurationValue(configuration, "Race Assistant Shutdown", simulatorName . ".SaveSettings", getConfigurationValue(configuration, "Race Engineer Shutdown", simulatorName . ".SaveSettings", kNever))
									  , SaveTyrePressures: getConfigurationValue(configuration, "Race Engineer Shutdown", simulatorName . ".SaveTyrePressures", kAsk)})
		
		this.updateDynamicValues({KnowledgeBase: this.createKnowledgeBase(session), SetupData: {}
								, BestLapTime: 0, OverallTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false})
		
		if this.Speaker {
			speaker := this.getSpeaker()
			
			speaker.speakPhrase("GreetingEngineer")
			
			Process Exist, Race Strategist.exe
			
			if ErrorLevel {
				strategistPlugin := new Plugin("Race Strategist", kSimulatorConfiguration)
				strategistName := strategistPlugin.getArgumentValue("raceAssistantName", false)
				
				if strategistName {
					speaker.speakPhrase("GreetingStrategist", {strategist: strategistName})
				
					speaker.speakPhrase("CallUs")
				}
				else
					speaker.speakPhrase("CallMe")
			}
			else
				speaker.speakPhrase("CallMe")
		}
		
		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(this.KnowledgeBase)
	}
	
	finishSession() {
		if this.KnowledgeBase {
			if this.Speaker
				this.getSpeaker().speakPhrase("Bye")
			
			if ((this.Session == kSessionPractice) || (this.Session == kSessionRace)) {
				this.shutdownSession("Before")
						
				if (this.Listener && (((this.SaveTyrePressures == kAsk) && (this.SetupData.Count() > 0)) || (this.SaveSettings == kAsk))) {
					this.getSpeaker().speakPhrase("ConfirmDataUpdate", false, true)
					
					this.setContinuation(ObjBindMethod(this, "shutdownSession", "After"))
					
					callback := ObjBindMethod(this, "forceFinishSession")
					
					SetTimer %callback%, -120000
					
					return
				}
			}
			
			this.updateDynamicValues({KnowledgeBase: false})
		}

		this.updateDynamicValues({BestLapTime: 0, OverallTime: 0, LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false})
		this.updateSessionValues({Simulator: "", Session: kSessionFinished, SessionTime: false})
	}
	
	forceFinishSession() {
		if !this.SessionDataActive {
			this.updateDynamicValues({KnowledgeBase: false, SetupData: {}})
			
			this.finishSession()
		}
	}
	
	prepareData(lapNumber, data) {
		local knowledgeBase
		
		data := base.prepareData(lapNumber, data)
		
		knowledgeBase := this.KnowledgeBase
		
		if (knowledgeBase.getValue("Lap", false) != lapNumber) {
			bodyworkDamage := string2Values(",", getConfigurationValue(data, "Car Data", "BodyworkDamage", ""))
			
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Front", Round(bodyworkDamage[1], 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Rear", Round(bodyworkDamage[2], 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Left", Round(bodyworkDamage[3], 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Right", Round(bodyworkDamage[4], 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Bodywork.Center", Round(bodyworkDamage[5], 2))
			
			suspensionDamage := string2Values(",", getConfigurationValue(data, "Car Data", "SuspensionDamage", ""))
			
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.FL", Round(suspensionDamage[1], 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.FR", Round(suspensionDamage[2], 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.RL", Round(suspensionDamage[3], 2))
			knowledgeBase.addFact("Lap." . lapNumber . ".Damage.Suspension.RR", Round(suspensionDamage[4], 2))
		}
		
		return data
	}
	
	addLap(lapNumber, data) {
		local knowledgeBase
		
		result := base.addLap(lapNumber, data)
		
		knowledgeBase := this.KnowledgeBase
		
		if this.hasEnoughData(false) {
			currentCompound := knowledgeBase.getValue("Tyre.Compound", false)
			currentCompoundColor := knowledgeBase.getValue("Tyre.Compound.Color", false)
			targetCompound := knowledgeBase.getValue("Tyre.Compound.Target", false)
			targetCompoundColor := knowledgeBase.getValue("Tyre.Compound.Color.Target", false)
		
			airTemperature := Round(getConfigurationValue(data, "Weather Data", "Temperature", 0))
			trackTemperature := Round(getConfigurationValue(data, "Track Data", "Temperature", 0))
			
			if (airTemperature = 0)
				airTemperature := Round(getConfigurationValue(data, "Car Data", "AirTemperature", 0))
			
			if (trackTemperature = 0)
				trackTemperature := Round(getConfigurationValue(data, "Car Data", "RoadTemperature", 0))
		
			weatherNow := getConfigurationValue(data, "Weather Data", "Weather", "Dry")
			
			lastValid := knowledgeBase.getValue("Lap." . (lapNumber - 1) . ".Valid", true)
		
			if (lastValid && currentCompound && (currentCompound = targetCompound) && (currentCompoundColor = targetCompoundColor))
				this.updateSetupData(knowledgeBase.getValue("Session.Simulator"), knowledgeBase.getValue("Session.Car"), knowledgeBase.getValue("Session.Track")
								   , weatherNow, airTemperature, trackTemperature, currentCompound, currentCompoundColor)
		}
		
		return result
	}
	
	updateLap(lapNumber, data) {
		local knowledgeBase := this.KnowledgeBase
		local fact
		
		result := base.updateLap(lapNumber, data)
		
		needProduce := false
		
		tyrePressures := string2Values(",", getConfigurationValue(data, "Car Data", "TyrePressure", ""))
		threshold := knowledgeBase.getValue("Session.Settings.Tyre.Pressure.Deviation")
		changed := false
		
		for index, tyreType in ["FL", "FR", "RL", "RR"] {
			newValue := Round(tyrePressures[index], 2)
			fact := ("Lap." . lapNumber . ".Tyre.Pressure." . tyreType)
		
			if (Abs(knowledgeBase.getValue(fact) - newValue) > threshold) {
				knowledgeBase.setValue(fact, newValue)
				
				changed := true
			}
		}
		
		if changed {
			knowledgeBase.addFact("Tyre.Update.Pressure", true)
		
			needProduce := true
		}
		
		tyreTemperatures := string2Values(",", getConfigurationValue(data, "Car Data", "TyreTemperature", ""))
		
		for index, tyreType in ["FL", "FR", "RL", "RR"]
			knowledgeBase.setValue("Lap." . lapNumber . ".Tyre.Temperature." . tyreType, Round(tyreTemperatures[index], 2))
		
		bodyworkDamage := string2Values(",", getConfigurationValue(data, "Car Data", "BodyworkDamage", ""))
		changed := false
		
		for index, position in ["Front", "Rear", "Left", "Right", "Center"] {
			newValue := Round(bodyworkDamage[index], 2)
			fact := ("Lap." . lapNumber . ".Damage.Bodywork." . position)
			oldValue := knowledgeBase.getValue(fact, 0)
			
			if (oldValue < newValue)
				knowledgeBase.setValue(fact, newValue)
			
			changed := (changed || (Round(oldValue) < Round(newValue)))
		}
		
		if changed {
			knowledgeBase.addFact("Damage.Update.Bodywork", lapNumber)
		
			needProduce := true
		}
		
		suspensionDamage := string2Values(",", getConfigurationValue(data, "Car Data", "SuspensionDamage", ""))
		changed := false
		
		for index, position in ["FL", "FR", "RL", "RR"] {
			newValue := Round(suspensionDamage[index], 2)
			fact := ("Lap." . lapNumber . ".Damage.Suspension." . position)
			oldValue := knowledgeBase.getValue(fact, 0)
			
			if (oldValue < newValue)
				knowledgeBase.setValue(fact, newValue)
		
			changed := (changed || (Round(oldValue) < Round(newValue)))
		}
		
		if changed {
			knowledgeBase.addFact("Damage.Update.Suspension", lapNumber)
		
			needProduce := true
		}
				
		if needProduce {
			if knowledgeBase.produce()
				result := true
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(this.KnowledgeBase)
		}

		return result
	}
	
	updateSetupData(simulator, car, track, weather, airTemperature, trackTemperature, compound, compoundColor) {
		local knowledgeBase := this.KnowledgeBase
		
		this.iSessionDataActive := true
		
		try {
			targetPressures := Array(Round(knowledgeBase.getValue("Tyre.Pressure.Target.FL"), 1)
								   , Round(knowledgeBase.getValue("Tyre.Pressure.Target.FR"), 1)
								   , Round(knowledgeBase.getValue("Tyre.Pressure.Target.RL"), 1)
								   , Round(knowledgeBase.getValue("Tyre.Pressure.Target.RR"), 1))
			
			if (compoundColor = "Black")
				descriptor := ConfigurationItem.descriptor(simulator, track, car, compound, airTemperature, trackTemperature, weather)
			else
				descriptor := ConfigurationItem.descriptor(simulator, track, car, compound, compoundColor, airTemperature, trackTemperature, weather)
			
			if this.SetupData.HasKey(descriptor)
				setupData := this.SetupData[descriptor]
			else {
				setupData := Object()
			
				this.SetupData[descriptor] := setupData
			}
			
			for ignore, tyre in ["FL", "FR", "RL", "RR"] {
				pressure := (tyre . ":" . targetPressures[A_Index])
				
				setupData[pressure] := (setupData.HasKey(pressure) ? (setupData[pressure] + 1) : 1)
			}
		}
		finally {
			this.iSessionDataActive := false
		}
	}
	
	shutdownSession(phase) {
		this.iSessionDataActive := true
		
		try {
			if ((this.Session == kSessionRace) && (this.SaveSettings = ((phase = "Before") ? kAlways : kAsk)))
				this.saveSessionSettings()
			
			if ((this.SaveTyrePressures = ((phase = "After") ? kAsk : kAlways)) && (this.SetupData.Count() > 0))
				this.saveTyrePressureData()
		}
		finally {
			this.iSessionDataActive := false
		}
		
		if (phase = "After") {
			if this.Speaker
				this.getSpeaker().speakPhrase("DataUpdated")
			
			this.updateDynamicValues({KnowledgeBase: false, SetupData: {}})
			
			this.finishSession()
		}
	}
	
	saveSessionSettings() {
		local knowledgeBase := this.KnowledgeBase
		local compound
		
		if knowledgeBase {
			setupDB := this.SetupDatabase
			
			simulatorName := setupDB.getSimulatorName(knowledgeBase.getValue("Session.Simulator"))
			car := knowledgeBase.getValue("Session.Car")
			track := knowledgeBase.getValue("Session.Track")
			duration := knowledgeBase.getValue("Session.Duration")
			weather := knowledgeBase.getValue("Weather.Now")
			compound := knowledgeBase.getValue("Tyre.Compound")
			compoundColor := knowledgeBase.getValue("Tyre.Compound.Color")
			
			oldValue := getConfigurationValue(this.Configuration, "Race Engineer Startup", simulatorName . ".LoadSettings", "Default")
			loadSettings := getConfigurationValue(this.Configuration, "Race Assistant Startup", simulatorName . ".LoadSettings", oldValue)
		
			duration := (Round((duration / 60) / 5) * 300)
			
			values := {AvgFuelConsumption: this.AvgFuelConsumption, Compound: compound, CompoundColor: compoundColor, Duration: duration}
			
			lapTime := Round(this.BestLapTime / 1000)
			
			if (lapTime > 10)
				values["AvgLapTime"] := lapTime
			
			if (loadSettings = "SetupDatabase")
				setupDB.updateSettings(simulatorName, car, track
									 , {Duration: duration, Weather: weather, Compound: compound, CompoundColor: compoundColor}, values)
			else {
				fileName := getFileName("Race.settings", kUserConfigDirectory)
				
				settings := readConfiguration(fileName)
				
				setupDB.updateSettingsValues(settings, values)
				
				writeConfiguration(fileName, settings)
			}
		}
	}

	saveTyrePressureData() {
		local compound
		
		if this.KnowledgeBase
			for descriptor, pressures in this.SetupData {
				descriptor := ConfigurationItem.splitDescriptor(descriptor)
			
				simulator := descriptor[1]
				track := descriptor[2]
				car := descriptor[3]
				compound := descriptor[4]
				
				if (descriptor.Length() = 7) {
					compoundColor := "Black"
					airTemperature := descriptor[5]
					trackTemperature := descriptor[6]
					weather := descriptor[7]
				}
				else {
					compoundColor := descriptor[5]
					airTemperature := descriptor[6]
					trackTemperature := descriptor[7]
					weather := descriptor[8]
				}
				
				this.SetupDatabase.updatePressures(simulator, car, track, weather, airTemperature, trackTemperature, compound, compoundColor, pressures)
			}
		
		this.updateDynamicValues({SetupData: {}})
	}
	
	hasPlannedPitstop() {
		return this.KnowledgeBase.getValue("Pitstop.Planned", false)
	}
	
	hasPreparedPitstop() {
		return this.KnowledgeBase.getValue("Pitstop.Prepared", false)
	}
	
	supportsPitstop() {
		return ((this.Session == kSessionRace) && this.PitstopHandler)
	}
	
	requestInformation(category, arguments*) {
		switch category {
			case "LapsRemaining":
				this.lapInfoRecognized([])
			case "Weather":
				this.weatherRecognized([])
			case "TyrePressures":
				this.tyreInfoRecognized(Array(this.getSpeaker().Fragments["Pressures"]))
			case "TyreTemperatures":
				this.tyreInfoRecognized(Array(this.getSpeaker().Fragments["Temperatures"]))
		}
	}
	
	planPitstop(optionsOrLap := true, refuelAmount := "__Undefined__", changeTyres := "__Undefined__") {
		local knowledgeBase := this.KnowledgeBase
		local compound
		
		confirm := true
		
		options := optionsOrLap
		plannedLap := false
		
		if (optionsOrLap != true)
			if optionsOrLap is number
			{
				plannedLap := optionsOrLap
				
				options := true
			}
			else if IsObject(optionsOrLap)
				if optionsOrLap.HasKey("Confirm")
					confirm := optionsOrLap["Confirm"]
		
		if !this.hasEnoughData()
			return false
		
		if !this.supportsPitstop() {
			if this.Speaker
				this.getSpeaker().speakPhrase("NoPitstop")
			
			return false
		}
	
		knowledgeBase.addFact("Pitstop.Plan", ((options == true) || !options.HasKey("Update") || !options.Update) ? true : false)
		
		if (refuelAmount != kUndefined)
			knowledgeBase.addFact("Pitstop.Plan.Fuel.Amount.Target", refuelAmount)
		
		if (changeTyres != kUndefined)
			knowledgeBase.addFact("Pitstop.Plan.Tyre.Change", changeTyres)
	
		result := knowledgeBase.produce()
		
		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(knowledgeBase)
		
		pitstopNumber := knowledgeBase.getValue("Pitstop.Planned.Nr")
		
		knowledgeBase.setFact("Pitstop.Planned.Lap", plannedLap)
		
		if this.Speaker {
			speaker := this.getSpeaker()
			fragments := speaker.Fragments
			
			if ((options == true) || options.Intro)
				speaker.speakPhrase("Pitstop", {number: pitstopNumber})
			
			if ((options == true) || options.Fuel) {
				fuel := Round(knowledgeBase.getValue("Pitstop.Planned.Fuel", 0))
				
				if (fuel == 0)
					speaker.speakPhrase("NoRefuel")
				else
					speaker.speakPhrase("Refuel", {litres: fuel})
			}
			
			compound := knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound", false)
			
			if ((options == true) || options.Compound) {
				if compound {
					color := knowledgeBase.getValue("Pitstop.Planned.Tyre.Compound.Color")
					
					if (compound = "Dry")
						speaker.speakPhrase("DryTyres", {compound: fragments[compound], color: color, set: knowledgeBase.getValue("Pitstop.Planned.Tyre.Set")})
					else
						speaker.speakPhrase("WetTyres", {compound: fragments[compound], color: color, set: knowledgeBase.getValue("Pitstop.Planned.Tyre.Set")})
				}
				else {
					if (knowledgeBase.getValue("Lap.Remaining.Stint") > 5)
						speaker.speakPhrase("NoTyreChange")
					else
						speaker.speakPhrase("NoTyreChangeLap")
				}
			}
			
			debug := this.Debug[kDebugPhrases]
			
			if (compound && ((options == true) || options.Pressures)) {
				incrementFL := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FL.Increment", 0), 1)
				incrementFR := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FR.Increment", 0), 1)
				incrementRL := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RL.Increment", 0), 1)
				incrementRR := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RR.Increment", 0), 1)
			
				if (debug || (incrementFL != 0) || (incrementFR != 0) || (incrementRL != 0) || (incrementRR != 0))
					speaker.speakPhrase("NewPressures")
				
				if (debug || (incrementFL != 0))
					speaker.speakPhrase("TyreFL", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FL"), 1))
												 , unit: fragments["PSI"]})
				
				if (debug || (incrementFR != 0))
					speaker.speakPhrase("TyreFR", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.FR"), 1))
												 , unit: fragments["PSI"]})
				
				if (debug || (incrementRL != 0))
					speaker.speakPhrase("TyreRL", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RL"), 1))
												 , unit: fragments["PSI"]})
				
				if (debug || (incrementRR != 0))
					speaker.speakPhrase("TyreRR", {value: Format("{:.1f}", Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.RR"), 1))
												 , unit: fragments["PSI"]})
		
				pressureCorrection := Round(knowledgeBase.getValue("Pitstop.Planned.Tyre.Pressure.Correction", 0), 1)
				
				if (Abs(pressureCorrection) > 0.05) {
					temperatureDelta := knowledgeBase.getValue("Weather.Temperature.Air.Delta", 0)
					
					if (temperatureDelta = 0)
						temperatureDelta := ((pressureCorrection > 0) ? -1 : 1)
					
					speaker.speakPhrase((pressureCorrection > 0) ? "PressureCorrectionUp" : "PressureCorrectionDown"
									  , {value: Format("{:.1f}", Abs(pressureCorrection)), unit: fragments["PSI"]
									   , pressureDirection: (pressureCorrection > 0) ? fragments["Increase"] : fragments["Decrease"]
									   , temperatureDirection: (temperatureDelta > 0) ? fragments["Rising"] : fragments["Falling"]})
				}
			}

			if ((options == true) || options.Repairs) {
				if knowledgeBase.getValue("Pitstop.Planned.Repair.Suspension", false)
					speaker.speakPhrase("RepairSuspension")
				else if debug
					speaker.speakPhrase("NoRepairSuspension")

				if knowledgeBase.getValue("Pitstop.Planned.Repair.Bodywork", false)
					speaker.speakPhrase("RepairBodywork")
				else if debug
					speaker.speakPhrase("NoRepairBodywork")
			}
			
			if (confirm && this.Listener)
				if plannedLap
					speaker.speakPhrase("PitstopLap", {lap: plannedLap})
				else {
					speaker.speakPhrase("ConfirmPrepare", false, true)
					
					this.setContinuation(ObjBindMethod(this, "preparePitstop"))
				}
		}
		
		if (result && this.PitstopHandler) {
			this.PitstopHandler.pitstopPlanned(pitstopNumber, plannedLap)
		}
		
		return result
	}
	
	preparePitstop(lap := false) {
		if !this.supportsPitstop() {
			if this.Speaker
				this.getSpeaker().speakPhrase("NoPitstop")
			
			return false
		}
		
		if !this.hasPlannedPitstop() {
			if this.Speaker {
				speaker := this.getSpeaker()

				speaker.speakPhrase("MissingPlan")
				
				if (this.Listener && this.supportsPitstop()) {
					speaker.speakPhrase("ConfirmPlan", false, true)
				
					this.setContinuation(ObjBindMethod(this, "planPitstop"))
				}
			}
			
			return false
		}
		else {
			if this.Speaker {
				speaker := this.getSpeaker()

				if lap
					speaker.speakPhrase("PrepareLap", {lap: lap})
				else
					speaker.speakPhrase("PrepareNow")
			}
				
			if !lap
				this.KnowledgeBase.addFact("Pitstop.Prepare", true)
			else
				this.KnowledgeBase.setFact("Pitstop.Planned.Lap", lap - 1)
		
			result := this.KnowledgeBase.produce()
			
			if this.Debug[kDebugKnowledgeBase]
				this.dumpKnowledge(this.KnowledgeBase)
					
			return result
		}
	}
	
	pitstopOptionChanged(option, values*) {
		local knowledgeBase := this.KnowledgeBase
		local compound
		
		if this.hasPreparedPitstop() {
			switch option {
				case "Refuel":
					knowledgeBase.setFact("Pitstop.Planned.Fuel", values[1])
				case "Tyre Compound":
					knowledgeBase.setFact("Pitstop.Planned.Tyre.Compound", values[1])
					knowledgeBase.setFact("Pitstop.Planned.Tyre.Compound.Color", values[2])
				case "Tyre Set":
					knowledgeBase.setFact("Pitstop.Planned.Tyre.Set", values[1])
				case "Tyre Pressures":
					for index, suffix in ["FL", "FR", "RL", "RR"] {
						prssKey := ("Pitstop.Planned.Tyre.Pressure." . suffix)
						incrKey := ("Pitstop.Planned.Tyre.Pressure." . suffix . ".Increment")
						
						targetPressure := values[index]
						
						knowledgeBase.setFact(prssKey, targetPressure)
						knowledgeBase.setFact(incrKey, knowledgeBase.getValue(incrKey) + (targetPressure - knowledgeBase.getValue(prssKey)))
					}
				case "Repair Suspension":
					knowledgeBase.setFact("Pitstop.Planned.Repair.Suspension", values[1])
				case "Repair Bodywork":
					knowledgeBase.setFact("Pitstop.Planned.Repair.Bodywork", values[1])
			}
		}
	}
	
	performPitstop(lapNumber := false) {
		local knowledgeBase := this.KnowledgeBase
		
		if this.Speaker
			this.getSpeaker().speakPhrase("Perform")
		
		knowledgeBase.addFact("Pitstop.Lap", lapNumber ? lapNumber : knowledgeBase.getValue("Lap"))
		
		result := knowledgeBase.produce()
		
		this.updateDynamicValues({LastFuelAmount: 0, InitialFuelAmount: 0, EnoughData: false})
		
		if this.Debug[kDebugKnowledgeBase]
			this.dumpKnowledge(knowledgeBase)
		
		if (result && this.PitstopHandler)
			this.PitstopHandler.pitstopFinished(knowledgeBase.getValue("Pitstop.Last", 0))
		
		return result
	}
	
	callPlanPitstop(lap := false) {		
		this.clearContinuation()
		
		if !this.supportsPitstop()
			this.getSpeaker().speakPhrase("NoPitstop")
		else {
			this.getSpeaker().speakPhrase("Confirm")
		
			sendMessage()
		
			Loop 10
				Sleep 500
			
			if lap
				this.planPitstop(lap)
			else
				this.planPitstop()
		}
	}
	
	callPreparePitstop(lap := false) {		
		this.clearContinuation()
				
		if !this.supportsPitstop()
			this.getSpeaker().speakPhrase("NoPitstop")
		else {
			this.getSpeaker().speakPhrase("Confirm")
		
			sendMessage()
			
			Loop 10
				Sleep 500
			
			if lap
				this.preparePitstop(lap)
			else
				this.preparePitstop()
		}
	}
	
	lowFuelWarning(remainingLaps) {
		if this.Speaker {
			speaker := this.getSpeaker()
			
			speaker.speakPhrase((remainingLaps <= 2) ? "VeryLowFuel" : "LowFuel", {laps: remainingLaps})
						
			if (this.Listener && this.supportsPitstop()) {
				if this.hasPreparedPitstop()
					speaker.speakPhrase((remainingLaps <= 2) ? "LowComeIn" : "ComeIn")
				else if !this.hasPlannedPitstop() {
					speaker.speakPhrase("ConfirmPlan", false, true)
					
					this.setContinuation(ObjBindMethod(this, "planPitstop"))
				}
				else if !(this.KnowledgeBase.getValue("Pitstop.Planned.Lap", 0) >= this.KnowledgeBase.getValue("Lap")) {
					speaker.speakPhrase("ConfirmPrepare", false, true)
					
					this.setContinuation(ObjBindMethod(this, "preparePitstop"))
				}
			}
		}
	}
	
	damageWarning(newSuspensionDamage, newBodyworkDamage) {
		local knowledgeBase := this.KnowledgeBase
		
		if this.Speaker {
			speaker := this.getSpeaker()
			phrase := false
			
			if (newSuspensionDamage && newBodyworkDamage)
				phrase := "BothDamage"
			else if newSuspensionDamage
				phrase := "SuspensionDamage"
			else if newBodyworkDamage
				phrase := "BodyworkDamage"
			
			speaker.speakPhrase(phrase)
	
			if (knowledgeBase.getValue("Lap.Remaining") > 4)
				speaker.speakPhrase("DamageAnalysis")
			else
				speaker.speakPhrase("NoDamageAnalysis")
		}
	}
	
	reportDamageAnalysis(repair, stintLaps, delta) {
		local knowledgeBase := this.KnowledgeBase
		
		if (knowledgeBase.getValue("Lap.Remaining") > 3)
			if this.Speaker {
				speaker := this.getSpeaker()
				
				stintLaps := Round(stintLaps)
				delta := Format("{:.1f}", Round(delta, 2))
				
				if repair {
					speaker.speakPhrase("RepairPitstop", {laps: stintLaps, delta: delta})
			
					if (this.Listener && this.supportsPitstop()) {
						speaker.speakPhrase("ConfirmPlan", false, true)
					
						this.setContinuation(ObjBindMethod(this, "planPitstop"))
					}
				}
				else if (repair == false)
					speaker.speakPhrase((delta == 0) ? "NoTimeLost" : "NoRepairPitstop", {laps: stintLaps, delta: delta})
			}
	}
	
	weatherChangeNotification(change, minutes) {
		local knowledgeBase := this.KnowledgeBase
			
		Process Exist, Race Strategist.exe
		
		if !ErrorLevel
			if this.Speaker {
				speaker := this.getSpeaker()
				
				speaker.speakPhrase(change ? "WeatherChange" : "WeatherNoChange", {minutes: minutes})
			}
	}
	
	weatherTyreChangeRecommendation(minutes, recommendedCompound) {
		local knowledgeBase := this.KnowledgeBase
		
		Process Exist, Race Strategist.exe
		
		if (!ErrorLevel && (knowledgeBase.getValue("Lap.Remaining") > 3))
			if this.Speaker {
				speaker := this.getSpeaker()
				fragments := speaker.Fragments
				
				speaker.speakPhrase((recommendedCompound = "Wet") ? "WeatherRainChange" : "WeatherDryChange"
								  , {minutes: minutes, compound: fragments[recommendedCompound]})
				
				if (this.Listener && this.supportsPitstop()) {
					speaker.speakPhrase("ConfirmPlan", false, true)
				
					this.setContinuation(ObjBindMethod(this, "planPitstop"))
				}
			}
	}
	
	startPitstopSetup(pitstopNumber) {
		if this.PitstopHandler
			this.PitstopHandler.startPitstopSetup(pitstopNumber)
	}

	finishPitstopSetup(pitstopNumber) {
		if this.PitstopHandler {
			this.PitstopHandler.finishPitstopSetup(pitstopNumber)
			
			this.PitstopHandler.pitstopPrepared(pitstopNumber)
			
			if this.Speaker
				this.getSpeaker().speakPhrase("CallToPit")
		}
	}

	setPitstopRefuelAmount(pitstopNumber, litres) {
		if this.PitstopHandler
			this.PitstopHandler.setPitstopRefuelAmount(pitstopNumber, litres)
	}

	setPitstopTyreSet(pitstopNumber, compound, compoundColor, set) {
		if this.PitstopHandler
			this.PitstopHandler.setPitstopTyreSet(pitstopNumber, compound, compoundColor, set)
	}

	setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
		if this.PitstopHandler
			this.PitstopHandler.setPitstopTyrePressures(pitstopNumber, Round(pressureFL, 1), Round(pressureFR, 1), Round(pressureRL, 1), Round(pressureRR, 1))
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork) {
		if this.PitstopHandler
			this.PitstopHandler.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork)
	}
	
	getTyrePressures(weather, airTemperature, trackTemperature, ByRef compound, ByRef compoundColor, ByRef pressures, ByRef certainty) {
		local knowledgeBase := this.KnowledgeBase
		
		return this.SetupDatabase.getTyreSetup(knowledgeBase.getValue("Session.Simulator"), knowledgeBase.getValue("Session.Car"), knowledgeBase.getValue("Session.Track")
											 , weather, airTemperature, trackTemperature, compound, compoundColor, pressures, certainty)
	}
}

;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

lowFuelWarning(context, remainingLaps) {
	context.KnowledgeBase.RaceAssistant.lowFuelWarning(Round(remainingLaps))
	
	return true
}

damageWarning(context, newSuspensionDamage, newBodyworkDamage) {
	context.KnowledgeBase.RaceAssistant.damageWarning(newSuspensionDamage, newBodyworkDamage)
	
	return true
}

reportDamageAnalysis(context, repair, stintLaps, delta) {
	context.KnowledgeBase.RaceAssistant.reportDamageAnalysis(repair, stintLaps, delta)
	
	return true
}

weatherChangeNotification(context, change, minutes) {
	context.KnowledgeBase.RaceAssistant.weatherChangeNotification(change, minutes)
	
	return true
}

weatherTyreChangeRecommendation(context, minutes, recommendedCompound) {
	context.KnowledgeBase.RaceAssistant.weatherTyreChangeRecommendation(minutes, recommendedCompound)
	
	return true
}

startPitstopSetup(context, pitstopNumber) {
	context.KnowledgeBase.RaceAssistant.startPitstopSetup(pitstopNumber)
	
	return true
}

finishPitstopSetup(context, pitstopNumber) {
	context.KnowledgeBase.RaceAssistant.finishPitstopSetup(pitstopNumber)
	
	return true
}

setPitstopRefuelAmount(context, pitstopNumber, litres) {
	context.KnowledgeBase.RaceAssistant.setPitstopRefuelAmount(pitstopNumber, litres)
	
	return true
}

setPitstopTyreSet(context, pitstopNumber, compound, compoundColor, set) {
	context.KnowledgeBase.RaceAssistant.setPitstopTyreSet(pitstopNumber, compound, compoundColor, set)
	
	return true
}

setPitstopTyrePressures(context, pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
	context.KnowledgeBase.RaceAssistant.setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR)
	
	return true
}

requestPitstopRepairs(context, pitstopNumber, repairSuspension, repairBodywork) {
	context.KnowledgeBase.RaceAssistant.requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork)
	
	return true
}

setupTyrePressures(context, weather, airTemperature, trackTemperature, compound, compoundColor) {
	local knowledgeBase := context.KnowledgeBase
	
	pressures := false
	certainty := 1.0
	
	if (!inList(kTyreCompounds, compound) || !inList(kTyreCompoundColors, compoundColor)) {
		compound := false
		compoundColor := false
	}
	
	airTemperature := Round(airTemperature)
	trackTemperature := Round(trackTemperature)
	
	if context.KnowledgeBase.RaceAssistant.getTyrePressures(weather, airTemperature, trackTemperature, compound, compoundColor, pressures, certainty) {
		knowledgeBase.setFact("Tyre.Setup.Certainty", certainty)
		knowledgeBase.setFact("Tyre.Setup.Compound", compound)
		knowledgeBase.setFact("Tyre.Setup.Compound.Color", compoundColor)
		knowledgeBase.setFact("Tyre.Setup.Weather", weather)
		knowledgeBase.setFact("Tyre.Setup.Temperature.Air", airTemperature)
		knowledgeBase.setFact("Tyre.Setup.Temperature.Track", trackTemperature)
		knowledgeBase.setFact("Tyre.Setup.Pressure.FL", pressures[1])
		knowledgeBase.setFact("Tyre.Setup.Pressure.FR", pressures[2])
		knowledgeBase.setFact("Tyre.Setup.Pressure.RL", pressures[3])
		knowledgeBase.setFact("Tyre.Setup.Pressure.RR", pressures[4])
		
		return true
	}
	else
		return false
}