﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - GUI Functions                   ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2023) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Global Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Framework\Constants.ahk"
#Include "..\Framework\Variables.ahk"
#Include "..\Framework\Debug.ahk"
#Include "..\Framework\Strings.ahk"
#Include "..\Framework\Localization.ahk"
#Include "..\Framework\MultiMap.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                    Private Function Declaration Section                 ;;;
;;;-------------------------------------------------------------------------;;;

getControllerActionDefinitions(type) {
	local fileName := ("Controller Action " . type . "." . getLanguage())
	local definitions, section, values, key, value

	if (!FileExist(kTranslationsDirectory . fileName) && !FileExist(kUserTranslationsDirectory . fileName))
		fileName := ("Controller Action " . type . ".en")

	definitions := readMultiMap(kTranslationsDirectory . fileName)

	for section, values in readMultiMap(kUserTranslationsDirectory . fileName)
		for key, value in values
			setMultiMapValue(definitions, section, key, value)

	return definitions
}


;;;-------------------------------------------------------------------------;;;
;;;                    Public Classes Declaration Section                   ;;;
;;;-------------------------------------------------------------------------;;;

class ResizeableGui extends Gui {
	iMinWidth := 0
	iMinHeight := 0

	iWidth := 0
	iHeight := 0

	iResizers := []

	iDescriptor := false

	class Resizer {
		iGui := false

		Gui {
			Get {
				return this.iGui
			}
		}

		__New(resizeableGui) {
			this.iGui := resizeableGui
		}

		Initialize() {
		}

		CanResize(deltaWidth, deltaHeight) {
			return true
		}

		Resize(deltaWidth, deltaHeight) {
		}
	}

	class ControlResizer extends ResizeableGui.Resizer {
		iRule := false
		iControl := false

		iOriginalX := 0
		iOriginalY := 0
		iOriginalWidth := 0
		iOriginalHeight := 0

		Control {
			Get {
				return this.iControl
			}
		}

		Rule {
			Get {
				return this.iRule
			}
		}

		OriginalX {
			Get {
				return this.iOriginalX
			}
		}

		OriginalY {
			Get {
				return this.iOriginalY
			}
		}

		OriginalWidth {
			Get {
				return this.iOriginalWidth
			}
		}

		OriginalHeight {
			Get {
				return this.iOriginalHeight
			}
		}

		__New(resizeableGui, control, rule) {
			this.iControl := control
			this.iRule := rule

			super.__New(resizeableGui)
		}

		Initialize() {
			local x, y, w, h

			ControlGetPos(&x, &y, &w, &h, this.Control)

			this.iOriginalX := x
			this.iOriginalY := y
			this.iOriginalWidth := w
			this.iOriginalHeight := h
		}

		CanResize(deltaWidth, deltaHeight) {
			return !!this.Rule
		}

		Resize(deltaWidth, deltaHeight) {
			local x := this.OriginalX
			local y := this.OriginalY
			local w := this.OriginalWidth
			local h := this.OriginalHeight
			local ignore, part, variable, horizontal

			for ignore, part in string2Values(";", this.Rule) {
				part := string2Values(":", part)
				variable := part[1]

				if (variable = "Width")
					variable := "w"
				else if (variable = "Height")
					variable := "h"

				horizontal := ((variable = "x") || (variable = "w"))

				switch part[2], false {
					case "Move":
						%variable% += (horizontal ? deltaWidth : deltaHeight)
					case "Move/2":
						%variable% += Round((horizontal ? deltaWidth : deltaHeight) / 2)
					case "Grow":
						%variable% += (horizontal ? deltaWidth : deltaHeight)
					case "Grow/2":
						%variable% += Round((horizontal ? deltaWidth : deltaHeight) / 2)
					case "Center":
						if horizontal
							x := Round((this.Gui.Width / 2) - (w / 2))
						else
							y := Round((this.Gui.Height / 2) - (h / 2))
				}
			}

			ControlMove(x, y, w, h, this.Control)

			this.Control.Redraw()
		}
	}

	Descriptor {
		Get {
			return this.iDescriptor
		}

		Set {
			return (this.iDescriptor := value)
		}
	}

	MinWidth {
		Get {
			return this.iMinWidth
		}
	}

	MinHeight {
		Get {
			return this.iMinHeight
		}
	}

	Width {
		Get {
			return this.iWidth
		}
	}

	Height {
		Get {
			return this.iHeight
		}
	}

	Resizers {
		Get {
			return this.iResizers
		}
	}

	__New(arguments*) {
		super.__New(arguments*)

		this.Opt("+Resize -MaximizeBox")

		this.OnEvent("Size", this.Resize)
	}

	Show(arguments*) {
		local x, y, width, height

		super.Show(arguments*)

		WinGetPos(&x, &y, &width, &height, this)

		this.iMinWidth := width
		this.iMinHeight := height
		this.iWidth := width
		this.iHeight := height

		for ignore, resizer in this.Resizers
			resizer.Initialize()
	}

	AddResizer(resizer) {
		this.Resizers.Push(resizer)
	}

	DefineResizeRule(control, rule) {
		this.AddResizer(ResizeableGui.ControlResizer(this, control, rule))
	}

	Resize(minMax, width, height) {
		local descriptor := this.Descriptor
		local x, y, w, h, settings

		if (minMax = "Initialize") {
			WinGetPos(&x, &y, &w, &h, this)

			this.iWidth := width
			this.iHeight := height

			WinMove(x, y, width, height, this)
		}
		else {
			if !this.Width
				return

			WinGetPos(&x, &y, &w, &h, this)

			width := w
			height := h

			if ((width < this.iMinWidth) || (height < this.iMinHeight)) {
				this.iWidth := this.MinWidth
				this.iHeight := this.MinHeight

				WinMove(x, y, this.MinWidth, this.MinHeight, this)

				this.ControlsResize(this.MinWidth, this.MinHeight)
			}
			else if ((this.Resizers.Length = 0) || !this.ControlsCanResize(width, height)) {
				if (this.Width && this.Height)
					WinMove(x, y, this.Width, this.Height, this)
			}
			else {
				this.iWidth := width
				this.iHeight := height

				this.ControlsResize(width, height)

				WinRedraw(this)
			}

			if descriptor {
				settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

				setMultiMapValue(settings, "Window Positions", descriptor . ".Width", this.Width)
				setMultiMapValue(settings, "Window Positions", descriptor . ".Height", this.Height)

				writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)
			}
		}
	}

	ControlsCanResize(width, height) {
		local ignore, resizer

		for ignore, resizer in this.Resizers
			if !resizer.CanResize(width - this.MinWidth, height - this.MinHeight)
				return false

		return true
	}

	ControlsResize(width, height) {
		local ignore, resizer

		for ignore, resizer in this.Resizers
			resizer.Resize(width - this.MinWidth, height - this.MinHeight)
	}
}


;;;-------------------------------------------------------------------------;;;
;;;                    Public Function Declaration Section                  ;;;
;;;-------------------------------------------------------------------------;;;

setButtonIcon(buttonHandle, file, index := 1, options := "") {
	local ptrSize, button_il, normal_il, L, T, R, B, A, W, H, S, DW, PTR
	local BCM_SETIMAGELIST

;   Parameters:
;   1) {Handle} 	HWND handle of Gui button
;   2) {File} 		File containing icon image
;   3) {Index} 		Index of icon in file
;						Optional: Default = 1
;   4) {Options}	Single letter flag followed by a number with multiple options delimited by a space
;						W = Width of Icon (default = 16)
;						H = Height of Icon (default = 16)
;						S = Size of Icon, Makes Width and Height both equal to Size
;						L = Left Margin
;						T = Top Margin
;						R = Right Margin
;						B = Botton Margin
;						A = Alignment (0 = left, 1 = right, 2 = top, 3 = bottom, 4 = center; default = 4)

	RegExMatch(options, "i)w\K\d+", &W), !W ? W := 16 : W := W[]
	RegExMatch(options, "i)h\K\d+", &H), !H ? H := 16 : H := H[]
	RegExMatch(options, "i)s\K\d+", &S), S ? W := H := S[] :
	RegExMatch(options, "i)l\K\d+", &L), !L ? L := 0 : L := L[]
	RegExMatch(options, "i)t\K\d+", &T), !T ? T := 0 : T := T[]
	RegExMatch(options, "i)r\K\d+", &R), !R ? R := 0 : R := R[]
	RegExMatch(options, "i)b\K\d+", &B), !B ? B := 0 : B := B[]
	RegExMatch(options, "i)a\K\d+", &A), !A ? A := 4 : A := A[]

	ptrSize := A_PtrSize = "" ? 4 : A_PtrSize, DW := "UInt", Ptr := A_PtrSize = "" ? DW : "Ptr"

	button_il := Buffer(20 + ptrSize, 0)

	NumPut(Ptr, normal_il := DllCall("ImageList_Create", DW, W, DW, H, DW, 0x21, DW, 1, DW, 1), button_il, 0)	; Width & Height
	NumPut(DW, L, button_il, 0 + ptrSize)		; Left Margin
	NumPut(DW, T, button_il, 4 + ptrSize)		; Top Margin
	NumPut(DW, R, button_il, 8 + ptrSize)		; Right Margin
	NumPut(DW, B, button_il, 12 + ptrSize)		; Bottom Margin
	NumPut(DW, A, button_il, 16 + ptrSize)		; Alignment

	SendMessage(BCM_SETIMAGELIST := 5634, 0, button_il, , "AHK_ID " . (buttonHandle is Gui.Control) ? buttonHandle.Hwnd : buttonHandle)

	return IL_Add(normal_il, file, index)
}

