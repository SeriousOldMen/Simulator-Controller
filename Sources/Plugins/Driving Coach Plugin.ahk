﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Driving Coach Plugin            ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Libraries\Task.ahk"
#Include "Libraries\RaceAssistantPlugin.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                         Public Constant Section                         ;;;
;;;-------------------------------------------------------------------------;;;

global kDrivingCoachPlugin := "Driving Coach"


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class DrivingCoachPlugin extends RaceAssistantPlugin  {
	iServiceState := "Available"

	class RemoteDrivingCoach extends RaceAssistantPlugin.RemoteRaceAssistant {
		__New(plugin, remotePID) {
			super.__New(plugin, "Driving Coach", remotePID)
		}
	}

	DrivingCoach {
		Get {
			return this.RaceAssistant
		}
	}

	RaceAssistantPersistent {
		Get {
			return true
		}
	}

	createRaceAssistantAction(controller, action, actionFunction, arguments*) {
		if (inList(["RaceAssistant", "Call", "SetupWorkbenchOpen"], action))
			super.createRaceAssistantAction(controller, action, actionFunction, arguments*)
		else
			logMessage(kLogWarn, translate("Action `"") . action . translate("`" not found in plugin ") . translate(this.Plugin) . translate(" - please check the configuration"))
	}

	createRaceAssistant(pid) {
		return DrivingCoachPlugin.RemoteDrivingCoach(this, pid)
	}

	serviceState(health) {
		this.iServiceState := health
	}

	writePluginState(configuration) {
		local problem

		if this.Active {
			if this.RaceAssistantEnabled {
				setMultiMapValue(configuration, "Race Assistants", this.Plugin, (this.iServiceState = "Available") ? "Active" : "Critical")

				setMultiMapValue(configuration, this.Plugin, "State", (this.iServiceState = "Available") ? "Active" : "Critical")

				information := (translate("Started: ") . translate(this.RaceAssistant ? "Yes" : "No"))

				if (this.iServiceState = "Available") {
					if !this.RaceAssistantSpeaker
						information .= ("; " . translate("Silent: ") . translate("Yes"))
						
					if this.RaceAssistantMuted
						information .= ("; " . translate("Muted: ") . translate("Yes"))
				}
				else if (InStr(this.iServiceState, "Error") = 1)
					information .= ("; " . translate("Problem: ") . translate(string2Values(":", this.iServiceState)[2]))


				setMultiMapValue(configuration, this.Plugin, "Information", information)
			}
			else
				setMultiMapValue(configuration, this.Plugin, "State", "Disabled")
		}
		else
			super.writePluginState(configuration, false)
	}

	enableRaceAssistant(label := false, startup := false) {
		startCoach() {
			if MessageManager.isPaused()
				return Task.CurrentTask
			else
				this.requireRaceAssistant()
		}

		super.enableRaceAssistant(label, startup)

		Task.startTask(startCoach, 1000, kLowPriority)
	}

	disableRaceAssistant(label := false, startup := false) {
		super.disableRaceAssistant(label, startup)

		this.shutdownRaceAssistant(true)
	}

	shutdownRaceAssistant(force := false) {
		if force
			super.shutdownRaceAssistant()
	}

	joinSession(settings, data) {
		this.startSession(settings, data)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

initializeDrivingCoachPlugin() {
	local controller := SimulatorController.Instance

	DrivingCoachPlugin(controller, kDrivingCoachPlugin, controller.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeDrivingCoachPlugin()