﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Practice Center Tool            ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                       Global Declaration Section                        ;;;
;;;-------------------------------------------------------------------------;;;

;@SC-IF %configuration% == Development
#Include "..\Framework\Development.ahk"
;@SC-EndIF

;@SC-If %configuration% == Production
;@SC #Include "..\Framework\Production.ahk"
;@SC-EndIf

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Practice.ico
;@Ahk2Exe-ExeName Practice Center.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Framework\Application.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Libraries\HTMLViewer.ahk"
#Include "..\Libraries\Messages.ahk"
#Include "..\Libraries\Math.ahk"
#Include "..\Database\Libraries\SessionDatabase.ahk"
#Include "..\Database\Libraries\SettingsDatabase.ahk"
#Include "..\Database\Libraries\TyresDatabase.ahk"
#Include "..\Database\Libraries\TelemetryDatabase.ahk"
#Include "Libraries\RaceReportViewer.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                   Private Constant Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global kClose := "Close"
global kSave := "Save"
global kEvent := "Event"

global kSessionReports := concatenate(kRaceReports, ["Pressures", "Brakes", "Temperatures", "Free"])
global kDetailReports := ["Run", "Lap", "Session", "Drivers"]

global kSessionDataSchemas := CaseInsenseMap("Run.Data", ["Nr", "Lap", "Driver.Forname", "Driver.Surname", "Driver.Nickname", "Driver.ID"
													    , "Weather", "Tyre.Compound", "Tyre.Compound.Color", "Tyre.Set", "Tyre.Laps"
														, "Lap.Time.Average", "Lap.Time.Best"
														, "Fuel.Amount", "Fuel.Consumption", "Accidents"
													    , "Time.Start", "Time.End"]
										   , "Driver.Data", ["Forname", "Surname", "Nickname", "ID"]
										   , "Lap.Data", ["Run", "Nr", "Lap", "Lap.Time", "Grip", "Map", "TC", "ABS"
														, "Weather", "Temperature.Air", "Temperature.Track"
														, "Fuel.Remaining", "Fuel.Consumption", "Damage", "EngineDamage", "Accident"
														, "Tyre.Laps", "Tyre.Compound", "Tyre.Compound.Color"
														, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
														, "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right"
														, "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
														, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
														, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right"
														, "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
														, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right"
														, "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
														, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
														, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right"
														, "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"
														, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
														, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right"
														, "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"
														, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right"
														, "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
														, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
														, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right"
														, "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"
														, "Brake.Temperature.Average"
														, "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
														, "Data.Telemetry", "Data.Pressures"])

global kPCTyresSchemas := kTyresSchemas.Clone()

