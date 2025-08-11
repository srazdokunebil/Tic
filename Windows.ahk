; ==========================================
; Tic PixelBot for WoW 3.3.5  (AutoHotkey v2)
; Hold Numpad6 to run; release to stop
; Human-like cadence around GCD
; ==========================================
#Requires AutoHotKey v2.0
#SingleInstance Force
SetTitleMatchMode 2

; ---------- Pixel coords (match /tic px) ----------
p1x := 12, p1y := 8    ; gate (white = fire)
p2x := 36, p2y := 8
p3x := 58, p3y := 8

; ---------- Target window ----------
WOW_TITLE := "World of Warcraft"

; ---------- Timing ----------
SCAN_SLEEP_MS := 10

; Base jitter before a keypress IF we’re going to press right now
PRESS_MIN_MS  := 40
PRESS_MAX_MS  := 120

; Human cadence model
GCD_MS        := 1500       ; typical base GCD in Wrath (adjust for haste if you want)
BURST_MS      := 300        ; “mash more” during the last this-many ms of the GCD
COAST_MIN_MS  := 180        ; earlier in the cycle, slower taps…
COAST_MAX_MS  := 360
BURST_MIN_MS  := 40         ; near end of GCD, faster taps…
BURST_MAX_MS  := 110
STUTTER_ODDS  := 0.12       ; ~12% of actions add a tiny extra pause
STUTTER_MIN   := 40
STUTTER_MAX   := 140

; ---------- Canonical colors (must match addon order) ----------
C_WHITE  := 0xFFFFFF
C_YELLOW := 0xFFFF00
C_MAG    := 0xFF00FF
C_CYAN   := 0x00FFFF
C_RED    := 0xFF0000
C_BLUE   := 0x0000FF
SIX := [C_WHITE, C_YELLOW, C_MAG, C_CYAN, C_RED, C_BLUE]

; ---------- Snap a read color to nearest of SIX ----------
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

; ---------- Build 36‑combo → key map (1..9, 0, A..Z) ----------
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

; ---------- Key → beep frequency map ----------
KeyToBeep := Map(
    "1", 1000, "2", 1250, "3", 1500, "4", 1750, "5", 2000, "6", 2250,
    "7", 2500, "8", 2750, "9", 3000, "0", 3250,
    "A", 3500, "B", 3750, "C", 4000, "D", 4250, "E", 4500, "F", 4750,
    "G", 5000, "H", 5250, "I", 5500, "J", 5750, "K", 6000, "L", 6250,
    "M", 6500, "N", 6750, "O", 7000, "P", 7250, "Q", 7500, "R", 7750,
    "S", 8000, "T", 8250, "U", 8500, "V", 8750, "W", 9000, "X", 9250,
    "Y", 9500, "Z", 9750
)

; ---------- Helpers ----------
ReadRGB(x, y) => PixelGetColor(x, y, "RGB")
IsGateOpen()  => ReadRGB(p1x, p1y) = C_WHITE

PressCtrlToken(token) {
    try {
        if !GetKeyState("Ctrl", "P")
            Send("{Ctrl down}")
        Sleep(18 + Random(0,6))
        Send("{" token "}")
    } finally {
        Sleep(16 + Random(0,6))
        if GetKeyState("Ctrl","P")
            Send("{Ctrl up}")
    }
}

; Human cadence delay: more taps near end of GCD, lazier earlier
HumanDelay(msSinceLastFire) {
    global GCD_MS, BURST_MS, COAST_MIN_MS, COAST_MAX_MS, BURST_MIN_MS, BURST_MAX_MS
    ; v2: use Mod(a,b), not %.
    remaining := GCD_MS - Mod(msSinceLastFire, GCD_MS)
    if (remaining <= BURST_MS) {
        return Random(BURST_MIN_MS, BURST_MAX_MS)
    } else {
        return Random(COAST_MIN_MS, COAST_MAX_MS)
    }
}

; Optional micro-stutter sometimes
MaybeStutter() {
    global STUTTER_ODDS, STUTTER_MIN, STUTTER_MAX
    if (Random(0.0, 1.0) <= STUTTER_ODDS) {
        Sleep(Random(STUTTER_MIN, STUTTER_MAX))
    }
}

; ---------- Hold-to-run on Numpad6 ----------
Numpad6::{
    lastFire := A_TickCount  ; “start of GCD” reference
    try {
        while GetKeyState("Numpad6", "P") {
            if !WinActive(WOW_TITLE) {
                Sleep(SCAN_SLEEP_MS)
                continue
            }

            ; human cadence sleep (simulates rhythm even before gate opens)
            Sleep(HumanDelay(A_TickCount - lastFire))

            if !IsGateOpen() {
                Sleep(SCAN_SLEEP_MS)
                continue
            }

            ; small jitter just before the actual press
            Sleep(Random(PRESS_MIN_MS, PRESS_MAX_MS))

            raw2 := ReadRGB(p2x, p2y), raw3 := ReadRGB(p3x, p3y)
            s2 := SnapToSix(raw2),     s3 := SnapToSix(raw3)

            key := Combo.Get(Format("{}-{}", s2, s3), "")
            if (key != "") {
                if KeyToBeep.Has(key)
                    SoundBeep KeyToBeep[key], 110
                MaybeStutter()
                PressCtrlToken(key)
                lastFire := A_TickCount  ; reset our GCD phase
            }

            Sleep(SCAN_SLEEP_MS)
        }
    } finally {
        if GetKeyState("Ctrl","P")
            Send("{Ctrl up}")
    }
}

; ---------- Debug: read pixel under mouse ----------
F9::{
    MouseGetPos &mx, &my
    MsgBox "X" mx "  Y" my "  color " Format("0x{:06X}", ReadRGB(mx, my))
}
