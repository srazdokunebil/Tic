-- Ace3 core
local ADDON_NAME = ...
local Tic = LibStub("AceAddon-3.0"):NewAddon("Tic", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
_G.Tic = Tic -- optional global for quick /run testing

-- Defaults
local defaults = {
  profile = {
    debug = false,
    throttle = 0.10,

    -- Pixel beacon defaults: adjusted
    pxEnabled = true,
    pxSize = 8,       -- size in pixels
    pxBaseX = 1,      -- screen X position of box1
    pxBaseY = 1,      -- screen Y position of box1
    pxSpacing = 8,    -- distance between boxes
    pxStrata = "TOOLTIP",
    pxGate = true,

    debugEvents = false,
    debugOnUpdate = false,
  }
}

-- Pixel placement defaults (used by /tic px defaults)
local PX_DEFAULTS = {
  baseX   = 1,
  baseY   = 1,
  spacing = 8,
  size    = 8,
}

-- Class table (display, short code) ----
Tic_classes = {
  {"Death Knight", "DKT"},
  {"Druid",        "DRU"},
  {"Hunter",       "HUN"},
  {"Mage",         "MAG"},
  {"Paladin",      "PAL"},
  {"Priest",       "PRI"},
  {"Rogue",        "ROG"},
  {"Shaman",       "SHM"},
  {"Warlock",      "WLK"},
  {"Warrior",      "WAR"},
}

-- ---- 6 colors used for pixel2/pixel3 (order matters; 6×6 = 36 combos) ----
local SIX = { "FFFFFF", "FFFF00", "FF00FF", "00FFFF", "FF0000", "0000FF" } -- white,yellow,magenta,cyan,red,blue

-- Compute the pair for an index 1..36: returns hex2, hex3
local function indexToPair(idx)
  if idx < 1 or idx > 36 then return "000000","000000" end
  local n = idx - 1
  local i = floor(n / 6) + 1  -- 1..6 -> pixel2
  local j = (n % 6) + 1       -- 1..6 -> pixel3
  return SIX[i], SIX[j]
end

-- Map letters for indices > 10: 1..9 -> 1..9, 10->0, 11..36 -> A..Z
local function indexToKeyToken(idx)
  if idx >= 1 and idx <= 9 then return tostring(idx) end
  if idx == 10 then return "0" end
  local n = idx - 10 -- 1 -> A, 26 -> Z
  if n >= 1 and n <= 26 then
    return string.char(64 + n) -- 65='A'
  end
  return nil
end

-- Public API: emit pixels for a given index (and raise the gate)
function Tic:SignalIndex(idx)
  local c2, c3 = indexToPair(idx)
  self.Pixel:SetGate(true)        -- pixel1 = white gate on
  self.Pixel:SetPair(c2, c3)      -- pixel2/pixel3 = combo
end

-- Public API: convenience for spell-by-name -> find bound index, then signal
function Tic:CastSpellByNameSignal(spellName)
  local bind = self.bindings and self.bindings.bySpell and self.bindings.bySpell[spellName]
  if not bind then
    if self.db.profile.debug then self:Printf("No binding for %q", tostring(spellName)) end
    return
  end
  self:SignalIndex(bind.index)
end

-- Alias you asked for
function Tic_castSpellByName(spellName)
  if Tic and Tic.CastSpellByNameSignal then Tic:CastSpellByNameSignal(spellName) end
end

-- Secure button factory and key binder (out of combat only)
function Tic:BindKey(spellName)
  if InCombatLockdown() then
    self:Printf("Cannot bind %q in combat.", spellName)
    return nil
  end

  self.bindings = self.bindings or { list = {}, bySpell = {}, byIndex = {} }

  -- Assign next index 1..36
  local idx = #self.bindings.list + 1
  if idx > 36 then
    self:Printf("Max 36 bindings reached.")
    return nil
  end

  -- Create hidden secure button
  local btnName = "TicBtn"..idx
  local btn = CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate")
  btn:Hide()
  btn:SetAttribute("type", "spell")
  btn:SetAttribute("spell", spellName)

  -- Bind CTRL-<token> to click this button
  local token = indexToKeyToken(idx)
  if not token then
    self:Printf("No key token for index %d", idx); return nil
  end
  -- Clear any existing and set new
  SetBinding("CTRL-"..token) -- clear direct binding just in case
  SetBindingClick("CTRL-"..token, btnName) -- CTRL+token -> click the button
  SaveBindings(GetCurrentBindingSet())     -- persist

  -- Track
  local rec = { index = idx, spell = spellName, button = btnName, token = token }
  table.insert(self.bindings.list, rec)
  self.bindings.bySpell[spellName] = rec
  self.bindings.byIndex[idx] = rec

  if self.db.profile.debug then
    self:Printf("Bound #%d [%s] -> CTRL-%s (button %s)", idx, spellName, token, btnName)
  end
  return idx
end

-- Shortcut name you used in your pseudocode
function tic_bind_key(spellName)
  return Tic and Tic.BindKey and Tic:BindKey(spellName)
end

-- Class detection
function Tic:GetPlayerClass() -- returns englishClass, classIndex
  local _, eng = UnitClass("player") -- "DRUID", "MAGE", etc
  -- map to our short codes if you want, not strictly necessary
  return eng
end












-- Utils
function Tic:Printf(fmt, ...) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[Tic]|r "..string.format(fmt, ...)) end
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

function Tic:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("TicDB", defaults, true)

  -- Options UI
  local ACR = LibStub("AceConfig-3.0"); local ACD = LibStub("AceConfigDialog-3.0")
  ACR:RegisterOptionsTable("Tic", self:GetOptionsTable().general)
  self.optionsFrame = ACD:AddToBlizOptions("Tic", "Tic")
  local AceDBOptions = LibStub("AceDBOptions-3.0", true)
  if AceDBOptions then
    local profiles = AceDBOptions:GetOptionsTable(self.db)
    ACR:RegisterOptionsTable("Tic_Profiles", profiles)
    ACD:AddToBlizOptions("Tic_Profiles", "Profiles", "Tic")
  end

  -- Wrap RegisterEvent so we can optionally print event names
  self._OrigRegisterEvent = self.RegisterEvent
  self.RegisterEvent = function(obj, event, method)
    local real = method or event
    local wrap
    if type(real) == "string" then
      wrap = function(...) if obj.db.profile.debugEvents then obj:Printf("[EV] %s", event) end; return obj[real](obj, ...) end
    elseif type(real) == "function" then
      wrap = function(...) if obj.db.profile.debugEvents then obj:Printf("[EV] %s", event) end; return real(...) end
    else
      wrap = function(...) if obj.db.profile.debugEvents then obj:Printf("[EV] %s", event) end; if obj[event] then return obj[event](obj, ...) end end
    end
    return Tic._OrigRegisterEvent(obj, event, wrap)
  end

  -- Slash
  self:RegisterChatCommand("tic", function(msg) self:HandleSlash(msg) end)
end

function Tic:OnEnable()
  -- Events you can keep or replace
  self:RegisterEvent("UI_SCALE_CHANGED", "_OnScaleChanged")
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "_OnScaleChanged")
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

  -- Start pixel module
  self.Pixel = self.Pixel or Tic_Pixels:New(self)
  self.Pixel:ApplyAll()  -- build frames & place them

  -- Optional OnUpdate logger
  if not self._updateFrame then
    self._updateFrame = CreateFrame("Frame", "TicUpdateFrame")
    self._updateAccum = 0
    self._updateFrame:SetScript("OnUpdate", function(_, elapsed)
      self._updateAccum = self._updateAccum + elapsed
      local thr = self.db.profile.throttle
      if self._updateAccum >= thr then
        --if self.db.profile.debugOnUpdate then self:Printf("[OnUpdate] tick (Δ=%.3f)", self._updateAccum) end
        self._updateAccum = 0
      end
    end)
  end

  -- Class bootstrap
  self.playerClass = self:GetPlayerClass()             -- e.g., "DRUID"
  if self.InitForClass then self:InitForClass(self.playerClass) end

  -- OnUpdate dispatcher for rotations
  if not self._rotFrame then
    self._rotFrame = CreateFrame("Frame", "TicRotationFrame")
    self._rotFrame:SetScript("OnUpdate", function(_, elapsed)
      if self.UpdateForClass then self:UpdateForClass(elapsed) end
    end)
  end

  self:Printf("Class: %s", tostring(self.playerClass or "?"))

  self:_RefreshOnUpdateVisibility()

  self:Printf("Loaded. /tic options  |  /tic px help")
end

function Tic:OnDisable()
  if self._updateFrame then self._updateFrame:Hide() end
  if self.Pixel then self.Pixel:Show(false) end
end

-- Demo handler (replace with your own logic)
function Tic:COMBAT_LOG_EVENT_UNFILTERED()
  -- Example: blink gate during combat aura applied/removed (debug only)
  if not self.db.profile.debug then return end
  local _, sub = CombatLogGetCurrentEventInfo()
  if sub == "SPELL_AURA_APPLIED" then self.Pixel:SetGate(true)
  elseif sub == "SPELL_AURA_REMOVED" then self.Pixel:SetGate(false) end
end

-- Scale change -> re-place for pixel-perfect alignment
function Tic:_OnScaleChanged() if self.Pixel then self.Pixel:ApplyPositions() end end
function Tic:_RefreshOnUpdateVisibility()
  if not self._updateFrame then return end
  if self.db and self.db.profile and self.db.profile.debugOnUpdate then
    self._updateFrame:Show()
  else
    self._updateFrame:Hide()
  end
end

-- -------- Slash commands --------
function Tic:HandleSlash(msg)
  msg = trim(msg or "")
  local sub, rest = msg:match("^(%S+)%s*(.*)$")
  if not sub or sub == "" then
    self:Printf("Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic options                - open config")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px help                - pixel beacon help")
    return
  end

  if sub == "options" or sub == "opt" then
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    return
  end

  if sub == "px" then
    self:HandlePx(rest)
    return
  end

  self:Printf("Unknown command. Try /tic or /tic px help")
