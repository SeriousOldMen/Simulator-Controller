;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Race Strategist Configuration   ;;;
;;;                                         Plugin                          ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; RaceStrategistConfigurator                                              ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

global rsSimulatorDropDown

global rsLearningLapsEdit
global rsLapsConsideredEdit
global rsDampingFactorEdit
global rsSaveRaceReportDropDown
global rsSaveTelemetryDropDown
global rsRaceReviewDropDown

global raceReportsPathEdit := ""

class RaceStrategistConfigurator extends ConfigurationItem {
	iEditor := false

	iSimulators := []
	iSimulatorConfigurations := {}
	iCurrentSimulator := false

	Editor[] {
		Get {
			return this.iEditor
		}
	}

	Simulators[] {
		Get {
			return this.iSimulators
		}
	}

	__New(editor, configuration := false) {
		this.iEditor := editor

		base.__New(configuration)

		RaceStrategistConfigurator.Instance := this
	}

	createGui(editor, x, y, width, height) {
		local window := editor.Window
		local x0, x1, x2, x3, x4, x5, x6, w1, w2, w3, w4, choices, chosen, lineX, lineW

		Gui %window%:Font, Norm, Arial

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

		Gui %window%:Add, Text, x%x0% y%y% w160 h23 +0x200 HWNDwidget15 Hidden, % translate("Race Reports Folder")
		Gui %window%:Add, Edit, x%x1% yp w%w2% h21 VraceReportsPathEdit HWNDwidget16 Hidden, %raceReportsPathEdit%
		Gui %window%:Add, Button, x%x4% yp-1 w23 h23 gchooseRaceReportsPath HWNDwidget17 Hidden, % translate("...")

		lineX := x + 20
		lineW := width - 40

		Gui %window%:Add, Text, x%lineX% yp+30 w%lineW% 0x10 HWNDwidget24 Hidden

		Gui %window%:Add, Text, x%x0% yp+10 w105 h23 +0x200 HWNDwidget1 Hidden, % translate("Simulator")

		if (this.Simulators.Length() = 0)
			this.iSimulators := this.getSimulators()

 		choices := this.iSimulators
		chosen := (choices.Length() > 0) ? 1 : 0

		Gui %window%:Add, DropDownList, x%x1% yp w%w4% Choose%chosen% gchooseRaceStrategistSimulator vrsSimulatorDropDown HWNDwidget2 Hidden, % values2String("|", choices*)

		Gui %window%:Add, Button, x%x6% yp w23 h23 Center +0x200 greplicateRSSettings HWNDwidget29 Hidden
		setButtonIcon(widget29, kIconsDirectory . "Renew.ico", 1, "L4 T4 R4 B4")

		Gui %window%:Font, Norm, Arial
		Gui %window%:Font, Italic, Arial

		Gui %window%:Add, GroupBox, -Theme x%x% yp+40 w%width% h96 HWNDwidget3 Hidden, % translate("Data Analysis")

		Gui %window%:Font, Norm, Arial

		Gui %window%:Add, Text, x%x0% yp+17 w80 h23 +0x200 HWNDwidget4 Hidden, % translate("Learn for")
		Gui %window%:Add, Edit, x%x1% yp w40 h21 Number Limit1 vrsLearningLapsEdit HWNDwidget5 Hidden
		Gui %window%:Add, UpDown, x%x2% yp w17 h21 Range1-9 HWNDwidget6 Hidden, 1
		Gui %window%:Add, Text, x%x3% yp w%w3% h23 +0x200 HWNDwidget7 Hidden, % translate("Laps after Start or Pitstop")

		Gui %window%:Add, Text, x%x0% yp+26 w105 h20 Section HWNDwidget8 Hidden, % translate("Statistical Window")
		Gui %window%:Add, Edit, x%x1% yp-2 w40 h21 Number Limit1 vrsLapsConsideredEdit HWNDwidget9 Hidden
		Gui %window%:Add, UpDown, x%x2% yp w17 h21 Range1-9 HWNDwidget10 Hidden, 1
		Gui %window%:Add, Text, x%x3% yp+2 w80 h20 HWNDwidget11 Hidden, % translate("Laps")

		Gui %window%:Add, Text, x%x0% ys+24 w105 h20 Section HWNDwidget12 Hidden, % translate("Damping Factor")
		Gui %window%:Add, Edit, x%x1% yp-2 w40 h21 vrsDampingFactorEdit gvalidateRSDampingFactor HWNDwidget13 Hidden
		Gui %window%:Add, Text, x%x3% yp+2 w80 h20 HWNDwidget14 Hidden, % translate("p. Lap")

		Gui %window%:Font, Norm, Arial
		Gui %window%:Font, Italic, Arial

		Gui %window%:Add, GroupBox, -Theme x%x% yp+40 w%width% h96 HWNDwidget28 Hidden, % translate("Actions")

		Gui %window%:Font, Norm, Arial

		choices := map(["Ask", "Always save", "No action"], "translate")
		Gui %window%:Add, Text, x%x0% yp+17 w105 h23 +0x200 HWNDwidget18 Hidden, % translate("Save Race Report")
		Gui %window%:Add, DropDownList, x%x1% yp w110 AltSubmit vrsSaveRaceReportDropDown HWNDwidget19 Hidden, % values2String("|", choices*)

		x5 := x1 + 114

		Gui %window%:Add, Text, x%x5% yp+3 w110 h20 HWNDwidget20 Hidden, % translate("@ Session End")

		choices := map(["Ask", "Always save", "No action"], "translate")
		Gui %window%:Add, Text, x%x0% yp+21 w105 h23 +0x200 HWNDwidget21 Hidden, % translate("Save Telemetry")
		Gui %window%:Add, DropDownList, x%x1% yp w110 AltSubmit vrsSaveTelemetryDropDown HWNDwidget22 Hidden, % values2String("|", choices*)

		Gui %window%:Add, Text, x%x5% yp+3 w110 h20 HWNDwidget23 Hidden, % translate("@ Session End")

		choices := map(["No", "Yes"], "translate")
		Gui %window%:Add, Text, x%x0% yp+21 w105 h23 +0x200 HWNDwidget25 Hidden, % translate("Race Review")
		Gui %window%:Add, DropDownList, x%x1% yp w110 AltSubmit vrsRaceReviewDropDown HWNDwidget26 Hidden, % values2String("|", choices*)

		Gui %window%:Add, Text, x%x5% yp+3 w110 h20 HWNDwidget27 Hidden, % translate("@ Session End")

		loop 29
			editor.registerWidget(this, widget%A_Index%)

		this.loadSimulatorConfiguration()
	}

