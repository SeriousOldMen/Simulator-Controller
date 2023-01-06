﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Installation Step Wizard        ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;
;;; InstallationStepWizard                                                  ;;;
;;;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -;;;

class InstallationStepWizard extends StepWizard {
	iPages := {}
	iSoftwareLocators := {}

	Pages[] {
		Get {
			return Ceil(this.Definition.Length() / 3)
		}
	}

	createGui(wizard, x, y, width, height) {
		local window := this.Window
		local definition := this.Definition
		local startY := y
		local iconHandle, labelHandle, installButtonHandle, locateButtonHandle, infoTextHandle
		local ignore, software, installer, folder, locatable, info, label, installed, buttonX
		local labelWidth, labelX, labelY, buttonY, page, html

		static infoText1
		static infoText2
		static infoText3
		static infoText4
		static infoText5
		static infoText6
		static infoText7
		static infoText8
		static infoText9
		static infoText10
		static infoText11
		static infoText12
		static infoText13
		static infoText14
		static infoText15
		static infoText16

		static installButton1
		static installButton2
		static installButton3
		static installButton4
		static installButton5
		static installButton6
		static installButton7
		static installButton8
		static installButton9
		static installButton10
		static installButton11
		static installButton12
		static installButton13
		static installButton14
		static installButton15
		static installButton16

		static locateButton1
		static locateButton2
		static locateButton3
		static locateButton4
		static locateButton5
		static locateButton6
		static locateButton7
		static locateButton8
		static locateButton9
		static locateButton10
		static locateButton11
		static locateButton12
		static locateButton13
		static locateButton14
		static locateButton15
		static locateButton16

		if (this.Definition.Count() > 16)
			throw "Too many modules detected in InstallationStepWizard.createGui..."

		for ignore, software in this.Definition
		{
			iconHandle := false
			labelHandle := false
			installButtonHandle := false
			locateButtonHandle := false
			infoTextHandle := false

			installer := substituteVariables(getConfigurationValue(this.SetupWizard.Definition, "Setup.Installation", "Installation." . software))
			folder := getConfigurationValue(this.SetupWizard.Definition, "Setup.Installation", "Installation." . software . ".Folder", false)
			locatable := getConfigurationValue(this.SetupWizard.Definition, "Setup.Installation", "Installation." . software . ".Locatable", true)
			info := substituteVariables(getConfigurationValue(this.SetupWizard.Definition, "Setup.Installation", "Installation." . software . ".Info." . getLanguage()))

			label := (translate("Software: ") . software)
			info := "<div style='font-family: Arial, Helvetica, sans-serif' style='font-size: 11px'><hr style='width: 90%'>" . info . "</div>"

			installed := (folder ? false : this.SetupWizard.isSoftwareInstalled(software))

			buttonX := x + width - 90

			if locatable
				buttonX -= 95

			labelWidth := width - 60 - 90 - (locatable * 95)
			labelX := x + 35
			labelY := y + 8

			Gui %window%:Add, Picture, x%x% y%y% w30 h30 HWNDiconHandle Hidden, %kResourcesDirectory%Setup\Images\Install.png

			Gui %window%:Font, s10 Bold, Arial

			Gui %window%:Add, Text, x%labelX% y%labelY% w%labelWidth% h26 HWNDlabelHandle Hidden, % label

			Gui %window%:Font, s8 Norm, Arial

			buttonY := y + 5

			Gui %window%:Add, Button, x%buttonX% y%buttonY% w90 h23 HWNDinstallButtonHandle VinstallButton%A_Index% GinstallSoftware Hidden, % folder ? translate("Open...") : (InStr(installer, "http") = 1) ? translate("Download...") : translate("Install...")

			if locatable {
				buttonX += 95

				Gui %window%:Add, Button, x%buttonX% y%buttonY% w90 h23 HWNDlocateButtonHandle VlocateButton%A_Index% GlocateSoftware Hidden, % installed ? translate("Installed") : translate("Locate...")
			}

			Sleep 200

			Gui %window%:Add, ActiveX, x%x% yp+33 w%width% h121 HWNDinfoTextHandle VinfoText%A_Index% Hidden, shell.explorer

			html := "<html><body style='background-color: #D0D0D0' style='overflow: auto' leftmargin='0' topmargin='0' rightmargin='0' bottommargin='0'>" . info . "</body></html>"

			infoText%A_Index%.Navigate("about:blank")
			infoText%A_Index%.Document.Write(html)

			y += 170

			page := Ceil(A_Index / 3)

			this.registerWidgets(page, iconHandle, labelHandle, installButtonHandle, infoTextHandle)

			if locatable
				this.registerWidget(page, locateButtonHandle)

			this.iSoftwareLocators[software] := (locatable ? [installButtonHandle, locateButtonHandle] : [installButtonHandle])

			if !this.iPages.HasKey(page)
				this.iPages[page] := {}

			this.iPages[page][software] := (locatable ? [installButtonHandle, locateButtonHandle] : [installButtonHandle])

			if (((A_Index / 3) - Floor(A_Index / 3)) == 0)
				y := startY
		}
	}

