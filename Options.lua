local ADDON_NAME = ...
local Tic = LibStub("AceAddon-3.0"):GetAddon("Tic")

local strataList = { "BACKGROUND","LOW","MEDIUM","HIGH","DIALOG","TOOLTIP" }

function Tic:GetOptionsTable()
  local db = self.db and self.db.profile
  local opt = {
    general = {
      type = "group",
      name  = "Tic",
      args = {
        header = { type="header", name="Tic Settings", order=0 },

        debug = {
          type="toggle", name="General debug", order=5,
          get=function() return db.debug end,
          set=function(_,v) db.debug=v end,
        },

        pxHeader = { type="header", name="Pixel Beacons", order=10 },
        pxEnabled = {
          type="toggle", name="Enable pixels", order=11,
          get=function() return db.pxEnabled end,
          set=function(_,v) db.pxEnabled=v; Tic.Pixel:Show(v) end,
        },
        pxGate = {
          type="toggle", name="Gate (box1 white)", order=12,
          get=function() return db.pxGate end,
          set=function(_,v) db.pxGate=v; Tic.Pixel:SetGate(v) end,
        },
        pxSize = {
          type="range", name="Size (px)", min=1, max=20, step=1, order=13,
          get=function() return db.pxSize end,
          set=function(_,v) db.pxSize=v; Tic.Pixel:ApplySizes(); Tic.Pixel:ApplyPositions() end,
        },
        pxSpacing = {
          type="range", name="Spacing (px)", min=1, max=100, step=1, order=14,
          get=function() return db.pxSpacing end,
          set=function(_,v) db.pxSpacing=v; Tic.Pixel:ApplyPositions() end,
        },
        pxStrata = {
          type="select", name="Frame strata", order=15, values=strataList, style="dropdown",
          get=function()
            local s=db.pxStrata or "TOOLTIP"
            for i,v in ipairs(strataList) do if v==s then return i end end
            return 6
          end,
          set=function(_,idx) db.pxStrata=strataList[idx]; Tic.Pixel:ApplyPositions() end,
        },
        pxBaseX = {
          type="input", name="Base X (screen px)", order=16, width="half",
          get=function() return tostring(db.pxBaseX) end,
          set=function(_,v) v=tonumber(v); if v then db.pxBaseX=v; Tic.Pixel:ApplyPositions() end end,
        },
        pxBaseY = {
          type="input", name="Base Y (screen px)", order=17, width="half",
          get=function() return tostring(db.pxBaseY) end,
          set=function(_,v) v=tonumber(v); if v then db.pxBaseY=v; Tic.Pixel:ApplyPositions() end end,
        },

        throttle = {
          type="range", name="Throttle (seconds)", min=0.02, max=1.0, step=0.02, order=30,
          get=function() return db.throttle end,
          set=function(_,v) db.throttle=v end,
        },

        debugEvents = {
          type="toggle", name="Log all events", order=40,
          get=function() return db.debugEvents end,
          set=function(_,v) db.debugEvents=v end,
        },
        debugOnUpdate = {
          type="toggle", name="Log OnUpdate ticks", order=41,
          get=function() return db.debugOnUpdate end,
          set=function(_,v) db.debugOnUpdate=v; Tic:_RefreshOnUpdateVisibility() end,
        },
      },
    }
  }
  return opt
end