kPCTyresSchemas["Tyres.Pressures"] := concatenate(kPCTyresSchemas["Tyres.Pressures"].Clone()
												, ["Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right"
												 , "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"])


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                        PracticeCenterTask                         ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class PracticeCenterTask extends Task {
	Window {
		Get {
			return PracticeCenter.Instance.Window
		}
	}

	run() {
		local pCenter := PracticeCenter.Instance

		if pCenter.startWorking() {
			try {
				super.run()

				return false
			}
			finally {
				pCenter.finishWorking()
			}
		}
		else
			return this
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; Class                          PracticeCenter                           ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class PracticeCenter extends ConfigurationItem {
	iWindow := false

	iWorking := 0
	iSyncTask := false

	iSessionDirectory := false

	iSessionMode := false

	iDate := A_Now
	iTime := A_Now

	iSimulator := false
	iCar := false
	iTrack := false
	iWeather := false
	iWeather10Min := false
	iWeather30Min := false
	iAirTemperature := false
	iTrackTemperature := false

	iTyreCompounds := [normalizeCompound("Dry")]

	iTyreCompound := false
	iTyreCompoundColor := false

	iUseSessionData := true
	iUseTelemetryDatabase := false

	iDrivers := []
	iRuns := CaseInsenseWeakMap()
	iLaps := CaseInsenseWeakMap()

	iCurrentRun := false
	iLastLap := false

	iRunsListView := false
	iLapsListView := false

	iSessionStore := false
	iTelemetryDatabase := false
	iPressuresDatabase := false

	iReportsListView := false
	iChartViewer := false
	iReportViewer := false
	iDetailsViewer := false
	iSelectedReport := false
	iSelectedChartType := false

	iSelectedRun := false

	iSelectedDetailReport := false
	iSelectedDetailHTML := false

	iTasks := []

	class PracticeCenterResizer extends Window.Resizer {
		iRedraw := false

		__New(arguments*) {
			super.__New(arguments*)

			Task.startTask(ObjBindMethod(this, "RedrawHTMLViwer"), 500, kLowPriority)
		}

		Resize(deltaWidth, deltaHeight) {
			this.iRedraw := true
		}

		RedrawHTMLViwer() {
			if this.iRedraw {
				local center := PracticeCenter.Instance
				local ignore, button

				for ignore, button in ["LButton", "MButton", "RButton"]
					if GetKeyState(button, "P")
						return Task.CurrentTask

				this.iRedraw := false

				center.ChartViewer.Resized()
				center.DetailsViewer.Resized()

				center.pushTask(ObjBindMethod(PracticeCenter.Instance, "updateReports", true))
			}

			return Task.CurrentTask
		}
	}

	class SessionTelemetryDatabase extends TelemetryDatabase {
		iPracticeCenter := false
		iTelemetryDatabase := false

		PracticeCenter {
			Get {
				return this.iPracticeCenter
			}
		}

		TelemetryDatabase {
			Get {
				return this.iTelemetryDatabase
			}
		}

		__New(practiceCenter, simulator := false, car := false, track := false) {
			this.iPracticeCenter := practiceCenter

			super.__New()

			this.Shared := false

			this.setDatabase(Database(practiceCenter.SessionDirectory, kTelemetrySchemas))

			if simulator
				this.iTelemetryDatabase := TelemetryDatabase(simulator, car, track)
		}

		setDrivers(drivers) {
			super.setDrivers(drivers)

			if this.TelemetryDatabase
				this.TelemetryDatabase.setDrivers(drivers)
		}

		getMapData(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, ignore, entry, found, candidate, lastLap, result

			if this.PracticeCenter.UseSessionData
				for ignore, entry in super.getMapData(weather, tyreCompound, tyreCompoundColor)
					if ((entry["Fuel.Consumption"] > 0) && (entry["Lap.Time"] > 0))
						entries.Push(entry)

			if (this.PracticeCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getMapData(weather, tyreCompound, tyreCompoundColor) {
					if ((entry["Fuel.Consumption"] > 0) && (entry["Lap.Time"] > 0)) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Map"] = entry["Map"]) && (candidate["Lap.Time"] = entry["Lap.Time"])
																  && (candidate["Fuel.Consumption"] = entry["Fuel.Consumption"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			return entries
		}

		getTyreData(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, found, candidate

			if this.PracticeCenter.UseSessionData
				for ignore, entry in super.getTyreData(weather, tyreCompound, tyreCompoundColor)
					if (entry["Lap.Time"] > 0)
						entries.Push(entry)

			if (this.PracticeCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getTyreData(weather, tyreCompound, tyreCompoundColor) {
					if (entry["Lap.Time"] > 0) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Tyre.Laps"] = entry["Tyre.Laps"]) && (candidate["Lap.Time"] = entry["Lap.Time"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			return entries
		}

		getMapLapTimes(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, found, candidate, lastLap, result

			if this.PracticeCenter.UseSessionData
				for ignore, entry in super.getMapLapTimes(weather, tyreCompound, tyreCompoundColor)
					if (entry["Lap.Time"] > 0)
						entries.Push(entry)

			if (this.PracticeCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getMapLapTimes(weather, tyreCompound, tyreCompoundColor) {
					if (entry["Lap.Time"] > 0) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Map"] = entry["Map"]) && (candidate["Fuel.Remaining"] = entry["Fuel.Remaining"])
																  && (candidate["Lap.Time"] = entry["Lap.Time"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			return entries
		}

		getTyreLapTimes(weather, tyreCompound, tyreCompoundColor) {
			local entries := []
			local newEntries, ignore, entry, found, candidate

			if this.PracticeCenter.UseSessionData
				for ignore, entry in super.getTyreLapTimes(weather, tyreCompound, tyreCompoundColor)
					if (entry["Lap.Time"] > 0)
						entries.Push(entry)

			if (this.PracticeCenter.UseTelemetryDatabase && this.TelemetryDatabase) {
				newEntries := []

				for ignore, entry in this.TelemetryDatabase.getTyreLapTimes(weather, tyreCompound, tyreCompoundColor) {
					if (entry["Lap.Time"] > 0) {
						found := false

						for ignore, candidate in entries
							if ((candidate["Tyre.Laps"] = entry["Tyre.Laps"]) && (candidate["Lap.Time"] = entry["Lap.Time"])) {
								found := true

								break
							}

						if !found
							newEntries.Push(entry)
					}
				}

				for ignore, entry in newEntries
					entries.Push(entry)
			}

			return entries
		}
	}

	class SessionPressuresDatabase {
		iDatabase := false

		Database {
			Get {
				return this.iDatabase
			}
		}

		__New(pCenter) {
			this.iDatabase := Database(pCenter.SessionDirectory, kPCTyresSchemas)
		}

		updatePressures(weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor, coldPressures, hotPressures, pressuresLosses, driver) {
			local tyres, types, typeIndex, tPressures, tyreIndex, pressure

			if (!tyreCompoundColor || (tyreCompoundColor = ""))
				tyreCompoundColor := "Black"

			this.Database.add("Tyres.Pressures",
							  Database.Row("Weather", weather, "Temperature.Air", airTemperature, "Temperature.Track", trackTemperature
										 , "Compound", tyreCompound, "Compound.Color", tyreCompoundColor, "Driver", driver
										 , "Tyre.Pressure.Cold.Front.Left", null(coldPressures[1])
										 , "Tyre.Pressure.Cold.Front.Right", null(coldPressures[2])
										 , "Tyre.Pressure.Cold.Rear.Left", null(coldPressures[3])
										 , "Tyre.Pressure.Cold.Rear.Right", null(coldPressures[4])
										 , "Tyre.Pressure.Hot.Front.Left", null(hotPressures[1])
										 , "Tyre.Pressure.Hot.Front.Right", null(hotPressures[2])
										 , "Tyre.Pressure.Hot.Rear.Left", null(hotPressures[3])
										 , "Tyre.Pressure.Hot.Rear.Right", null(hotPressures[4])
										 , "Tyre.Pressure.Loss.Front.Left", null(pressuresLosses[1])
										 , "Tyre.Pressure.Loss.Front.Right", null(pressuresLosses[2])
										 , "Tyre.Pressure.Loss.Rear.Left", null(pressuresLosses[3])
										 , "Tyre.Pressure.Loss.Rear.Right", null(pressuresLosses[4]))
							, true)

			tyres := ["FL", "FR", "RL", "RR"]
			types := ["Cold", "Hot"]

			for typeIndex, tPressures in [coldPressures, hotPressures]
				for tyreIndex, pressure in tPressures
					this.updatePressure(weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
									  , types[typeIndex], tyres[tyreIndex], pressure, 1, driver, true)
		}

		updatePressure(weather, airTemperature, trackTemperature, tyreCompound, tyreCompoundColor
					 , type, tyre, pressure, count, driver, flush) {
			local rows

			if (isNull(null(pressure)))
				return

			if (!tyreCompoundColor || (tyreCompoundColor = ""))
				tyreCompoundColor := "Black"

			rows := this.Database.query("Tyres.Pressures.Distribution"
									  , {Where: CaseInsenseMap("Weather", weather, "Temperature.Air", airTemperature, "Temperature.Track", trackTemperature
															 , "Driver", driver, "Compound", tyreCompound, "Compound.Color", tyreCompoundColor
															 , "Type", type, "Tyre", tyre, "Pressure", pressure)})

			if (rows.Length > 0)
				rows[1]["Count"] := rows[1]["Count"] + count
			else
				this.Database.add("Tyres.Pressures.Distribution"
								, Database.Row("Weather", weather, "Temperature.Air", airTemperature, "Temperature.Track", trackTemperature
											 , "Driver", driver, "Compound", tyreCompound, "Compound.Color", tyreCompoundColor
											 , "Type", type, "Tyre", tyre, "Pressure", pressure, "Count", count)
								, flush)
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

	SessionDirectory {
		Get {
			return this.iSessionDirectory
		}
	}

	SessionMode {
		Get {
			return this.iSessionMode
		}
	}

	SessionLoaded {
		Get {
			return ((this.SessionMode = "Loaded") ? this.iSessionLoaded : false)
		}
	}

	HasData {
		Get {
			return (this.SessionMode && this.CurrentRun && this.LastLap)
		}
	}

	Date {
		Get {
			return this.iDate
		}
	}

	Time {
		Get {
			return this.iTime
		}
	}

	Simulator {
		Get {
			return this.iSimulator
		}
	}

	SelectedSimulator {
		Get {
			return this.Simulator
		}
	}

	Car {
		Get {
			return this.iCar
		}
	}

	SelectedCar {
		Get {
			return this.Car
		}
	}

	Track {
		Get {
			return this.iTrack
		}
	}

	SelectedTrack {
		Get {
			return this.Track
		}
	}

	Weather {
		Get {
			return this.iWeather
		}
	}

	Weather10Min {
		Get {
			return this.iWeather10Min
		}
	}

	Weather30Min {
		Get {
			return this.iWeather30Min
		}
	}

	AirTemperature {
		Get {
			return this.iAirTemperature
		}
	}

	TrackTemperature {
		Get {
			return this.iTrackTemperature
		}
	}

	TyreCompounds[key?] {
		Get {
			return (isSet(key) ? this.iTyreCompounds[key] : this.iTyreCompounds)
		}
	}

	TyreCompound {
		Get {
			return this.iTyreCompound
		}
	}

	TyreCompoundColor {
		Get {
			return this.iTyreCompoundColor
		}
	}

	UseSessionData {
		Get {
			return this.iUseSessionData
		}
	}

	UseTelemetryDatabase {
		Get {
			return this.iUseTelemetryDatabase
		}
	}

	Drivers {
		Get {
			return this.iDrivers
		}
	}

	Runs[key?] {
		Get {
			return (isSet(key) ? this.iRuns[key] : this.iRuns)
		}

		Set {
			return (isSet(key) ? (this.iRuns[key] := value) : (this.iRuns := value))
		}
	}

	CurrentRun[asNr := false] {
		Get {
			if this.iCurrentRun
				return (asNr ? this.iCurrentRun.Nr : this.iCurrentRun)
			else
				return false
		}
	}

	Laps[key?] {
		Get {
			return (isSet(key) ? this.iLaps[key] : this.iLaps)
		}

		Set {
			return (isSet(key) ? (this.iLaps[key] := value) : (this.iLaps := value))
		}
	}

	LastLap[asNr := false] {
		Get {
			if this.iLastLap
				return (asNr ? this.iLastLap.Nr : this.iLastLap)
			else
				return false
		}
	}

	RunsListView {
		Get {
			return this.iRunsListView
		}
	}

	LapsListView {
		Get {
			return this.iLapsListView
		}
	}

	SessionStore {
		Get {
			if !this.iSessionStore
				this.iSessionStore := Database(this.SessionDirectory, kSessionDataSchemas)

			return this.iSessionStore
		}
	}

	TelemetryDatabase {
		Get {
			if !this.iTelemetryDatabase
				this.iTelemetryDatabase := PracticeCenter.SessionTelemetryDatabase(this)

			return this.iTelemetryDatabase
		}
	}

	PressuresDatabase {
		Get {
			if !this.iPressuresDatabase
				this.iPressuresDatabase := PracticeCenter.SessionPressuresDatabase(this)

			return this.iPressuresDatabase
		}
	}

	ReportsListView {
		Get {
			return this.iReportsListView
		}
	}

	ChartViewer {
		Get {
			return this.iChartViewer
		}
	}

	ReportViewer {
		Get {
			return this.iReportViewer
		}
	}

	DetailsViewer {
		Get {
			return this.iDetailsViewer
		}
	}

	SelectedRun {
		Get {
			return this.iSelectedRun
		}
	}

	SelectedReport {
		Get {
			return this.iSelectedReport
		}
	}

	SelectedChartType {
		Get {
			return this.iSelectedChartType
		}
	}

	SelectedDetailReport {
		Get {
			return this.iSelectedDetailReport
		}
	}

	__New(configuration, raceSettings, simulator := false, car := false, track := false) {
		this.iSimulator := simulator
		this.iCar := car
		this.iTrack := track

		this.iSessionDirectory := (kTempDirectory . "Sessions\Practice\")

		super.__New(configuration)

		PracticeCenter.Instance := this
	}

	createGui(configuration) {
		local center := this
		local centerGui, centerTab, x, y, width, ignore, report, choices, serverURLs, settings, button, control
		local simulator, car, track

		validateNumber(field, *) {
			field := centerGui[field]

			if !isNumber(internalValue("Float", field.Text)) {
				field.Text := (field.HasProp("ValidText") ? field.ValidText : "")

				loop 10
					SendInput("{Right}")
			}
			else
				field.ValidText := field.Text
		}

		closePracticeCenter(*) {
			ExitApp(0)
		}

		chooseSimulator(*) {
			this.loadSimulator(centerGui["simulatorDropDown"].Text)
		}

		chooseCar(*) {
			this.loadCar(this.getAvailableCars(this.SelectedSimulator)[centerGui["carDropDown"].Value])
		}

		chooseTrack(*) {
			local simulator := this.SelectedSimulator
			local tracks := this.getAvailableTracks(simulator, this.SelectedCar)
			local trackNames := collect(tracks, ObjBindMethod(SessionDatabase, "getTrackName", simulator))

			this.loadTrack(tracks[inList(trackNames, centerGui["trackDropDown"].Text)])
		}

		chooseReport(listView, line, *) {
			if center.HasData {
				if center.isWorking()
					return

				if line
					center.showReport(kSessionReports[line])
			}
			else
				loop listView.GetCount()
					listView.Modify(A_Index, "-Select")
		}

		reportSettings(*) {
			center.withExceptionhandler(ObjBindMethod(center, "reportSettings", center.SelectedReport))
		}

		chooseRunData(*) {
			center.withExceptionHandler(ObjBindMethod(center, "selectRun"
									  , (centerGui["runDropDown"].Value = 1) ? false : center.Runs[centerGui["runDropDown"].Value - 1]))
		}

		chooseAxis(*) {
			center.withExceptionhandler(ObjBindMethod(center, "showTelemetryReport"))
		}

		chooseChartType(*) {
			center.selectChartType(["Scatter", "Bar", "Bubble", "Line"][centerGui["chartTypeDropDown"].Value])
		}

		sessionMenu(*) {
			center.withExceptionhandler(ObjBindMethod(center, "chooseSessionMenu", centerGui["sessionMenuDropDown"].Value))
		}

		runMenu(*) {
			center.withExceptionhandler(ObjBindMethod(center, "chooseRunMenu", centerGui["runMenuDropDown"].Value))
		}

		chooseRun(listView, line, *) {
			if line
				center.withExceptionhandler(ObjBindMethod(center, "showRunDetails", center.Runs[listView.GetText(line, 1)]))
		}

		chooseLap(listView, line, *) {
			if line
				center.withExceptionhandler(ObjBindMethod(center, "showLapDetails", center.Laps[listView.GetText(line, 1)]))
		}

		updateState(*) {
			center.withExceptionhandler(ObjBindMethod(center, "updateState"))
		}

		centerGui := Window({Descriptor: "Practice Center", Closeable: true, Resizeable: "Deferred"})

		this.iWindow := centerGui

		centerGui.SetFont("s10 Bold", "Arial")

		centerGui.Add("Text", "w1334 H:Center Center", translate("Modular Simulator Controller System")).OnEvent("Click", moveByMouse.Bind(centerGui, "Practice Center"))

		centerGui.SetFont("s9 Norm", "Arial")

		centerGui.Add("Documentation", "x608 YP+20 w134 H:Center Center", translate("Practice Center")
					, "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Virtual-Race-Strategist#practice-center")

		centerGui.Add("Text", "x8 yp+30 w1350 W:Grow 0x10")

		centerGui.SetFont("Norm")
		centerGui.SetFont("s10 Bold", "Arial")

		centerGui.Add("Picture", "x16 yp+12 w30 h30 Section", kIconsDirectory . "Report.ico")
		centerGui.Add("Text", "x50 yp+5 w80 h26", translate("Reports"))

		centerGui.SetFont("s8 Norm", "Arial")

		x := 16
		y := 70
		width := 388

		centerGui.SetFont("s8 Norm", "Arial")

		centerGui.Add("Text", "x16 yp+32 w70 h23 +0x200", translate("Simulator"))

		simulators := this.getAvailableSimulators()
		simulator := 0

		if (simulators.Length > 0) {
			if this.SelectedSimulator
				simulator := inList(simulators, this.SelectedSimulator)

			if (simulator == 0)
				simulator := 1
		}

		centerGui.Add("DropDownList", "x90 yp w296 Choose" . simulator . " vsimulatorDropDown", simulators).OnEvent("Change", chooseSimulator)

		if (simulator > 0)
			simulator := simulators[simulator]
		else
			simulator := false

		centerGui.Add("Text", "x16 yp+24 w70 h23 +0x200", translate("Car"))
		centerGui.Add("DropDownList", "x90 yp w296 vcarDropDown").OnEvent("Change", chooseCar)

		centerGui.Add("Text", "x16 yp24 w70 h23 +0x200", translate("Track"))
		centerGui.Add("DropDownList", "x90 yp w296 vtrackDropDown").OnEvent("Change", chooseTrack)

		centerGui.Add("Text", "x24 yp+31 w356 0x10")

		this.iReportsListView := centerGui.Add("ListView", "x16 yp+10 w115 h230 H:Grow(0.2) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", [translate("Report")])
		this.iReportsListView.OnEvent("Click", chooseReport)

		for ignore, report in kSessionReports
			if (report = "Drivers")
				this.iReportsListView.Add("", translate("Driver (Start)"))
			else
				this.iReportsListView.Add("", translate(report))

		this.iReportsListView.ModifyCol(1, "AutoHdr")

		centerGui.Add("Text", "x141 yp+2 w70 h23 +0x200", translate("Run"))
		centerGui.Add("DropDownList", "x195 yp w191 vrunDropDown").OnEvent("Change", chooseRunData)

		centerGui.Add("Text", "x141 yp+24 w70 h23 +0x200", translate("X-Axis"))

		centerGui.Add("DropDownList", "x195 yp w191 vdataXDropDown").OnEvent("Change", chooseAxis)

		centerGui.Add("Text", "x141 yp+24 w70 h23 +0x200", translate("Series"))

		centerGui.Add("DropDownList", "x195 yp w191 vdataY1DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY2DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY3DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY4DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY5DropDown").OnEvent("Change", chooseAxis)
		centerGui.Add("DropDownList", "x195 yp+24 w191 vdataY6DropDown").OnEvent("Change", chooseAxis)

		centerGui.Add("Text", "x400 ys w40 h23 +0x200", translate("Plot"))
		centerGui.Add("DropDownList", "x444 yp w80 Choose1 vchartTypeDropDown", collect(["Scatter", "Bar", "Bubble", "Line"], translate)).OnEvent("Change", chooseChartType)

		centerGui.Add("Button", "x1327 yp w23 h23 X:Move vreportSettingsButton").OnEvent("Click", reportSettings)
		setButtonIcon(centerGui["reportSettingsButton"], kIconsDirectory . "General Settings.ico", 1)

		this.iChartViewer := centerGui.Add("HTMLViewer", "x400 yp+24 w950 h343 W:Grow H:Grow(0.2) Border vchartViewer")

		centerGui.Rules := "Y:Move(0.2)"

		centerGui.Add("Text", "x8 yp+351 w1350 W:Grow 0x10")

		centerGui.SetFont("Norm")
		centerGui.SetFont("s10 Bold", "Arial")

		centerGui.Add("Picture", "x16 yp+10 w30 h30 Section", kIconsDirectory . "Watch.ico")
		centerGui.Add("Text", "x50 yp+5 w80 h26", translate("Session"))

		centerGui.SetFont("s8 Norm", "Arial")

		centerGui.Add("DropDownList", "x195 yp-2 w180 Choose1 +0x200 vsessionMenuDropDown").OnEvent("Change", sessionMenu)
		centerGui.Add("DropDownList", "x380 yp w180 Choose1 +0x200 vrunMenuDropDown").OnEvent("Change", runMenu)

		centerGui.SetFont("s8 Norm", "Arial")

		centerGui.SetFont("Norm", "Arial")
		centerGui.SetFont("Italic", "Arial")

		centerGui.Add("Text", "x619 ys+39 w80 h21", translate("Output"))
		centerGui.Add("Text", "x700 yp+7 w651 0x10 W:Grow")

		this.iDetailsViewer := centerGui.Add("HTMLViewer", "x619 yp+14 w732 h293 W:Grow H:Grow(0.8) Border vdetailsViewer")

		centerGui.SetFont("Norm", "Arial")

		centerTab := centerGui.Add("Tab3", "x16 ys+39 w593 h316 H:Grow(0.8) AltSubmit -Wrap Section vpracticeCenterTabView", collect(["Runs", "Laps"], translate))

		centerTab.UseTab(1)

		this.iRunsListView := centerGui.Add("ListView", "x24 ys+33 w577 h270 H:Grow(0.8) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", collect(["#", "Lap", "Driver", "Weather", "Compound", "Laps", "Fuel Level", "Consumption", "Avg. Lap Time", "Accidents", "Potential", "Race Craft", "Speed", "Consistency", "Car Control"], translate))
		this.iRunsListView.OnEvent("Click", chooseRun)

		centerTab.UseTab(2)

		this.iLapsListView := centerGui.Add("ListView", "x24 ys+33 w577 h270 H:Grow(0.8) -Multi -LV0x10 AltSubmit NoSort NoSortHdr", collect(["#", "Run", "Weather", "Grip", "Lap Time", "Consumption", "Remaining", "Pressures", "Accident"], translate))
		this.iLapsListView.OnEvent("Click", chooseLap)

		centerGui.Rules := ""

		this.iReportViewer := RaceReportViewer(centerGui, this.ChartViewer)

		centerGui.Add(PracticeCenter.PracticeCenterResizer(centerGui))

		car := this.SelectedCar
		track := this.SelectedTrack

		this.loadSimulator(simulator, true)

		if car
			this.loadCar(car)

		if track
			this.loadTrack(track)
	}

	show() {
		local window := this.Window
		local x, y, w, h

		if getWindowPosition("Practice Center", &x, &y)
			window.Show("AutoSize x" . x . " y" . y)
		else
			window.Show("AutoSize")

		if getWindowSize("Practice Center", &w, &h)
			window.Resize("Initialize", w, h)

		this.startWorking(false)

		this.showDetails(false, false)
		this.showChart(false)

		this.initializeSession()

		this.updateState()
	}

	getAvailableSimulators() {
		return SessionDatabase().getSimulators()
	}

	getAvailableCars(simulator) {
		return SessionDatabase().getCars(simulator)
	}

	getAvailableTracks(simulator, car) {
		return SessionDatabase().getTracks(simulator, car)
	}

	loadSimulator(simulator, force := false) {
		local drivers, ignore, id, index, car, carNames, cars, settings

		if (force || (simulator != this.SelectedSimulator)) {
			this.iSimulator := simulator

			settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

			setMultiMapValue(settings, "Practice Center", "Simulator", simulator)

			writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)

			cars := this.getAvailableCars(simulator)
			carNames := cars.Clone()

			for index, car in cars
				carNames[index] := SessionDatabase.getCarName(simulator, car)

			this.Control["simulatorDropDown"].Choose(inList(this.getAvailableSimulators(), simulator))

			this.Control["carDropDown"].Delete()
			this.Control["carDropDown"].Add(carNames)

			this.loadCar((cars.Length > 0) ? cars[1] : false, true)
		}
	}

	loadCar(car, force := false) {
		local tracks, settings

		if (force || (car != this.SelectedCar)) {
			this.iCar := car

			settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

			setMultiMapValue(settings, "Practice Center", "Car", car)

			writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)

			tracks := this.getAvailableTracks(this.SelectedSimulator, car)

			this.Control["carDropDown"].Choose(inList(this.getAvailableCars(this.SelectedSimulator), car))
			this.Control["trackDropDown"].Delete()
			this.Control["trackDropDown"].Add(collect(tracks, ObjBindMethod(SessionDatabase, "getTrackName", this.SelectedSimulator)))

			this.loadTrack((tracks.Length > 0) ? tracks[1] : false, true)
		}
	}

	loadTrack(track, force := false) {
		local simulator, car, settings

		if (force || (track != this.SelectedTrack)) {
			simulator := this.SelectedSimulator
			car := this.SelectedCar

			this.iTrack := track

			settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

			setMultiMapValue(settings, "Practice Center", "Track", track)

			writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)

			this.Control["trackDropDown"].Choose(inList(this.getAvailableTracks(simulator, car), track))
		}
	}

	selectRun(run, force := false) {
		if (force || (run != this.SelectedRun)) {
			this.Control["runDropDown"].Choose(run + 1)

			this.iSelectedRun := run

			this.updateReports()
		}
	}

	createDriver(driver) {
		local ignore, candidate, found

		if !driver.HasProp("Nr")
			driver.Nr := false

		if !driver.HasProp("ID")
			driver.ID := false

		for ignore, candidate in this.Drivers {
			found := false

			if ((candidate.Forname = driver.Forname) && (candidate.Surname = driver.Surname))
				found := candidate

			if found {
				if driver.ID {
					found.ID := driver.ID

					if !inList(this.iDrivers, driver.ID)
						this.iDrivers.Push(driver.ID)

					if this.Simulator
						SessionDatabase.registerDriver(this.Simulator, driver.ID, found.FullName)
				}

				return found
			}
		}

		driver.FullName := computeDriverName(driver.Forname, driver.Surname, driver.Nickname)
		driver.Laps := []
		driver.Runs := []
		driver.Accidents := 0
		driver.Penalties := 0

		if driver.ID {
			if !inList(this.iDrivers, driver.ID)
				this.iDrivers.Push(driver.ID)

			if this.Simulator
				SessionDatabase.registerDriver(this.Simulator, driver.ID, driver.FullName)
		}

		this.Drivers.Push(driver)

		return driver
	}

	getClasses(data) {
		local classes := CaseInsenseMap()
		local class

		loop getMultiMapValue(data, "Position Data", "Car.Count") {
			class := this.getClass(data, A_Index)

			if !classes.Has(class)
				classes[class] := true
		}

		return getKeys(classes)
	}

	getClass(data, car := false) {
		local categories := (this.ReportViewer.Settings.Has("CarCategories") ? this.ReportViewer.Settings["CarCategories"] : ["Class"])
		local carClass, carCategory

		if !car
			car := getMultiMapValue(data, "Position Data", "Driver.Car")

		if inList(categories, "Class") {
			carClass := getMultiMapValue(data, "Position Data", "Car." . car . ".Class", kUnknown)

			if inList(categories, "Cup") {
				carCategory := getMultiMapValue(data, "Position Data", "Car." . car . ".Category", kUndefined)

				return ((carCategory != kUndefined) ? (carClass . translate(" (") . carCategory . translate(")")) : carClass)
			}
			else
				return carClass
		}
		else
			return getMultiMapValue(data, "Position Data", "Car." . car . ".Category", kUnknown)
	}

	getCars(data, class := "Overall", sorted := false) {
		local classGrid := []
		local positions, ignore, position

		compareClassPositions(c1, c2) {
			local pos1 := c1[2]
			local pos2 := c2[2]

			if !isNumber(pos1)
				pos1 := 999

			if !isNumber(pos2)
				pos2 := 999

			return (pos1 > pos2)
		}

		if (class = "Class")
			class := this.getClass(data)
		else if (class = "Overall")
			class := false

		if sorted {
			positions := []

			loop getMultiMapValue(data, "Position Data", "Car.Count")
				if (!class || (class = this.getClass(data, A_Index)))
					positions.Push(Array(A_Index, getMultiMapValue(data, "Position Data", "Car." . A_Index . ".Position")))

			bubbleSort(&positions, compareClassPositions)

			for ignore, position in positions
				classGrid.Push(position[1])
		}
		else
			loop getMultiMapValue(data, "Position Data", "Car.Count")
				if (!class || (class = this.getClass(data, A_Index)))
					classGrid.Push(A_Index)

		return classGrid
	}

	getPosition(data, type := "Overall", car := false) {
		local position, candidate

		if !car
			if (type = "Overall")
				return getMultiMapValue(data, "Position Data", "Car." . getMultiMapValue(data, "Position Data", "Driver.Car") . ".Position", false)
			else
				car := getMultiMapValue(data, "Position Data", "Driver.Car")

		if (type != "Overall")
			for position, candidate in this.getCars(data, this.getClass(data, car), true)
				if (candidate = car)
					return position

		return getMultiMapValue(data, "Position Data", "Car." . car . ".Position", false)
	}

	updateState() {
		local window := this.Window

		window["simulatorDropDown"].Enabled := false
		window["carDropDown"].Enabled := false
		window["trackDropDown"].Enabled := false

		window["runDropDown"].Enabled := false

		window["dataXDropDown"].Enabled := false
		window["dataY1DropDown"].Enabled := false
		window["dataY2DropDown"].Enabled := false
		window["dataY3DropDown"].Enabled := false
		window["dataY4DropDown"].Enabled := false
		window["dataY5DropDown"].Enabled := false
		window["dataY6DropDown"].Enabled := false

		if this.HasData {
			if inList(["Overview", "Drivers", "Positions", "Lap Times", "Performance", "Consistency", "Pace", "Pressures", "Brakes", "Temperatures", "Free"], this.SelectedReport)
				window["reportSettingsButton"].Enabled := true
			else
				window["reportSettingsButton"].Enabled := false

			if inList(["Pressures", "Brakes", "Temperatures", "Free"], this.SelectedReport) {
				window["chartTypeDropDown"].Enabled := true

				window["runDropDown"].Enabled := true

				window["dataXDropDown"].Enabled := true
				window["dataY1DropDown"].Enabled := true
				window["dataY2DropDown"].Enabled := true
				window["dataY3DropDown"].Enabled := true

				if (this.SelectedChartType != "Bubble") {
					window["dataY4DropDown"].Enabled := true
					window["dataY5DropDown"].Enabled := true
					window["dataY6DropDown"].Enabled := true
				}
			}
			else {
				window["chartTypeDropDown"].Enabled := false
				window["chartTypeDropDown"].Choose(0)

				this.iSelectedChartType := false

				window["runDropDown"].Choose(0)

				window["dataXDropDown"].Choose(0)
				window["dataY1DropDown"].Choose(0)
				window["dataY2DropDown"].Choose(0)
				window["dataY3DropDown"].Choose(0)
				window["dataY4DropDown"].Choose(0)
				window["dataY5DropDown"].Choose(0)
				window["dataY6DropDown"].Choose(0)
			}
		}
		else {
			window["reportSettingsButton"].Enabled := false

			window["runDropDown"].Choose(0)

			window["dataXDropDown"].Choose(0)
			window["dataY1DropDown"].Choose(0)
			window["dataY2DropDown"].Choose(0)
			window["dataY3DropDown"].Choose(0)
			window["dataY4DropDown"].Choose(0)
			window["dataY5DropDown"].Choose(0)
			window["dataY6DropDown"].Choose(0)

			window["chartTypeDropDown"].Enabled := false
			window["chartTypeDropDown"].Choose(0)

			this.iSelectedChartType := false
		}

		this.updateSessionMenu()
		this.updateRunMenu()
	}

	updateSessionMenu() {
		this.Control["sessionMenuDropDown"].Delete()
		this.Control["sessionMenuDropDown"].Add(collect(["Session", "---------------------------------------------"], translate))

		this.Control["sessionMenuDropDown"].Choose(1)
	}

	updateRunMenu() {
		this.Control["runMenuDropDown"].Delete()
		this.Control["runMenuDropDown"].Add(collect(["Practice", "---------------------------------------------"], translate))

		this.Control["runMenuDropDown"].Choose(1)
	}

	chooseSessionMenu(line) {
		this.updateSessionMenu()
	}

	chooseRunMenu(line) {
		this.updateRunMenu()
	}

	withExceptionHandler(function, arguments*) {
		try {
			return function.Call(arguments*)
		}
		catch Any as exception {
			logError(exception, false)

			OnMessage(0x44, translateOkButton)
			MsgBox((translate("Error while executing command.") . "`n`n" . translate("Error: ") . exception.Message), translate("Error"), 262160)
			OnMessage(0x44, translateOkButton, 0)
		}
	}

	pushTask(theTask) {
		PracticeCenterTask(theTask).start()
	}

	startWorking(state := true) {
		local start := false

		if state {
			start := (this.iWorking == 0)

			this.iWorking += 1

			if !start
				return false
		}
		else {
			this.iWorking -= 1

			if (this.iWorking > 0)
				return
			else
				this.iWorking := 0
		}

		if state
			this.Window.Block()
		else {
			curAutoActivate := this.Window.AutoActivate

			try {
				this.Window.AutoActivate := false

				this.Window.Unblock()
			}
			finally {
				this.Window.AutoActivate := curAutoActivate
			}
		}

		return (start || (this.iWorking == 0))
	}

	finishWorking() {
		this.startWorking(false)
	}

	isWorking() {
		return (this.iWorking > 0)
	}

	initializeSession() {
		local directory, reportDirectory

		directory := this.SessionDirectory

		deleteDirectory(directory)

		DirCreate(directory)

		reportDirectory := (directory . "Race Report")

		deleteDirectory(reportDirectory)

		DirCreate(reportDirectory)

		this.ReportViewer.setReport(reportDirectory)

		this.RunsListView.Delete()
		this.LapsListView.Delete()

		this.iSessionMode := false
		this.iSessionLoaded := false

		this.Control["runDropDown"].Delete()
		this.Control["runDropDown"].Add([translate("All")])
		this.Control["runDropDown"].Choose(1)

		this.iDrivers := []

		this.iRuns := CaseInsenseWeakMap()
		this.iLaps := CaseInsenseWeakMap()

		this.iLastLap := false
		this.iCurrentRun := false

		this.iTelemetryDatabase := false
		this.iPressuresDatabase := false
		this.iSessionStore := false

		this.iSelectedReport := false
		this.iSelectedChartType := false
		this.iSelectedDetailReport := false

		this.iSimulator := false
		this.iCar := false
		this.iTrack := false

		this.iWeather := false
		this.iWeather10Min := false
		this.iWeather30Min := false
		this.iAirTemperature := false
		this.iTrackTemperature := false

		this.iTyreCompound := false
		this.iTyreCompoundColor := false

		this.iSelectedRun := false

		this.showChart(false)
		this.showDetails(false, false)
	}

	initializeSimulator(simulator, car, track, force := false) {
		local row, compound

		if (force || !this.Simulator || (this.Simulator != simulator) || (this.Car != car) || (this.Track != track)) {
			this.iSimulator := simulator
			this.iCar := car
			this.iTrack := track

			if (this.Simulator = "") {
				this.iSimulator := false
				this.iCar := false
				this.iTrack := false
			}
		}
	}

	initializeReports() {
		local raceData, drivers, positions, times

		if !this.Simulator {
			raceData := true
			drivers := false
			positions := false
			times := false

			this.ReportViewer.loadReportData(false, &raceData, &drivers, &positions, &times)

			this.initializeSimulator(getMultiMapValue(raceData, "Session", "Simulator", false)
								   , getMultiMapValue(raceData, "Session", "Car")
								   , getMultiMapValue(raceData, "Session", "Track"))
		}
	}

	getPreviousLap(lap) {
		local laps := this.Laps

		lap := (lap.Nr - 1)

		while (lap > 0)
			if laps.Has(lap)
				return laps[lap]
			else
				lap -= 1

		return false
	}

	createRun(lapNumber) {
		local newRun := {Nr: (this.CurrentRun ? (this.CurrentRun.Nr + 1) : 1), Lap: lapNumber, StartTime: A_Now, TyreLaps: 0
					   , Driver: "-", FuelAmount: "-", FuelConsumption: 0.0, Accidents: 0, Weather: "-", Compound: "-"
					   , AvgLapTime: "-", Potential: "-", RaceCraft: "-", Speed: "-", Consistency: "-", CarControl: "-"
					   , Laps: []}

		this.RunsListView.Add("", newRun.Nr, newRun.Lap, "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-")

		newRun.Row := this.RunsListView.GetCount()

		this.RunsListView.ModifyCol()

		loop this.RunsListView.GetCount("Col")
			this.RunsListView.ModifyCol(A_Index, "AutoHdr")

		this.Control["runDropDown"].Add([newRun.Nr])

		return newRun
	}

	modifyRun(run) {
		local laps, numLaps, lapTimes, airTemperatures, trackTemperatures
		local ignore, lap, consumption, weather, fuelAmount

		run.FuelConsumption := 0.0
		run.Accidents := 0
		run.Weather := ""

		laps := run.Laps
		numLaps := laps.Length

		lapTimes := []
		airTemperatures := []
		trackTemperatures := []

		for ignore, lap in laps {
			if (lap.Nr > 1) {
				consumption := lap.FuelConsumption

				if isNumber(consumption) {
					run.FuelConsumption += ((this.getPreviousLap(lap).FuelConsumption = "-") ? (consumption * 2) : consumption)

					if (run.FuelAmount = "-")
						run.FuelAmount := (lap.FuelRemaining + run.FuelConsumption)
				}
			}

			if lap.Accident
				run.Accidents += 1

			lapTimes.Push(lap.Laptime)
			airTemperatures.Push(lap.AirTemperature)
			trackTemperatures.Push(lap.TrackTemperature)

			if (A_Index == 1)
				run.Compound := lap.Compound

			weather := lap.Weather

			if (run.Weather = "")
				run.Weather := weather
			else if !inList(string2Values(",", run.Weather), weather)
				run.Weather .= (", " . weather)
		}

		run.AvgLaptime := Round(average(laptimes), 1)
		run.BestLaptime := Round(minimum(laptimes), 1)
		run.FuelConsumption := Round(run.FuelConsumption, 2)
		run.AirTemperature := Round(average(airTemperatures), 1)
		run.TrackTemperature := Round(average(trackTemperatures), 1)

		if (run.Compound != "-") {
			this.iTyreCompound := compound(run.Compound)
			this.iTyreCompoundColor := compoundColor(run.Compound)
		}

		fuelAmount := run.FuelAmount

		if isNumber(fuelAmount)
			fuelAmount := displayValue("Float", convertUnit("Volume", fuelAmount))

		this.RunsListView.Modify(run.Row, "", run.Nr, run.Lap, (run.Driver != "-") ? run.Driver.FullName : "-"
											, values2String(", ", collect(string2Values(",", run.Weather), translate)*)
											, translate(run.Compound), run.Laps.Length
											, fuelAmount, displayValue("Float", convertUnit("Volume", run.FuelConsumption))
											, lapTimeDisplayValue(run.AvgLaptime)
											, run.Accidents, run.Potential, run.RaceCraft, run.Speed, run.Consistency, run.CarControl)
	}

	requireRun(lapNumber) {
		if !this.CurrentRun
			this.iCurrentRun := this.createRun(lapNumber)

		return this.CurrentRun
	}

	createLap(run, lapNumber) {
		local newLap := {Run: run, Nr: lapNumber, Weather: "-", Grip: "-", LapTime: "-", FuelConsumption: "-", FuelRemaining: "-"
					   , Pressures: "-,-,-,-", Temperatures: "-,-,-,-", Accident: ""
					   , Electronics: false, Tyres: false
					   , HotPressures: false, ColdPressures: false, PressureLosses: false}

		newLap.Run := run
		run.Laps.Push(newLap)

		this.LapsListView.Add("", newLap.Nr, run.Nr, "-", "-", "-", "-", "-", "-, -, -, -", "")

		newLap.Row := this.LapsListView.GetCount()

		this.LapsListView.ModifyCol()

		loop this.LapsListView.GetCount("Col")
			this.LapsListView.ModifyCol(A_Index, "AutoHdr")

		return newLap
	}

	modifyLap(lap) {
		local fuelConsumption := lap.FuelConsumption
		local remainingFuel := lap.FuelRemaining
		local pressures := string2Values(",", lap.Pressures)
		local pressure

		if isNumber(remainingFuel)
			remainingFuel := displayValue("Float", convertUnit("Volume", remainingFuel))

		if isNumber(fuelConsumption)
			fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

		loop 4 {
			pressure := pressures[A_Index]

			if isNumber(pressure)
				pressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
		}

		this.LapsListView.Modify(lap.Row, "", lap.Nr, lap.Run.Nr, translate(lap.Weather), translate(lap.Grip)
											, lapTimeDisplayValue(lap.Laptime), displayNullValue(fuelConsumption), remainingFuel
											, values2String(", ", pressures*)
											, lap.Accident ? translate("x") : "")
	}

	requireLap(lapNumber) {
		if this.Laps.Has(lapNumber)
			return this.Laps[lapNumber]
		else
			return this.createLap(this.requireRun(lapNumber), lapNumber)
	}

	addLap(lapNumber, data) {
		local lap := this.requireLap(lapNumber)
		local selectedLap := this.LapsListView.GetNext()
		local selectedRun := this.RunsListView.GetNext()
		local damage, pLap, fuelConsumption, car

		if selectedLap
			selectedLap := (selectedLap == this.LapsListView.GetCount())

		if selectedRun
			selectedRun := (selectedRun == this.RunsListView.GetCount())

		lap.Data := data

		if !isObject(lap.Run.Driver) {
			lap.Run.Driver := this.createDriver({Forname: getMultiMapValue(data, "Stint Data", "DriverForname")
											   , Surname: getMultiMapValue(data, "Stint Data", "DriverSurname")
											   , Nickname: getMultiMapValue(data, "Stint Data", "DriverNickname")
											   , ID: SessionDatabase.ID})

			lap.Run.Compound := compound(getMultiMapValue(data, "Car Data", "TyreCompound")
									   , getMultiMapValue(data, "Car Data", "TyreCompoundColor"))
		}

		damage := 0

		for ignore, value in string2Values(",", getMultiMapValue(data, "Car Data", "BodyworkDamage"))
			damage += value

		for ignore, value in string2Values(",", getMultiMapValue(data, "Car Data", "SuspensionDamage"))
			damage += value

		lap.Damage := damage

		if ((lap.Nr == 1) && (damage > 0))
			lap.Accident := true
		else {
			pLap := this.getPreviousLap(lap)

			if ((lap.Nr > 1) && pLap && (damage > pLap.Damage))
				lap.Accident := true
			else
				lap.Accident := false
		}

		lap.EngineDamage := getMultiMapValue(data, "Car Data", "EngineDamage", 0)

		lap.FuelRemaining := Round(getMultiMapValue(data, "Car Data", "FuelRemaining"), 1)

		if ((lap.Nr == 1) || ((lap.Run.Laps.Length > 0) && (lap.Run.Laps[1] == lap)))
			lap.FuelConsumption := "-"
		else {
			pLap := this.getPreviousLap(lap)

			fuelConsumption := (pLap ? (pLap.FuelRemaining - lap.FuelRemaining) : 0)

			lap.FuelConsumption := ((fuelConsumption > 0) ? Round(fuelConsumption, 2) : "-")
		}

		lap.Laptime := Round(getMultiMapValue(data, "Stint Data", "LapLastTime") / 1000, 1)

		lap.Map := getMultiMapValue(data, "Car Data", "Map", "n/a")
		lap.TC := getMultiMapValue(data, "Car Data", "TC", "n/a")
		lap.ABS := getMultiMapValue(data, "Car Data", "ABS", "n/a")

		lap.Weather := getMultiMapValue(data, "Weather Data", "Weather")
		lap.Weather10Min := getMultiMapValue(data, "Weather Data", "Weather10Min")
		lap.Weather30Min := getMultiMapValue(data, "Weather Data", "Weather30Min")
		lap.AirTemperature := Round(getMultiMapValue(data, "Weather Data", "Temperature"), 1)
		lap.TrackTemperature := Round(getMultiMapValue(data, "Track Data", "Temperature"), 1)
		lap.Grip := getMultiMapValue(data, "Track Data", "Grip")

		car := getMultiMapValue(data, "Position Data", "Driver.Car")

		lap.Position := (car ? getMultiMapValue(data, "Position Data", "Car." . car . ".Position") : false)

		lap.Compound := lap.Run.Compound

		this.iWeather := lap.Weather
		this.iAirTemperature := lap.AirTemperature
		this.iTrackTemperature := lap.TrackTemperature
		this.iWeather10Min := lap.Weather10Min
		this.iWeather30Min := lap.Weather30Min

		this.iLastLap := lap

		this.modifyLap(lap)
		this.modifyRun(lap.Run)

		this.updateReports()

		this.syncSessionStore()

		if (selectedLap && (this.SelectedDetailReport = "Lap")) {
			this.LapsListView.Modify(this.LapsListView.GetCount(), "Select Vis")

			this.showLapDetails(this.LastLap)
		}

		if (selectedRun && (this.SelectedDetailReport = "Run")) {
			this.RunsListView.Modify(this.RunsListView.GetCount(), "Select Vis")

			this.showRunDetails(this.CurrentRun)
		}

		this.updateState()
	}

	addTelemetry(lap, simulator, car, track, weather, airTemperature, trackTemperature
			   , fuelConsumption, fuelRemaining, lapTime, pitstop, map, tc, abs
			   , compound, compoundColor, pressures, temperatures, wear) {
		local telemetryDB := this.TelemetryDatabase
		local driverID := lap.Run.Driver.ID
		local update := false

		if (lap.Pressures = "-,-,-,-") {
			lap.Pressures := pressures

			update := true
		}

		if (lap.Temperatures = "-,-,-,-") {
			lap.Temperatures := temperatures

			update := true
		}

		lap.TelemetryData := values2String("|||", simulator, car, track, weather, airTemperature, trackTemperature
												, fuelConsumption, fuelRemaining, lapTime, pitstop, map, tc, abs
												, compound, compoundColor, pressures, temperatures, wear)

		telemetryDB.addElectronicEntry(weather, airTemperature, trackTemperature, compound, compoundColor
									 , map, tc, abs, fuelConsumption, fuelRemaining, lapTime
									 , driverID)

		pressures := string2Values(",", pressures)
		temperatures := string2Values(",", temperatures)
		wear := string2Values(",", wear)

		telemetryDB.addTyreEntry(weather, airTemperature, trackTemperature, compound, compoundColor
							   , lap.Run.TyreLaps + (lap.Nr - lap.Run.Lap) + 1
							   , pressures[1], pressures[2], pressures[3], pressures[4]
							   , temperatures[1], temperatures[2], temperatures[3], temperatures[4]
							   , wear[1], wear[2], wear[3], wear[4], fuelConsumption, fuelRemaining, lapTime
							   , driverID)

		if update {
			this.modifyLap(lap)
			this.modifyRun(lap.Run)

			this.updateState()
		}
	}

	addPressures(lap, simulator, car, track, weather, airTemperature, trackTemperature
			   , compound, compoundColor, coldPressures, hotPressures, pressuresLosses) {
		this.PressuresDatabase.updatePressures(weather, airTemperature, trackTemperature, compound, compoundColor
											 , string2Values(",", coldPressures), string2Values(",", hotPressures), string2Values(",", pressuresLosses)
											 , lap.Run.Driver.ID)

		lap.PressuresData := values2String("|||", simulator, car, track, weather, airTemperature, trackTemperature
												, compound, compoundColor, coldPressures, hotPressures, pressuresLosses)

		if (lap.Pressures = "-,-,-,-") {
			lap.Pressures := hotPressures

			this.modifyLap(lap)
			this.modifyRun(lap.Run)

			this.updateState()
		}
	}

	updateReports(redraw := false) {
		local selectedLap, selectedRun

		if this.HasData {
			if !this.SelectedReport
				this.iSelectedReport := "Overview"

			this.showReport(this.SelectedReport, true)
		}
		else if redraw
			this.showChart(false)

		if redraw {
			selectedLap := this.LapsListView.GetNext(0)

			if (selectedLap && (this.SelectedDetailReport = "Lap"))
				this.showLapDetails(this.Laps[selectedLap])
			else {
				selectedRun := this.RunsListView.GetNext(0)

				if (selectedRun && (this.SelectedDetailReport = "Run"))
					this.showRunDetails(this.Runs[selectedRun])
				else if (this.SelectedDetailReport && this.iSelectedDetailHTML) {
					this.DetailsViewer.document.open()
					this.DetailsViewer.document.write(this.iSelectedDetailHTML)
					this.DetailsViewer.document.close()
				}
			}
		}
	}

	getCar(lap, carID, &car, &carNumber, &carName, &driverForname, &driverSurname, &driverNickname) {
		return this.ReportViewer.getCar(lap.Nr, &carID, &car, &carNumber, &carName, &driverForname, &driverSurname, &driverNickname)
	}

	getStandings(lap, &cars, &ids, &overallPositions, &classPositions, &carNumbers, &carNames
					, &driverFornames, &driverSurnames, &driverNicknames, &driverCategories) {
		local tCars := true
		local tIDs := true
		local tOPositions := true
		local tCPositions := true
		local tCarNumbers := carNumbers
		local tCarNames := carNames
		local tDriverFornames := driverFornames
		local tDriverSurnames := driverSurnames
		local tDriverNicknames := driverNicknames
		local tDriverCategories := driverNicknames
		local index, multiClass

		multiClass := this.ReportViewer.getStandings(lap.Nr, &tCars, &tIDs, &tOPositions, &tCPositions, &tCarNumbers, &tCarNames
														   , &tDriverFornames, &tDriverSurnames, &tDriverNicknames, &tDriverCategories)

		if cars
			cars := []

		if ids
			ids := []

		if overallPositions
			overallPositions := []

		if classPositions
			classPositions := []

		if carNumbers
			carNumbers := []

		if carNames
			carNames := []

		if driverFornames
			driverFornames := []

		if driverSurnames
			driverSurnames := []

		if driverNicknames
			driverNicknames := []

		if driverCategories
			driverCategories := []

		if (tCars.Length > 0)
			loop tOPositions.Length {
				index := inList(tOPositions, A_Index)

				if index {
					if cars
						cars.Push(tCars[index])

					if ids
						ids.Push(tIDs[index])

					if overallPositions
						overallPositions.Push(tOPositions[index])

					if classPositions
						classPositions.Push(tCPositions[index])

					if carNumbers
						carNumbers.Push(tCarNumbers[index])

					if carNames
						carNames.Push(tCarNames[index])

					if driverFornames
						driverFornames.Push(tDriverFornames[index])

					if driverSurnames
						driverSurnames.Push(tDriverSurnames[index])

					if driverNicknames
						driverNicknames.Push(tDriverNicknames[index])

					if driverCategories
						driverCategories.Push(tDriverCategories[index])
				}
			}

		return multiClass
	}

	computeDriverTime(driver) {
		local duration := 0
		local run

		if this.CurrentRun
			loop this.CurrentRun.Nr {
				run := this.Runs[A_Index]

				if (run.Driver == driver)
					duration += this.computeDuration(run)
			}

		return duration
	}

	computeDuration(run) {
		local duration, ignore, lap

		if run.HasProp("Duration")
			return run.Duration
		else {
			duration := 0

			for ignore, lap in run.Laps
				duration += lap.LapTime

			if (run != this.CurrentRun)
				run.Duration := duration

			return duration
		}
	}

	computeEndTime(run, update := false) {
		local time, duration

		if run.HasProp("EndTime")
			return run.EndTime
		else {
			time := this.computeStartTime(run)
			duration := this.computeDuration(run)

			time := DateAdd(time, duration, "Seconds")

			if update
				run.EndTime := time

			return time
		}
	}

	computeStartTime(run) {
		local time

		if run.HasProp("StartTime")
			return run.StartTime
		else {
			if (run.Nr = 1) {
				run.StartTime := (A_Now . "")

				time := run.StartTime
			}
			else
				time := this.computeEndTime(this.Runs[run.Nr - 1], true)

			if (run != this.CurrentRun)
				run.StartTime := time

			return time
		}
	}

	computeLapStatistics(driver, laps, &potential, &raceCraft, &speed, &consistency, &carControl) {
		local raceData := true
		local drivers := false
		local positions := true
		local times := true
		local car, cars, potentials, raceCrafts, speeds, consistencies, carControls, count, oldLapSettings

		this.ReportViewer.loadReportData(laps, &raceData, &drivers, &positions, &times)

		car := getMultiMapValue(raceData, "Cars", "Driver", false)

		if car {
			cars := []

			loop getMultiMapValue(raceData, "Cars", "Count")
				cars.Push(A_Index)

			potentials := false
			raceCrafts := false
			speeds := false
			consistencies := false
			carControls := false

			count := laps.Length
			laps := []

			loop count
				laps.Push(A_Index)

			oldLapSettings := (this.ReportViewer.Settings.Has("Laps") ? this.ReportViewer.Settings["Laps"] : false)

			try {
				this.ReportViewer.Settings["Laps"] := laps

				this.ReportViewer.getDriverStatistics(raceData, cars, positions, times, &potentials, &raceCrafts, &speeds, &consistencies, &carControls)
			}
			finally {
				if oldLapSettings
					this.ReportViewer.Settings["Laps"] := oldLapSettings
				else
					this.ReportViewer.Settings.Delete("Laps")
			}

			potential := Round(potentials[car], 2)
			raceCraft := Round(raceCrafts[car], 2)
			speed := Round(speeds[car], 2)
			consistency := Round(consistencies[car], 2)
			carControl := Round(carControls[car], 2)
		}
		else {
			potential := 0.0
			raceCraft := 0.0
			speed := 0.0
			consistency := 0.0
			carControl := 0.0
		}
	}

	updateRunStatistics(run) {
		local laps := []
		local ignore, lap, potential, raceCraft, speed, consistency, carControl

		for ignore, lap in run.Laps
			laps.Push(lap.Nr)

		potential := false
		raceCraft := false
		speed := false
		consistency := false
		carControl := false

		this.computeLapStatistics(run.Driver, laps, &potential, &raceCraft, &speed, &consistency, &carControl)

		run.Potential := potential
		run.RaceCraft := raceCraft
		run.Speed := speed
		run.Consistency := consistency
		run.CarControl := carControl
	}

	updateDriverStatistics(driver) {
		local laps := []
		local accidents := 0
		local penalties := 0
		local ignore, lap, potential, raceCraft, speed, consistency, carControl

		for ignore, lap in driver.Laps {
			laps.Push(lap.Nr)

			if lap.Accident
				accidents += 1

			if lap.Penalty
				penalties += 1
		}

		potential := false
		raceCraft := false
		speed := false
		consistency := false
		carControl := false

		this.computeLapStatistics(driver, laps, &potential, &raceCraft, &speed, &consistency, &carControl)

		driver.Potential := potential
		driver.RaceCraft := raceCraft
		driver.Speed := speed
		driver.Consistency := consistency
		driver.CarControl := carControl
		driver.Accidents := accidents
		driver.Penalties := penalties
	}

	updateStatistics() {
		updateStatisticsAsync() {
			local progressWindow := showProgress({color: "Green", title: translate("Updating Run Statistics")})
			local currentRun := this.CurrentRun
			local count, run, ignore, driver

			if currentRun {
				count := currentRun.Nr

				loop count {
					showProgress({progress: Round((A_Index / count) * 50), color: "Green", message: translate("Run: ") . A_Index})

					if this.Runs.Has(A_Index) {
						run := this.Runs[A_Index]

						this.updateRunStatistics(run)

						this.RunsListView.Modify(run.Row, "Col12", run.Potential, run.RaceCraft, run.Speed, run.Consistency, run.CarControl)
					}

					Sleep(200)
				}
			}

			showProgress({title: translate("Updating Driver Statistics"), message: translate("...")})

			count := this.Drivers.Length

			for ignore, driver in this.Drivers {
				showProgress({progress: 50 + Round((A_Index / count) * 50), color: "Green", message: translate("Driver: ") . driver.FullName})

				this.updateDriverStatistics(driver)

				Sleep(200)
			}

			hideProgress()
		}

		this.pushTask(updateStatisticsAsync)
	}

	saveSession(copy := false) {
		saveSessionAsync(copy := false) {
			local info, directory, translator, folder, session

			this.showMessage(translate("Saving session"))

			if (this.SessionMode = "Active") {
				this.syncSessionStore(true)

				info := newMultiMap()

				setMultiMapValue(info, "Session", "Team", this.SelectedTeam)
				setMultiMapValue(info, "Session", "Session", this.SelectedSession)
				setMultiMapValue(info, "Session", "Date", this.Date)
				setMultiMapValue(info, "Session", "Time", this.Time)
				setMultiMapValue(info, "Session", "Simulator", this.Simulator)
				setMultiMapValue(info, "Session", "Car", this.Car)
				setMultiMapValue(info, "Session", "Track", this.Track)

				setMultiMapValue(info, "Weather", "Weather", this.Weather)
				setMultiMapValue(info, "Weather", "Weather10Min", this.Weather10Min)
				setMultiMapValue(info, "Weather", "Weather30Min", this.Weather30Min)
				setMultiMapValue(info, "Weather", "AirTemperature", this.AirTemperature)
				setMultiMapValue(info, "Weather", "TrackTemperature", this.TrackTemperature)

				writeMultiMap(this.SessionDirectory . "Practice.info", info)
			}
			else {
				this.saveSetups()
				this.savePlan()

				this.SessionStore.flush()
			}

			if copy {
				directory := ((this.SessionMode = "Loaded") ? this.SessionLoaded : this.SessionDirectory)

				this.Window.Opt("+OwnDialogs")

				translator := translateMsgBoxButtons.Bind(["Select", "Select", "Cancel"])

				OnMessage(0x44, translator)
				folder := DirSelect("*" directory, 0, translate("Select target folder..."))
				OnMessage(0x44, translator, 0)

				if (folder != "")
					try {
						DirCopy(directory, folder . "\" . this.SelectedSession, 1)
					}
					catch Any as exception {
						logError(exception)
					}
			}

			this.showMessage(false)
		}

		this.pushTask(saveSessionAsync.Bind(copy))
	}

	clearSession() {
		clearSessionAsync() {
			this.initializeSession()
			this.updateState()
		}

		this.pushTask(clearSessionAsync)
	}

	loadDrivers() {
		local ignore, driver

		this.iDrivers := []

		for ignore, driver in this.SessionStore.Tables["Driver.Data"]
			this.createDriver({Forname: driver["Forname"], Surname: driver["Surname"], Nickname: driver["Nickname"]
							 , Fullname: computeDriverName(driver["Forname"], driver["Surname"], driver["Nickname"])
							 , ID: driver["ID"]})
	}

	loadLaps() {
		local ignore, lap, newLap, engineDamage

		this.iLaps := CaseInsenseWeakMap()

		for ignore, lap in this.SessionStore.Tables["Lap.Data"] {
			newLap := {Nr: lap["Nr"], Run: lap["Run"], Laptime: lap["Lap.Time"], Position: lap["Position"], Grip: lap["Grip"]
					 , Map: lap["Map"], TC: lap["TC"], ABS: lap["ABS"]
					 , Weather: lap["Weather"], AirTemperature: lap["Temperature.Air"], TrackTemperature: lap["Temperature.Track"]
					 , FuelRemaining: lap["Fuel.Remaining"], FuelConsumption: lap["Fuel.Consumption"]
					 , Damage: lap["Damage"], EngineDamage: lap["EngineDamage"]
					 , Accident: lap["Accident"]
					 , Compound: compound(lap["Tyre.Compound"], lap["Tyre.Compound.Color"])
					 , Data: false, TelemetryData: lap["Data.Telemetry"], PressuresData: lap["Data.Pressures"]}

			if (isNull(newLap.Map))
				newLap.Map := "n/a"

			if (isNull(newLap.TC))
				newLap.TC := "n/a"

			if (isNull(newLap.ABS))
				newLap.ABS := "n/a"

			if (isNull(newLap.EngineDamage))
				newLap.EngineDamage := 0

			if (isNull(newLap.Position))
				newLap.Position := "-"

			if (isNull(newLap.Laptime))
				newLap.Laptime := "-"

			if (isNull(newLap.FuelConsumption))
				newLap.FuelConsumption := "-"

			if (isNull(newLap.FuelRemaining))
				newLap.FuelRemaining := "-"

			if (isNull(newLap.AirTemperature))
				newLap.AirTemperature := "-"

			if (isNull(newLap.TrackTemperature))
				newLap.TrackTemperature := "-"

			this.Laps[newLap.Nr] := newLap
			this.iLastLap := newLap
		}
	}

	loadRuns() {
		local ignore, run, newRun, driver, laps, lap, runNr, runLap, airTemperatures, trackTemperatures
		local currentRun, lastLap, remainingFuel, fuelConsumption, penalty

		this.iRuns := CaseInsenseWeakMap()

		for ignore, run in this.SessionStore.Tables["Run.Data"] {
			driver := this.createDriver({Forname: run["Driver.Forname"], Surname: run["Driver.Surname"], Nickname: run["Driver.Nickname"], ID: run["Driver.ID"]})

			newRun := {Nr: run["Nr"], Lap: run["Lap"], Driver: driver, Weather: run["Weather"]
					 , FuelAmound: run["Fuel.Amount"], FuelConsumption: run["Fuel.Consumption"]
					 , Compound: compound(run["Tyre.Compound"], run["Tyre.Compound.Color"]), TyreSet: run["Tyre.Set"], TyreLaps: run["Tyre.Laps"]
					 , AvgLaptime: run["Lap.Time.Average"], BestLaptime: run["Lap.Time.Best"]
					 , Accidents: run["Accidents"], StartTime: run["Time.Start"], EndTime: run["Time.End"]}

			if (isNull(newRun.StartTime))
				newRun.StartTime := false

			if (isNull(newRun.EndTime))
				newRun.EndTime := false

			driver.Runs.Push(newRun)
			laps := []

			newRun.Laps := laps

			runNr := newRun.Nr
			runLap := newRun.Lap

			airTemperatures := []
			trackTemperatures := []

			loop {
				if !this.Laps.Has(runLap)
					break

				lap := this.Laps[runLap]

				airTemperatures.Push(lap.AirTemperature)
				trackTemperatures.Push(lap.TrackTemperature)

				if isObject(lap.Run)
					newRun.Lap := (runLap + 1)
				else
					if (lap.Run != runNr)
						break
					else {
						lap.Run := newRun
						laps.Push(lap)

						driver.Laps.Push(lap)
					}

				runLap += 1
			}

			newRun.AirTemperature := Round(average(airTemperatures), 1)
			newRun.TrackTemperature := Round(average(trackTemperatures), 1)

			newRun.Potential := "-"
			newRun.RaceCraft := "-"
			newRun.Speed := "-"
			newRun.Consistency := "-"
			newRun.CarControl := "-"

			if (isNull(newRun.AvgLaptime))
				newRun.AvgLaptime := "-"

			if (isNull(newRun.BestLaptime))
				newRun.BestLaptime := "-"

			if (isNull(newRun.FuelAmount))
				newRun.FuelAmount := "-"

			if (isNull(newRun.FuelConsumption))
				newRun.FuelConsumption := "-"

			this.Runs[newRun.Nr] := newRun

			this.iCurrentRun := newRun
		}

		currentRun := this.CurrentRun

		if currentRun
			loop currentRun.Nr
				if this.Runs.Has(A_Index) {
					run := this.Runs[A_Index]
					run.Row := (this.RunsListView.GetCount() + 1)

					this.RunsListView.Add("", run.Nr, run.Lap, run.Driver.FullName
											, values2String(", ", collect(string2Values(",", run.Weather), translate)*)
											, translate(run.Compound), run.Laps.Length
											, isNumber(run.FuelAmount) ? displayValue("Float", convertUnit("Volume", run.FuelAmount)) : run.FuelAmount
											, isNumber(run.FuelConsumption) ? displayValue("Float", convertUnit("Volume", run.FuelConsumption)) : run.FuelConsumption
											, lapTimeDisplayValue(run.AvgLaptime)
											, run.Accidents, run.Potential, run.RaceCraft, run.Speed, run.Consistency, run.CarControl)
				}

		this.RunsListView.ModifyCol()

		loop this.RunsListView.GetCount("Col")
			this.RunsListView.ModifyCol(A_Index, "AutoHdr")

		lastLap := this.LastLap

		if lastLap
			loop lastLap.Nr
				if this.Laps.Has(A_Index) {
					lap := this.Laps[A_Index]
					lap.Row := (this.LapsListView.GetCount() + 1)

					remainingFuel := lap.FuelRemaining

					if isNumber(remainingFuel)
						remainingFuel := displayValue("Float", convertUnit("Volume", remainingFuel))

					fuelConsumption := lap.FuelConsumption

					if isNumber(fuelConsumption)
						fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

					this.LapsListView.Add("", lap.Nr, lap.Run.Nr, translate(lap.Weather), translate(lap.Grip)
											, lapTimeDisplayValue(lap.Laptime), displayNullValue(fuelConsumption), remainingFuel, "-, -, -, -"
											, lap.Accident ? translate("x") : "")
				}

		this.LapsListView.ModifyCol()

		loop this.LapsListView.GetCount("Col")
			this.LapsListView.ModifyCol(A_Index, "AutoHdr")
	}

	loadTelemetry() {
		local lastLap := this.LastLap
		local lap

		if lastLap
			loop lastLap.Nr
				if this.Laps.Has(A_Index) {
					lap := this.Laps[A_Index]

					this.addTelemetry(lap, string2Values("|||", lap.TelemetryData)*)
				}
	}

	loadPressures() {
		local lastLap := this.LastLap
		local lap

		if lastLap
			loop lastLap.Nr
				if this.Laps.Has(A_Index) {
					lap := this.Laps[A_Index]

					this.addPressures(lap, string2Values("|||", lap.PressuresData)*)
				}
	}

	loadSession() {
		loadSessionAsync() {
			local directory := ((this.SessionMode = "Loaded") ? this.SessionLoaded : this.iSessionDirectory)
			local folder, info, lastLap, currentRun, translator

			this.Window.Opt("+OwnDialogs")

			translator := translateMsgBoxButtons.Bind(["Select", "Select", "Cancel"])

			OnMessage(0x44, translator)
			folder := DirSelect("*" . directory, 0, translate("Select Practice folder..."))
			OnMessage(0x44, translator, 0)

			if (folder != "") {
				folder := (folder . "\")

				info := readMultiMap(folder . "Practice.info")

				if (info.Count == 0) {
					OnMessage(0x44, translateOkButton)
					MsgBox(translate("This is not a valid folder with a saved session."), translate("Error"), 262160)
					OnMessage(0x44, translateOkButton, 0)
				}
				else {
					this.initializeSession()

					this.iSessionMode := "Loaded"
					this.iSessionLoaded := folder

					this.iDate := getMultiMapValue(info, "Session", "Date", A_Now)
					this.iTime := getMultiMapValue(info, "Session", "Time", A_Now)

					this.iWeather := getMultiMapValue(info, "Weather", "Weather", false)
					this.iWeather10Min := getMultiMapValue(info, "Weather", "Weather10Min", false)
					this.iWeather30Min := getMultiMapValue(info, "Weather", "Weather30Min", false)
					this.iAirTemperature := getMultiMapValue(info, "Weather", "AirTemperature", false)
					this.iTrackTemperature := getMultiMapValue(info, "Weather", "TrackTemperature", false)

					this.Control["sessionDateCal"].Value := this.Date
					this.Control["sessionTimeEdit"].Value := this.Time

					this.loadDrivers()
					this.loadLaps()
					this.loadRuns()
					this.loadTelemetry()
					this.loadPressures()

					this.ReportViewer.setReport(folder . "Race Report")

					this.initializeReports()

					if !this.Weather {
						lastLap := this.LastLap

						if lastLap {
							this.iWeather := lastLap.Weather
							this.iAirTemperature := lastLap.AirTemperature
							this.iTrackTemperature := lastLap.TrackTemperature
							this.iWeather10Min := lastLap.Weather10Min
							this.iWeather30Min := lastLap.Weather30Min
						}
					}

					if !this.TyreCompound {
						currentRun := this.CurrentRun

						if currentRun {
							this.iTyreCompound := compound(currentRun.Compound)
							this.iTyreCompoundColor := compoundColor(currentRun.Compound)
						}
					}

					this.updateReports()

					this.updateState()
				}
			}
		}

		this.pushTask(loadSessionAsync)
	}

	showChart(drawChartFunction) {
		local before, after, html

		this.ChartViewer.document.open()

		if (drawChartFunction && (drawChartFunction != "")) {
			before := "
			(
			<html>
			    <meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; background-color: #%oddRowBackColor%; }
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawChart);
			)"

			before := substituteVariables(before, {headerBackColor: this.Window.Theme.ListBackColor["Header"]
												 , evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
												 , oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]})

			after := "
			(
					</script>
				</head>
				<body style='background-color: #%backColor%' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; background-color: #%oddRowBackColor%; }
					</style>
					<div id="chart_id" style="width: %width%px; height: %height%px"></div>
				</body>
			</html>
			)"

			html := (before . drawChartFunction . substituteVariables(after, {width: (this.ChartViewer.getWidth() - 5)
																			, height: (this.ChartViewer.getHeight() - 5)
																			, backColor: this.Window.AltBackColor
																			, headerBackColor: this.Window.Theme.ListBackColor["Header"]
																			, evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
																			, oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]}))

			this.ChartViewer.document.write(html)
		}
		else {
			html := "<html><body style='background-color: #%backColor%' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'></body></html>"

			this.ChartViewer.document.write(substituteVariables(html, {backColor: this.Window.AltBackColor}))
		}

		this.ChartViewer.document.close()
	}

	showDataPlot(data, xAxis, yAxises) {
		local double := (yAxises.Length > 1)
		local minValue := kUndefined
		local maxValue := kUndefined
		local drawChartFunction := ""
		local ignore, yAxis, settingsLaps, laps, ignore, lap, first, values, value, minValue, maxValue
		local series, vAxis, index

		drawChartFunction .= "function drawChart() {"
		drawChartFunction .= "`nvar data = new google.visualization.DataTable();"

		if (this.SelectedChartType = "Bubble")
			drawChartFunction .= ("`ndata.addColumn('string', 'ID');")

		drawChartFunction .= ("`ndata.addColumn('number', '" . xAxis . "');")

		for ignore, yAxis in yAxises {
			drawChartFunction .= ("`ndata.addColumn('number', '" . yAxis . "');")
		}

		settingsLaps := (this.ReportViewer.Settings.Has("Laps") ? this.ReportViewer.Settings["Laps"] : false)
		laps := false

		if (settingsLaps && (settingsLaps.Length > 0)) {
			laps := CaseInsenseWeakMap()

			for ignore, lap in settingsLaps
				laps[lap] := lap
		}

		drawChartFunction .= "`ndata.addRows(["
		first := true

		for ignore, values in data {
			if (laps && !laps.Has(A_Index))
				continue

			if !first
				drawChartFunction .= ",`n"

			first := false
			value := ((this.SelectedRun && (this.SelectedRun != this.Runs[values["Run"]].Nr)) ? kNull : values[xAxis])

			if ((value = "n/a") || (isNull(value)))
				value := kNull

			if (this.SelectedChartType = "Bubble")
				drawChartFunction .= ("['', " . convertValue(xAxis, value))
			else
				drawChartFunction .= ("[" . convertValue(xAxis, value))

			for ignore, yAxis in yAxises {
				value := values[yAxis]

				if ((value = "n/a") || (isNull(value)))
					value := kNull
				else {
					minValue := ((minValue == kUndefined) ? value : Min(minValue, value))
					maxValue := ((maxValue == kUndefined) ? value : Max(maxValue, value))
				}

				drawChartFunction .= (", " . convertValue(yAxis, value))
			}

			drawChartFunction .= "]"
		}

		drawChartFunction .= "`n]);"

		series := "series: {"
		vAxis := "vAxis: { "

		for ignore, yAxis in yAxises {
			if (A_Index > 1) {
				series .= ", "
				vAxis .= ", "
			}

			if (A_Index > 2)
				break

			index := A_Index - 1

			series .= (index . ": {targetAxisIndex: " . index . "}")
			vAxis .= (index . ": {title: '" . translate(yAxis) . "'}")
		}

		series .= "}"
		vAxis .= "}"

		if (this.SelectedChartType = "Scatter") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "', hAxis: { title: '" . translate(xAxis) . "' }, " . series . ", " . vAxis . "};")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.ScatterChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Bar") {
			if (minValue == kUndefined)
				minValue := 0
			else
				minValue := Min(0, minValue)

			if (maxValue == kUndefined)
				maxValue := 0

			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "', hAxis: { viewWindow: {min: " . minValue . ", max: " . maxValue . "} }, vAxis: { viewWindowMode: 'pretty' } };")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BarChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Bubble") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "', hAxis: { title: '" . translate(xAxis) . "', viewWindowMode: 'pretty' }, vAxis: { title: '" . translate(yAxises[1]) . "', viewWindowMode: 'pretty' }, colorAxis: { legend: {position: 'none'}, colors: ['blue', 'red'] }, sizeAxis: { maxSize: 15 } };")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BubbleChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Line") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#" . this.Window.AltBackColor . "' };")

			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.LineChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}

		this.showChart(drawChartFunction)
	}

	showDetails(report, details, charts*) {
		local chartID := 1
		local html := (details ? details : "")
		local script, ignore, chart

		this.iSelectedDetailReport := report

		if details {
			script := "
			(
				<meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; background-color: #%oddRowBackColor%; }
						%tableCSS%
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawCharts);

						function drawCharts() {
			)"

			script := substituteVariables(script, {tableCSS: this.StrategyViewer.getTableCSS()
												 , headerBackColor: this.Window.Theme.ListBackColor["Header"]
												 , evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
												 , oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]})

			for ignore, chart in charts
				script .= (A_Space . "drawChart" . chart[1] . "();")

			script .= "}`n"

			for ignore, chart in charts {
				if (A_Index > 0)
					script .= "`n"

				script .= chart[2]
			}

			script .= "</script></head>"
		}
		else
			script := ""

		html := ("<html>" . script . "<body style='background-color: #" . this.Window.AltBackColor . "' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><style> div, table { font-family: Arial, Helvetica, sans-serif; font-size: 11px }</style><style> #header { font-size: 12px; }</style><div>" . html . "</div></body></html>")

		this.iSelectedDetailHTML := html

		this.DetailsViewer.document.open()
		this.DetailsViewer.document.write(html)
		this.DetailsViewer.document.close()
	}

	selectReport(report) {
		if report {
			this.ReportsListView.Modify(inList(kSessionReports, report), "+Select")

			this.iSelectedReport := report
		}
		else {
			loop this.ReportsListView.GetCount()
				this.ReportsListView.Modify(A_Index, "-Select")

			this.iSelectedReport := false
		}
	}

	showOverviewReport() {
		this.selectReport("Overview")

		this.ReportViewer.showOverviewReport()

		this.updateState()
	}

	editOverviewReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Classes")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showCarReport() {
		this.selectReport("Car")

		this.ReportViewer.showCarReport()

		this.updateState()
	}

	showDriverReport() {
		this.selectReport("Drivers")

		this.ReportViewer.showDriverReport()

		this.updateState()
	}

	editDriverReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps", "Drivers", "Classes")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showPositionsReport() {
		this.selectReport("Positions")

		this.ReportViewer.showPositionsReport()

		this.updateState()
	}

	editPositionsReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps", "Classes")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showLapTimesReport() {
		this.selectReport("Lap Times")

		this.ReportViewer.showLapTimesReport()

		this.updateState()
	}

	editLapTimesReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showConsistencyReport() {
		this.selectReport("Consistency")

		this.ReportViewer.showConsistencyReport()

		this.updateState()
	}

	editConsistencyReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showPaceReport() {
		this.selectReport("Pace")

		this.ReportViewer.showPaceReport()

		this.updateState()
	}

	editPaceReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showPerformanceReport() {
		this.selectReport("Performance")

		this.ReportViewer.showPerformanceReport()

		this.updateState()
	}

	editPerformanceReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps", "Cars", "Classes")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showRaceReport(report) {
		local raceData, drivers, ignore

		switch report, false {
			case "Overview":
				this.showOverviewReport()
			case "Car":
				this.showCarReport()
			case "Drivers":
				if !this.ReportViewer.Settings.Has("Drivers") {
					raceData := true

					this.ReportViewer.loadReportData(false, &raceData, &ignore := false, &ignore := false, &ignore := false)

					drivers := []

					loop Min(5, getMultiMapValue(raceData, "Cars", "Count"))
						drivers.Push(A_Index)

					if !this.ReportViewer.Settings.Has("Drivers")
						this.ReportViewer.Settings["Drivers"] := drivers
				}

				this.showDriverReport()
			case "Positions":
				this.showPositionsReport()
			case "Lap Times":
				this.showLapTimesReport()
			case "Consistency":
				if !this.ReportViewer.Settings.Has("Drivers") {
					raceData := true

					this.ReportViewer.loadReportData(false, &raceData, &ingore := false, &ingore := false, &ingore := false)

					drivers := []

					loop Min(5, getMultiMapValue(raceData, "Cars", "Count"))
						drivers.Push(A_Index)

					if !this.ReportViewer.Settings.Has("Drivers")
						this.ReportViewer.Settings["Drivers"] := drivers
				}

				this.showConsistencyReport()
			case "Pace":
				this.showPaceReport()
			case "Performance":
				this.showPerformanceReport()
		}
	}

	showTelemetryReport() {
		local window := this.Window
		local xAxis, yAxises

		xAxis := this.iXColumns[window["dataXDropDown"].Value]
		yAxises := Array(this.iY1Columns[window["dataY1DropDown"].Value])

		if (window["dataY2DropDown"].Value > 1)
			yAxises.Push(this.iY2Columns[window["dataY2DropDown"].Value - 1])

		if (window["dataY3DropDown"].Value > 1)
			yAxises.Push(this.iY3Columns[window["dataY3DropDown"].Value - 1])

		if (window["dataY4DropDown"].Value > 1)
			yAxises.Push(this.iY4Columns[window["dataY4DropDown"].Value - 1])

		if (window["dataY5DropDown"].Value > 1)
			yAxises.Push(this.iY5Columns[window["dataY5DropDown"].Value - 1])

		if (window["dataY6DropDown"].Value > 1)
			yAxises.Push(this.iY6Columns[window["dataY6DropDown"].Value - 1])

		this.showDataPlot(this.SessionStore.Tables["Lap.Data"], xAxis, yAxises)

		this.updateState()
	}

	showPressuresReport() {
		this.selectReport("Pressures")

		this.showTelemetryReport()

		this.updateState()
	}

	editPressuresReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showBrakesReport() {
		this.selectReport("Brakes")

		this.showTelemetryReport()

		this.updateState()
	}

	editBrakesReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showTemperaturesReport() {
		this.selectReport("Temperatures")

		this.showTelemetryReport()

		this.updateState()
	}

	editTemperaturesReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Unblock()
		}
	}

	showCustomReport() {
		this.selectReport("Free")

		this.showTelemetryReport()

		this.updateState()
	}

	editCustomReportSettings() {
		this.Window.Block()

		try {
			return this.ReportViewer.editReportSettings("Laps")
		}
		finally {
			this.Window.Unblock()
		}
	}

	updateSeriesSelector(report, force := false) {
		local window := this.Window
		local xChoices, y1Choices, y2Choices, y3Choices, y4Choices, y5Choices, y6Choices
		local sessionDB, selected, runs, ignore, run

		if (force || (report != this.SelectedReport) || (window["dataXDropDown"].Value == 0)) {
			xChoices := []
			y1Choices := []
			y2Choices := []
			y3Choices := []
			y4Choices := []
			y5Choices := []
			y6Choices := []

			if (report = "Pressures") {
				xChoices := ["Run", "Lap", "Lap.Time", "Tyre.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Tyre.Laps"
							, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right", "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right", "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
							, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
							, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right", "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Brakes") {
				xChoices := ["Run", "Lap", "Lap.Time", "Brake.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining"
							, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
							, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
							, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
							, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Temperatures") {
				xChoices := ["Run", "Lap", "Lap.Time", "Tyre.Wear.Average", "Brake.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Tyre.Laps"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right", "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
							, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
							, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right", "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"
							, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
							, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right", "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"
							, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
							, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
							, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
							, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Free") {
				xChoices := ["Run", "Lap", "Lap.Time", "Tyre.Laps", "Map", "TC", "ABS", "Temperature.Air", "Temperature.Track", "Tyre.Wear.Average", "Brake.Wear.Average"]

				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Fuel.Consumption", "Lap.Time", "Tyre.Laps", "Map", "TC", "ABS"
							, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Pressure.Loss.Front.Left", "Tyre.Pressure.Loss.Front.Right", "Tyre.Pressure.Loss.Rear.Left", "Tyre.Pressure.Loss.Rear.Right"
							, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
							, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right", "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"
							, "Tyre.Wear.Average", "Tyre.Wear.Front.Average", "Tyre.Wear.Rear.Average"
							, "Tyre.Wear.Front.Left", "Tyre.Wear.Front.Right", "Tyre.Wear.Rear.Left", "Tyre.Wear.Rear.Right"
							, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"
							, "Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
							, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"
							, "Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"]

				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}

			this.iXColumns := xChoices
			this.iY1Columns := y1Choices
			this.iY2Columns := y2Choices
			this.iY3Columns := y3Choices
			this.iY4Columns := y3Choices
			this.iY5Columns := y3Choices
			this.iY6Columns := y3Choices

			window["dataXDropDown"].Delete()
			window["dataXDropDown"].Add(xChoices)
			window["dataY1DropDown"].Delete()
			window["dataY1DropDown"].Add(y1Choices)
			window["dataY2DropDown"].Delete()
			window["dataY2DropDown"].Add(concatenate([translate("None")], y2Choices))
			window["dataY3DropDown"].Delete()
			window["dataY3DropDown"].Add(concatenate([translate("None")], y3Choices))
			window["dataY4DropDown"].Delete()
			window["dataY4DropDown"].Add(concatenate([translate("None")], y4Choices))
			window["dataY5DropDown"].Delete()
			window["dataY5DropDown"].Add(concatenate([translate("None")], y5Choices))
			window["dataY6DropDown"].Delete()
			window["dataY6DropDown"].Add(concatenate([translate("None")], y6Choices))

			local dataXChoice := 0
			local dataY1Choice := 0
			local dataY2Choice := 0
			local dataY3Choice := 0
			local dataY4Choice := 0
			local dataY5Choice := 0
			local dataY6Choice := 0

			if (report = "Pressures") {
				window["chartTypeDropDown"].Choose(4)

				this.iSelectedChartType := "Line"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Temperature.Air")
				dataY2Choice := inList(y2Choices, "Tyre.Pressure.Cold.Average") + 1
				dataY3Choice := inList(y3Choices, "Tyre.Pressure.Hot.Average") + 1
				dataY4Choice := 1
				dataY5Choice := 1
				dataY6Choice := 1
			}
			else if (report = "Brakes") {
				window["chartTypeDropDown"].Choose(4)

				this.iSelectedChartType := "Line"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Temperature.Air")
				dataY2Choice := inList(y2Choices, "Brake.Temperature.Front.Average") + 1
				dataY3Choice := inList(y3Choices, "Brake.Temperature.Rear.Average") + 1
				dataY4Choice := inList(y4Choices, "Brake.Wear.Front.Average") + 1
				dataY5Choice := inList(y5Choices, "Brake.Wear.Rear.Average") + 1
				dataY6Choice := 1
			}
			else if (report = "Temperatures") {
				window["chartTypeDropDown"].Choose(1)

				this.iSelectedChartType := "Scatter"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Temperature.Air")
				dataY2Choice := inList(y2Choices, "Tyre.Temperature.Front.Average") + 1
				dataY3Choice := inList(y3Choices, "Tyre.Temperature.Rear.Average") + 1
				dataY4Choice := 1
				dataY5Choice := 1
				dataY6Choice := 1
			}
			else if (report = "Free") {
				window["chartTypeDropDown"].Choose(4)

				this.iSelectedChartType := "Line"

				dataXChoice := inList(xChoices, "Lap")
				dataY1Choice := inList(y1Choices, "Lap.Time")
				dataY2Choice := inList(y2Choices, "Tyre.Laps") + 1
				dataY3Choice := inList(y3Choices, "Temperature.Air") + 1
				dataY4Choice := inList(y4Choices, "Temperature.Track") + 1
				dataY5Choice := inList(y5Choices, "Tyre.Pressure.Cold.Average") + 1
				dataY6Choice := inList(y6Choices, "Tyre.Pressure.Hot.Average") + 1
			}

			sessionDB := SessionDatabase()
			runs := []
			selected := false

			if this.CurrentRun
				loop this.CurrentRun.Nr {
					runs.Push(A_Index)

					if (A_Index = this.SelectedRun)
						selected := A_Index
				}

			window["runDropDown"].Delete()
			window["runDropDown"].Add(concatenate([translate("All")], runs))
			window["runDropDown"].Choose(selected + 1)

			window["dataXDropDown"].Choose(dataXChoice)
			window["dataY1DropDown"].Choose(dataY1Choice)
			window["dataY2DropDown"].Choose(dataY2Choice)
			window["dataY3DropDown"].Choose(dataY3Choice)
			window["dataY4DropDown"].Choose(dataY4Choice)
			window["dataY5DropDown"].Choose(dataY5Choice)
			window["dataY6DropDown"].Choose(dataY6Choice)
		}
	}

	syncSessionStore(forSave := false) {
		local sessionStore := this.SessionStore
		local lastLap := this.LastLap
		local pressuresTable, tyresTable, newLap, lap, lapData, pressures, tyres
		local pressureFL, pressureFR, pressureRL, pressureRR
		local pressureLossFL, pressureLossFR, pressureLossRL, pressureLossRR
		local temperatureFL, temperatureFR, temperatureRL, temperatureRR
		local wearFL, wearFR, wearRL, wearRR
		local telemetry, brakeTemperatures, ignore, field, brakeWears
		local currentListView, lapPressures, entry, standingsData, prefix, driver, category
		local currentRun, newRun, run, runData, tries, carIDs, positions

		if lastLap
			lastLap := lastLap.Nr

		if lastLap {
			pressuresTable := this.PressuresDatabase.Database.Tables["Tyres.Pressures"]
			tyresTable := this.TelemetryDatabase.Database.Tables["Tyres"]

			newLap := (sessionStore.Tables["Lap.Data"].Length + 1)

			while (newLap <= lastLap) {
				if !this.Laps.Has(newLap) {
					newLap += 1

					continue
				}

				lap := this.Laps[newLap]

				if ((pressuresTable.Length < newLap) || (tyresTable.Length < newLap))
					return

				lapData := Database.Row("Nr", newLap, "Lap", newLap, "Run", lap.Run.Nr, "Lap.Time", null(lap.Laptime), "Position", null(lap.Position)
									  , "Damage", lap.Damage, "EngineDamage", lap.EngineDamage, "Accident", lap.Accident
									  , "Fuel.Consumption", null(lap.FuelConsumption), "Fuel.Remaining", null(lap.FuelRemaining)
									  , "Weather", lap.Weather, "Temperature.Air", null(lap.AirTemperature), "Temperature.Track", null(lap.TrackTemperature)
									  , "Grip", lap.Grip, "Map", null(lap.Map), "TC", null(lap.TC), "ABS", null(lap.ABS)
									  , "Tyre.Compound", compound(lap.Compound), "Tyre.Compound.Color", compoundColor(lap.Compound)
									  , "Data.Telemetry", lap.TelemetryData, "Data.Pressures", lap.PressuresData)

				pressures := pressuresTable[newLap]
				tyres := tyresTable[newLap]

				pressureFL := pressures["Tyre.Pressure.Cold.Front.Left"]
				pressureFR := pressures["Tyre.Pressure.Cold.Front.Right"]
				pressureRL := pressures["Tyre.Pressure.Cold.Rear.Left"]
				pressureRR := pressures["Tyre.Pressure.Cold.Rear.Right"]

				lapData["Tyre.Pressure.Cold.Front.Left"] := null(pressureFL)
				lapData["Tyre.Pressure.Cold.Front.Right"] := null(pressureFR)
				lapData["Tyre.Pressure.Cold.Rear.Left"] := null(pressureRL)
				lapData["Tyre.Pressure.Cold.Rear.Right"] := null(pressureRR)
				lapData["Tyre.Pressure.Cold.Average"] := null(average([pressureFL, pressureFR, pressureRL, pressureRR]))
				lapData["Tyre.Pressure.Cold.Front.Average"] := null(average([pressureFL, pressureFR]))
				lapData["Tyre.Pressure.Cold.Rear.Average"] := null(average([pressureRL, pressureRR]))

				pressureFL := pressures["Tyre.Pressure.Hot.Front.Left"]
				pressureFR := pressures["Tyre.Pressure.Hot.Front.Right"]
				pressureRL := pressures["Tyre.Pressure.Hot.Rear.Left"]
				pressureRR := pressures["Tyre.Pressure.Hot.Rear.Right"]

				if (isNull(pressureFL))
					pressureFL := tyres["Tyre.Pressure.Front.Left"]
				if (isNull(pressureFR))
					pressureFR := tyres["Tyre.Pressure.Front.Right"]
				if (isNull(pressureRL))
					pressureRL := tyres["Tyre.Pressure.Rear.Left"]
				if (isNull(pressureRR))
					pressureRR := tyres["Tyre.Pressure.Rear.Right"]

				lapData["Tyre.Pressure.Hot.Front.Left"] := null(pressureFL)
				lapData["Tyre.Pressure.Hot.Front.Right"] := null(pressureFR)
				lapData["Tyre.Pressure.Hot.Rear.Left"] := null(pressureRL)
				lapData["Tyre.Pressure.Hot.Rear.Right"] := null(pressureRR)
				lapData["Tyre.Pressure.Hot.Average"] := null(average([pressureFL, pressureFR, pressureRL, pressureRR]))
				lapData["Tyre.Pressure.Hot.Front.Average"] := null(average([pressureFL, pressureFR]))
				lapData["Tyre.Pressure.Hot.Rear.Average"] := null(average([pressureRL, pressureRR]))

				pressureLossFL := pressures["Tyre.Pressure.Loss.Front.Left"]
				pressureLossFR := pressures["Tyre.Pressure.Loss.Front.Right"]
				pressureLossRL := pressures["Tyre.Pressure.Loss.Rear.Left"]
				pressureLossRR := pressures["Tyre.Pressure.Loss.Rear.Right"]

				lapData["Tyre.Pressure.Loss.Front.Left"] := null(pressureLossFL)
				lapData["Tyre.Pressure.Loss.Front.Right"] := null(pressureLossFR)
				lapData["Tyre.Pressure.Loss.Rear.Left"] := null(pressureLossRL)
				lapData["Tyre.Pressure.Loss.Rear.Right"] := null(pressureLossRR)

				tyres := tyresTable[newLap]

				lapData["Tyre.Laps"] := null(tyres["Tyre.Laps"])

				temperatureFL := tyres["Tyre.Temperature.Front.Left"]
				temperatureFR := tyres["Tyre.Temperature.Front.Right"]
				temperatureRL := tyres["Tyre.Temperature.Rear.Left"]
				temperatureRR := tyres["Tyre.Temperature.Rear.Right"]

				lapData["Tyre.Temperature.Front.Left"] := null(temperatureFL)
				lapData["Tyre.Temperature.Front.Right"] := null(temperatureFR)
				lapData["Tyre.Temperature.Rear.Left"] := null(temperatureRL)
				lapData["Tyre.Temperature.Rear.Right"] := null(temperatureRR)
				lapData["Tyre.Temperature.Average"] := null(average([temperatureFL, temperatureFR, temperatureRL, temperatureRR]))
				lapData["Tyre.Temperature.Front.Average"] := null(average([temperatureFL, temperatureFR]))
				lapData["Tyre.Temperature.Rear.Average"] := null(average([temperatureRL, temperatureRR]))

				wearFL := tyres["Tyre.Wear.Front.Left"]
				wearFR := tyres["Tyre.Wear.Front.Right"]
				wearRL := tyres["Tyre.Wear.Rear.Left"]
				wearRR := tyres["Tyre.Wear.Rear.Right"]

				lapData["Tyre.Wear.Front.Left"] := null(wearFL)
				lapData["Tyre.Wear.Front.Right"] := null(wearFR)
				lapData["Tyre.Wear.Rear.Left"] := null(wearRL)
				lapData["Tyre.Wear.Rear.Right"] := null(wearRR)
				lapData["Tyre.Wear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR, wearRL, wearRR])))
				lapData["Tyre.Wear.Front.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR])))
				lapData["Tyre.Wear.Rear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearRL, wearRR])))

				if lap.HasProp("Data") {
					telemetry := parseMultiMap(lap.Data)

					if (telemetry.Count > 0) {
						brakeTemperatures := string2Values(",", getMultiMapValue(telemetry, "Car Data", "BrakeTemperature", ""))

						if (brakeTemperatures.Length = 4) {
							temperatureFL := brakeTemperatures[1]
							temperatureFR := brakeTemperatures[2]
							temperatureRL := brakeTemperatures[3]
							temperatureRR := brakeTemperatures[4]

							lapData["Brake.Temperature.Front.Left"] := null(temperatureFL)
							lapData["Brake.Temperature.Front.Right"] := null(temperatureFR)
							lapData["Brake.Temperature.Rear.Left"] := null(temperatureRL)
							lapData["Brake.Temperature.Rear.Right"] := null(temperatureRR)
							lapData["Brake.Temperature.Average"] := null(average([temperatureFL, temperatureFR, temperatureRL, temperatureRR]))
							lapData["Brake.Temperature.Front.Average"] := null(average([temperatureFL, temperatureFR]))
							lapData["Brake.Temperature.Rear.Average"] := null(average([temperatureRL, temperatureRR]))
						}
						else
							for ignore, field in ["Brake.Temperature.Front.Left", "Brake.Temperature.Front.Right", "Brake.Temperature.Rear.Left", "Brake.Temperature.Rear.Right"
												, "Brake.Temperature.Average", "Brake.Temperature.Front.Average", "Brake.Temperature.Rear.Average"]
								lapData[field] := kNull

						brakeWears := string2Values(",", getMultiMapValue(telemetry, "Car Data", "BrakeWear", ""))

						if (brakeWears.Length = 4) {
							wearFL := brakeWears[1]
							wearFR := brakeWears[2]
							wearRL := brakeWears[3]
							wearRR := brakeWears[4]

							lapData["Brake.Wear.Front.Left"] := null(wearFL)
							lapData["Brake.Wear.Front.Right"] := null(wearFR)
							lapData["Brake.Wear.Rear.Left"] := null(wearRL)
							lapData["Brake.Wear.Rear.Right"] := null(wearRR)
							lapData["Brake.Wear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR, wearRL, wearRR])))
							lapData["Brake.Wear.Front.Average"] := ((wearFL = kNull) ? kNull : null(average([wearFL, wearFR])))
							lapData["Brake.Wear.Rear.Average"] := ((wearFL = kNull) ? kNull : null(average([wearRL, wearRR])))
						}
						else
							for ignore, field in ["Brake.Wear.Front.Left", "Brake.Wear.Front.Right", "Brake.Wear.Rear.Left", "Brake.Wear.Rear.Right"
												, "Brake.Wear.Average", "Brake.Wear.Front.Average", "Brake.Wear.Rear.Average"]
								lapData[field] := kNull
					}
				}

				sessionStore.add("Lap.Data", lapData)

				newLap += 1
			}
		}

		if forSave {
			currentRun := this.CurrentRun

			if currentRun {
				sessionStore.clear("Run.Data")
				newRun := 1

				while (newRun <= currentRun.Nr) {
					if this.Runs.Has(newRun) {
						run := this.Runs[newRun]

						runData := Database.Row("Nr", newRun, "Lap", run.Lap
											  , "Driver.Forname", run.Driver.Forname, "Driver.Surname", run.Driver.Surname
											  , "Driver.Nickname", run.Driver.Nickname, "Driver.ID", run.ID
											  , "Weather", run.Weather
											  , "Tyre.Compound", compound(run.Compound), "Tyre.Compound.Color", compoundColor(run.Compound)
											  , "Tyre.Set", run.TyreSet, "Tyre.Laps", run.TyreLaps
											  , "Lap.Time.Average", null(run.AvgLaptime), "Lap.Time.Best", null(run.BestLapTime)
											  , "Fuel.Amount", null(run.FuelAmount), , "Fuel.Consumption", null(run.FuelConsumption)
											  , "Accidents", run.Accidents
											  , "Time.Start", this.computeStartTime(run), "Time.End", this.computeEndTime(run))

						sessionStore.add("Run.Data", runData)
					}

					newRun += 1
				}
			}

			sessionStore.flush()
		}
	}

	reportSettings(report) {
		switch report, false {
			case "Overview":
				if this.editOverviewReportSettings()
					this.showOverviewReport()
			case "Drivers":
				if this.editDriverReportSettings()
					this.showDriverReport()
			case "Positions":
				if this.editPositionsReportSettings()
					this.showPositionsReport()
			case "Lap Times":
				if this.editLapTimesReportSettings()
					this.showLapTimesReport()
			case "Consistency":
				if this.editConsistencyReportSettings()
					this.showConsistencyReport()
			case "Pace":
				if this.editPaceReportSettings()
					this.showPaceReport()
			case "Performance":
				if this.editPerformanceReportSettings()
					this.showPerformanceReport()
			case "Pressures":
				if this.editPressuresReportSettings()
					this.showPressuresReport()
			case "Brakes":
				if this.editBrakesReportSettings()
					this.showBrakesReport()
			case "Temperatures":
				if this.editTemperaturesReportSettings()
					this.showTemperaturesReport()
			case "Free":
				if this.editCustomReportSettings()
					this.showCustomReport()
		}
	}

	showReport(report, force := false) {
		showReportAsync(report) {
			this.updateSeriesSelector(report)

			if (report = "Track")
				this.showTrackMap()
			else if inList(kRaceReports, report)
				this.showRaceReport(report)
			else if (report = "Pressures")
				this.showPressuresReport()
			else if (report = "Brakes")
				this.showBrakesReport()
			else if (report = "Temperatures")
				this.showTemperaturesReport()
			else if (report = "Free")
				this.showCustomReport()
		}

		if (force || (report != this.SelectedReport)) {
			this.pushTask(ObjBindMethod(this, "syncSessionStore"))

			this.pushTask(showReportAsync.Bind(report))
		}
	}

	selectChartType(chartType, force := false) {
		if (force || (chartType != this.SelectedChartType)) {
			this.Control["chartTypeDropDown"].Choose(inList(["Scatter", "Bar", "Bubble", "Line"], chartType))

			this.iSelectedChartType := chartType

			this.showTelemetryReport()
		}
	}

	createRunHeader(run) {
		local startTime := this.computeStartTime(run)
		local endTime := this.computeEndTime(run)
		local duration := 0
		local ignore, lap, html

		for ignore, lap in run.Laps
			duration += lap.Laptime

		if startTime
			startTime := FormatTime(startTime, "Time")
		else
			startTime := "-"

		if endTime
			endTime := FormatTime(endTime, "Time")
		else
			endTime := "-"

		html := "<table>"
		html .= ("<tr><td><b>" . translate("Driver:") . "</b></div></td><td>" . StrReplace(run.Driver.FullName, "'", "\'") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Start:") . "</b></div></td><td>" . startTime . "</td></tr>")
		html .= ("<tr><td><b>" . translate("End:") . "</b></div></td><td>" . endTime . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Duration:") . "</b></div></td><td>" . Round(duration / 60) . A_Space . translate("Minutes") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Start Position:") . "</b></div></td><td>" . run.StartPosition . "</td></tr>")
		html .= ("<tr><td><b>" . translate("End Position:") . "</b></div></td><td>" . run.EndPosition . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Temperatures (A / T):") . "</b></td><td>" . displayValue("Float", convertUnit("Temperature", run.AirTemperature)) . ", " . displayValue("Float", convertUnit("Temperature", run.TrackTemperature)) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Consumption:") . "</b></div></td><td>" . displayValue("Float", convertUnit("Volume", run.FuelConsumption)) . "</td></tr>")
		html .= "</table>"

		return html
	}

	createLapDetailsChart(chartID, width, height, lapSeries, positionSeries, lapTimeSeries, fuelSeries, tempSeries) {
		local drawChartFunction := ("function drawChart" . chartID . "() {`nvar data = new google.visualization.DataTable();")
		local ignore, time, fuel, temperature

		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Position") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap Time") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Consumption") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Tyre Temperatures") . "');")

		drawChartFunction .= "`ndata.addRows(["

		for ignore, time in lapSeries {
			if (A_Index > 1)
				drawChartFunction .= ", "

			fuel := fuelSeries[A_Index]

			if isNumber(fuel)
				fuel := convertUnit("Volume", fuel)

			temperature := tempSeries[A_Index]

			if isNumber(temperature)
				temperature := convertUnit("Temperature", temperature)

			drawChartFunction .= ("[" . values2String(", ", lapSeries[A_Index]
														  , chartValue(null(positionSeries[A_Index]))
														  , chartValue(null(lapTimeSeries[A_Index]))
														  , chartValue(null(fuel))
														  , chartValue(null(temperature)))
								. "]")
		}

		drawChartFunction .= ("]);`nvar options = { legend: { position: 'Right' }, chartArea: { left: '10%', top: '5%', right: '25%', bottom: '20%' }, hAxis: { title: '" . translate("Lap") . "', gridlines: {count: 0} }, vAxis: { viewWindow: { min: 0 }, gridlines: {count: 0} }, backgroundColor: '" . this.Window.AltBackColor . "' };`n")

		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return drawChartFunction
	}

	createRunPerformanceChart(chartID, width, height, run) {
		local drawChartFunction := ""
		local minValue, maxValue

		this.updateRunStatistics(run)

		drawChartFunction .= "function drawChart" . chartID . "() {"
		drawChartFunction .= "`nvar data = google.visualization.arrayToDataTable(["
		drawChartFunction .= "`n['" . values2String("', '", translate("Category"), StrReplace(run.Driver.FullName, "'", "\'")) . "'],"

		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Potential") . "'", run.Potential) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Race Craft") . "'", run.RaceCraft) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Speed") . "'", run.Speed) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Consistency") . "'", run.Consistency) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Car Control") . "'", run.CarControl) . "]"

		drawChartFunction .= ("`n]);")

		minValue := Min(0, run.Potential, run.RaceCraft, run.Speed, run.Consistency, run.CarControl)
		maxValue := Max(run.Potential, run.RaceCraft, run.Speed, run.Consistency, run.CarControl)

		drawChartFunction := drawChartFunction . "`nvar options = { bars: 'horizontal', legend: 'none', backgroundColor: '" . this.Window.AltBackColor . "', chartArea: { left: '20%', top: '5%', right: '10%', bottom: '10%' }, hAxis: {viewWindowMode: 'explicit', viewWindow: {min: " . minValue . ", max: " . maxValue . "}, gridlines: {count: 0} }, vAxis: {gridlines: {count: 0}} };"
		drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BarChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }"

		return drawChartFunction
	}

	createRunConsistencyChart(chartID, width, height, run, laps, lapTimes) {
		local drawChartFunction := "function drawChart" . chartID . "() {"
		local validLaps := []
		local validTimes := []
		local ignore, lap, time, theMin, avg, theMax, delta, window, consistency, time, title

		for ignore, lap in laps {
			if (A_Index > 1) {
				time := lapTimes[A_Index]

				if isNumber(time) {
					validLaps.Push(lap)
					validTimes.Push(time)
				}
			}
		}

		drawChartFunction .= "`nvar data = google.visualization.arrayToDataTable(["

		drawChartFunction .= "`n['" . values2String("', '", translate("Lap"), translate("Lap Time")
														  , translate("Max"), translate("Avg"), translate("Min"))
						   . "']"

		theMin := minimum(validTimes)
		avg := average(validTimes)
		theMax := maximum(validTimes)

		for ignore, lap in validLaps
			drawChartFunction .= ",`n[" . values2String(", ", lap, validTimes[A_Index], theMax, avg, theMin) . "]"

		drawChartFunction .= ("`n]);")

		delta := (theMax - theMin)

		theMin := Max(avg - (3 * delta), 0)
		theMax := Min(avg + (2 * delta), theMax)

		if (theMin = 0)
			theMin := (avg / 3)

		window := ("baseline: " . theMin . ", viewWindow: {min: " . theMin . ", max: " . theMax . "}, ")
		consistency := 0

		for ignore, time in validTimes
			consistency += (100 - Abs(avg - time))

		consistency := Round(consistency / ((validTimes.Length = 0) ? 0.01 : validTimes.Length), 2)

		title := ("title: '" . translate("Consistency: ") . consistency . translate(" %") . "', titleTextStyle: {bold: false}, ")

		drawChartFunction .= ("`nvar options = {" . title . "seriesType: 'bars', series: {1: {type: 'line'}, 2: {type: 'line'}, 3: {type: 'line'}}, backgroundColor: '#" . this.Window.AltBackColor . "', vAxis: {" . window . "title: '" . translate("Lap Time") . "', gridlines: {count: 0}}, hAxis: {title: '" . translate("Laps") . "', gridlines: {count: 0}}, chartArea: { left: '20%', top: '15%', right: '15%', bottom: '15%' } };")

		drawChartFunction .= ("`nvar chart = new google.visualization.ComboChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return drawChartFunction
	}

	createLapDetails(run) {
		local html := "<table>"
		local lapData := []
		local mapData := []
		local lapTimeData := []
		local fuelConsumptionData := []
		local accidentData := []
		local penaltyData := []
		local ignore, lap, fuelConsumption

		html .= ("<tr><td><b>" . translate("Average:") . "</b></td><td>" . lapTimeDisplayValue(run.AvgLapTime) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Best:") . "</b></td><td>" . lapTimeDisplayValue(run.BestLapTime) . "</td></tr>")
		html .= "</table>"

		for ignore, lap in run.Laps {
			lapData.Push("<th class=`"th-std`">" . lap.Nr . "</th>")
			mapData.Push("<td class=`"td-std`">" . lap.Map . "</td>")
			lapTimeData.Push("<td class=`"td-std`">" . lapTimeDisplayValue(lap.Laptime) . "</td>")

			fuelConsumption := lap.FuelConsumption

			if isNumber(fuelConsumption)
				fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

			penalty := ""

			if lap.Penalty {
				penalty := lap.Penalty

				if (InStr(penalty, "SG") = 1) {
					penalty := ((StrLen(penalty) > 2) ? (A_Space . SubStr(penalty, 3)) : "")

					penalty := (translate("Stop and Go") . penalty)
				}
				else if (penalty = "Time")
					penalty := translate("Time")
				else if (penalty = "DT")
					penalty := translate("Drive Through")
				else if (penalty == true)
					penalty := "x"
			}

			fuelConsumptionData.Push("<td class=`"td-std`">" . displayNullValue(fuelConsumption) . "</td>")
			accidentData.Push("<td class=`"td-std`">" . (lap.Accident ? "x" : "") . "</td>")
			penaltyData.Push("<td class=`"td-std`">" . penalty . "</td>")
		}

		html .= "<br><table class=`"table-std`">"

		html .= ("<tr><th class=`"th-std`">" . translate("Lap") . "</th>"
				   . "<th class=`"th-std`">" . translate("Map") . "</th>"
				   . "<th class=`"th-std`">" . translate("Lap Time") . "</th>"
				   . "<th class=`"th-std`">" . translate("Consumption") . "</th>"
				   . "<th class=`"th-std`">" . translate("Accident") . "</th>"
				   . "<th class=`"th-std`">" . translate("Penalty") . "</th>"
			   . "</tr>")

		loop lapData.Length
			html .= ("<tr>" . lapData[A_Index]
							. mapData[A_Index]
							. lapTimeData[A_Index]
							. fuelConsumptionData[A_Index]
							. accidentData[A_Index]
							. penaltyData[A_Index]
				   . "</tr>")

		html .= "</table>"

		return html
	}

	showRunDetails(run) {
		showRunDetailsAsync(run) {
			local html := ("<div id=`"header`"><b>" . translate("Run: ") . run.Nr . "</b></div>")
			local laps := []
			local positions := []
			local lapTimes := []
			local fuelConsumptions := []
			local temperatures := []
			local lapTable := this.SessionStore.Tables["Lap.Data"]
			local ignore, lap, width, chart1, chart2, chart3

			html .= ("<br><br><div id=`"header`"><i>" . translate("Overview") . "</i></div>")

			html .= ("<br>" . this.createRunHeader(run))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Laps") . "</i></div>")

			html .= ("<br>" . this.createLapDetails(run))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Telemetry") . "</i></div>")

			for ignore, lap in run.Laps {
				laps.Push(lap.Nr)
				positions.Push(lap.Position)
				lapTimes.Push(lap.Laptime)
				fuelConsumptions.Push(lap.FuelConsumption)
				temperatures.Push(lapTable[lap.Nr]["Tyre.Temperature.Average"])
			}

			width := (this.DetailsViewer.getWidth() - 20)

			chart1 := this.createLapDetailsChart(1, width, 248, laps, positions, lapTimes, fuelConsumptions, temperatures)

			html .= ("<br><br><div id=`"chart_1`" style=`"width: " . width . "px; height: 248px`"></div>")

			html .= ("<br><br><div id=`"header`"><i>" . translate("Statistics") . "</i></div>")

			chart2 := this.createRunPerformanceChart(2, width, 248, run)

			html .= ("<br><div id=`"chart_2`" style=`"width: " . width . "px; height: 248px`"></div>")

			html .= ("<br><br><div id=`"header`"><i>" . translate("Consistency") . "</i></div>")

			chart3 := this.createRunConsistencyChart(3, width, 248, run, laps, lapTimes)

			html .= ("<br><div id=`"chart_3`" style=`"width: " . width . "px; height: 248px`"></div>")

			this.showDetails("Run", html, [1, chart1], [2, chart2], [3, chart3])
		}

		this.pushTask(ObjBindMethod(this, "syncSessionStore"))

		this.pushTask(showRunDetailsAsync.Bind(run))
	}

	createLapOverview(lap) {
		local html := "<table>"
		local hotPressures := "-, -, -, -"
		local coldPressures := "-, -, -, -"
		local pressuresLosses := "-, -, -, -"
		local hasColdPressures := false
		local pressuresDB := this.PressuresDatabase
		local pressuresTable, pressures, coldPressures, hotPressures, pressuresLosses, tyresTable, tyres
		local fuel, tyreCompound, tyreCompoundColor, tyreSet, tyrePressures, pressureCorrections, pressure
		local fuelConsumption, remainingFuel

		if pressuresDB {
			pressuresTable := pressuresDB.Database.Tables["Tyres.Pressures"]

			if (pressuresTable.Length >= lap.Nr) {
				pressures := pressuresTable[lap.Nr]

				coldPressures := [displayNullValue(pressures["Tyre.Pressure.Cold.Front.Left"]), displayNullValue(pressures["Tyre.Pressure.Cold.Front.Right"])
								, displayNullValue(pressures["Tyre.Pressure.Cold.Rear.Left"]), displayNullValue(pressures["Tyre.Pressure.Cold.Rear.Right"])]

				this.getRunSetup(lap.Run.Nr, true, &fuel, &tyreCompound, &tyreCompoundColor, &tyreSet, &tyrePressures)

				if tyrePressures {
					loop 4 {
						coldPressure := coldPressures[A_Index]

						if (coldPressure != "-") {
							tyrePressures[A_Index] := Round(coldPressure - tyrePressures[A_Index], 1)

							if (tyrePressures[A_Index] = 0)
								tyrePressures[A_Index] := displayNullValue(kNull)
							else if (tyrePressures[A_Index] > 0)
								tyrePressures[A_Index] := ("+ " . displayValue("Float", convertUnit("Pressure", tyrePressures[A_Index])))
							else if (tyrePressures[A_Index] < 0)
								tyrePressures[A_Index] := ("- " . displayValue("Float", convertUnit("Pressure", Abs(tyrePressures[A_Index]))))

							hasColdPressures := true
						}
						else
							tyrePressures[A_Index] := displayNullValue(kNull)
					}

					pressureCorrections := (translate(" (") . values2String(", ", tyrePressures*) . translate(")"))
				}
				else
					pressureCorrections := ""

				loop 4 {
					pressure := coldPressures[A_Index]

					if isNumber(pressure)
						coldPressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				coldPressures := values2String(", ", coldPressures*)

				hasColdPressures := (hasColdPressures || (coldPressures != "-, -, -, -"))

				coldPressures := (coldPressures . pressureCorrections)

				hotPressures := [displayNullValue(pressures["Tyre.Pressure.Hot.Front.Left"]), displayNullValue(pressures["Tyre.Pressure.Hot.Front.Right"])
							   , displayNullValue(pressures["Tyre.Pressure.Hot.Rear.Left"]), displayNullValue(pressures["Tyre.Pressure.Hot.Rear.Right"])]

				loop 4 {
					pressure := hotPressures[A_Index]

					if isNumber(pressure)
						hotPressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				hotPressures := values2String(", ", hotPressures*)

				pressuresLosses := [displayNullValue(pressures["Tyre.Pressure.Loss.Front.Left"]), displayNullValue(pressures["Tyre.Pressure.Loss.Front.Right"])
								  , displayNullValue(pressures["Tyre.Pressure.Loss.Rear.Left"]), displayNullValue(pressures["Tyre.Pressure.Loss.Rear.Right"])]

				loop 4 {
					pressure := pressuresLosses[A_Index]

					if isNumber(pressure)
						pressuresLosses[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
				}

				pressuresLosses := values2String(", ", pressuresLosses*)

				if (hotPressures = "-, -, -, -") {
					tyresTable := this.TelemetryDatabase.Database.Tables["Tyres"]

					if (tyresTable.Length >= lap.Nr) {
						tyres := tyresTable[lap.Nr]

						hotPressures := [displayNullValue(tyres["Tyre.Pressure.Front.Left"]), displayNullValue(tyres["Tyre.Pressure.Front.Right"])
									   , displayNullValue(tyres["Tyre.Pressure.Rear.Left"]), displayNullValue(tyres["Tyre.Pressure.Rear.Right"])]

						loop 4 {
							pressure := hotPressures[A_Index]

							if isNumber(pressure)
								hotPressures[A_Index] := displayValue("Float", convertUnit("Pressure", pressure))
						}

						hotPressures := values2String(", ", hotPressures*)
					}
				}
			}
		}

		remainingFuel := lap.FuelRemaining

		if isNumber(remainingFuel)
			remainingFuel := displayValue("Float", convertUnit("Volume", remainingFuel))

		fuelConsumption := lap.FuelConsumption

		if isNumber(fuelConsumption)
			fuelConsumption := displayValue("Float", convertUnit("Volume", fuelConsumption))

		html .= ("<tr><td><b>" . translate("Position:") . "</b></td><td>" . lap.Position . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Lap Time:") . "</b></td><td>" . lapTimeDisplayValue(lap.LapTime) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Consumption:") . "</b></td><td>" . displayNullValue(fuelConsumption) . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Fuel Level:") . "</b></td><td>" . remainingFuel . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Temperatures (A / T):") . "</b></td><td>" . displayValue("Float", convertUnit("Temperature", lap.AirTemperature)) . ", " . displayValue("Float", convertUnit("Temperature", lap.TrackTemperature)) . "</td></tr>")

		if (hotPressures != "-, -, -, -")
			html .= ("<tr><td><b>" . translate("Pressures (hot):") . "</b></td><td>" . hotPressures . "</td></tr>")

		if hasColdPressures
			html .= ("<tr><td><b>" . translate("Pressures (cold, recommended):") . "</b></td><td>" . coldPressures . "</td></tr>")

		if (pressuresLosses != "-, -, -, -")
			html .= ("<tr><td><b>" . translate("Pressures (loss):") . "</b></td><td>" . pressuresLosses . "</td></tr>")

		html .= ("<tr><td></td><td></td></tr>")

		html .= "</table>"

		return html
	}

	createLapDeltas(lap, leaderColor := false, aheadColor := false, behindColor := false) {
		local sessionStore := this.SessionStore
		local html := "<table class=`"table-std`">"
		local labels := [translate("Leader"), translate("Standings (Ahead)"), translate("Standings (Behind)")
					   , translate("Track (Ahead)"), translate("Track (Behind)")]
		local rowIndices := CaseInsenseMap("Standings.Leader", 1, "Standings.Front", 2, "Standings.Ahead", 2, "Standings.Behind", 3
										 , "Track.Front", 4, "Track.Ahead", 4, "Track.Behind", 5)
		local telemetryDB := this.TelemetryDatabase
		local rows := [1, 2, 3, 4, 5]
		local deltas, ignore, entry, carNumber, carName, driverFullName, delta, row
		local driverForname, driverSurname, driverNickname, entryType, index, label
		local car, carID

		html .= ("<tr><th class=`"th-std`">" . "" . "</th>"
				   . "<th class=`"th-std`">" . translate("Nr.") . "</th>"
				   . "<th class=`"th-std`">" . translate("Driver") . "</th>"
				   . "<th class=`"th-std`">" . translate("Car") . "</th>"
				   . "<th class=`"th-std`">" . translate("Delta") . "</th>"
			   . "</tr>")

		deltas := sessionStore.query("Delta.Data", {Where: {Lap: lap.Nr}})

		if (deltas.Length > 0) {
			for ignore, entry in deltas {
				carNumber := "-"
				carName := "-"
				driverFullname := "-"
				delta := "-"

				if ((entry["Car"] && (entry["Car"] != kNull)) || (entry["ID"] && (entry["ID"] != kNull))) {
					driverForname := false
					driverSurname := false
					driverNickname := false

					car := entry["Car"]

					if this.getCar(lap, (entry["ID"] != kNull) ? entry["ID"] : false, &car, &carNumber, &carName, &driverForname, &driverSurname, &driverNickname) {
						driverFullname := computeDriverName(driverForname, driverSurname, driverNickname)

						delta := entry["Delta"]
					}
				}

				entryType := entry["Type"]

				index := rowIndices[entryType]

				if (leaderColor && (entryType = "Standings.Leader"))
					label := ("<p style=`"color:#" . leaderColor . "`";>" . labels[index] . "</p>")
				else if (aheadColor && ((entryType = "Standings.Front") || (entryType = "Standings.Ahead")))
					label := ("<p style=`"color:#" . aheadColor . "`";>" . labels[index] . "</p>")
				else if (behindColor && (entryType = "Standings.Behind"))
					label := ("<p style=`"color:#" . behindColor . "`";>" . labels[index] . "</p>")
				else
					label := labels[index]

				rows[index] := ("<tr><th class=`"th-std th-left`">" . label . "</th>"
							  . "<td class=`"td-std`">" . values2String("</td><td class=`"td-std`">" , carNumber, driverFullname, telemetryDB.getCarName(this.Simulator, carName), delta)
							  . "</td></tr>")
			}

			for ignore, row in rows
				html .= row
		}

		html .= "</table>"

		return html
	}

	createLapStandings(lap) {
		local sessionStore := this.SessionStore
		local telemetryDB := this.TelemetryDatabase
		local html := "<table class=`"table-std`">"
		local lapNr := lap.Nr
		local cars := true
		local carIDs := true
		local overallPositions := true
		local classPositions := true
		local carNumbers := true
		local carNames := true
		local driverFornames := true
		local driverSurnames := true
		local driverNicknames := true
		local driverCategories := (this.ReportViewer.Settings.Has("DriverCategories") && this.ReportViewer.Settings["DriverCategories"])
		local index, position, lapTime, laps, delta, result, multiClass, numPitstops, ignore, pitstop, pitstops, pitstopLaps

		multiClass := this.getStandings(lap, &cars, &carIDs, &overallPositions, &classPositions, &carNumbers, &carNames
										   , &driverFornames, &driverSurnames, &driverNicknames, &driverCategories)

		html .= ("<tr><th class=`"th-std`">" . translate("#") . "</th>"
				   . "<th class=`"th-std`">" . translate("Nr.") . "</th>"
				   . "<th class=`"th-std`">" . translate("Driver") . "</th>"
				   . "<th class=`"th-std`">" . translate("Car") . "</th>")

		if multiClass
			html .= ("<th class=`"th-std`">" . translate("Position") . "</th>")

		html .= ("<th class=`"th-std`">" . translate("Lap Time") . "</th>"
			   . "<th class=`"th-std`">" . translate("Laps") . "</th>"
			   . "<th class=`"th-std`">" . translate("Delta") . "</th>"
			   . "<th class=`"th-std`">" . translate("Pitstops") . "</th>"
			   . "</tr>")

		for index, position in overallPositions
			if (position && carIDs.Has(index)) {
				lapTime := "-"
				laps := "-"
				delta := "-"

				result := sessionStore.query("Standings.Data", {Select: ["Time", "Laps", "Delta"], Where: {Lap: lap.Nr, ID: carIDs[index]}})

				if (result.Length = 0)
					result := sessionStore.query("Standings.Data", {Select: ["Time", "Laps", "Delta"], Where: {Lap: lap.Nr, Car: cars[index]}})

				if (result.Length > 0) {
					lapTime := result[1]["Time"]
					laps := result[1]["Laps"]
					delta := Round(result[1]["Delta"], 1)
				}

				driver := computeDriverName(driverFornames[index] , driverSurnames[index], driverNickNames[index])

				if (driverCategories && (driverCategories[index] != "Unknown"))
					driver .= (translate(" [") . translate(driverCategories[index]) . translate("]"))

				html .= ("<tr><th class=`"th-std`">" . position . "</th>")
				html .= ("<td class=`"td-std`">" . values2String("</td><td class=`"td-std`">", carNumbers[index], driver
																							 , telemetryDB.getCarName(this.Simulator, carNames[index]))
					   . "</td>")

				if multiClass
					html .= ("<td class=`"td-std`">" . classPositions[index] . "</td>")

				html .= ("<td class=`"td-std`">" . values2String("</td><td class=`"td-std`">", lapTimeDisplayValue(lapTime), laps, delta) . "</td>")

				pitstops := this.Pitstops[carIDs[index]]
				numPitstops := 0

				if (pitstops.Length > 0) {
					pitstopLaps := []

					for ignore, pitstop in pitstops
						if (pitstop.Lap <= lapNr) {
							numPitstops += 1

							pitstopLaps.Push(pitstop.Lap)

							if (pitstopLaps.Length > 3)
								pitstopLaps.RemoveAt(1)
						}

					if (numPitstops > 0) {
						pitstops := (numPitstops . translate(":   ["))

						if (numPitstops > 3)
							pitstops .= (translate("...") . translate(", "))

						pitstops .= (values2String(", ", pitstopLaps*) . translate("]"))
					}
					else
						pitstops := "-"
				}
				else
					pitstops := "-"

				html .= ("<td class=`"td-std td-left`">" . pitstops . "</td></tr>")
			}

		html .= "</table>"

		return html
	}

	showLapDetails(lap) {
		showLapDetailsAsync(lap) {
			local html := ("<div id=`"header`"><b>" . translate("Lap: ") . lap.Nr . "</b></div>")

			this.initializeReports()

			html .= ("<br><br><div id=`"header`"><i>" . translate("Overview") . "</i></div>")

			html .= ("<br>" . this.createLapOverview(lap))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Deltas") . "</i></div>")

			html .= ("<br>" . this.createLapDeltas(lap))

			html .= ("<br><br><div id=`"header`"><i>" . translate("Standings") . "</i></div>")

			html .= ("<br>" . this.createLapStandings(lap))

			this.showDetails("Lap", html)
		}

		this.pushTask(ObjBindMethod(this, "syncSessionStore"))

		this.pushTask(showLapDetailsAsync.Bind(lap))
	}

	updateLap(lapNumber, fileName) {
		updateLapAsync() {
			local data := readMultiMap(fileName)

			try {
				if (this.SessionMode && this.SessionMode != "Active")
					return

				if ((!this.LastLap && (lapNumber = 1)) || ((this.LastLap.Nr + 1) = lapNumber)) {
					this.iSessionMode := "Active"

					this.addLap(lapNumber, data)
				}
			}
			finally {
				deleteFile(fileName)
			}
		}

		this.pushTask(updateLapAsync)
	}

	updateReportData(lapNumber, fileName) {
		updateReportDataAsync() {
			try {
				if ((this.SessionMode = "Active") && (this.LastLap.Nr = lapNumber)) {
					DirCreate(this.SessionDirectory . "Race Report")

					FileCopy(fileName, this.SessionDirectory . "Race Report\Race.data", 1)

					this.initializeReports()
				}
			}
			finally {
				deleteFile(fileName)
			}
		}

		this.pushTask(updateReportDataAsync)
	}

	updateReportLap(lapNumber, fileName) {
		updateReportLapAsync() {
			local raceData, lapData, directory, key, value, newLine, line
			local pitstops, times, positions, laps, drivers

			if ((this.SessionMode = "Active") && (this.LastLap.Nr = lapNumber)) {
				directory := (this.SessionDirectory . "Race Report\")

				raceData := readMultiMap(directory . "Race.data")
				lapData := readMultiMap(fileName)

				deleteFile(fileName)

				if (getMultiMapValue(raceData, "Cars", "Count") = kNotInitialized)
					setMultiMapValue(raceData, "Cars", "Count", 0)

				if (getMultiMapValue(raceData, "Cars", "Driver") = kNotInitialized)
					setMultiMapValue(raceData, "Cars", "Driver", 0)

				if (lapData.Count == 0)
					return

				for key, value in getMultiMapValues(lapData, "Lap")
					setMultiMapValue(raceData, "Laps", key, value)

				pitstops := getMultiMapValue(lapData, "Pitstop", "Laps", "")

				setMultiMapValue(raceData, "Laps", "Pitstops", pitstops)

				times := getMultiMapValue(lapData, "Times", lapNumber)
				positions := getMultiMapValue(lapData, "Positions", lapNumber)
				laps := getMultiMapValue(lapData, "Laps", lapNumber)
				drivers := getMultiMapValue(lapData, "Drivers", lapNumber)

				newLine := ((lapNumber > 1) ? "`n" : "")

				line := (newLine . times)

				FileAppend(line, directory . "Times.CSV")

				line := (newLine . positions)

				FileAppend(line, directory . "Positions.CSV")

				line := (newLine . laps)

				FileAppend(line, directory . "Laps.CSV")

				line := (newLine . drivers)
				fileName := (directory . "Drivers.CSV")

				FileAppend(line, fileName, "UTF-16")

				removeMultiMapValue(raceData, "Laps", "Lap")
				setMultiMapValue(raceData, "Laps", "Count", lapNumber)

				writeMultiMap(directory . "Race.data", raceData)

				if (this.LapsListView.GetCount() && (this.SelectedDetailReport = "Lap")) {
					this.LapsListView.Modify(this.LapsListView.GetCount(), "Select Vis")

					this.showLapDetails(this.LastLap)
				}

				this.updateReports()
				this.updateState()
			}
		}

		this.pushTask(updateReportLapAsync)
	}

	updateStandings(lapNumber, fileName) {
		if (this.SessionMode = "Active") {
		}

		deleteFile(fileName)
	}

	updateTelemetry(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
				  , fuelConsumption, fuelRemaining, lapTime, pitstop, map, tc, abs
				  , compound, compoundColor, pressures, temperatures, wear) {
		udateTelemetryAsync() {
			if ((this.SessionMode = "Active") && (this.LastLap.Nr = lapNumber))
				this.addTelemetry(this.LastLap, simulator, car, track, weather, airTemperature, trackTemperature
								, fuelConsumption, fuelRemaining, lapTime, pitstop, map, tc, abs
								, compound, compoundColor, pressures, temperatures, wear)
		}

		this.pushTask(udateTelemetryAsync)
	}

	updatePressures(lapNumber, simulator, car, track, weather, airTemperature, trackTemperature
				  , compound, compoundColor, coldPressures, hotPressures, pressuresLosses) {
		updatePressuresAsync() {
			if ((this.SessionMode = "Active") && (this.LastLap.Nr = lapNumber))
				this.addPressures(this.LastLap, simulator, car, track, weather, airTemperature, trackTemperature
								, compound, compoundColor, coldPressures, hotPressures, pressuresLosses)
		}

		this.pushTask(updatePressuresAsync)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

getDeprecatedValue(data, section, newKey, oldKey, default := false) {
	local value := getMultiMapValue(data, section, newKey, kUndefined)

	if (value != kUndefined)
		return value
	else
		return getMultiMapValue(data, section, oldKey, default)
}

convertValue(name, value) {
	if (value = kNull)
		return value
	else if InStr(name, "Fuel")
		return convertUnit("Volume", value)
	else if InStr(name, "Temperature")
		return convertUnit("Temperature", value)
	else if InStr(name, "Pressure")
		return convertUnit("Pressure", value)
	else
		return value
}

lapTimeDisplayValue(lapTime) {
	if (lapTime = "-")
		return "-"
	else
		return RaceReportViewer.lapTimeDisplayValue(lapTime)
}

displayNullValue(value, null := "-") {
	return (isNull(value) ? null : value)
}

chartValue(value) {
	return (isNull(value) ? kNull : value)
}

null(value) {
	return (((value == 0) || (value == "-") || (value = "n/a")) ? kNull : valueOrNull(value))
}

startupPracticeCenter() {
	local icon := kIconsDirectory . "Practice.ico"
	local settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")
	local simulator := getMultiMapValue(settings, "Practice Center", "Simulator", false)
	local car := getMultiMapValue(settings, "Practice Center", "Car", false)
	local track := getMultiMapValue(settings, "Practice Center", "Track", false)
	local index := 1
	local pCenter

	TraySetIcon(icon, "1")
	A_IconTip := "Practice Center"

	while (index < A_Args.Length) {
		switch A_Args[index], false {
			case "-Simulator":
				simulator := A_Args[index + 1]
				index += 2
			case "-Car":
				car := A_Args[index + 1]
				index += 2
			case "-Track":
				track := A_Args[index + 1]
				index += 2
			default:
				index += 1
		}
	}

	pCenter := PracticeCenter(kSimulatorConfiguration, readMultiMap(kUserConfigDirectory . "Race.settings"), simulator, car, track)

	pCenter.createGui(pCenter.Configuration)

	pCenter.show()

	registerMessageHandler("Practice", methodMessageHandler, pCenter)
}


;;;-------------------------------------------------------------------------;;;
;;;                          Initialization Section                         ;;;
;;;-------------------------------------------------------------------------;;;

startupPracticeCenter()