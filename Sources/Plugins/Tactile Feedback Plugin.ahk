;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Tactile Feedback Plugin         ;;;
;;;                                         (Powered by SimHub)             ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    Creative Commons - BY-NC-SA                               ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kVibrationIntensityIncrement = 5

global kSimHub

						
;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kTactileFeedbackPlugin = "Tactile Feedback"

global kPedalVibrationMode = "Pedal Vibration"
global kChassisVibrationMode = "Chassis Vibration"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;
	
class TactileFeedbackPlugin extends ControllerPlugin {
	iVibrationApplication := false
	iPedalVibrationMode := false
	iChassisVibrationMode := false

	class PedalVibrationMode extends ControllerMode {
		Mode[] {
			Get {
				return kPedalVibrationMode
			}
		}
		
		isActive() {
			return (base.isActive() && this.Plugin.Application.isRunning())
		}
	}

	class ChassisVibrationMode extends ControllerMode {
		Mode[] {
			Get {
				return kChassisVibrationMode
			}
		}
		
		isActive() {
			return (base.isActive() && this.Plugin.Application.isRunning())
		}
	}
	
	class SimHub1WayAction extends ControllerAction {
		iCommand := false
		
		__New(function, label, command) {
			this.iCommand := command
			
			base.__New(function, label)
		}
		
		fireAction(function, trigger) {
			callSimHub(this.iCommand)
		}
	}

	class SimHub2WayAction extends ControllerAction {
		iUpCommand := false
		iDownCommand := false
		
		__New(function, label, upCommand, downCommand) {
			this.iUpCommand := upCommand
			this.iDownCommand := downCommand
			
			base.__New(function, label)
		}
		
		fireAction(function, trigger) {
			callSimHub(((trigger = "On") || (trigger = "Increase") || (trigger == "Push")) ? this.iUpCommand : this.iDownCommand)
		}
	}

	class FXToggleAction extends TactileFeedbackPlugin.SimHub1WayAction {
		iIsActive := true
		
		Active[] {
			Get {
				return this.iIsActive
			}
		}
		
		__New(function, label, command, initialActive) {
			this.iIsActive := initialActive
			
			base.__New(function, label, command)
		}
		
		fireAction(function, trigger) {
			local plugin := this.Controller.findPlugin(kTactileFeedbackPlugin)
			
			if !plugin.Application.isRunning() {
				plugin.requireSimHub()
			
				return
			}
			
			if (this.iIsActive && ((trigger = "Off") || (trigger == "Push"))) {
				base.fireAction(function, trigger)
				this.iIsActive := false
				
				trayMessage(translate(this.Label), translate("State: Off"))
			
				function.setText(translate(this.Label), "Gray")
			}
			else if (!this.iIsActive && ((trigger = "On") || (trigger == "Push"))) {
				base.fireAction(function, trigger)
				this.iIsActive := true
				
				trayMessage(translate(this.Label), translate("State: On"))
			
				function.setText(translate(this.Label), "Green")
			}
		}
	}

	class FXChangeAction extends TactileFeedbackPlugin.SimHub2WayAction {
		iEffect := ""
		iUpChange := ""
		iDownChange := false
		
		__New(function, label, effect, upChange, downChange := false) {
			this.iEffect := effect
			this.iUpChange := upChange
			this.iDownChange := downChange
			
			StringLower upChange, upChange
			
			upChange := upChange . effect . "Vibration"
			
			if downChange {
				StringLower downChange, downChange
				
				downChange := downChange . effect . "Vibration"
			}
			
			base.__New(function, label, upChange, downChange)
		}
		
		fireAction(function, trigger) {
			base.fireAction(function, trigger)
		
			change := (((trigger = "On") || (trigger = "Increase") || (trigger == "Push")) ? this.iUpChange : this.iDownChange)
				
			StringUpper change, change, T
		
			trayMessage(translate(this.iEffect), translate(change) . translate(" Vibration"))
			
			this.Function.setText(((change = kIncrease) ? "+ " : "- ") . kVibrationIntensityIncrement . "%")
		
			Sleep 500
			
			this.Function.setText(translate(this.Label))
		}
	}
	
	Application[] {
		Get {
			return this.iVibrationApplication
		}
	}
	
	__New(controller, name, configuration := false) {
		base.__New(controller, name, configuration)
		
		this.iVibrationApplication := new Application(kTactileFeedbackPlugin, configuration)
		
		pedalVibrationArguments := string2Values(A_Space, this.getArgumentValue("pedalVibration", ""))
		frontChassisVibrationArguments := string2Values(A_Space, this.getArgumentValue("frontChassisVibration", ""))
		rearChassisVibrationArguments := string2Values(A_Space, this.getArgumentValue("rearChassisVibration", ""))
		
		this.createPluginToggleAction("Pedal Vibration", "togglePedalVibration", pedalVibrationArguments[2], (pedalVibrationArguments[1] = "On"))
		this.createPluginToggleAction("Front Vibration", "toggleFrontChassisVibration", frontChassisVibrationArguments[2], (frontChassisVibrationArguments[1] = "On"))
		this.createPluginToggleAction("Rear Vibration", "toggleRearChassisVibration", rearChassisVibrationArguments[2], (rearChassisVibrationArguments[1] = "On"))
		
		pedalMode := new this.PedalVibrationMode(this)
		
		this.iPedalVibrationMode := pedalMode
		
		this.createPluginDialAction(pedalMode, "Pedal Vibration", "Pedal", pedalVibrationArguments[3])
		
		for ignore, effect in string2Values(",", this.getArgumentValue("pedalEffects", ""))
			this.createModeAction(controller, pedalMode, string2Values(A_Space, effect)*)
		
		chassisMode := new this.ChassisVibrationMode(this)
		
		this.iChassisVibrationMode := chassisMode
		
		this.createPluginDialAction(chassisMode, "Front Vibration", "FrontChassis", frontChassisVibrationArguments[3])
		this.createPluginDialAction(chassisMode, "Rear Vibration", "RearChassis", rearChassisVibrationArguments[3])
	
		for ignore, effect in string2Values(",", this.getArgumentValue("chassisEffects", ""))
			this.createModeAction(controller, chassisMode, string2Values(A_Space, effect)*)
		
		controller.registerPlugin(this)
	}

	createPluginToggleAction(label, command, descriptor, initialState) {
		local function
		
		if (descriptor != false) {
			function := this.Controller.findFunction(descriptor)
			
			if (function != false)
				this.registerAction(new this.FXToggleAction(function, label, command, initialState))
			else
				this.logFunctionNotFound(descriptor)
		}
	}

	createPluginDialAction(mode, label, effect, descriptor) {
		local function := this.Controller.findFunction(descriptor)
		
		if (function != false)
			mode.registerAction(new this.FXChangeAction(function, label, effect, kIncrease, kDecrease))
		else
			this.logFunctionNotFound(descriptor)
	}
	
	createModeAction(controller, mode, effect, increaseFunction, decreaseFunction := false) {
		local function := this.Controller.findFunction(increaseFunction)
		
		if !decreaseFunction {
			if (function != false)
				mode.registerAction(new this.FXChangeAction(function, this.getLabel(ConfigurationItem.descriptor(effect, "Toggle"), effect), effect, kIncrease, kDecrease))
			else
				this.logFunctionNotFound(increaseFunction)
		}
		else {
			if (function != false)
				mode.registerAction(new this.FXChangeAction(function, this.getLabel(ConfigurationItem.descriptor(effect, "Increase"), effect), effect, kIncrease))
			else
				this.logFunctionNotFound(increaseFunction)
				
			function := this.Controller.findFunction(decreaseFunction)
			
			if (function != false)
				mode.registerAction(new this.FXChangeAction(function, this.getLabel(ConfigurationItem.descriptor(effect, "Decrease"), effect), effect, kDecrease))
			else
				this.logFunctionNotFound(decreaseFunction)
		}
	}
	
	getLabel(descriptor, default := false) {
		label := translate(base.getLabel(descriptor, default))
		
		return StrReplace(StrReplace(label, "Increase", translate("Increase")), "Decrease", translate("Decrease"))
	}
	
	activate() {
		base.activate()
	
		isRunning := this.Application.isRunning()
		
		for ignore, action in this.Actions
			action.Function.setText(translate(action.Label), isRunning ? (action.Active ? "Green" : "Black") : "Olive")
		
		SetTimer updateVibrationState, 50
	}
	
	deactivate() {
		SetTimer updateVibrationState, Off
		
		base.deactivate()
	}
	
	requireSimHub() {
		if !this.Application.isRunning() {
			this.Application.startup()
			
			Loop {
				Sleep 500
			} until this.Application.isRunning()
			
			this.deactivate()
			this.activate()
		}
	}
	
	updateVibrationState() {
		static isRunning := "__Undefined__"
		
		if (isRunning == kUndefined)
			isRunning := this.Application.isRunning()
		
		if (isRunning != this.Application.isRunning()) {
			protectionOn()
			
			try {
				if ((this.Controller.ActiveMode == this.findMode(kPedalVibrationMode)) || (this.Controller.ActiveMode == this.findMode(kChassisVibrationMode)))
					this.Controller.rotateMode()
						
				this.deactivate()
				this.activate()
		
				isRunning := !isRunning
			}
			finally {
				protectionOff()
			}
		}
				
		setTimer updateVibrationState, % isRunning ? 5000 : 1000
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

updateVibrationState() {
	static plugin := false
	
	if !plugin
		plugin := SimulatorController.Instance.findPlugin(kTactileFeedbackPlugin)
		
	plugin.updateVibrationState()
}

startSimHub() {
	simHub := new Application("Tactile Feedback", SimulatorController.Instance.Configuration)
	
	return (simHub.isRunning() ? simHub.CurrentPID : simHub.startup(false))
}

callSimHub(command) {
	try {
		logMessage(kLogInfo, translate("Sending command '") . command . translate("' to SimHub (") . kSimHub . translate(")"))
		
		RunWait "%kSimHub%" -triggerinput %command%, , Hide
	}
	catch exception {
		logMessage(kLogCritical, translate("Error while connecting to SimHub (") . kSimHub . translate("): ") . exception.Message . translate(" - please check the configuration"))
		
		title := translate("Modular Simulator Controller System")
		
		SplashTextOn 800, 60, %title%, % translate("Cannot connect to SimHub (%kSimHub%) - please check the configuration...")
				
		Sleep 5000
					
		SplashTextOff
			
		return 0
	}
}

activatePedalVibration() {
	action := SimulatorController.Instance.findPlugin(kTactileFeedbackPlugin).findAction("Pedal Vibration")
	
	action.fireAction(action.Function, "On")
}

deactivatePedalVibration() {
	action := SimulatorController.Instance.findPlugin(kTactileFeedbackPlugin).findAction("Pedal Vibration")
	
	action.fireAction(action.Function, "Off")
}

activateFrontChassisVibration() {
	action := SimulatorController.Instance.findPlugin(kTactileFeedbackPlugin).findAction("Front Vibration")
	
	action.fireAction(action.Function, "On")
}

deactivateFrontChassisVibration() {
	action := SimulatorController.Instance.findPlugin(kTactileFeedbackPlugin).findAction("Front Vibration")
	
	action.fireAction(action.Function, "Off")
}

activateRearChassisVibration() {
	action := SimulatorController.Instance.findPlugin(kTactileFeedbackPlugin).findAction("Rear Vibration")
	
	action.fireAction(action.Function, "On")
}

deactivateRearChassisVibration() {
	action := SimulatorController.Instance.findPlugin(kTactileFeedbackPlugin).findAction("Rear Vibration")
	
	action.fireAction(action.Function, "Off")
}

initializeSimHubPlugin() {
	controller := SimulatorController.Instance
	
	kSimHub := getConfigurationValue(controller.Configuration, kTactileFeedbackPlugin, "Exe Path", false)
	
	if (!kSimHub || !FileExist(kSimHub)) {
		logMessage(kLogCritical, translate("Plugin Tactile Feedback deactivated, because the configured application path (") . kSimHub . translate(") cannot be found - please check the configuration"))
		
		if !isDebug()
			return
	}

	new TactileFeedbackPlugin(controller, kTactileFeedbackPlugin, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                        Controller Action Section                        ;;;
;;;-------------------------------------------------------------------------;;;

enablePedalVibration() {
	withProtection("activatePedalVibration")
}

disablePedalVibration() {
	withProtection("deactivatePedalVibration")
}

enableFrontChassisVibration() {
	withProtection("activateFrontChassisVibration")
}

disableFrontChassisVibration() {
	withProtection("deactivateFrontChassisVibration")
}

enableRearChassisVibration() {
	withProtection("activateRearChassisVibration")
}

disableRearChassisVibration() {
	withProtection("deactivateRearChassisVibration")
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeSimHubPlugin()