	loadFromConfiguration(configuration) {
		local ignore, simulator, simulatorConfiguration

		base.loadFromConfiguration(configuration)

		raceReportsPathEdit := getConfigurationValue(configuration, "Race Strategist Reports", "Database", false)

		if !raceReportsPathEdit
			raceReportsPathEdit := ""

		if (this.Simulators.Length() = 0)
			this.iSimulators := this.getSimulators()

		for ignore, simulator in this.Simulators {
			simulatorConfiguration := {}

			simulatorConfiguration["LearningLaps"] := getConfigurationValue(configuration, "Race Strategist Analysis", simulator . ".LearningLaps", 1)
			simulatorConfiguration["ConsideredHistoryLaps"] := getConfigurationValue(configuration, "Race Strategist Analysis", simulator . ".ConsideredHistoryLaps", 5)
			simulatorConfiguration["HistoryLapsDamping"] := getConfigurationValue(configuration, "Race Strategist Analysis", simulator . ".HistoryLapsDamping", 0.2)
			simulatorConfiguration["SaveRaceReport"] := getConfigurationValue(configuration, "Race Strategist Shutdown", simulator . ".SaveRaceReport", "Never")
			simulatorConfiguration["SaveTelemetry"] := getConfigurationValue(configuration, "Race Strategist Shutdown", simulator . ".SaveTelemetry", "Always")
			simulatorConfiguration["RaceReview"] := getConfigurationValue(configuration, "Race Strategist Shutdown", simulator . ".RaceReview", "Yes")

			this.iSimulatorConfigurations[simulator] := simulatorConfiguration
		}
	}

	saveToConfiguration(configuration) {
		local simulator, simulatorConfiguration, ignore, key

		base.saveToConfiguration(configuration)

		this.saveSimulatorConfiguration()

		GuiControlGet raceReportsPathEdit

		setConfigurationValue(configuration, "Race Strategist Reports", "Database", (raceReportsPathEdit != "") ? raceReportsPathEdit : false)

		for simulator, simulatorConfiguration in this.iSimulatorConfigurations {
			for ignore, key in ["LearningLaps", "ConsideredHistoryLaps", "HistoryLapsDamping"]
				setConfigurationValue(configuration, "Race Strategist Analysis", simulator . "." . key, simulatorConfiguration[key])

			setConfigurationValue(configuration, "Race Strategist Shutdown", simulator . ".SaveRaceReport", simulatorConfiguration["SaveRaceReport"])
			setConfigurationValue(configuration, "Race Strategist Shutdown", simulator . ".SaveTelemetry", simulatorConfiguration["SaveTelemetry"])
			setConfigurationValue(configuration, "Race Strategist Shutdown", simulator . ".RaceReview", simulatorConfiguration["RaceReview"])
		}
	}

	loadConfigurator(configuration, simulators) {
		this.loadFromConfiguration(configuration)

		GuiControl Text, raceReportsPathEdit, %raceReportsPathEdit%

		this.setSimulators(simulators)
	}