	reset() {
		base.reset()

		this.iPages := {}
		this.iSoftwareLocators := {}
	}

	loadStepDefinition(definition) {
		local ignore, software

		base.loadStepDefinition(definition)

		for ignore, software in this.Definition
			this.SetupWizard.locateSoftware(software)
	}

	installSoftware(software) {
		local wizard := this.SetupWizard
		local folder := getConfigurationValue(wizard.Definition, "Setup.Installation", "Installation." . software . ".Folder", false)
		local locatable, installer, extension, buttons, button

		if folder {
			folder := substituteVariables(getConfigurationValue(this.SetupWizard.Definition, "Setup.Installation", "Installation." . software))

			Run explore %folder%
		}
		else {
			locatable := getConfigurationValue(wizard.Definition, "Setup.Installation", "Installation." . software . ".Locatable", true)
			installer := substituteVariables(getConfigurationValue(wizard.Definition, "Setup.Installation", "Installation." . software))

			SplitPath installer, , , extension

			if (!locatable || (extension = "EXE") || (extension = "MSI")) {
				RunWait %installer%

				wizard.locateSoftware(software)

				if (wizard.isSoftwareInstalled(software) && this.iSoftwareLocators.HasKey(software)) {
					buttons := this.iSoftwareLocators[software]

					GuiControl Disable, % buttons[1]

					if (buttons.Length() > 1) {
						button := buttons[2]

						GuiControl Disable, %button%
						GuiControl Text, %button%, % translate("Installed")
					}
					else {
						button := buttons[1]

						GuiControl Text, %button%, % translate("Installed")
					}
				}
			}
			else
				Run %installer%
		}
	}

	locateSoftware(software, executable) {
		local buttons, button

		this.SetupWizard.locateSoftware(software, executable)

		buttons := this.iSoftwareLocators[software]

		GuiControl Disable, % buttons[1]

		button := buttons[2]

		GuiControl Disable, %button%
		GuiControl Text, %button%, % translate("Installed")
	}

	showPage(page) {
		local software, widgets, ignore, widget, buttons, button

		base.showPage(page)

		for software, widgets in this.iPages[page]
			if !getConfigurationValue(this.SetupWizard.Definition, "Setup.Installation", "Installation." . software . ".Folder", false)
				if !this.SetupWizard.isSoftwareRequested(software)
					for ignore, widget in widgets
						GuiControl Disable, %widget%
				else {
					this.SetupWizard.locateSoftware(software)

					if (this.SetupWizard.isSoftwareInstalled(software) && this.iSoftwareLocators.HasKey(software)) {
						buttons := this.iSoftwareLocators[software]

						GuiControl Disable, % buttons[1]

						if (buttons.Length() > 1) {
							button := buttons[2]

							GuiControl Disable, %button%
							GuiControl Text, %button%, % translate("Installed")
						}
						else {
							button := buttons[1]

							GuiControl Text, %button%, % translate("Installed")
						}
					}
				}
	}

	hidePage(page) {
		local wizard := this.SetupWizard
		local done := true
		local software, ignore, title

		for software, ignore in this.iPages[page]
			if (wizard.isSoftwareRequested(software) && !wizard.isSoftwareOptional(software) && !wizard.isSoftwareInstalled(software)) {
				done := false

				break
			}

		if !done {
			OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Yes", "No"]))
			title := translate("Setup")
			MsgBox 262436, %title%, % translate("Not all required software components have been installed. Do you really want to proceed?")
			OnMessage(0x44, "")

			IfMsgBox No
				return false
		}

		return base.hidePage(page)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                   Private Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

installSoftware() {
	local stepWizard := SetupWizard.Instance.StepWizards["Installation"]
	local definition := stepWizard.Definition

	stepWizard.installSoftware(definition[StrReplace(A_GuiControl, "installButton", "")])
}

locateSoftware() {
	local stepWizard := SetupWizard.Instance.StepWizards["Installation"]
	local definition := stepWizard.Definition
	local name := definition[StrReplace(A_GuiControl, "locateButton", "")]
	local folder := getConfigurationValue(stepWizard.SetupWizard.Definition, "Setup.Installation", "Installation." . name . ".Folder", false)
	local title, file

	if folder {
		folder := substituteVariables(getConfigurationValue(stepWizard.SetupWizard.Definition, "Setup.Installation", "Installation." . name))

		Run explore %folder%
	}
	else {
		title := substituteVariables(translate("Select %name% executable..."), {name: name})

		Gui +OwnDialogs

		OnMessage(0x44, Func("translateMsgBoxButtons").Bind(["Select", "Cancel"]))
		FileSelectFile file, 1, , %title%, Executable (*.exe)
		OnMessage(0x44, "")

		if (file != "")
			stepWizard.locateSoftware(name, file)
	}
}

initializeInstallationStepWizard() {
	SetupWizard.Instance.registerStepWizard(new InstallationStepWizard(SetupWizard.Instance, "Installation", kSimulatorConfiguration))
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeInstallationStepWizard()