﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Simulator Controller            ;;;
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

;@Ahk2Exe-SetMainIcon ..\..\Resources\Icons\Gear.ico
;@Ahk2Exe-ExeName Simulator Controller.exe


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Includes\Includes.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Local Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\SpeechRecognizer.ahk


;;;-------------------------------------------------------------------------;;;
;;;                        Private Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kPluginLabelsFile = "Controller Plugin Labels.ini"

global kLogoBright = kResourcesDirectory . "Logo Bright.gif"
global kLogoDark = kResourcesDirectory . "Logo Dark.gif"

global kAllTrigger = "__All Trigger__"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class ButtonBox extends ConfigurationItem {
	static iButtonBoxGuis := {}
	
	iController := false
	
	iNum1WayToggles := 0
	iNum2WayToggles := 0
	iNumButtons := 0
	iNumDials := 0
	
	iWindow := false
	iWindowWidth := 0
	iWindowHeight := 0
	iControlHandles := {}
	
	iIsVisible := false
	iIsPositioned := false
	
	Controller[] {
		Get {
			return this.iController
		}
	}
	
	Descriptor[] {
		Get {
			return this.base.__Class
		}
	}
	
	Num1WayToggles[] {
		Get {
			return this.iNum1WayToggles
		}
	}
	
	Num2WayToggles[] {
		Get {
			return this.iNum2WayToggles
		}
	}
	
	NumButtons[] {
		Get {
			return this.iNumButtons
		}
	}
	
	NumDials[] {
		Get {
			return this.iNumDials
		}
	}
	
	Visible[] {
		Get {
			return this.iIsVisible
		}
	}
	
	VisibleDuration[] {
		Get {
			controller := this.Controller
			
			if (controller != false) {
				inSimulation := (controller.ActiveSimulator != false)
	
				return getConfigurationValue(this.Controller.Settings, "Button Box"
										   , inSimulation ? "Button Box Simulation Duration" : "Button Box Duration"
										   , inSimulation ? false : 10000)
			}
			else
				return false
		}
	}

	__New(controller, configuration := false) {
		this.iController := controller
		
		base.__New(configuration)
		
		this.createGui()
		
		controller.registerButtonBox(this)
	}
	
	createGui() {
		Throw "Virtual method ButtonBox.createGui must be implemented in a subclass..."
	}
	
	associateGui(window, width, height, num1WayToggles, num2WayToggles, numButtons, numDials) {
		this.iWindow := window
		this.iWindowWidth := width
		this.iWindowHeight := height
		
		this.iNum1WayToggles := num1WayToggles
		this.iNum2WayToggles := num2WayToggles
		this.iNumButtons := numButtons
		this.iNumDials := numDials
		
		this.iButtonBoxGuis[window] := this
		
		logMessage(kLogInfo, translate("Controller layout initialized:") . " #" . num1WayToggles . " " . translate("1-Way Toggles") . ", #" . num2WayToggles . " " . translate("2-Way Toggles") . ", #" . numButtons . " " . translate("Buttons") . ", #" . numDials . " " . translate("Dials"))
	}
	
	findButtonBox(window) {
		if this.iButtonBoxGuis.HasKey(window)
			return this.iButtonBoxGuis[window]
		else
			return false
	}
	
	registerControlHandle(descriptor, handle) {
		this.iControlHandles[descriptor] := handle
	}
	
	getControlHandle(descriptor) {
		if this.iControlHandles.HasKey(descriptor)
			return this.iControlHandles[descriptor]
		else
			return false
	}
	
	setControlText(function, text, color := "Black") {
		window := this.iWindow
		
		if (window != false) {
			handle := this.getControlHandle(function.Descriptor)
    
			if (handle != false) {
				Gui %window%:Font, s8 c%color%, Arial
				GuiControl Text, %handle%, % text
				GuiControl Font, %handle%
				Gui %window%:Font
			
				this.show()
			}
		}
	}
	
	updateVisibility() {
		this.Controller.updateLastEvent()
		
		this.show(false)
	}
	
	distanceFromTop() {
		distance := 0
		
		for ignore, btnBox in this.Controller.ButtonBoxes
			if (btnBox == this)
				return distance
			else
				distance += btnBox.iWindowHeight
		
		Throw "Internal error detected in ButtonBox.distanceFromTop..."
	}
	
	distanceFromBottom() {
		distance := 0
		buttonBoxes := this.Controller.ButtonBoxes
		index := buttonBoxes.Length()
		
		Loop {
			btnBox := buttonBoxes[index]
		
			distance += btnBox.iWindowHeight
		
			if (btnBox == this)
				return distance
		} until (--index = 0)
		
		Throw "Internal error detected in ButtonBox.distanceFromBottom..."
	}
	
	show(makeVisible := true) {
		duration := this.VisibleDuration
	
		if (duration >= 9999)
			duration := 24 * 3600 * 1000 ; Show always - one day should be enough :-)
		
		if (duration > 0) {
			if ((A_TickCount - this.Controller.LastEvent) > duration)
				return
			else
				SetTimer hideButtonBoxes, %duration%
		
			protectionOn()

			try {
				if makeVisible {
					this.Controller.hideLogo()
			
					window := this.iWindow
					width := this.iWindowWidth
					height := this.iWindowHeight
				
					if this.iIsPositioned
						Gui %window%:Show, NoActivate
					else {
						position := getConfigurationValue(this.Controller.Settings, "Button Box", "Button Box Position", "Bottom Right")
						
						SysGet mainScreen, MonitorWorkArea

						switch position {
							case "Top Left":
								x := mainScreenLeft
								y := mainScreenTop + this.distanceFromTop()
							case "Top Right":
								x := mainScreenRight - width
								y := mainScreenTop + this.distanceFromTop()
							case "Bottom Left":
								x := mainScreenLeft
								y := mainScreenBottom - this.distanceFromBottom()
							case "Bottom Right":
								x := mainScreenRight - width
								y := mainScreenBottom - this.distanceFromBottom()
							case "Secondary Screen":
								SysGet count, MonitorCount
								
								if (count > 1) {
									SysGet, secondScreen, MonitorWorkArea, 2
									
									x := Round(secondScreenLeft + ((secondScreenRight - secondScreenLeft - width) / 2))
									y := Round(secondScreenTop + ((secondScreenBottom - secondScreenTop- height) / 2))
								}
								else
									Goto defaultCase
							case "Last Position":
	defaultCase:
								x := getConfigurationValue(this.Controller.Settings, "Button Box", this.Descriptor . ".Position.X", mainScreenRight - width)
								y := getConfigurationValue(this.Controller.Settings, "Button Box", this.Descriptor . ".Position.Y", mainScreenBottom - height)
							default:
								Throw "Unhandled position for Button Box (" . position . ") encountered in ButtonBox.show..."
						}
						
						Gui %window%:Show, x%x% y%y% w%width% h%height% NoActivate
						
						this.iIsPositioned := true
					}

					this.iIsVisible := true
				}
			}
			finally {
				protectionOff()
			}
		}
		else
			this.hide()
	}
	
	hide() {
		protectionOn()
	
		try {
			if this.Visible {
				window := this.iWindow
			
				Gui %window%:Hide
	
				this.iIsVisible := false
			}
		}
		finally {
			protectionOff()
		}
	}
	
	moveByMouse(window, button := "LButton") {
		curCoordMode := A_CoordModeMouse
		
		CoordMode Mouse, Screen
			
		try {	
			MouseGetPos anchorX, anchorY
			WinGetPos winX, winY, w, h, %A_ScriptName%
			
			newX := winX
			newY := winY
			
			while GetKeyState(button, "P") {
				MouseGetPos x, y
			
				newX := winX + (x - anchorX)
				newY := winY + (y - anchorY)
				
				Gui %window%:Show, X%newX% Y%newY%
			}
			
			settings := this.Controller.Settings
			
			setConfigurationValue(settings, "Button Box", this.Descriptor . ".Position.X", newX)
			setConfigurationValue(settings, "Button Box", this.Descriptor . ".Position.Y", newY)
			
			writeConfiguration(kSimulatorSettingsFile, settings)
			
			this.Controller.reloadSettings(settings)
		}
		finally {
			CoordMode Mouse, curCoordMode
		}
	}
}

