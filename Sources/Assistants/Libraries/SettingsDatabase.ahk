;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Settings Database               ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Local Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\Database.ahk
#Include ..\Assistants\Libraries\SessionDatabase.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kSettingsDataSchemas := {"Settings": ["Owner", "Car", "Track", "Weather", "Section", "Key", "Value"]}


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class SettingsDatabase extends SessionDatabase {
	iLastSimulator := false
	iUserDatabase := false
	iCommunityDatabase := false
	
	iID := false
	
	ID[] {
		Get {
			return this.iID
		}
	}
	
	__New(controllerConfiguration := false) {
		base.__New(controllerConfiguration)
		
		FileRead identifier, % kUserConfigDirectory . "ID"
		
		this.iID := identifier
	}
	
	getSettingsDatabase(simulator, type := "User") {
		if (this.iLastSimulator != simulator) {
			this.iLastSimulator := simulator
			
			this.iUserDatabase := new Database(kDatabaseDirectory . "User\" . this.getSimulatorCode(simulator) . "\", kSettingsDataSchemas)
			this.iCommunityDatabase := new Database(kDatabaseDirectory . "Community\" . this.getSimulatorCode(simulator) . "\", kSettingsDataSchemas)
		}
		
		return ((type = "User") ? this.iUserDatabase : this.iCommunityDatabase)
	}
	
	querySettings(simulator, car, track, weather, ByRef userSettings, ByRef communitySettings) {
		local database
		
		id := this.ID
		
		if userSettings {
			result := {}
			
			readSettings(this, simulator, result, id, true, false, "*", "*", "*")
			readSettings(this, simulator, result, id, true, false, car, "*", "*")
			readSettings(this, simulator, result, id, true, false, "*", track, "*")
			readSettings(this, simulator, result, id, true, false, "*", "*", weather)
			readSettings(this, simulator, result, id, true, false, car, track, "*")
			readSettings(this, simulator, result, id, true, false, car, "*", weather)
			readSettings(this, simulator, result, id, true, false, "*", track, weather)
			readSettings(this, simulator, result, id, true, false, car, track, weather)
			
			userSettings := []
			
			for ignore, setting in result
				userSettings.Push(setting)
		}
		
		if communitySettings {
			result := {}
			
			readSettings(this, simulator, result, id, false, true, "*", "*", "*")
			readSettings(this, simulator, result, id, false, true, car, "*", "*")
			readSettings(this, simulator, result, id, false, true, "*", track, "*")
			readSettings(this, simulator, result, id, false, true, "*", "*", weather)
			readSettings(this, simulator, result, id, false, true, car, track, "*")
			readSettings(this, simulator, result, id, false, true, car, "*", weather)
			readSettings(this, simulator, result, id, false, true, "*", track, weather)
			readSettings(this, simulator, result, id, false, true, car, track, weather)
			
			communitySettings := []
			
			for ignore, setting in result
				communitySettings.Push(setting)
		}
	}
	
	doSettings(simulator, car, track, weather, function, userSettings := true, communitySettings := true) {
		this.querySettings(simulator, car, track, weather, userSettings, communitySettings)
		
		if userSettings
			for ignore, setting in userSettings
				%function%(simulator, car, track, weather, setting)
		
		if communitySettings
			for ignore, setting in communitySettings
				%function%(simulator, car, track, weather, setting)
	}
	
	loadSettings(simulator, car, track, weather, community := "__Undefined__") {
		if (community = kUndefined)
			community := this.UseCommunity
		
		settings := newConfiguration()
		
		id := this.ID
		
		loadSettings(this, simulator, settings, id, true, community, "*", "*", "*")
		loadSettings(this, simulator, settings, id, true, community, car, "*", "*")
		loadSettings(this, simulator, settings, id, true, community, "*", track, "*")
		loadSettings(this, simulator, settings, id, true, community, "*", "*", weather)
		loadSettings(this, simulator, settings, id, true, community, car, track, "*")
		loadSettings(this, simulator, settings, id, true, community, car, "*", weather)
		loadSettings(this, simulator, settings, id, true, community, "*", track, weather)
		loadSettings(this, simulator, settings, id, true, community, car, track, weather)
		
		return settings
	}
	
	readSettings(simulator, car, track, weather, inherited := true, community := "__Undefined__") {
		if (community = kUndefined)
			community := this.UseCommunity
		
		result := {}
		
		id := this.ID
		
		if inherited {
			readSettings(this, simulator, result, id, true, community, "*", "*", "*")
			readSettings(this, simulator, result, id, true, community, car, "*", "*")
			readSettings(this, simulator, result, id, true, community, "*", track, "*")
			readSettings(this, simulator, result, id, true, community, "*", "*", weather)
			readSettings(this, simulator, result, id, true, community, car, track, "*")
			readSettings(this, simulator, result, id, true, community, car, "*", weather)
			readSettings(this, simulator, result, id, true, community, "*", track, weather)
		}
		
		readSettings(this, simulator, result, id, true, community, car, track, weather)

		settings := []
		
		for ignore, setting in result
			settings.Push(setting)
			
		return settings
	}
	
	getSettingValue(simulator, car, track, weather, section, key, default := false) {
		rows := this.getSettingsDatabase(simulator, "User").query("Settings", {Where: {Owner: this.ID
																					 , Car: car, Track: track, Weather: weather
																					 , Section: section, Key: key}})
		
		return ((rows.Length() > 0) ? rows[1].Value : default)
	}
	
	setSettingValue(simulator, car, track, weather, section, key, value) {
		local database := this.getSettingsDatabase(simulator, "User")
		
		database.remove("Settings", {Owner: this.ID, Car: car, Track: track, Weather: weather, Section: section, Key: key}
								  , Func("always").Bind(true))
		
		database.add("Settings", {Owner: this.ID, Car: car, Track: track, Weather: weather, Section: section, Key: key, Value: value})
		
		database.flush()
	}
	
	removeSettingValue(simulator, car, track, weather, section, key) {
		this.getSettingsDatabase(simulator, "User").remove("Settings", {Owner: this.ID
																	  , Car: car, Track: track, Weather: weather
																	  , Section: section, Key: key}
																	 , Func("always").Bind(true), true)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                    Private Function Declaration Section                 ;;;
;;;-------------------------------------------------------------------------;;;

constraintSettings(constraints, row) {
	for column, value in constraints
		if (row[column] != value)
			return false
		
	return true
}

always(value, ignore*) {
	return value
}

readSettings(database, simulator, settings, owner, user, community, car, track, weather) {
	result := []
	
	if community
		for ignore, row in database.getSettingsDatabase(simulator, "Community").query("Settings"
																					, {Where: {Car: car, Track: track, Weather: weather}})
			if (row.Owner != owner)
				result.Push(row)

	if user
		for ignore, row in database.getSettingsDatabase(simulator, "User").query("Settings", {Where: {Car: car, Track: track
																									, Weather: weather, Owner: owner}})
			result.Push(row)
	
	filtered := []
	visited := {}
	
	for ignore, row in reverse(result)
		if !visited.HasKey(row.Section . "." . row.Key) {
			visited[row.Section . "." . row.Key] := true
			
			filtered.Push(row)
		}
	
	for ignore, row in reverse(filtered)
		settings[row.Section . "." . row.Key] := row
}

loadSettings(database, simulator, settings, owner, user, community, car, track, weather) {
	values := {}
	
	readSettings(database, simulator, values, owner, user, community, car, track, weather)
	
	for ignore, setting in values
		setConfigurationValue(settings, setting.Section, setting.Key, setting.Value)
}