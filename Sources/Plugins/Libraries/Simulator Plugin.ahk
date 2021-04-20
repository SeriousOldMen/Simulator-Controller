;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Simulator Plugin                ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kSessionFinished = 0
global kSessionPaused = -1
global kSessionOther = 1
global kSessionPractice = 2
global kSessionQualification = 3
global kSessionRace = 4

global kPitstopMode = "Pitstop"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kSessionStates = [kSessionOther, kSessionPractice, kSessionQualification, kSessionRace]
global kSessionStateNames = ["Other", "Practice", "Qualification", "Race"]


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variable Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global vRunningSimulator = false


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;
	
class PitstopMode extends ControllerMode {
	Mode[] {
		Get {
			return kPitstopMode
		}
	}

	activate() {
		base.activate()
		
		this.updateActions(this.Plugin.SessionState)
	}
	
	updateActions(sessionState) {
		this.updatePitstopActions(sessionState)
		this.updateRaceEngineerActions(sessionState)
	}			
		
	updatePitstopActions(sessionState) {	
		for ignore, theAction in this.Actions
			if isInstance(theAction, PitstopAction)
				if ((sessionState != kSessionFinished) && (sessionState != kSessionPaused)) {
					theAction.Function.enable(kAllTrigger)
					theAction.Function.setText(theAction.Label)
				}
				else {
					theAction.Function.disable(kAllTrigger)
					theAction.Function.setText(theAction.Label, "Gray")
				}
	}
		
	updateRaceEngineerActions(sessionState) {
		if (!this.Plugin.RaceEngineer || !this.Plugin.RaceEngineer.RaceEngineer)
			sessionState := kSessionFinished
		
		for ignore, theAction in this.Actions
			if isInstance(theAction, RaceEngineerAction)
				if (sessionState == kSessionRace) {
					theAction.Function.enable(kAllTrigger)
					theAction.Function.setText(theAction.Label)
				}
				else {
					theAction.Function.disable(kAllTrigger)
					theAction.Function.setText(theAction.Label, "Gray")
				}
	}
}

class PitstopAction extends ControllerAction {
	iPlugin := false
	iPitstopOption := false
	iSteps := 1
	
	Plugin[] {
		Get {
			return this.iPlugin
		}
	}
	
	Option[] {
		Get {
			return this.iPitstopOption
		}
	}
	
	Steps[] {
		Get {
			return this.iSteps
		}
	}
	
	__New(plugin, function, label, pitstopOption, steps := 1, moreArguments*) {
		this.iPlugin := plugin
		this.iPitstopOption := pitstopOption
		this.iSteps := steps
		
		if (moreArguments.Length() > 0)
			Throw "Unsupported arguments (" . values2String(", ", moreArguments*) . ") detected in PitstopAction.__New"
		
		base.__New(function, label)
	}
	
	fireAction(function, trigger) {
		local plugin := this.Plugin
		
		return (plugin.requirePitstopMFD() && plugin.selectPitstopOption(this.iPitstopOption))
	}
}

class PitstopChangeAction extends PitstopAction {
	iDirection := false
	
	__New(plugin, function, label, pitstopOption, direction, moreArguments*) {
		this.iDirection := direction
		
		base.__New(plugin, function, label, pitstopOption, moreArguments*)
	}
	
	fireAction(function, trigger) {
		if base.fireAction(function, trigger)
			this.Plugin.changePitstopOption(this.Option, this.iDirection, this.Steps)
	}
}

class PitstopSelectAction extends PitstopChangeAction {
	__New(plugin, function, label, pitstopOption, moreArguments*) {
		base.__New(plugin, function, label, pitstopOption, "Increase", moreArguments*)
	}
}

class PitstopToggleAction extends PitstopAction {		
	fireAction(function, trigger) {
		if base.fireAction(function, trigger)
			if ((trigger == "On") || (trigger == "Increase") || (trigger == "Push") || (trigger == "Call"))
				this.Plugin.changePitstopOption(this.Option, "Increase", this.Steps)
			else
				this.Plugin.changePitstopOption(this.Option, "Decrease", this.Steps)
	}
}

class SimulatorPlugin extends ControllerPlugin {
	iSimulator := false
	iSessionState := kSessionFinished
	
	Code[] {
		Get {
			return this.Plugin
		}
	}
	
	Simulator[] {
		Get {
			return this.iSimulator
		}
	}
	
	SessionState[asText := false] {
		Get {
			if asText {
				sessionState := this.iSessionState
				
				if (sessionState >= kSessionOther)
					return kSessionStateNames[sessionState]
				else
					return ((sessionState == kSessionFinished) ? "Finished" : "Paused")
			}
			else
				return this.iSessionState
		}
	}
	