class SimulatorController extends ConfigurationItem {
	iSettings := false
	
	iPlugins := []
	iFunctions := {}
	iButtonBoxes := []
	
	iModes := []
	iActiveMode := false
	
	iFunctionActions := {}
	
	iVoiceServer := false
	iVoiceCommands := {}
	
	iLastEvent := A_TickCount
	
	iShowLogo := false
	iLogoIsVisible := false
	
	Settings[] {
		Get {
			return this.iSettings
		}
	}
	
	VoiceServer[] {
		Get {
			return this.iVoiceServer
		}
	}
	
	ButtonBoxes[] {
		Get {
			return this.iButtonBoxes
		}
	}
	
	Functions[] {
		Get {
			return this.iFunctions
		}
	}
	
	Plugins[] {
		Get {
			return this.iPlugins
		}
	}
	
	Modes[] {
		Get {
			return this.iModes
		}
	}
	
	ActiveMode[] {
		Get {
			return this.iActiveMode
		}
	}
	
	ActiveSimulator[] {
		Get {
			return this.runningSimulator()
		}
	}
	
	LastEvent[] {
		Get {
			return this.iLastEvent
		}
	}
	
	__New(configuration, settings, voiceServer := false) {
		SimulatorController.Controller := this
		
		this.iSettings := settings
		this.iVoiceServer := voiceServer
		
		SimulatorController.Instance := this
		
		base.__New(configuration)
		
		this.initializeBackgroundTasks()
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		for descriptor, arguments in getConfigurationSectionValues(configuration, "Controller Functions", Object()) {
			descriptor := ConfigurationItem.splitDescriptor(descriptor)
			descriptor := ConfigurationItem.descriptor(descriptor[1], descriptor[2])
			functions := this.Functions
			
			if !functions.HasKey(descriptor)
				functions[descriptor] := this.createControllerFunction(descriptor, configuration)
		}
	}
	
	reloadSettings(settings) {
		this.iSettings := settings
	}
	
	createControllerFunction(descriptor, configuration) {
		descriptor := ConfigurationItem.splitDescriptor(descriptor)
		
		switch descriptor[1] {
			case k2WayToggleType:
				return new Controller2WayToggleFunction(this, descriptor[2], configuration)
			case k1WayToggleType:
				return new Controller1WayToggleFunction(this, descriptor[2], configuration)
			case kButtonType:
				return new ControllerButtonFunction(this, descriptor[2], configuration)
			case kDialType:
				return new ControllerDialFunction(this, descriptor[2], configuration)
			case kCustomType:
				return new ControllerCustomFunction(this, descriptor[2], configuration)
			default:
				Throw "Unknown controller function descriptor (" . descriptor[1] . ") detected in SimulatorController.createControllerFunction..."
		}
	}
	
	findPlugin(name) {
		for ignore, mode in this.Plugins
			if (mode.Plugin = name)
				return mode
		
		return false
	}
	
	findMode(name) {
		for ignore, mode in this.Modes
			if (mode.Mode = name)
				return mode
		
		return false
	}
	
	findFunction(descriptor) {
		functions := this.Functions
		
		return (functions.HasKey(descriptor) ? functions[descriptor] : false)
	}
	
	getAction(function, trigger) {
		return (this.iFunctionActions.HasKey(function) ? this.iFunctionActions[function] : false)
	}
	
	getLogo() {
		Random randomLogo, 0, 1
	
		return ((Round(randomLogo) == 1) ? kLogoDark : kLogoBright)
	}
	
	registerButtonBox(buttonBox) {
		if !inList(this.iButtonBoxes, buttonBox)
			this.iButtonBoxes.Push(buttonBox)
	}
	
	unregisterButtonBox(buttonBox) {
		index := inList(this.iButtonBoxes, buttonBox)
		
		if index {
			buttonBox.hide()
			
			this.iButtonBoxes.RemoveAt(index)
		}
	}
	
	registerPlugin(plugin) {
		if !inList(this.Plugins, plugin) {
			logMessage(kLogInfo, translate("Plugin ") . translate(getPluginForLogMessage(plugin)) . (this.isActive(plugin) ? translate(" (Active)") : translate(" (Inactive)")) . translate(" registered"))
			
			this.Plugins.Push(plugin)
		}
	
		if this.isActive(plugin)
			plugin.activate()
	}
	
	registerMode(plugin, mode) {
		if !inList(this.Modes, mode) {
			logMessage(kLogInfo, translate("Mode ") . translate(getModeForLogMessage(mode)) . translate(" registered") . (plugin ? (translate(" for plugin ") . translate(getPluginForLogMessage(plugin))) : ""))
			
			this.Modes.Push(mode)
		}
	}
	
	isActive(modeOrPlugin) {
		return isDebug() ? true : modeOrPlugin.isActive()
	}
	
	runningSimulator() {
		for ignore, thePlugin in this.Plugins
			if this.isActive(thePlugin) {
				simulator := thePlugin.runningSimulator()
				
				if (simulator != false)
					return simulator
			}
		
		return false
	}

	simulatorStartup(simulator) {
		for ignore, thePlugin in this.Plugins
			if this.isActive(thePlugin)
				thePlugin.simulatorStartup(simulator)
		
		for ignore, btnBox in this.ButtonBoxes {
			buttonBox.hide()
			buttonBox.show()
		}
	}
	
	simulatorShutdown() {
		for ignore, thePlugin in this.Plugins
			if this.isActive(thePlugin) 
				thePlugin.simulatorShutdown()
		
		for ignore, btnBox in this.ButtonBoxes {
			buttonBox.hide()
			buttonBox.show()
		}
	}
	
