;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Team Server Plugin              ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\Task.ahk
#Include ..\Assistants\Libraries\SessionDatabase.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kSessionFinished := 0
global kSessionPaused := -1
global kSessionOther := 1
global kSessionPractice := 2
global kSessionQualification := 3
global kSessionRace := 4

global kTeamServerPlugin := "Team Server"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class TeamServerPlugin extends ControllerPlugin {
	iConnector := false

	iServerURL := false
	iServerToken := false

	iConnection := false

	iSimulator := false
	iTeam := false
	iDriver := false
	iSession := false

	iDriverForName := false
	iDriverSurName := false
	iDriverNickName := false

	iTeamServerEnabled := false

	iSessionActive := false
	iLapData := {Telemetry: {}, Positions: {}}

	class TeamServerToggleAction extends ControllerAction {
		iPlugin := false

		Plugin[] {
			Get {
				return this.iPlugin
			}
		}

		__New(plugin, function, label, icon) {
			this.iPlugin := plugin

			base.__New(function, label, icon)
		}

		fireAction(function, trigger) {
			local plugin := this.Plugin

			if (plugin.TeamServerEnabled && ((trigger = "Off") || (trigger == "Push"))) {
				plugin.disableTeamServer(plugin.actionLabel(this))

				function.setLabel(plugin.actionLabel(this), "Black")
			}
			else if (!plugin.TeamServerEnabled && ((trigger = "On") || (trigger == "Push"))) {
				plugin.enableTeamServer(plugin.actionLabel(this))

				function.setLabel(plugin.actionLabel(this), "Green")
			}
		}
	}

	class RaceSettingsAction extends ControllerAction {
		iPlugin := false

		Plugin[] {
			Get {
				return this.iPlugin
			}
		}

		__New(plugin, function, label, icon) {
			this.iPlugin := plugin

			base.__New(function, label, icon)
		}

		fireAction(function, trigger) {
			local exePath := kBinariesDirectory . "Race Settings.exe"

			try {
				Run "%exePath%", %kBinariesDirectory%
			}
			catch exception {
				logMessage(kLogCritical, translate("Cannot start the Race Settings tool (") . exePath . translate(") - please rebuild the applications in the binaries folder (") . kBinariesDirectory . translate(")"))

				showMessage(substituteVariables(translate("Cannot start the Race Settings tool (%exePath%) - please check the configuration..."), {exePath: exePath})
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
		}
	}

	class RaceCenterAction extends ControllerAction {
		iPlugin := false

		Plugin[] {
			Get {
				return this.iPlugin
			}
		}

		__New(plugin, function, label, icon) {
			this.iPlugin := plugin

			base.__New(function, label, icon)
		}

		fireAction(function, trigger) {
			local exePath := kBinariesDirectory . "Race Center.exe"

			try {
				Run "%exePath%", %kBinariesDirectory%
			}
			catch exception {
				logMessage(kLogCritical, translate("Cannot start the Race Center tool (") . exePath . translate(") - please rebuild the applications in the binaries folder (") . kBinariesDirectory . translate(")"))

				showMessage(substituteVariables(translate("Cannot start the Race Center tool (%exePath%) - please check the configuration..."), {exePath: exePath})
						  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
			}
		}
	}

	ID[] {
		Get {
			return this.Controller.ID
		}
	}

	Connector[] {
		Get {
			return this.iConnector
		}
	}

	ServerURL[] {
		Get {
			return ((this.iServerURL && (this.iServerURL != "")) ? this.iServerURL : false)
		}
	}

	ServerToken[] {
		Get {
			return ((this.iServerToken && (this.iServerToken != "")) ? this.iServerToken : false)
		}
	}

	Connection[] {
		Get {
			return this.iConnection
		}
	}

	Connected[] {
		Get {
			return (this.Connection != false)
		}
	}

	Simulator[] {
		Get {
			return this.iSimulator
		}
	}

	Team[] {
		Get {
			return ((this.iTeam && (this.iTeam != "")) ? this.iTeam : false)
		}
	}

	Driver[] {
		Get {
			return ((this.iDriver && (this.iDriver != "")) ? this.iDriver : false)
		}
	}

	Session[] {
		Get {
			return ((this.iSession && (this.iSession != "")) ? this.iSession : false)
		}
	}

	DriverForName[force := false] {
		Get {
			return this.getDriverForName(force)
		}
	}

	DriverSurName[force := false] {
		Get {
			return this.getDriverSurName(force)
		}
	}

	DriverNickName[force := false] {
		Get {
			return this.getDriverNickName(force)
		}
	}

	TeamServerEnabled[] {
		Get {
			return this.iTeamServerEnabled
		}
	}

	TeamServerActive[] {
		Get {
			return (this.Connected && this.TeamServerEnabled && this.Team && this.Driver && this.Session)
		}
	}

	SessionActive[] {
		Get {
			return (this.TeamServerActive && this.iSessionActive)
		}
	}

	DriverActive[] {
		Get {
			local currentDriver := this.getCurrentDriver()

			return (this.SessionActive && (currentDriver == this.Driver))
		}
	}

	__New(controller, name, configuration := false, register := true) {
		local dllName := "Team Server Connector.dll"
		local dllFile := kBinariesDirectory . dllName
		local teamServerToggle, arguments, openRaceSettings, openRaceCenter

		try {
			if (!FileExist(dllFile)) {
				logMessage(kLogCritical, translate("Team Server Connector.dll not found in ") . kBinariesDirectory)

				throw "Unable to find Team Server Connector.dll in " . kBinariesDirectory . "..."
			}

			this.iConnector := CLR_LoadLibrary(dllFile).CreateInstance("TeamServer.TeamServerConnector")
		}
		catch exception {
			logMessage(kLogCritical, translate("Error while initializing Team Server Connector - please rebuild the applications"))

			showMessage(translate("Error while initializing Team Server Connector - please rebuild the applications") . translate("...")
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}

		base.__New(controller, name, configuration, false)

		if (this.Active || isDebug()) {
			teamServerToggle := this.getArgumentValue("teamServer", false)

			if teamServerToggle {
				arguments := string2Values(A_Space, teamServerToggle)

				if (arguments.Length() == 0)
					arguments := ["On"]

				if ((arguments.Length() == 1) && !inList(["On", "Off"], arguments[1]))
					arguments.InsertAt(1, "Off")

				this.iTeamServerEnabled := (arguments[1] = "On")

				if (arguments.Length() > 1)
					this.createTeamServerAction(controller, "TeamServer", arguments[2])
			}
			else
				this.iTeamServerEnabled := false

			openRaceSettings := this.getArgumentValue("openRaceSettings", false)

			if openRaceSettings
				this.createTeamServerAction(controller, "RaceSettingsOpen", openRaceSettings)

			openRaceCenter := this.getArgumentValue("openRaceCenter", false)

			if openRaceCenter
				this.createTeamServerAction(controller, "RaceCenterOpen", openRaceCenter)

			if register
				controller.registerPlugin(this)

			if this.TeamServerEnabled
				this.enableTeamServer(false, true)
			else
				this.disableTeamServer(false, true)

			this.keepAlive(true)

			OnExit(ObjBindMethod(this, "finishSession"))
		}
	}

	createTeamServerAction(controller, action, actionFunction, arguments*) {
		local function := controller.findFunction(actionFunction)
		local descriptor

		if (function != false) {
			if (action = "TeamServer") {
				descriptor := ConfigurationItem.descriptor(action, "Toggle")

				this.registerAction(new this.TeamServerToggleAction(this, function, this.getLabel(descriptor, action), this.getIcon(descriptor)))
			}
			else if (action = "RaceSettingsOpen") {
				descriptor := ConfigurationItem.descriptor(action, "Activate")

				this.registerAction(new this.RaceSettingsAction(this, function, this.getLabel(descriptor, action), this.getIcon(descriptor)))
			}
			else if (action = "RaceSettingsOpen") {
				descriptor := ConfigurationItem.descriptor(action, "Activate")

				this.registerAction(new this.RaceCenterAction(this, function, this.getLabel(descriptor, action), this.getIcon(descriptor)))
			}
			else
				logMessage(kLogWarn, translate("Action """) . action . translate(""" not found in plugin ") . translate(this.Plugin) . translate(" - please check the configuration"))
		}
		else
			this.logFunctionNotFound(actionFunction)
	}

	activate() {
		base.activate()

		this.updateActions(kSessionFinished)
	}

	updateActions(session) {
		local ignore, theAction

		for ignore, theAction in this.Actions
			if isInstance(theAction, TeamServerPlugin.TeamServerToggleAction) {
				theAction.Function.enable(kAllTrigger, theAction)
				theAction.Function.setLabel(this.actionLabel(theAction), this.TeamServerEnabled ? "Green" : "Black")
			}
			else if isInstance(theAction, TeamServerPlugin.RaceSettingsAction) {
				theAction.Function.enable(kAllTrigger, theAction)
				theAction.Function.setLabel(theAction.Label)
			}
	}

	toggleTeamServer() {
		if this.TeamServerEnabled
			this.disableTeamServer()
		else
			this.enableTeamServer()
	}

	updateTrayLabel(label, enabled) {
		local callback, index

		static hasTrayMenu := false

		label := StrReplace(label, "`n", A_Space)

		if !hasTrayMenu {
			callback := ObjBindMethod(this, "toggleTeamServer")

			Menu Tray, Insert, 1&
			Menu Tray, Insert, 1&, %label%, %callback%

			hasTrayMenu := true
		}

		if enabled
			Menu Tray, Check, %label%
		else
			Menu Tray, Uncheck, %label%
	}

	enableTeamServer(label := false, force := false) {
		if (!this.TeamServerEnabled || force) {
			if !label
				label := this.getLabel("TeamServer.Toggle")

			trayMessage(label, translate("State: On"))

			this.iTeamServerEnabled := true

			Task.startTask(ObjBindMethod(this, "tryConnect"), 2000, kLowPriority)

			this.updateActions(kSessionFinished)

			this.updateTrayLabel(label, true)
		}
	}

	disableTeamServer(label := false, force := false) {
		if (this.TeamServerEnabled || force) {
			if !label
				label := this.getLabel("TeamServer.Toggle")

			trayMessage(label, translate("State: Off"))

			this.disconnect(true, true)

			Menu Tray, Tip, % string2Values(".", A_ScriptName)[1]

			this.iTeamServerEnabled := false

			this.updateActions(kSessionFinished)

			this.updateTrayLabel(label, false)
		}
	}

	parseObject(properties) {
		local result := {}
		local property

		properties := StrReplace(properties, "`r", "")

		loop Parse, properties, `n
		{
			property := string2Values("=", A_LoopField)

			result[property[1]] := property[2]
		}

		return result
	}

	setSession(team, driver, session) {
		this.iTeam := ((team && (team != "")) ? team : false)
		this.iDriver := ((driver && (driver != "")) ? driver : false)
		this.iSession := ((session && (session != "")) ? session : false)

		this.iDriverForName := false
		this.iDriverSurName := false
		this.iDriverNickName := false
	}

	tryConnect() {
		local settings := readConfiguration(getFileName("Race.settings", kUserConfigDirectory))
		local serverURL := getConfigurationValue(settings, "Team Settings", "Server.URL", "")
		local serverToken := getConfigurationValue(settings, "Team Settings", "Server.Token", "")
		local teamIdentifier := getConfigurationValue(settings, "Team Settings", "Team.Identifier", false)
		local driverIdentifier := getConfigurationValue(settings, "Team Settings", "Driver.Identifier", false)
		local sessionIdentifier := getConfigurationValue(settings, "Team Settings", "Session.Identifier", false)

		this.connect(serverURL, serverToken, teamIdentifier, driverIdentifier, sessionIdentifier, !kSilentMode)

		this.disconnect()
	}

	connect(serverURL, serverToken, team, driver, session, verbose := false) {
		local driverObject, teamName, driverName, sessionName

		this.disconnect()

		this.iServerURL := ((serverURL && (serverURL != "")) ? serverURL : false)
		this.iServerToken := ((serverToken && (serverToken != "")) ? serverToken : false)

		this.setSession(team, driver, session)

		this.keepAlive()

		if this.Connected {
			try {
				driverObject := this.parseObject(this.Connector.GetDriver(driver))

				teamName := this.parseObject(this.Connector.GetTeam(team)).Name
				driverName := (driverObject.ForName . A_Space . driverObject.SurName)
				sessionName := this.parseObject(this.Connector.GetSession(session)).Name

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Connected to the Team Server (URL: ") . serverURL . translate(", Token: ") . serverToken . translate(", Team: ") . team . translate(", Driver: ") . driver . translate(", Session: ") . session . translate(")"))

				if verbose
					showMessage(translate("Successfully connected to the Team Server.") . "`n`n"
										. translate("Team: ") . teamName . "`n"
										. translate("Driver: ") . driverName . "`n"
										. translate("Session: ") . sessionName
							  , false, "Information.png", 5000, "Center", "Bottom", 400, 120)

				Menu Tray, Tip, % string2Values(".", A_ScriptName)[1] . translate(" (Team: ") . teamName . translate(")")
			}
			catch exception {
				this.iConnection := false

				Menu Tray, Tip, % string2Values(".", A_ScriptName)[1] . translate(" (Team: Error)")

				logMessage(kLogCritical, translate("Cannot connect to the Team Server (URL: ") . serverURL . translate(", Token: ") . serverToken . translate(", Team: ") . team . translate(", Driver: ") . driver . translate(", Session: ") . session . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))

				this.disconnect(false)
			}
		}

		return (this.Connected && this.Team && this.Driver && this.Session)
	}

	disconnect(leave := true, disconnect := false) {
		if (leave && this.SessionActive)
			this.leaveSession()

		if disconnect {
			this.iServerURL := false
			this.iServerToken := false

			this.iConnection := false

			this.keepAlive()
		}
	}

	getStintDriverName(stint, session := false) {
		local driver

		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				if stint is Integer
					stint := this.Connector.GetSessionStint(session, stint)

				driver := this.parseObject(this.Connector.GetDriver(this.Connector.GetStintDriver(stint)))

				return computeDriverName(driver.ForName, driver.SurName, driver.NickName)
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching stint data (Session: ") . session . translate(", Stint: ") . stint . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}

		return false
	}

	getDriverForName(force := false) {
		local driver

		if (force || (!this.iDriverForName && this.TeamServerActive)) {
			try {
				driver := this.parseObject(this.Connector.GetDriver(this.Driver))

				this.iDriverForName := driver.ForName
				this.iDriverSurName := driver.SurName
				this.iDriverNickName := driver.NickName

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Fetching Driver (Driver: ") . this.Driver . translate(", Name: ") . driver.ForName . A_Space . driver.SurName . translate(")"))
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching driver names (Driver: ") . this.Driver . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))

				this.keepAlive()
			}
		}

		return (this.iDriverForName ? this.iDriverForName : "")
	}

	getDriverSurName(force := false) {
		this.getDriverForName(force)

		return (this.iDriverSurName ? this.iDriverSurName : "")
	}

	getDriverNickName(force := false) {
		this.getDriverForName(force)

		return (this.iDriverNickName ? this.iDriverNickName : "")
	}

	startSession(simulator, car, track, duration) {
		if this.SessionActive
			this.leaveSession()

		if this.TeamServerActive && !this.SessionActive {
			if isDebug()
				showMessage("Starting team session: " . car . ", " . track)

			try {
				this.iLapData := {Telemetry: {}, Positions: {}}
				this.iSimulator := simulator

				this.Connector.StartSession(this.Session, duration, car, track)

				this.Connector.SetSessionValue(this.Session, "Simulator", simulator)
				this.Connector.SetSessionValue(this.Session, "Car", car)
				this.Connector.SetSessionValue(this.Session, "Track", track)
				this.Connector.SetSessionValue(this.Session, "Time", A_Now)

				this.iSessionActive := true

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Starting session (Session: ") . this.Session . translate(", Car: ") . car . translate(", Track: ") . track . translate(")"))
			}
			catch exception {
				this.iSessionActive := false

				logMessage(kLogCritical, translate("Error while starting session (Session: ") . this.Session . translate(", Car: ") . car . translate(", Track: ") . track . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))

				this.keepAlive()
			}
		}
	}

	finishSession() {
		if this.TeamServerActive {
			try {
				if this.DriverActive {
					if isDebug()
						showMessage("Finishing team session")

					this.Connector.FinishSession(this.Session)

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Finishing session (Session: ") . this.Session . translate(")"))
				}
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while finishing session (Session: ") . this.Session . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))

				this.keepAlive()
			}
		}

		this.iLapData := {Telemetry: {}, Positions: {}}
		this.iSessionActive := false
		this.iSimulator := false

		return false
	}

	joinSession(simulator, car, track, lapNumber, duration := 0) {
		if this.TeamServerActive {
			if !this.SessionActive {
				if (lapNumber = 1) {
					if isDebug()
						showMessage("Creating team session: " . car . ", " . track)

					this.startSession(simulator, car, track, duration)
				}
				else {
					if isDebug()
						showMessage("Joining team session: " . car . ", " . track)

					this.iLapData := {Telemetry: {}, Positions: {}}
					this.iSessionActive := true
					this.iSimulator := simulator
				}

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Starting stint (Session: ") . this.Session . translate(", Lap: ") . lapNumber . translate(")"))

				return this.addStint(lapNumber)
			}
		}
	}

	leaveSession() {
		if this.DriverActive {
			if isDebug()
				showMessage("Leaving team session")

			if (getLogLevel() <= kLogInfo)
				logMessage(kLogInfo, translate("Leaving team session (Session: ") . this.Session . translate(")"))

			this.finishSession()
		}
		else {
			this.iLapData := {Telemetry: {}, Positions: {}}
			this.iSessionActive := false
			this.iSimulator := false
		}
	}

	getCurrentDriver() {
		local driver

		if this.SessionActive {
			try {
				driver := this.Connector.GetSessionDriver(this.Session)

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Requesting current driver (Session: ") . this.Session . translate(", Driver: ") . driver . translate(")"))

				return driver
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while requesting current driver session (Session: ") . this.Session . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))

				return false
			}
		}
		else
			return false
	}

	getSessionValue(name, default := "__Undefined__") {
		local value

		if this.SessionActive {
			try {
				value := this.Connector.GetSessionValue(this.Session, name)

				if isDebug()
					showMessage("Fetching session value: " . name . " => " . value)

				if ((getLogLevel() <= kLogInfo) && value && (value != ""))
					logMessage(kLogInfo, translate("Fetching session data (Session: ") . this.Session . translate(", Name: ") . name . translate("), Value:`n`n") . value . "`n")

				return value
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching session data (Session: ") . this.Session . translate(", Name: ") . name . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}

		return ((default != kUndefined) ? default : false)
	}

	setSessionValue(name, value) {
		if this.SessionActive {
			try {
				if isDebug()
					showMessage("Saving session value: " . name . " => " . value)

				if (!value || (value == "")) {
					this.Connector.DeleteSessionValue(this.Session, name)

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Deleting session data (Session: ") . this.Session . translate(", Name: ") . name . translate(")"))
				}
				else {
					this.Connector.SetSessionValue(this.Session, name, value)

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Storing session data (Session: ") . this.Session . translate(", Name: ") . name . translate("), Value:`n`n") . value . "`n")
				}
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while storing session data (Session: ") . this.Session . translate(", Name: ") . name . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}
	}

	getStintValue(stint, name, session := false) {
		local value

		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				if stint is Integer
					value := this.Connector.GetSessionStintValue(session, stint, name)
				else
					value := this.Connector.GetStintValue(stint, name)

				if isDebug()
					showMessage("Fetching value for " . stint . ": " . name . " => " . value)

				if ((getLogLevel() <= kLogInfo) && value && (value != ""))
					logMessage(kLogInfo, translate("Fetching stint data (Session: ") . this.Session . translate(", Name: ") . name . translate("), Value:`n`n") . value . "`n")

				return value
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching stint data (Session: ") . session . translate(", Stint: ") . stint . translate(", Name: ") . name . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}

		return false
	}

	setStintValue(stint, name, value, session := false) {
		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				if isDebug()
					showMessage("Saving value for stint " . stint . ": " . name . " => " . value)

				if (!value || (value == "")) {
					if stint is Integer
						this.Connector.DeleteSessionStintValue(session, stint, name)
					else
						this.Connector.DeleteStintValue(stint, name, value)
				}
				else {
					if stint is Integer
						this.Connector.SetSessionStintValue(session, stint, name, value)
					else
						this.Connector.SetStintValue(stint, name, value)
				}

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Storing stint data (Session: ") . this.Session . translate(", Name: ") . name . translate("), Value:`n`n") . value . "`n")
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while storing stint data (Session: ") . session . translate(", Stint: ") . stint . translate(", Name: ") . name . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}
	}

	getStintSession(stint, session := false) {
		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				if stint is Integer
					stint := this.Connector.GetSessionStint(session, stint)

				return this.Connector.GetStintSession(stint)
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching stint data (Session: ") . session . translate(", Stint: ") . stint . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}

		return false
	}

	getCurrentLap(session := false) {
		local lap, lapNr

		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				lap := this.Connector.GetSessionLastLap(session)
				lapNr := this.parseObject(this.Connector.GetLap(lap)).Nr

				if (getLogLevel() <= kLogInfo)
					logMessage(kLogInfo, translate("Fetching lap number (Session: ") . this.Session . translate(", Lap: ") . lap . translate(", Number: ") . lapNr . translate(")"))

				return lapNr
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching lap data (Session: ") . session . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}

		return false
	}

	getLapStint(lap, session := false) {
		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				if lap is Integer
					lap := this.Connector.GetSessionLap(session, lap)

				return this.Connector.GetLapStint(lap)
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching lap data (Session: ") . session . translate(", Lap: ") . lap . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}

		return false
	}

	getLapValue(lap, name, session := false) {
		local value

		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				if lap is Integer
					value := this.Connector.GetSessionLapValue(session, lap, name)
				else
					value := this.Connector.GetLapValue(lap, name)

				if isDebug()
					showMessage("Fetching value for " . lap . ": " . name . " => " . value)

				if ((getLogLevel() <= kLogInfo) && value && (value != ""))
					logMessage(kLogInfo, translate("Fetching lap data (Session: ") . this.Session . translate(", Lap: ") . lap . translate(", Name: ") . name . translate("), Value:`n`n") . value . "`n")

				return value
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while fetching lap data (Session: ") . session . translate(", Lap: ") . lap . translate(", Name: ") . name . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}

		return false
	}

	setLapValue(lap, name, value, session := false) {
		if (!session && this.SessionActive)
			session := this.Session

		if session {
			try {
				if isDebug()
					showMessage("Saving value for lap " . lap . ": " . name . " => " . value)

				if (!value || (value == "")) {
					if lap is Integer
						this.Connector.DeleteSessionLapValue(session, lap, name)
					else
						this.Connector.DeleteLapValue(lap, name, value)

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Deleting lap data (Session: ") . this.Session . translate(", Lap: ") . lap . translate(", Name: ") . name . translate(")"))
				}
				else {
					if lap is Integer
						this.Connector.SetSessionLapValue(session, lap, name, value)
					else
						this.Connector.SetLapValue(lap, name, value)

					if (getLogLevel() <= kLogInfo)
						logMessage(kLogInfo, translate("Storing lap data (Session: ") . this.Session . translate(", Lap: ") . lap . translate(", Name: ") . name . translate("), Value:`n`n") . value . "`n")
				}
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while storing lap data (Session: ") . session . translate(", Lap: ") . lap . translate(", Name: ") . name . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}
	}

	addStint(lapNumber) {
		local stint

		if this.TeamServerActive {
			try {
				if !this.SessionActive
					throw Exception("Cannot add a stint to an inactive session...")

				if isDebug()
					showMessage("Updating stint in lap " . lapNumber . " for team session")

				stint := this.Connector.StartStint(this.Session, this.Driver, lapNumber)

				try {
					this.Connector.SetStintValue(stint, "Time", A_Now)
					this.Connector.SetStintValue(stint, "ID", this.ID)
				}
				catch exception {
					logError(exception)
				}

				return stint
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while starting stint (Session: ") . this.Session . translate(", Driver: ") . this.Driver . translate(", Lap: ") . lapNumber . translate("), Exception: ") . (IsObject(exception) ? exception.Message :  exception))

				this.keepAlive()
			}
		}
	}

	addLap(lapNumber, telemetryData, positionsData) {
		local driverForName, driverSurName, driverNickName, stint, simulator, car, track, lap

		if this.TeamServerActive {
			try {
				driverForName := getConfigurationValue(telemetryData, "Stint Data", "DriverForname", "John")
				driverSurName := getConfigurationValue(telemetryData, "Stint Data", "DriverSurname", "Doe")
				driverNickName := getConfigurationValue(telemetryData, "Stint Data", "DriverNickname", "JDO")

				if isDebug() {
					showMessage("Updating lap for team session: " . lapNumber)

					if ((this.DriverForName != driverForName) || (this.DriverSurName != driverSurName))
						throw Exception("Driver inconsistency detected...")
				}

				stint := false

				if !this.SessionActive {
					simulator := getConfigurationValue(telemetryData, "Session Data", "Simulator", "Unknown")
					car := getConfigurationValue(telemetryData, "Session Data", "Car", "Unknown")
					track := getConfigurationValue(telemetryData, "Session Data", "Track", "Unknown")

					new SessionDatabase().registerDriver(simulator, this.ID, computeDriverName(driverForName, driverSurName, driverNickName))

					stint := this.joinSession(simulator, car, track, lapNumber)
				}
				else if !this.DriverActive
					stint := this.addStint(lapNumber)
				else
					stint := this.Connector.GetSessionCurrentStint(this.Session)

				lap := this.Connector.CreateLap(stint, lapNumber)

				if (telemetryData && (telemetryData.Count() > 0) && !this.iLapData["Telemetry"].HasKey(lapNumber)) {
					telemetryData := printConfiguration(telemetryData)

					if isDebug()
						showMessage("Setting telemetry data for lap " . lapNumber . ": " . telemetryData)

					this.setLapValue(lapNumber, "Telemetry Data", telemetryData)

					this.iLapData["Telemetry"][lapNumber] := true
				}

				if (positionsData && (positionsData.Count() > 0) && !this.iLapData["Positions"].HasKey(lapNumber)) {
					positionsData := printConfiguration(positionsData)

					if isDebug()
						showMessage("Setting standings data for lap " . lapNumber . ": " . positionsData)

					this.setLapValue(lapNumber, "Positions Data", positionsData)

					this.iLapData["Positions"][lapNumber] := true
				}
			}
			catch exception {
				logMessage(kLogCritical, translate("Error while updating a lap (Session: ") . this.Session . translate(", Lap: ") . lapNumber . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))
			}
		}
	}

	keepAlive(start := false) {
		local nextPing := 10000

		static keepAliveTask := false

		if (this.Connector && this.ServerURL && this.ServerToken)
			try {
				if this.Connection
					this.Connector.KeepAlive(this.Connection)
				else {
					this.Connector.Initialize(this.ServerURL)

					this.Connector.Token := this.ServerToken

					if (this.Driver && this.Session)
						this.iConnection := this.Connector.Connect(this.ServerToken
																 , new SessionDatabase().ID
																 , computeDriverName(this.DriverForName[true]
																				   , this.DriverSurName[true]
																				   , this.DriverNickName[true])
																 , "Driver", this.Session)
				}

				nextPing := 60000
			}
			catch exception {
				Menu Tray, Tip, % string2Values(".", A_ScriptName)[1] . translate(" (Team: Error)")

				logMessage(kLogCritical, translate("Cannot connect to the Team Server (URL: ") . this.ServerURL . translate(", Token: ") . this.ServerToken . translate("), Exception: ") . (IsObject(exception) ? exception.Message : exception))

				this.iConnection := false
			}
		else
			this.iConnection := false

		if start {
			keepAliveTask := new PeriodicTask(ObjBindMethod(this, "keepAlive"), nextPing, kLowPriority)

			keepAliveTask.start()
		}
		else if keepAliveTask
			keepAliveTask.Sleep := nextPing

		return false
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeTeamServerPlugin() {
	local controller := SimulatorController.Instance

	new TeamServerPlugin(controller, kTeamServerPlugin, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                        Controller Action Section                        ;;;
;;;-------------------------------------------------------------------------;;;

enableTeamServer() {
	local controller := SimulatorController.Instance
	local plugin := controller.findPlugin(kTeamServerPlugin)

	protectionOn()

	try {
		if (plugin && controller.isActive(plugin))
			plugin.enableTeamServer()
	}
	finally {
		protectionOff()
	}
}

disableTeamServer() {
	local controller := SimulatorController.Instance
	local plugin := controller.findPlugin(kTeamServerPlugin)

	protectionOn()

	try {
		if (plugin && controller.isActive(plugin))
			plugin.disableTeamServer()
	}
	finally {
		protectionOff()
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeTeamServerPlugin()