	SessionStates[asText := false] {
		Get {
			return (asText ? kSessionStateNames : kSessionStates)
		}
	}
	
	__New(controller, name, simulator, configuration := false) {
		this.iSimulator := new Application(simulator, SimulatorController.Instance.Configuration)
		
		base.__New(controller, name, configuration)
		
		for ignore, theAction in string2Values(",", this.getArgumentValue("pitstopCommands", "")) {
			arguments := string2Values(A_Space, theAction)
		
			theAction := arguments[1]
			
			if ((theAction = "PitstopPlan") || (theAction = "PitstopPrepare"))
				this.createRaceEngineerAction(controller, arguments*)
			else
				this.createPitstopAction(controller, arguments*)
		}
	
		controller.registerPlugin(this)
	}
	
	createPitstopAction(controller, action, increaseFunction, moreArguments*) {
		local function
		
		this.getPitstopActions(actions, selectActions)
		
		if actions.HasKey(action) {
			decreaseFunction := false
			
			if (moreArguments.Length() > 0) {
				decreaseFunction := moreArguments[1]
				
				if (controller.findFunction(decreaseFunction) != false)
					moreArguments.RemoveAt(1)
				else
					decreaseFunction := false
			}
			
			function := controller.findFunction(increaseFunction)
			
			mode := this.findMode(kPitstopMode)
			
			if (mode == false)
				mode := new PitstopMode(this)
			
			if !decreaseFunction {
				if (function != false)
					if (inList(selectActions, action))
						mode.registerAction(new PitstopSelectAction(this, function, this.getLabel(ConfigurationItem.descriptor(action, "Toggle"), action), actions[action], moreArguments*))
					else
						mode.registerAction(new PitstopToggleAction(this, function, this.getLabel(ConfigurationItem.descriptor(action, "Toggle"), action), actions[action], moreArguments*))
				else
					this.logFunctionNotFound(increaseFunction)
			}
			else {
				if (function != false)
					mode.registerAction(new PitstopChangeAction(this, function, this.getLabel(ConfigurationItem.descriptor(action, "Increase"), action), actions[action], "Increase", moreArguments*))
				else
					this.logFunctionNotFound(increaseFunction)
					
				function := controller.findFunction(decreaseFunction)
				
				if (function != false)
					mode.registerAction(new PitstopChangeAction(this, function, this.getLabel(ConfigurationItem.descriptor(action, "Decrease"), action), actions[action], "Decrease", moreArguments*))
				else
					this.logFunctionNotFound(decreaseFunction)
			}
		}
		else
			logMessage(kLogWarn, translate("Pitstop action ") . action . translate(" not found in plugin ") . translate(this.Plugin) . translate(" - please check the configuration"))
	}
	
