-- Pixel beacon module for Tic
Tic_Pixels = {}
Tic_Pixels.__index = Tic_Pixels

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

function Tic_Pixels:New(addon)
  local o = setmetatable({}, self)
  o.addon = addon
  o.frames = {}

  -- create 3 squares
  for i=1,3 do
    local f = CreateFrame("Frame", "TicPx"..i, UIParent)
    f:SetFrameStrata(addon.db.profile.pxStrata or "TOOLTIP")
    f:SetFrameLevel(99)
    f:EnableMouse(false)
    f:Hide()

    local t = f:CreateTexture(nil, "ARTWORK")
    t:SetAllPoints(f)
    t:SetTexture(0,0,0)   -- RGB in 0..1
    t:SetAlpha(1)
    f.tex = t

    o.frames[i] = f
  end
  return o
end

function Tic_Pixels:ApplyAll()
  self:ApplySizes()
  self:ApplyPositions()
  self:Show(self.addon.db.profile.pxEnabled)
  self:SetGate(self.addon.db.profile.pxGate)
  self:SetPair("FFFFFF","FFFFFF") -- default c2/c3 = white/white
end

function Tic_Pixels:ApplySizes()
  local sz = self.addon.db.profile.pxSize
  for _,f in ipairs(self.frames) do f:SetWidth(sz); f:SetHeight(sz) end
end

function Tic_Pixels:ApplyPositions()
  local db = self.addon.db.profile
  local x0,y0 = db.pxBaseX, db.pxBaseY
  local sp = db.pxSpacing
  for i=1,3 do
    local f = self.frames[i]
    f:ClearAllPoints()
    local x = x0 + (i-1)*sp
    local y = y0
    local ox, oy = pxToUI(x,y)
    f:SetPoint("TOPLEFT", UIParent, "TOPLEFT", ox, oy)
    f:SetFrameStrata(db.pxStrata or "TOOLTIP")
  end
end

function Tic_Pixels:Show(show)
  for _,f in ipairs(self.frames) do if show then f:Show() else f:Hide() end end
end

-- Gate = box1 color (true=white, false=black)
function Tic_Pixels:SetGate(state)
  local f = self.frames[1]
  local r,g,b = state and 1 or 0, state and 1 or 0, state and 1 or 0
  f.tex:SetTexture(r,g,b)
  f.tex:SetAlpha(1)
end

-- Set c2/c3 colors using "RRGGBB" hex strings
function Tic_Pixels:SetPair(hex2, hex3)
  local r2,g2,b2 = hexToRGB1(hex2); local r3,g3,b3 = hexToRGB1(hex3)
  self.frames[2].tex:SetTexture(r2,g2,b2); self.frames[2].tex:SetAlpha(1)
  self.frames[3].tex:SetTexture(r3,g3,b3); self.frames[3].tex:SetAlpha(1)
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
