;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Setup Editor for ACC            ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2022) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                           Local Include Section                         ;;;
;;;-------------------------------------------------------------------------;;;

#Include ..\Libraries\JSON.ahk


;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCBrakeBalanceConverter                                                ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCBrakeBalanceConverter extends OffsetConverter {
	__New() {
		base.__New(47.0, 47.0, 68.0)
	}
	
	convertToDisplayValue(value) {
		return Round(base.convertToDisplayValue(value / 5), 1)
	}
	
	convertToRawValue(value) {
		return Round((value - this.Offset) * 5)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCTyrePressureConverter                                                ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCTyrePressureConverter extends OffsetConverter {
	__New() {
		base.__New(20.3, 20.3, 35.0)
	}
	
	convertToDisplayValue(value) {
		return Round(base.convertToDisplayValue(value / 10), 1)
	}
	
	convertToRawValue(value) {
		return Round((value - this.Offset) * 10)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCSpringRateConverter                                                  ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCSpringRateConverter extends IdentityConverter {
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCBumpstopRateConverter                                                ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCBumpstopRateConverter extends OffsetConverter {
	__New() {
		base.__New(300, 300, 2500)
	}
	
	convertToDisplayValue(value) {
		return Round(base.convertToDisplayValue(value * 100))
	}
	
	convertToRawValue(value) {
		return Round((value - this.Offset) / 100)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCBumpstopRangeConverter                                               ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCBumpstopRangeConverter extends IdentityConverter {
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCDamperConverter                                                      ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCDamperConverter extends ClickConverter {
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCToeConverter                                                         ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCToeConverter extends OffsetConverter {
	convertToDisplayValue(value) {
		return Round(base.convertToDisplayValue(value / 100), 2)
	}
	
	convertToRawValue(value) {
		return Round((value - this.Offset) * 100)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCFrontToeConverter                                                    ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCFrontToeConverter extends ACCToeConverter {
	__New() {
		base.__New(-0.48, -0.48, 0.44)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCRearToeConverter                                                     ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCRearToeConverter extends ACCToeConverter {
	__New() {
		base.__New(-0.1, -0.1, 0.4)
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCCamberConverter                                                      ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCCamberConverter extends ClickConverter {
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCPreloadConverter                                                     ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCPreloadConverter extends IdentityConverter {
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCSetup                                                                ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCSetup extends Setup {
	iOriginalData := false
	iModifiedData := false
	
	Data[original := false] {
		Get {
			return (original ? this.iOriginalData : this.iModifiedData)
		}
	}
	
	__New(editor, originalFileName := false) {
		iEditor := editor
		
		base.__New(editor, originalFileName)
		
		this.iOriginalData := JSON.parse(this.Setup[true])
		this.iModifiedData := JSON.parse(this.Setup[false])
	}
	
	getValue(data, setting, default := false) {
		for ignore, path in string2Values(".", getConfigurationValue(this.Editor.Configuration, "Setup.Settings", setting)) {
			if InStr(path, "[") {
				path := string2Values("[", SubStr(path, 1, StrLen(path) - 1))
				
				if data.HasKey(path[1]) {
					data := data[path[1]]
					
					if data.HasKey(path[2])
						data := data[path[2]]
					else
						return default
				}
				else
					return default
			}
			else if data.HasKey(path)
				data := data[path]
			else
				return default
		}
		
		return data
	}
}

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; ACCSetupEditor                                                          ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class ACCSetupEditor extends SetupEditor {
	editSetup(theSetup := false) {
		if !theSetup {
			title := translate("Load ACC Setup File...")
	
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Load", "Cancel"]))
			FileSelectFile fileName, 1, %A_MyDocuments%\Assetto Corsa Competizione\Setups, %title%, Setup (*.json)
			OnMessage(0x44, "")

			if fileName
				theSetup := new ACCSetup(this, fileName)
		}

		if theSetup
			return base.editSetup(theSetup)
		else
			return false
	}
	
	loadSetup(setup := false) {
		local converter
		
		base.loadSetup(setup)
		
		settingsLabels := getConfigurationSectionValues(this.Advisor.Definition, "Setup.Settings.Labels." . getLanguage(), Object())
		
		if (settingsLabels.Count() == 0)
			settingsLabels := getConfigurationSectionValues(this.Advisor.Definition, "Setup.Settings.Labels.EN", Object())
		
		settingsUnits := getConfigurationSectionValues(this.Configuration, "Setup.Settings.Units." . getLanguage(), Object())
		
		if (settingsUnits.Count() == 0)
			settingsUnits := getConfigurationSectionValues(this.Configuration, "Setup.Settings.Units.EN", Object())
		
		window := this.Window
		
		Gui %window%:Default
		
		Gui ListView, % this.SettingsListView
		
		LV_Delete()
		
		for ignore, setting in this.Advisor.Settings {
			converter := this.createConverter(setting)
			
			originalValue := converter.convertToDisplayValue(setup.getValue(setup.Data[true], setting))
			modifiedValue := converter.convertToDisplayValue(setup.getValue(setup.Data[false], setting))
			
			if (originalValue = modifiedValue)
				value := originalValue
			else if (modifiedValue > originalValue)
				value := (originalValue . A_Space . translate("(") . "+" . (modifiedValue - originalValue) . translate(")"))
			else
				value := (originalValue . A_Space . translate("(") . "-" . (originalValue - modifiedValue) . translate(")"))
			
			LV_Add("", settingsLabels[setting], value, settingsUnits[setting])
		}
		
		LV_ModifyCol()
		
		LV_ModifyCol(1, "AutoHdr")
		LV_ModifyCol(2, "AutoHdr")
		LV_ModifyCol(3, "AutoHdr")
	}
}