	startSimulator(application, splashImage := false) {
		if !application.isRunning()
			if (application.startup(false))
				if (!kSilentMode && splashImage) {
					protectionOff()
		
					try {
						showSplash(splashImage)
		
						theme := getConfigurationValue(this.Settings, "Startup", "Splash Theme", false)
						songFile := (theme ? getConfigurationValue(this.Configuration, "Splash Themes", theme . ".Song", false) : false)
				
						if (songFile && FileExist(getFileName(songFile, kUserSplashMediaDirectory, kSplashMediaDirectory)))
							raiseEvent(kLocalMessage, "Startup", "playStartupSong:" . songFile)
						
						posX := Round((A_ScreenWidth - 300) / 2)
						posY := A_ScreenHeight - 150
		
						name := application.Application
						
						Progress B w300 x%posX% y%posY% FS8 CWD0D0D0 CBGreen, %name%, % translate("Starting Simulator")

						started := false

						Loop {
							if (A_Index >= 100)
								break
						
							Progress %A_Index%

							if (!started && application.isRunning())
								started := true
		
							Sleep % started ? 10 : 100
						}
					
						Progress Off
					}
					finally {
						protectionOn()
		
						hideSplash()
					}
				}
				
		return application.CurrentPID
	}
	
	getVoiceCommandDescriptor(command) {
		if this.iVoiceCommands.HasKey(command)
			return this.iVoiceCommands[command]
		else {
			descriptor := Array(command, false)
			
			this.iVoiceCommands[command] := descriptor
			
			if this.VoiceServer {
				Process Exist
				
				raiseEvent(kFileMessage, "Voice", "registerVoiceCommand:" . values2String(";", false, command, ErrorLevel, "voiceCommand"), this.VoiceServer)
			}
			
			return descriptor
		}
	}
	
	voiceCommand(grammar, command, words*) {
		handler := this.iVoiceCommands[command][2]
		
		if handler
			%handler%()
	}
	
	enableVoiceCommand(command, handler) {
		this.getVoiceCommandDescriptor(command)[2] := handler
	}
	
	disableVoiceCommand(command) {
		this.getVoiceCommandDescriptor(command)[2] := false
	}
	
	connectAction(function, action) {
		logMessage(kLogInfo, translate("Connecting ") . function.Descriptor . translate(" to action ") . translate(getLabelForLogMessage(action)))
		
		function.connectAction(action)
		
		this.iFunctionActions[function] := action
	}
	
	disconnectAction(function, action) {
		logMessage(kLogInfo, translate("Disconnecting ") . function.Descriptor . translate(" from action ") . translate(getLabelForLogMessage(action)))
		
		function.disconnectAction(action)
		
		this.iFunctionActions.Delete(function)
	}
	
	updateLastEvent() {
		this.iLastEvent := A_TickCount
	}
	
	fireAction(function, trigger) {
		local action := this.getAction(function, trigger)
		
		if (action != false) {
			this.updateLastEvent()
			
			logMessage(kLogInfo, translate("Firing action ") . translate(getLabelForLogMessage(action)) . translate(" for ") . function.Descriptor)
			
			action.fireAction(function, trigger)
		}
		else
			Throw "Cannot find action for " . function.Descriptor . ".trigger " . " in SimulatorController.fireAction..."
	}	

	setMode(newMode) {
		if !this.isActive(newMode)
			return
			
		modeSwitched := (this.ActiveMode != newMode)
	
		if modeSwitched {
			if (this.ActiveMode != false)
				this.ActiveMode.deactivate()
		
			this.iActiveMode := newMode
			
			logMessage(kLogInfo, translate("Setting controller mode to ") . translate(getModeForLogMessage(newMode)))
			
			if (newMode != false)
				newMode.activate()
		
			if modeSwitched
				trayMessage(translate("Control"), translate("Mode: ") . translate(newMode.Mode))
		}
	}
	
	rotateMode(delta := 1) {
		modes := this.Modes
		position := inList(modes, this.ActiveMode)
	
		targetMode := false
		index := position + delta
	
		Loop {
			if (index > modes.Length())
				index := 1
			else if (index < 1)
				index := modes.Length()
		
			targetMode := modes[index]
		
			if !this.isActive(targetMode) {
				index += delta
				targetMode := false
			}
		} until targetMode
		
		this.setMode(targetMode)
	}

	showLogo(show := "__Undefined__") {
		if (show != kUndefined)
			this.iShowLogo := show
		else if (this.iShowLogo && !this.iLogoIsVisible) {
			static videoPlayer
	
			info := kVersion . " - 2021, Oliver Juwig`nCreative Commons - BY-NC-SA"
			logo := this.getLogo()
			image := "1:" . logo

			SysGet mainScreen, MonitorWorkArea
			
			x := mainScreenRight - 229
			y := mainScreenBottom - 259
		
			title1 := translate("Modular Simulator")
			title2 := translate("Controller System")
			SplashImage %image%, B FS8 CWD0D0D0 w229 x%x% y%y% ZH180 ZW209, %info%, %title1%`n%title2%
	
			WinSet Transparent, 255, , % translate("Creative Commons - BY-NC-SA")
		
			Gui Logo:-Border -Caption 
			Gui Logo:Add, ActiveX, x0 y0 w209 h180 VvideoPlayer, shell explorer

			videoPlayer.Navigate("about:blank")
	
			html := "<html><body style='background-color: transparent' style='overflow:hidden' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'><img src='" . logo . "' width=209 height=180 border=0 padding=0></body></html>"

			videoPlayer.document.write(html)

			x += 10
			y += 40
		
			Gui Logo:Margin, 0, 0
			Gui Logo:+AlwaysOnTop
			Gui Logo:Show, AutoSize x%x% y%y%

			this.iLogoIsVisible := true
		}
	}
	
	hideLogo() {
		if this.iLogoIsVisible {
			Gui Logo:Destroy
			SplashImage 1:Off
		
			this.iLogoIsVisible := false
		}
	}
	
	initializeBackgroundTasks() {
		SetTimer updateSimulatorState, -10000
		
		this.iShowLogo := (this.iShowLogo && !kSilentMode)
	}
}

class ControllerFunction {
	iController := false
	iFunction := false
	
	Controller[] {
		Get {
			return this.iController
		}
	}
	
	Function[] {
		Get {
			return this.iFunction
		}
	}
	
	Type[] {
		Get {
			return this.Function.Type
		}
	}
	
	Number[] {
		Get {
			return this.Function.Number
		}
	}
	
	Descriptor[] {
		Get {
			return this.Function.Descriptor
		}
	}
	
	Hotkeys[trigger := false] {
		Get {
			return this.Function.Hotkeys[trigger]
		}
	}
	
	Trigger[] {
		Get {
			return this.Function.Trigger
		}
	}
	
	Actions[trigger := false] {
		Get {
			return this.Function.Actions[trigger]
		}
	}
	
	__New(controller, function) {
		this.iController := controller
		this.iFunction := function
	}
	
	setText(text, color := "Black") {
		for ignore, btnBox in this.Controller.ButtonBoxes
			btnBox.setControlText(this, text, color)
	}
	
	enable(trigger := "__All Trigger__") {
		if (trigger == kAllTrigger)
			for ignore, trigger in this.Trigger
				setHotkeyEnabled(this, trigger, true)
		else
			setHotkeyEnabled(this, trigger, true)
	}
	
	disable(trigger := "__All Trigger__") {
		if (trigger == kAllTrigger)
			for ignore, trigger in this.Trigger
				setHotkeyEnabled(this, trigger, false)
		else
			setHotkeyEnabled(this, trigger, false)
	}
	
	connectAction(action) {
		local controller := this.Controller
		
		for ignore, trigger in this.Trigger {
			handler := this.Actions[trigger]
			
			for ignore, theHotkey in this.Hotkeys[trigger] {
				if (SubStr(theHotkey, 1, 1) = "?") {
					command := SubStr(theHotkey, 2)
					
					controller.enableVoiceCommand(command, handler)
						
					logMessage(kLogInfo, translate("Binding voice command ") . command . translate(" for trigger ") . trigger . translate(" to ") . (action ? (action.base.__Class . ".fireAction") : this.Function.Actions[trigger, true]))
				}
				else
					try {
						Hotkey %theHotkey%, %handler%
						Hotkey %theHotkey%, On
						
						logMessage(kLogInfo, translate("Binding hotkey ") . theHotkey . translate(" for trigger ") . trigger . translate(" to ") . (action ? (action.base.__Class . ".fireAction") : this.Function.Actions[trigger, true]))
					}
					catch exception {
						logMessage(kLogCritical, translate("Error while registering hotkey ") . theHotkey . translate(" - please check the configuration"))
			
						showMessage(substituteVariables(translate("Cannot register hotkey %hotkey% - please check the configuration..."), {hotKey: theHotKey})
								  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
						
					}
			}
		}
	}
	
	disconnectAction(action) {
		local controller := this.Controller
		
		this.setText("")
		
		for ignore, trigger in this.Function.Trigger {
			for ignore, theHotkey in this.Hotkeys[trigger]
				if (SubStr(theHotkey, 1, 1) = "?")
					controller.disableVoiceCommand(SubStr(theHotkey, 2))
				else
					Hotkey %theHotkey%, Off
		}
	}
}

class Controller1WayToggleFunction extends ControllerFunction {
	class Inner1WayToggleFunction extends 1WayToggleFunction {
		iOuterFunction := false
			
		__New(outerFunction, functionNumber, configuration := false) {
			this.iOuterFunction := outerFunction
			
			base.__New(functionNumber, configuration)
		}
		
		actionCallable(trigger, action) {
			return functionActionCallable(this.iOuterFunction, trigger, base.actionCallable(trigger, action))
		}
	}
	
	__New(controller, number, configuration := false) {
		base.__New(controller, new this.Inner1WayToggleFunction(this, number, configuration))
	}
}

class Controller2WayToggleFunction extends ControllerFunction {
	class Inner2WayToggleFunction extends 2WayToggleFunction {
		iOuterFunction := false
			
		__New(outerFunction, functionNumber, configuration := false) {
			this.iOuterFunction := outerFunction
			
			base.__New(functionNumber, configuration)
		}
		
		actionCallable(trigger, action) {
			return functionActionCallable(this.iOuterFunction, trigger, base.actionCallable(trigger, action))
		}
	}
	
	__New(controller, number, configuration := false) {
		base.__New(controller, new this.Inner2WayToggleFunction(this, number, configuration))
	}
}

class ControllerButtonFunction extends ControllerFunction {
	class InnerButtonFunction extends ButtonFunction {
		iOuterFunction := false
			
		__New(outerFunction, functionNumber, configuration := false) {
			this.iOuterFunction := outerFunction
			
			base.__New(functionNumber, configuration)
		}
		
		actionCallable(trigger, action) {
			return functionActionCallable(this.iOuterFunction, trigger, base.actionCallable(trigger, action))
		}
	}
	
	__New(controller, number, configuration := false) {
		base.__New(controller, new this.InnerButtonFunction(this, number, configuration))
	}
}

class ControllerDialFunction extends ControllerFunction {
	class InnerDialFunction extends DialFunction {
		iOuterFunction := false
			
		__New(outerFunction, functionNumber, configuration := false) {
			this.iOuterFunction := outerFunction
			
			base.__New(functionNumber, configuration)
		}
		
		actionCallable(trigger, action) {
			return functionActionCallable(this.iOuterFunction, trigger, base.actionCallable(trigger, action))
		}
	}
	
	__New(controller, number, configuration := false) {
		base.__New(controller, new this.InnerDialFunction(this, number, configuration))
	}
}

class ControllerCustomFunction extends ControllerFunction {
	class InnerCustomFunction extends CustomFunction {
		iOuterFunction := false
			
		__New(outerFunction, functionNumber, configuration := false) {
			this.iOuterFunction := outerFunction
			
			base.__New(functionNumber, configuration)
		}
		
		actionCallable(trigger, action) {
			return functionActionCallable(this.iOuterFunction, trigger, base.actionCallable(trigger, action))
		}
	}
	
	__New(controller, number, configuration := false) {
		base.__New(controller, new this.InnerCustomFunction(this, number, configuration))
			
		this.connectAction(false)
	}
}

class ControllerPlugin extends Plugin {
	static sLabelsDatabase := false
	iController := false
	iModes := []
	iActions := []
	
	Controller[] {
		Get {
			return this.iController
		}
	}
	
	Modes[] {
		Get {
			return this.iModes
		}
	}
	
	Actions[] {
		Get {
			return this.iActions
		}
	}
	
	__New(controller, name, configuration := false, register := true) {
		this.iController := controller
		
		base.__New(name, configuration)
		
		if register
			this.Controller.registerPlugin(this)
	}
	
	findMode(name) {
		for ignore, mode in this.Modes
			if (mode.Mode = name)
				return mode
		
		return false
	}
	
	findAction(label) {
		for ignore, candidate in this.Actions
			if (candidate.Label = label)
				return candidate
			
		return false
	}
	
	registerMode(mode) {
		if !inList(this.Modes, mode)
			this.Modes.Push(mode)
		
		if (this.Controller != false)
			this.Controller.registerMode(this, mode)
	}
	
	registerAction(action) {
		if !inList(this.Actions, action)
			this.Actions.Push(action)
	}
	
	isActive() {
		return this.Active
	}
	
	activate() {
		controller := this.Controller
		
		logMessage(kLogInfo, translate("Activating plugin ") . translate(this.Plugin))
		
		for ignore, theAction in this.Actions {
			controller.connectAction(theAction.Function, theAction)
			
			theAction.Function.enable(kAllTrigger)
			theAction.Function.setText(translate(theAction.Label))
		}
	}
	
	deactivate() {
		controller := this.Controller
		
		logMessage(kLogInfo, translate("Deactivating plugin ") . translate(this.Plugin))
		
		for ignore, theAction in this.Actions
			controller.disconnectAction(theAction.Function, theAction)
	}
	
	runningSimulator() {
		return false
	}
	
	simulatorStartup(simulator) {
	}
	
	simulatorShutdown() {
	}
		
	getLabel(descriptor, default := false) {
		if !this.sLabelsDatabase
			this.sLabelsDatabase := readConfiguration(kPluginLabelsFile)
		
		label := getConfigurationValue(this.sLabelsDatabase, this.Plugin, descriptor, false)
		
		if (!label || (label == ""))
			label := default
			
		return label
	}
	
	logFunctionNotFound(functionDescriptor) {
		logMessage(kLogWarn, translate("Controller function ") . functionDescriptor . translate(" not found in plugin ") . translate(this.Plugin) . translate(" - please check the configuration"))
	}
}

class ControllerMode {
	iPlugin := false
	iActions := []
	
	Mode[] {
		Get {
			Throw "Virtual property ControllerMode.Mode must be implemented in a subclass..."
		}
	}
	
	Plugin[] {
		Get {
			return this.iPlugin
		}
	}
	
	Controller[] {
		Get {
			return this.Plugin.Controller
		}
	}
	
	Actions[] {
		Get {
			return this.iActions
		}
	}
	
	__New(plugin) {
		this.iPlugin := plugin
		
		plugin.registerMode(this)
	}
	
	registerAction(action) {
		if !inList(this.Actions, action)
			this.Actions.Push(action)
	}
	
	findAction(label) {
		for ignore, candidate in this.Actions
			if (candidate.Label = label)
				return candidate
			
		return false
	}
	
	isActive() {
		if this.Plugin.isActive() {
			simulators := this.Plugin.Simulators
			
			if (simulators.Length() == 0)
				return true
			else {
				simulator := this.Controller.ActiveSimulator
				
				return (simulator ? inList(simulators, simulator) : false)
			}
		}
		else
			return false
	}
	
	activate() {
		controller := this.Controller
		
		logMessage(kLogInfo, translate("Activating mode ") . translate(getModeForLogMessage(this)))
		
		for ignore, theAction in this.Actions {
			controller.connectAction(theAction.Function, theAction)
			
			theAction.Function.enable(kAllTrigger)
			theAction.Function.setText(translate(theAction.Label))
		}
	}
	
	deactivate() {
		controller := this.Controller
		
		logMessage(kLogInfo, translate("Deactivating mode ") . translate(getModeForLogMessage(this)))
		
		for ignore, theAction in this.Actions
			controller.disconnectAction(theAction.Function, theAction)
	}
}

class ControllerAction {
	iFunction := false
	iLabel := ""
	
	Function[] {
		Get {
			return this.iFunction
		}
	}
	
	Controller[] {
		Get {
			return this.Function.Controller
		}
	}
	
	Label[] {
		Get {
			return this.iLabel
		}
	}
	
	__New(function, label := "") {
		this.iFunction := function
		this.iLabel := label
	}
	
	fireAction(function, trigger) {
		Throw "Virtual method ControllerAction.fireAction must be implemented in a subclass..."
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

hideButtonBoxes() {
	for ignore, btnBox in SimulatorController.Instance.ButtonBoxes
		btnBox.hide()
}

setHotkeyEnabled(function, trigger, enabled) {
	local controller := SimulatorController.Instance
	
	state := enabled ? "On" : "Off"
	
	for ignore, theHotkey in function.Hotkeys[trigger]
		if (SubStr(theHotkey, 1, 1) = "?") {
			if enabled
				controller.enableVoiceCommand(SubStr(theHotkey, 2))
			else
				controller.disableVoiceCommand(SubStr(theHotkey, 2))
		}
		else
			Hotkey %theHotkey%, %state%
}

functionActionCallable(function, trigger, action) {
	return (action ? action : Func("fireControllerAction").Bind(function, trigger))
}

fireControllerAction(function, trigger) {
	protectionOn()
	
	try {
		function.Controller.fireAction(function, trigger)
	}
	finally {
		protectionOff()
	}
}

getLabelForLogMessage(action) {
	label := action.Label

	if (label == "")
		label := action.base.__Class
	
	return label
}
	
getPluginForLogMessage(plugin) {
	plugin := plugin.Plugin

	if (plugin == "")
		plugin := plugin.base.__Class
	
	return plugin
}

getModeForLogMessage(mode) {
	mode := mode.Mode

	if (mode == "")
		mode := mode.base.__Class
	
	return mode
}

updateSimulatorState() {
	static isSimulatorRunning := false
	controller := SimulatorController.Instance
	
	protectionOn()

	try {
		updateTrayMessageState()
			
		if (isSimulatorRunning != (controller.ActiveSimulator != false)) {
			isSimulatorRunning := !isSimulatorRunning
		
			if isSimulatorRunning
				controller.simulatorStartup(controller.ActiveSimulator)
			else
				controller.simulatorShutdown()

			for ignore, btnBox in controller.ButtonBoxes
				btnBox.updateVisibility()
		}
		
		if isSimulatorRunning {
			SetTimer updateSimulatorState, -5000
			
			controller.hideLogo()
		}
		else {
			SetTimer updateSimulatorState, -1000

			show := true
			
			for ignore, btnBox in controller.ButtonBoxes
				show := (show && !btnBox.Visible)
			
			if show
				controller.showLogo()
		}
	}
	finally {
		protectionOff()
	}
}

updateTrayMessageState(settings := false) {
	inSimulation := false
	
	if !settings {
		settings := SimulatorController.Instance.Settings
		inSimulation := SimulatorController.Instance.ActiveSimulator
	}
	
	duration := getConfigurationValue(settings, "Tray Tip"
									, inSimulation ? "Tray Tip Simulation Duration" : "Tray Tip Duration"
									, inSimulation ? 1500 : false)
							   
	if (duration > 0)
		enableTrayMessages(duration)
	else
		disableTrayMessages()
}

initializeSimulatorController() {
	icon := kIconsDirectory . "Gear.ico"
	
	Menu Tray, Icon, %icon%, , 1
	
	settings := readConfiguration(kSimulatorSettingsFile)
	
	updateTrayMessageState(settings)
	
	argIndex := inList(A_Args, "-Voice")
	
	protectionOn()
	
	try {
		new SimulatorController(kSimulatorConfiguration, settings, argIndex ? A_Args[argIndex + 1] : false)
	}
	finally {
		protectionOff()
	}
	
	registerEventHandler("Voice", "handleVoiceRemoteCalls")
}

startupSimulatorController() {
	controller := SimulatorController.Instance
	
	controller.updateLastEvent()
	
	for ignore, btnBox in controller.ButtonBoxes
		if btnBox.VisibleDuration >= 9999
			btnBox.show()
}


;;;-------------------------------------------------------------------------;;;
;;;                        Controller Action Section                        ;;;
;;;-------------------------------------------------------------------------;;;

pushButton(buttonNumber) {
	local function
	
	descriptor := ConfigurationItem.descriptor(kButtonType, buttonNumber)
	function := SimulatorController.Instance.findFunction(descriptor)
	
	if ((function != false) && SimulatorController.Instance.getAction(function, "Push"))
		fireControllerAction(function, "Push")
	else
		logMessage(kLogWarn, translate("Controller function ") . descriptor . translate(" not found in custom controller action pushButton - please check the configuration"))
}

rotateDial(dialNumber, direction) {
	local function
	
	if (direction = "increase")
		direction := "Increase"
	else if (direction = "decrease")
		direction := "Decrease"
	else {
		logMessage(kLogWarn, translate("Unsupported argument (") . direction . translate(") detected in rotateDial - please check the configuration"))
		
		Throw "Unsupported argument (" . direction . ") detected in rotateDial..."
	}
	
	descriptor := ConfigurationItem.descriptor(kDialType, dialNumber)
	function := SimulatorController.Instance.findFunction(descriptor)
	
	if ((function != false) && SimulatorController.Instance.getAction(function, direction))
		fireControllerAction(function, direction)
	else
		logMessage(kLogWarn, translate("Controller function ") . descriptor . translate(" not found in custom controller action rotateDial - please check the configuration"))
}

switchToggle(toggleType, toggleNumber, mode := "activate") {
	local function
	
	descriptor := ConfigurationItem.descriptor(toggleType, toggleNumber)
	function := SimulatorController.Instance.findFunction(descriptor)
	
	if (function != false) {
		if (((mode = "activate") || (mode = "on")) && SimulatorController.Instance.getAction(function, "On"))
			fireControllerAction(function, "On")
		else if (((mode = "deactivate") || (mode = "off")) && SimulatorController.Instance.getAction(function, "Off"))
			fireControllerAction(function, "Off")
		else {
			logMessage(kLogWarn, translate("Unsupported argument (") . mode . translate(") detected in switchToggle - please check the configuration"))
		
			Throw "Unsupported argument (" . mode . ") detected in switchToggle..."
		}
	}
	else
		logMessage(kLogWarn, translate("Controller function ") . descriptor . translate(" not found in custom controller action switchToggle - please check the configuration"))
}

setMode(action) {
	controller := SimulatorController.Instance

	protectionOn()
	
	try {
		if (action = kIncrease)
			SimulatorController.Instance.rotateMode(1)
		else if (action = kDecrease)
			SimulatorController.Instance.rotateMode(-1)
		else {
			mode := controller.findMode(action)
			
			if ((mode != false) && controller.isActive(mode))
				controller.setMode(mode)
			else
				trayMessage(translate("Control"), translate("Mode: ") . translate(action) . translate(" is not available"), 10000)
		}
	}
	finally {
		protectionOff()
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                          Event Handler Section                          ;;;
;;;-------------------------------------------------------------------------;;;

handleVoiceRemoteCalls(event, data) {
	if InStr(data, ":") {
		data := StrSplit(data, ":", , 2)
	
		return withProtection(ObjBindMethod(SimulatorController.Instance, data[1]), string2Values(";", data[2])*)
	}
	else
		return withProtection(ObjBindMethod(SimulatorController.Instance, data))
}


;;;-------------------------------------------------------------------------;;;
;;;                       Initialization Section Part 1                     ;;;
;;;-------------------------------------------------------------------------;;;

initializeSimulatorController()


;;;-------------------------------------------------------------------------;;;
;;;                          Plugin Include Section                         ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Plugins\Plugins.ahk
#Include %A_MyDocuments%\Simulator Controller\Plugins\Plugins.ahk


;;;-------------------------------------------------------------------------;;;
;;;                       Initialization Section Part 2                     ;;;
;;;-------------------------------------------------------------------------;;;

startupSimulatorController()