	loadSimulatorConfiguration(simulator := false) {
		local window := this.Editor.Window
		local configuration

		Gui %window%:Default

		if simulator {
			rsSimulatorDropDown := simulator

			GuiControl Choose, rsSimulatorDropDown, % inList(this.iSimulators, simulator)
		}
		else
			GuiControlGet rsSimulatorDropDown

		this.iCurrentSimulator := rsSimulatorDropDown

		if this.iSimulatorConfigurations.HasKey(rsSimulatorDropDown) {
			configuration := this.iSimulatorConfigurations[rsSimulatorDropDown]

			GuiControl Choose, rsSaveRaceReportDropDown, % inList(["Ask", "Always", "Never"], configuration["SaveRaceReport"])
			GuiControl Choose, rsSaveTelemetryDropDown, % inList(["Ask", "Always", "Never"], configuration["SaveTelemetry"])
			GuiControl Choose, rsRaceReviewDropDown, % inList(["No", "Yes"], configuration["RaceReview"])
			GuiControl Text, rsLearningLapsEdit, % configuration["LearningLaps"]
			GuiControl Text, rsLapsConsideredEdit, % configuration["ConsideredHistoryLaps"]

			rsDampingFactorEdit := displayValue("Float", configuration["HistoryLapsDamping"])
			GuiControl Text, rsDampingFactorEdit, %rsDampingFactorEdit%
		}
	}

	saveSimulatorConfiguration() {
		local window := this.Editor.Window
		local configuration

		Gui %window%:Default

		if this.iCurrentSimulator {
			GuiControlGet rsLearningLapsEdit
			GuiControlGet rsLapsConsideredEdit
			GuiControlGet rsDampingFactorEdit
			GuiControlGet rsSaveRaceReportDropDown
			GuiControlGet rsSaveTelemetryDropDown
			GuiControlGet rsRaceReviewDropDown

			configuration := this.iSimulatorConfigurations[this.iCurrentSimulator]

			configuration["LearningLaps"] := rsLearningLapsEdit
			configuration["ConsideredHistoryLaps"] := rsLapsConsideredEdit
			configuration["HistoryLapsDamping"] := internalValue("Float", rsDampingFactorEdit)
			configuration["SaveRaceReport"] := ["Ask", "Always", "Never"][rsSaveRaceReportDropDown]
			configuration["SaveTelemetry"] := ["Ask", "Always", "Never"][rsSaveTelemetryDropDown]
			configuration["RaceReview"] := ["No", "Yes"][rsRaceReviewDropDown]
		}
	}

	setSimulators(simulators) {
		local window := this.Editor.Window

		Gui %window%:Default

		this.iSimulators := simulators

		GuiControl, , rsSimulatorDropDown, % "|" . values2String("|", simulators*)

		if (simulators.Length() > 0) {
			this.loadFromConfiguration(this.Configuration)

			this.loadSimulatorConfiguration(simulators[1])
		}
	}

	getSimulators() {
		return this.Editor.getSimulators()
	}

	replicateSettings() {
		local configuration, simulator, simulatorConfiguration

		this.saveSimulatorConfiguration()

		configuration := this.iSimulatorConfigurations[this.iCurrentSimulator]

		for simulator, simulatorConfiguration in this.iSimulatorConfigurations
			if (simulator != this.iCurrentSimulator)
				for ignore, key in ["LearningLaps", "ConsideredHistoryLaps", "HistoryLapsDamping", "SaveRaceReport", "SaveTelemetry", "RaceReview"]
					simulatorConfiguration[key] := configuration[key]
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

replicateRSSettings() {
	RaceStrategistConfigurator.Instance.replicateSettings()
}

validateRSDampingFactor() {
	local oldValue := rsDampingFactorEdit
	local value

	GuiControlGet rsDampingFactorEdit

	value := internalValue("Float", rsDampingFactorEdit)

	if value is not Number
	{
		rsDampingFactorEdit := oldValue

		GuiControl, , rsDampingFactorEdit, %rsDampingFactorEdit%
	}
}

chooseRaceReportsPath() {
	local directory

	GuiControlGet raceReportsPathEdit

	OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Select", "Select", "Cancel"]))
	FileSelectFolder directory, *%raceReportsPathEdit%, 0, % translate("Select Race Reports Folder...")
	OnMessage(0x44, "")

	if (directory != "")
		GuiControl Text, raceReportsPathEdit, %directory%
}

chooseRaceStrategistSimulator() {
	local configurator := RaceStrategistConfigurator.Instance

	configurator.saveSimulatorConfiguration()
	configurator.loadSimulatorConfiguration()
}

initializeRaceStrategistConfigurator() {
	local editor

	if kConfigurationEditor {
		editor := ConfigurationEditor.Instance

		editor.registerConfigurator(translate("Race Strategist"), new RaceStrategistConfigurator(editor, editor.Configuration))
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeRaceStrategistConfigurator()