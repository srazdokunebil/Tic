-- Options.lua
local ADDON_NAME = ...
local Tic = LibStub("AceAddon-3.0"):GetAddon("Tic")

-- Small helpers
local floor = math.floor
local function clamp(v, lo, hi) if v < lo then return lo elseif v > hi then return hi else return v end end

function Tic:GetOptionsTable()
  local db = self.db and self.db.profile

  local function specList()
    local t = {}
    for i, s in ipairs(self:GetSpecListForClass(self.playerClass)) do
      t[s] = string.format("%d) %s", i, s)
    end
    t["auto"] = "Auto (fallback to class updater)"
    return t
  end

  local general = {
    type = "group",
    name = "Tic",
    args = {
      header = { type = "header", name = "Tic - Settings", order = 0 },

      -- ===== HUD / UI =====
      uiHeader = { type="header", name="HUD / UI", order=10 },

      uiEnabled = {
        type="toggle", name="Show HUD", desc="Show/hide the on-screen Tic widget.",
        order=11,
        get=function() return db.uiEnabled end,
        set=function(_, v) db.uiEnabled=v; Tic:UIBuild() end,
      },

      uiLocked = {
        type="toggle", name="Lock HUD", desc="Prevent dragging the HUD.",
        order=12,
        get=function() return db.uiLocked end,
        set=function(_, v) db.uiLocked=v end,
      },

      uiScale = {
        type="range", name="HUD Scale", desc="Overall HUD scale.",
        order=13, min=0.5, max=2.0, step=0.05, bigStep=0.05,
        get=function() return db.uiScale end,
        set=function(_, v) db.uiScale=v; Tic:UIBuild() end,
      },

      uiAlpha = {
        type="range", name="HUD Alpha", desc="HUD transparency.",
        order=14, min=0.1, max=1.0, step=0.05, bigStep=0.05,
        get=function() return db.uiAlpha end,
        set=function(_, v) db.uiAlpha=v; Tic:UIBuild() end,
      },

      uiCols = {
        type="range", name="Icons per Row", desc="Number of toggle icons per row.",
        order=15, min=1, max=16, step=1,
        get=function() return db.uiCols end,
        set=function(_, v) db.uiCols=floor(v); Tic:UIBuild() end,
      },

      uiIcon = {
        type="range", name="Icon Size", desc="Toggle icon size (pixels).",
        order=16, min=16, max=64, step=1,
        get=function() return db.uiIcon end,
        set=function(_, v) db.uiIcon=floor(v); Tic:UIBuild() end,
      },

      uiReset = {
        type="execute", name="Reset HUD", desc="Reset HUD position & look to defaults and center it.",
        order=17,
        func=function() Tic:UIResetAll() end,
      },

      -- ===== Minimap =====
      mmHeader = { type="header", name="Minimap Button", order=30 },

      mmShown = {
        type="toggle", name="Show Minimap Button",
        order=31,
        get=function() return db.mm and db.mm.shown ~= false end,
        set=function(_, v) Tic:Minimap_Show(v) end,
      },

      mmAngle = {
        type="range", name="Angle", desc="Position around the minimap (degrees). Hold Shift and drag to move too.",
        order=32, min=0, max=360, step=1, bigStep=5,
        get=function() return (db.mm and db.mm.angle) or 200 end,
        set=function(_, v) Tic:Minimap_SetPosition(clamp(v,0,360)) end,
      },

      mmRadius = {
        type="range", name="Radius", desc="Distance from minimap center.",
        order=33, min=60, max=120, step=1,
        get=function() return (db.mm and db.mm.radius) or 78 end,
        set=function(_, v) db.mm = db.mm or {}; db.mm.radius = floor(v); Tic:Minimap_SetPosition(db.mm.angle or 200) end,
      },

      -- ===== Spec =====
      specHeader = { type="header", name="Spec Control", order=50 },

      specInfo = {
        type="description",
        name=function()
          local list = table.concat(self:GetSpecListForClass(self.playerClass), ", ")
          return string.format("Class: |cffffff00%s|r\nAvailable specs: |cffffff00%s|r\n\nBind Spec 1–4 in Key Bindings → AddOns → Tic.", self.playerClass or "?", list ~= "" and list or "—")
        end,
        order=51,
      },

      specType = {
        type="select", name="Active Spec", desc="Change the current spec. (Your rotation dispatcher will try spec-specific updater first.)",
        order=52, values=function() return specList() end,
        get=function()
          local cur = db.specType or "auto"
          return specList()[cur] and cur or "auto"
        end,
        set=function(_, v)
          Tic:SetSpecType(v)
          Tic:UIRefresh()
        end,
      },

      -- ===== Debug =====
      dbgHeader = { type="header", name="Debugging", order=70 },

      debug = {
        type="toggle", name="General Debug",
        order=71,
        get=function() return db.debug end,
        set=function(_, v) db.debug=v end,
      },

      debugEvents = {
        type="toggle", name="Log All Events", desc="Print every registered event when it fires.",
        order=72,
        get=function() return db.debugEvents end,
        set=function(_, v) db.debugEvents=v end,
      },

      debugOnUpdate = {
        type="toggle", name="Log OnUpdate Ticks",
        order=73,
        get=function() return db.debugOnUpdate end,
        set=function(_, v) db.debugOnUpdate=v; Tic:_RefreshOnUpdateVisibility() end,
      },
    },
  }

  return { general = general }
end
