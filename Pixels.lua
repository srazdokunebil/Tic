-- Pixel beacon module for Tic
local Tic_Pixels = {}
Tic_Pixels.__index = Tic_Pixels
_G.Tic_Pixels = Tic_Pixels  -- ← THIS makes the class visible to Core.lua

local function hexToRGB1(hex) -- "RRGGBB" -> 0..1
  local r = tonumber(hex:sub(1,2),16)/255
  local g = tonumber(hex:sub(3,4),16)/255
  local b = tonumber(hex:sub(5,6),16)/255
  return r,g,b
end

local function pxToUI(x, y) -- screen pixels (from top-left) -> UIParent offsets (TOPLEFT)
  local scale = UIParent:GetEffectiveScale()
  return x/scale, -y/scale
end

-- constructor
function Tic_Pixels:New(addon)
  local o = setmetatable({}, Tic_Pixels)
  o.db = addon.db

  local function makeBox(name, strata)
    local f = CreateFrame("Frame", name, UIParent)
    f:SetFrameStrata(strata or "TOOLTIP")
    local t = f:CreateTexture(nil, "BACKGROUND")
    t:SetAllPoints(f)                -- ← important in 3.3.5
    f.tex = t
    return f
  end

  local strata = o.db.profile.pxStrata or "TOOLTIP"
  local b1 = makeBox("TicPx1", strata)
  local b2 = makeBox("TicPx2", strata)
  local b3 = makeBox("TicPx3", strata)
  local b4 = makeBox("TicPx4", strata)

  o.frames = { b1, b2, b3, b4 }
  o.box1, o.box2, o.box3, o.box4 = b1, b2, b3, b4

  o:ApplyAll()

  -- init black
  for i=1,4 do o.frames[i].tex:SetTexture(0,0,0,1) end

  return o
end

function Tic_Pixels:ApplyAll()
  self:ApplySizes()
  self:ApplyPositions()
  self:Show(self.db.profile.pxEnabled ~= false)
end

function Tic_Pixels:ApplySizes()
  local db = self.db.profile
  local size   = db.pxSize or 8
  local sizeP4 = db.pxGCDSize or size -- if no separate P4 size, follow main size

  -- pixels 1–3
  for i = 1, 3 do
    self.frames[i]:SetWidth(size)
    self.frames[i]:SetHeight(size)
  end

  -- pixel 4
  self.frames[4]:SetWidth(size)
  self.frames[4]:SetHeight(size)
end

function Tic_Pixels:ApplyPositions()
  local db     = self.db.profile
  local anchor = (db.pxAnchor == "TOPLEFT") and "TOPLEFT" or "BOTTOMLEFT"
  local x      = db.pxBaseX or 1
  local y      = db.pxBaseY or 1
  local s      = db.pxSpacing or 8
  local ox     = db.pxGCDOffsetX or 0
  local oy     = db.pxGCDOffsetY or 0

  -- Make Y behave like “distance from the corner inward”
  local ySign  = (anchor == "TOPLEFT") and -1 or 1
  local yMain  = y * ySign
  local yP4    = (y + oy) * ySign

  local f1, f2, f3, f4 = self.frames[1], self.frames[2], self.frames[3], self.frames[4]

  f1:ClearAllPoints(); f1:SetPoint(anchor, UIParent, anchor, x,            yMain)
  f2:ClearAllPoints(); f2:SetPoint(anchor, UIParent, anchor, x + s,        yMain)
  f3:ClearAllPoints(); f3:SetPoint(anchor, UIParent, anchor, x + s * 2,    yMain)
  f4:ClearAllPoints(); f4:SetPoint(anchor, UIParent, anchor, x + s * 3 + ox, yP4)
end


function Tic_Pixels:Show(show)
  local vis = show ~= false
  for i=1,4 do if vis then self.frames[i]:Show() else self.frames[i]:Hide() end end
end

-- helpers
local function setHex(tex, hex)
  if not tex or not hex then return end
  local r = tonumber(hex:sub(1,2),16)/255
  local g = tonumber(hex:sub(3,4),16)/255
  local b = tonumber(hex:sub(5,6),16)/255
  tex:SetTexture(r,g,b,1)
end

-- Gate = box1 color (true=white, false=black)
-- the three setters used by Core/Rotations
function Tic_Pixels:SetGate(on)
  if not (self.frames and self.frames[1]) then return end
  setHex(self.frames[1].tex, on and "FFFFFF" or "000000")
end

-- Set c2/c3 colors using "RRGGBB" hex strings
function Tic_Pixels:SetPair(h2, h3)
  if not self.frames then return end
  setHex(self.frames[2].tex, h2 or "000000")
  setHex(self.frames[3].tex, h3 or "000000")
end

function Tic_Pixels:SetGCDPhase(hex)
  if not (self.frames and self.frames[4]) then return end
  setHex(self.frames[4].tex, hex or "000000")
end

-- Quick visual test sequence
function Tic_Pixels:TestCycle()
  local seq = {
    {"FFFFFF","FFFFFF"},
    {"FFFF00","FF00FF"},
    {"00FFFF","FF0000"},
    {"0000FF","FFFFFF"},
    {"000000","000000"},
  }
  local i=1
  local function step()
    if not self.addon.db.profile.pxEnabled then self.addon:Printf("Pixels are OFF"); return end
    local c2,c3 = unpack(seq[i]); self:SetPair(c2,c3)
    self.addon:Printf("Test %d: c2=#%s c3=#%s", i, c2, c3)
    i = i % #seq + 1
  end
  step()
  if self.testTimer then self.addon:CancelTimer(self.testTimer) end
  self.testTimer = self.addon:ScheduleRepeatingTimer(step, 1.0)
  -- auto stop after a few cycles
  self.addon:ScheduleTimer(function()
    if self.testTimer then self.addon:CancelTimer(self.testTimer); self.testTimer=nil end
    self.addon:Printf("Test done")
  end, 6.0)
end
