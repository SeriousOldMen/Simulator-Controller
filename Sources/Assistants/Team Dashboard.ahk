﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Team Team Dashboard             ;;;
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
;@Ahk2Exe-ExeName Team Dashboard.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\Math.ahk
#Include ..\Libraries\CLR.ahk
#Include Libraries\RaceReportViewer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                   Private Constant Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

global kClose = "Close"
global kConnect = "Connect"
global kEvent = "Event"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vToken := false


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global serverURLEdit
global serverTokenEdit
global teamDropDownMenu
global sessionDropDownMenu

global chartTypeDropDown
global chartViewer

global informationViewer

global analysisMenuDropDown
global informationMenuDropDown
global pitstopMenuDropDown

global pitstopLapEdit
global pitstopRefuelEdit
global pitstopTyreCompoundDropDown
global pitstopTyreSetEdit
global pitstopPressureFLEdit
global pitstopPressureFREdit
global pitstopPressureRLEdit
global pitstopPressureRREdit
global pitstopRepairsDropDown

class TeamDashboard extends ConfigurationItem {
	iClosed := false
	
	iSessionDirectory := false
	iRaceSettings := false
	
	iConnector := false
	iConnected := false
	
	iServerURL := ""
	iServerToken := ""
	
	iTeams := {}
	iSessions := {}
	
	iTeamIdentifier := false
	iTeamName := false
	
	iSessionIdentifier := false
	iSessionName := false
	
	iStints := {}
	iLaps := {}
	
	iCurrentStint := false
	iLastLap := false
	
	iStintsListView := false
	iLapsListView := false
	
	iReportViewer := false
	
	Window[] {
		Get {
			return "Dashboard"
		}
	}
	
	RaceSettings[] {
		Get {
			return this.iRaceSettings
		}
	}
	
