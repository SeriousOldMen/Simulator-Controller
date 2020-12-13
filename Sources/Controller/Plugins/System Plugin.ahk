;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - System Plugin (required)        ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2020) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kSystemPlugin = "System"
global kLaunchMode = "Launch"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class SystemPlugin extends ControllerPlugin {
	iLaunchMode := false
	iMouseClicked := false
	iStartupSongIsPlaying := false
	iRunnableApplications := []
	iModeSelector := false
	
	class RunnableApplication extends Application {
		iIsRunning := false
		iLaunchpadFunction := false
		iLaunchpadAction := false
		
		LaunchpadFunction[] {
			Get {
				return this.iLaunchpadFunction
			}
		}
		
		LaunchpadAction[] {
			Get {
				return this.iLaunchpadAction
			}
		}
		
		updateRunningState() {
			isRunning := this.isRunning()
			stateChange := false
			
			if (isRunning != this.iIsRunning) {
				this.iIsRunning := isRunning
				
				stateChange := true
				
				trayMessage(kSystemPlugin, (isRunning ? "Start: " : "Stop: ") . this.Application)
			}
			
			if (stateChange && this.LaunchpadFunction != false) {
				controller := SimulatorController.Instance
					
				if (controller.ActiveMode == controller.findMode(kLaunchMode)) {
					transition := this.LaunchpadAction.Transition
					
					if (transition && ((A_TickCount - transition) > 10000)) {
						this.LaunchpadAction.endTransition()
						
						transition := false
					}
					
					if transition
						this.LaunchpadFunction.setText(this.LaunchpadAction.Label, "Gray")
					else {
						this.LaunchpadFunction.setText(this.LaunchpadAction.Label, isRunning ? "Green" : "Black")
					
						this.LaunchpadAction.endTransition()
					}
				}
			}
		}
		
		connectAction(function, action) {
			this.iLaunchpadFunction := function
			this.iLaunchpadAction := action
		}
	}
	
	class LaunchMode extends ControllerMode {
		Mode[] {
			Get {
				return kLaunchMode
			}
		}
	}
	
	class ModeSelectorAction extends ControllerAction {	
		Label[] {
			Get {
				return this.Controller.ActiveMode.Mode
			}
		}
	
		fireAction(function, trigger) {
			this.Controller.rotateMode(((trigger == "Off") || (trigger == "Decrease")) ? -1 : 1)

			this.Function.setText(this.Label)
		}
	}

	class LaunchAction extends ControllerAction {
		iApplication := false
		iTransition := false
	
		Application[] {
			Get {
				return this.iApplication
			}
		}
	
		Transition[] {
			Get {
				return this.iTransition
			}
		}
	
		__New(function, label, name) {
			this.iApplication := new Application(name, function.Controller.Configuration)
			
			base.__New(function, label)
		}
		
		fireAction(function, trigger) {
			if !this.Transition {
				if (function.Controller.ActiveMode == function.Controller.findMode(kLaunchMode)) {
					this.beginTransition()
				
					function.setText(this.Label, "Gray")
				}
				
				if !this.Application.isRunning()
					this.Application.startup()
				else
					this.Application.shutdown()
			}
		}
		
		beginTransition() {
			iTransition := A_TickCount
		}
		
		endTransition() {
			iTransition := false
		}
	}
	
	class LogoToggleAction extends ControllerAction {
		iLogoIsVisible := true
		
		fireAction(function, trigger) {
			this.Controller.showLogo(this.iLogoIsVisible := !this.iLogoIsVisible)
		}
	}
	
	class SystemShutdownAction extends ControllerAction {
		fireAction(function, trigger) {			
			SoundPlay *32
	
			OnMessage(0x44, "translateMsgBoxButtons")
			MsgBox 262436, Shutdown, Shutdown Simulator?
			OnMessage(0x44, "")

			IfMsgBox Yes
				Shutdown 1
		}
	}
	
	ModeSelector[] {
		Get {
			return this.iModeSelector
		}
	}
	
	RunnableApplications[] {
		Get {
			return this.iRunnableApplications
		}
	}
	
	MouseClicked[] {
		Get {
			return this.iMouseClicked
		}
	}
	
	__New(controller, name, configuration := false) {
		this.iLaunchMode := new this.LaunchMode(this)
		
		base.__New(controller, name, configuration)
		
		this.registerMode(this.iLaunchMode)
		
		this.initializeBackgroundTasks()
	}
	
	simulatorShutdown() {
		base.simulatorShutdown()
		
		this.Controller.setMode(this.iLaunchMode)
	}
	
	loadFromConfiguration(configuration) {
		local function
		
		base.loadFromConfiguration(configuration)
	
		descriptor := this.getArgumentValue("modeSelector")
		
		if (descriptor != false) {
			function := this.Controller.findFunction(descriptor)
			
			if (function != false)
				this.registerAction(this.iModeSelector := new this.ModeSelectorAction(function))
			else
				logMessage(kLogWarn, "Controller function " . descriptor . " not found in plugin " . this.Plugin . " - please check the setup")
		}
		
		for descriptor, name in getConfigurationSectionValues(configuration, "Applications", Object())
			this.RunnableApplications.Push(new this.RunnableApplication(name, configuration))
	
		registeredButtons := {}
		btnBox := this.Controller.ButtonBox
		
		for descriptor, appDescriptor in getConfigurationSectionValues(configuration, "Launchpad", Object()) {
			function := this.Controller.findFunction(descriptor)
			
			if (function != false) {
				appDescriptor := string2Values("|", appDescriptor)
			
				registeredButtons[ConfigurationItem.splitDescriptor(descriptor)[2]] := true
				
				action := new this.LaunchAction(function, appDescriptor[1], appDescriptor[2])
				
				this.iLaunchMode.registerAction(action)
				
				runnable := this.findRunnableApplication(appDescriptor[2])
				
				if (runnable != false)
					runnable.connectAction(function, action)
			}
			else
				logMessage(kLogWarn, "Controller function " . descriptor . " not found in plugin " . this.Plugin . " - please check the setup")
		}
			
		if ((btnBox != false) && !registeredButtons.HasKey(btnBox.NumButtons)) {
			descriptor := ConfigurationItem.descriptor("Button", btnBox.NumButtons)
			function := this.Controller.findFunction(descriptor)
		
			if (function != false)
				this.iLaunchMode.registerAction(new this.SystemShutdownAction(function, "Shutdown"))
			else
				logMessage(kLogWarn, "Controller function " . descriptor . " not found in plugin " . this.Plugin . " - please check the setup")
		}
			
		if ((btnBox != false) && !registeredButtons.HasKey(btnBox.NumButtons - 1)) {
			descriptor := ConfigurationItem.descriptor("Button", btnBox.NumButtons - 1)
			function := this.Controller.findFunction(descriptor)
		
			if (function != false)
				this.iLaunchMode.registerAction(new this.LogoToggleAction(function, ""))
			else
				logMessage(kLogWarn, "Controller function " . descriptor . " not found in plugin " . this.Plugin . " - please check the setup")
		}
	}
	
	findRunnableApplication(name) {
		for ignore, candidate in this.RunnableApplications
			if (name == candidate.Application)
				return candidate
				
		return false
	}
	
	mouseClick(clicked := true) {
		iMouseClicked := clicked
	}
	
	playStartupSong(songFile) {
		if (!kSilentMode && !this.iStartupSongIsPlaying) {
			try {
				if FileExist(kSplashMediaDirectory . songFile) {
					SoundPlay % kSplashMediaDirectory . songFile
			
					this.iStartupSongIsPlaying := true
				}
			}
			catch exception {
				; Ignore
			}
		}
	}
	
	stopStartupSong(callback := false) {
		if (this.iStartupSongIsPlaying) {
			masterVolume := fadeOut()

			try {
				SoundPlay NonExistent.avi
			}
			catch ignore {
			}
		
			this.iStartupSongIsPlaying := false
			
			if callback
				%callback%()
				
			fadeIn(masterVolume)
		}
	}

	initializeBackgroundTasks() {
		SetTimer updateApplicationStates, 1000
		SetTimer updateModeSelector, 200
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

fadeOut() {
	SoundGet masterVolume, MASTER

	currentVolume := masterVolume

	Loop {
		currentVolume -= 5

		if (currentVolume <= 0)
			break
		else {
			SoundSet %currentVolume%, MASTER

			Sleep 100
		}
	}
	
	return masterVolume
}

fadeIn(masterVolume) {
	currentVolume := 0

	Loop {
		currentVolume += 5

		if (currentVolume >= masterVolume)
			break
		else {
			SoundSet %currentVolume%, MASTER

			Sleep 100
		}
	}

	SoundSet %masterVolume%, MASTER
}

mouseClicked(clicked := true) {
	SimulatorController.Instance.findPlugin(kSystemPlugin).mouseClick(clicked)
}

restoreSimulatorVolume() {
	if kNirCmd
		try {
			Run %kNirCmd% setappvolume focused 1.0
		}
		catch exception {
			SplashTextOn 800, 60, Modular Simulator Controller System - Controller (Plugin: System), Cannot start NirCmd (%kNirCmd%): `n`nPlease run the setup tool...
					
			Sleep 5000
					
			SplashTextOff
		}
}

muteSimulator() {
	if (SimulatorController.Instance.ActiveSimulator != false) {
		SetTimer muteSimulator, Off
		
		Sleep 5000
		
		if kNirCmd
			try {
				Run %kNirCmd% setappvolume focused 0.0
			}
			catch exception {
				SplashTextOn 800, 60, Modular Simulator Controller System - Controller (Plugin: System), Cannot start NirCmd (%kNirCmd%): `n`nPlease run the setup tool...
						
				Sleep 5000
						
				SplashTextOff
			}
	
		SetTimer unmuteSimulator, 500
		
		mouseClicked(false)
		
		HotKey Escape, mouseClicked
		HotKey ~LButton, mouseClicked
	}
}

unmuteSimulator() {
	local plugin := SimulatorController.Instance.findPlugin(kSystemPlugin)
	
	if (plugin.MouseClicked || GetKeyState("LButton") || GetKeyState("Escape")) {
		HotKey ~LButton, Off
		HotKey Escape, Off
		
		SetTimer unmuteSimulator, Off

		plugin.stopStartupSong("restoreSimulatorVolume")
	}
}

updateApplicationStates() {
	protectionOn()

	try {
		for ignore, runnable in SimulatorController.Instance.findPlugin(kSystemPlugin).RunnableApplications
			runnable.updateRunningState()
	}
	finally {
		protectionOff()
	}
}

updateModeSelector() {
	local function
	
	static lastMode := false
	static countdown := 10
	static modeSelectorMode := false
	
	controller := SimulatorController.Instance
	
	protectionOn()
	
	try {
		countDown -= 1
		
		if (countDown == 0) {
			lastMode := false
				
			if modeSelectorMode {
				countDown := 10
				
				currentMode := controller.ActiveMode.Mode
			}
			else {
				countDown := 5
				
				currentMode := "Mode Selector"
			}
			
			modeSelectorMode := !modeSelectorMode
		}
		else
			currentMode := controller.ActiveMode.Mode
			
		if (currentMode != lastMode) {
			selector := controller.findPlugin(kSystemPlugin).ModeSelector
			function := selector.Function
			
			function.setText(currentMode, (currentMode == "Mode Selector") ? "Gray" : "Black")
			
			if !modeSelectorMode
				lastMode := currentMode
			else
				lastMode := controller.ActiveMode.Mode
		}
	}
	finally {
		protectionOff()
	}
}

initializeSystemPlugin() {
	local controller
	
	registerEventHandler("Startup", "handleStartupEvents")
	
	controller := SimulatorController.Instance
	
	new SystemPlugin(controller, kSystemPlugin, controller.Configuration)
	
	controller.setMode(controller.findMode(kLaunchMode))
}


;;;-------------------------------------------------------------------------;;;
;;;                          Event Handler Section                          ;;;
;;;-------------------------------------------------------------------------;;;

startupApplication(application, silent := true) {
	runnable := SimulatorController.Instance.findPlugin(kSystemPlugin).findRunnableApplication(application)
	
	if (runnable != false)
		return (runnable.startup(!silent) != 0)
	else
		return false
}

startupComponent(component) {
	startupApplication(component)
}

startupSimulator(simulator, silent := false) {
	startupApplication(simulator, silent)
}

shutdownSimulator(simulator) {
	runnable := SimulatorController.Instance.findPlugin(kSystemPlugin).findRunnableApplication(simulator)
	
	if (runnable != false)
		runnable.shutdown()
	
	return false
}

playStartupSong(songFile) {
	SimulatorController.Instance.findPlugin(kSystemPlugin).playStartupSong(songFile)
	
	SetTimer muteSimulator, 1000
}

stopStartupSong() {
	SimulatorController.Instance.findPlugin(kSystemPlugin).stopStartupSong()
		
	SetTimer muteSimulator, Off
}

handleStartupEvents(event, data) {
	local function
	
	if InStr(data, ":") {
		data := StrSplit(data, ":")
		
		function := data[1]
		arguments := string2Values(",", data[2])
			
		withProtection(function, arguments*)
	}
	else	
		withProtection(data)
}


;;;-------------------------------------------------------------------------;;;
;;;                        Controller Action Section                        ;;;
;;;-------------------------------------------------------------------------;;;

startSimulation(name := false) {
	local controller := SimulatorController.Instance
	
	if !(controller.ActiveSimulator != false) {
		if !name {
			simulators := string2Values("|", getConfigurationValue(controller.Configuration, "Configuration", "Simulators", ""))
	
			if (simulators.Length() > 0)
				name := simulators[1]
		}
		
		withProtection("startupSimulator", name)
	}
}

stopSimulation() {
	local simulator := SimulatorController.Instance.ActiveSimulator
	
	if (simulator != false) {
		withProtection("shutdownSimulator", simulator)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeSystemPlugin()