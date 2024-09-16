﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Telemetry Browser               ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2024) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                         Local Include Section                           ;;;
;;;-------------------------------------------------------------------------;;;

#Include "..\..\Libraries\HTMLViewer.ahk"


;;;-------------------------------------------------------------------------;;;
;;;                        Private Variables Section                        ;;;
;;;-------------------------------------------------------------------------;;;

;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class TelemetryChart {
	static sChartID := 1

	iWindow := false
	iTelemetryViewer := false

	iZoom := 100

	Window {
		Get {
			return this.iWindow
		}
	}

	TelemetryViewer {
		Get {
			return this.iTelemetryViewer
		}
	}

	Zoom {
		Get {
			return this.iZoom
		}

		Set {
			return (this.iZoom := value)
		}
	}

	__New(window, telemetryViewer := false) {
		this.iWindow := window
		this.iTelemetryViewer := telemetryViewer
	}

	showLapTelemetry(lapFileName, referenceLapFileName := false) {
		if this.TelemetryViewer {
			this.TelemetryViewer.document.open()
			this.TelemetryViewer.document.write(this.createTelemetryContent(lapFileName, referenceLapFileName))
			this.TelemetryViewer.document.close()
		}
	}

	createTelemetryContent(lapFileName, referenceLapFileName := false, margin := 0) {
		local lapTelemetry := []
		local referenceLapTelemetry := false
		local html := ""
		local width, height
		local drawChartFunction1, chartID1, chartArea1, drawChartFunction2, chartID2, chartArea2
		local before, after, margins
		local entry, index, field, running

		if lapFileName
			loop Read, lapFileName {
				entry := string2Values(";", A_LoopReadLine)

				for index, value in entry
					if !isNumber(value)
						entry[index] := kNull

				lapTelemetry.Push(entry)
			}

		if referenceLapFileName {
			referenceLapTelemetry := Map()

			loop Read, referenceLapFileName {
				entry := string2Values(";", A_LoopReadLine)

				running := kNull

				for index, value in entry
					if !isNumber(value)
						entry[index] := kNull
					else if (index = 1)
						running := entry[index] := (Round(entry[index] / 10) * 10)

				referenceLapTelemetry[running] := entry
			}
		}

		if this.TelemetryViewer {
			width := ((this.TelemetryViewer.getWidth() - 4) / 100 * this.Zoom)
			height := (this.TelemetryViewer.getHeight() - 4)

			chartArea1 := this.createSpeedChart(width, height / 3 * 2, lapTelemetry, referenceLapTelemetry, &drawChartFunction1, &chartID1)
			chartArea2 := this.createElectronicsChart(width, height / 3, lapTelemetry, referenceLapTelemetry, &drawChartFunction2, &chartID2)

			before := "
			(
				<meta charset='utf-8'>
				<head>
					<style>
						.headerStyle { height: 25; font-size: 11px; font-weight: 500; background-color: #%headerBackColor%; }
						.rowStyle { font-size: 11px; color: #%fontColor%; background-color: #%evenRowBackColor%; }
						.oddRowStyle { font-size: 11px; color: #%fontColor%; background-color: #%oddRowBackColor%; }
					</style>
					<script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>
					<script type="text/javascript">function drawCharts() { drawChart%chartID1%(); drawChart%chartID2%() }</script>
					<script type="text/javascript">
						google.charts.load('current', {'packages':['corechart', 'table', 'scatter']}).then(drawCharts);
			)"

			before := substituteVariables(before, {fontColor: this.Window.Theme.TextColor
												 , headerBackColor: this.Window.Theme.ListBackColor["Header"]
												 , evenRowBackColor: this.Window.Theme.ListBackColor["EvenRow"]
												 , oddRowBackColor: this.Window.Theme.ListBackColor["OddRow"]
												 , chartID1: chartID1, chartID2: chartID2})

			after := "
			(
					</script>
				</head>
			)"

			margins := substituteVariables("style='overflow: auto' leftmargin='%margin%' topmargin='%margin%' rightmargin='%margin%' bottommargin='%margin%'"
										 , {margin: margin})

			return ("<html>" . before . drawChartFunction1 . "`n" . drawChartFunction2 . after . "<body style='background-color: #" . this.Window.AltBackColor . "' " . margins . "><style> div, table { color: '" . this.Window.Theme.TextColor . "'; font-family: Arial, Helvetica, sans-serif; font-size: 11px }</style><style> #header { font-size: 12px; } table, p, div { color: #" . this.Window.Theme.TextColor . " } </style>" . chartArea1 . chartArea2 . "</body></html>")
		}
		else
			return "<html></html>"
	}

	createSpeedChart(width, height, lapTelemetry, referenceLapTelemetry, &drawChartFunction, &chartID) {
		local speedMin := 9999
		local speedMax := 0
		local ignore, data, refData, axes, speed, refSpeed, color, running

		chartID := TelemetryChart.sChartID++
		drawChartFunction := ("function drawChart" . chartID . "() {`nvar data = new google.visualization.DataTable();")

		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Distance") . "');")

		if referenceLapTelemetry {
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Speed (Reference)") . "');")
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Throttle (Reference)") . "');")
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Brake (Reference)") . "');")
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Steering (Reference)") . "');")
		}

		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Speed") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Throttle") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Brake") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Steering") . "');")

		drawChartFunction .= "`ndata.addRows(["

		for ignore, data in lapTelemetry {
			if (A_Index = 1)
				continue
			else if (A_Index > 2)
				drawChartFunction .= ", "

			running := data[1]
			speed := data[7]

			if (speed > 0) {
				speed := convertUnit("Speed", speed)

				speedMin := Min(speedMin, speed)
				speedMax := Max(speedMax, speed)
			}
			else
				speed := kNull

			if referenceLapTelemetry {
				running := (Round(running / 10) * 10)

				if referenceLapTelemetry.Has(running) {
					refData := referenceLapTelemetry[running]

					refSpeed := refData[7]

					if (refSpeed = 0)
						refSpeed := kNull

					drawChartFunction .= ("[" . running . ", " . refSpeed . ", " . refData[2] . ", " . refData[3] . ", " . refData[4] . ", " . speed . ", " . data[2] . ", " . data[3] . ", " . data[4] . "]")
				}
				else
					drawChartFunction .= ("[" . running . ", null, null, null, null, " . speed . ", " . data[2] . ", " . data[3] . ", " . data[4] . "]")
			}
			else
				drawChartFunction .= ("[" . running . ", " . speed . ", " . data[2] . ", " . data[3] . ", " . data[4] . "]")
		}

		if referenceLapTelemetry {
			color := this.Window.Theme.TextColor["Disabled"]

			axes := "series: { 0: {targetAxisIndex: 0, color: '" . color . "'}, 1: {targetAxisIndex: 1, color: '" . color . "'}, 2: {targetAxisIndex: 2, color: '" . color . "'}, 3: {targetAxisIndex: 3, color: '" . color . "'}, 4: {targetAxisIndex: 4}, 5: {targetAxisIndex: 5}, 6: {targetAxisIndex: 6}, 7: {targetAxisIndex: 7} },`n"
			axes .= "hAxes: {gridlines: {count: 0}, ticks: []}, vAxes: { 0: { gridlines: {count: 0}, ticks: [], minValue: " . (speedMax - ((speedMax - speedMin) * 3)) . " }, 1: { gridlines: {count: 0}, ticks: [], minValue : -2, maxValue: 5 }, 2: { gridlines: {count: 0}, ticks: [], minValue: -2, maxValue: 5 }, 3: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 }, 4: { gridlines: {count: 0}, ticks: [], minValue: " . (speedMax - ((speedMax - speedMin) * 3)) . " }, 5: { gridlines: {count: 0}, ticks: [], minValue : -2, maxValue: 5 }, 6: { gridlines: {count: 0}, ticks: [], minValue: -2, maxValue: 5 },  7: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 } }"
		}
		else {
			axes := "series: { 0: {targetAxisIndex: 0}, 1: {targetAxisIndex: 1}, 2: {targetAxisIndex: 2}, 3: {targetAxisIndex: 3} },`n"
			axes .= "hAxes: {gridlines: {count: 0}, ticks: []}, vAxes: { 0: { gridlines: {count: 0}, ticks: [], minValue: " . (speedMax - ((speedMax - speedMin) * 3)) . " }, 1: { gridlines: {count: 0}, ticks: [], minValue : -2, maxValue: 5 }, 2: { gridlines: {count: 0}, ticks: [], minValue: -2, maxValue: 5 }, 3: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 } }"
		}

		drawChartFunction .= ("]);`nvar options = { " . axes . ", legend: { position: 'bottom', textStyle: { color: '" . this.Window.Theme.TextColor . "'} }, chartArea: { left: '2%', top: '5%', right: '2%', bottom: '20%' }, backgroundColor: '" . this.Window.AltBackColor . "' };`n")

		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return ("<div id=`"chart_" . chartID . "`" style=`"width: " . Round(width) . "px; height: " . Round(height) . "px`"></div>")
	}

	createElectronicsChart(width, height, lapTelemetry, referenceLapTelemetry, &drawChartFunction, &chartID) {
		local rpmsMin := 99999
		local rpmsMax := 0
		local ignore, data, refData, rpms, refRpms, rpmsMin, rpmsMax, axes, color, running

		chartID := TelemetryChart.sChartID++
		drawChartFunction := ("function drawChart" . chartID . "() {`nvar data = new google.visualization.DataTable();")

		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Distance") . "');")

		if referenceLapTelemetry {
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("RPMS (Reference)") . "');")
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Gear (Reference)") . "');")
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("TC (Reference)") . "');")
			drawChartFunction .= ("`ndata.addColumn('number', '" . translate("ABS (Reference)") . "');")
		}

		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("RPMS") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("Gear") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("TC") . "');")
		drawChartFunction .= ("`ndata.addColumn('number', '" . translate("ABS") . "');")

		drawChartFunction .= "`ndata.addRows(["

		for ignore, data in lapTelemetry {
			if (A_Index = 1)
				continue
			else if (A_Index > 2)
				drawChartFunction .= ", "

			running := data[1]
			rpms := data[6]

			if (rpms > 0) {
				rpmsMin := Min(rpmsMin, rpms)
				rpmsMax := Max(rpmsMax, rpms)
			}
			else
				rpms := kNull

			if referenceLapTelemetry {
				running := (Round(running / 10) * 10)

				if referenceLapTelemetry.Has(running) {
					refData := referenceLapTelemetry[running]

					refRpms := refData[6]

					if (refRpms = 0)
						refRpms := kNull

					drawChartFunction .= ("[" . running . ", " . refRpms . ", " . refData[5] . ", " . refData[8] . ", " . refData[9] . ", " . rpms . ", " . data[5] . ", " . data[8] . ", " . data[9] . "]")
				}
				else
					drawChartFunction .= ("[" . running . ", null, null, null, null, " . rpms . ", " . data[5] . ", " . data[8] . ", " . data[9] . "]")
			}
			else
				drawChartFunction .= ("[" . running . ", " . rpms . ", " . data[5] . ", " . data[8] . ", " . data[9] . "]")
		}

		if referenceLapTelemetry {
			color := this.Window.Theme.TextColor["Disabled"]

			axes := "series: { 0: {targetAxisIndex: 0, color: '" . color . "'}, 1: {targetAxisIndex: 1, color: '" . color . "'}, 2: {targetAxisIndex: 2, color: '" . color . "'}, 3: {targetAxisIndex: 3, color: '" . color . "'}, 4: {targetAxisIndex: 4}, 5: {targetAxisIndex: 5}, 6: {targetAxisIndex: 6}, 7: {targetAxisIndex: 7} },`n"
			axes .= "hAxes: {gridlines: {count: 0}, ticks: []}, vAxes: { 0: { gridlines: {count: 0}, ticks: [], minValue: " . (rpmsMax - ((rpmsMax - rpmsMin) * 3)) . " }, 1: { gridlines: {count: 0}, ticks: [], minValue : -2, maxValue: 10 }, 2: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 }, 3: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 }, 4: { gridlines: {count: 0}, ticks: [], minValue: " . (rpmsMax - ((rpmsMax - rpmsMin) * 3)) . " }, 5: { gridlines: {count: 0}, ticks: [], minValue : -2, maxValue: 10 }, 6: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 },  7: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 } }"
		}
		else {
			axes := "series: { 0: {targetAxisIndex: 0}, 1: {targetAxisIndex: 1}, 2: {targetAxisIndex: 2}, 3: {targetAxisIndex: 3} },`n"
			axes .= "hAxes: {gridlines: {count: 0}, ticks: []}, vAxes: { 0: { gridlines: {count: 0}, ticks: [], minValue: " . (rpmsMax - ((rpmsMax - rpmsMin) * 3)) . " }, 1: { gridlines: {count: 0}, ticks: [], minValue : -2, maxValue: 10 }, 2: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 }, 3: { gridlines: {count: 0}, ticks: [], minValue: -1, maxValue: 5 } }"
		}

		drawChartFunction .= ("]);`nvar options = { " . axes . ", legend: { position: 'bottom', textStyle: { color: '" . this.Window.Theme.TextColor . "'} }, chartArea: { left: '2%', top: '5%', right: '2%', bottom: '20%' }, backgroundColor: '" . this.Window.AltBackColor . "' };`n")

		drawChartFunction .= ("`nvar chart = new google.visualization.LineChart(document.getElementById('chart_" . chartID . "')); chart.draw(data, options); }")

		return ("<div id=`"chart_" . chartID . "`" style=`"width: " . Round(width) . "px; height: " . Round(height) . "px`"></div>")
	}
}

class TelemetryBrowser {
	iManager := false

	iTelemetryDirectory := false
	iTelemetryCollectorPID := false

	iWindow := false
	iTelemetryChart := false

	iLaps := []

	iLap := false
	iReferenceLap := false

	iCollectorTask := false

	class TelemetryBrowserWindow extends Window {
		iBrowser := false

		__New(browser, arguments*) {
			this.iBrowser := browser

			super.__New(arguments*)
		}

		Close(*) {
			this.iBrowser.Close()
		}
	}

	class TelemetryBrowserResizer extends Window.Resizer {
		iTelemetryBrowser := false
		iRedraw := false

		__New(telemetryBrowser, arguments*) {
			this.iTelemetryBrowser := telemetryBrowser

			super.__New(arguments*)

			Task.startTask(ObjBindMethod(this, "RedrawHTMLViewer"), 500, kHighPriority)
		}

		Resize(deltaWidth, deltaHeight) {
			this.iRedraw := true
		}

		RedrawHTMLViewer() {
			if this.iRedraw
				try {
					local ignore, button

					for ignore, button in ["LButton", "MButton", "RButton"]
						if GetKeyState(button)
							return Task.CurrentTask

					this.iRedraw := false

					this.iTelemetryBrowser.TelemetryChart.TelemetryViewer.Resized()

					Task.startTask(ObjBindMethod(this.iTelemetryBrowser, "updateTelemetryChart", true))
				}
				catch Any as exception {
					logError(exception)
				}
				finally {
					this.iRedraw := false
				}

			return Task.CurrentTask
		}
	}

	Manager {
		Get {
			return this.iManager
		}
	}

	TelemetryDirectory {
		Get {
			return this.iTelemetryDirectory
		}
	}

	ReadOnly {
		Get {
			return !this.iCollectorTask
		}
	}

	Window {
		Get {
			return this.iWindow
		}
	}

	Control[name] {
		Get {
			return this.Window[name]
		}
	}

	TelemetryChart {
		Get {
			return this.iTelemetryChart
		}
	}

	Laps {
		Get {
			return this.iLaps
		}

		Set {
			return (this.iLaps := value)
		}
	}

	SelectedLap[path := false] {
		Get {
			return (this.iLap ? (path ? (this.TelemetryDirectory . "Lap " . this.iLap . ".telemetry")
									  : this.iLap)
							  : false)
		}

		Set {
			this.iLap := value

			this.updateTelemetryChart(true)

			return value
		}
	}

	SelectedReferenceLap[path := false] {
		Get {
			return (this.iReferenceLap ? (path ? (this.TelemetryDirectory . "Lap " . this.iReferenceLap . ".telemetry")
											   : this.iLap)
									   : false)
		}

		Set {
			this.iReferenceLap := value

			this.updateTelemetryChart(true)

			return value
		}
	}

	__New(manager, directory, collect := true) {
		local laps := []
		local name

		this.iManager := manager
		this.iTelemetryDirectory := (normalizeDirectoryPath(directory) . "\")

		loop Files, this.TelemetryDirectory . "*.telemetry" {
			SplitPath(A_LoopFileName, , , , &name)

			laps.Push(Integer(StrReplace(name, "Lap ", "")))
		}

		bubbleSort(&laps)

		this.iLaps := laps

		if collect
			OnExit(ObjBindMethod(this, "shutdownTelemetryCollector", true))
	}

	createGui() {
		local browserGui := TelemetryBrowser.TelemetryBrowserWindow(this, {Descriptor: "Telemetry Browser", Closeable: true, Resizeable:  "Deferred"}, translate("Telemetry"))
		local telemetryViewer

		changeZoom(*) {
			this.TelemetryChart.Zoom := browserGui["zoomSlider"].Value

			this.updateTelemetryChart(true)
		}

		chooseLap(*) {
			this.selectLap(browserGui["lapDropDown"].Text)
		}

		chooseReferenceLap(*) {
			this.selectReferenceLap(browserGui["referenceLapDropDown"].Text)
		}

		this.iWindow := browserGui

		browserGui.SetFont("s10 Bold", "Arial")

		browserGui.Add("Text", "w656 H:Center Center", translate("Modular Simulator Controller System")).OnEvent("Click", moveByMouse.Bind(browserGui, "Telemetry Browser"))

		browserGui.SetFont("s9 Norm", "Arial")

		browserGui.Add("Documentation", "x176 YP+20 w336 H:Center Center", translate("Telemetry Browser")
					 , "https://github.com/SeriousOldMan/Simulator-Controller/wiki/Solo-Center#Telemetry-Browser")

		browserGui.Add("Text", "x8 yp+30 w656 W:Grow 0x10")

		browserGui.SetFont("s8 Norm", "Arial")

		browserGui.Add("Text", "x16 yp+10 w80", translate("Lap"))
		browserGui.Add("DropDownList", "x98 yp-4 w296 vlapDropDown", this.Laps).OnEvent("Change", chooseLap)

		browserGui.Add("Text", "x16 yp+28 w80", translate("Reference"))
		browserGui.Add("DropDownList", "x98 yp-4 w296 Choose1 vreferenceLapDropDown", concatenate([translate("None")], this.Laps)).OnEvent("Change", chooseReferenceLap)

		browserGui.Add("Text", "x468 yp+4 w80 X:Move", translate("Zoom"))
		browserGui.Add("Slider", "Center Thick15 x556 yp-2 X:Move w100 0x10 Range100-400 ToolTip vzoomSlider", 100).OnEvent("Change", changeZoom)

		telemetryViewer := browserGui.Add("HTMLViewer", "x16 yp+26 w640 h480 W:Grow H:Grow Border")

		telemetryViewer.document.open()
		telemetryViewer.document.write("")
		telemetryViewer.document.close()

		this.iTelemetryChart := TelemetryChart(browserGui, telemetryViewer)

		browserGui.Add(TelemetryBrowser.TelemetryBrowserResizer(this, telemetryViewer))

		if (this.Laps.Length > 0)
			this.selectLap(this.Laps[1])
	}

	show() {
		local x, y, w, h

		this.createGui()

		if getWindowPosition("Telemetry Browser", &x, &y)
			this.Window.Show("x" . x . " y" . y)
		else
			this.Window.Show()

		if getWindowSize("Telemetry Browser", &w, &h)
			this.Window.Resize("Initialize", w, h)

		this.updateTelemetryChart(true)
	}

	startup(simulator, trackLength) {
		if !this.iTelemetryCollectorPID
			this.startupTelemetryCollector(simulator, trackLength)
	}

	shutdown() {
		this.shutdownTelemetryCollector()
	}

	clear() {
		this.selectLap(false, true)
		this.selectReferenceLap(false, true)

		this.Laps := []
	}

	close() {
		this.shutdownTelemetryCollector(true)

		this.Manager.closedTelemetryBrowser()

		this.Window.Destroy()
	}

	selectLap(lap, force := false) {
		if (force || (lap != this.SelectedLap)) {
			this.SelectedLap := lap

			this.Control["lapDropDown"].Choose(inList(this.Laps, lap))
		}
	}

	selectReferenceLap(lap, force := false) {
		if (lap = translate("None"))
			lap := false

		if (force || (lap != this.SelectedReferenceLap)) {
			this.SelectedReferenceLap := lap

			this.Control["referenceLapDropDown"].Choose(lap ? (inList(this.Laps, lap) + 1) : 1)
		}
	}

	startupTelemetryCollector(simulator, trackLength) {
		local code, exePath, pid

		if this.iTelemetryCollectorPID
			this.shutdownTelemetryCollector(true)

		code := SessionDatabase.getSimulatorCode(simulator)
		exePath := (kBinariesDirectory . "Providers\" . code . " SHM Spotter.exe")
		pid := false

		try {
			if !FileExist(exePath)
				throw "File not found..."

			Run("`"" . exePath . "`" -Telemetry " . trackLength . " `"" . normalizeDirectoryPath(this.TelemetryDirectory) . "`""
			  , kBinariesDirectory, "Hide", &pid)
		}
		catch Any as exception {
			logError(exception, true)

			logMessage(kLogCritical, substituteVariables(translate("Cannot start %simulator% %protocol% Spotter (")
													   , {simulator: code, protocol: "SHM"})
								   . exePath . translate(") - please rebuild the applications in the binaries folder (")
								   . kBinariesDirectory . translate(")"))

			showMessage(substituteVariables(translate("Cannot start %simulator% %protocol% Spotter (%exePath%) - please check the configuration...")
										  , {exePath: exePath, simulator: code, protocol: "SHM"})
					  , translate("Modular Simulator Controller System"), "Alert.png", 5000, "Center", "Bottom", 800)
		}

		if pid {
			this.iTelemetryCollectorPID := pid

			this.iCollectorTask := PeriodicTask(ObjBindMethod(this, "collectTelemetry"), 10000, kLowPriority)

			this.iCollectorTask.start()
		}
	}

	shutdownTelemetryCollector(force := false, arguments*) {
		local pid := this.iTelemetryCollectorPID
		local tries

		if ((arguments.Length > 0) && inList(["Logoff", "Shutdown"], arguments[1]))
			return false

		if pid {
			ProcessClose(pid)

			Sleep(500)

			if (force && ProcessExist(pid)) {
				tries := 5

				while (tries-- > 0) {
					pid := ProcessExist(pid)

					if pid {
						ProcessClose(pid)

						Sleep(500)
					}
					else
						break
				}
			}

			this.iTelemetryCollectorPID := false

			if this.iCollectorTask {
				this.iCollectorTask.stop()

				this.iCollectorTask := false
			}
		}

		return false
	}

	collectTelemetry() {
		local laps := []
		local lap, name

		newLap(lap) {
			local file

			if !inList(this.Laps, lap) {
				try {
					file := FileOpen(this.TelemetryDirectory . "Lap " . lap . ".telemetry", "r-wd")

					if file {
						file.Close()

						return true
					}
					else
						return false
				}
				catch Any {
					return false
				}
			}
			else
				return false
		}

		loop Files, this.TelemetryDirectory . "*.telemetry" {
			SplitPath(A_LoopFileName, , , , &name)

			lap := Integer(StrReplace(name, "Lap ", ""))

			if newLap(lap)
				laps.Push(lap)
		}

		laps := bubbleSort(&laps)

		this.Laps := concatenate(this.Laps, laps)

		this.Control["lapDropDown"].Add(laps)
		this.Control["referenceLapDropDown"].Add(laps)

		if (!this.SelectedLap && (laps.Length > 0))
			this.selectlap(laps[1])
	}

	updateTelemetryChart(redraw := false) {
		if (this.TelemetryChart && redraw)
			this.TelemetryChart.showLapTelemetry(this.SelectedLap[true], this.SelectedReferenceLap[true])
	}
}