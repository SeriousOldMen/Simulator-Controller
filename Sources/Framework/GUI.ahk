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
;;;                          Local Include Section                          ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\Libraries\Task.ahk"


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

class Window extends Gui {
	iCloseable := false
	iResizeable := false

	iMinWidth := 0
	iMinHeight := 0
	iMaxWidth := 0
	iMaxHeight := 0

	iWidth := 0
	iHeight := 0

	iResizers := []

	iDescriptor := false

	iLastX := false
	iLastY := false

	iRules := []

	class Resizer {
		iWindow := false

		Window {
			Get {
				return this.iWindow
			}
		}

		__New(window) {
			this.iWindow := window
		}

		Initialize() {
		}

		RestrictResize(&deltaWidth, &deltaHeight) {
			return false
		}

		Resize(deltaWidth, deltaHeight) {
		}

		Redraw() {
		}
	}

	class ControlResizer extends Window.Resizer {
		iRule := false
		iCompiledRule := false

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

		Rule[optimized := false] {
			Get {
				return (optimized ? this.iCompiledRule : this.iRule)
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

		__New(window, control, rule) {
			this.iControl := control
			this.iRule := rule

			super.__New(window)

			this.Optimize()
		}

		Initialize() {
			local x, y, w, h

			try {
				ControlGetPos(&x, &y, &w, &h, this.Control)

				this.iOriginalX := x
				this.iOriginalY := y
				this.iOriginalWidth := w
				this.iOriginalHeight := h
			}
			catch Any as exception {
				logError(exception)
			}
		}

		Reset() {
			this.Optimize()
		}

		Optimize() {
			local ignore, part, variable, horizontal, rule, factor, rules

			callRules(rules, &x, &y, &w, &h, dw, dh) {
				local ignore, rule

				for ignore, rule in rules
					rule(&x, &y, &w, &h, dw, dh)
			}

			fastMover(horizontal, variable, factor) {
				move(&x, &y, &w, &h, dw, dh) {
					switch variable, false {
						case "x":
							x += Round((horizontal ? dw : dh) * factor)
						case "y":
							y += Round((horizontal ? dw : dh) * factor)
						case "w":
							w += Round((horizontal ? dw : dh) * factor)
						case "h":
							h += Round((horizontal ? dw : dh) * factor)
						default:
							logError("Unknown variable detected in Resizre.Optimize...")
					}
				}

				return move
			}

			fastGrower := fastMover

			fastCenter(horizontal, variable, factor) {
				if (variable = "h")
					return (&x, &y, &w, &h, dw, dh) => (x := Round((this.Window.Width / 2) - (w / 2)))
				else
					return (&x, &y, &w, &h, dw, dh) => (y := Round((this.Window.Height / 2) - (h / 2)))
			}

			rules := []

			for ignore, part in string2Values(A_Space, this.Rule) {
				part := StrSplit(part, ":", , 2)
				variable := part[1]

				if (variable = "Width")
					variable := "w"
				else if (variable = "Height")
					variable := "h"
				else if (variable = "Horizontal")
					variable := "h"
				else if (variable = "Vertical")
					variable := "v"

				horizontal := ((variable = "x") || (variable = "w"))

				rule := part[2]

				if Instr(rule, "(") {
					rule := StrSplit(rule, "(", " `t)", 2)

					factor := rule[2]
					rule := rule[1]
				}
				else
					factor := 1

				switch rule, false {
					case "Move":
						rules.Push(fastMover(horizontal, variable, factor))
					case "Grow":
						rules.Push(fastGrower(horizontal, variable, factor))
					case "Center":
						rules.Push(fastCenter(horizontal, variable, factor))
				}
			}

			this.iCompiledRule := callRules.Bind(rules)
		}

		RestrictResize(&deltaWidth, &deltaHeight) {
			return false
		}

		Resize(deltaWidth, deltaHeight) {
			local x := this.OriginalX
			local y := this.OriginalY
			local w := this.OriginalWidth
			local h := this.OriginalHeight

			this.Rule[true](&x, &y, &w, &h, deltaWidth, deltaHeight)

			ControlMove(x, y, w, h, this.Control)
		}

		Redraw() {
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

	Closeable {
		Get {
			return this.iCloseable
		}
	}

	Resizeable {
		Get {
			return this.iResizeable
		}
	}

	MinWidth {
		Get {
			return this.iMinWidth
		}

		Set {
			try {
				return (this.iMinWidth := value)
			}
			finally {
				this.Resize("Auto", this.Width, this.Height)
			}
		}
	}

	MinHeight {
		Get {
			return this.iMinHeight
		}

		Set {
			try {
				return (this.iMinHeight := value)
			}
			finally {
				this.Resize("Auto", this.Width, this.Height)
			}
		}
	}

	MaxWidth {
		Get {
			return this.iMaxWidth
		}

		Set {
			try {
				return (this.iMaxWidth := value)
			}
			finally {
				if this.MaxWidth
					this.Opt("+MaxSize" . this.MaxWidth . "x")
				else
					this.Opt("-MaxSize")

				this.Resize("Auto", this.Width, this.Height)
			}
		}
	}

	MaxHeight {
		Get {
			return this.iMaxHeight
		}

		Set {
			try {
				return (this.iMaxHeight := value)
			}
			finally {
				if this.MaxHeight
					this.Opt("+MaxSize" . "x" . this.MaxHeight)
				else
					this.Opt("-MaxSize")

				this.Resize("Auto", this.Width, this.Height)
			}
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

	Rules[asText := true] {
		Get {
			return (asText ? values2String(A_Space, this.iRules*) : this.iRules)
		}

		Set {
			this.iRules := (isObject(value) ? value : ((Trim(value) = "") ? [] : string2Values(A_Space, value)))

			return this.Rules[asText]
		}
	}

	__New(options := {}, name := Strsplit(A_ScriptName, ".")[1], arguments*) {
		local backColor := "D0D0D0"
		local ignore, argument

		for name, argument in options.OwnProps()
			switch name, false {
				case "Closeable":
					this.iCloseable := argument
				case "Resizeable":
					this.iResizeable := argument
				case "Descriptor":
					this.iDescriptor := argument

					if argument
						Task.startTask(ObjBindMethod(this, "UpdatePosition", argument), 2000, kLowPriority)
				case "Options":
					options := argument
				case "BackColor":
					backColor := argument
			}

		super.__New("", name, arguments*)

		this.OnEvent("Close", this.Close)

		if this.Resizeable {
			this.Opt("+Resize")

			this.OnEvent("Size", this.Resize)
		}
		else
			this.Opt("-SysMenu -Border -Caption +0x800000")

		if !isObject(options)
			this.Opt(options)

		this.BackColor := backColor
	}

	Opt(options) {
		super.Opt(options)

		if InStr(options, "-Disabled")
			this.Show("NA")
	}

	Add(type, options := "", arguments*) {
		local rules := false
		local newOptions, ignore, option, control

		if type is Window.Resizer
			return this.AddResizer(type)
		else {
			if RegExMatch(options, "i)[xywhv].*:") {
				newOptions := []
				rules := []

				for ignore, option in string2Values(A_Space, options)
					if RegExMatch(option, "i)[xywhv].*:")
						rules.Push(option)
					else
						newOptions.Push(option)

				options := values2String(A_Space, newOptions*)
			}

			control := super.Add(type, options, arguments*)

			if (rules || this.Rules[false].Length > 0) {
				if !rules
					rules := []

				this.DefineResizeRule(control, values2String(" ", concatenate(this.Rules[false], rules)*))
			}

			return control
		}
	}

	Show(arguments*) {
		local x, y, width, height

		super.Show(arguments*)

		if !this.MinWidth {
			WinGetPos(&x, &y, &width, &height, this)

			this.iMinWidth := width
			this.iMinHeight := height

			this.Opt("MinSize" . width . "x" . height)

			this.iWidth := width
			this.iHeight := height

			for ignore, resizer in this.Resizers
				resizer.Initialize()
		}
	}

	AddResizer(resizer) {
		this.Resizers.Push(resizer)

		return resizer
	}

	DefineResizeRule(control, rule) {
		this.AddResizer(Window.ControlResizer(this, control, rule))
	}

	UpdatePosition(descriptor) {
		local x, y, settings

		try {
			WinGetPos(&x, &y, , , this)

			if (x && y) {
				if (this.iLastX && ((this.iLastX != x) || (this.iLastY != y))) {
					settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

					setMultiMapValue(settings, "Window Positions", descriptor . ".X", x)
					setMultiMapValue(settings, "Window Positions", descriptor . ".Y", y)

					writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)
				}

				this.iLastX := x
				this.iLastY := y
			}
		}
		catch Any {
		}

		return Task.CurrentTask
	}

	Close(*) {
		if this.Closeable
			ExitApp(0)
		else
			return true
	}

	Resize(minMax, width, height) {
		local restricted := false
		local x, y, w, h, ignore, resizer

		static resizeTask := false

		runResizers(synchronous := false) {
			local curPriority, width, height, ignore, button

			if !synchronous {
				for ignore, button in ["LButton", "MButton", "RButton"]
					if GetKeyState(button, "P")
						return Task.CurrentTask

				resizeTask := false
			}

			curPriority := Task.block(kInterruptPriority)

			try {
				WinGetPos( , , &width, &height, this)

				if (width < this.MinWidth) {
					width := this.MinWidth
					restricted := true
				}
				else if (this.MaxWidth && (width > this.MaxWidth)) {
					width := this.MaxWidth
					restricted := true
				}

				if (height < this.MinHeight) {
					height := this.MinHeight
					restricted := true
				}
				else if (this.MaxHeight && (height > this.MaxHeight)) {
					height := this.MaxHeight
					restricted := true
				}

				if this.ControlsRestrictResize(&width, &height)
					restricted := true

				this.iWidth := width
				this.iHeight := height

				this.ControlsResize(width, height)

				if restricted {
					WinMove( , , width, height, this)

					return
				}
				else {
					for ignore, resizer in this.Resizers
						resizer.Redraw()

					WinRedraw(this)

					if this.Descriptor {
						updateSettings(width, height) {
							local settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

							setMultiMapValue(settings, "Window Positions", this.Descriptor . ".Width", width)
							setMultiMapValue(settings, "Window Positions", this.Descriptor . ".Height", height)

							writeMultiMap(kUserConfigDirectory . "Application Settings.ini", settings)
						}

						Task.startTask(updateSettings.Bind(width, height), 1000, kLowPriority)
					}
				}
			}
			catch Any as exception {
				Task.startTask(logError.Bind(exception), 100, kLowPriority)
			}
			finally {
				Task.unblock(curPriority)
			}
		}

		if this.Width
			if InStr(minMax, "Init")
				WinMove( , , width, height, this)
			else if (this.Resizeable = "Deferred") {
				if !resizeTask {
					resizeTask := Task(runResizers, 100)

					resizeTask.start()
				}
			}
			else
				runResizers(true)
	}

	ControlsRestrictResize(&width, &height) {
		local deltaWidth := (width - this.MinWidth)
		local deltaHeight := (height - this.MinHeight)
		local restricted := false
		local ignore, resizer

		for ignore, resizer in this.Resizers
			if resizer.RestrictResize(&deltaWidth, &deltaHeight)
				restricted := true

		if restricted {
			width := (this.MinWidth + deltaWidth)
			height := (this.MinHeight + deltaHeight)
		}

		return restricted
	}

	ControlsResize(width, height) {
		local deltaWidth := (width - this.MinWidth)
		local deltaHeight := (height - this.MinHeight)
		local ignore, resizer

		for ignore, resizer in this.Resizers
			resizer.Resize(deltaWidth, deltaHeight)
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

moveByMouse(window, descriptor := false, *) {
	local curCoordMode := A_CoordModeMouse
	local anchorX, anchorY, winX, winY, x, y, newX, newY, settings

	CoordMode("Mouse", "Screen")

	try {
		MouseGetPos(&anchorX, &anchorY)
		WinGetPos(&winX, &winY, , , window)

		newX := winX
		newY := winY

		while GetKeyState("LButton", "P") {
			MouseGetPos(&x, &y)

			newX := winX + (x - anchorX)
			newY := winY + (y - anchorY)

			window.Move(newX, newY)
		}

		WinGetPos(&winX, &winY, , , window)

		if descriptor {
			settings := readMultiMap(kUserConfigDirectory . "Application Settings.ini")

			setMultiMapValue(settings, "Window Positions", descriptor . ".X", winX)
			setMultiMapValue(settings, "Window Positions", descriptor . ".Y", winY)

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

			if ((posX >= (screenLeft - 50)) && (posX <= (screenRight + 50)) && (posY >= (screenTop - 50)) && (posY <= (screenBottom + 50))) {
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