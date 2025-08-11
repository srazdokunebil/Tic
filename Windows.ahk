; ==========================================
; Tic PixelBot for WoW 3.3.5  (AutoHotkey v2)
; Hold Numpad6 to run; release to stop
; Human-ish cadence with GCD phase bias + noise
; ==========================================
#Requires AutoHotkey v2.0
#SingleInstance Force
SetTitleMatchMode 2

; ----- Pixel coords (match your /tic px; P4 is to the right of P3) -----
p1x := 19, p1y := 18
p2x := 53, p2y := 17
p3x := 82, p3y := 19
p4x := 110, p4y := 16     ; adjust if you offset P4 in-game

WOW_TITLE := "World of Warcraft"

; ----- Canonical colors (must match addon order) -----
C_WHITE  := 0xFFFFFF
C_YELLOW := 0xFFFF00
C_MAG    := 0xFF00FF
C_CYAN   := 0x00FFFF
C_RED    := 0xFF0000
C_BLUE   := 0x0000FF
SIX := [C_WHITE, C_YELLOW, C_MAG, C_CYAN, C_RED, C_BLUE]

; ----- GCD phase colors (from addon P4) -----
C_PHASE_EARLY := 0x0000FF  ; blue
C_PHASE_MID   := 0x00FFFF  ; cyan
C_PHASE_LATE  := 0xFFFF00  ; yellow

; ----- Loop timing + safety -----
SCAN_SLEEP_MS     := 6          ; scanner tick
REFRACTORY_MIN_MS := 55         ; min gap between presses (hard floor)
MISS_CHANCE_EARLY := 0.40       ; chance to skip a press
MISS_CHANCE_MID   := 0.25
MISS_CHANCE_LATE  := 0.08
MISS_CHANCE_NONE  := 0.20
BURST_CHANCE_LATE := 0.22       ; chance to double-tap late
PRESS_DOWN_MS     := 14         ; how long to hold Ctrl before key
PRESS_UP_MS       := 14         ; delay before Ctrl up

; ----- Key maps -----
Combo := Map()
tokens := []
loop 9
    tokens.Push(Format("{}", A_Index))   ; 1..9
tokens.Push("0")                         ; 10 -> 0
loop 26
    tokens.Push(Chr(64 + A_Index))       ; 11..36 -> A..Z
idx := 1
for , c2 in SIX {
    for , c3 in SIX {
        Combo[Format("{}-{}", c2, c3)] := tokens[idx]
        idx += 1
    }
}

KeyToBeep := Map(
    "1", 1000, "2", 1250, "3", 1500, "4", 1750, "5", 2000, "6", 2250,
    "7", 2500, "8", 2750, "9", 3000, "0", 3250,
    "A", 3500, "B", 3750, "C", 4000, "D", 4250, "E", 4500, "F", 4750,
    "G", 5000, "H", 5250, "I", 5500, "J", 5750, "K", 6000, "L", 6250,
    "M", 6500, "N", 6750, "O", 7000, "P", 7250, "Q", 7500, "R", 7750,
    "S", 8000, "T", 8250, "U", 8500, "V", 8750, "W", 9000, "X", 9250,
    "Y", 9500, "Z", 9750
)

; ----- Helpers -----
ReadRGB(x, y) => PixelGetColor(x, y, "RGB")
IsGateOpen()  => ReadRGB(p1x, p1y) = C_WHITE

SnapToSix(c) {
    global SIX
    for , s in SIX
        if (c = s)
            return s
    nearest := SIX[1], best := 0x7FFFFFFF
    ar := (c >> 16) & 0xFF, ag := (c >> 8) & 0xFF, ab := c & 0xFF
    for , s in SIX {
        br := (s >> 16) & 0xFF, bg := (s >> 8) & 0xFF, bb := s & 0xFF
        d := Abs(ar-br) + Abs(ag-bg) + Abs(ab-bb)
        if (d < best) {
            best := d
            nearest := s
        }
    }
    return nearest
}

; Triangular distribution: more natural “human” delays
; Returns integer ms in [min,max], peaking at 'mode'
Tri(min, mode, max) {
    if (mode < min) or (mode > max) {
        mode := (min + max) / 2
    }
    u := Random(0.0, 1.0)
    if (u < (mode - min) / (max - min)) {
        return Floor(min + Sqrt(u * (max - min) * (mode - min)))
    } else {
        return Floor(max - Sqrt((1 - u) * (max - min) * (max - mode)))
    }
}

; Phase-aware delay generator (ms)
; EARLY: lazy (longer), MID: moderate, LATE: frenetic (short)
DelayForPhase(phase) {
    global C_PHASE_EARLY, C_PHASE_MID, C_PHASE_LATE
    if (phase = C_PHASE_LATE) {
        ; very short, biased to the low end
        return Tri(25, 38, 110)
    } else if (phase = C_PHASE_MID) {
        ; medium, broader range
        return Tri(120, 180, 320)
    } else if (phase = C_PHASE_EARLY) {
        ; long-ish, biased to the high end
        return Tri(260, 360, 460)
    } else {
        ; no GCD: neutral scan cadence
        return Tri(140, 180, 260)
    }
}

MissChanceForPhase(phase) {
    global C_PHASE_EARLY, C_PHASE_MID, C_PHASE_LATE
    global MISS_CHANCE_EARLY, MISS_CHANCE_MID, MISS_CHANCE_LATE, MISS_CHANCE_NONE

    if (phase = C_PHASE_LATE) {
        return MISS_CHANCE_LATE
    }
    if (phase = C_PHASE_MID) {
        return MISS_CHANCE_MID
    }
    if (phase = C_PHASE_EARLY) {
        return MISS_CHANCE_EARLY
    }
    return MISS_CHANCE_NONE
}

MaybeBurst(phase) {
    global C_PHASE_LATE, BURST_CHANCE_LATE
    return (phase = C_PHASE_LATE) && (Random(0.0,1.0) < BURST_CHANCE_LATE)
}

PressCtrlToken(token) {
    try {
        if !GetKeyState("Ctrl", "P")
            Send("{Ctrl down}")
        Sleep(PRESS_DOWN_MS + Random(0,8))
        Send("{" token "}")
    } finally {
        Sleep(PRESS_UP_MS + Random(0,8))
        if GetKeyState("Ctrl","P")
            Send("{Ctrl up}")
    }
}

; ----- Hold-to-run on Numpad6 -----
Numpad6::{
    lastPress := A_TickCount - 1000

    try {
        while GetKeyState("Numpad6", "P") {

            ; keep CPU chill
            Sleep(SCAN_SLEEP_MS)

            if !WinActive(WOW_TITLE)
                continue

            ; sample phase-driven scan delay
            phase := ReadRGB(p4x, p4y)
            Sleep(DelayForPhase(phase))

            if !IsGateOpen()
                continue

            ; enforce a refractory window
            since := A_TickCount - lastPress
            if (since < REFRACTORY_MIN_MS)
                continue

            ; tiny human “hesitation” before the actual press
            Sleep(Tri(18, 28, 60))

            ; read colors for action
            raw2 := ReadRGB(p2x, p2y), raw3 := ReadRGB(p3x, p3y)
            s2 := SnapToSix(raw2),     s3 := SnapToSix(raw3)

            key := Combo.Get(Format("{}-{}", s2, s3), "")
            if (key = "")
                continue

            ; miss a press sometimes (especially earlier in the GCD)
            if (Random(0.0,1.0) < MissChanceForPhase(phase))
                continue

            ; beep & press
            if KeyToBeep.Has(key)
                SoundBeep KeyToBeep[key], 90
            PressCtrlToken(key)
            lastPress := A_TickCount

            ; occasional late-GCD double tap with tiny gap
            if MaybeBurst(phase) {
                Sleep(Tri(36, 48, 78))
                if KeyToBeep.Has(key)
                    SoundBeep KeyToBeep[key], 70
                PressCtrlToken(key)
                lastPress := A_TickCount
            }
        }
    } finally {
        if GetKeyState("Ctrl","P")
            Send("{Ctrl up}")
    }
}

; ----- Debug pixel probe -----
!F5::{
	MsgBox "box1color " PixelGetColor(p1x, p1y)
}
!F6::{
	MsgBox "box2color " PixelGetColor(p2x, p2y)
}
!F7::{
	MsgBox "box3color " PixelGetColor(p2x, p2y)
}
F9::{
    MouseGetPos &mx, &my
    MsgBox "X" mx "  Y" my "  color " Format("0x{:06X}", PixelGetColor(mx, my, "RGB"))
}