end

local colorNames = { white="FFFFFF", yellow="FFFF00", magenta="FF00FF", cyan="00FFFF", red="FF0000", blue="0000FF", black="000000" }

function Tic:HandlePx(rest)
  local a,b,c = rest:match("^(%S+)%s*(%S*)%s*(.*)$")
  a = (a or ""):lower()

  if a == "help" or a == "" then
    self:Printf("Pixel beacons:")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px on|off             - show/hide squares")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px gate on|off        - box1 white toggle")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px pos <x> <y>        - set base screen coords")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px size <n>           - set square size")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px spacing <n>        - set spacing between boxes")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px set <c2> <c3>      - set colors by name (white|yellow|magenta|cyan|red|blue|black)")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px defaults           - reset pos/size/spacing to defaults") -- ← add this
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px test               - quick cycle test")
    return
  end

  if a == "on" or a == "off" then
    self.db.profile.pxEnabled = (a == "on")
    self.Pixel:Show(self.db.profile.pxEnabled)
    self:Printf("Pixels: %s", a:upper())
    return
  end

  if a == "gate" then
    b = b:lower()
    self.db.profile.pxGate = (b == "on")
    self.Pixel:SetGate(self.db.profile.pxGate)
    self:Printf("Gate: %s", self.db.profile.pxGate and "ON" or "OFF")
    return
  end

  if a == "pos" then
    local x,y = tonumber(b), tonumber(c)
    if not (x and y) then self:Printf("Usage: /tic px pos <x> <y>"); return end
    self.db.profile.pxBaseX, self.db.profile.pxBaseY = x, y
    self.Pixel:ApplyPositions()
    self:Printf("Pos set to %d,%d", x, y)
    return
  end

  if a == "size" then
    local n = tonumber(b); if not n then self:Printf("Usage: /tic px size <n>"); return end
    self.db.profile.pxSize = n; self.Pixel:ApplySizes(); self.Pixel:ApplyPositions()
    self:Printf("Size = %d", n)
    return
  end

  if a == "spacing" then
    local n = tonumber(b); if not n then self:Printf("Usage: /tic px spacing <n>"); return end
    self.db.profile.pxSpacing = n; self.Pixel:ApplyPositions()
    self:Printf("Spacing = %d", n)
    return
  end

  if a == "set" then
    local c2, c3 = b:lower(), (c or ""):lower()
    local h2, h3 = colorNames[c2], colorNames[c3]
    if not (h2 and h3) then self:Printf("Bad colors. Try: white yellow magenta cyan red blue black"); return end
    self.Pixel:SetPair(h2, h3)
    self:Printf("Set c2=%s c3=%s", c2, c3)
    return
  end

  if a == "test" then
    self.Pixel:TestCycle()
    return
  end

  if a == "defaults" then
    local d = PX_DEFAULTS
    self.db.profile.pxBaseX   = d.baseX
    self.db.profile.pxBaseY   = d.baseY
    self.db.profile.pxSpacing = d.spacing
    self.db.profile.pxSize    = d.size

    -- Reapply sizes/positions immediately (no reload needed)
    if self.Pixel then
      self.Pixel:ApplySizes()
      self.Pixel:ApplyPositions()
    end

    self:Printf("Pixel defaults applied: x=%d y=%d spacing=%d size=%d",
      d.baseX, d.baseY, d.spacing, d.size)
    return
  end

  self:Printf("Unknown px cmd. /tic px help")
end

-- Exposed for Options.lua
Tic._GetAddon = function() return Tic end
