#Requires AutoHotKey v2.0

p1x := 12
p1y := 8
p2x := 36
p2y := 8
p3x := 58
p3y := 8


; DEBUG
!F5::{
	MsgBox "box1color " PixelGetColor(p1x, p1y)
}
!F6::{
	MsgBox "box2color " PixelGetColor(p2x, p2y)
}
!F7::{
	MsgBox "box3color " PixelGetColor(p2x, p2y)
}
!F9::{
    MouseGetPos &mx, &my
    MsgBox "X" mx " Y" my "  color " Format("0x{:06X}", PixelGetColor(mx, my, "RGB"))
}

Numpad6::{
	rand_delay := Random(1,3)
	padd := 0
	if (rand_delay == 2)
		padd := Random(0, 120)

	num := Random(125, 350) + padd
	while(GetKeyState("Numpad6")){

		;SoundBeep 1000, 300  ; 1000 Hz for 300 ms

		if WinActive("World of Warcraft") {

			;SoundBeep 1000, 300  ; 1000 Hz for 300 ms

			;num5StateInner := GetKeyState("Numpad5", "P")
			;if (num5StateInner != "D")
			;	break  ; exit if keys released

			box1color := PixelGetColor(p1x, p1y, "RGB")
			box2color := PixelGetColor(p2x, p2y, "RGB")
			box3color := PixelGetColor(p3x, p3y, "RGB")

			if (box1color = 0xFFFFFF) {

				;SoundBeep 1000, 300  ; 1000 Hz for 300 ms

				ctrlState := GetKeyState("Ctrl")
				if (ctrlState = "D") {
					Send("{Ctrl up}")
				}

				Send("{Ctrl down}")
				Sleep(200)

				;--------------------
				if (box2color = 0xFFFFFF) {  ; WHITE
					if (box3color = 0xFFFFFF) {
						SoundBeep 1000, 300  ; 1000 Hz for 300 ms
						Send("{1}")
					} else if (box3color = 0xFFFF00) {
						SoundBeep 1250, 300  ; 1000 Hz for 300 ms
						Send("{2}")
					} else if (box3color = 0xFF00FF) {
						SoundBeep 1500, 300  ; 1000 Hz for 300 ms
						Send("{3}")
					} else if (box3color = 0x00FFFF) {
						SoundBeep 1750, 300  ; 1000 Hz for 300 ms
						Send("{4}")
					} else if (box3color = 0xFF0000) {
						SoundBeep 2000, 300  ; 1000 Hz for 300 ms
						Send("{5}")
					} else if (box3color = 0x0000FF) {
						SoundBeep 2250, 300  ; 1000 Hz for 300 ms
						Send("{6}")
					}

				} else if (box2color = 0xFFFF00) {  ; YELLOW
					if (box3color = 0xFFFFFF) {
						SoundBeep 2500, 300  ; 1000 Hz for 300 ms
						Send("{7}")
					} else if (box3color = 0xFFFF00) {
						SoundBeep 2750, 300  ; 1000 Hz for 300 ms
						Send("{8}")
					} else if (box3color = 0xFF00FF) {
						SoundBeep 3000, 300  ; 1000 Hz for 300 ms
						Send("{9}")
					} else if (box3color = 0x00FFFF) {
						SoundBeep 3250, 300  ; 1000 Hz for 300 ms
						Send("{0}")
					} else if (box3color = 0xFF0000) {
						SoundBeep 3500, 300  ; 1000 Hz for 300 ms
						Send("{a}")
					} else if (box3color = 0x0000FF) {
						SoundBeep 3750, 300  ; 1000 Hz for 300 ms
						Send("{b}")
					}

				} else if (box2color = 0xFF00FF) {  ; MAGENTA
					if (box3color = 0xFFFFFF) {
						Send("{c}")
					} else if (box3color = 0xFFFF00) {
						Send("{d}")
					} else if (box3color = 0xFF00FF) {
						Send("{e}")
					} else if (box3color = 0x00FFFF) {
						Send("{f}")
					} else if (box3color = 0xFF0000) {
						Send("{g}")
					} else if (box3color = 0x0000FF) {
						Send("{h}")
					}
				}
				else
				{

				}
				Send("{Ctrl up}")
				Sleep(num)
			}
			Sleep(10)  ; prevent 100% CPU usage
		}
	}
	Sleep num
}