fixIE(version := 0, exeName := "") {
	local previousValue

	static key := "Software\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_BROWSER_EMULATION"
	static versions := Map(7, 7000, 8, 8888, 9, 9999, 10, 10001, 11, 11001)

	if versions.Has(version)
		version := versions[version]

	if !exeName {
		if A_IsCompiled
			exeName := A_ScriptName
		else
			SplitPath(A_AhkPath, &exeName)
	}

	previousValue := RegRead("HKCU\" . key, exeName, "")

	try {
		if (version = "") {
			RegDelete("HKCU\" . key, exeName)
			RegDelete("HKLM\" . key, exeName)
		}
		else {
			RegWrite(version, "REG_DWORD", "HKCU\" . key, exeName)
			RegWrite(version, "REG_DWORD", "HKLM\" . key, exeName)
		}
	}
	catch Any as exception {
		logError(exception, false, false)
	}

	return previousValue
}

openDocumentation(dialog, url, *) {
	Run(url)
}

moveByMouse(dialog, descriptor := false, *) {
	local curCoordMode := A_CoordModeMouse
	local anchorX, anchorY, winX, winY, newX, newY, x, y, w, h
	local curCoordMode, anchorX, anchorY, winX, winY, x, y, w, h, newX, newY, settings

	CoordMode("Mouse", "Screen")

	try {
		MouseGetPos(&anchorX, &anchorY)
		WinGetPos(&winX, &winY, &w, &h, "A")

		newX := winX
		newY := winY

		while GetKeyState("LButton", "P") {
			MouseGetPos(&x, &y)

			newX := winX + (x - anchorX)
			newY := winY + (y - anchorY)

			dialog.Move(newX, newY)
		}

		if descriptor {
			settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

			setMultiMapValue(settings, "Window Positions", descriptor . ".X", newX)
			setMultiMapValue(settings, "Window Positions", descriptor . ".Y", newY)

			writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)
		}
	}
	finally {
		CoordMode("Mouse", curCoordMode)
	}
}

getWindowPosition(descriptor, &x, &y) {
	local settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")
	local posX := getMultiMapValue(settings, "Window Positions", descriptor . ".X", kUndefined)
	local posY := getMultiMapValue(settings, "Window Positions", descriptor . ".Y", kUndefined)
	local screen, screenLeft, screenRight, screenTop, screenBottom

	if ((posX == kUndefined) || (posY == kUndefined))
		return false
	else {
		loop MonitorGetCount() {
			MonitorGetWorkArea(A_Index, &screenLeft, &screenTop, &screenRight, &screenBottom)

			if ((posX >= screenLeft) && (posX <= screenRight) && (posY >= screenTop) && (posY <= screenBottom)) {
				x := posX
				y := posY

				return true
			}
		}

		return false
	}
}

getWindowSize(descriptor, &width, &height) {
	local settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

	width := getMultiMapValue(settings, "Window Positions", descriptor . ".Width", kUndefined)
	height := getMultiMapValue(settings, "Window Positions", descriptor . ".Height", kUndefined)

	if ((width == kUndefined) || (height == kUndefined))
		return false
	else
		return true
}

translateMsgBoxButtons(buttonLabels, *) {
	local curDetectHiddenWindows := A_DetectHiddenWindows
	local index, label

    DetectHiddenWindows(true)

	try {
		if WinExist("ahk_class #32770 ahk_pid " . ProcessExist()) {
			for index, label in buttonLabels
				try {
					ControlSetText(translate(label), "Button" index)
				}
				catch Any as exception {
					logError(exception)
				}
		}
	}
	finally {
		DetectHiddenWindows(curDetectHiddenWindows)
	}
}

translateYesNoButtons := translateMsgBoxButtons.Bind(["Yes", "No"])
translateOkButton := translateMsgBoxButtons.Bind(["Ok"])
translateOkCancelButtons := translateMsgBoxButtons.Bind(["Ok", "Cancel"])
translateLoadCancelButtons := translateMsgBoxButtons.Bind(["Load", "Cancel"])
translateSaveCancelButtons := translateMsgBoxButtons.Bind(["Save", "Cancel"])

getControllerActionLabels() {
	return getControllerActionDefinitions("Labels")
}

getControllerActionIcons() {
	local icons := getControllerActionDefinitions("Icons")
	local section, values, key, value

	for section, values in icons
		for key, value in values
			values[key] := substituteVariables(value)

	return icons
}