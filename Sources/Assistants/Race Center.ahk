﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Race Center                     ;;;
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

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Console.ico
;@Ahk2Exe-ExeName Race Center.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\Math.ahk
#Include ..\Libraries\CLR.ahk
#Include Libraries\TelemetryDatabase.ahk
#Include Libraries\SetupDatabase.ahk
#Include Libraries\RaceReportViewer.ahk
#Include Libraries\Strategy.ahk
#Include Libraries\StrategyViewer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                   Private Constant Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global kClose = "Close"
global kConnect = "Connect"
global kEvent = "Event"

global kSessionReports = concatenate(kRaceReports, ["Pressures", "Temperatures", "Free"])
global kDetailReports = ["Plan", "Stint", "Lap", "Session", "Driver", "Strategy"]

global kSessionDataSchemas := {"Stint.Data": ["Nr", "Lap", "Driver.Forname", "Driver.Surname", "Driver.Nickname"
											, "Weather", "Compound", "Lap.Time.Average", "Lap.Time.Best", "Fuel.Consumption", "Accidents"
											, "Position.Start", "Position.End", "Time.Start"]
							 , "Driver.Data": ["Forname", "Surname", "Nickname"]
							 , "Lap.Data": ["Stint", "Nr", "Lap", "Lap.Time", "Position", "Grip", "Map", "TC", "ABS"
										  , "Weather", "Temperature.Air", "Temperature.Track"
										  , "Fuel.Remaining", "Fuel.Consumption", "Damage", "Accident"
										  , "Tyre.Laps", "Tyre.Compound", "Tyre.Compound.Color"
										  , "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
										  , "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right"
										  , "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
										  , "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
										  , "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right"
										  , "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
										  , "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
										  , "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right"
										  , "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"]
							 , "Pitstop.Data": ["Lap", "Fuel", "Tyre.Compound", "Tyre.Compound.Color", "Tyre.Set"
											  , "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right"
											  , "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
											  , "Repair.Bodywork", "Repair.Suspension"]
							 , "Delta.Data": ["Lap", "Car", "Type", "Delta", "Distance"]
							 , "Standings.Data": ["Lap", "Car", "Driver", "Position", "Time", "Laps", "Delta"]
							 , "Plan.Data": ["Stint", "Driver", "Time.Planned", "Time.Actual", "Lap.Planned", "Lap.Actual"
										   , "Fuel.Amount", "Tyre.Change"]}


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vToken := false
global vWait := 0


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global serverURLEdit
global serverTokenEdit
global teamDropDownMenu
global sessionDropDownMenu

global chartTypeDropDown
global chartViewer

global reportSettingsButton

global detailsViewer

global reportsListView

global dataXDropDown
global dataY1DropDown
global dataY2DropDown
global dataY3DropDown
global dataY4DropDown
global dataY5DropDown
global dataY6DropDown

global waitViewer

global sessionMenuDropDown
global strategyMenuDropDown
global planMenuDropDown
global pitstopMenuDropDown

global sessionDateCal
global sessionTimeEdit
global driverDropDownMenu
global planTimeEdit
global actTimeEdit
global planLapEdit
global actLapEdit
global planRefuelEdit
global planTyreCompoundDropDown

global addPlanButton
global deletePlanButton

global pitstopLapEdit
global pitstopRefuelEdit
global pitstopTyreCompoundDropDown
global pitstopTyreSetEdit
global pitstopPressureFLEdit
global pitstopPressureFREdit
global pitstopPressureRLEdit
global pitstopPressureRREdit
global pitstopRepairsDropDown

class RaceCenter extends ConfigurationItem {
	iClosed := false
	
	iSessionDirectory := false
	iRaceSettings := false
	
	iConnector := false
	iConnected := false
	
	iServerURL := ""
	iServerToken := "__INVALID__"
	
	iTeams := {}
	iSessions := {}
	iSessionDrivers := {}
	
	iTeamIdentifier := false
	iTeamName := false
	
	iSessionIdentifier := false
	iSessionName := false
	
	iSessionLoaded := false
	iSessionFinished := false

	iVersion := false
	iDate := false
	iTime := false
	
	iSimulator := false
	iCar := false
	iTrack := false
	iWeather := false
	iAirTemperature := false
	iTrackTemperature := false
	
	iTyreCompound := false
	iTyreCompoundColor := false
	
	iStrategy := false
	
	iUseSessionData := true
	iUseTelemetryDatabase := false
	iUseCurrentMap := true
	iUseTraffic := false
	
	iDrivers := []
	iStints := {}
	iLaps := {}
	
	iCurrentStint := false
	iLastLap := false

	iPlanListView := false
	iStintsListView := false
	iLapsListView := false
	iPitstopsListView := false
	
	iSessionDatabase := false
	iTelemetryDatabase := false
	iPressuresDatabase := false
	
	iReportViewer := false
	iSelectedReport := false
	iSelectedChartType := false
	
	iSelectedDetailReport := false
	
	iStrategyViewer := false
	
	class SessionStrategy extends Strategy {
		iVersion := false
		
		Version[] {
			Get {
				return this.iVersion
			}
		}
		
		__New(strategyManager, configuration := false) {
			base.__New(strategyManager, configuration)
		}
		
		setVersion(version) {
			this.iVersion := (version . "")
		}
		
		loadFromConfiguration(configuration) {
			base.loadFromConfiguration(configuration)
			
			this.iVersion := getConfigurationValue(configuration, "General", "Version", false)
		}
		
		saveToConfiguration(configuration) {
			base.saveToConfiguration(configuration)
			
			setConfigurationValue(configuration, "General", "Version", this.iVersion)
		}
	}
	
	class SessionTelemetryDatabase extends TelemetryDatabase {
		iRaceCenter := false
		iTelemetryDatabase := false
		
		__New(raceCenter, simulator := false, car := false, track := false) {
			this.iRaceCenter := raceCenter
			
			base.__New()
			
			this.setDatabase(new Database(raceCenter.SessionDirectory, kTelemetrySchemas))
			
			if simulator
				this.iTelemetryDatabase := new TelemetryDatabase(simulator, car, track)
		}
		
		getMapData(weather, compound, compoundColor) {
			entries := []
			
			if this.iRaceCenter.UseSessionData
				entries := base.getMapData(weather, compound, compoundColor)
			
			if this.iRaceCenter.UseTelemetryDatabase {
				newEntries := []
			
				for ignore, entry in this.iTelemetryDatabse.getMapData(weather, compound, compoundColor) {
					found := false
				
					for ignore, candidate in entries
						if ((candidate.Map = entry.Map) && (candidate["Lap.Time"] = entry["Lap.Time"])
														&& (candidate["Fuel.Consumption"] = entry["Fuel.Consumption"])) {
							found := true
						
							break
						}
					
					if !found
						newEntries.Push(entry)
				}
				
				for ignore, entry in newEntries
					entries.Push(entry)
			}
			
			if this.iRaceCenter.UseCurrentMap {
				lastLap := this.iRaceCenter.LastLap
				
				if lastLap {
					result := []
					
					for ignore, entry in entries
						if (entry.Map = lastLap.Map)
							result.Push(entry)
					
					return result
				}
			}
			
			return entries
		}
		
		getTyreData(weather, compound, compoundColor) {
			entries := []
			
			if this.iRaceCenter.UseSessionData
				entries := base.getTyreData(weather, compound, compoundColor)
			
			if this.iRaceCenter.UseTelemetryDatabase {
				newEntries := []
			
				for ignore, entry in this.iTelemetryDatabse.getTyreData(weather, compound, compoundColor) {
					found := false
				
					for ignore, candidate in entries
						if ((candidate["Tyre.Laps"] = entry["Tyre.Laps"]) && (candidate["Lap.Time"] = entry["Lap.Time"])) {
							found := true
						
							break
						}
					
					if !found
						newEntries.Push(entry)
				}
				
				for ignore, entry in newEntries
					entries.Push(entry)
			}
			
			return entries
		}
	}
	
	class SessionPressuresDatabase {
		iDatabase := false
		
		Database[] {
			Get {
				return this.iDatabase
			}
		}
		
		__New(rCenter) {
			this.iDatabase := new Database(rCenter.SessionDirectory, kSetupDataSchemas)
		}
		
		updatePressures(weather, airTemperature, trackTemperature, compound, compoundColor, coldPressures, hotPressures, flush := true) {
			if (!compoundColor || (compoundColor = ""))
				compoundColor := "Black"
			
			this.Database.add("Setup.Pressures", {Weather: weather, "Temperature.Air": airTemperature, "Temperature.Track": trackTemperature
												, Compound: compound, "Compound.Color": compoundColor
												, "Tyre.Pressure.Cold.Front.Left": null(coldPressures[1])
												, "Tyre.Pressure.Cold.Front.Right": null(coldPressures[2])
												, "Tyre.Pressure.Cold.Rear.Left": null(coldPressures[3])
												, "Tyre.Pressure.Cold.Rear.Right": null(coldPressures[4])
												, "Tyre.Pressure.Hot.Front.Left": null(hotPressures[1])
												, "Tyre.Pressure.Hot.Front.Right": null(hotPressures[2])
												, "Tyre.Pressure.Hot.Rear.Left": null(hotPressures[3])
												, "Tyre.Pressure.Hot.Rear.Right": null(hotPressures[4])}
												, flush)
			
			tyres := ["FL", "FR", "RL", "RR"]
			types := ["Cold", "Hot"]
			
			for typeIndex, tPressures in [coldPressures, hotPressures]
				for tyreIndex, pressure in tPressures
					this.updatePressure(weather, airTemperature, trackTemperature, compound, compoundColor
									  , types[typeIndex], tyres[tyreIndex], pressure, 1, flush, false)
		}
		
		updatePressure(weather, airTemperature, trackTemperature, compound, compoundColor
					 , type, tyre, pressure, count := 1, flush := true) {
			if (null(pressure) == kNull)
				return
			
			if (!compoundColor || (compoundColor = ""))
				compoundColor := "Black"
			
			rows := this.Database.query("Setup.Pressures.Distribution"
									  , {Where: {Weather: weather, "Temperature.Air": airTemperature, "Temperature.Track": trackTemperature
											   , Compound: compound, "Compound.Color": compoundColor, Type: type, Tyre: tyre, "Pressure": pressure}})
			
			if (rows.Length() > 0)
				rows[1].Count := rows[1].Count + count
			else
				this.Database.add("Setup.Pressures.Distribution"
								, {Weather: weather, "Temperature.Air": airTemperature, "Temperature.Track": trackTemperature
								 , Compound: compound, "Compound.Color": compoundColor, Type: type, Tyre: tyre, "Pressure": pressure, Count: count}, flush)
		}
	}
	
	Window[] {
		Get {
			return "RaceCenter"
		}
	}
	
	RaceSettings[] {
		Get {
			return this.iRaceSettings
		}
	}
	
	SessionDirectory[] {
		Get {
			if this.SessionActive
				return (this.iSessionDirectory . this.iSessionName . "\")
			else if this.SessionLoaded
				return this.SessionLoaded
			else
				return this.iSessionDirectory
		}
	}
	
	Connector[] {
		Get {
			return this.iConnector
		}
	}
	
	Connected[] {
		Get {
			return this.iConnected
		}
	}
	
	ServerURL[] {
		Get {
			return this.iServerURL
		}
	}
	
	ServerToken[] {
		Get {
			return this.iServerToken
		}
	}
	
	Teams[key := false] {
		Get {
			if key
				return this.iTeams[key]
			else
				return this.iTeams
		}
	}
	
	Sessions[key := false] {
		Get {
			if key
				return this.iSessions[key]
			else
				return this.iSessions
		}
	}
	
	SessionDrivers[key := false] {
		Get {
			if key
				return this.iSessionDrivers[key]
			else
				return this.iSessionDrivers
		}
	}
	
	SelectedTeam[asIdentifier := false] {
		Get {
			return (asIdentifier ? this.iTeamIdentifier : this.iTeamName)
		}
	}
	
	SelectedSession[asIdentifier := false] {
		Get {
			return (asIdentifier ? this.iSessionIdentifier : this.iSessionName)
		}
	}
	
	SessionActive[] {
		Get {
			return (this.Connected && this.SelectedTeam[true] && this.SelectedSession[true])
		}
	}
	
	SessionFinished[] {
		Get {
			return this.iSessionFinished
		}
	}
	
	SessionLoaded[] {
		Get {
			return this.iSessionLoaded
		}
	}
	
	HasData[] {
		Get {
			return (this.SessionActive || this.SessionLoaded)
		}
	}
	
	Version[] {
		Get {
			return this.iVersion
		}
	}
	
	Date[] {
		Get {
			return this.iDate
		}
	}
	
	Time[] {
		Get {
			return this.iTime
		}
	}
	
	Simulator[] {
		Get {
			return this.iSimulator
		}
	}
	
	Car[] {
		Get {
			return this.iCar
		}
	}
	
	Track[] {
		Get {
			return this.iTrack
		}
	}
	
	Weather[] {
		Get {
			return this.iWeather
		}
	}
	
	AirTemperature[] {
		Get {
			return this.iAirTemperature
		}
	}
	
	TrackTemperature[] {
		Get {
			return this.iTrackTemperature
		}
	}
	
	TyreCompound[] {
		Get {
			return this.iTyreCompound
		}
	}
	
	TyreCompoundColor[] {
		Get {
			return this.iTyreCompoundColor
		}
	}
	
	Strategy[] {
		Get {
			return this.iStrategy
		}
	}
	
	UseSessionData[] {
		Get {
			return this.iUseSessionData
		}
	}
	
	UseTelemetryDatabase[] {
		Get {
			return this.iUseTelemetryDatabase
		}
	}
	
	UseCurrentMap[] {
		Get {
			return this.iUseCurrentMap
		}
	}
	
	UseTraffic[] {
		Get {
			return this.iUseTraffic
		}
	}
	
	Drivers[] {
		Get {
			return this.iDrivers
		}
		
		Set {
			return (key ? (this.iStints[key] := value) : (this.iStints := value))
		}
	}
	
	Stints[key := false] {
		Get {
			return (key ? this.iStints[key] : this.iStints)
		}
		
		Set {
			return (key ? (this.iStints[key] := value) : (this.iStints := value))
		}
	}
	
	CurrentStint[asIdentifier := false] {
		Get {
			if this.iCurrentStint
				return (asIdentifier ? this.iCurrentStint.Identifier : this.iCurrentStint)
			else
				return false
		}
	}
	
	Laps[key := false] {
		Get {
			return (key ? this.iLaps[key] : this.iLaps)
		}
		
		Set {
			return (key ? (this.iLaps[key] := value) : (this.iLaps := value))
		}
	}
	
	LastLap[asIdentifier := false] {
		Get {
			if this.iLastLap
				return (asIdentifier ? this.iLastLap.Identifier : this.iLastLap)
			else
				return false
		}
	}
	
	PlanListView[] {
		Get {
			return this.iPlanListView
		}
	}
	
	StintsListView[] {
		Get {
			return this.iStintsListView
		}
	}
	
	LapsListView[] {
		Get {
			return this.iLapsListView
		}
	}
	
	PitstopsListView[] {
		Get {
			return this.iPitstopsListView
		}
	}
	
	SessionDatabase[] {
		Get {
			if (!this.iSessionDatabase && this.HasData) {
				this.iSessionDatabase := new Database(this.SessionDirectory, kSessionDataSchemas)
			}
			
			return this.iSessionDatabase
		}
	}
	
	TelemetryDatabase[] {
		Get {
			if !this.iTelemetryDatabase
				this.iTelemetryDatabase := new this.SessionTelemetryDatabase(this)
			
			return this.iTelemetryDatabase
		}
	}
	
	PressuresDatabase[] {
		Get {
			if !this.iPressuresDatabase
				this.iPressuresDatabase := new this.SessionPressuresDatabase(this)
		
			return this.iPressuresDatabase
		}
	}
	
	ReportViewer[] {
		Get {
			return this.iReportViewer
		}
	}
	
	StrategyViewer[] {
		Get {
			return this.iStrategyViewer
		}
	}
	
	SelectedReport[] {
		Get {
			return this.iSelectedReport
		}
	}
	
	SelectedChartType[] {
		Get {
			return this.iSelectedChartType
		}
	}
	
	SelectedDetailReport[] {
		Get {
			return this.iSelectedDetailReport
		}
	}
	
	__New(configuration, raceSettings) {
		this.iRaceSettings := raceSettings
		
		dllName := "Team Server Connector.dll"
		dllFile := kBinariesDirectory . dllName
		
		try {
			if (!FileExist(dllFile)) {
				logMessage(kLogCritical, translate("Team Server Connector.dll not found in ") . kBinariesDirectory)
				
				Throw "Unable to find Team Server Connector.dll in " . kBinariesDirectory . "..."
			}

			this.iConnector := CLR_LoadLibrary(dllFile).CreateInstance("TeamServer.TeamServerConnector")
		}
		catch exception {
			logMessage(kLogCritical, translate("Error while initializing Team Server Connector - please rebuild the applications"))
			
			showMessage(translate("Error while initializing Team Server Connector - please rebuild the applications") . translate("...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}
		
		base.__New(configuration)
		
		RaceCenter.Instance := this
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		directory := getConfigurationValue(configuration, "Team Server", "Session.Folder", kTempDirectory . "Sessions")
		
		if (!directory || (directory = ""))
			directory := (kTempDirectory . "Sessions")
		
		this.iSessionDirectory := (directory . "\")
		
		settings := this.RaceSettings
		
		this.iServerURL := getConfigurationValue(settings, "Team Settings", "Server.URL", "")
		this.iServerToken := getConfigurationValue(settings, "Team Settings", "Server.Token", "__INVALID__")
		this.iTeamName := getConfigurationValue(settings, "Team Settings", "Team.Name", "")
		this.iTeamIdentifier := getConfigurationValue(settings, "Team Settings", "Team.Identifier", false)
		this.iSessionName := getConfigurationValue(settings, "Team Settings", "Session.Name", "")
		this.iSessionIdentifier := getConfigurationValue(settings, "Team Settings", "Session.Identifier", false)
	}
	
	createGui(configuration) {
		window := this.Window
		
		Gui %window%:Default
	
		Gui %window%:-Border ; -Caption
		Gui %window%:Color, D0D0D0, D8D8D8

		Gui %window%:Font, s10 Bold, Arial

		Gui %window%:Add, Text, w1184 Center gmoveRaceCenter, % translate("Modular Simulator Controller System") 
		
		Gui %window%:Font, s9 Norm, Arial
		Gui %window%:Font, Italic Underline, Arial

		Gui %window%:Add, Text, YP+20 w1184 cBlue Center gopenDashboardDocumentation, % translate("Race Center")
		
		Gui %window%:Add, Text, x8 yp+30 w1200 0x10
			
		Gui %window%:Font, Norm
		Gui %window%:Font, s10 Bold, Arial
			
		Gui %window%:Add, Picture, x16 yp+12 w30 h30 Section, %kIconsDirectory%Report.ico
		Gui %window%:Add, Text, x50 yp+5 w80 h26, % translate("Reports")
			
		Gui %window%:Font, s8 Norm, Arial
		
		x := 16
		y := 70
		width := 388
			
		Gui %window%:Add, Text, x16 yp+30 w90 h23 +0x200, % translate("Server URL")
		Gui %window%:Add, Edit, x141 yp+1 w245 h21 VserverURLEdit, % this.ServerURL
		
		Gui %window%:Add, Text, x16 yp+24 w90 h23 +0x200, % translate("Access Token")
		Gui %window%:Add, Edit, x141 yp+1 w245 h21 VserverTokenEdit, % this.ServerToken
		Gui %window%:Add, Button, x116 yp-1 w23 h23 Center +0x200 HWNDconnectButton gconnectServer
		setButtonIcon(connectButton, kIconsDirectory . "Authorize.ico", 1, "L4 T4 R4 B4")

		Gui %window%:Add, Text, x16 yp+26 w90 h23 +0x200, % translate("Team / Session")
			
		if this.SelectedTeam[true]
			Gui %window%:Add, DropDownList, x141 yp w120 AltSubmit Choose1 vteamDropDownMenu gchooseTeam, % this.SelectedTeam
		else
			Gui %window%:Add, DropDownList, x141 yp w120 AltSubmit vteamDropDownMenu gchooseTeam
			
		if this.SelectedSession[true]
			Gui %window%:Add, DropDownList, x266 yp w120 AltSubmit Choose1 vsessionDropDownMenu gchooseSession, % this.SelectedSession
		else
			Gui %window%:Add, DropDownList, x266 yp w120 AltSubmit Choose0 vsessionDropDownMenu gchooseSession
		
		Gui %window%:Add, Text, x24 yp+30 w356 0x10
		
		Gui %window%:Add, ListView, x16 yp+10 w115 h176 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDreportsListView gchooseReport, % translate("Report")
		
		for ignore, report in map(kSessionReports, "translate")
			LV_Add("", report)
		
		LV_ModifyCol(1, "AutoHdr")
		
		Gui %window%:Add, Text, x141 yp+2 w70 h23 +0x200, % translate("X-Axis")
		
		Gui %window%:Add, DropDownList, x195 yp w191 AltSubmit vdataXDropDown gchooseAxis
		
		Gui %window%:Add, Text, x141 yp+24 w70 h23 +0x200, % translate("Series")
		
		Gui %window%:Add, DropDownList, x195 yp w191 AltSubmit vdataY1DropDown gchooseAxis
		Gui %window%:Add, DropDownList, x195 yp+24 w191 AltSubmit vdataY2DropDown gchooseAxis
		Gui %window%:Add, DropDownList, x195 yp+24 w191 AltSubmit vdataY3DropDown gchooseAxis
		Gui %window%:Add, DropDownList, x195 yp+24 w191 AltSubmit vdataY4DropDown gchooseAxis
		Gui %window%:Add, DropDownList, x195 yp+24 w191 AltSubmit vdataY5DropDown gchooseAxis
		Gui %window%:Add, DropDownList, x195 yp+24 w191 AltSubmit vdataY6DropDown gchooseAxis
		
		Gui %window%:Add, Text, x400 ys w40 h23 +0x200, % translate("Plot")
		Gui %window%:Add, DropDownList, x444 yp w80 AltSubmit Choose1 vchartTypeDropDown gchooseChartType, % values2String("|", map(["Scatter", "Bar", "Bubble", "Line"], "translate")*)
		
		Gui %window%:Add, Button, x1177 yp w23 h23 HwndreportSettingsButtonHandle vreportSettingsButton greportSettings
		setButtonIcon(reportSettingsButtonHandle, kIconsDirectory . "Report Settings.ico", 1)
		
		Gui %window%:Add, ActiveX, x400 yp+24 w800 h278 Border vchartViewer, shell.explorer
		
		chartViewer.Navigate("about:blank")
		
		Gui %window%:Add, Text, x8 yp+286 w1200 0x10

		Gui %window%:Font, s10 Bold, Arial
			
		Gui %window%:Add, Picture, x16 yp+10 w30 h30 Section, %kIconsDirectory%Tools BW.ico
		Gui %window%:Add, Text, x50 yp+5 w80 h26, % translate("Session")
		
		Gui %window%:Add, ActiveX, x1173 yp w30 h30 vwaitViewer, shell.explorer
		
		waitViewer.Navigate("about:blank")
		
		this.showWait(false)
		
		Gui %window%:Font, s8 Norm cBlack, Arial
		
		Gui %window%:Add, DropDownList, x195 yp-2 w180 AltSubmit Choose1 +0x200 vsessionMenuDropDown gsessionMenu, % values2String("|", map(["Session", "---------------------------------------------", "Connect", "Clear", "---------------------------------------------", "Load Session...", "Save Session", "Save a Copy...", "---------------------------------------------", "Update Statistics", "---------------------------------------------", "Race Summary", "Driver Statistics"], "translate")*)
		
		Gui %window%:Add, DropDownList, x380 yp w180 AltSubmit Choose1 +0x200 vplanMenuDropDown gplanMenu, % values2String("|", map(["Plan", "---------------------------------------------", "Load from Strategy", "Clear Plan...", "---------------------------------------------", "Plan Summary", "---------------------------------------------", "Release Plan"], "translate")*)

		Gui %window%:Add, DropDownList, x565 yp w180 AltSubmit Choose1 +0x200 vstrategyMenuDropDown gstrategyMenu
		
		this.updateStrategyMenu()
		
		Gui %window%:Add, DropDownList, x750 yp w180 AltSubmit Choose1 +0x200 vpitstopMenuDropDown gpitstopMenu, % values2String("|", map(["Pitstop", "---------------------------------------------", "Initialize from Session", "Load from Setup Database...", "---------------------------------------------", "Instruct Engineer"], "translate")*)
		
		Gui %window%:Font, s8 Norm, Arial
		
		Gui %window%:Font, Norm, Arial
		Gui %window%:Font, Italic, Arial

		Gui %window%:Add, GroupBox, -Theme x619 ys+39 w582 h9, % translate("Output")
		
		Gui %window%:Add, ActiveX, x619 yp+21 w582 h293 Border vdetailsViewer, shell.explorer
		
		detailsViewer.Navigate("about:blank")
		
		this.iStrategyViewer := new StrategyViewer(window, detailsViewer)
		
		this.showDetails(false, false)
		this.showChart(false)
		
		Gui %window%:Font, Norm, Arial
		
		Gui %window%:Add, Text, x8 y750 w1200 0x10
		
		Gui %window%:Add, Button, x574 y756 w80 h23 GcloseRaceCenter, % translate("Close")

		Gui %window%:Add, Tab3, x16 ys+39 w593 h316 -Wrap Section, % values2String("|", map(["Plan", "Stints", "Laps", "Pitstops"], "translate")*)
		
		Gui Tab, 1
		
		Gui %window%:Add, Text, x24 ys+33 w90 h23 +0x200, % translate("Session")
		Gui %window%:Add, DateTime, x106 yp w80 h23 vsessionDateCal gupdateDate
		Gui %window%:Add, DateTime, x190 yp w50 h23  vsessionTimeEdit gupdateTime 1, HH:mm
		
		Gui %window%:Add, ListView, x24 ys+63 w344 h240 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistHandle gchoosePlan, % values2String("|", map(["Stint", "Driver", "Time (est.)", "Time (act.)", "Lap (est.)", "Lap (act.)", "Refuel", "Tyre Change"], "translate")*)
		
		this.iPlanListView := listHandle
		
		Gui %window%:Add, Text, x378 ys+68 w90 h23 +0x200, % translate("Driver")
		Gui %window%:Add, DropDownList, x474 yp w126 AltSubmit vdriverDropDownMenu gupdatePlan
		
		Gui %window%:Add, Text, x378 yp+28 w90 h23 +0x200, % translate("Time (est. / act.)")
		Gui %window%:Add, DateTime, x474 yp w50 h23 vplanTimeEdit gupdatePlan 1, HH:mm
		Gui %window%:Add, DateTime, x528 yp w50 h23 vactTimeEdit gupdatePlan 1, HH:mm
		
		Gui %window%:Add, Text, x378 yp+28 w90 h20, % translate("Lap (est. / act.)")
		Gui %window%:Add, Edit, x474 yp-2 w50 h20 Limit3 Number vplanLapEdit gupdatePlan
		Gui %window%:Add, UpDown, x506 yp w18 h20
		Gui %window%:Add, Edit, x528 yp w50 h20 Limit3 Number vactLapEdit gupdatePlan
		Gui %window%:Add, UpDown, x560 yp w18 h20
		
		Gui %window%:Add, Text, x378 yp+30 w85 h20, % translate("Refuel")
		Gui %window%:Add, Edit, x474 yp-2 w50 h20 Limit3 Number vplanRefuelEdit gupdatePlan
		Gui %window%:Add, UpDown, x506 yp-2 w18 h20
		Gui %window%:Add, Text, x528 yp+2 w30 h20, % translate("Liter")

		Gui %window%:Add, Text, x378 yp+24 w85 h23 +0x200, % translate("Tyre Change")
		choices := map(["Yes", "No"], "translate")
		Gui %window%:Add, DropDownList, x474 yp w50 AltSubmit Choose1 vplanTyreCompoundDropDown gupdatePlan, % values2String("|", choices*)
		
		Gui %window%:Add, Button, x550 yp+35 w23 h23 Center +0x200 HWNDplusButton vaddPlanButton gaddPlan
		setButtonIcon(plusButton, kIconsDirectory . "Plus.ico", 1, "L4 T4 R4 B4")
		Gui %window%:Add, Button, x575 yp w23 h23 Center +0x200 HWNDminusButton vdeletePlanButton gdeletePlan
		setButtonIcon(minusButton, kIconsDirectory . "Minus.ico", 1, "L4 T4 R4 B4")
		
		Gui %window%:Add, Button, x408 ys+279 w160 greleasePlan, % translate("Release Plan")

		Gui Tab, 2
		
		Gui %window%:Add, ListView, x24 ys+33 w577 h270 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistHandle gchooseStint, % values2String("|", map(["#", "Driver", "Weather", "Compound", "Laps", "Pos. (Start)", "Pos. (End)", "Avg. Lap Time", "Consumption", "Accidents", "Potential", "Race Craft", "Speed", "Consistency", "Car Control"], "translate")*)
		
		this.iStintsListView := listHandle
		
		Gui Tab, 3
		
		Gui %window%:Add, ListView, x24 ys+33 w577 h270 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistHandle gchooseLap, % values2String("|", map(["#", "Stint", "Driver", "Position", "Weather", "Grip", "Lap Time", "Consumption", "Remaining", "Pressures", "Accident"], "translate")*)
		
		this.iLapsListView := listHandle
		
		Gui Tab, 4
	
		Gui %window%:Add, Text, x24 ys+36 w85 h20, % translate("Lap")
		Gui %window%:Add, Edit, x106 yp-2 w50 h20 Limit3 Number vpitstopLapEdit
		Gui %window%:Add, UpDown, x138 yp-2 w18 h20
		
		Gui %window%:Add, Text, x24 yp+30 w85 h20, % translate("Refuel")
		Gui %window%:Add, Edit, x106 yp-2 w50 h20 Limit3 Number vpitstopRefuelEdit
		Gui %window%:Add, UpDown, x138 yp-2 w18 h20
		Gui %window%:Add, Text, x164 yp+2 w30 h20, % translate("Liter")

		Gui %window%:Add, Text, x24 yp+24 w85 h23 +0x200, % translate("Tyre Change")
		choices := map(["No Tyre Change", "Wet", "Dry", "Dry (Red)", "Dry (White)", "Dry (Blue)"], "translate")
		Gui %window%:Add, DropDownList, x106 yp w157 AltSubmit Choose1 vpitstopTyreCompoundDropDown gupdateState, % values2String("|", choices*)

		Gui %window%:Add, Text, x24 yp+26 w85 h20, % translate("Tyre Set")
		Gui %window%:Add, Edit, x106 yp-2 w50 h20 Limit2 Number vpitstopTyreSetEdit
		Gui %window%:Add, UpDown, x138 yp w18 h20
		
		Gui %window%:Add, Text, x24 yp+24 w85 h20, % translate("Pressures")
		
		Gui %window%:Add, Edit, x106 yp-2 w50 h20 Limit4 vpitstopPressureFLEdit
		Gui %window%:Add, Edit, x160 yp w50 h20 Limit4 vpitstopPressureFREdit
		Gui %window%:Add, Text, x214 yp+2 w30 h20, % translate("PSI")
		Gui %window%:Add, Edit, x106 yp+20 w50 h20 Limit4 vpitstopPressureRLEdit
		Gui %window%:Add, Edit, x160 yp w50 h20 Limit4 vpitstopPressureRREdit
		Gui %window%:Add, Text, x214 yp+2 w30 h20, % translate("PSI")
		
		Gui %window%:Add, Text, x24 yp+24 w85 h23 +0x200, % translate("Repairs")
		choices := map(["No Repairs", "Bodywork & Aerodynamics", "Suspension & Chassis", "Everything"], "translate")
		Gui %window%:Add, DropDownList, x106 yp w157 AltSubmit Choose1 vpitstopRepairsDropDown, % values2String("|", choices*)
		
		Gui %window%:Add, Button, x66 ys+279 w160 gplanPitstop, % translate("Instruct Engineer")
		
		Gui %window%:Add, ListView, x270 ys+34 w331 h269 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistHandle gchoosePitstop, % values2String("|", map(["#", "Lap", "Fuel", "Compound", "Set", "Pressures", "Repairs"], "translate")*)
		
		this.iPitstopsListView := listHandle
		
		this.iReportViewer := new RaceReportViewer(window, chartViewer)
		
		this.initializeSession()
		
		this.updateState()
	}
	
	connect(silent := false) {
		window := this.Window
		
		Gui %window%:+Disabled
		
		try {
			token := this.Connector.Connect(this.ServerURL, this.ServerToken)
	
			this.iConnected := true
			
			showMessage(translate("Successfully connected to the Team Server."))
			
			this.loadTeams()
			
			SetTimer syncSession, -50
		}
		catch exception {
			SetTimer syncSession, Off
			
			this.iServerToken := "__INVALID__"
			
			GuiControl, , serverTokenEdit, % ""
			
			if !silent {
				title := translate("Error")
			
				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
				MsgBox 262160, %title%, % (translate("Cannot connect to the Team Server.") . "`n`n" . translate("Error: ") . exception.Message)
				OnMessage(0x44, "")
			}
			
			this.loadTeams()
		}
		finally {
			Gui %window%:-Disabled
		}
	}
	
	loadTeams() {
		window := this.Window
		
		Gui %window%:Default
		
		teams := (this.Connected ? loadTeams(this.Connector) : {})
		
		this.iTeams := teams

		names := getKeys(teams)
		identifiers := getValues(teams)
		
		GuiControl, , teamDropDownMenu, % ("|" . values2String("|", names*))
		
		chosen := inList(identifiers, this.SelectedTeam[true])
	
		if ((chosen == 0) && (names.Length() > 0))
			chosen := 1
		
		this.selectTeam((chosen == 0) ? false : identifiers[chosen])
	}
	
	selectTeam(identifier) {
		window := this.Window
		
		Gui %window%:Default
		
		chosen := inList(getValues(this.Teams), identifier)
		
		GuiControl Choose, teamDropDownMenu, % chosen

		names := getKeys(this.Teams)
		
		if (chosen > 0) {
			this.iTeamName := names[chosen]
			this.iTeamIdentifier := identifier
		}
		else {
			this.iTeamName := ""
			this.iTeamIdentifier := false
		}
		
		this.loadSessions()
		this.loadSessionDrivers()
	}
	
	loadSessions() {
		window := this.Window
		
		Gui %window%:Default
		
		teamIdentifier := this.SelectedTeam[true]
		
		sessions := ((this.Connected && teamIdentifier) ? loadSessions(this.Connector, teamIdentifier) : {})
		
		this.iSessions := sessions
				
		names := getKeys(sessions)
		identifiers := getValues(sessions)
		
		GuiControl, , sessionDropDownMenu, % ("|" . values2String("|", names*))
		
		chosen := inList(identifiers, this.SelectedSession[true])
	
		if ((chosen == 0) && (names.Length() > 0))
			chosen := 1
		
		this.selectSession((chosen == 0) ? false : identifiers[chosen])
	}
	
	loadSessionDrivers() {
		if this.SessionActive {
			window := this.Window
			
			Gui %window%:Default
			
			teamIdentifier := this.SelectedTeam[true]
			
			drivers := ((this.Connected && teamIdentifier) ? loadDrivers(this.Connector, teamIdentifier) : {})
		}
		else {
			drivers := {}
			
			for ignore, driver in this.Drivers {
				name := computeDriverName(driver.Forname, driver.Surname, driver.Nickname)
			
				drivers[name] := false
			}
		}
		
		this.iSessionDrivers := drivers
			
		names := getKeys(drivers)
		identifiers := getValues(drivers)
		
		GuiControl, , driverDropDownMenu, % ("|" . values2String("|", translate("-"), names*))
	}
	
	selectSession(identifier) {
		window := this.Window
		
		Gui %window%:Default
		
		chosen := inList(getValues(this.Sessions), identifier)
		
		GuiControl Choose, sessionDropDownMenu, % chosen

		names := getKeys(this.Sessions)
		
		if (chosen > 0) {
			this.iSessionName := names[chosen]
			this.iSessionIdentifier := identifier
		}
		else {
			this.iSessionName := ""
			this.iSessionIdentifier := false
		}
		
		this.initializeSession()
	}
	
	addDriver(driver) {
		for ignore, candidate in this.Drivers
			if (this.SessionActive && (candidate.Identifier == driver.Identifier))
				return candidate
			else if ((candidate.Forname = driver.Forname) && (candidate.Surname = driver.Surname) && (candidate.Nickname = driver.Nickname))
				return candidate
		
		driver.Fullname := computeDriverName(driver.Forname, driver.Surname, driver.Nickname)
		driver.Laps := []
		driver.Stints := []
		driver.Accidents := 0
		
		this.Drivers.Push(driver)
		
		return driver
	}
	
	updateState() {
		window := this.Window
		
		Gui %window%:Default
		
		GuiControlGet pitstopTyreCompoundDropDown
					
		if (pitstopTyreCompoundDropDown > 1) {
			GuiControl Enable, pitstopTyreSetEdit
			GuiControl Enable, pitstopPressureFLEdit
			GuiControl Enable, pitstopPressureFREdit
			GuiControl Enable, pitstopPressureRLEdit
			GuiControl Enable, pitstopPressureRREdit
		}
		else {
			GuiControl Disable, pitstopTyreSetEdit
			GuiControl Disable, pitstopPressureFLEdit
			GuiControl Disable, pitstopPressureFREdit
			GuiControl Disable, pitstopPressureRLEdit
			GuiControl Disable, pitstopPressureRREdit
		}
		
		GuiControl Disable, dataXDropDown
		GuiControl Disable, dataY1DropDown
		GuiControl Disable, dataY2DropDown
		GuiControl Disable, dataY3DropDown
		GuiControl Disable, dataY4DropDown
		GuiControl Disable, dataY5DropDown
		GuiControl Disable, dataY6DropDown

		if this.HasData {
			if inList(["Driver", "Position", "Pace", "Pressures", "Temperatures", "Free"], this.SelectedReport)
				GuiControl Enable, reportSettingsButton
			else
				GuiControl Disable, reportSettingsButton
			
			if inList(["Pressures", "Temperatures", "Free"], this.SelectedReport) {
				GuiControl Enable, chartTypeDropDown

				GuiControl Enable, dataXDropDown
				GuiControl Enable, dataY1DropDown
				GuiControl Enable, dataY2DropDown
				GuiControl Enable, dataY3DropDown
				
				if (this.SelectedChartType != "Bubble") {
					GuiControl Enable, dataY4DropDown
					GuiControl Enable, dataY5DropDown
					GuiControl Enable, dataY6DropDown
				}
			}
			else {
				GuiControl Disable, chartTypeDropDown
				GuiControl Choose, chartTypeDropDown, 0
		
				this.iSelectedChartType := false
				
				GuiControl Choose, dataXDropDown, 0
				GuiControl Choose, dataY1DropDown, 0
				GuiControl Choose, dataY2DropDown, 0
				GuiControl Choose, dataY3DropDown, 0
				GuiControl Choose, dataY4DropDown, 0
				GuiControl Choose, dataY5DropDown, 0
				GuiControl Choose, dataY6DropDown, 0
			}
		}
		else {
			GuiControl Disable, reportSettingsButton

			GuiControl Choose, dataXDropDown, 0
			GuiControl Choose, dataY1DropDown, 0
			GuiControl Choose, dataY2DropDown, 0
			GuiControl Choose, dataY3DropDown, 0
			GuiControl Choose, dataY4DropDown, 0
			GuiControl Choose, dataY5DropDown, 0
			GuiControl Choose, dataY6DropDown, 0
			
			GuiControl Disable, chartTypeDropDown
			GuiControl Choose, chartTypeDropDown, 0
			
			this.iSelectedChartType := false
		}
		
		this.updateStrategyMenu()
		
		Gui ListView, % this.PlanListView
		
		selected := LV_GetNext(0)
		
		if selected {
			GuiControl Enable, driverDropDownMenu
			GuiControl Enable, planTimeEdit
			GuiControl Enable, actTimeEdit
			GuiControl Enable, deletePlanButton
			
			LV_GetText(stint, selected)
			
			if (stint = 1) {
				GuiControl Disable, planLapEdit
				GuiControl Disable, actLapEdit
				GuiControl Disable, planRefuelEdit
				GuiControl Disable, planTyreCompoundDropDown
				
				GuiControl, , planLapEdit, % ""
				GuiControl, , actLapEdit, % ""
				GuiControl, , planRefuelEdit, % ""
				GuiControl Choose, planTyreCompoundDropDown, 0
			}
			else {
				GuiControl Enable, planLapEdit
				GuiControl Enable, actLapEdit
				GuiControl Enable, planRefuelEdit
				GuiControl Enable, planTyreCompoundDropDown
			}
		}
		else {
			GuiControl Disable, driverDropDownMenu
			GuiControl Disable, planTimeEdit
			GuiControl Disable, actTimeEdit
			GuiControl Disable, planLapEdit
			GuiControl Disable, actLapEdit
			GuiControl Disable, planRefuelEdit
			GuiControl Disable, planTyreCompoundDropDown
			GuiControl Disable, deletePlanButton
			
			GuiControl Choose, driverDropDownMenu, 0
			GuiControl, , planTimeEdit, 20200101000000
			GuiControl, , actTimeEdit, 20200101000000
			GuiControl, , planLapEdit, % ""
			GuiControl, , actLapEdit, % ""
			GuiControl, , planRefuelEdit, % ""
			GuiControl Choose, planTyreCompoundDropDown, 0
		}
	}
	
	updateStrategyMenu() {
		window := this.Window
		
		Gui %window%:Default
		
		use1 := (this.UseSessionData ? "(x) Use Session Data" : "      Use Session Data")
		use2 := (this.UseTelemetryDatabase ? "(x) Use Telemetry Database" : "      Use Telemetry Database")
		use3 := (this.UseCurrentMap ? "(x) Keep current Map" : "      Keep current Map")
		use4 := (this.UseTraffic ? "(x) Consider Traffic" : "      Consider Traffic")
		
		GuiControl, , strategyMenuDropDown, % "|" . values2String("|", map(["Strategy", "---------------------------------------------", "Load current Race Strategy", "Load Strategy...", "Save Strategy...", "---------------------------------------------", "Strategy Summary", "---------------------------------------------", use1, use2, use3, use4, "---------------------------------------------", "Adjust Strategy (Simulation)", "---------------------------------------------", "Discard Strategy", "---------------------------------------------", "Instruct Strategist"], "translate")*)
		
		GuiControl Choose, strategyMenuDropDown, 1
	}
	
	loadPlanFromStrategy() {
		if this.Strategy {
			window := this.Window
			
			Gui %window%:Default
			
			Gui ListView, % this.PlanListView
		
			pitstops := this.Strategy.Pitstops
			
			numStints := (pitstops.Length() + 1)
			
			if (numStints < LV_GetCount()) {
				title := translate("Plan")
				
				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Beginning", "End", "Cancel"]))
				MsgBox 262179, %title%, % translate("The plan has more stints than the strategy. Do you want to remove surplus stints from the beginning or from the end of the plan?")
				OnMessage(0x44, "")
				
				IfMsgBox Cancel
					return
				
				IfMsgBox Yes
				{
					while (LV_GetCount() > numStints)
						LV_Delete(1)
					
					if (LV_GetCount() > 0)
						LV_Modify(1, "Col5", "-", "-", "-", "-")
				}
				
				IfMsgBox No
					while (LV_GetCount() > numStints)
						LV_Delete(LV_GetCount())
			}
			
			if (LV_GetCount() < numStints) {
				if (LV_GetCount() > 0) {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("The plan has less stints than the strategy. Additional stints will be added at the end of the plan.")
					OnMessage(0x44, "")
				}
				
				while (LV_GetCount() < numStints) {
					if (LV_GetCount() == 0)
						last := 0
					else
						LV_GetText(last, LV_GetCount())
			
					time := this.Time
					
					FormatTime time, %time%, HH:mm
					
					if (last = 0)
						LV_Add("", 1, "", time, "", "-", "-", "-", "-")
					else
						LV_Add("", last + 1, "", time, "", "", "", "", "")
				}
			}
			
			if (LV_GetCount() > 0) {
				LV_GetText(time, 1, 3)
				
				time := string2Values(":", time)
				
				currentTime := "20200101000000"
				
				EnvAdd currentTime, time[1], Hours
				EnvAdd currentTime, time[2], Minutes
			}
			
			lastTime := 0
			
			Loop % LV_GetCount()
				if (A_Index > 1) {
					pitstop := pitstops[A_Index - 1]
					
					time := pitstop.Time
					time -= lastTime
					
					lastTime := pitstop.Time
					
					EnvAdd currentTime, time, Seconds
					FormatTime time, %currentTime%, HH:mm
					
					LV_Modify(A_Index, "Col3", time)
					LV_Modify(A_Index, "Col5", pitstop.Lap)
					LV_Modify(A_Index, "Col7", (pitstop.RefuelAmount == 0) ? "-" : pitstop.RefuelAmount)
					LV_Modify(A_Index, "Col8", pitstop.TyreChange ? "x" : "")
				}
		
			if (this.SelectedDetailReport = "Plan")
				this.showPlanDetails()
		
			this.updateState()
		}
	}
	
	updatePlan(minutesOrStint) {
		window := this.Window
			
		Gui %window%:Default
		
		Gui ListView, % this.PlanListView
		
		if IsObject(minutesOrStint) {
			if (LV_GetCount() > 0) {
				time := this.computeStartTime(minutesOrStint)
				
				FormatTime time, %time%, HH:mm
				
				Loop % LV_GetCount()
				{
					LV_GetText(stintNr, A_Index)
					
					if (stintNr = minutesOrStint.Nr) {
						LV_Modify(A_Index, "Col2", minutesOrStint.Driver.FullName)
						LV_Modify(A_Index, "Col4", time)
						
						if (stintNr != 1)
							LV_Modify(A_Index, "Col6", minutesOrStint.Lap)
					}
				}
			}
		}
		else
			Loop % LV_GetCount()
			{
				LV_GetText(time, A_Index, 3)
				
				time := string2Values(":", time)
				time := ("20200101" . time[1] . time[2] . "00")
				
				EnvAdd time, %minutesOrStint%, Minutes
				FormatTime time, %time%, HH:mm
						
				LV_Modify(A_Index, "Col3", time)
			}
		
		if (this.SelectedDetailReport = "Plan")
			this.showPlanDetails()
		
		this.updateState()
	}
	
	addPlan(position := "After") {
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.PlanListView
		
		selected := LV_GetNext(0)
		
		if selected {
			position := ((position = "After") ? selected + 1 : selected)
			
			if (position > LV_GetCount())
				position := false
		}
		else
			position := false
		
		if position
			LV_GetText(stintNr, position)
		else {
			if (LV_GetCount() > 0) {
				LV_GetText(stintNr, LV_GetCount())
				
				stintNr += 1
			}
			else
				stintNr := 1
		}
		
		initial := ((stintNr = 1) ? "-" : "")
			
		if position
			LV_Insert(position, "Select", stintNr, "", "", "", initial, initial, initial, initial)
		else
			LV_Add("Select", stintNr, "", "", "", initial, initial, initial, initial)
		
		GuiControl Choose, driverDropDownMenu, 1
		GuiControl, , planTimeEdit, 20200101000000
		GuiControl, , actTimeEdit, 20200101000000
		GuiControl, , planLapEdit, % ""
		GuiControl, , actLapEdit, % ""
		GuiControl, , planRefuelEdit, 0
		GuiControl Choose, planTyreCompoundDropDown, 2
	
		LV_GetText(stintNr, 1)
		
		Loop % LV_GetCount()
			LV_Modify(A_Index, "", stintNr++)
		
		this.updateState()
	}
	
	deletePlan() {
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.PlanListView
		
		selected := LV_GetNext(0)
		
		if selected {
			LV_Delete(selected)
		
			if (selected <= LV_GetCount()) {
				LV_GetText(stintNr, 1)
				
				Loop % LV_GetCount()
					LV_Modify(A_Index, "", stintNr++)
			}
		}
		
		this.updateState()
	}
	
	releasePlan() {
		if this.SessionActive
			try {
				session := this.SelectedSession[true]
		
				version := (A_Now . "")
				
				this.iVersion := version
				
				info := newConfiguration()
				
				setConfigurationValue(info, "Plan", "Version", version)
				setConfigurationValue(info, "Plan", "Date", this.Date)
				setConfigurationValue(info, "Plan", "Time", this.Time)
				
				this.savePlan(true)
				
				fileName := (this.SessionDirectory . "Plan.Data.CSV")
				
				FileRead plan, %fileName%
				
				this.Connector.setSessionValue(session, "Stint Plan Info", printConfiguration(info))
				this.Connector.setSessionValue(session, "Stint Plan", plan)
				this.Connector.setSessionValue(session, "Stint Plan Version", version)
				
				showMessage(translate("Plan will be updated for this Session."))
			}
			catch exception {
				; ignore
			}
	}
	
	initializePitstopSettings(ByRef lap, ByRef refuel, ByRef compound, ByRef compoundColor) {
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.PlanListView
		
		currentStint := this.CurrentStint
				
		if currentStint {
			nextStint := (currentStint.Nr + 1)
		
			Loop % LV_GetCount()
			{
				LV_GetText(stint, A_Index)
				
				if (stint = nextStint) {
					LV_GetText(plannedLap, A_Index, 5)
					LV_GetText(refuelAmount, A_Index, 7)
					LV_GetText(tyreChange, A_Index, 8)
		
					lap := plannedLap
					refuel := refuelAmount
					
					if (tyreChange != "x") {
						compound := false
						compoundColor := false
					}
					
					return
				}
			}
		
			if this.Strategy
				for index, pitstop in this.Strategy.Pitstops
					if (pitstop.ID = currentStint.Nr) {
						lap := pitstop.Lap
						refuel := pitstop.RefuelAmount
			
						if !pitstop.TyreChange {
							compound := false
							compoundColor := false
						}
						
						return
					}
		}
	}			
	
	initializePitstopFromSession() {
		pressuresDB := this.PressuresDatabase
		
		if pressuresDB {
			pressuresTable := pressuresDB.Database.Tables["Setup.Pressures"]
		
			last := pressuresTable.Length()
			
			if (last > 0) {
				pressures := pressuresTable[last]
				
				lap := 0
				refuel := 0
				compound := pressures["Compound"]
				compoundColor := pressures["Compound.Color"]
				
				this.initializePitstopSettings(lap, refuel, compound, compoundColor)
				
				window := this.Window
		
				Gui %window%:Default
				
				GuiControl, , pitstopLapEdit, %lap%
				GuiControl, , pitstopRefuelEdit, %refuel%
				
				this.initializePitstopTyreSetup(compound, compoundColor
											  , displayValue(pressures["Tyre.Pressure.Cold.Front.Left"]), displayValue(pressures["Tyre.Pressure.Cold.Front.Right"])
											  , displayValue(pressures["Tyre.Pressure.Cold.Rear.Left"]), displayValue(pressures["Tyre.Pressure.Cold.Rear.Right"]))
			}
		}
	}
	
	initializePitstopTyreSetup(compound, compoundColor, flPressure, frPressure, rlPressure, rrPressure) {
		window := this.Window
		
		Gui %window%:Default
		
		if (compoundColor != "Black")
			compound := (compound . " (" . compoundColor . ")")
		
		GuiControl Choose, pitstopTyreCompoundDropDown, % (!compound ? 1 : inList(["No Tyre Change", "Wet", "Dry", "Dry (Red)", "Dry (White)", "Dry (Blue)"], compound))
		
		GuiControl, , pitstopPressureFLEdit, % Round(flPressure, 1)
		GuiControl, , pitstopPressureFREdit, % Round(frPressure, 1)
		GuiControl, , pitstopPressureRLEdit, % Round(rlPressure, 1)
		GuiControl, , pitstopPressureRREdit, % Round(rrPressure, 1)
		
		this.updateState()
	}
	
	updateStrategy() {
		local strategy
		
		if (this.Strategy && this.SessionActive)
			try {
				this.Strategy.setVersion(A_Now)
				
				strategy := newConfiguration()
							
				this.Strategy.saveToConfiguration(strategy)
				
				strategy := printConfiguration(strategy)
				
				session := this.SelectedSession[true]
				lap := this.Connector.GetSessionLastLap(session)

				this.Connector.SetLapValue(lap, "Strategy Update", strategy)
				this.Connector.SetSessionValue(session, "Strategy Update", lap)
				
				this.Connector.SetSessionValue(session, "Race Strategy", strategy)
				this.Connector.SetSessionValue(session, "Race Strategy Version", this.Strategy.Version)
				this.Connector.SetLapValue(lap, "Race Strategy", strategy)
				
				showMessage(translate("Race Strategist will be instructed in the next lap."))
			}
			catch exception {
				showMessage(translate("Session has not been started yet."))
			}
	}
	
	discardStrategy() {
		this.selectStrategy(false)
		
		if this.SessionActive
			try {
				session := this.SelectedSession[true]
				
				lap := this.Connector.GetSessionLastLap(session)

				this.Connector.SetLapValue(lap, "Strategy Update", "CANCEL")
				this.Connector.SetSessionValue(session, "Strategy Update", lap)
				
				this.Connector.SetSessionValue(session, "Race Strategy", "CANCEL")
				this.Connector.SetSessionValue(session, "Race Strategy Version", A_Now . "")
				
				showMessage(translate("Race Strategist will be instructed in the next lap."))
			}
			catch exception {
				showMessage(translate("Session has not been started yet."))
			}
	}
	
	planPitstop() {
		if this.SessionActive() {
			window := this.Window
			
			Gui %window%:Default
			
			GuiControlGet pitstopLapEdit
			GuiControlGet pitstopRefuelEdit
			GuiControlGet pitstopTyreCompoundDropDown
			GuiControlGet pitstopTyreSetEdit
			GuiControlGet pitstopPressureFLEdit
			GuiControlGet pitstopPressureFREdit
			GuiControlGet pitstopPressureRLEdit
			GuiControlGet pitstopPressureRREdit
			GuiControlGet pitstopRepairsDropDown
			
			pitstopPlan := newConfiguration()
			
			setConfigurationValue(pitstopPlan, "Pitstop", "Lap", pitstopLapEdit)
			setConfigurationValue(pitstopPlan, "Pitstop", "Refuel", pitstopRefuelEdit)
			
			if (pitstopTyreCompoundDropDown > 1) {
				setConfigurationValue(pitstopPlan, "Pitstop", "Tyre.Change", true)
				
				setConfigurationValue(pitstopPlan, "Pitstop", "Tyre.Set", pitstopTyreSetEdit)
				setConfigurationValue(pitstopPlan, "Pitstop", "Tyre.Compound", (pitstopTyreCompoundDropDown = 2) ? "Wet" : "Dry")
				setConfigurationValue(pitstopPlan, "Pitstop", "Tyre.Compound.Color"
									, ["Black", "Black", "Red", "White", "Blue"][pitstopTyreCompoundDropDown - 1])
				
				setConfigurationValue(pitstopPlan, "Pitstop", "Tyre.Pressures"
									, values2String(",", pitstopPressureFLEdit, pitstopPressureFREdit
													   , pitstopPressureRLEdit, pitstopPressureRREdit))
			}
			else
				setConfigurationValue(pitstopPlan, "Pitstop", "Tyre.Change", false)
			
			setConfigurationValue(pitstopPlan, "Pitstop", "Repair.Bodywork", false)
			setConfigurationValue(pitstopPlan, "Pitstop", "Repair.Suspension", false)
				
			if ((pitstopRepairsDropDown = 2) || (pitstopRepairsDropDown = 4))
				setConfigurationValue(pitstopPlan, "Pitstop", "Repair.Bodywork", true)
				
			if (pitstopRepairsDropDown > 2)
				setConfigurationValue(pitstopPlan, "Pitstop", "Repair.Suspension", true)
			
			try {
				session := this.SelectedSession[true]
				
				lap := this.Connector.GetSessionLastLap(session)

				this.Connector.SetLapValue(lap, "Pitstop Plan", printConfiguration(pitstopPlan))
				this.Connector.SetSessionValue(session, "Pitstop Plan", lap)
				
				showMessage(translate("Race Engineer will be instructed in the next lap."))
			}
			catch exception {
				title := translate("Information")

				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
				MsgBox 262192, %title%, % translate("You must be connected to an active session to plan a pitstop.")
				OnMessage(0x44, "")
			}
		}
		else {
			title := translate("Information")

			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			MsgBox 262192, %title%, % translate("You must be connected to an active session to plan a pitstop.")
			OnMessage(0x44, "")
		}
	}
	
	chooseSessionMenu(line) {
		switch line {
			case 3: ; Connect...
				window := this.Window
						
				Gui %window%:Default
				
				GuiControlGet serverURLEdit
				GuiControlGet serverTokenEdit

				this.iServerURL := serverURLEdit
				this.iServerToken := ((serverTokenEdit = "") ? "__INVALID__" : serverTokenEdit)
				
				this.connect()
			case 4: ; Clear...
				if this.SessionActive {
					title := translate("Delete")
					
					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
					MsgBox 262436, %title%, % translate("Do you really want to delete all data from the currently active session? This can take quite a while...")
					OnMessage(0x44, "")
					
					IfMsgBox Yes
						this.clearSession()
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("You are not connected to an active session.")
					OnMessage(0x44, "")
				}
			case 6: ; Load Session...
				this.loadSession()
			case 7: ; Save Session
				if this.HasData {
					if this.SessionActive
						this.saveSession()
					else {
						title := translate("Information")

						OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
						MsgBox 262192, %title%, % translate("You are not connected to an active session. Use ""Save a Copy..."" instead.")
						OnMessage(0x44, "")
					}
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no session data to be saved.")
					OnMessage(0x44, "")
				}
			case 8: ; Save Session Copy...
				if this.HasData
					this.saveSession(true)
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no session data to be saved.")
					OnMessage(0x44, "")
				}
			case 10: ; Update Statistics
				this.updateStatistics()
			case 12: ; Race Summary
				this.showRaceSummary()
			case 13: ; Driver Statistics
				this.showDriverStatistics()
		}
	}
	
	chooseStrategyMenu(line) {
		local strategy
		
		if this.Simulator {
			simulator := this.Simulator
			car := this.Car
			track := this.Track
			sessionDB := new SessionDatabase()
			simulatorCode := sessionDB.getSimulatorCode(simulator)
			
			dirName = %kDatabaseDirectory%Local\%simulatorCode%\%car%\%track%\Race Strategies
			
			FileCreateDir %dirName%
		}
		else
			dirName := ""
			
		switch line {
			case 3:
				fileName := kUserConfigDirectory . "Race.strategy"
				
				if FileExist(fileName) {
					configuration := readConfiguration(fileName)
					
					if (configuration.Count() > 0)
						this.selectStrategy(this.createStrategy(configuration), true)
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no active Race Strategy.")
					OnMessage(0x44, "")
				}
			case 4:
				title := translate("Load Race Strategy...")
				
				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Load", "Cancel"]))
				FileSelectFile file, 1, %dirName%, %title%, Strategy (*.strategy)
				OnMessage(0x44, "")
			
				if (file != "") {
					configuration := readConfiguration(file)
					
					if (configuration.Count() > 0)
						this.selectStrategy(this.createStrategy(configuration), true)
				}
			case 5: ; "Save Strategy..."
				if this.Strategy {
					title := translate("Save Race Strategy...")
					
					fileName := (dirName . "\" . this.Strategy.Name . ".strategy")
					
					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Save", "Cancel"]))
					FileSelectFile file, S17, %fileName%, %title%, Strategy (*.strategy)
					OnMessage(0x44, "")
				
					if (file != "") {
						if !InStr(file, ".")
							file := (file . ".strategy")
			
						SplitPath file, , , , name
						
						this.Strategy.setName(name)
							
						configuration := newConfiguration()
						
						this.Strategy.saveToConfiguration(configuration)
						
						writeConfiguration(file, configuration)
					}
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no current Strategy.")
					OnMessage(0x44, "")
				}
			case 7: ; Strategy Summary
				if this.Strategy {
					this.StrategyViewer.showStrategyInfo(this.Strategy)
						
					this.iSelectedDetailReport := "Strategy"
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no current Strategy.")
					OnMessage(0x44, "")
				}
			case 9: ; Use Session Data
				this.iUseSessionData := !this.UseSessionData
				
				this.updateStrategyMenu()
			case 10: ; Use Telemetry Database
				this.iUseTelemetryDatabase := !this.UseTelemetryDatabase
				
				this.updateStrategyMenu()
			case 11: ; Use current Map
				this.iUseCurrentMap := !this.UseCurrentMap
				
				this.updateStrategyMenu()
			case 12: ; Use Traffic
				title := translate("Information")

				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
				MsgBox 262192, %title%, % translate("Not yet implemented...")
				OnMessage(0x44, "")
			case 14: ; Run Simulation
				if this.Strategy {
					sessionType := getConfigurationValue(this.Strategy, "Session", "SessionType")
					
					new VariationSimulation(this, sessionType, new this.SessionTelemetryDatabase(this, this.Simulator, this.Car, this.Track)).runSimulation(true)
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no current Strategy.")
					OnMessage(0x44, "")
				}
			case 16: ; Discard Strategy
				if this.Strategy {
					if this.SessionActive {
						title := translate("Strategy")
						
						OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
						MsgBox 262436, %title%, % translate("Do you really want to discard the active strategy? Strategist will be instructed in the next lap...")
						OnMessage(0x44, "")
						
						IfMsgBox Yes
						{
							this.discardStrategy()
							
							if (this.SelectedDetailReport = "Strategy")
								this.showDetails(false, false)
						}
					}
					else {
						title := translate("Information")

						OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
						MsgBox 262192, %title%, % translate("You are not connected to an active session.")
						OnMessage(0x44, "")
					}
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no current Strategy.")
					OnMessage(0x44, "")
				}
			case 18: ; Instruct Strategist
				if this.Strategy {
					if this.SessionActive
						this.updateStrategy()
					else {
						title := translate("Information")

						OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
						MsgBox 262192, %title%, % translate("You are not connected to an active session.")
						OnMessage(0x44, "")
					}
				}
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("There is no current Strategy.")
					OnMessage(0x44, "")
				}
		}
	}
	
	choosePlanMenu(line) {
		switch line {
			case 3:
				this.loadPlanFromStrategy()
			case 4:
				window := this.Window
				
				Gui %window%:Default
				
				Gui ListView, % this.PlanListView
				
				if (LV_GetCount() > 0) {
					title := translate("Delete")
					
					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
					MsgBox 262436, %title%, % translate("Do you really want to delete the current plan?")
					OnMessage(0x44, "")
					
					IfMsgBox Yes
					{
						LV_Delete()
						
						this.Version := (A_Now . "")
					}
				}
			case 6:
				this.showPlanDetails()
						
				this.iSelectedDetailReport := "Plan"
			case 8:
				if this.SessionActive
					this.releasePlan()
				else {
					title := translate("Information")

					OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
					MsgBox 262192, %title%, % translate("You are not connected to an active session.")
					OnMessage(0x44, "")
				}
		}
	}
	
	choosePitstopMenu(line) {
		switch line {
			case 3:
				this.initializePitstopFromSession()
			case 4:
				exePath := kBinariesDirectory . "Setup Database.exe"
				
				try {
					Process Exist
					
					options := ["-Simulator", this.Simulator, "-Car", this.Car, "-Track", this.Track, "-Weather", this.Weather
							  , "-AirTemperature", this.AirTemperature, "-TrackTemperature", this.TrackTemperature, "-Setup", ErrorLevel]
					options := values2String(A_Space, options*)
					
					Run "%exePath%" %options%, %kBinariesDirectory%, , pid
				}
				catch exception {
					logMessage(kLogCritical, translate("Cannot start the Setup Database tool (") . exePath . translate(") - please rebuild the applications in the binaries folder (") . kBinariesDirectory . translate(")"))
						
					showMessage(substituteVariables(translate("Cannot start the Setup Database tool (%exePath%) - please check the configuration..."), {exePath: exePath})
							  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
				}
			case 6:
				this.planPitstop()
		}
	}
	
	withExceptionHandler(function, arguments*) {
		; try {
			return %function%(arguments*)
		/*}
		catch exception {
			title := translate("Error")
		
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			MsgBox 262160, %title%, % (translate("Error while executing command.") . "`n`n" . translate("Error: ") . exception.Message)
			OnMessage(0x44, "")
		}
		*/
	}
	
	createStrategy(nameOrConfiguration := false) {
		name := nameOrConfiguration
		
		if !IsObject(nameOrConfiguration)
			nameOrConfiguration := false
		
		theStrategy := new this.SessionStrategy(this, nameOrConfiguration)
		
		if (name && !IsObject(name))
			theStrategy.setName(name)
		
		return theStrategy
	}
	
	selectStrategy(strategy, show := false) {
		this.iStrategy := strategy
		
		if (show || (this.SelectedDetailReport = "Strategy") || !this.SelectedDetailReport)
			if strategy {
				this.StrategyViewer.showStrategyInfo(this.Strategy)
				
				this.iSelectedDetailReport := "Strategy"
			}
			else {
				this.showDetails(false, false)
			
				this.iSelectedDetailReport := false
			}
	}
	
	getStrategySettings(ByRef simulator, ByRef car, ByRef track, ByRef weather, ByRef airTemperature, ByRef trackTemperature
					  , ByRef sessionType, ByRef sessionLength
					  , ByRef maxTyreLaps, ByRef tyreCompound, ByRef tyreCompoundColor, ByRef tyrePressures) {
		local strategy := this.Strategy
		
		if this.Simulator {
			simulator := new SessionDatabase().getSimulatorName(this.Simulator)
			car := this.Car
			track := this.Track
		}
		else if strategy {
			simulator := strategy.Simulator
			car := strategy.Car
			track := strategy.Track
		}
		else
			return false
			
		if this.Weather {
			weather := this.Weather
			airTemperature := this.AirTemperature
			trackTemperature := this.TrackTemperature
		}
		else if strategy {
			weather := strategy.Weather
			airTemperature := strategy.AirTemperature
			track := strategy.TrackTemperature
		}
		else
			return false
		
		if this.TyreCompound {
			tyreCompound := this.TyreCompound
			tyreCompoundColor := this.TyreCompoundColor
		}
		else if strategy {
			tyreCompound := strategy.TyreCompound
			tyreCompoundColor := strategy.TyreCompoundColor
		}
		else
			return false
		
		if strategy {
			sessionType := strategy.SessionType
			sessionLength := strategy.SessionLength
			maxTyreLaps := strategy.MaxTyreLaps
			tyrePressures := strategy.TyrePressures
		}
		else
			return false
	
		return true
	}
	
	getSessionSettings(ByRef stintLength, ByRef formationLap, ByRef postRaceLap, ByRef fuelCapacity, ByRef safetyFuel
					 , ByRef pitstopDelta, ByRef pitstopRefuelService, ByRef pitstopTyreService) {
		if this.Strategy {
			stintLength := this.Strategy.StintLength
			formationLap := this.Strategy.FormationLap
			postRaceLap := this.Strategy.PostRaceLap
			
			fuelCapacity := this.Strategy.FuelCapacity
			safetyFuel := this.Strategy.SafetyFuel
			
			pitstopDelta := this.Strategy.PitstopDelta
			pitstopFuelService := this.Strategy.PitstopFuelService
			pitstopTyreService := this.Strategy.PitstopTyreService
			
			return true
		}
		else
			return false
	}
	
	getStartConditions(ByRef initialLap, ByRef initialStintTime, ByRef initialTyreLaps, ByRef initialFuelAmount
					 , ByRef initialMap, ByRef initialFuelConsumption, ByRef initialAvgLapTime) {
		this.syncSessionDatabase()
		
		lastLap := this.LastLap
		initialLap := 0
		initialStintTime := 0
		initialTyreLaps := 0
		initialFuelAmount := 0
		initialMap := "n/a"
		initialFuelConsumption := 0
		initialAvgLapTime := 0.0
		
		if lastLap {
			telemetryDB := this.TelemetryDatabase
			
			initialLap := lastLap.Nr + 1
			initialFuelAmount := lastLap.FuelRemaining
			initialMap := lastLap.Map
			initialFuelConsumption := lastLap.FuelConsumption
			initialAvgLapTime := lastLap.AvgLapTime
			
			Loop % lastLap.nr
				initialStintTime += lastLap.Laptime
			
			tyresTable := telemetryDB.Database.Tables["Tyres"]
	
			lap := tyresTable.Length()
			
			if (tyresTable.Length() >= lastLap.Nr)
				initialTyreLaps := tyresTable[lastLap.Nr]["Tyre.Laps"]
			else
				initialTyreLaps := 0
		}
	}
	
	getSimulationSettings(ByRef useStartConditions, ByRef useTelemetryData, ByRef consumptionWeight, ByRef initialFuelWeight, ByRef tyreUsageWeight) {
		useStartConditions := false
		useTelemetryData := true
		
		consumptionWeight := 0
		initialFuelWeight := 0
		tyreUsageWeight := 0
		
		return true
	}
	
	getPitstopRules(ByRef pitstopRequired, ByRef refuelRequired, ByRef tyreChangeRequired) {
		if this.Strategy {
			pitstopRequired := this.Strategy.PitstopRequired
			refuelRequired := this.Strategy.RefuelRequired
			tyreChangeRequired := this.Strategy.TyreChangeRequired
			
			return true
		}
		else
			return false
	}
	
	getAvgLapTime(map, remainingFuel, default := false) {
		lapTimes := this.TelemetryDatabase.getLapTimes(this.Weather, this.TyreCompound, this.TyreCompoundColor)
		
		lapTime := lookupLapTime(lapTimes, map, remainingFuel)
		
		return lapTime ? lapTime : (default ? default : this.Strategy.AvgLapTime)
	}
	
	chooseScenario(strategy) {
		if strategy
			this.selectStrategy(strategy, true)
	}
	
	showWait(state := true) {
		if state
			vWait += 1
		else {
			vWait -= 1
		
			if (vWait > 0)
				return
			else
				vWait := 0
		}
		
		waitViewer.Document.Open()

		html := (state ? ("<img src='" . (kResourcesDirectory . "Wait.gif") . "' width=28 height=28 border=0 padding=0></body></html>") : "")
		html := ("<html><body style='background-color: #D0D0D0' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>" . html . "</body></html>")
		
		waitViewer.Document.Write(html)
		waitViewer.Document.Close()
	}
	
	hideWait() {
		this.showWait(false)
	}
	
	initializeSession() {
		this.iSessionFinished := false
		this.iSessionLoaded := false
		
		if this.SessionActive {
			directory := this.SessionDirectory
			
			try {
				FileRemoveDir %directory%, 1
			}
			catch exception {
				; ignore
			}
			
			FileCreateDir %directory%
			
			reportDirectory := (directory . "Race Report")
			
			try {
				FileRemoveDir %reportDirectory%, 1
			}
			catch exception {
				; ignore
			}
		
			FileCreateDir %reportDirectory%
			
			this.ReportViewer.setReport(reportDirectory)
		}
		
		Gui ListView, % this.PlanListView
		
		LV_Delete()
		
		Gui ListView, % this.StintsListView
		
		LV_Delete()
		
		Gui ListView, % this.LapsListView
		
		LV_Delete()
		
		Gui ListView, % this.PitstopsListView
		
		LV_Delete()
		
		GuiControl, , driverDropDownMenu, % "|"
		
		this.iDrivers := []
		this.iStints := {}
		this.iLaps := {}
		
		this.iLastLap := false
		this.iCurrentStint := false
		
		this.iTelemetryDatabase := false
		this.iPressuresDatabase := false
		this.iSessionDatabase := false
		
		this.iSelectedReport := false
		this.iSelectedChartType := false
		this.iSelectedDetailReport := false

		GuiControlGet sessionDateCal
		GuiControlGet sessionTimeEdit
		
		this.iDate := sessionDateCal
		this.iTime := sessionTimeEdit
		
		this.iSimulator := false
		this.iCar := false
		this.iTrack := false
	
		this.iWeather := false
		this.iAirTemperature := false
		this.iTrackTemperature := false
		
		this.iTyreCompound := false
		this.iTyreCompoundColor := false
	
		this.showChart(false)
		this.showDetails(false, false)
	}
	
	loadNewStints(currentStint) {
		session := this.SelectedSession[true]
		newStints := []
			
		if (!this.CurrentStint || (currentStint.Nr > this.CurrentStint.Nr)) {
			for ignore, identifier in string2Values(";", this.Connector.GetSessionStints(session))
				if !this.Stints.HasKey(identifier) {
					newStint := parseObject(this.Connector.GetStint(identifier))
					newStint.Nr := (newStint.Nr + 0)
					
					time := this.Connector.GetStintValue(identifier, "Time")
						
					if (!time || (time == ""))
						newStint.Time := ((newStint.Nr == 1) ? (A_Now . "") : false)
					else
						newStint.Time := time
					
					newStints.Push(newStint)
				}
			
			Loop % newStints.Length()
			{
				stint := newStints[A_Index]
				identifier := stint.Identifier
				
				driver := this.addDriver(parseObject(this.Connector.GetDriver(this.Connector.GetStintDriver(identifier))))
				
				stint.Driver := driver
				driver.Stints.Push(stint)
				stint.FuelConsumption := 0.0
				stint.Accidents := 0
				stint.Weather := "-"
				stint.Compound := "-"
				stint.StartPosition := "-"
				stint.EndPosition := "-"
				stint.AvgLaptime := "-"
				stint.Potential := "-"
				stint.RaceCraft := "-"
				stint.Speed := "-"
				stint.Consistency := "-"
				stint.CarControl := "-"
				
				stint.Laps := []
				
				this.Stints[identifier] := stint
				this.Stints[stint.Nr] := stint
			}
		}
		
		bubbleSort(newStints, "objectOrder")
			
		return newStints
	}

	loadNewLaps(stint) {
		newLaps := []
		
		stintLaps := string2Values(";" , this.Connector.GetStintLaps(stint.Identifier))
		
		for ignore, identifier in stintLaps
			if !this.Laps.HasKey(identifier) {
				newLap := parseObject(this.Connector.GetLap(identifier))
				newLap.Nr := (newLap.Nr + 0)
				
				if !this.Laps.HasKey(newLap.Nr)
					newLaps.Push(newLap)
			}
		
		bubbleSort(newLaps, "objectOrder")
		
		count := newLaps.Length()
		
		Loop %count% {
			lap := newLaps[A_Index]
			identifier := lap.Identifier
			
			lap.Stint := stint
			
			tries := ((A_Index == count) ? 10 : 1)
			
			while (tries > 0) {
				rawData := this.Connector.GetLapValue(identifier, "Telemetry Data")
				
				if (!rawData || (rawData == "")) {
					tries -= 1
					
					if (tries <= 0) {
						newLaps.RemoveAt(A_Index, newLaps.Length() - A_Index + 1)
						
						return newLaps
					}
					else
						Sleep 400
				}
				else
					break
			}
			
			if (stint.Laps.Length() == 0)
				stint.Lap := lap.Nr
			
			stint.Laps.Push(lap)
			stint.Driver.Laps.Push(lap)
				
			data := parseConfiguration(rawData)
			
			lap.Telemetry := rawData
			
			damage := 0
			
			for ignore, value in string2Values(",", getConfigurationValue(data, "Car Data", "BodyworkDamage"))
				damage += value
			
			for ignore, value in string2Values(",", getConfigurationValue(data, "Car Data", "SuspensionDamage"))
				damage += value
			
			lap.Damage := damage
			
			if ((lap.Nr == 1) && (damage > 0))
				lap.Accident := true
			else if ((lap.Nr > 1) && (damage > this.Laps[lap.Nr - 1].Damage))
				lap.Accident := true
			else
				lap.Accident := false
			
			lap.FuelRemaining := Round(getConfigurationValue(data, "Car Data", "FuelRemaining"), 1)
			
			if ((lap.Nr == 1) || (stint.Laps[1] == lap))
				lap.FuelConsumption := "-"
			else
				lap.FuelConsumption := Round((this.Laps[lap.Nr - 1].FuelRemaining - lap.FuelRemaining), 1)
			
			lap.Laptime := Round(getConfigurationValue(data, "Stint Data", "LapLastTime") / 1000, 1)
			
			lap.Map := getConfigurationValue(data, "Car Data", "Map")
			lap.TC := getConfigurationValue(data, "Car Data", "TC")
			lap.ABS := getConfigurationValue(data, "Car Data", "ABS")
			
			lap.Weather := getConfigurationValue(data, "Weather Data", "Weather")
			lap.AirTemperature := Round(getConfigurationValue(data, "Weather Data", "Temperature"), 1)
			lap.TrackTemperature := Round(getConfigurationValue(data, "Track Data", "Temperature"), 1)
			lap.Grip := getConfigurationValue(data, "Track Data", "Grip")
			
			compound := getConfigurationValue(data, "Car Data", "TyreCompound")
			color := getConfigurationValue(data, "Car Data", "TyreCompoundColor")
			
			if (color != "Black")
				compound .= (" (" . color . ")")
			
			lap.Compound := compound
			
			try {
				tries := ((A_Index == count) ? 10 : 1)
			
				while (tries > 0) {
					rawData := this.Connector.GetLapValue(identifier, "Positions Data")
					
					if (!rawData || (rawData = "")) {
						tries -= 1
						
						if (tries <= 0)
							throw "No data..."
						else
							Sleep 400
					}
					else
						break
				}
				
				data := parseConfiguration(rawData)
				
				lap.Positions := rawData
				
				car := getConfigurationValue(data, "Position Data", "Driver.Car")
				
				if car
					lap.Position := getConfigurationValue(data, "Position Data", "Car." . car . ".Position")
				else
					throw "No data..."
			}
			catch exception {
				if (lap.Nr > 1)
					lap.Position := this.Laps[lap.Nr - 1].Position
			}
			
			this.Laps[identifier] := lap
			this.Laps[lap.Nr] := lap
		}
		
		return newLaps
	}
		
	updateStint(stint) {
		window := this.Window
				
		Gui %window%:Default
		
		stint.FuelConsumption := 0.0
		stint.Accidents := 0
		stint.Weather := ""
		
		laps := stint.Laps
		numLaps := laps.Length()
		
		lapTimes := []
		
		for ignore, lap in laps {
			if (lap.Nr > 1) {
				consumption := lap.FuelConsumption
					
				if consumption is number
					stint.FuelConsumption += ((this.Laps[lap.Nr - 1].FuelConsumption = "-") ? (consumption * 2) : consumption)
			}
				
			if lap.Accident
				stint.Accidents += 1
			
			lapTimes.Push(lap.Laptime)
			
			if (A_Index == 1) {
				stint.Compound := lap.Compound
				stint.StartPosition := lap.Position
			}
			else if (A_Index == numLaps)
				stint.EndPosition := lap.Position
			
			weather := lap.Weather
			
			if (stint.Weather = "")
				stint.Weather := weather
			else if !inList(string2Values(",", stint.Weather), weather)
				stint.Weather .= (", ", weather)
		}
		
		stint.AvgLaptime := Round(average(laptimes), 1)
		stint.BestLaptime := Round(minimum(laptimes), 1)
		stint.FuelConsumption := Round(stint.FuelConsumption, 1)
		
		Gui ListView, % this.StintsListView
		
		LV_Modify(stint.Row, "", stint.Nr, stint.Driver.FullName, values2String(", ", map(string2Values(",", stint.Weather), "translate")*)
							   , translate(stint.Compound), stint.Laps.Length()
							   , stint.StartPosition, stint.EndPosition, stint.AvgLaptime, stint.FuelConsumption, stint.Accidents
							   , stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)
		
		this.updatePlan(stint)
	}
	
	syncLaps() {
		session := this.SelectedSession[true]
		
		window := this.Window
		
		Gui %window%:Default
		
		try {
			lastLap := this.Connector.GetSessionLastLap(session)
			
			if lastLap {
				lastLap := parseObject(this.Connector.GetLap(lastLap))
				lastLap.Nr := (lastLap.Nr + 0)
			}
				
		}
		catch exception {
			lastLap := false
		}
		
		if !lastLap
			return false
		
		try {
			currentStint := this.Connector.GetSessionCurrentStint(session)
			
			if currentStint {
				currentStint := parseObject(this.Connector.GetStint(currentStint))
				currentStint.Nr := (currentStint.Nr + 0)
			}
		}
		catch exception {
			currentStint := false
		}
		
		first := (!this.CurrentStint || !this.LastLap)
		
		if (!currentStint
		 || (!lastLap && this.CurrentStint && !((currentStint.Nr = (this.CurrentStint.Nr + 1)) && (currentStint.Lap == this.LastLap.Nr)))
		 || (this.CurrentStint && ((currentStint.Nr < this.CurrentStint.Nr)
								|| ((currentStint.Nr = this.CurrentStint.Nr) && (currentStint.Identifier != this.CurrentStint.Identifier))))
		 || (this.LastLap && (lastLap.Nr < this.LastLap.Nr))) {
			this.initializeSession()
			
			first := true
		}
		
		newData := first
		
		if (!this.LastLap || (lastLap.Nr > this.LastLap.Nr)) {
			try {
				newStints := this.loadNewStints(currentStint)
				
				currentStint := this.Stints[currentStint.Identifier]
				
				updatedStints := []
				
				if this.CurrentStint
					updatedStints := [this.CurrentStint]
					
				Gui ListView, % this.StintsListView
				
				for ignore, stint in newStints {
					LV_Add("", stint.Nr, stint.Driver.FullName, values2String(", ", map(string2Values(",", stint.Weather), "translate")*)
							 , translate(stint.Compound), stint.Laps.Length()
							 , stint.StartPosition, stint.EndPosition, stint.AvgLaptime, stint.FuelConsumption, stint.Accidents
							 , stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)
					
					stint.Row := LV_GetCount()
					
					updatedStints.Push(stint)
				}
				
				if first {
					LV_ModifyCol()
					
					Loop % LV_GetCount("Col")
						LV_ModifyCol(A_Index, "AutoHdr")
				}
		
				Gui ListView, % this.LapsListView
				
				for ignore, stint in updatedStints {
					for ignore, lap in this.loadNewLaps(stint) {
						LV_Add("", lap.Nr, stint.Nr, stint.Driver.Fullname, lap.Position, translate(lap.Weather), translate(lap.Grip), lap.Laptime, lap.FuelConsumption, lap.FuelRemaining, "", lap.Accident ? translate("x") : "")
					
						lap.Row := LV_GetCount()
					}
				}
				
				if first {
					LV_ModifyCol()
					
					Loop % LV_GetCount("Col")
						LV_ModifyCol(A_Index, "AutoHdr")
				}
				
				for ignore, stint in updatedStints
					this.updateStint(stint)
				
				newData := true
				
				this.iLastLap := this.Laps[lastLap.Nr]
				this.iCurrentStint := currentStint
				
				lastLap := this.LastLap
				
				if lastLap {
					this.iWeather := lastLap.Weather
					this.iAirTemperature := lastLap.AirTemperature
					this.iTrackTemperature := lastLap.TrackTemperature
				}
				
				currentStint := this.CurrentStint
				
				if currentStint {
					this.iTyreCompound := compound(currentStint.Compound)
					this.iTyreCompoundColor := compoundColor(currentStint.Compound)
				}
			}
			catch exception {
				return newData
			}
		}
		
		return newData
	}
	
	syncRaceReport() {
		lastLap := this.LastLap
		
		if lastLap
			lastLap := lastLap.Nr
		else
			return
		
		directory := this.SessionDirectory . "Race Report\"
		
		FileCreateDir %directory%
		
		data := readConfiguration(directory . "Race.data")
		
		if (data.Count() == 0)
			lap := 1
		else
			lap := (getConfigurationValue(data, "Laps", "Count") + 1)
		
		if (lap == 1) {
			try {
				try {
					raceInfo := this.Connector.getLapValue(this.Laps[lap].Identifier, "Race Strategist Race Info")
				}
				catch exception {
					raceInfo := false
				}

				if (!raceInfo || (raceInfo == ""))
					return
					
				FileAppend %raceInfo%, %directory%Race.data
			}
			catch exception {
				; ignore
			}
				
			data := readConfiguration(directory . "Race.data")
		}
		
		pitstops := false
		newData := false
		
		while (lap <= lastLap) {
			try {
				lapData := this.Connector.getLapValue(this.Laps[lap].Identifier, "Race Strategist Race Lap")
				
				if (lapData && (lapData != ""))
					lapData := parseConfiguration(lapData)
				else
					throw "No data..."
			}
			catch exception {
				return newData
			}
			
			if (lapData.Count() == 0)
				return
			
			for key, value in getConfigurationSectionValues(lapData, "Lap")
				setConfigurationValue(data, "Laps", key, value)
				
			pitstops := getConfigurationValue(lapData, "Pitstop", "Laps", "")
			
			times := getConfigurationValue(lapData, "Times", lap)
			positions := getConfigurationValue(lapData, "Positions", lap)
			laps := getConfigurationValue(lapData, "Laps", lap)
			drivers := getConfigurationValue(lapData, "Drivers", lap)
			
			newLine := ((lap > 1) ? "`n" : "")
			
			line := (newLine . times)
			
			FileAppend %line%, % directory . "Times.CSV"
			
			line := (newLine . positions)
			
			FileAppend %line%, % directory . "Positions.CSV"
			
			line := (newLine . laps)
			
			FileAppend %line%, % directory . "Laps.CSV"
			
			line := (newLine . drivers)
			fileName := (directory . "Drivers.CSV")
			
			FileAppend %line%, %fileName%, UTF-16
			
			removeConfigurationValue(data, "Laps", "Lap")
			setConfigurationValue(data, "Laps", "Count", lap)
			
			newData := true
			lap += 1
		}
		
		if newData {
			setConfigurationValue(data, "Laps", "Pitstops", pitstops)
				
			writeConfiguration(directory . "Race.data", data)
		}
		
		return newData
	}
	
	syncTelemetry(load := false) {
		lastLap := this.LastLap
		
		if lastLap
			lastLap := lastLap.Nr
		else
			return false
		
		newData := false
		
		if !load {
			session := this.SelectedSession[true]
			telemetryDB := this.TelemetryDatabase
			
			tyresTable := telemetryDB.Database.Tables["Tyres"]
		
			lap := tyresTable.Length()
			
			if (lap > 0)
				runningLap := tyresTable[lap]["Tyre.Laps"]
			else
				runningLap := 0
		
			lap += 1
			
			while (lap <= lastLap) {
				try {
					tries := ((lap == lastLap) ? 10 : 1)
			
					while (tries > 0) {
						telemetryData := this.Connector.GetSessionLapValue(session, lap, "Race Strategist Telemetry")
						
						if (!telemetryData || (telemetryData == "")) {
							tries -= 1
							
							if (tries <= 0)
								throw "No data..."
							else
								Sleep 400
						}
						else
							break
					}
				}
				catch exception {
					state := false
					
					try {
						state := this.Connector.GetSessionValue(session, "Race Engineer State")
					}
					catch exception {
						; ignore
					}
				
					if (state && (state != "")) {
						state := parseConfiguration(state)
						
						pitstop := getConfigurationValue(state, "Session State", "Pitstop.Last", false)
				
						if pitstop
							pitstop := (lap == (getConfigurationValue(state, "Session State", "Pitstop." . pitstop . ".Lap") + 1))
					}
					else
						pitstop := false
				
					telemetryData := values2String(";", "-", "-", "-", "-", "-", "-", "-", "-", "-", pitstop, "n/a", "n/a", "n/a", "-", "-", ",,,", ",,,")
				}
				
				telemetryData := string2Values(";", telemetryData)
			
				if telemetryData[10]
					runningLap := 0
				
				runningLap += 1
				
				pressures := string2Values(",", telemetryData[16])
				temperatures := string2Values(",", telemetryData[17])
				
				telemetryDB.addElectronicEntry(telemetryData[4], telemetryData[5], telemetryData[6], telemetryData[14], telemetryData[15]
											 , telemetryData[11], telemetryData[12], telemetryData[13], telemetryData[7], telemetryData[8], telemetryData[9])
											 
				telemetryDB.addTyreEntry(telemetryData[4], telemetryData[5], telemetryData[6], telemetryData[14], telemetryData[15], runningLap
									   , pressures[1], pressures[2], pressures[4], pressures[4]
									   , temperatures[1], temperatures[2], temperatures[3], temperatures[4]
									   , telemetryData[7], telemetryData[8], telemetryData[9])
				
				newData := true
				lap += 1
			}
		}
		
		return newData
	}
	
	syncTyrePressures(load := false) {
		if load {
			Gui ListView, % this.LapsListView
			
			lastLap := this.LastLap
			
			if lastLap
				lastLap := (lastLap.Nr + 0)
			
			for ignore, pressureData in this.PressuresDatabase.Database.Tables["Setup.Pressures"] {
				if (A_Index > lastLap)
					break
				
				pressureFL := pressureData["Tyre.Pressure.Hot.Front.Left"]
				pressureFR := pressureData["Tyre.Pressure.Hot.Front.Right"]
				pressureRL := pressureData["Tyre.Pressure.Hot.Rear.Left"]
				pressureRR := pressureData["Tyre.Pressure.Hot.Rear.Right"]
				
				if (pressureFL == kNull)
					pressureFL := "-"
				
				if (pressureFR == kNull)
					pressureFR := "-"
				
				if (pressureRL == kNull)
					pressureRL := "-"
				
				if (pressureRR == kNull)
					pressureRR := "-"
				
				LV_Modify(this.Laps[A_Index].Row, "Col10", values2String(", ", pressureFL, pressureFR, pressureRL, pressureRR))
			}
			
			return false
		}
		else {
			session := this.SelectedSession[true]
			pressuresDB := this.PressuresDatabase
			lastLap := this.LastLap
			
			if lastLap
				lastLap := lastLap.Nr
			else
				return
			
			pressuresTable := pressuresDB.Database.Tables["Setup.Pressures"]
			lap := pressuresTable.Length()
			
			newData := false
			lap += 1
			
			flush := (Abs(lastLap - lap) <= 2)
			
			while (lap <= lastLap) {
				try {
					tries := ((lap == lastLap) ? 10 : 1)
			
					while (tries > 0) {
						lapPressures := this.Connector.GetSessionLapValue(session, lap, "Race Engineer Pressures")
						
						if (!lapPressures || (lapPressures == "")) {
							tries -= 1
							
							if (tries <= 0)
								throw "No data..."
							else
								Sleep 400
						}
						else
							break
					}
				}
				catch exception {
					lapPressures := values2String(";", "-", "-", "-", "-", "-", "-", "-", "-", "-,-,-,-", "-,-,-,-")
				}
				
				lapPressures := string2Values(";", lapPressures)
				
				if (!this.iSimulator && (lapPressures[1] != "-")) {
					this.iSimulator := lapPressures[1]
					this.iCar := lapPressures[2]
					this.iTrack := lapPressures[3]
				}
				
				pressuresDB.updatePressures(lapPressures[4], lapPressures[5], lapPressures[6]
										  , lapPressures[7], lapPressures[8], string2Values(",", lapPressures[9]), string2Values(",", lapPressures[10]), flush)
				
				Gui ListView, % this.LapsListView
				
				LV_Modify(this.Laps[lap].Row, "Col10", values2String(", ", string2Values(",", lapPressures[10])*))

				newData := true
				lap += 1
			}
			
			if (newData && !flush)
				pressuresDB.Database.flush()
			
			return newData
		}
	}
	
	syncPitstops(state := false) {
		sessionDB := this.SessionDatabase
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.PitstopsListView
		
		session := this.SelectedSession[true]
		
		nextStop := (LV_GetCount() + 1)
		
		if !state
			try {
				state := this.Connector.GetSessionValue(session, "Race Engineer State")
			}
			catch exception {
				; ignore
			}
		
		if (state && (state != "")) {
			state := parseConfiguration(state)
				
			lap := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Lap", false)
			
			if lap {
				fuel := Round(getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Fuel", 0))
				compound := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Compound", false)
				compoundColor := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Compound.Color")
				tyreSet := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Set", "-")
				pressureFL := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.FL", "-")
				pressureFR := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.FR", "-")
				pressureRL := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.RL", "-")
				pressureRR := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Tyre.Pressure.RR", "-")
				repairBodywork := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Repair.Bodywork", false)
				repairSuspension := getConfigurationValue(state, "Session State", "Pitstop." . nextStop . ".Repair.Suspension", false)
				
				if (compound && (compound != "-"))
					pressures := values2String(", ", Round(pressureFL, 1), Round(pressureFR, 1), Round(pressureRL, 1), Round(pressureRR, 1))
				else {
					compound := "-"
					compoundColor := false
				
					tyreSet := "-"
					pressures := "-, -, -, -"
				}
				
				if (repairBodywork && repairSuspension)
					repairs := (translate("Bodywork") . ", " . translate("Suspension"))
				else if repairBodywork
					repairs := translate("Bodywork")
				else if repairSuspension
					repairs := translate("Suspension")
				else
					repairs := "-"
				
				Gui ListView, % this.PitstopsListView
				
				LV_Add("", nextStop, lap, fuel, translate(compound(compound, compoundColor)), tyreSet, pressures, repairs)
				
				if (nextStop = 1) {
					LV_ModifyCol()
					
					Loop % LV_GetCount("Col")
						LV_ModifyCol(A_Index, "AutoHdr")
				}
				
				pressures := string2Values(",", pressures)
				
				sessionDB.add("Pitstop.Data", {Lap: lap, Fuel: fuel, "Tyre.Compound": compound, "Tyre.Compound.Color": compoundColor, "Tyre.Set": tyreSet
											 , "Tyre.Pressure.Cold.Front.Left": pressures[1], "Tyre.Pressure.Cold.Front.Right": pressures[2]
											 , "Tyre.Pressure.Cold.Rear.Left": pressures[3], "Tyre.Pressure.Cold.Rear.Right": pressures[4]
											 , "Repair.Bodywork": repairBodywork, "Repair.Suspension": repairSuspension})
											  
				this.syncPitstop(state)
			}
		}
	}
	
	syncStrategy() {
		local strategy
		
		try {
			session := this.SelectedSession[true]
			
			version := this.Connector.getSessionValue(session, "Race Strategy Version")
			
			if (version && (version != ""))
				if (!this.Strategy || (this.Strategy.Version && (version > this.Strategy.Version))) {
					strategy := this.Connector.getSessionValue(session, "Race Strategy")
				
					this.selectStrategy((strategy = "CANCEL") ? false : this.createStrategy(parseConfiguration(strategy)))
				}
		}
		catch exception {
			; ignore
		}
	}
	
	syncPlan() {
		try {
			session := this.SelectedSession[true]
			
			version := this.Connector.getSessionValue(session, "Stint Plan Version")
			
			if (version && (version != "")) {
				window := this.Window
				
				Gui %window%:Default
				
				Gui ListView, % this.PlanListView
				
				if ((LV_GetCount() == 0) || !this.Version || (this.Version < version)) {
					info := this.Connector.getSessionValue(session, "Stint Plan Info")
					plan := this.Connector.getSessionValue(session, "Stint Plan")
					
					this.loadPlan(info, plan)
				}
			}
		}
		catch exception {
			; ignore
		}
	}
	
	syncSession() {
		local strategy
		
		if this.SessionActive {
			window := this.Window
			
			Gui %window%:Default
	
			this.showWait()
			
			Sleep 200
			
			Gui %window%:+Disabled
	
			try {
				this.syncPlan()
				this.syncStrategy()
				
				newLaps := false
				newData := false
				
				if this.syncLaps()
					newLaps := true
				
				if this.syncRaceReport()
					newData := true
				
				if this.syncTelemetry()
					newData := true
				
				if this.syncTyrePressures()
					newData := true
				
				this.syncStandings()
				
				if newLaps
					this.syncPitstops()
			
				if (newData || newLaps)
					this.updateReports()
				
				if (!newLaps && !this.SessionFinished) {
					finished := parseObject(this.Connector.GetSession(this.SelectedSession[true])).Finished
					
					if (finished && (finished = "true")) {
						this.saveSession()
						
						this.iSessionFinished := true
					}
				}
			}
			catch exception {
				showMessage(translate("Cannot connect to the Team Server.") . "`n`n" . translate("Retry in 10 seconds."))
			}
			finally {
				Gui %window%:-Disabled
				
				this.hideWait(false)
			}
		}
	}
	
	updateReports() {
		if !this.SelectedReport
			this.iSelectedReport := "Overview"
		
		this.showReport(this.SelectedReport, true)
		
		if (!this.SelectedDetailReport && this.Strategy)
			this.StrategyViewer.showStrategyInfo(this.Strategy)
	}
	
	getCar(lap, car, ByRef carNumber, ByRef carName, ByRef driverForname, ByRef driverSurname, ByRef driverNickname) {
		this.ReportViewer.getCar(lap.Nr, car, carNumber, carName, driverForname, driverSurname, driverNickname)
	}
	
	getStandings(lap, ByRef cars, ByRef positions, ByRef carNumbers, ByRef carNames, ByRef driverFornames, ByRef driverSurnames, ByRef driverNicknames) {
		tCars := true
		tPositions := true
		tCarNumbers := carNumbers
		tCarNames := carNames
		tDriverFornames := driverFornames
		tDriverSurnames := driverSurnames
		tDriverNicknames := driverNicknames
		
		this.ReportViewer.getStandings(lap.Nr, tCars, tPositions, tCarNumbers, tCarNames, tDriverFornames, tDriverSurnames, tDriverNicknames)
		
		if cars
			cars := []
		
		if positions
			positions := []
		
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
		
		if (tCars.Length() > 0)
			Loop % tPositions.Length()
			{
				index := inList(tPositions, A_Index)
				
				if cars
					cars.Push(tCars[index])
				
				if positions
					positions.Push(tPositions[index])
				
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
			}
	}
	
	computeStartTime(stint) {
		if stint.Time
			return stint.Time
		else {
			if (stint.Nr = 1) {
				stint.Time := (A_Now . "")
				
				time := stint.Time
			}
			else {
				lastStint := this.Stints[stint.Nr - 1]
				duration := 0
			
				for ignore, lap in lastStint.Laps
					duration += lap.LapTime
				
				time := this.computeStartTime(lastStint)
				
				EnvAdd time, %duration%, Seconds
			}
			
			if (stint != this.CurrentStint)
				stint.Time := time
				
			return time
		}
	}
	
	computeLapStatistics(driver, laps, ByRef potential, ByRef raceCraft, ByRef speed, ByRef consistency, ByRef carControl) {
		raceData := true
		drivers := false
		positions := true
		times := true
		
		this.ReportViewer.loadReportData(laps, raceData, drivers, positions, times)
			
		car := getConfigurationValue(raceData, "Cars", "Driver", false)
		
		if car {		
			cars := []
			
			Loop % getConfigurationValue(raceData, "Cars", "Count")
				cars.Push(A_Index)
		
			potentials := false
			raceCrafts := false
			speeds := false
			consistencies := false
			carControls := false
			
			count := laps.Length()
			laps := []
			
			Loop %count%
				laps.Push(A_Index)
			
			oldLapSettings := (this.ReportViewer.Settings.HasKey("Laps") ? this.ReportViewer.Settings["Laps"] : false)
			
			try {
				this.ReportViewer.Settings["Laps"] := laps
				
				this.ReportViewer.getDriverStats(raceData, cars, positions, times, potentials, raceCrafts, speeds, consistencies, carControls)
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
	}
	
	updateStintStatistics(stint) {
		laps := []
		
		for ignore, lap in stint.Laps
			laps.Push(lap.Nr)

		potential := false
		raceCraft := false
		speed := false
		consistency := false
		carControl := false
		
		this.computeLapStatistics(stint.Driver, laps, potential, raceCraft, speed, consistency, carControl)
			
		stint.Potential := potential
		stint.RaceCraft := raceCraft
		stint.Speed := speed
		stint.Consistency := consistency
		stint.CarControl := carControl
	}
	
	updateDriverStatistics(driver) {
		laps := []
		accidents := 0
		
		for ignore, lap in driver.Laps {
			laps.Push(lap.Nr)
		
			if lap.Accident
				accidents += 1
		}
		
		potential := false
		raceCraft := false
		speed := false
		consistency := false
		carControl := false
		
		this.computeLapStatistics(driver, laps, potential, raceCraft, speed, consistency, carControl)
			
		driver.Potential := potential
		driver.RaceCraft := raceCraft
		driver.Speed := speed
		driver.Consistency := consistency
		driver.CarControl := carControl
	}
	
	updateStatistics() {
		x := Round((A_ScreenWidth - 300) / 2)
		y := A_ScreenHeight - 150
			
		progressWindow := showProgress({x: x, y: y, color: "Green", title: translate("Updating Stint Statistics")})
		
		currentStint := this.CurrentStint
		
		if currentStint {
			count := currentStint.Nr
			
			Loop %count% {
				showProgress({progress: Round((A_Index / count) * 50), color: "Green", message: translate("Stint: ") . A_Index})
			
				stint := this.Stints[A_Index]
				
				this.updateStintStatistics(stint)
					
				window := this.Window
				
				Gui %window%:Default
				
				Gui ListView, % this.StintsListView

				LV_Modify(stint.Row, "Col11", stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)
				
				Sleep 200
			}
		}
		
		showProgress({title: translate("Updating Driver Statistics"), message: translate("...")})
		
		count := this.Drivers.Length()
		
		for ignore, driver in this.Drivers {
			showProgress({progress: 50 + Round((A_Index / count) * 50), color: "Green", message: translate("Driver: ") . driver.FullName})
		
			this.updateDriverStatistics(driver)
			
			Sleep 200
		}
	
		hideProgress()
	}
	
	savePlan(flush := false) {
		sessionDB := this.SessionDatabase
		
		sessionDB.clear("Plan.Data")
					
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.PlanListView
		
		Loop % LV_GetCount()
		{
			LV_GetText(stint, A_Index, 1)
			LV_GetText(driver, A_Index, 2)
			LV_GetText(timePlanned, A_Index, 3)
			LV_GetText(timeActual, A_Index, 4)
			LV_GetText(lapPlanned, A_Index, 5)
			LV_GetText(lapActual, A_Index, 6)
			LV_GetText(refuelAmount, A_Index, 7)
			LV_GetText(tyreChange, A_Index, 8)
		
			sessionDB.add("Plan.Data", {Stint: stint, Driver: driver
									  , "Time.Planned": timePlanned, "Time.Actual": timeActual
									  , "Lap.Planned": lapPlanned, "Lap.Actual": lapActual
									  , "Fuel.Amount": refuelAmount, "Tyre.Change": tyreChange})
		}
		
		if flush
			sessionDB.flush("Plan.Data")
	}
	
	saveSession(copy := false) {
		if this.SessionActive {
			window := this.Window
			
			Gui %window%:+Disabled
			
			this.showWait()
			
			try {
				this.syncSessionDatabase(true)
				
				info := newConfiguration()
				
				setConfigurationValue(info, "Session", "Team", this.SelectedTeam)
				setConfigurationValue(info, "Session", "Session", this.SelectedSession)
				setConfigurationValue(info, "Session", "Date", this.Date)
				setConfigurationValue(info, "Session", "Time", this.Time)
				setConfigurationValue(info, "Session", "Simulator", this.Simulator)
				setConfigurationValue(info, "Session", "Car", this.Car)
				setConfigurationValue(info, "Session", "Track", this.Track)
				
				writeConfiguration(this.SessionDirectory . "Session.info", info)
			}
			finally {
				Gui %window%:-Disabled
			
				this.hideWait()
			}
		}
		else {
			this.savePlan()
		
			this.SessionDatabase.flush()
		}
		
		if copy {
			directory := (this.SessionLoaded ? this.SessionLoaded : this.SessionDirectory)
			
			title := translate("Select target folder...")
			
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Select", "Select", "Cancel"]))
			FileSelectFolder folder, *%directory%, 0, %title%
			OnMessage(0x44, "")
		
			if (folder != "") {
				session := this.SelectedSession
				
				FileCopyDir %directory%, %folder%\%session%, 1
			}
		}
	}
	
	loadDrivers() {
		this.iDrivers := []
		
		for ignore, driver in this.SessionDatabase.Tables["Driver.Data"] {
			name := computeDriverName(driver.Forname, driver.Surname, driver.Nickname)
		
			this.addDriver({Forname: driver.Forname, Surname: driver.Surname, Nickname: driver.Nickname, Fullname: name})
		}
	}
			
	loadLaps() {
		this.iLaps := []
		
		for ignore, lap in this.SessionDatabase.Tables["Lap.Data"] {
			newLap := {Nr: lap.Nr, Stint: lap.Stint, Laptime: lap["Lap.Time"], Position: lap.Position, Grip: lap.Grip
						  , Map: lap.Map, TC: lap.TC, ABS: lap.ABS
						  , Weather: lap.Weather, AirTemperature: lap["Temperature.Air"], TrackTemperature: lap["Temperature.Track"]
						  , FuelRemaining: lap["Fuel.Remaining"], FuelConsumption: lap["Fuel.Consumption"]
						  , Damage: lap.Damage, Accident: lap.Accident
						  , Compound: compound(lap["Tyre.Compound"], lap["Tyre.Compoiund.Color"])}
			
			if (newLap.Map == kNull)
				newLap.Map := "n/a"
			
			if (newLap.TC == kNull)
				newLap.TC := "n/a"
			
			if (newLap.ABS == kNull)
				newLap.ABS := "n/a"
			
			if (newLap.Position == kNull)
				newLap.Position := "-"
			
			if (newLap.Laptime == kNull)
				newLap.Laptime := "-"
			
			if (newLap.FuelConsumption == kNull)
				newLap.FuelConsumption := "-"
			
			if (newLap.FuelRemaining == kNull)
				newLap.FuelRemaining := "-"
			
			if (newLap.AirTemperature == kNull)
				newLap.AirTemperature := "-"
			
			if (newLap.TrackTemperature == kNull)
				newLap.TrackTemperature := "-"
			
			this.Laps[newLap.Nr] := newLap
			this.iLastLap := newLap
		}
	}
	
	loadStints() {
		this.iStints := []
		
		for ignore, stint in this.SessionDatabase.Tables["Stint.Data"] {
			driver := this.addDriver({Forname: stint["Driver.Forname"], Surname: stint["Driver.Surname"], Nickname: stint["Driver.Nickname"]})
			
			newStint := {Nr: stint.Nr, Lap: stint.Lap, Driver: driver
					   , Weather: stint.Weather, Compound: stint.Compound, AvgLaptime: stint["Lap.Time.Average"], BestLaptime: stint["Lap.Time.Best"]
					   , FuelConsumption: stint["Fuel.Consumption"], Accidents: stint.Accidents
					   , StartPosition: stint["Position.Start"], EndPosition: stint["Position.End"]
					   , Time: stint["Time.Start"]}
					   
			if (newStint.Time == kNull)
				newStint.Time := false
			
			driver.Stints.Push(newStint)
			laps := []
			
			newStint.Laps := laps
			
			stintNr := newStint.Nr
			stintLap := newStint.Lap
			
			Loop {
				if !this.Laps.HasKey(stintLap)
					break
				
				lap := this.Laps[stintLap]
			
				if IsObject(lap.Stint)
					newStint.Lap := (stintLap + 1)
				else
					if (lap.Stint != stintNr)
						break
					else {
						lap.Stint := newStint
						laps.Push(lap)
						
						driver.Laps.Push(lap)
					}
				
				stintLap += 1
			}
					
			newStint.Potential := "-"
			newStint.RaceCraft := "-"
			newStint.Speed := "-"
			newStint.Consistency := "-"
			newStint.CarControl := "-"

			if (newStint.AvgLaptime == kNull)
				newStint.AvgLaptime := "-"
			
			if (newStint.BestLaptime == kNull)
				newStint.BestLaptime := "-"
			
			if (newStint.FuelConsumption == kNull)
				newStint.FuelConsumption := "-"
			
			if (newStint.StartPosition == kNull)
				newStint.StartPosition := "-"
			
			if (newStint.EndPosition == kNull)
				newStint.EndPosition := "-"
			
			this.Stints[newStint.Nr] := newStint
			
			this.iCurrentStint := newStint
		}
		
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.StintsListView
			
		currentStint := this.CurrentStint
		
		if currentStint
			Loop % currentStint.Nr
			{
				stint := this.Stints[A_Index]
				stint.Row := A_Index
				
				LV_Add("", stint.Nr, stint.Driver.FullName, values2String(", ", map(string2Values(",", stint.Weather), "translate")*)
						 , translate(stint.Compound), stint.Laps.Length()
						 , stint.StartPosition, stint.EndPosition, stint.AvgLaptime, stint.FuelConsumption, stint.Accidents
						 , stint.Potential, stint.RaceCraft, stint.Speed, stint.Consistency, stint.CarControl)
			}
				
		LV_ModifyCol()
		
		Loop % LV_GetCount("Col")
			LV_ModifyCol(A_Index, "AutoHdr")
		
		Gui ListView, % this.LapsListView
			
		lastLap := this.LastLap
		
		if lastLap
			Loop % lastLap.Nr
			{
				lap := this.Laps[A_Index]
				lap.Row := A_Index
				
				LV_Add("", lap.Nr, lap.Stint.Nr, lap.Stint.Driver.Fullname, lap.Position, translate(lap.Weather), translate(lap.Grip), lap.Laptime, lap.FuelConsumption, lap.FuelRemaining, "", lap.Accident ? translate("x") : "")
			}
				
		LV_ModifyCol()
		
		Loop % LV_GetCount("Col")
			LV_ModifyCol(A_Index, "AutoHdr")
	}
	
	loadPlan(info := false, plan := false) {
		window := this.Window
		
		Gui %window%:Default
		
		if info {
			info := parseConfiguration(info)
				
			this.iVersion := getConfigurationValue(info, "Plan", "Version")
			this.iDate := getConfigurationValue(info, "Plan", "Date")
			this.iTime := getConfigurationValue(info, "Plan", "Time")
			
			GuiControl, , sessionDateCal, % this.Date
			GuiControl, , sessionTimeEdit, % this.Time
		}
		
		Gui ListView, % this.PlanListView
		
		LV_Delete()
		
		if plan {
			fileName := (this.SessionDirectory . "Plan.Data.CSV")
			
			try {
				FileDelete %fileName%
			}
			catch exception {
				; ignore
			}
			
			FileAppend %plan%, %fileName%, UTF-16
			
			this.SessionDatabase.reload("Plan.Data", false)
		}
		
		for ignore, plan in this.SessionDatabase.Tables["Plan.Data"]
			LV_Add("", plan.Stint, plan.Driver, plan["Time.Planned"], plan["Time.Actual"]
					 , plan["Lap.Planned"], plan["Lap.Actual"]
					 , plan["Fuel.Amount"], plan["Tyre.Change"])
				
		LV_ModifyCol()
		
		Loop % LV_GetCount("Col")
			LV_ModifyCol(A_Index, "AutoHdr")
		
		if (this.SelectedDetailReport = "Plan")
			this.showPlanDetails()
	}
	
	loadPitstops() {
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.PitstopsListView
		
		for ignore, pitstop in this.SessionDatabase.Tables["Pitstop.Data"] {
			repairBodywork := pitstop["Repair.Bodywork"]
			repairSuspension := pitstop["Repair.Suspension"]
		
			if (repairBodywork && repairSuspension)
				repairs := (translate("Bodywork") . ", " . translate("Suspension"))
			else if repairBodywork
				repairs := translate("Bodywork")
			else if repairSuspension
				repairs := translate("Suspension")
			else
				repairs := "-"
			
			pressures := values2String(", ", pitstop["Tyre.Pressure.Cold.Front.Left"], pitstop["Tyre.Pressure.Cold.Front.Right"]
										   , pitstop["Tyre.Pressure.Cold.Rear.Left"], pitstop["Tyre.Pressure.Cold.Rear.Right"])
				
			LV_Add("", A_Index, pitstop.Lap, pitstop.Fuel
					 , translate(compound(pitstop["Tyre.Compound"], pitstop["Tyre.Compound.Color"]))
					 , pitstop["Tyre.Set"], pressures, repairs)
		}
				
		LV_ModifyCol()
		
		Loop % LV_GetCount("Col")
			LV_ModifyCol(A_Index, "AutoHdr")
	}
	
	clearSession() {
		session := this.SelectedSession[true]
		
		if session {
			try {
				this.Connector.ClearSession(session)
			}
			catch exception {
				; ignore
			}
			
			this.initializeSession()
		}
	}
	
	loadSession() {
		title := translate("Select Session folder...")
		
		directory := (this.SessionLoaded ? this.SessionLoaded : this.iSessionDirectory)
			
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Select", "Select", "Cancel"]))
		FileSelectFolder folder, *%directory%, 0, %title%
		OnMessage(0x44, "")
	
		if (folder != "") {
			folder := (folder . "\")
			
			info := readConfiguration(folder . "Session.info")
			
			if (info.Count() == 0) {
				title := translate("Error")
			
				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
				MsgBox 262160, %title%, % translate("This is not a valid folder with a saved session.")
				OnMessage(0x44, "")
			}
			else {
				SetTimer syncSession, Off
			
				this.iConnected := false
				
				this.initializeSession()
				
				this.iSessionLoaded := folder
				
				this.iTeamName := getConfigurationValue(info, "Session", "Team")
				this.iTeamIdentifier := false
				
				this.iSessionName := getConfigurationValue(info, "Session", "Session")
				this.iSessionIdentifier := false
			
				this.iDate := getConfigurationValue(info, "Session", "Date", A_Now)
				this.iTime := getConfigurationValue(info, "Session", "Time", A_Now)
				
				window := this.Window
		
				Gui %window%:Default
				
				GuiControl, , sessionDateCal, % this.Date
				GuiControl, , sessionTimeEdit, % this.Time
				
				GuiControl, , teamDropDownMenu, % "|" . this.iTeamName
				GuiControl Choose, teamDropDownMenu, 1
				
				GuiControl, , sessionDropDownMenu, % "|" . this.iSessionName
				GuiControl Choose, sessionDropDownMenu, 1
				
				this.loadDrivers()
				this.loadSessionDrivers()
				this.loadPlan()
				this.loadLaps()
				this.loadStints()
				this.loadPitstops()
				
				this.syncTelemetry(true)
				this.syncTyrePressures(true)
				this.syncStandings(true)
			
				this.ReportViewer.setReport(folder . "Race Report")
			
				raceData := true
				drivers := false
				positions := false
				times := false
				
				this.ReportViewer.loadReportData(false, raceData, drivers, positions, times)
		
				if !this.Simulator {
					this.iSimulator := getConfigurationValue(raceData, "Session", "Simulator", false)
					this.iCar := getConfigurationValue(raceData, "Session", "Car")
					this.iTrack := getConfigurationValue(raceData, "Session", "Track")
				}
				
				if !this.Weather {
					lastLap := this.LastLap
					
					if lastLap {
						this.iWeather := lastLap.Weather
						this.iAirTemperature := lastLap.AirTemperature
						this.iTrackTemperature := lastLap.TrackTemperature
					}
				}
				
				if !this.TyreCompound {
					currentStint := this.CurrentStint
					
					if currentStint {
						this.iTyreCompound := compound(currentStint.Compound)
						this.iTyreCompoundColor := compoundColor(currentStint.Compound)
					}
				}
			
				this.updateReports()
				
				this.updateState()
			}
		}
	}
	
	show() {
		window := this.Window
			
		Gui %window%:Show
		
		while !this.iClosed
			Sleep 1000
		
		SetTimer syncSession, Off
	}
	
	close() {
		this.iClosed := true
	}
	
	showChart(drawChartFunction) {
		window := this.Window
		
		Gui %window%:Default
		
		chartViewer.Document.Open()
		
		if (drawChartFunction && (drawChartFunction != "")) {
			before =
			(
			<html>
			    <meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: 'FFFFFF'; }
						.rowStyle { font-size: 11px; background-color: 'E0E0E0'; }
						.oddRowStyle { font-size: 11px; background-color: 'E8E8E8'; }
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawChart);
			)

			after =
			(
					</script>
				</head>
				<body style='background-color: #D8D8D8' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>
					<div id="chart_id" style="width: 798px; height: 248px"></div>
				</body>
			</html>
			)

			html := (before . drawChartFunction . after)
			
			chartViewer.Document.Write(html)
		}
		else {
			html := "<html><body style='background-color: #D8D8D8' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'></body></html>"
		
			chartViewer.Document.Write(html)
		}
		
		chartViewer.Document.Close()
	}
	
	showDataPlot(data, xAxis, yAxises) {
		double := (yAxises.Length() > 1)
		
		drawChartFunction := ""
		
		drawChartFunction .= "function drawChart() {"
		drawChartFunction .= "`nvar data = new google.visualization.DataTable();"
		
		if (this.SelectedChartType = "Bubble")
			drawChartFunction .= ("`ndata.addColumn('string', 'ID');")
		
		drawChartFunction .= ("`ndata.addColumn('number', '" . xAxis . "');")
		
		for ignore, yAxis in yAxises {
			drawChartFunction .= ("`ndata.addColumn('number', '" . yAxis . "');")
		}
		
		settingsLaps := this.ReportViewer.Settings["Laps"]
		laps := false
		
		if (settingsLaps && (settingsLaps.Length() > 0)) {
			laps := {}
			
			for ignore, lap in settingsLaps
				laps[lap] := lap
		}
		
		drawChartFunction .= "`ndata.addRows(["
		first := true
		
		for ignore, values in data {
			if (laps && !laps.HasKey(A_Index))
				continue
			
			if !first
				drawChartFunction .= ",`n"
			
			first := false
			value := values[xAxis]
			
			if ((value = "n/a") || (value == kNull))
				value := "null"

			if (this.SelectedChartType = "Bubble")
				drawChartFunction .= ("['', " . value)
			else
				drawChartFunction .= ("[" . value)
		
			for ignore, yAxis in yAxises {
				value := values[yAxis]
			
				if ((value = "n/a") || (value == kNull))
					value := "null"
				
				drawChartFunction .= (", " . value)
			}
			
			drawChartFunction .= "]"
		}
		
		drawChartFunction .= "`n]);"
		
		series := "series: {"
		vAxis := "vAxis: { gridlines: { color: 'E0E0E0' }, "
		for ignore, yAxis in yAxises {
			if (A_Index > 1) {
				series .= ", "
				vAxis .= ", "
			}
			
			index := A_Index - 1
			
			series .= (index . ": {targetAxisIndex: " . index . "}")
			vAxis .= (index . ": {title: '" . translate(yAxis) . "'}")
		}
		
		series .= "}"
		vAxis .= "}"
		
		if (this.SelectedChartType = "Scatter") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#D8D8D8', hAxis: { title: '" . translate(xAxis) . "', gridlines: { color: 'E0E0E0' } }, " . series . ", " . vAxis . "};")
				
			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.ScatterChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Bar") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#D8D8D8', hAxis: { viewWindowMode: 'pretty' }, vAxis: { viewWindowMode: 'pretty' } };")
				
			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BarChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Bubble") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#D8D8D8', hAxis: { title: '" . translate(xAxis) . "', viewWindowMode: 'pretty' }, vAxis: { title: '" . translate(yAxises[1]) . "', viewWindowMode: 'pretty' }, colorAxis: { legend: {position: 'none'}, colors: ['blue', 'red'] }, sizeAxis: { maxSize: 15 } };")
				
			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BubbleChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		else if (this.SelectedChartType = "Line") {
			drawChartFunction .= ("`nvar options = { legend: {position: 'bottom'}, chartArea: { left: '10%', right: '10%', top: '10%', bottom: '30%' }, backgroundColor: '#D8D8D8' };")
				
			drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.LineChart(document.getElementById('chart_id')); chart.draw(data, options); }"
		}
		
		this.showChart(drawChartFunction)
	}
	
	showDetails(report, details, charts*) {
		chartID := 1
		html := (details ? details : "")
		
		this.iSelectedDetailReport := report
		
		if details {
			tableCSS := getTableCSS()
				
			script =
			(
				<meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: 'FFFFFF'; }
						.rowStyle { font-size: 11px; background-color: 'E0E0E0'; }
						.oddRowStyle { font-size: 11px; background-color: 'E8E8E8'; }
						%tableCSS%
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawCharts);
						
						function drawCharts() {
			)
			
			for ignore, chart in charts
				script .= (A_Space . "drawChart" . chart[1] . "();")
			
			script .= "}`n"
			
			for ignore, chart in charts {
				if (A_Index > 0)
					script .= . "`n"
				
				script .= chart[2]
			}
			
			script .= "</script></head>"
		}
		else
			script := ""
			
		html := ("<html>" . script . "<body style='background-color: #D8D8D8' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><style> div, table { font-family: Arial, Helvetica, sans-serif; font-size: 11px }</style><style> #header { font-size: 12px; } </style><div>" . html . "</div></body></html>")

		detailsViewer.Document.Open()
		detailsViewer.Document.Write(html)
		detailsViewer.Document.Close()
	}
	
	selectReport(report) {
		Gui ListView, % reportsListView
		
		if report {
			LV_Modify(inList(kSessionReports, report), "+Select")
		
			this.iSelectedReport := report
		}
		else {
			Loop % LV_GetCount()
				LV_Modify(A_Index, "-Select")
			
			this.iSelectedReport := false
		}
	}
	
	showOverviewReport() {
		this.selectReport("Overview")
		
		this.ReportViewer.showOverviewReport()
		
		this.updateState()
	}
	
	showCarReport() {
		this.selectReport("Car")
		
		this.ReportViewer.showCarReport()
		
		this.updateState()
	}
	
	showDriverReport() {
		this.selectReport("Driver")
		
		this.ReportViewer.showDriverReport()
		
		this.updateState()
	}
	
	editDriverReportSettings() {
		return this.ReportViewer.editReportSettings("Laps", "Drivers")
	}
	
	showPositionReport() {
		this.selectReport("Position")
		
		this.ReportViewer.showPositionReport()
		
		this.updateState()
	}
	
	editPositionReportSettings() {
		return this.ReportViewer.editReportSettings("Laps")
	}
	
	showPaceReport() {
		this.selectReport("Pace")
		
		this.ReportViewer.showPaceReport()
		
		this.updateState()
	}
	
	editPaceReportSettings() {
		return this.ReportViewer.editReportSettings("Laps", "Drivers")
	}
	
	showRaceReport(report) {
		switch report {
			case "Overview":
				this.showOverviewReport()
			case "Car":
				this.showCarReport()
			case "Driver":
				if !this.ReportViewer.Settings.HasKey("Drivers")
					this.ReportViewer.Settings["Drivers"] := [1, 2, 3, 4, 5]
				
				this.showDriverReport()
			case "Position":
				this.showPositionReport()
			case "Pace":
				this.showPaceReport()
		}
	}
	
	showTelemetryReport() {
		window := this.Window
		
		Gui %window%:Default
		
		GuiControlGet dataXDropDown
		GuiControlGet dataY1DropDown
		GuiControlGet dataY2DropDown
		GuiControlGet dataY3DropDown
		GuiControlGet dataY4DropDown
		GuiControlGet dataY5DropDown
		GuiControlGet dataY6DropDown
		
		xAxis := this.iXColumns[dataXDropDown]
		yAxises := Array(this.iY1Columns[dataY1DropDown])
		
		if (dataY2DropDown > 1)
			yAxises.Push(this.iY2Columns[dataY2DropDown - 1])
		
		if (dataY3DropDown > 1)
			yAxises.Push(this.iY3Columns[dataY3DropDown - 1])
		
		if (dataY4DropDown > 1)
			yAxises.Push(this.iY4Columns[dataY4DropDown - 1])
		
		if (dataY5DropDown > 1)
			yAxises.Push(this.iY5Columns[dataY5DropDown - 1])
		
		if (dataY6DropDown > 1)
			yAxises.Push(this.iY6Columns[dataY6DropDown - 1])
		
		this.showDataPlot(this.SessionDatabase.Tables["Lap.Data"], xAxis, yAxises)
		
		this.updateState()
	}
	
	showPressuresReport() {
		this.selectReport("Pressures")
		
		this.showTelemetryReport()
		
		this.updateState()
	}
	
	editPressuresReportSettings() {
		return this.ReportViewer.editReportSettings("Laps")
	}
	
	showTemperaturesReport() {
		this.selectReport("Temperatures")
		
		this.showTelemetryReport()
		
		this.updateState()
	}
	
	editTemperaturesReportSettings() {
		return this.ReportViewer.editReportSettings("Laps")
	}
	
	showCustomReport() {
		this.selectReport("Free")
		
		this.showTelemetryReport()
		
		this.updateState()
	}
	
	editCustomReportSettings() {
		return this.ReportViewer.editReportSettings("Laps")
	}
	
	updateSeriesSelector(report, force := false) {
		window := this.Window
		
		Gui %window%:Default
		
		GuiControlGet dataXDropDown
		
		if (force || (report != this.SelectedReport) || (dataXDropDown == 0)) {
			xChoices := []
			y1Choices := []
			y2Choices := []
			y3Choices := []
			y4Choices := []
			y5Choices := []
			y6Choices := []
		
			if (report = "Pressures") {
				xChoices := ["Stint", "Lap", "Lap.Time"]
			
				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Tyre.Laps"
							, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Cold.Front.Left", "Tyre.Pressure.Cold.Front.Right", "Tyre.Pressure.Cold.Rear.Left", "Tyre.Pressure.Cold.Rear.Right"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"]
				
				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Temperatures") {
				xChoices := ["Stint", "Lap", "Lap.Time"]
			
				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Tyre.Laps"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
							, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right", "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"]
				
				y2Choices := y1Choices
				y3Choices := y1Choices
				y4Choices := y1Choices
				y5Choices := y1Choices
				y6Choices := y1Choices
			}
			else if (report = "Free") {
				xChoices := ["Stint", "Lap", "Lap.Time", "Tyre.Laps", "Map", "TC", "ABS", "Temperature.Air", "Temperature.Track"]
			
				y1Choices := ["Temperature.Air", "Temperature.Track", "Fuel.Remaining", "Fuel.Consumption", "Lap.Time", "Tyre.Laps", "Map", "TC", "ABS"
							, "Tyre.Pressure.Cold.Average", "Tyre.Pressure.Cold.Front.Average", "Tyre.Pressure.Cold.Rear.Average"
							, "Tyre.Pressure.Hot.Average", "Tyre.Pressure.Hot.Front.Average", "Tyre.Pressure.Hot.Rear.Average"
							, "Tyre.Pressure.Hot.Front.Left", "Tyre.Pressure.Hot.Front.Right", "Tyre.Pressure.Hot.Rear.Left", "Tyre.Pressure.Hot.Rear.Right"
							, "Tyre.Temperature.Average", "Tyre.Temperature.Front.Average", "Tyre.Temperature.Rear.Average"
							, "Tyre.Temperature.Front.Left", "Tyre.Temperature.Front.Right", "Tyre.Temperature.Rear.Left", "Tyre.Temperature.Rear.Right"]
				
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
			
			GuiControl, , dataXDropDown, % ("|" . values2String("|", xChoices*))
			GuiControl, , dataY1DropDown, % ("|" . values2String("|", y1Choices*))
			GuiControl, , dataY2DropDown, % ("|" . values2String("|", translate("None"), y2Choices*))
			GuiControl, , dataY3DropDown, % ("|" . values2String("|", translate("None"), y3Choices*))
			GuiControl, , dataY4DropDown, % ("|" . values2String("|", translate("None"), y4Choices*))
			GuiControl, , dataY5DropDown, % ("|" . values2String("|", translate("None"), y5Choices*))
			GuiControl, , dataY6DropDown, % ("|" . values2String("|", translate("None"), y6Choices*))
		
			dataY1DropDown := 0
			dataY2DropDown := 0
			dataY3DropDown := 0
			dataY4DropDown := 0
			dataY5DropDown := 0
			dataY6DropDown := 0
			
			if (report = "Pressures") {
				GuiControl Choose, chartTypeDropDown, 4
				
				this.iSelectedChartType := "Line"
				
				dataXDropDown := inList(xChoices, "Lap")
				dataY1DropDown := inList(y1Choices, "Temperature.Air")
				dataY2DropDown := inList(y2Choices, "Tyre.Pressure.Cold.Average") + 1
				dataY3DropDown := inList(y3Choices, "Tyre.Pressure.Hot.Average") + 1
				dataY4DropDown := 1
				dataY5DropDown := 1
				dataY6DropDown := 1
			}
			else if (report = "Temperatures") {
				GuiControl Choose, chartTypeDropDown, 1
				
				this.iSelectedChartType := "Scatter"
				
				dataXDropDown := inList(xChoices, "Lap")
				dataY1DropDown := inList(y1Choices, "Temperature.Air")
				dataY2DropDown := inList(y2Choices, "Tyre.Temperature.Front.Average") + 1
				dataY3DropDown := inList(y3Choices, "Tyre.Temperature.Rear.Average") + 1
				dataY4DropDown := 1
				dataY5DropDown := 1
				dataY6DropDown := 1
			}
			else if (report = "Free") {
				GuiControl Choose, chartTypeDropDown, 1
				
				this.iSelectedChartType := "Line"
				
				dataXDropDown := inList(xChoices, "Lap")
				dataY1DropDown := inList(y1Choices, "Lap.Time")
				dataY2DropDown := inList(y2Choices, "Tyre.Laps") + 1
				dataY3DropDown := inList(y3Choices, "Temperature.Air") + 1
				dataY4DropDown := inList(y4Choices, "Temperature.Track") + 1
				dataY5DropDown := inList(y5Choices, "Tyre.Pressure.Cold.Average") + 1
				dataY6DropDown := inList(y6Choices, "Tyre.Pressure.Hot.Average") + 1
			}
			
			GuiControl Choose, dataXDropDown, %dataXDropDown%
			GuiControl Choose, dataY1DropDown, %dataY1DropDown%
			GuiControl Choose, dataY2DropDown, %dataY2DropDown%
			GuiControl Choose, dataY3DropDown, %dataY3DropDown%
			GuiControl Choose, dataY4DropDown, %dataY4DropDown%
			GuiControl Choose, dataY5DropDown, %dataY5DropDown%
			GuiControl Choose, dataY6DropDown, %dataY6DropDown%
		}
	}
	
	syncSessionDatabase(forSave := false) {
		this.showWait()
		
		try {
			session := this.SelectedSession[true]
			sessionDB := this.SessionDatabase
			lastLap := this.LastLap
			
			if lastLap
				lastLap := lastLap.Nr
			
			if lastLap {
				pressuresTable := this.PressuresDatabase.Database.Tables["Setup.Pressures"]
				tyresTable := this.TelemetryDatabase.Database.Tables["Tyres"]
						
				newLap := (sessionDB.Tables["Lap.Data"].Length() + 1)
				
				while (newLap <= lastLap) {
					lap := this.Laps[newLap]
					
					if ((pressuresTable.Length() < newLap) || (tyresTable.Length() < newLap))
						return
					
					lapData := {Nr: newLap, Lap: newLap, Stint: lap.Stint.Nr, "Lap.Time": null(lap.Laptime), Position: null(lap.Position)
							  , Damage: lap.Damage, Accident: lap.Accident
							  , "Fuel.Consumption": null(lap.FuelConsumption), "Fuel.Remaining": null(lap.FuelRemaining)
							  , Weather: lap.Weather, "Temperature.Air": null(lap.AirTemperature), "Temperature.Track": null(lap.TrackTemperature)
							  , Grip: lap.Grip, Map: null(lap.Map), TC: null(lap.TC), ABS: null(lap.ABS)
							  , "Tyre.Compound": compound(lap.Compound), "Tyre.Compound.Color": compoundColor(lap.Compound)}				
					
					pressures := pressuresTable[newLap]
					
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
					
					lapData["Tyre.Pressure.Hot.Front.Left"] := null(pressureFL)
					lapData["Tyre.Pressure.Hot.Front.Right"] := null(pressureFR)
					lapData["Tyre.Pressure.Hot.Rear.Left"] := null(pressureRL)
					lapData["Tyre.Pressure.Hot.Rear.Right"] := null(pressureRR)
					lapData["Tyre.Pressure.Hot.Average"] := null(average([pressureFL, pressureFR, pressureRL, pressureRR]))
					lapData["Tyre.Pressure.Hot.Front.Average"] := null(average([pressureFL, pressureFR]))
					lapData["Tyre.Pressure.Hot.Rear.Average"] := null(average([pressureRL, pressureRR]))
			
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
					
					sessionDB.add("Lap.Data", lapData)
					
					newLap += 1
				}
			
				if this.SessionActive {
					lap := 0
				
					for ignore, entry in sessionDB.Tables["Delta.Data"]
						lap := Max(lap, entry.Lap)

					lap += 1
					
					while (lap <= lastLap) {
						try {
							tries := ((lap == lastLap) ? 10 : 1)
					
							while (tries > 0) {
								standingsData := this.Connector.GetSessionLapValue(session, lap, "Race Strategist Race Standings")
								
								if (!standingsData || (standingsData == "")) {
									tries -= 1
									
									if (tries <= 0)
										throw "No data..."
									else
										Sleep 400
								}
								else
									break
							}
							
							standingsData := parseConfiguration(standingsData)
						}
						catch exception {
							standingsData := newConfiguration()
						}
						
						if (standingsData.Count() > 0) {
							sessionDB.add("Delta.Data", {Lap: lap, Type: "Standings.Behind"
													   , Car: getConfigurationValue(standingsData, "Position", "Position.Standings.Behind.Car")
													   , Delta: Round(getConfigurationValue(standingsData, "Position", "Position.Standings.Behind.Delta") / 1000, 2)
													   , Distance: Round(getConfigurationValue(standingsData, "Position", "Position.Standings.Behind.Distance"), 2)})
							sessionDB.add("Delta.Data", {Lap: lap, Type: "Standings.Front"
													   , Car: getConfigurationValue(standingsData, "Position", "Position.Standings.Front.Car")
													   , Delta: Round(getConfigurationValue(standingsData, "Position", "Position.Standings.Front.Delta") / 1000, 2)
													   , Distance: Round(getConfigurationValue(standingsData, "Position", "Position.Standings.Front.Distance"), 2)})
							sessionDB.add("Delta.Data", {Lap: lap, Type: "Standings.Leader"
													   , Car: getConfigurationValue(standingsData, "Position", "Position.Standings.Leader.Car")
													   , Delta: Round(getConfigurationValue(standingsData, "Position", "Position.Standings.Leader.Delta") / 1000, 2)
													   , Distance: Round(getConfigurationValue(standingsData, "Position", "Position.Standings.Leader.Distance"), 2)})
							sessionDB.add("Delta.Data", {Lap: lap, Type: "Track.Behind"
													   , Car: getConfigurationValue(standingsData, "Position", "Position.Track.Behind.Car")
													   , Delta: Round(getConfigurationValue(standingsData, "Position", "Position.Track.Behind.Delta") / 1000, 2)
													   , Distance: Round(getConfigurationValue(standingsData, "Position", "Position.Track.Behind.Distance"), 2)})
							sessionDB.add("Delta.Data", {Lap: lap, Type: "Track.Front"
													   , Car: getConfigurationValue(standingsData, "Position", "Position.Track.Front.Car")
													   , Delta: Round(getConfigurationValue(standingsData, "Position", "Position.Track.Front.Delta") / 1000, 2)
													   , Distance: Round(getConfigurationValue(standingsData, "Position", "Position.Track.Front.Distance"), 2)})
													   
							prefix := ("Standings.Lap." . lap . ".Car.")
							
							Loop % getConfigurationValue(standingsData, "Standings", prefix . "Count")
							{
								driver := computeDriverName(getConfigurationValue(standingsData, "Standings", prefix . A_Index . ".Driver.Forname")
														  , getConfigurationValue(standingsData, "Standings", prefix . A_Index . ".Driver.Surname")
														  , getConfigurationValue(standingsData, "Standings", prefix . A_Index . ".Driver.Nickname"))
								
								sessionDB.add("Standings.Data", {Lap: lap, Car: A_Index, Driver: driver
															   , Position: getConfigurationValue(standingsData, "Standings", prefix . A_Index . ".Position")
															   , Time: Round(getConfigurationValue(standingsData, "Standings", prefix . A_Index . ".Time") / 1000, 1)
															   , Laps: Round(getConfigurationValue(standingsData, "Standings", prefix . A_Index . ".Laps"), 1)
															   , Delta: Round(getConfigurationValue(standingsData, "Standings", prefix . A_Index . ".Delta") / 1000, 2)})
							}
						}
						
						lap += 1
					}
				}
			}
			
			if forSave
				this.savePlan(this.SessionFinished)
			
			if (forSave && !this.SessionFinished) {
				currentStint := this.CurrentStint
				
				if currentStint {
					newStint := (sessionDB.Tables["Stint.Data"].Length() + 1)
					
					while (newStint <= currentStint.Nr) {
						stint := this.Stints[newStint]
					
						stintData := {Nr: newStint, Lap: stint.Lap
									, "Driver.Forname": stint.Driver.Forname, "Driver.Surname": stint.Driver.Surname, "Driver.Nickname": stint.Driver.Nickname
									, "Weather": stint.Weather, "Compound": stint.Compound, "Lap.Time.Average": null(stint.AvgLaptime), "Lap.Time.Best": null(stint.BestLapTime)
									, "Fuel.Consumption": null(stint.FuelConsumption), "Accidents": stint.Accidents
									, "Position.Start": null(stint.StartPosition), "Position.End": null(stint.EndPosition)
									, "Time.Start": stint.Time}
						
						sessionDB.add("Stint.Data", stintData)
						
						newStint += 1
					}
				}
				
				if (this.Drivers.Length() != sessionDB.Tables["Driver.Data"].Length()) {
					sessionDB.clear("Driver")
					
					for ignore, driver in this.Drivers
						sessionDB.add("Driver.Data", {Forname: driver.Forname, Surname: driver.Surname, Nickname: driver.Nickname})
				}
				
				sessionDB.flush()
			}
		}
		finally {
			this.hideWait()
		}
	}
	
	reportSettings(report) {
		switch report {
			case "Driver":
				if this.editDriverReportSettings()
					this.showDriverReport()
			case "Position":
				if this.editPositionReportSettings()
					this.showPositionReport()
			case "Pace":
				if this.editPaceReportSettings()
					this.showPaceReport()
			case "Pressures":
				if this.editPressuresReportSettings()
					this.showPressuresReport()
			case "Temperatures":
				if this.editTemperaturesReportSettings()
					this.showTemperaturesReport()
			case "Free":
				if this.editCustomReportSettings()
					this.showCustomReport()
		}
	}
	
	showReport(report, force := false) {
		if (force || (report != this.SelectedReport)) {
			this.syncSessionDatabase()
			this.updateSeriesSelector(report)
			
			if inList(kRaceReports, report)
				this.showRaceReport(report)
			else if (report = "Pressures")
				this.showPressuresReport()
			else if (report = "Temperatures")
				this.showTemperaturesReport()
			else if (report = "Free")
				this.showCustomReport()
		}
	}
	
	selectChartType(chartType, force := false) {
		if (force || (chartType != this.SelectedChartType)) {
			GuiControl Choose, chartTypeDropDown, % inList(["Scatter", "Bar", "Bubble", "Line"], chartType)
			
			this.iSelectedChartType := chartType
			
			this.showTelemetryReport()
		}
	}
	
	createStintHeader(stint) {
		duration := 0
		
		for ignore, lap in stint.Laps
			duration += lap.Laptime
		
		html := "<table>"
		html .= ("<tr><td><b>" . translate("Driver:") . "</b></div></td><td>" . StrReplace(stint.Driver.Fullname, "'", "\'") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Duration:") . "</b></div></td><td>" . Round(duration / 60) . A_Space . translate("Minutes") . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Start Position:") . "</b></div></td><td>" . stint.StartPosition . "</td></tr>")
		html .= ("<tr><td><b>" . translate("End Position:") . "</b></div></td><td>" . stint.EndPosition . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Consumption:") . "</b></div></td><td>" . stint.FuelConsumption . A_Space . translate("Liter") . "</td></tr>")
		html .= "</table>"
		
		return html
	}
	
	createLapDetailsChart(chartID, width, height, lapSeries, positionSeries, lapTimeSeries, fuelSeries, tempSeries) {
		drawChartFunction := ("function drawChart" . chartID . "() {`nvar data = new google.visualization.DataTable();")
		
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Position") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap Time") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Consumption") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Tyre Temperatures") . "');")

		drawChartFunction .= "`ndata.addRows(["
		
		for ignore, time in lapSeries {
			if (A_Index > 1)
				drawChartFunction .= ", "
			
			drawChartFunction .= ("[" . values2String(", ", lapSeries[A_Index]
														  , chartValue(null(positionSeries[A_Index]))
														  , chartValue(null(lapTimeSeries[A_Index]))
														  , chartValue(null(fuelSeries[A_Index]))
														  , chartValue(null(tempSeries[A_Index])))
									  . "]")
		}
		
		drawChartFunction .= ("]);`nvar options = { legend: { position: 'Right' }, chartArea: { left: '10%', top: '5%', right: '25%', bottom: '20%' }, hAxis: { title: '" . translate("Lap") . "' }, vAxis: { viewWindow: { min: 0 } }, backgroundColor: 'D8D8D8' };`n")
				
		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")
		
		return drawChartFunction
	}
	
	createStintPerformanceChart(chartID, width, height, stint) {
		this.updateStintStatistics(stint)

		drawChartFunction := ""
		
		drawChartFunction .= "function drawChart" . chartID . "() {"
		drawChartFunction .= "`nvar data = google.visualization.arrayToDataTable(["
		drawChartFunction .= "`n['" . values2String("', '", translate("Category"), StrReplace(stint.Driver.Fullname, "'", "\'")) . "'],"
		
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Potential") . "'", stint.Potential) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Race Craft") . "'", stint.RaceCraft) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Speed") . "'", stint.Speed) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Consistency") . "'", stint.Consistency) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Car Control") . "'", stint.CarControl) . "]"
		
		drawChartFunction .= ("`n]);")
			
		drawChartFunction := drawChartFunction . "`nvar options = { bars: 'horizontal', legend: 'none', backgroundColor: 'D8D8D8', chartArea: { left: '20%', top: '5%', right: '10%', bottom: '10%' } };"
		drawChartFunction := drawChartFunction . "`nvar chart = new google.visualization.BarChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }"
		
		return drawChartFunction
	}
	
	createLapDetails(stint) {
		html := "<table>"
		html .= ("<tr><td><b>" . translate("Average:") . "</b></td><td>" . stint.AvgLapTime . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Best:") . "</b></td><td>" . stint.BestLapTime . "</td></tr>")
		html .= "</table>"
		
		lapData := []
		mapData := []
		lapTimeData := []
		fuelConsumptionData := []
		accidentData := []
		
		for ignore, lap in stint.Laps {
			lapData.Push("<th class=""th-std"">" . lap.Nr . "</th>")
			mapData.Push("<td class=""td-std"">" . lap.Map . "</td>")
			lapTimeData.Push("<td class=""td-std"">" . lap.Laptime . "</td>")
			fuelConsumptionData.Push("<td class=""td-std"">" . lap.FuelConsumption . "</td>")
			accidentData.Push("<td class=""td-std"">" . (lap.Accident ? "x" : "") . "</td>")
		}
		
		html .= "<br><table class=""table-std"">"
		
		html .= ("<tr><th class=""th-std"">" . translate("Lap") . "</th>"
			       . "<th class=""th-std"">" . translate("Map") . "</th>"
			       . "<th class=""th-std"">" . translate("Lap Time") . "</th>"
			       . "<th class=""th-std"">" . translate("Consumption") . "</th>"
			       . "<th class=""th-std"">" . translate("Accident") . "</th>"
			   . "</tr>")
		
		Loop % lapData.Length()
			html .= ("<tr>" . lapData[A_Index]
							. mapData[A_Index]
							. lapTimeData[A_Index]
							. fuelConsumptionData[A_Index]
							. accidentData[A_Index]
				   . "</tr>")
		
		html .= "</table>"
		
		return html
	}
	
	showStintDetails(stint) {
		html := ("<div id=""header""><b>" . translate("Stint: ") . stint.Nr . "</b></div>")
			
		html .= ("<br><br><div id=""header""><i>" . translate("Overview") . "</i></div>")
		
		html .= ("<br>" . this.createStintHeader(stint))
		
		html .= ("<br><br><div id=""header""><i>" . translate("Laps") . "</i></div>")
		
		html .= ("<br>" . this.createLapDetails(stint))
		
		html .= ("<br><br><div id=""header""><i>" . translate("Telemetry") . "</i></div>")
		
		laps := []
		positions := []
		lapTimes := []
		fuelConsumptions := []
		temperatures := []
		
		this.syncSessionDatabase()
		
		lapTable := this.SessionDatabase.Tables["Lap.Data"]
		
		for ignore, lap in stint.Laps {
			laps.Push(lap.Nr)
			positions.Push(lap.Position)
			lapTimes.Push(lap.Laptime)
			fuelConsumptions.Push(lap.FuelConsumption)
			temperatures.Push(lapTable[lap.Nr]["Tyre.Temperature.Average"])
		}
			
		chart1 := this.createLapDetailsChart(1, 555, 248, laps, positions, lapTimes, fuelConsumptions, temperatures)
		
		html .= ("<br><br><div id=""chart_1" . """ style=""width: 555px; height: 248px""></div>")
			
		html .= ("<br><br><div id=""header""><i>" . translate("Driver") . "</i></div>")
		
		chart2 := this.createStintPerformanceChart(2, 555, 248, stint)
		
		html .= ("<br><div id=""chart_2" . """ style=""width: 555px; height: 248px""></div>")
			
		this.showDetails("Stint", html, [1, chart1], [2, chart2])
	}
	
	createLapOverview(lap) {
		hotPressures := "-, -, -, -"
		coldPressures := "-, -, -, -"
		
		pressuresDB := this.PressuresDatabase
		
		if pressuresDB {
			pressuresTable := pressuresDB.Database.Tables["Setup.Pressures"]
		
			if (pressuresTable.Length() >= lap.Nr) {
				pressures := pressuresTable[lap.Nr]
				
				coldPressures := values2String(", ", displayValue(pressures["Tyre.Pressure.Cold.Front.Left"]), displayValue(pressures["Tyre.Pressure.Cold.Front.Right"])
												   , displayValue(pressures["Tyre.Pressure.Cold.Rear.Left"]), displayValue(pressures["Tyre.Pressure.Cold.Rear.Right"]))
												   
				hotPressures := values2String(", ", displayValue(pressures["Tyre.Pressure.Hot.Front.Left"]), displayValue(pressures["Tyre.Pressure.Hot.Front.Right"])
												  , displayValue(pressures["Tyre.Pressure.Hot.Rear.Left"]), displayValue(pressures["Tyre.Pressure.Hot.Rear.Right"]))
			}
		}
		
		html := "<table>"
		html .= ("<tr><td><b>" . translate("Position:") . "</b></td><td>" . lap.Position . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Lap Time:") . "</b></td><td>" . lap.LapTime . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Consumption:") . "</b></td><td>" . lap.FuelConsumption . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Fuel Level:") . "</b></td><td>" . lap.FuelRemaining . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Pressures (hot):") . "</b></td><td>" . hotPressures . "</td></tr>")
		html .= ("<tr><td><b>" . translate("Pressures (cold):") . "</b></td><td>" . coldPressures . "</td></tr>")
		html .= "</table>"
		
		return html
	}
	
	createLapDeltas(lap) {
		sessionDB := this.SessionDatabase
		
		html := "<table class=""table-std"">"
		
		html .= ("<tr><th class=""th-std"">" . "" . "</th>"
			   . "<th class=""th-std"">" . translate("Nr.") . "</th>"
			   . "<th class=""th-std"">" . translate("Driver") . "</th>"
			   . "<th class=""th-std"">" . translate("Car") . "</th>"
			   . "<th class=""th-std"">" . translate("Delta") . "</th>"
			   . "</tr>")
		
		label := [translate("Leader"), translate("Standings (Front)"), translate("Standings (Behind)")
				, translate("Track (Front)"), translate("Track (Behind)")]
		rowIndex := {"Standings.Leader": 1, "Standings.Front": 2, "Standings.Behind": 3, "Track.Front": 4, "Track.Behind": 5}
		
		telemetryDB := this.TelemetryDatabase
		
		rows := [1, 2, 3, 4, 5]
		deltas := sessionDB.query("Delta.Data", {Where: {Lap: lap.Nr}})
		
		if (deltas.Length() > 0) {
			for ignore, entry in deltas {
				carNumber := "-"
				carName := "-"
				driverFullname := "-"
				delta := "-"
				
				if (entry.Car) {
					driverFullname := false
					driverSurname := false
					driverNickname := false
					
					this.getCar(lap, entry.Car, carNumber, carName, driverForname, driverSurname, driverNickname)
					
					driverFullname := computeDriverName(driverForname, driverSurname, driverNickname)
					delta := entry.Delta
				}
				
				index := rowIndex[entry.Type]
				
				rows[index] := ("<tr><th class=""th-std th-left"">" . label[index] . "</th>"
							  . "<td class=""td-std"">" . values2String("</td><td class=""td-std"">" , carNumber, driverFullname, telemetryDB.getCarName(this.Simulator, carName), delta)
							  . "</td></tr>")
			}
			
			for ignore, row in rows
				html .= row
		}
		
		html .= "</table>"
		
		return html
	}
	
	createLapStandings(lap) {
		sessionDB := this.SessionDatabase
		telemetryDB := this.TelemetryDatabase
		
		html := "<table class=""table-std"">"
		
		html .= ("<tr><th class=""th-std"">" . translate("#") . "</th>"
			   . "<th class=""th-std"">" . translate("Nr.") . "</th>"
			   . "<th class=""th-std"">" . translate("Driver") . "</th>"
			   . "<th class=""th-std"">" . translate("Car") . "</th>"
			   . "<th class=""th-std"">" . translate("Lap Time") . "</th>"
			   . "<th class=""th-std"">" . translate("Laps") . "</th>"
			   . "<th class=""th-std"">" . translate("Delta") . "</th>"
			   . "</tr>")
	
		cars := true
		positions := true
		carNumbers := true
		carNames := true
		driverFornames := true
		driverSurnames := true
		driverNicknames := true
		
		this.getStandings(lap, cars, positions, carNumbers, carNames, driverFornames, driverSurnames, driverNicknames)
	
		for index, position in positions {
			lapTime := "-"
			laps := "-"
			delta := "-"
			
			result := sessionDB.query("Standings.Data", {Select: ["Time", "Laps", "Delta"], Where: {Lap: lap.Nr, Car: cars[index]}})
			
			if (result.Length() > 0) {
				lapTime := result[1].Time
				laps := result[1].Laps
				delta := Round(result[1].Delta, 1)
			}
			
			html .= ("<tr><th class=""th-std"">" . position . "</td>"
				   . "<td class=""td-std"">" . values2String("</td><td class=""td-std"">", carNumbers[index]
																						 , computeDriverName(driverFornames[index]
																										   , driverSurnames[index]
																										   , driverNickNames[index])
																						 ,  telemetryDB.getCarName(this.Simulator, carNames[index])
																						 , lapTime, laps, delta)
				   . "</td></tr>")
		}
		
		html .= "</table>"
		
		return html
	}
	
	showLapDetails(lap) {
		this.syncSessionDatabase()
		
		html := ("<div id=""header""><b>" . translate("Lap: ") . lap.Nr . "</b></div>")
			
		html .= ("<br><br><div id=""header""><i>" . translate("Overview") . "</i></div>")
		
		html .= ("<br>" . this.createLapOverview(lap))
		
		html .= ("<br><br><div id=""header""><i>" . translate("Deltas") . "</i></div>")
		
		html .= ("<br>" . this.createLapDeltas(lap))
		
		html .= ("<br><br><div id=""header""><i>" . translate("Standings") . "</i></div>")
		
		html .= ("<br>" . this.createLapStandings(lap))
			
		this.showDetails("Lap", html)
	}
	
	createDriverDetails(drivers) {
		driverData := []
		stintsData := []
		lapsData := []
		drivingTimesData := []
		avgLapTimesData := []
		avgFuelConsumptionsData := []
		accidentsData := []
		
		for ignore, driver in drivers {
			driverData.Push("<th class=""th-std"">" . StrReplace(driver.FullName, "'", "\'") . "</th>")
			stintsData.Push("<td class=""td-std"">" . driver.Stints.Length() . "</td>")
			lapsData.Push("<td class=""td-std"">" . driver.Laps.Length() . "</td>")
			
			drivingTime := 0
			lapAccidents := 0
			lapTimes := []
			fuelConsumptions := []
			
			for ignore, lap in driver.Laps {
				drivingTime += lap.Laptime
				lapTimes.Push(lap.Laptime)
				fuelConsumptions.Push(lap.FuelConsumption)
				
				if lap.Accident
					lapAccidents += 1
			}
			
			drivingTimesData.Push("<td class=""td-std"">" . Round(drivingTime / 60) . "</td>")
			avgLapTimesData.Push("<td class=""td-std"">" . Round(average(lapTimes), 1) . "</td>")
			avgFuelConsumptionsData.Push("<td class=""td-std"">" . Round(average(fuelConsumptions), 1) . "</td>")
			accidentsData.Push("<td class=""td-std"">" . lapAccidents . "</td>")
		}
			
		html := "<table class=""table-std"">"
		html .= ("<tr><th class=""th-std th-left"">" . translate("Driver") . "</th>" . values2String("", driverData*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Stints") . "</th>" . values2String("", stintsData*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Laps") . "</th>" . values2String("", lapsData*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Driving Time") . "</th>" . values2String("", drivingTimesData*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Avg. Lap Time") . "</th>" . values2String("", avgLapTimesData*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Avg. Consumption") . "</th>" . values2String("", avgFuelConsumptionsData*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Accidents") . "</th>" . values2String("", accidentsData*) . "</tr>")
		html .= "</table>"
			
		return html
	}
	
	createDriverPaceChart(chartID, width, height, drivers) {
		drawChartFunction := "function drawChart" . chartID . "() {`nvar array = [`n"
		
		length := 2000000
		
		for ignore, driver in drivers
			length := Min(length, driver.Laps.Length())
		
		if (length = 2000000)
			return ""
			
		lapTimes := []
		
		for ignore, driver in drivers {
			driverTimes := Array("'" . driver.Nickname . "'")
			
			for ignore, lap in driver.Laps {
				if (A_Index > length)
					break
				
				value := chartValue(null(lap.Laptime))
				
				if (value != "null")
					driverTimes.Push(value)
			}
			lapTimes.Push("[" . values2String(", ", driverTimes*) . "]")
		}
		
		drawChartFunction .= (values2String("`n, ", lapTimes*) . "];")
			
		drawChartFunction .= "`nvar data = new google.visualization.DataTable();"
		drawChartFunction .= "`ndata.addColumn('string', '" . translate("Driver") . "');"
		
		Loop %length%
			drawChartFunction .= "`ndata.addColumn('number', '" . translate("Lap") . A_Space . A_Index . "');"
		
		text =
		(
		data.addColumn({id:'max', type:'number', role:'interval'});
		data.addColumn({id:'min', type:'number', role:'interval'});
		data.addColumn({id:'firstQuartile', type:'number', role:'interval'});
		data.addColumn({id:'median', type:'number', role:'interval'});
		data.addColumn({id:'thirdQuartile', type:'number', role:'interval'});
		)
		
		drawChartFunction .= ("`n" . text)
		
		drawChartFunction .= ("`n" . "data.addRows(getBoxPlotValues(array, " . (length + 1) . "));")
		
		drawChartFunction .= ("`n" . getPaceJSFunctions())
		
		text =
		(
		var options = {
			backgroundColor: 'D8D8D8', chartArea: { left: '10`%', top: '5`%', right: '5`%', bottom: '20`%' },
			legend: { position: 'none' },
		)
		
		drawChartFunction .= text
		
		text =
		(
			hAxis: { title: '`%drivers`%', gridlines: { color: '#777' } },
			vAxis: { title: '`%seconds`%' }, 
			lineWidth: 0,
			series: [ { 'color': 'D8D8D8' } ],
			intervals: { barWidth: 1, boxWidth: 1, lineWidth: 2, style: 'boxes' },
			interval: { max: { style: 'bars', fillOpacity: 1, color: '#777' },
						min: { style: 'bars', fillOpacity: 1, color: '#777' } }
		};
		)
		
		drawChartFunction .= ("`n" . substituteVariables(text, {drivers: translate("Drivers"), seconds: translate("Seconds")}))
		
		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")
		
		return drawChartFunction
	}
	
	createDriverPerformanceChart(chartID, width, height, drivers) {
		driverNames := []
		potentialsData := []
		raceCraftsData := []
		speedsData := []
		consistenciesData := []
		carControlsData := []
		
		for ignore, driver in drivers {
			driverNames.Push(StrReplace(driver.FullName, "'", "\'"))
			potentialsData.Push(driver.Potential)
			raceCraftsData.Push(driver.RaceCraft)
			speedsData.Push(driver.Speed)
			consistenciesData.Push(driver.Consistency)
			carControlsData.Push(driver.CarControl)
		}

		drawChartFunction := ""
		
		drawChartFunction .= "function drawChart" . chartID . "() {"
		drawChartFunction .= "`nvar data = google.visualization.arrayToDataTable(["
		drawChartFunction .= "`n['" . values2String("', '", translate("Category"), driverNames*) . "'],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Potential") . "'", potentialsData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Race Craft") . "'", raceCraftsData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Speed") . "'", speedsData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Consistency") . "'", consistenciesData*) . "],"
		drawChartFunction .= "`n[" . values2String(", ", "'" . translate("Car Control") . "'", carControlsData*) . "]"
		
		drawChartFunction .= ("`n]);")
			
		drawChartFunction .= "`nvar options = { bars: 'horizontal', backgroundColor: 'D8D8D8', chartArea: { left: '20%', top: '5%', right: '30%', bottom: '10%' } };"
		drawChartFunction .= ("`nvar chart = new google.visualization.BarChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")
		
		return drawChartFunction
	}			
			
	showDriverStatistics() {
		for ignore, driver in this.Drivers
			this.updateDriverStatistics(driver)
		
		html := ("<div id=""header""><b>" . translate("Driver Statistics") . "</b></div>")
		
		html .= ("<br><br><div id=""header""><i>" . translate("Overview") . "</i></div>")
		
		html .= ("<br>" . this.createDriverDetails(this.Drivers))
		
		html .= ("<br><br><div id=""header""><i>" . translate("Pace") . "</i></div>")
			
		chart1 := this.createDriverPaceChart(1, 555, 248, this.Drivers)
		
		html .= ("<br><br><div id=""chart_1" . """ style=""width: 555px; height: 248px""></div>")
			
		html .= ("<br><br><div id=""header""><i>" . translate("Performance") . "</i></div>")
			
		chart2 := this.createDriverPerformanceChart(2, 555, 248, this.Drivers)
		
		html .= ("<br><br><div id=""chart_2" . """ style=""width: 555px; height: 248px""></div>")
		
		this.showDetails("Driver", html, [1, chart1], [2, chart2])
	}
	
	createRaceSummaryChart(chartID, width, height, lapSeries, positionSeries, fuelSeries, tyreSeries) {
		drawChartFunction := ("function drawChart" . chartID . "() {`nvar data = new google.visualization.DataTable();")
		
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Lap") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Position") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Fuel Remaining") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Tyre Laps") . "');")
		drawChartFunction .= "`ndata.addRows(["
		
		for ignore, time in lapSeries {
			if (A_Index > 1)
				drawChartFunction .= ", "
			
			drawChartFunction .= ("[" . values2String(", ", lapSeries[A_Index]
														  , chartValue(null(positionSeries[A_Index]))
														  , chartValue(null(fuelSeries[A_Index]))
														  , chartValue(null(tyreSeries[A_Index])))
									  . "]")
		}
		
		drawChartFunction .= ("]);`nvar options = { legend: { position: 'Right' }, chartArea: { left: '10%', top: '5%', right: '25%', bottom: '20%' }, hAxis: { title: '" . translate("Lap") . "' }, vAxis: { viewWindow: { min: 0 } }, backgroundColor: 'D8D8D8' };`n")
				
		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")
		
		return drawChartFunction
	}
	
	showRaceSummary() {
		html := ("<div id=""header""><b>" . translate("Race Summary") . "</b></div>")
		
		html .= ("<br><br><div id=""header""><i>" . translate("Stints") . "</i></div>")
		
		stints := []
		drivers := []
		laps := []
		durations := []
		numLaps := []
		positions := []
		avgLapTimes := []
		fuelConsumptions := []
		accidents := []
		
		currentStint := this.CurrentStint
		
		if currentStint
			Loop % currentStint.Nr
			{
				stint := this.Stints[A_Index]
				
				stints.Push("<th class=""th-std"">" . stint.Nr . "</th>")
				drivers.Push("<td class=""td-std"">" . StrReplace(stint.Driver.Nickname, "'", "\'") . "</td>")
				laps.Push("<td class=""td-std"">" . stint.Lap . "</td>")
				
				duration := 0
				
				for ignore, lap in stint.Laps
					duration += lap.Laptime
				
				durations.Push("<td class=""td-std"">" . Round(duration / 60) . "</td>")
				numLaps.Push("<td class=""td-std"">" . stint.Laps.Length() . "</td>")
				positions.Push("<td class=""td-std"">" . stint.StartPosition . translate(" -> ") . stint.EndPosition . "</td>")
				avgLapTimes.Push("<td class=""td-std"">" . stint.AvgLaptime . "</td>")
				fuelConsumptions.Push("<td class=""td-std"">" . stint.FuelConsumption . "</td>")
				accidents.Push("<td class=""td-std"">" . stint.Accidents . "</td>")
			}
		
		html .= "<br><br><table class=""table-std"">"
		html .= ("<tr><th class=""th-std th-left"">" . translate("Stint") . "</th>" . values2String("", stints*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Driver") . "</th>" . values2String("", drivers*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Lap") . "</th>" . values2String("", laps*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Duration") . "</th>" . values2String("", durations*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Laps") . "</th>" . values2String("", numLaps*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Position") . "</th>" . values2String("", positions*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Avg. Lap Time") . "</th>" . values2String("", avgLapTimes*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Consumption") . "</th>" . values2String("", fuelConsumptions*) . "</tr>")
		html .= ("<tr><th class=""th-std th-left"">" . translate("Accidents") . "</th>" . values2String("", accidents*) . "</tr>")
		html .= "</table>"
		
		html .= ("<br><br><div id=""header""><i>" . translate("Race Course") . "</i></div>")
		
		laps := []
		positions := []
		remainingFuels := []
		tyreLaps := []
		
		lastLap := this.LastLap
		
		lapDataTable := this.SessionDatabase.Tables["Lap.Data"]
		
		if lastLap
			Loop % lastLap.Nr
			{
				lap := this.Laps[A_Index]
				
				laps.Push(A_Index)
				positions.Push(lap.Position)
				remainingFuels.Push(lap.FuelRemaining)
				tyreLaps.Push(lapDataTable[A_Index]["Tyre.Laps"])
			}
		
		chart1 := this.createRaceSummaryChart(1, 555, 248, laps, positions, remainingFuels, tyreLaps)
		
		html .= ("<br><br><div id=""chart_1" . """ style=""width: 555px; height: 248px""></div>")
		
		this.showDetails("Session", html, [1, chart1])
	}
	
	showPlanDetails() {
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.PlanListView
		
		html := ("<div id=""header""><b>" . translate("Plan Summary") . "</b></div>")
		
		stints := []
		drivers := []
		laps := []
		durations := []
		numLaps := []
		positions := []
		avgLapTimes := []
		fuelConsumptions := []
		accidents := []
		
		currentStint := this.CurrentStint
		
		if currentStint
			Loop % currentStint.Nr
			{
				stint := this.Stints[A_Index]
				
				stints.Push("<th class=""th-std"">" . stint.Nr . "</th>")
				drivers.Push("<td class=""td-std"">" . StrReplace(stint.Driver.Nickname, "'", "\'") . "</td>")
				laps.Push("<td class=""td-std"">" . stint.Lap . "</td>")
				
				duration := 0
				
				for ignore, lap in stint.Laps
					duration += lap.Laptime
				
				durations.Push("<td class=""td-std"">" . Round(duration / 60) . "</td>")
				numLaps.Push("<td class=""td-std"">" . stint.Laps.Length() . "</td>")
				positions.Push("<td class=""td-std"">" . stint.StartPosition . translate(" -> ") . stint.EndPosition . "</td>")
				avgLapTimes.Push("<td class=""td-std"">" . stint.AvgLaptime . "</td>")
				fuelConsumptions.Push("<td class=""td-std"">" . stint.FuelConsumption . "</td>")
				accidents.Push("<td class=""td-std"">" . stint.Accidents . "</td>")
			}
		
		html .= "<br><br><table class=""table-std"">"
		
		html .= ("<tr><th class=""th-std"">" . translate("Stint") . "</th>"
			   . "<th class=""th-std"">" . translate("Driver") . "</th>"
			   . "<th class=""th-std"">" . translate("Time (est.)") . "</th>"
			   . "<th class=""th-std"">" . translate("Time (act.)") . "</th>"
			   . "<th class=""th-std"">" . translate("Lap (est.)") . "</th>"
			   . "<th class=""th-std"">" . translate("Lap (act.)") . "</th>"
			   . "<th class=""th-std"">" . translate("Refuel") . "</th>"
			   . "<th class=""th-std"">" . translate("Tyre Change") . "</th>"
			   . "</tr>")
	
		Loop % LV_GetCount()
		{
			LV_GetText(stint, A_Index, 1)
			LV_GetText(driver, A_Index, 2)
			LV_GetText(timePlanned, A_Index, 3)
			LV_GetText(timeActual, A_Index, 4)
			LV_GetText(lapPlanned, A_Index, 5)
			LV_GetText(lapActual, A_Index, 6)
			LV_GetText(refuelAmount, A_Index, 7)
			LV_GetText(tyreChange, A_Index, 8)
			
			html .= ("<tr><td class=""td-std"">" . stint . "</td>"
				   . "<td class=""td-std"">" . driver . "</td>"
				   . "<td class=""td-std"">" . timePlanned . "</td>"
				   . "<td class=""td-std"">" . timeActual . "</td>"
				   . "<td class=""td-std"">" . lapPlanned . "</td>"
				   . "<td class=""td-std"">" . lapActual . "</td>"
				   . "<td class=""td-std"">" . refuelAmount . "</td>"
				   . "<td class=""td-std"">" . tyreChange . "</td>"
				   . "</tr>")
		}
		
		html .= "</table>"
		
		this.showDetails("Plan", html)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

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

fixIE(version := 0, exeName := "") {
	static key := "Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
	static versions := {7: 7000, 8: 8888, 9: 9999, 10: 10001, 11: 11001}
	
	if versions.HasKey(version)
		version := versions[version]
	
	if !exeName {
		if A_IsCompiled
			exeName := A_ScriptName
		else
			SplitPath A_AhkPath, exeName
	}
	
	RegRead previousValue, HKCU, %key%, %exeName%

	if (version = "")
		RegDelete, HKCU, %key%, %exeName%
	else
		RegWrite, REG_DWORD, HKCU, %key%, %exeName%, %version%
	
	return previousValue
}

displayValue(value) {
	return ((value == kNull) ? "-" : value)
}

chartValue(value) {
	return ((value == kNull) ? "null" : value)
}

null(value) {
	return (((value == 0) || (value == "-") || (value = "n/a")) ? kNull : valueOrNull(value))
}

objectOrder(a, b) {
	return (a.Nr > b.Nr)
}

parseObject(properties) {
	result := {}
	
	properties := StrReplace(properties, "`r", "")
	
	Loop Parse, properties, `n
	{
		property := string2Values("=", A_LoopField)
		
		result[property[1]] := property[2]
	}
	
	return result
}

computeDriverName(forName, surName, nickName) {
	name := ""
	
	if (forName != "")
		name .= (forName . A_Space)
	
	if (surName != "")
		name .= (surName . A_Space)
	
	if (nickName != "")
		name .= (translate("(") . nickName . translate(")"))
	
	return Trim(name)
}

getKeys(map) {
	keys := []
	
	for key, ignore in map
		keys.Push(key)
	
	return keys
}

getValues(map) {
	values := []
	
	for ignore, value in map
		values.Push(value)
	
	return values
}

loadTeams(connector) {
	teams := {}
	
	try {
		for ignore, identifier in string2Values(";", connector.GetAllTeams()) {
			team := parseObject(connector.GetTeam(identifier))
			
			teams[team.Name] := team.Identifier
		}
	}
	catch exception {
		; ignore
	}
	
	return teams
}

loadSessions(connector, team) {
	sessions := {}

	if team
		for ignore, identifier in string2Values(";", connector.GetTeamSessions(team)) {
			try {
				session := parseObject(connector.GetSession(identifier))
				
				sessions[session.Name] := session.Identifier
			}
			catch exception {
				; ignore
			}
		}			
	
	return sessions
}

loadDrivers(connector, team) {
	drivers := {}

	if team
		for ignore, identifier in string2Values(";", connector.GetTeamDrivers(team)) {
			try {
				driver := parseObject(connector.GetDriver(identifier))
				
				name := computeDriverName(driver.ForName, driver.SurName, driver.NickName)
				
				drivers[name] := driver.Identifier
			}
			catch exception {
				; ignore
			}
		}			
	
	return drivers
}

moveRaceCenter() {
	moveByMouse(RaceCenter.Instance.Window)
}

closeRaceCenter() {
	RaceCenter.Instance.close()
}

connectServer() {
	rCenter := RaceCenter.Instance
	
	GuiControlGet serverURLEdit
	GuiControlGet serverTokenEdit
	
	rCenter.iServerURL := serverURLEdit
	rCenter.iServerToken := ((serverTokenEdit = "") ? "__INVALID__" : serverTokenEdit)
	
	rCenter.connect()
}

chooseTeam() {
	rCenter := RaceCenter.Instance
	
	GuiControlGet teamDropDownMenu
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "selectTeam")
							   , getValues(rCenter.Teams)[teamDropDownMenu])
}

chooseSession() {
	rCenter := RaceCenter.Instance
	
	GuiControlGet sessionDropDownMenu
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "selectSession")
							   , getValues(rCenter.Sessions)[sessionDropDownMenu])
}

chooseChartType() {
	rCenter := RaceCenter.Instance
	
	GuiControlGet chartTypeDropDown
	
	rCenter.selectChartType(["Scatter", "Bar", "Bubble", "Line"][chartTypeDropDown])
}

sessionMenu() {
	GuiControlGet sessionMenuDropDown
	
	GuiControl Choose, sessionMenuDropDown, 1
	
	RaceCenter.Instance.withExceptionhandler(ObjBindMethod(RaceCenter.Instance, "chooseSessionMenu", sessionMenuDropDown))
}

planMenu() {
	GuiControlGet planMenuDropDown
	
	GuiControl Choose, planMenuDropDown, 1
	
	RaceCenter.Instance.withExceptionhandler(ObjBindMethod(RaceCenter.Instance, "choosePlanMenu", planMenuDropDown))
}

strategyMenu() {
	GuiControlGet strategyMenuDropDown
	
	GuiControl Choose, strategyMenuDropDown, 1
	
	RaceCenter.Instance.withExceptionhandler(ObjBindMethod(RaceCenter.Instance, "chooseStrategyMenu", strategyMenuDropDown))
}

pitstopMenu() {
	GuiControlGet pitstopMenuDropDown
	
	GuiControl Choose, pitstopMenuDropDown, 1
	
	RaceCenter.Instance.withExceptionhandler(ObjBindMethod(RaceCenter.Instance, "choosePitstopMenu", pitstopMenuDropDown))
}

openDashboardDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Team-Server#race-center
}

updateDate() {
	rCenter := RaceCenter.Instance
	
	GuiControlGet sessionDateCal
	
	rCenter.iDate := sessionDateCal
}

updateTime() {
	rCenter := RaceCenter.Instance
	
	GuiControlGet sessionTimeEdit
	
	time := rCenter.Time
	
	EnvSub time, %sessionTimeEdit%, Minutes
	
	rCenter.iTime := sessionTimeEdit
	
	rCenter.updatePlan(-time)
	
	Gui ListView, % rCenter.PlanListView

	Loop % LV_GetCount()
		LV_Modify(A_Index, "-Select")
	
	rCenter.updateState()
}

choosePlan() {
	if (((A_GuiEvent = "Normal") || (A_GuiEvent = "RightClick")) && (A_EventInfo > 0)) {
		rCenter := RaceCenter.Instance
	
		window := rCenter.Window
		
		Gui %window%:Default
		
		Gui ListView, % rCenter.PlanListView

		LV_GetText(stint, A_EventInfo, 1)
		LV_GetText(driver, A_EventInfo, 2)
		LV_GetText(timePlanned, A_EventInfo, 3)
		LV_GetText(timeActual, A_EventInfo, 4)
		LV_GetText(lapPlanned, A_EventInfo, 5)
		LV_GetText(lapActual, A_EventInfo, 6)
		LV_GetText(refuelAmount, A_EventInfo, 7)
		LV_GetText(tyreChange, A_EventInfo, 8)
		
		time := string2Values(":", timePlanned)
		
		currentTime := "20200101000000"
		
		EnvAdd currentTime, time[1], Hours
		EnvAdd currentTime, time[2], Minutes
		
		timePlanned := currentTime
		
		time := string2Values(":", timeActual)
		
		currentTime := "20200101000000"
		
		EnvAdd currentTime, time[1], Hours
		EnvAdd currentTime, time[2], Minutes
		
		timeActual := currentTime
		
		GuiControl Choose, driverDropDownMenu, % (inList(getKeys(rCenter.SessionDrivers), driver) + 1)
		GuiControl, , planTimeEdit, %timePlanned%
		GuiControl, , actTimeEdit, %timeActual%
		GuiControl, , planLapEdit, %lapPlanned%
		GuiControl, , actLapEdit, %lapActual%
		GuiControl, , planRefuelEdit, %refuelAmount%
		GuiControl Choose, planTyreCompoundDropDown, % ((tyreChange = "x") ? 1 : 2)
	
		rCenter.updateState()
	}
}

updatePlan() {
	rCenter := RaceCenter.Instance
	
	Gui ListView, % rCenter.PlanListView
	
	row := LV_GetNext(0)
	
	if (row > 0) {
		GuiControlGet driverDropDownMenu
		GuiControlGet planTimeEdit
		GuiControlGet actTimeEdit
		GuiControlGet planLapEdit
		GuiControlGet actLapEdit
		GuiControlGet planRefuelEdit
		GuiControlGet planTyreCompoundDropDown
		
		if (driverDropDownMenu = 1)
			LV_Modify(row, "Col2", "")
		else
			LV_Modify(row, "Col2", getKeys(rCenter.SessionDrivers)[driverDropDownMenu - 1])

		FormatTime time, %planTimeEdit%, HH:mm
		
		LV_Modify(row, "Col3", ((time = "00:00") ? "" : time))
		
		FormatTime time, %actTimeEdit%, HH:mm
		
		LV_Modify(row, "Col4", ((time = "00:00") ? "" : time))
		
		LV_GetText(stint, row)
		
		if (stint > 1)
			LV_Modify(row, "Col5", planLapEdit, actLapEdit, planRefuelEdit, (planTyreCompoundDropDown = 2) ? "" : "x")
		
		if (rCenter.SelectedDetailReport = "Plan")
			rCenter.showPlanDetails()
	}
}

addPlan() {
	rCenter := RaceCenter.Instance
	
	window := rCenter.Window
	
	Gui %window%:Default
	
	Gui ListView, % rCenter.PlanListView
	
	if LV_GetNext(0) {
		title := translate("Insert")
		
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Before", "After", "Cancel"]))
		MsgBox 262179, %title%, % translate("Do you want to add the new entry before or after the currently selected entry?")
		OnMessage(0x44, "")
		
		IfMsgBox Cancel
			return
		
		IfMsgBox Yes
			rCenter.withExceptionhandler(ObjBindMethod(rCenter, "addPlan", "Before"))
		
		IfMsgBox No
			rCenter.withExceptionhandler(ObjBindMethod(rCenter, "addPlan", "After"))
	}
	else
		rCenter.withExceptionhandler(ObjBindMethod(rCenter, "addPlan"))
}

deletePlan() {
	rCenter := RaceCenter.Instance
	
	window := rCenter.Window
	
	Gui %window%:Default
	
	Gui ListView, % rCenter.PlanListView
	
	if LV_GetNext(0) {
		title := translate("Delete")
					
		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
		MsgBox 262436, %title%, % translate("Do you really want to delete the selected plan entry?")
		OnMessage(0x44, "")
		
		IfMsgBox Yes
			rCenter.withExceptionhandler(ObjBindMethod(rCenter, "deletePlan"))
	}
}

releasePlan() {
	rCenter := RaceCenter.Instance
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "releasePlan"))
}

updateState() {
	rCenter := RaceCenter.Instance
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "updateState"))
}

planPitstop() {
	rCenter := RaceCenter.Instance
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "planPitstop"))
}

chooseStint() {
	rCenter := RaceCenter.Instance
	
	Gui ListView, % rCenter.StintsListView
	
	if (((A_GuiEvent = "Normal") || (A_GuiEvent = "RightClick")) && (A_EventInfo > 0)) {
		LV_GetText(stint, A_EventInfo, 1)
		
		rCenter.withExceptionhandler(ObjBindMethod(rCenter, "showStintDetails", rCenter.Stints[stint]))
	}
}

chooseLap() {
	rCenter := RaceCenter.Instance
	
	Gui ListView, % rCenter.LapsListView
	
	if (((A_GuiEvent = "Normal") || (A_GuiEvent = "RightClick")) && (A_EventInfo > 0)) {
		LV_GetText(lap, A_EventInfo, 1)
		
		rCenter.withExceptionhandler(ObjBindMethod(rCenter, "showLapDetails", rCenter.Laps[lap]))
	}
}

choosePitstop() {
	rCenter := RaceCenter.Instance
	
	Gui ListView, % rCenter.PitstopsListView
	
	Loop % LV_GetCount()
		LV_Modify(A_Index, "-Select")
}

chooseReport() {
	rCenter := RaceCenter.Instance
	
	Gui ListView, % reportsListView
	
	if rCenter.HasData {
		if (((A_GuiEvent = "Normal") || (A_GuiEvent = "RightClick")) && (A_EventInfo > 0))
			rCenter.showReport(kSessionReports[A_EventInfo])
	}
	else
		Loop % LV_GetCount()
			LV_Modify(A_Index, "-Select")
}

chooseAxis() {
	rCenter := RaceCenter.Instance
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "showTelemetryReport"))
}

reportSettings() {
	rCenter := RaceCenter.Instance
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "reportSettings", rCenter.SelectedReport))
}

setTyrePressures(compound, compoundColor, flPressure, frPressure, rlPressure, rrPressure) {
	rCenter := RaceCenter.Instance
	
	rCenter.withExceptionhandler(ObjBindMethod(rCenter, "initializePitstopTyreSetup", compound, compoundColor, flPressure, frPressure, rlPressure, rrPressure))
	
	return false
}

syncSession() {
	rCenter := RaceCenter.Instance
	
	try {
		rCenter.syncSession()
	}
	finally {
		SetTimer syncSession, -10000
	}
}

startupRaceCenter() {
	icon := kIconsDirectory . "Console.ico"
	
	Menu Tray, Icon, %icon%, , 1
	Menu Tray, Tip, Race Center

	current := fixIE(11)
	
	try {
		rCenter := new RaceCenter(kSimulatorConfiguration, readConfiguration(kUserConfigDirectory . "Race.settings"))
		
		rCenter.createGui(rCenter.Configuration)
		
		rCenter.connect(true)
		
		registerEventHandler("Setup", "functionEventHandler")
		
		rCenter.show()
		
		ExitApp 0
	}
	finally {
		fixIE(current)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                          Initialization Section                         ;;;
;;;-------------------------------------------------------------------------;;;

startupRaceCenter()