;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;   Modular Simulator Controller System - Button Box Plugin               ;;;
;;;                                                                         ;;;
;;;   Author:     Oliver Juwig (TheBigO)                                    ;;;
;;;   License:    (2020) Creative Commons - BY-NC-SA                        ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;-------------------------------------------------------------------------;;;
;;;                          Public Classes Section                         ;;;
;;;-------------------------------------------------------------------------;;;

class SimpleButtonBox extends ButtonBox {
	iControlHandles := {}
	
	createWindow(ByRef window, ByRef windowWidth, ByRef windowHeight) {
		Gui SBB:-Border -Caption +AlwaysOnTop

		Gui SBB:Add, Picture, x-10 y-10, % kButtonBoxImagesDirectory . "CF Background.png"
		
		Gui SBB:Font, s12 Bold cSilver
		Gui SBB:Add, Text, x40 y8 w457 h23 +0x200 +0x1 BackgroundTrans, Modular Simulator Controller System
		Gui SBB:Font, s10 cSilver
		Gui SBB:Add, Text, x40 y28 w457 h23 +0x200 +0x1 BackgroundTrans, Button Box
		Gui SBB:Color, 0x000000
		Gui SBB:Add, Picture, x33 y60 w54 h85 BackgroundTrans, % kButtonBoxImagesDirectory . "Toggle Switch.png"
		Gui SBB:Add, Picture, x137 y60 w54 h85 BackgroundTrans, % kButtonBoxImagesDirectory . "Toggle Switch.png"
		Gui SBB:Add, Picture, x241 y60 w54 h85 BackgroundTrans, % kButtonBoxImagesDirectory . "Toggle Switch.png"
		Gui SBB:Add, Picture, x345 y60 w54 h85 BackgroundTrans, % kButtonBoxImagesDirectory . "Toggle Switch.png"
		Gui SBB:Add, Picture, x449 y60 w54 h85 BackgroundTrans, % kButtonBoxImagesDirectory . "Toggle Switch.png"
		Gui SBB:Add, Picture, x40 y196 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x40 y284 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x144 y196 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x248 y196 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x352 y196 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x144 y284 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x248 y284 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x352 y284 w40 h40 BackgroundTrans, % kButtonBoxImagesDirectory . "Push Button.png"
		Gui SBB:Add, Picture, x455 y195 w42 h42 BackgroundTrans, % kButtonBoxImagesDirectory . "Rotary Dial.png"
		Gui SBB:Add, Picture, x455 y283 w42 h42 BackgroundTrans, % kButtonBoxImagesDirectory . "Rotary Dial.png"

		Gui SBB:Add, Text, x32 y148 w56 h30 Hwndtoggle1 +Border -Background  +0x1000 +Center +0x1
		Gui SBB:Add, Text, x136 y148 w56 h30 Hwndtoggle2 +Border -Background  +0x1000 +Center +0x1
		Gui SBB:Add, Text, x240 y148 w56 h30 Hwndtoggle3 +Border -Background  +0x1000 +Center +0x1
		Gui SBB:Add, Text, x344 y148 w56 h30 Hwndtoggle4 +Border -Background  +0x1000 +Center +0x1
		Gui SBB:Add, Text, x448 y148 w56 h30 Hwndtoggle5 +Border -Background  +0x1000 +Center +0x1

		Gui SBB:Add, Text, x32 y239 w56 h30 Hwndbutton1 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x136 y239 w56 h30 Hwndbutton2 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x240 y239 w56 h30 Hwndbutton3 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x344 y239 w56 h30 Hwndbutton4 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x32 y327 w56 h30 Hwndbutton5 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x135 y327 w56 h30 Hwndbutton6 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x240 y327 w56 h30 Hwndbutton7 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x344 y327 w56 h30 Hwndbutton8 +Border -Background  +0x1000 +0x1

		Gui SBB:Add, Text, x448 y239 w56 h30 Hwnddial1 +Border -Background  +0x1000 +0x1
		Gui SBB:Add, Text, x448 y327 w56 h30 Hwnddial2 +Border -Background  +0x1000 +0x1

		Gui SBB:+AlwaysOnTop
			
		controlHandles := Object()
		
		Loop 5 {
			toggle := "toggle" . A_Index
		
			controlHandles[ConfigurationItem.descriptor(k2WayToggleType, A_Index)] := %toggle%
		}

		Loop 8 {
			button := "button" . A_Index
		
			controlHandles[ConfigurationItem.descriptor(kButtonType, A_Index)] := %button%
		}

		Loop 2 {
			dial := "dial" . A_Index
		
			controlHandles[ConfigurationItem.descriptor(kDialType, A_Index)] := %dial%
		}
		
		this.iControlHandles := controlHandles
		
		window := "SBB"
		windowWidth := 543
		windowHeight := 368
	}
	
	getControlHandle(descriptor) {
		if this.iControlHandles.HasKey(descriptor)
			return this.iControlHandles[descriptor]
		else
			return false
	}
}

initializeButtonBoxPlugin() {
	new SimpleButtonBox(SimulatorController.Instance, SimulatorController.Instance.Configuration)
}


;;;-------------------------------------------------------------------------;;;
;;;                         Initialization Section                          ;;;
;;;-------------------------------------------------------------------------;;;

initializeButtonBoxPlugin()