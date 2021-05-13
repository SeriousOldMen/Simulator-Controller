;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Setup Database Test             ;;;
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

; SetBatchLines -1				; Maximize CPU utilization
; ListLines Off					; Disable execution history


;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Engineer\Libraries\SetupDatabase.ahk
#Include AHKUnit\AHKUnit.ahk


;;;-------------------------------------------------------------------------;;;
;;;                              Test Section                               ;;;
;;;-------------------------------------------------------------------------;;;

class InitializeDatabase extends Assert {
	Initialize_Test() {
		try {
			FileRemoveDir %kSetupDatabaseDirectory%Local\Unknown\TestCar, 1
		}
		catch exception {
			; ignore
		}
		
		this.AssertEqual(true, true)
	}
}

class WritePressures extends Assert {	
	SimpleWritePressure_Test() {
		database := new SetupDatabase()
		
		pressures := {}
		
		pressures["FL:26.1"] := 1
		pressures["FR:26.2"] := 1
		pressures["RL:26.3"] := 1
		pressures["RR:26.4"] := 1
		
		database.updatePressures("Unknown", "TestCar", "TestTrack", "Dry", 25, 25, "Dry", "Black", pressures)
		
		this.AssertEqual(true, true)
	}
	
	ExtendedWritePressure_Test() {
		database := new SetupDatabase()
		
		pressures := {}
		
		pressures["FL:26.1"] := 1
		pressures["FL:26.2"] := 2
		pressures["FL:26.3"] := 7
		pressures["FL:26.4"] := 4
		
		pressures["FR:26.2"] := 1
		pressures["FR:26.3"] := 3
		pressures["FR:26.5"] := 5
		pressures["FR:26.6"] := 1
		
		pressures["RL:26.3"] := 1
		pressures["RL:26.4"] := 6
		pressures["RL:26.5"] := 1
		
		pressures["RR:26.4"] := 7
		
		database.updatePressures("Unknown", "TestCar", "TestTrack", "Dry", 25, 26, "Dry", "Black", pressures)
		
		this.AssertEqual(true, true)
	}
}

class ReadPressures extends Assert {
	AssertExactResult(pressures, flPressure, frPressure, rlPressure, rrPressure) {
		for tyre, pressureInfo in pressures {
			switch tyre {
				case "FL":
					this.AssertEqual(flPressure, pressureInfo["Pressure"], "FL pressure should be " . flPressure . "...")
				case "FR":
					this.AssertEqual(frPressure, pressureInfo["Pressure"], "FR pressure should be " . frPressure . "...")
				case "RL":
					this.AssertEqual(rlPressure, pressureInfo["Pressure"], "RL pressure should be " . rlPressure . "...")
				case "RR":
					this.AssertEqual(rrPressure, pressureInfo["Pressure"], "RR pressure should be " . rrPressure . "...")
				default:
					this.AssertEqual(true, false, "Unknown tyre type encountered...")
			}
			
			this.AssertEqual(0, pressureInfo["Delta Air"], "Delta Air should be 0...")
			this.AssertEqual(0, pressureInfo["Delta Track"], "Delta Track should be 0...")
		}
	}
		
	SimpleReadPressure_Test() {
		this.AssertExactResult(new SetupDatabase().getPressures("Unknown", "TestCar", "TestTrack", "Dry", 25, 25, "Dry", "Black"), 26.1, 26.2, 26.3, 26.4)
	}
		
	ExtendedReadPressure_Test() {
		this.AssertExactResult(new SetupDatabase().getPressures("Unknown", "TestCar", "TestTrack", "Dry", 25, 26, "Dry", "Black"), 26.3, 26.5, 26.4, 26.4)
	}
}

class ReadExtrapolatedPressures extends Assert {
	listEqual(list1, list2) {
		if (list1.Length() == list2.Length()) {
			for index, value in list1
				if (list2[index] != value)
					return false
			
			return true
		}
		else
			return false
	}
	
	AssertExtrapolatedResult(pressures, flPressure, frPressure, rlPressure, rrPressure, deltaAir, deltaTrack) {
		for tyre, pressureInfo in pressures {
			switch tyre {
				case "FL":
					this.AssertEqual(flPressure, pressureInfo["Pressure"], "FL pressure should be " . flPressure . "...")
				case "FR":
					this.AssertEqual(frPressure, pressureInfo["Pressure"], "FR pressure should be " . frPressure . "...")
				case "RL":
					this.AssertEqual(rlPressure, pressureInfo["Pressure"], "RL pressure should be " . rlPressure . "...")
				case "RR":
					this.AssertEqual(rrPressure, pressureInfo["Pressure"], "RR pressure should be " . rrPressure . "...")
				default:
					this.AssertEqual(true, false, "Unknown tyre type encountered...")
			}
			
			this.AssertEqual(deltaAir, pressureInfo["Delta Air"], "Delta Air should be 0...")
			this.AssertEqual(deltaTrack, pressureInfo["Delta Track"], "Delta Track should be 0...")
		}
	}
	
	AssertExtrapolatedValues(expCompound, compound, expCompoundColor, compoundColor, expPressures, pressures, expCertainty, certainty) {
		this.AssertEqual(expCompound, compound, "Compound should be " . expCompound . "...")
		this.AssertEqual(expCompoundColor, compoundColor, "Compound color should be " . expCompoundColor . "...")
		this.AssertEqual(expCertainty, certainty, "Certainty should be " . expCertainty . "...")
		this.AssertEqual(true, this.listEqual(pressures, expPressures), "Pressures do not match...")
	}
		
	ReadPressure_Test() {
		database := new SetupDatabase()
		
		this.AssertExtrapolatedResult(database.getPressures("Unknown", "TestCar", "TestTrack", "Dry", 25, 27, "Dry", "Black"), 26.3, 26.5, 26.4, 26.4, 0, -1)
		
		this.AssertExtrapolatedResult(database.getPressures("Unknown", "TestCar", "TestTrack", "Dry", 25, 28, "Dry", "Black"), 26.3, 26.5, 26.4, 26.4, 0, -2)
		
		this.AssertExtrapolatedResult(database.getPressures("Unknown", "TestCar", "TestTrack", "Dry", 24, 26, "Dry", "Black"), 26.3, 26.5, 26.4, 26.4, 1, 0)
		
		this.AssertExtrapolatedResult(database.getPressures("Unknown", "TestCar", "TestTrack", "Dry", 24, 27, "Dry", "Black"), 26.3, 26.5, 26.4, 26.4, 1, -1)
		
		this.AssertExtrapolatedResult(database.getPressures("Unknown", "TestCar", "TestTrack", "Dry", 25, 25, "Dry", "Black"), 26.1, 26.2, 26.3, 26.4, 0, 0)
	}
		
	ReadSetup_Test() {
		database := new SetupDatabase()
		
		compound := false
		compoundColor := false
		pressures := false
		certainty := false
		
		database.getTyreSetup("Unknown", "TestCar", "TestTrack", "Dry", 25, 25, compound, compoundColor, pressures, certainty)
			
		this.AssertExtrapolatedValues("Dry", compound, "Black", compoundColor, [26.1, 26.2, 26.3, 26.4], pressures, 1.0, certainty)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

AHKUnit.AddTestClass(InitializeDatabase)
AHKUnit.AddTestClass(WritePressures)
AHKUnit.AddTestClass(ReadPressures)
AHKUnit.AddTestClass(ReadExtrapolatedPressures)

AHKUnit.Run()
