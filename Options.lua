-- Options.lua
local ADDON_NAME = ...
local Tic = LibStub("AceAddon-3.0"):GetAddon("Tic")

local floor = math.floor
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end

-- Simple color name → hex map (for the /tic px set-like tester)
local COLOR_NAME_TO_HEX = {
  white   = "FFFFFF",
  yellow  = "FFFF00",
  magenta = "FF00FF",
  cyan    = "00FFFF",
  red     = "FF0000",
  blue    = "0000FF",
  black   = "000000",
}

function Tic:GetOptionsTable()
  local db = self.db and self.db.profile

  local function specList()
    local t = {}
    for _, s in ipairs(self:GetSpecListForClass(self.playerClass)) do
      t[s] = s
    end
    t["auto"] = "Auto"
    return t
  end

  local strataValues = {
    BACKGROUND = "BACKGROUND",
    LOW        = "LOW",
    MEDIUM     = "MEDIUM",
    HIGH       = "HIGH",
    DIALOG     = "DIALOG",
    TOOLTIP    = "TOOLTIP",
  }

  local general = {
    type = "group",
    name = "Tic",
    args = {
      header = { type = "header", name = "Tic - Settings", order = 0 },

      ----------------------------------------------------------------
      -- PIXELS
      ----------------------------------------------------------------
      pxHeader = { type = "header", name = "Pixel Beacons", order = 10 },

      pxEnabled = {
        type="toggle", name="Enable Pixels", desc="Show the 3 status pixels used by AHK.",
        order=11,
        get=function() return db.pxEnabled end,
        set=function(_, v) db.pxEnabled = v; if Tic.Pixel then Tic.Pixel:Show(v) end end,
      },

      pxGate = {
        type="toggle", name="Gate (Pixel 1 White)", desc="When ON, Pixel 1 is white; when OFF, it is black.",
        order=12,
        get=function() return db.pxGate end,
        set=function(_, v) db.pxGate = v; if Tic.Pixel then Tic.Pixel:SetGate(v) end end,
      },

      pxSize = {
        type="range", name="Size", desc="Pixel box width/height.",
        order=13, min=2, max=32, step=1,
        get=function() return db.pxSize end,
        set=function(_, v) db.pxSize = floor(v); if Tic.Pixel then Tic.Pixel:ApplySizes(); Tic.Pixel:ApplyPositions() end end,
      },

      pxSpacing = {
        type="range", name="Spacing", desc="Distance between pixel boxes.",
        order=14, min=2, max=64, step=1,
        get=function() return db.pxSpacing end,
        set=function(_, v) db.pxSpacing = floor(v); if Tic.Pixel then Tic.Pixel:ApplyPositions() end end,
      },

      pxBaseX = {
        type="range", name="Base X", desc="Screen X for Pixel 1.",
        order=15, min=0, max=2048, step=1, bigStep=10,
        get=function() return db.pxBaseX end,
        set=function(_, v) db.pxBaseX = floor(v); if Tic.Pixel then Tic.Pixel:ApplyPositions() end end,
      },

      pxBaseY = {
        type="range", name="Base Y", desc="Screen Y for Pixel 1.",
        order=16, min=0, max=1536, step=1, bigStep=10,
        get=function() return db.pxBaseY end,
        set=function(_, v) db.pxBaseY = floor(v); if Tic.Pixel then Tic.Pixel:ApplyPositions() end end,
      },

      pxStrata = {
        type="select", name="Frame Strata", desc="Z-order layer for the pixels.",
        order=17, values=strataValues,
        get=function() return db.pxStrata end,
        set=function(_, v) db.pxStrata = v; if Tic.Pixel and Tic.Pixel.ApplyAll then Tic.Pixel:ApplyAll() end end,
      },

      pxLineBreak1 = { type="description", name=" ", order=18 },

      pxTest = {
        type="execute", name="Test Cycle", desc="Cycle through all 36 pixel2/3 combos for ~2 seconds.",
        order=19,
        disabled=function() return not db.pxEnabled end,
        func=function() if Tic.Pixel and Tic.Pixel.TestCycle then Tic.Pixel:TestCycle() end end,
      },

      pxDefaults = {
        type="execute", name="Reset Pixel Defaults", desc="Reset pos/size/spacing to Tic defaults.",
        order=20,
        func=function()
          local d = { baseX=1, baseY=1, spacing=8, size=8 }
          db.pxBaseX, db.pxBaseY, db.pxSpacing, db.pxSize = d.baseX, d.baseY, d.spacing, d.size
          if Tic.Pixel then Tic.Pixel:ApplySizes(); Tic.Pixel:ApplyPositions() end
          Tic:Printf("Pixel defaults applied: x=%d y=%d spacing=%d size=%d", d.baseX, d.baseY, d.spacing, d.size)
        end,
      },

      pxLineBreak2 = { type="description", name=" ", order=21 },

      pxC2 = {
        type="select", name="Test: Pixel 2 Color", desc="Set Pixel 2 to a named color (test only).",
        order=22, values={ white="white", yellow="yellow", magenta="magenta", cyan="cyan", red="red", blue="blue", black="black" },
        set=function(_, k)
          local h = COLOR_NAME_TO_HEX[k]
          if Tic.Pixel and h then Tic.Pixel:SetPair(h, nil) end
        end,
        get=function() return "" end,
      },

      pxC3 = {
        type="select", name="Test: Pixel 3 Color", desc="Set Pixel 3 to a named color (test only).",
        order=23, values={ white="white", yellow="yellow", magenta="magenta", cyan="cyan", red="red", blue="blue", black="black" },
        set=function(_, k)
          local h = COLOR_NAME_TO_HEX[k]
          if Tic.Pixel and h then
            -- keep current c2 by reading from db via last SetPair? If not tracked, just set both when testing
            Tic.Pixel:SetPair(h, h) -- simple visible test; you can refine to remember c2
          end
        end,
        get=function() return "" end,
      },

      pxClear = {
        type="execute", name="Clear (All Black)", desc="Set all three pixels to black.",
        order=24,
        func=function() Tic:ClearPixels() end,
      },

      ----------------------------------------------------------------
      -- HUD / UI
      ----------------------------------------------------------------
      uiHeader = { type="header", name="HUD / UI", order=40 },

      uiEnabled = {
        type="toggle", name="Show HUD", desc="Show/hide the on-screen Tic widget.",
        order=41,
        get=function() return db.uiEnabled end,
        set=function(_, v) db.uiEnabled=v; Tic:UIBuild() end,
      },

      uiLocked = {
        type="toggle", name="Lock HUD", desc="Prevent dragging the HUD.",
        order=42,
        get=function() return db.uiLocked end,
        set=function(_, v) db.uiLocked=v end,
      },

      uiScale = {
        type="range", name="HUD Scale", desc="Overall HUD scale.",
        order=43, min=0.5, max=2.0, step=0.05, bigStep=0.05,
        get=function() return db.uiScale end,
        set=function(_, v) db.uiScale=v; Tic:UIBuild() end,
      },

      uiAlpha = {
        type="range", name="HUD Alpha", desc="HUD transparency.",
        order=44, min=0.1, max=1.0, step=0.05, bigStep=0.05,
        get=function() return db.uiAlpha end,
        set=function(_, v) db.uiAlpha=v; Tic:UIBuild() end,
      },

      uiCols = {
        type="range", name="Icons per Row", desc="Number of toggle icons per row.",
        order=45, min=1, max=16, step=1,
        get=function() return db.uiCols end,
        set=function(_, v) db.uiCols=floor(v); Tic:UIBuild() end,
      },

      uiIcon = {
        type="range", name="Icon Size", desc="Toggle icon size (pixels).",
        order=46, min=16, max=64, step=1,
        get=function() return db.uiIcon end,
        set=function(_, v) db.uiIcon=floor(v); Tic:UIBuild() end,
      },

      uiReset = {
        type="execute", name="Reset HUD", desc="Reset HUD position & look to defaults and center it.",
        order=47,
        func=function() Tic:UIResetAll() end,
      },

      ----------------------------------------------------------------
      -- Minimap
      ----------------------------------------------------------------
      mmHeader = { type="header", name="Minimap Button", order=60 },

      mmShown = {
        type="toggle", name="Show Minimap Button",
        order=61,
        get=function() return db.mm and db.mm.shown ~= false end,
        set=function(_, v) Tic:Minimap_Show(v) end,
      },

      mmAngle = {
        type="range", name="Angle", desc="Position around the minimap (degrees). Hold Shift and drag to move too.",
        order=62, min=0, max=360, step=1, bigStep=5,
        get=function() return (db.mm and db.mm.angle) or 200 end,
        set=function(_, v) Tic:Minimap_SetPosition(clamp(v,0,360)) end,
      },

      mmRadius = {
        type="range", name="Radius", desc="Distance from minimap center.",
        order=63, min=60, max=120, step=1,
        get=function() return (db.mm and db.mm.radius) or 78 end,
        set=function(_, v) db.mm = db.mm or {}; db.mm.radius = floor(v); Tic:Minimap_SetPosition(db.mm.angle or 200) end,
      },

      ----------------------------------------------------------------
      -- Spec Control
      ----------------------------------------------------------------
      specHeader = { type="header", name="Spec Control", order=80 },

      specInfo = {
        type="description",
        name=function()
          local list = table.concat(Tic:GetSpecListForClass(Tic.playerClass), ", ")
          return string.format("Class: |cffffff00%s|r\nAvailable specs: |cffffff00%s|r\nBind Spec 1–4 in Key Bindings → AddOns → Tic.",
            Tic.playerClass or "?", list ~= "" and list or "—")
        end,
        order=81,
      },

      specType = {
        type="select", name="Active Spec", desc="Change the current spec. Your rotation stub switches on this.",
        order=82, values=function() return specList() end,
        get=function()
          local cur = db.specType or "auto"
          return specList()[cur] and cur or "auto"
        end,
        set=function(_, v)
          Tic:SetSpecType(v)
          Tic:UIRefresh()
        end,
      },

      ----------------------------------------------------------------
      -- Debugging
      ----------------------------------------------------------------
      dbgHeader = { type="header", name="Debugging", order=100 },

      debug = {
        type="toggle", name="General Debug",
        order=101,
        get=function() return db.debug end,
        set=function(_, v) db.debug=v end,
      },

      debugEvents = {
        type="toggle", name="Log All Events", desc="Print every registered event when it fires.",
        order=102,
        get=function() return db.debugEvents end,
        set=function(_, v) db.debugEvents=v end,
      },

      debugOnUpdate = {
        type="toggle", name="Log OnUpdate Ticks",
        order=103,
        get=function() return db.debugOnUpdate end,
        set=function(_, v) db.debugOnUpdate=v; Tic:_RefreshOnUpdateVisibility() end,
      },
    },
  }

  return { general = general }
end