	createRaceEngineerAction(controller, action, actionFunction) {
		logMessage(kLogWarn, translate("Action """) . action . translate(""" not found in plugin ") . translate(this.Plugin) . translate(" - please check the configuration"))
	}
	
	getPitstopActions(ByRef allActions, ByRef selectActions) {
		allActions := {}
		selectActions := []
	}
	
	runningSimulator() {
		return (this.Simulator.isRunning() ? this.Simulator.Application : false)
	}
	
	simulatorStartup(simulator) {
		base.simulatorStartup(simulator)
		
		if (simulator = this.Simulator.Application) {
			this.updateSessionState(kSessionFinished)
			
			vRunningSimulator := this
		}
	}
	
	simulatorShutdown(simulator) {
		base.simulatorShutdown(simulator)
		
		if (simulator = this.Simulator.Application) {
			this.updateSessionState(kSessionFinished)
			
			if (vRunningSimulator == this)
				vRunningSimulator := false
		}
	}
	
	updateSessionState(sessionState) {
		if ((sessionState != this.SessionState) && (sessionState != kSessionPaused)) { 
			this.iSessionState := sessionState
			
			if (sessionState == kSessionFinished)
				this.Controller.setModes()
			else
				this.Controller.setModes(this.Simulator.Application, ["Other", "Practice", "Qualification", "Race"][sessionState])
		}
		
		mode := this.findMode(kPitstopMode)
		
		if (mode && inList(this.Controller.ActiveModes, mode))
			mode.updateActions(sessionState)
	}
	
	updatePitstopOption(option, action, steps := 1) {
		if (this.requirePitstopMFD() && this.selectPitstopOption(option))
			this.changePitstopOption(option, action, steps)
	}
	
	selectPitstopOption(option) {
		Throw "Virtual method SimulatorPlugin.selectPitstopOption must be implemented in a subclass..."
	}
	
	changePitstopOption(option, action, steps := 1) {
		Throw "Virtual method SimulatorPlugin.changePitstopOption must be implemented in a subclass..."
	}
	
	openPitstopMFD() {
		Throw "Virtual method SimulatorPlugin.openPitstopMFD must be implemented in a subclass..."
	}
	
	closePitstopMFD() {
		Throw "Virtual method SimulatorPlugin.closePitstopMFD must be implemented in a subclass..."
	}
	
	requirePitstopMFD() {
		return false
	}
}

class RaceEngineerAction extends ControllerAction {
	iPlugin := false
	iAction := false
	
	Plugin[] {
		Get {
			return this.iPlugin
		}
	}
	
	Action[] {
		Get {
			return this.iAction
		}
	}
	
	__New(pluginOrMode, function, label, action) {
		this.iPlugin := (isInstance(pluginOrMode, ControllerMode) ? pluginOrMode.Plugin : pluginOrMode)
		this.iAction := action
		
		base.__New(function, label)
	}
	
	fireAction(function, trigger) {
		local plugin := this.Plugin
		
		if plugin.RaceEngineer
			switch this.Action {
				case "PitstopPlan":
					plugin.planPitstop()
				case "PitstopPrepare":
					plugin.preparePitstop()
				default:
					Throw "Invalid action """ . this.Action . """ detected in RaceEngineerAction.fireAction...."
			}
	}
}

class RaceEngineerSimulatorPlugin extends SimulatorPlugin {
	iRaceEngineer := false
	
	RaceEngineer[] {
		Get {
			return this.iRaceEngineer
		}
	}
	
	__New(controller, name, simulator, configuration := false) {
		base.__New(controller, name, simulator, configuration)
		
		for ignore, theAction in string2Values(",", this.getArgumentValue("pitstopCommands", "")) {
			arguments := string2Values(A_Space, theAction)
		
			theAction := arguments[1]
			
			if ((theAction = "PitstopPlan") || (theAction = "PitstopPrepare"))
				this.createRaceEngineerAction(controller, arguments*)
			else
				this.createPitstopAction(controller, arguments*)
		}
	}
	
	createRaceEngineerAction(controller, action, actionFunction) {
		local function := controller.findFunction(actionFunction)
			
		mode := this.findMode(kPitstopMode)
		
		if (mode == false)
			mode := new PitstopMode(this)
		
		if (function != false) {
			if ((action = "PitstopPlan") || (action = "PitstopPrepare"))
				mode.registerAction(new RaceEngineerAction(this, function, this.getLabel(ConfigurationItem.descriptor(action, "Activate"), action), action))
			else
				logMessage(kLogWarn, translate("Action """) . action . translate(""" not found in plugin ") . translate(this.Plugin) . translate(" - please check the configuration"))
		}
		else
			this.logFunctionNotFound(actionFunction)
	}
	
	simulatorStartup(simulator) {
		base.simulatorStartup(simulator)
		
		if (simulator = this.Simulator.Application) {
			raceEngineer := SimulatorController.Instance.findPlugin(kRaceEngineerPlugin)
			
			if (raceEngineer && raceEngineer.isActive()) {
				raceEngineer.startSimulation(this)
				
				this.iRaceEngineer := raceEngineer
			}
		}
	}
	
	simulatorShutdown(simulator) {
		base.simulatorShutdown(simulator)
		
		if (simulator = this.Simulator.Application) {
			raceEngineer := SimulatorController.Instance.findPlugin(kRaceEngineerPlugin)
			
			if (raceEngineer && raceEngineer.isActive()) {
				raceEngineer.stopSimulation(this)
				
				this.iRaceEngineer := false
			}
		}
	}
	
	supportsPitstop() {
		return false
	}
	
	planPitstop() {
		if this.RaceEngineer
			this.RaceEngineer.planPitstop()
	}
	
	preparePitstop(lap := false) {
		if this.RaceEngineer
			this.RaceEngineer.preparePitstop(lap)
	}
	
	pitstopPlanned(pitstopNumber) {
	}
	
	pitstopPrepared(pitstopNumber) {
	}
	
	pitstopFinished(pitstopNumber) {
	}
	
	startPitstopSetup(pitstopNumber) {
	}

	finishPitstopSetup(pitstopNumber) {
	}

	setPitstopRefuelAmount(pitstopNumber, litres) {
	}
	
	setPitstopTyreSet(pitstopNumber, compound, compoundColor := false, set := false) {
	}

	setPitstopTyrePressures(pitstopNumber, pressureFL, pressureFR, pressureRL, pressureRR) {
	}

	requestPitstopRepairs(pitstopNumber, repairSuspension, repairBodywork) {
	}
	
	updateSimulatorData(data) {
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                    Private Function Declaration Section                 ;;;
;;;-------------------------------------------------------------------------;;;

getCurrentSimulatorPlugin(option := false) {
	if vRunningSimulator {
		if option {
			actions := false
			ignore := false
			
			vRunningSimulator.getPitstopActions(actions, ignore)
			
			for ignore, candidate in actions
				if (candidate = option)
					return vRunningSimulator
				
			return false
		}
		else
			return vRunningSimulator
	}
	else
		return false
}


;;;-------------------------------------------------------------------------;;;
;;;                         Controller Action Section                       ;;;
;;;-------------------------------------------------------------------------;;;

openPitstopMFD() {
	local plugin := getCurrentSimulatorPlugin()
	
	if plugin {
		protectionOn()
		
		try {
			plugin.openPitstopMFD()
		}
		finally {
			protectionOff()
		}
	}
}

closePitstopMFD() {
	local plugin := getCurrentSimulatorPlugin()
	
	if plugin {
		protectionOn()
		
		try {
			plugin.closePitstopMFD()
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopStrategy(selection, steps := 1) {
	local plugin
	
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported strategy selection """) . selection . translate(""" detected in changePitstopStrategy - please check the configuration"))
	
	plugin := getCurrentSimulatorPlugin("Strategy")
	
	if plugin {
		protectionOn()
	
		try {
			plugin.updatePitstopOption("Strategy", (selection = "Next") ? "Increase" : "Decrease", steps)
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopFuelAmount(direction, litres := 5) {
	local plugin := getCurrentSimulatorPlugin("Refuel")
	
	if plugin {
		protectionOn()
	
		try {
			plugin.updatePitstopOption("Refuel", direction, litres)
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopTyreCompound(selection) {
	local plugin
	
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported tyre compound selection """) . selection . translate(""" detected in changePitstopTyreCompound - please check the configuration"))
	
	plugin := getCurrentSimulatorPlugin("Tyre Compound")
	
	if plugin {
		protectionOn()
		
		try {
			plugin.updatePitstopOption("Tyre Compound", (selection = "Next") ? "Increase" : "Decrease")
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopTyreSet(selection, steps := 1) {
	local plugin
	
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported tyre set selection """) . selection . translate(""" detected in changePitstopTyreSet - please check the configuration"))
	
	plugin := getCurrentSimulatorPlugin("Tyre Set")
	
	if plugin {
		protectionOn()
		
		try {
			plugin.updatePitstopOption("Tyre Set", (selection = "Next") ? "Increase" : "Decrease", steps)
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopTyrePressure(tyre, direction, increments := 1) {
	local plugin
	
	if !inList(["All Around", "Front Left", "Front Right", "Rear Left", "Rear Right"], tyre)
		logMessage(kLogWarn, translate("Unsupported tyre position """) . tyre . translate(""" detected in changePitstopTyrePressure - please check the configuration"))
		
	if !inList(["Increase", "Decrease"], direction)
		logMessage(kLogWarn, translate("Unsupported pressure change """) . direction . translate(""" detected in changePitstopTyrePressure - please check the configuration"))
	
	plugin := getCurrentSimulatorPlugin(tyre)
	
	if plugin {
		protectionOn()
		
		try {
			plugin.updatePitstopOption(tyre, direction, increments)
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopBrakeType(brake, selection) {
	local plugin
	
	if !inList(["Front Brake", "Rear Brake"], selection)
		logMessage(kLogWarn, translate("Unsupported brake unit """) . brake . translate(""" detected in changePitstopBrakeType - please check the configuration"))
	
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported brake selection """) . selection . translate(""" detected in changePitstopBrakeType - please check the configuration"))
	
	plugin := getCurrentSimulatorPlugin(brake)
	
	if plugin {
		protectionOn()
	
		try {
			plugin.updatePitstopOption(brake, (selection = "Next") ? "Increase" : "Decrease")
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopDriver(selection) {
	local plugin
	
	if !inList(["Next", "Previous"], selection)
		logMessage(kLogWarn, translate("Unsupported driver selection """) . selection . translate(""" detected in changePitstopDriver - please check the configuration"))
	
	plugin := getCurrentSimulatorPlugin("Driver")
	
	if plugin {
		protectionOn()
	
		try {
			plugin.updatePitstopOption("Driver", (selection = "Next") ? "Increase" : "Decrease")
		}
		finally {
			protectionOff()
		}
	}
}

changePitstopOption(option, selection := "Next") {
	local plugin
	
	if !inList(["Next", "Previous", "Increase", "Decrease"], selection)
		logMessage(kLogWarn, translate("Unsupported option selection """) . selection . translate(""" detected in changePitstopOption - please check the configuration"))
	
	plugin := getCurrentSimulatorPlugin(option)
	
	if plugin {
		protectionOn()
	
		try {
			plugin.updatePitstopOption(option, (selection = "Next") ? "Increase" : "Decrease")
		}
		finally {
			protectionOff()
		}
	}
}