	SessionDirectory[] {
		Get {
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
	
	ActiveSession[] {
		Get {
			return (this.Connected && this.SelectedTeam[true] && this.SelectedSession[true])
		}
	}
	
	Stints[key := false] {
		Get {
			return (key ? this.iStints[key] : this.iStints)
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
	}
	
	LastLap[asIdentifier := false] {
		Get {
			if this.iLastLap
				return (asIdentifier ? this.iLastLap.Identifier : this.iLastLap)
			else
				return false
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
	
	ReportViewer[] {
		Get {
			return this.iReportViewer
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
		
		TeamDashboard.Instance := this

		this.initializeSession()
		
		callback := ObjBindMethod(this, "syncSession")
		
		SetTimer %callback%, 10000
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		this.iSessionDirectory := getConfigurationValue(configuration, "Team Server", "Session.Folder", kTempDirectory . "Sessions")
		
		settings := this.RaceSettings
		
		this.iServerURL := getConfigurationValue(settings, "Team Settings", "Server.URL", "")
		this.iServerToken := getConfigurationValue(settings, "Team Settings", "Server.Token", "")
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

		Gui %window%:Add, Text, w1184 Center gmoveTeamDashboard, % translate("Modular Simulator Controller System") 
		
		Gui %window%:Font, s9 Norm, Arial
		Gui %window%:Font, Italic Underline, Arial

		Gui %window%:Add, Text, YP+20 w1184 cBlue Center gopenDashboardDocumentation, % translate("Team Dashboard")
		
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
		
		Gui %window%:Add, Text, x16 yp+26 w90 h23 +0x200, % translate("Access Token")
		Gui %window%:Add, Edit, x141 yp-1 w245 h21 VserverTokenEdit, % this.ServerToken
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
		
		Gui %window%:Add, Text, x400 ys w40 h23 +0x200, % translate("Chart")
		Gui %window%:Add, DropDownList, x444 yp w80 AltSubmit Choose1 vchartTypeDropDown gchooseChartType, % values2String("|", map(["Scatter", "Bar", "Bubble", "Line"], "translate")*)
		
		Gui %window%:Add, ActiveX, x400 yp+24 w800 h278 Border vchartViewer, shell.explorer
		
		chartViewer.Navigate("about:blank")
		
		Gui %window%:Add, Text, x8 yp+286 w1200 0x10

		Gui %window%:Font, s10 Bold, Arial
			
		Gui %window%:Add, Picture, x16 yp+10 w30 h30 Section, %kIconsDirectory%Tools BW.ico
		Gui %window%:Add, Text, x50 yp+5 w80 h26, % translate("Session")
		
		Gui %window%:Font, s8 Norm, Arial

		Gui %window%:Add, DropDownList, x220 yp-2 w180 AltSubmit Choose1 +0x200 vanalysisMenuDropDown ganalysisMenu, % values2String("|", map(["Analysis", "---------------------------------------------"], "translate")*)
		
		Gui %window%:Add, DropDownList, x405 yp w180 AltSubmit Choose1 +0x200 vinformationMenuDropDown ginformationMenu, % values2String("|", map(["Information", "---------------------------------------------"], "translate")*)
		
		Gui %window%:Add, DropDownList, x590 yp w180 AltSubmit Choose1 +0x200 vpitstopMenuDropDown gpitstopMenu, % values2String("|", map(["Pitstop", "---------------------------------------------", "Instruct Engineer..."], "translate")*)
		
		Gui %window%:Font, s8 Norm, Arial
		
		Gui %window%:Font, Norm, Arial
		Gui %window%:Font, Italic, Arial

		Gui %window%:Add, GroupBox, -Theme x619 ys+39 w577 h9, % translate("Information")
		
		Gui %window%:Add, ActiveX, x619 yp+21 w577 h193 Border vinformationViewer, shell.explorer
		
		informationViewer.Navigate("about:blank")
		
		this.showInformation(false)
		this.showChart(false)
		
		Gui %window%:Font, Norm, Arial
		
		Gui %window%:Add, Text, x8 y650 w1200 0x10
		
		Gui %window%:Add, Button, x574 y656 w80 h23 GcloseTeamDashboard, % translate("Close")

		Gui %window%:Add, Tab, x16 ys+39 w593 h216 -Wrap Section, % values2String("|", map(["Stints", "Laps", "Pitstop"], "translate")*)
		
		Gui Tab, 1
		
		Gui %window%:Add, ListView, x24 ys+34 w577 h170 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistHandle, % values2String("|", map(["#", "Driver", "Weather", "Compound", "Laps", "Pos. (Start)", "Pos. (End)", "Avg. Laptime", "Consumption", "Accidents", "Race Craft", "Consistency", "Car Control"], "translate")*)
		
		this.iStintsListView := listHandle
		
		Gui Tab, 2
		
		Gui %window%:Add, ListView, x24 ys+34 w577 h170 -Multi -LV0x10 AltSubmit NoSort NoSortHdr HWNDlistHandle, % values2String("|", map(["#", "Stint", "Driver", "Position", "Laptime", "Consumption", "Accident"], "translate")*)
		
		this.iLapsListView := listHandle
		
		Gui Tab, 3
	
		Gui %window%:Add, Text, x24 ys+34 w85 h20, % translate("Lap")
		Gui %window%:Add, Edit, x106 yp-2 w50 h20 Limit3 Number vpitstopLapEdit
		Gui %window%:Add, UpDown, x138 yp-2 w18 h20
		
		Gui %window%:Add, Text, x24 yp+30 w85 h20, % translate("Refuel")
		Gui %window%:Add, Edit, x106 yp-2 w50 h20 Limit3 Number vpitstopRefuelEdit
		Gui %window%:Add, UpDown, x138 yp-2 w18 h20
		Gui %window%:Add, Text, x164 yp+2 w30 h20, % translate("Liter")

		Gui %window%:Add, Text, x24 yp+24 w85 h23 +0x200 Section, % translate("Tyre Change")
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
		
		this.iReportViewer := new RaceReportViewer(window, chartViewer)
		
		this.updateState()
	}
	
	connect(serverURL, serverToken, silent := false) {
		try {
			this.Connector.Connect(serverURL, serverToken)
	
			this.iConnected := true
			
			showMessage(translate("Successfully connected to the Team Server."))
			
			this.initializeSession()
			this.loadTeams()
		}
		catch exception {
			this.iServerToken := ""
			
			GuiControl, , serverTokenEdit, % ""
			
			if !silent {
				title := translate("Error")
			
				OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
				MsgBox 262160, %title%, % (translate("Cannot connect to the Team Server.") . "`n`n" . translate("Error: ") . exception.Message)
				OnMessage(0x44, "")
			}
		}
		
		this.loadTeams()
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
		
		this.loadSession()
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
	}
	
	planPitstop() {
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
			lap := this.Connector.GetSessionLastLap(sessionIdentifier)

			this.Connector.SetLapValue(lap, "Pitstop Plan", printConfiguration(pitstopPlan))
			this.Connector.SetSessionValue(sessionIdentifier, "Pitstop Plan", lap)
			
			showMessage(translate("Race Engineer will be instructed in the next lap..."))
		}
		catch exception {
			showMessage(translate("Session has not been started yet..."))
		}
	}
	
	chooseAnalysisMenu(line) {
		if !this.ActiveSession
			return
		
		window := this.Window
						
		Gui %window%:Default
		
		switch line {
		}
	}
	
	chooseInformationMenu(line) {
		if !this.ActiveSession
			return
		
		window := this.Window
						
		Gui %window%:Default
		
		switch line {
		}
	}
	
	choosePitstopMenu(line) {
		if !this.ActiveSession
			return
		
		window := this.Window
						
		Gui %window%:Default
		
		switch line {
			case 3:
				this.planPitstop()
		}
	}
	
	withExceptionHandler(function, arguments*) {
		try {
			%function%(arguments*)
		}
		catch exception {
			title := translate("Error")
		
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Ok"]))
			MsgBox 262160, %title%, % (translate("Error while executing command.") . "`n`n" . translate("Error: ") . exception.Message)
			OnMessage(0x44, "")
		}
	}
	
	initializeSession() {
		directory := this.iSessionDirectory
		
		FileCreateDir %directory%
		
		reportDirectory := (directory . "\Race Report")
		
		try {
			FileRemoveDir %reportDirectory%, 1
		}
		catch exception {
			; ignore
		}
	
		FileCreateDir %reportDirectory%
		
		Gui ListView, % this.StintsListView
		
		LV_Delete()
		
		Gui ListView, % this.LapsListView
		
		LV_Delete()
		
		this.iStints := {}
		this.iLaps := {}
		
		this.iLastLap := false
		this.iCurrentStint := false
		
		if (this.ReportViewer) {
			this.ReportViewer.showReportChart(false)
			this.ReportViewer.showReportInfo(false)
		}
	}
	
	loadNewStints(currentStint) {
		session := this.SelectedSession[true]
		newStints := []
			
		if (!this.CurrentStint || (currentStint.Nr > this.CurrentStint.Nr)) {
			for ignore, identifier in string2Values(";", this.Connector.GetSessionStints(session))
				if !this.Stints.HasKey(identifier)
					newStints.Push(parseObject(this.Connector.GetStint(identifier)))
			
			Loop % newStints.Length()
			{
				stint := newStints[A_Index]
				identifier := stint.Identifier
				
				driver := parseObject(this.Connector.GetDriver(this.Connector.GetStintDriver(identifier)))
				
				stint.Driver := driver
				stint.Driver.Fullname := computeDriverName(driver.Forname, driver.Surname, driver.Nickname)
				stint.FuelConsumption := 0.0
				stint.Accidents := 0
				stint.Weather := "-"
				stint.Compound := "-"
				stint.StartPosition := "-"
				stint.EndPosition := "-"
				stint.AvgLaptime := "-"
				stint.RaceCraft := "-"
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
				
		for ignore, identifier in string2Values(";" , this.Connector.GetStintLaps(stint.Identifier))
			if !this.Laps.HasKey(identifier) {
				newLap := parseObject(this.Connector.GetLap(identifier))
				
				if !this.Laps.HasKey(newLap.Nr)
					newLaps.Push(newLap)
			}
		
		bubbleSort(newLaps, "objectOrder")
		
		Loop % newLaps.Length()
		{
			lap := newLaps[A_Index]
			identifier := lap.Identifier
			
			stint.Laps.Push(lap)
			lap.Stint := stint
			
			rawData := this.Connector.GetLapValue(identifier, "Telemetry Data")
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
			
			lap.Weather := translate(getConfigurationValue(data, "Weather Data", "Weather"))
			lap.AirTemperature := Round(getConfigurationValue(data, "Weather Data", "Temperature"), 1)
			lap.TrackTemperature := Round(getConfigurationValue(data, "Track Data", "Temperature"), 1)
			lap.Grip := translate(getConfigurationValue(data, "Track Data", "Grip"))
			
			compound := getConfigurationValue(data, "Car Data", "TyreCompound")
			color := getConfigurationValue(data, "Car Data", "TyreCompoundColor")
			
			if (color != "Black")
				compound .= (" (" . color . ")")
			
			lap.Compound := translate(compound)
			
			rawData := this.Connector.GetLapValue(identifier, "Positions Data")
			data := parseConfiguration(rawData)
			
			lap.Positions := rawData
			
			car := getConfigurationValue(data, "Position Data", "Driver.Car")
			
			if car
				lap.Position := getConfigurationValue(data, "Position Data", "Car." . car . ".Position")
			else
				lap.Position := "-"
			
			this.Laps[identifier] := lap
			this.Laps[lap.Nr] := lap
		}
		
		return newLaps
	}
	
	updateDriverStats(stint) {
	}
		
	updateStint(stint) {
		window := this.Window
				
		Gui %window%:Default
		
		Gui ListView, % this.StintsListView
		
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
		stint.FuelConsumption := Round(stint.FuelConsumption, 1)
		
		this.updateDriverStats(stint)
		
		LV_Modify(stint.Row, "", stint.Nr, stint.Driver.FullName, stint.Weather, stint.Compound, stint.Laps.Length()
							   , stint.StartPosition, stint.EndPosition, stint.AvgLaptime, stint.FuelConsumption, stint.Accidents
							   , stint.RaceCraft, stint.Consistency, stint.CarControl)
	}
	
	syncLaps() {
		session := this.SelectedSession[true]
				
		window := this.Window
		
		Gui %window%:Default
		
		try {
			currentStint := this.Connector.GetSessionCurrentStint(session)
			
			if currentStint
				currentStint := parseObject(this.Connector.GetStint(currentStint))
		}
		catch exception {
			currentStint := false
		}
		
		try {
			lastLap := this.Connector.GetSessionLastLap(session)
			
			if lastLap
				lastLap := parseObject(this.Connector.GetLap(lastLap))
		}
		catch exception {
			lastLap := false
		}
		
		first := (!this.CurrentStint || !this.LastLap)
		
		if (!currentStint || !lastLap) {
			this.initializeSession()
			
			first := true
		}
		else if ((this.CurrentStint && (currentStint.Nr < this.CurrentStint.Nr))
			  || (this.LastLap && (lastLap.Nr < this.LastLap.Nr))) {
			this.initializeSession()
			
			first := true
		}
		
		needsUpdate := first
		
		if !lastLap
			return
		
		if (!this.LastLap || (lastLap.Nr > this.LastLap.Nr)) {
			newStints := this.loadNewStints(currentStint)
			
			currentStint := this.Stints[currentStint.Identifier]
			
			updatedStints := []
			
			if this.CurrentStint
				updatedStints := [this.CurrentStint]
				
			Gui ListView, % this.StintsListView
			
			for ignore, stint in newStints {
				LV_Add("", stint.Nr, stint.Driver.FullName, stint.Weather, stint.Compound, stint.Laps.Length()
						 , stint.StartPosition, stint.EndPosition, stint.AvgLaptime, stint.FuelConsumption, stint.Accidents
						 , stint.RaceCraft, stint.Consistency, stint.CarControl)
				
				stint.Row := LV_GetCount()
				
				updatedStints.Push(stint)
			}
			
			if first {
				LV_ModifyCol()
				
				Loop 13
					LV_ModifyCol(A_Index, "AutoHdr")
			}
	
			Gui ListView, % this.LapsListView
			
			for ignore, stint in updatedStints {
				for ignore, lap in this.loadNewLaps(stint) {
					LV_Add("", lap.Nr, lap.Stint.Nr, stint.Driver.Fullname, lap.Position, lap.Laptime, lap.FuelConsumption, lap.Accident ? translate("x") : "")
				
					lap.Row := LV_GetCount()
				}
			}
			
			if first {
				LV_ModifyCol()
				
				Loop 7
					LV_ModifyCol(A_Index, "AutoHdr")
			}
			
			for ignore, stint in updatedStints
				this.updateStint(stint)
			
			needsUpdate := true
			
			this.iLastLap := lastLap
			this.iCurrentStint := currentStint
		}
	}
	
	syncRaceReport() {
		lastLap := this.LastLap
		
		if lastLap
			lastLap := lastLap.Nr
		
		directory := this.SessionDirectory . "\Race Report"
		session := this.TeamSession
		
		data := readConfiguration(directory . "\Race.data")
		
		if (data.Count() == 0)
			lap := 1
		else
			lap := (getConfigurationValue(data, "Laps", "Count") + 1)
		
		showMessage(lastLap . " " . lap)
		
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
					
				FileAppend %raceInfo%, %directory%\Race.data
			}
			catch exception {
				; ignore
			}
				
			data := readConfiguration(directory . "\Race.data")
		}
		
		newLaps := false
		
		while (lap <= lastLap) {
			lapData := parseConfiguration(this.Connector.getLapValue(this.Laps[lap].Identifier, "Race Strategist Race Lap"))
			
			if (lapData.Count() == 0)
				return
			
			for key, value in getConfigurationSectionValues(lapData, "Lap")
				setConfigurationValue(data, "Laps", key, value)
			
			times := getConfigurationValue(lapData, "Times", lap)
			positions := getConfigurationValue(lapData, "Positions", lap)
			laps := getConfigurationValue(lapData, "Laps", lap)
			drivers := getConfigurationValue(lapData, "Drivers", lap)
			
			newLine := ((lap > 1) ? "`n" : "")
			
			line := (newLine . times)
			
			FileAppend %line%, % directory . "\Times.CSV"
			
			line := (newLine . positions)
			
			FileAppend %line%, % directory . "\Positions.CSV"
			
			line := (newLine . laps)
			
			FileAppend %line%, % directory . "\Laps.CSV"
			
			line := (newLine . drivers)
			fileName := (directory . "\Drivers.CSV")
			
			FileAppend %line%, %fileName%, UTF-16
			
			removeConfigurationValue(data, "Laps", "Lap")
			setConfigurationValue(data, "Laps", "Count", lap)
			
			newLaps := true
			lap += 1
		}
		
		writeConfiguration(directory . "\Race.data", data)
		
		if newlaps
			this.updateReports()
	}
	
	syncTelemetry() {
	}
	
	syncSession() {
		if this.ActiveSession {
			try {
				this.syncLaps()
			}
			catch exception {
				; silent
			}
			
			try {
				this.syncRaceReport()
			}
			catch exception {
				; silent
			}
			
			try {
				this.syncTelemetry()
			}
			catch exception {
				; silent
			}
		}
	}
	
	updateReports() {
		this.ReportViewer.setReport(this.SessionDirectory . "\Race Report")
		this.ReportViewer.showPositionReport()
	}
	
	show() {
		window := this.Window
			
		Gui %window%:Show
		
		while !this.iClosed
			Sleep 1000
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
		this.iSelectedChart := "LapTimes"
		
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
		
		drawChartFunction .= "`ndata.addRows(["
		
		for ignore, values in data {
			if (A_Index > 1)
				drawChartFunction .= ",`n"
			
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
		
		this.showTelemetryChart(drawChartFunction)
	}
	
	showInformation(information) {
		html := ""
		
		if information {
			drawChartFunction := ""
			
			chartArea := ""
			
			before =
			(
				<meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: 'FFFFFF'; }
						.rowStyle { font-size: 11px; background-color: 'E0E0E0'; }
						.oddRowStyle { font-size: 11px; background-color: 'E8E8E8'; }
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawChart%chartID%);
			)

			after =
			(
					</script>
				</head>
			)
		}
		else {
			before := ""
			after := ""
			drawChartFunction := ""
			chartArea := ""
		}
			
		html := ("<html>" . before . drawChartFunction . after . "<body style='background-color: #D8D8D8' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><style> div, table { font-family: Arial, Helvetica, sans-serif; font-size: 11px }</style><style> #stints td { border-right: solid 1px #A0A0A0; } </style><style> #header { font-size: 12px; } </style><style> #data { border-collapse: separate; border-spacing: 10px; text-align: center; } </style><div>" . html . "</div><br>" . chartArea . "</body></html>")

		informationViewer.Document.Open()
		informationViewer.Document.Write(html)
		informationViewer.Document.Close()
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
	
	for ignore, identifier in string2Values(";", connector.GetAllTeams()) {
		team := parseObject(connector.GetTeam(identifier))
		
		teams[team.Name] := team.Identifier
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

moveTeamDashboard() {
	moveByMouse(TeamDashboard.Instance.Window)
}

closeTeamDashboard() {
	TeamDashboard.Instance.close()
}

connectServer() {
	dashboard := TeamDashboard.Instance
	
	dashboard.connect(dashboard.ServerURL, dashboard.ServerToken)
}

chooseTeam() {
	dashboard := TeamDashboard.Instance
	
	GuiControlGet teamDropDownMenu
	
	dashboard.withExceptionhandler(ObjBindMethod(dashboard, "selectTeam")
								 , getValues(dashboard.Teams)[teamDropDownMenu])
}

chooseSession() {
	dashboard := TeamDashboard.Instance
	
	GuiControlGet sessionDropDownMenu
	
	dashboard.withExceptionhandler(ObjBindMethod(dashboard, "selectSession")
								 , getValues(dashboard.Teams)[sessionDropDownMenu])
}

chooseChartType() {
	dashboard := TeamDashboard.Instance
	
	GuiControlGet chartTypeDropDown
	
	dashboard.loadChart(["Scatter", "Bar", "Bubble", "Line"][chartTypeDropDown])
}

analysisMenu() {
	GuiControlGet analysisMenuDropDown
	
	GuiControl Choose, analysisMenuDropDown, 1
	
	TeamDashboard.Instance.chooseAnalysisMenu(analysisMenuDropDown)
}

informationMenu() {
	GuiControlGet informationMenuDropDown
	
	GuiControl Choose, informationMenuDropDown, 1
	
	TeamDashboard.Instance.chooseInformationMenu(informationMenuDropDown)
}

pitstopMenu() {
	GuiControlGet pitstopMenuDropDown
	
	GuiControl Choose, pitstopMenuDropDown, 1
	
	TeamDashboard.Instance.choosePitstopMenu(pitstopMenuDropDown)
}

openDashboardDocumentation() {
	Run https://github.com/SeriousOldMan/Simulator-Controller/wiki/Team-Server#team-dashboard
}

updateState() {
	dashboard := TeamDashboard.Instance
	
	dashboard.withExceptionhandler(ObjBindMethod(dashboard, "updateState"))
}

planPitstop() {
	dashboard := TeamDashboard.Instance
	
	dashboard.withExceptionhandler(ObjBindMethod(dashboard, "planPitstop"))
}

startupTeamDashboard() {
	icon := kIconsDirectory . "Console.ico"
	
	Menu Tray, Icon, %icon%, , 1
	Menu Tray, Tip, Team Dashboard

	current := fixIE(11)
	
	try {
		dashboard := new TeamDashboard(kSimulatorConfiguration, readConfiguration(kUserConfigDirectory . "Race.settings"))
		
		dashboard.createGui(dashboard.Configuration)
		
		dashboard.connect(dashboard.ServerURL, dashboard.ServerToken, true)
		
		dashboard.show()
		
		ExitApp 0
	}
	finally {
		fixIE(current)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                          Initialization Section                         ;;;
;;;-------------------------------------------------------------------------;;;

startupTeamDashboard()