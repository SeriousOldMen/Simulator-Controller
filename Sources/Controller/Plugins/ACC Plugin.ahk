;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - ACC Plugin                      ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2020) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kACCPlugin = "ACC"
global kDriveMode = "Drive"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class ACCPlugin extends ControllerPlugin {
	iDriveMode := false
	
	class DriveMode extends ControllerMode {
		Mode[] {
			Get {
				return kDriveMode
			}
		}
	}

	class ChatAction extends ControllerAction {
		iMessage := ""
		
		Message[] {
			Get {
				return this.iMessage
			}
		}
		
		__New(function, label, message) {
			this.iMessage := message
			
			base.__New(function, label)
		}
		
		fireAction(function, trigger) {
			message := this.Message
			
			Send {Enter}
			Sleep 100
			Send %message%
			Sleep 100
			Send {Enter}
		}
	}

	Plugin[] {
		Get {
			return kACCPlugin
		}
	}
	
	__New(controller, name, configuration := false) {
		this.iDriveMode := new this.DriveMode(this)
		
		base.__New(controller, name, configuration)
		
		this.registerMode(this.iDriveMode)
	}
	
	runningSimulator() {
		return isACCRunning() ? "Assetto Corsa Competizione" : false
	}
	
	simulatorStartup(simulator) {
		base.simulatorStartup(simulator)
		
		if (inList(this.Simulators, simulator)) {
			this.Controller.setMode(this.iDriveMode)
		}
	}
	
	loadFromConfiguration(configuration) {
		base.loadFromConfiguration(configuration)
		
		for descriptor, message in getConfigurationSectionValues(configuration, "Chat Messages", Object()) {
			function := this.Controller.findFunction(descriptor)
			
			if (function != false) {
				message := string2Values("|", message)
			
				this.iDriveMode.registerAction(new this.ChatAction(function, message[1], message[2]))
			}
			else
				logMessage(kLogWarn, "Controller function " . descriptor . " not found in plugin " . this.Plugin . " - please check the setup")
		}
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                     Function Hook Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

startACC() {
	if !isACCRunning()
		if (new Application("Assetto Corsa Competizione", SimulatorController.Instance.Configuration).startup(false))
			if !kSilentMode {
				protectionOff()
	
				try {
					showSplash("Simulator Splash Images\ACC Splash.jpg")
	
					raiseEvent(false, "Startup", "playStartupSong")
					
					posX := Round((A_ScreenWidth - 300) / 2)
					posY := A_ScreenHeight - 150
	
					Progress B w300 x%posX% y%posY% FS8 CWD0D0D0 CBGreen, Assetto Corsa Competizione, Starting Simulator

					started := false

					Loop {
						if (A_Index >= 100)
							break
					
						Progress %A_Index%

						if (!started && isACCRunning())
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
}

stopACC() {
	if isACCRunning() {
		IfWinNotActive AC2  , , WinActivate, AC2  , 
		WinWaitActive AC2  , , 2
		MouseClick left,  2093,  1052
		Sleep 500
		MouseClick left,  2614,  643
		Sleep 500
		MouseClick left,  2625,  619
		Sleep 500
	}
}

isACCRunning() {
	Process Exist, acc.exe
	
	return (ErrorLevel != 0)
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeACCPlugin() {
	local controller := SimulatorController.Instance
	
	new ACCPlugin(controller, kACCPLugin, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeACCPlugin()
