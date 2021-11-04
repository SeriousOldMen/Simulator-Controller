;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Stream Deck Plugin              ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2021) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\CLR.ahk


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constants Section                        ;;;
;;;-------------------------------------------------------------------------;;;

global kIcon = "Icon"
global kLabel = "Label"
global kIconAndLabel = "IconAndLabel"
global kIconOrLabel = "IconOrLabel"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class StreamDeck extends FunctionController {
	iName := false
	iLayout := false
	
	iRowDefinitions := []
	iRows := false
	iColumns := false
	
	iFunctions := []
	iLabels := {}
	iIcons := {}
	iModes := {}
		
	iConnector := false
	
	iActions := {}
	
	Type[] {
		Get {
			return "Stream Deck"
		}
	}
	
	Name[] {
		Get {
			return this.iName
		}
	}
	
	Layout[] {
		Get {
			return this.iLayout
		}
	}
	
	RowDefinitions[] {
		Get {
			return this.iRowDefinitions
		}
	}
	
	Rows[] {
		Get {
			return this.iRows
		}
	}
	
	Columns[] {
		Get {
			return this.iColumns
		}
	}
	
	Functions[] {
		Get {
			return this.iFunctions
		}
	}
	
	Actions[function := false] {
		Get {
			if function
				return (function ? this.iActions[function] : [])
			else
				return this.iActions
		}
	}
	
	Label[function := false] {
		Get {
			if function
				return (this.iLabels.HasKey(function) ? this.iLabels[function] : true)
			else
				return this.iLabels
		}
	}
	
	Icon[function := false] {
		Get {
			if function
				return (this.iIcons.HasKey(function) ? this.iIcons[function] : true)
			else
				return this.iIcons
		}
	}
	
	Mode[function := false] {
		Get {
			if function
				return (this.iModes.HasKey(function) ? this.iModes[function] : kIconOrLabel)
			else
				return this.iModes
		}
	}
	
	Connector[] {
		Get {
			return this.iConnector
		}
	}
	
	__New(name, layout, controller, configuration) {
		this.iName := name
		this.iLayout := layout
		
		dllName := "SimulatorControllerPluginConnector.dll"
		dllFile := kBinariesDirectory . dllName
			
		this.iConnector := CLR_LoadLibrary(dllFile).CreateInstance("PluginConnector.PluginConnector")
		
		base.__New(controller, configuration)
	}
	
	loadFromConfiguration(configuration) {
		local function
		
		numButtons := 0
		numDials := 0
		num1WayToggles := 0
		num2WayToggles := 0
		
		base.loadFromConfiguration(configuration)
		
		layout := string2Values("x", getConfigurationValue(configuration, "Layouts", ConfigurationItem.descriptor(this.Layout, "Layout"), ""))
		
		this.iRows := layout[1]
		this.iColumns := layout[2]
		
		rows := []
		
		Loop % this.Rows
		{
			row := string2Values(";", getConfigurationValue(configuration, "Layouts", ConfigurationItem.descriptor(this.Layout, A_Index), ""))
			
			for ignore, function in row
				if (function != "") {
					this.Functions.Push(function)
					
					icon := getConfigurationValue(configuration, "Buttons", this.Layout . "." . function . ".Icon", true)
					label := getConfigurationValue(configuration, "Buttons", this.Layout . "." . function . ".Label", true)
					mode := getConfigurationValue(configuration, "Buttons", this.Layout . "." . function . ".Mode", kIconOrLabel)
				
					isRunning := this.isRunning()
					
					if isRunning {
						this.Connector.SetTitle(function, "")
						this.Connector.SetImage(function, "clear")
					}
					
					if (mode != kIconOrLabel) {
						this.iModes[function] := mode
					}
					
					if (icon != true) {
						this.iIcons[function] := icon
						
						if (icon && (icon != "") && isRunning)
							this.setControlIcon(function, icon)
					}
					
					if (label != true) {
						this.iLabels[function] := label
						
						if (label && isRunning)
							this.setControlLabel(function, label)
					}
					
					switch ConfigurationItem.splitDescriptor(function)[1] {
						case k1WayToggleType:
							num1WayToggles += 1
						case k2WayToggleType:
							num2WayToggles += 1
						case kButtonType:
							numButtons += 1
						case kDialType:
							numDials += 1
						default:
							Throw "Unknown controller function type (" . ConfigurationItem.splitDescriptor(function)[1] . ") detected in StreamDeck.loadFromConfiguration..."
					}
				}
				
			rows.Push(row)
		}
		
		this.iRowDefinitions := rows
		
		this.setControls(num1WayToggles, num2WayToggles, numButtons, numDials)
	}
	
	isRunning() {
		Process Exist, SimulatorControllerPlugin.exe
		
		return (ErrorLevel != 0)
	}
	
	hasFunction(function) {
		if IsObject(function)
			function := function.Descriptor
		
		return (inList(this.Functions, function) != false)
	}
	
	connectAction(plugin, function, action) {
		actions := this.Actions
		
		if actions.HasKey(function)
			actions[function].Push(action)
		else
			actions[function] := Array(action)
		
		this.setControlLabel(function, plugin.actionLabel(action))
		this.setControlIcon(function, plugin.actionIcon(action))
	}
	
	disconnectAction(plugin, function, action) {
		this.setControlLabel(function, "")
		this.setControlIcon(function, false)
		
		actions := this.Actions[function]
		
		index := inList(actions, action)
		
		if index
			actions.RemoveAt(index)
		
		if (actions.Length() = 0)
			this.Actions.Delete(function)
	}
	
	setControlLabel(function, text, color := "Black", overlay := false) {
		if (this.isRunning() && this.hasFunction(function)) {
			actions := this.Actions[function]
			hasIcon := false
			
			for ignore, theAction in this.Actions[function]
				if theAction.Icon {
					hasIcon := true
					
					break
				}
			
			displayMode := this.Mode[function.Descriptor]
			
			if (hasIcon && !overlay && ((displayMode = kIcon) || (displayMode = kIconOrLabel)))
				this.Connector.SetTitle(function.Descriptor, "")
			else {
				labelMode := this.Label[function.Descriptor]
				
				if (labelMode == true)
					this.Connector.SetTitle(function.Descriptor, text)
				else if (labelMode == false)
					this.Connector.SetTitle(function.Descriptor, "")
				else
					this.Connector.SetTitle(function.Descriptor, labelMode)
			}
		}
	}
	
	setControlIcon(function, icon) {
		if (this.isRunning() && this.hasFunction(function)) {
			if (!icon || (icon = ""))
				icon := "clear"
			
			displayMode := this.Mode[function.Descriptor]
			
			if (displayMode = kLabel)
				this.Connector.SetImage(function.Descriptor, "clear")
			else {
				iconMode := this.Icon[function.Descriptor]
				
				if (iconMode == true)
					this.Connector.SetImage(function.Descriptor, icon)
				else if (iconMode == false)
					this.Connector.SetImage(function.Descriptor, "clear")
				else
					this.Connector.SetImage(function.Descriptor, iconMode)
			}
		}
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

streamDeckEventHandler(event, data) {
	local function
		
	command := string2Values(A_Space, data)
	
	function := command[1]
	
	found := false
	
	for ignore, fnController in SimulatorController.Instance.FunctionController
		if isInstance(fnController, StreamDeck) && fnController.hasFunction(function)
			found := true
	
	if !found
		return
	
	descriptor := ConfigurationItem.splitDescriptor(function)
	
	switch descriptor[1] {
		case k1WayToggleType, k2WayToggleType:
			switchToggle(descriptor[1], descriptor[2], (command.Length() > 1) ? command[2] : "On")
		case kButtonType:
			pushButton(descriptor[2])
		case kDialType:
			rotateDial(descriptor[2], command[2])
		default:
			Throw "Unknown controller function type (" . descriptor[1] . ") detected in streamDeckEventHandler..."
	}
}

initializeStreamDeckPlugin() {
	controller := SimulatorController.Instance
	
	configuration := readConfiguration(getFileName("Stream Deck Configuration.ini", kUserConfigDirectory, kConfigDirectory))
	
	for ignore, strmDeck in string2Values("|", getConfigurationValue(controller.Configuration, "Controller Layouts", "Stream Decks", "")) {
		strmDeck := string2Values(":", strmDeck)
	
		new StreamDeck(strmDeck[1], strmDeck[2], controller, configuration)
	}
	
	registerEventHandler("Stream Deck", "streamDeckEventHandler")
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeStreamDeckPlugin()