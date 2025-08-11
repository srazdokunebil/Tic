-- Core.lua
-- Ace3 core
local ADDON_NAME = ...
local Tic = LibStub("AceAddon-3.0"):NewAddon("Tic", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
_G.Tic = Tic -- optional global for quick /run testing

-- Locals
local floor, max = math.floor, math.max
local cos, sin, rad = math.cos, math.sin, math.rad

-- Defaults
local defaults = {
  profile = {
    debug = false,
    throttle = 0.10,

    -- Pixel beacon defaults
    pxEnabled = true,
    pxSize = 8,       -- size in pixels
    pxBaseX = 1,      -- screen X position of box1
    pxBaseY = 1,      -- screen Y position of box1
    pxSpacing = 8,    -- distance between boxes
    pxStrata = "TOOLTIP",
    pxGate = true,

    pxGCDEnabled = true,   -- show the 4th pixel
    pxGCDSize    = 8,
    pxGCDOffsetX = 0,      -- extra tweak if you want to separate it
    pxGCDOffsetY = 0,

    -- UI widget defaults
    uiEnabled = true,
    uiLocked  = false,
    uiScale   = 1.0,
    uiAlpha   = 1.0,
    uiCols    = 8,      -- icons per row before wrapping
    uiIcon    = 32,     -- icon size (px)
    uiPos = { point = "CENTER", rel = "CENTER", x = 0, y = 0 },

    -- Minimap button defaults
    mm = { shown = true, angle = 200, radius = 78 },

    -- Spec defaults (set dynamically on first load)
    specType = nil,

    -- Debug toggles
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

-- ---- Class table (display, short code) ----
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

-- Class -> Spec tokens (map by class token)
Tic.ClassSpecs = {
  DEATHKNIGHT = { "blood","frost","unholy" },
  DRUID       = { "heal","mdps","rdps","tank" },
  HUNTER      = { "bm","mm","sv" },
  MAGE        = { "arcane","frost","fire" },
  PALADIN     = { "holy","prot","ret" },
  PRIEST      = { "holy","shadow" },
  ROGUE       = { "ass","combat","sub" },
  SHAMAN      = { "heal","mdps","rdps","tank" }, -- your nomenclature
  WARLOCK     = { "dsr","md","sm" },
  WARRIOR     = { "arms","fury","prot" },
}

-- ---- 6 colors used for pixel2/pixel3 (order matters; 6×6 = 36 combos) ----
local SIX = { "FFFFFF", "FFFF00", "FF00FF", "00FFFF", "FF0000", "0000FF" } -- white,yellow,magenta,cyan,red,blue

-- Utils
function Tic:Printf(fmt, ...) DEFAULT_CHAT_FRAME:AddMessage("|cff66ccff[Tic]|r "..string.format(fmt, ...)) end
local function trim(s) return (s or ""):match("^%s*(.-)%s*$") end

-- Build a stable key for saved vars and HUD lists (CLASS:SPEC)
local function SpecKey(classToken, specToken)
  return (classToken or "?") .. ":" .. (specToken or "auto")
end

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

-- ========================
-- Per-spec toggle API (HUD lists)
-- ========================
function Tic:RegisterSpecToggles(spellList)
  return self:RegisterSpecTogglesFor(self.playerClass, self:GetSpecType(), spellList or {})
end

function Tic:RegisterSpecTogglesFor(classToken, specToken, spellList)
  self.specToggles = self.specToggles or {}
  local key = SpecKey(classToken, specToken)

  -- replace the list for this spec entirely
  self.specToggles[key] = {}
  for i, name in ipairs(spellList or {}) do
    self.specToggles[key][i] = name
  end

  -- ensure saved toggle states table exists for this spec
  self.db.profile.spellToggles = self.db.profile.spellToggles or {}
  self.db.profile.spellToggles[key] = self.db.profile.spellToggles[key] or {}
  local st = self.db.profile.spellToggles[key]

  -- default new items to ON (don’t flip existing OFF)
  for _, name in ipairs(self.specToggles[key]) do
    if st[name] == nil then st[name] = true end
  end

  -- feedback
  self:Printf("Registered %d toggle spell%s for spec [%s]",
    #self.specToggles[key],
    (#self.specToggles[key] == 1 and "" or "s"),
    key
  )
  if #self.specToggles[key] > 0 then
    DEFAULT_CHAT_FRAME:AddMessage("  " .. table.concat(self.specToggles[key], ", "))
  end

  -- if we registered for the ACTIVE spec, rebuild the HUD now
  if classToken == self.playerClass and specToken == self:GetSpecType() then
    self:UIBuild()
  end
end

function Tic:ClearSpecToggles()
  return self:ClearSpecTogglesFor(self.playerClass, self:GetSpecType())
end

function Tic:ClearSpecTogglesFor(classToken, specToken)
  local key = SpecKey(classToken, specToken)
  if self.specToggles and self.specToggles[key] then
    self.specToggles[key] = nil
  end
  if classToken == self.playerClass and specToken == self:GetSpecType() then
    self:UIBuild()
  end
end

-- Rotation helper: is a spell enabled for the ACTIVE spec?
function Tic:IsSpellEnabled(name)
  local key = SpecKey(self.playerClass, self:GetSpecType())
  local stateTbl = self.db.profile.spellToggles and self.db.profile.spellToggles[key]
  return not stateTbl and true or stateTbl[name] ~= false
end

-- ========================
-- Public Pixel API
-- ========================
-- Emit pixels for a given index (and raise the gate)
function Tic:SignalIndex(idx)
  local c2, c3 = indexToPair(idx)
  self.Pixel:SetGate(true)        -- pixel1 = white gate on
  self.Pixel:SetPair(c2, c3)      -- pixel2/pixel3 = combo
end

-- Convenience: spell-by-name -> find bound index, then signal
function Tic:CastSpellByNameSignal(spellName)
  local bind = self.bindings and self.bindings.bySpell and self.bindings.bySpell[spellName]
  if not bind then
    if self.db.profile.debug then self:Printf("No binding for %q", tostring(spellName)) end
    return
  end
  self:SignalIndex(bind.index)
end

-- Alias requested
function Tic_castSpellByName(spellName)
  if Tic and Tic.CastSpellByNameSignal then Tic:CastSpellByNameSignal(spellName) end
end

-- Clear all three pixels to black (no-op indicator)
function Tic:ClearPixels()
  if not self.Pixel then return end
  -- pixel1 black gate
  self.Pixel:SetGate(false)               -- sets pixel1 to black
  -- pixel2 & pixel3 black
  self.Pixel:SetPair("000000", "000000")
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

-- Shortcut name used in examples
function tic_bind_key(spellName)
  return Tic and Tic.BindKey and Tic:BindKey(spellName)
end

-- Class detection
function Tic:GetPlayerClass() -- returns englishClass token (DRUID, etc)
  local _, eng = UnitClass("player")
  return eng
end

-- ========================
-- HUD / UI
-- ========================
function Tic:UIBuild()
  -- Respect master toggle
  if not (self.db and self.db.profile and self.db.profile.uiEnabled) then
    if self.ui and self.ui.frame then self.ui.frame:Hide() end
    return
  end

  -- one-time container
  if not self.ui then self.ui = {} end
  local f = self.ui.frame
  if not f then
    f = CreateFrame("Frame", "TicUI", UIParent)
    f:SetMovable(true); f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetClampedToScreen(true)
    f:SetBackdrop({
      bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile     = true, tileSize = 16, edgeSize = 12,
      insets   = { left=3, right=3, top=3, bottom=3 }
    })
    f:SetBackdropColor(0,0,0,0.6)

    -- Drag handlers + persist position
    f:SetScript("OnDragStart", function(frame)
      if not Tic.db.profile.uiLocked then frame:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(frame)
      frame:StopMovingOrSizing()
      local point, _, rel, x, y = frame:GetPoint(1)
      Tic.db.profile.uiPos = {
        point = point or "CENTER",
        rel   = rel   or "CENTER",
        x     = x     or 0,
        y     = y     or 0
      }
    end)

    -- Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    title:SetPoint("TOPLEFT", 8, -6)
    title:SetText("Tic")
    self.ui.title = title

    -- Icon holder
    local holder = CreateFrame("Frame", nil, f)
    holder:SetPoint("TOPLEFT", 6, -22)
    holder:SetPoint("BOTTOMRIGHT", -6, 6)
    self.ui.holder = holder

    self.ui.frame = f
    f:Hide()
  end

  -- Restore saved position (or center)
  self.db.profile.uiPos = self.db.profile.uiPos or { point="CENTER", rel="CENTER", x=0, y=0 }
  local pos = self.db.profile.uiPos
  f:ClearAllPoints()
  f:SetPoint(pos.point, UIParent, pos.rel, pos.x, pos.y)

  -- Label: CLASS – spec
  local label = (self.playerClass or "?")
  local spec  = self:GetSpecType()
  if spec and spec ~= "auto" then label = label .. " – " .. spec end
  self.ui.title:SetText(label)

  -- Apply visual config
  f:SetScale(self.db.profile.uiScale or 1)
  f:SetAlpha(self.db.profile.uiAlpha or 1)

  -- Resolve current spec list & toggle state
  local key   = (self.playerClass or "?") .. ":" .. (self:GetSpecType() or "auto")
  self.db.profile.spellToggles = self.db.profile.spellToggles or {}
  self.db.profile.spellToggles[key] = self.db.profile.spellToggles[key] or {}
  local list  = (self.specToggles and self.specToggles[key]) or {}
  local state = self.db.profile.spellToggles[key]

  -- Nuke old buttons
  if self.ui.buttons then
    for _, b in ipairs(self.ui.buttons) do b:Hide(); b:SetParent(nil) end
  end
  self.ui.buttons = {}

  -- Layout math
  local cols = self.db.profile.uiCols or 8
  local size = self.db.profile.uiIcon or 32
  local pad  = 4
  local rows = math.ceil((#list > 0 and #list or 1) / cols) -- keep some height if empty
  local w = cols*size + (cols-1)*pad + 12
  local h = rows*size + (rows-1)*pad + 28
  f:SetSize(max(120, w), max(40, h))

  -- Build buttons
  for i, spellName in ipairs(list) do
    local b = CreateFrame("CheckButton", "TicUIToggle"..i, self.ui.holder)
    b:SetSize(size, size)

    local col = (i-1) % cols
    local row = floor((i-1) / cols)
    b:SetPoint("TOPLEFT", col*(size+pad), -row*(size+pad))

    -- Icon
    local sName, _, icon = GetSpellInfo(spellName)
    local tex = b:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints(true)
    tex:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    b.icon = tex

    -- Border glow when enabled
    local glow = b:CreateTexture(nil, "OVERLAY")
    glow:SetPoint("TOPLEFT", -2, 2)
    glow:SetPoint("BOTTOMRIGHT", 2, -2)
    glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    glow:SetBlendMode("ADD")
    b.highlight = glow

    -- Checked overlay
    local chk = b:CreateTexture(nil, "ARTWORK")
    chk:SetAllPoints(true)
    chk:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    chk:SetBlendMode("ADD")
    b:SetCheckedTexture(chk)

    -- Initial state (default ON)
    local enabled = (state[spellName] ~= false)
    b:SetChecked(enabled)
    if enabled then b.highlight:Show() else b.highlight:Hide() end

    -- Tooltip
    b:SetScript("OnEnter", function(selfBtn)
      GameTooltip:SetOwner(selfBtn, "ANCHOR_RIGHT")
      GameTooltip:SetText(sName or spellName, 1,1,1)
      GameTooltip:AddLine("Click to enable/disable", 0.8,0.8,0.8)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Click handler with chat feedback
    b:SetScript("OnClick", function(selfBtn)
      local on = selfBtn:GetChecked() and true or false
      state[spellName] = on
      if on then selfBtn.highlight:Show() else selfBtn.highlight:Hide() end
      Tic:Printf("%s toggled %s for spec [%s]",
        spellName,
        on and "|cff00ff00ON|r" or "|cffff0000OFF|r",
        key
      )
    end)

    table.insert(self.ui.buttons, b)
  end

  -- Finally, show/hide the frame
  if self.db.profile.uiEnabled then f:Show() else f:Hide() end
end

function Tic:UIRefresh() self:UIBuild() end

function Tic:UIResetPosition()
  if not (self.ui and self.ui.frame) then self:UIBuild() end
  if not (self.ui and self.ui.frame) then return end
  local f = self.ui.frame
  f:ClearAllPoints()
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  f:SetScale(self.db.profile.uiScale or 1)
  f:SetAlpha(self.db.profile.uiAlpha or 1)
  f:Show()
  self.db.profile.uiEnabled = true
  self.db.profile.uiLocked  = false
  self:Printf("UI reset to screen center. (Unlocked)")
end

function Tic:UIResetAll()
  self.db.profile.uiEnabled = true
  self.db.profile.uiLocked  = false
  self.db.profile.uiScale   = 1.0
  self.db.profile.uiAlpha   = 1.0
  self.db.profile.uiCols    = 8
  self.db.profile.uiIcon    = 32
  self.db.profile.uiPos     = { point = "CENTER", rel = "CENTER", x = 0, y = 0 }
  self:UIBuild()
  if self.ui and self.ui.frame then
    local f = self.ui.frame
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    f:SetScale(self.db.profile.uiScale)
    f:SetAlpha(self.db.profile.uiAlpha)
    f:Show()
  end
  self:Printf("UI reset to defaults (centered, unlocked, scale=1, alpha=1, cols=8, icon=32).")
end

-- ========================
-- Minimap Button (Wrath)
-- ========================
function Tic:Minimap_SetPosition(angle)
  self.db.profile.mm.angle = angle
  if not self.mm or not self.mm.btn then return end
  local r = self.db.profile.mm.radius or 78
  local x = cos(rad(angle)) * r
  local y = sin(rad(angle)) * r
  self.mm.btn:ClearAllPoints()
  self.mm.btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function Tic:Minimap_Show(show)
  self.db.profile.mm.shown = (show == nil) and true or not not show
  if self.mm and self.mm.btn then
    if self.db.profile.mm.shown then self.mm.btn:Show() else self.mm.btn:Hide() end
  end
end

function Tic:Minimap_ToggleUI()
  self.db.profile.uiEnabled = not self.db.profile.uiEnabled
  self:UIBuild()
  self:Printf("UI %s", self.db.profile.uiEnabled and "shown" or "hidden")
end

function Tic:Minimap_InitMenu()
  if self.mm and self.mm.menu then return end
  self.mm = self.mm or {}
  local dd = CreateFrame("Frame", "TicMiniMapDropDown", UIParent, "UIDropDownMenuTemplate")
  dd.displayMode = "MENU"
  self.mm.menu = dd
end

function Tic:Minimap_OpenMenu(anchor)
  self:Minimap_InitMenu()
  local menu = {
    { text = "Tic", isTitle = true, notCheckable = true },
    { text = (self.db.profile.uiEnabled and "Hide UI" or "Show UI"),
      notCheckable = true,
      func = function() Tic:Minimap_ToggleUI(); CloseDropDownMenus() end },
    { text = "Options…",
      notCheckable = true,
      func = function()
        if Tic.optionsFrame then
          InterfaceOptionsFrame_OpenToCategory(Tic.optionsFrame)
          InterfaceOptionsFrame_OpenToCategory(Tic.optionsFrame)
        end
        CloseDropDownMenus()
      end },
    { text = "Hide Minimap Button",
      notCheckable = true,
      func = function() Tic:Minimap_Show(false); CloseDropDownMenus() end },
    { text = "Cancel", notCheckable = true },
  }
  EasyMenu(menu, self.mm.menu, anchor or "cursor", 0, 0, "MENU", 2)
end

function Tic:Minimap_Create()
  self.mm = self.mm or {}
  if self.mm.btn then return end

  local b = CreateFrame("Button", "TicMinimapButton", Minimap)
  b:SetFrameStrata("MEDIUM")
  b:SetSize(32, 32)
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local overlay = b:CreateTexture(nil, "OVERLAY")
  overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  overlay:SetSize(56, 56)
  overlay:SetPoint("TOPLEFT")

  local icon = b:CreateTexture(nil, "BACKGROUND")
  icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark") -- change if desired
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 0)
  b.icon = icon

  -- Click behavior
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:SetScript("OnClick", function(_, btn)
    if btn == "LeftButton" then
      Tic:Minimap_ToggleUI()
    else
      Tic:Minimap_OpenMenu(b)
    end
  end)

  -- Shift-drag to move around rim
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", function(selfBtn)
    if IsShiftKeyDown() then
      selfBtn:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        local dx, dy = px - mx, py - my
        local angle = math.deg(math.atan2(dy, dx))
        if angle < 0 then angle = angle + 360 end
        Tic:Minimap_SetPosition(angle)
      end)
    end
  end)
  b:SetScript("OnDragStop", function(selfBtn) selfBtn:SetScript("OnUpdate", nil) end)

  -- Tooltip
  b:SetScript("OnEnter", function(selfBtn)
    GameTooltip:SetOwner(selfBtn, "ANCHOR_LEFT")
    GameTooltip:SetText("Tic", 1,1,1)
    GameTooltip:AddLine("Left-click: Show/Hide UI", 0.8,0.8,0.8)
    GameTooltip:AddLine("Right-click: Menu", 0.8,0.8,0.8)
    GameTooltip:AddLine("Shift-drag to move", 0.8,0.8,0.8)
    GameTooltip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

  self.mm.btn = b
  -- position & visibility from saved vars
  self:Minimap_SetPosition(self.db.profile.mm.angle or 200)
  self:Minimap_Show(self.db.profile.mm.shown ~= false)
end

-- ========================
-- Event helpers & misc
-- ========================
-- Valid hostile target?
function Tic:IsValidAttackableTarget()
  if not UnitExists("target") then return false end
  if UnitIsDead("target") then return false end
  if UnitIsFriend("player","target") then return false end
  if not UnitCanAttack("player","target") then return false end
  return true
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

-- CLEU (Wrath-compatible: no CombatLogGetCurrentEventInfo)
function Tic:COMBAT_LOG_EVENT_UNFILTERED(event, ...)
  local ts, subEvent, hideCaster,
        srcGUID, srcName, srcFlags, srcRaidFlags,
        dstGUID, dstName, dstFlags, dstRaidFlags,
        spellId, spellName, spellSchool, auraType

  if self.db.profile.debug then self:Printf("CLEU: %s", tostring((select(2, ...) or "???"))) end

  if CombatLogGetCurrentEventInfo then
    ts, subEvent, hideCaster,
    srcGUID, srcName, srcFlags, srcRaidFlags,
    dstGUID, dstName, dstFlags, dstRaidFlags,
    spellId, spellName, spellSchool, auraType = CombatLogGetCurrentEventInfo()
  else
    ts, subEvent, hideCaster,
    srcGUID, srcName, srcFlags, srcRaidFlags,
    dstGUID, dstName, dstFlags, dstRaidFlags,
    spellId, spellName, spellSchool, auraType = ...
  end

  if (subEvent == "SPELL_AURA_APPLIED" or subEvent == "SPELL_AURA_REMOVED")
     and dstGUID == UnitGUID("player") and self.db.profile.debug then
    self:Printf("%s %s (%d) on player", subEvent, spellName or "?", spellId or 0)
  end
end

-- ========================
-- Slash commands
-- ========================
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
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px defaults           - reset pos/size/spacing to defaults")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px clear              - set all three pixels to black")
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

  if a == "defaults" then
    local d = PX_DEFAULTS
    self.db.profile.pxBaseX   = d.baseX
    self.db.profile.pxBaseY   = d.baseY
    self.db.profile.pxSpacing = d.spacing
    self.db.profile.pxSize    = d.size
    if self.Pixel then
      self.Pixel:ApplySizes()
      self.Pixel:ApplyPositions()
    end
    self:Printf("Pixel defaults applied: x=%d y=%d spacing=%d size=%d",
      d.baseX, d.baseY, d.spacing, d.size)
    return
  end

  if a == "clear" then
    self:ClearPixels()
    self:Printf("Pixels cleared (all black).")
    return
  end

  if a == "test" then
    self.Pixel:TestCycle()
    return
  end

  self:Printf("Unknown px cmd. /tic px help")
end

function Tic:GetSpecListForClass(eng) return self.ClassSpecs[eng or self.playerClass or ""] or {} end
function Tic:GetSpecType() return (self.db and self.db.profile and self.db.profile.specType) or "auto" end
function Tic:SetSpecType(spec)
  spec = (spec or ""):lower()
  if spec == "auto" then
    self.db.profile.specType = "auto"
    self:Printf("Spec set to: auto")
    self:UIRefresh()
    return true
  end
  local ok = false
  for _, s in ipairs(self:GetSpecListForClass()) do if s == spec then ok = true break end end
  if ok then
    self.db.profile.specType = spec
    self:Printf("Spec set to: %s", spec)
    self:UIRefresh()
    return true
  else
    self:Printf("Unknown spec %q for %s. Options: %s",
      spec, tostring(self.playerClass or "?"), table.concat(self:GetSpecListForClass(), ", "))
    return false
  end
end

function Tic:ActivateSpecByIndex(i)
  local list = self:GetSpecListForClass(self.playerClass)
  local spec = list[i]
  if spec then
    self:SetSpecType(spec)
  else
    if self.db.profile.debug then self:Printf("No spec%d for %s", i, tostring(self.playerClass or "?")) end
  end
end

function Tic:HandleSlash(msg)
  msg = trim(msg or "")
  local sub, rest = msg:match("^(%S+)%s*(.*)$")
  if not sub or sub == "" then
    self:Printf("Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic options                - open config (if installed)")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic px help                - pixel beacon help")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic ui help                - HUD controls")
    DEFAULT_CHAT_FRAME:AddMessage("  /tic spec                   - show/set spec")
    return
  end

  if sub == "options" or sub == "opt" then
    if self.optionsFrame then
      InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
      InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
    else
      self:Printf("Options panel not available.")
    end
    return
  end

  if sub == "px" then self:HandlePx(rest); return end

  if sub == "ui" then
    local cmd, val = rest:match("^(%S*)%s*(.*)$"); cmd = (cmd or ""):lower()
    if cmd == "" or cmd == "help" then
      self:Printf("UI:")
      DEFAULT_CHAT_FRAME:AddMessage("  /tic ui show|hide|toggle")
      DEFAULT_CHAT_FRAME:AddMessage("  /tic ui lock|unlock")
      DEFAULT_CHAT_FRAME:AddMessage("  /tic ui scale <0.5..2.0>")
      DEFAULT_CHAT_FRAME:AddMessage("  /tic ui alpha <0.1..1.0>")
      DEFAULT_CHAT_FRAME:AddMessage("  /tic ui cols <n>")
      DEFAULT_CHAT_FRAME:AddMessage("  /tic ui reset               - reset HUD to defaults & center")
      return
    elseif cmd == "show" or cmd == "hide" or cmd == "toggle" then
      if cmd == "toggle" then self.db.profile.uiEnabled = not self.db.profile.uiEnabled
      else self.db.profile.uiEnabled = (cmd == "show") end
      self:UIBuild()
      self:Printf("UI %s", self.db.profile.uiEnabled and "shown" or "hidden")
      return
    elseif cmd == "lock" or cmd == "unlock" then
      self.db.profile.uiLocked = (cmd == "lock")
      self:Printf("UI is now %s", self.db.profile.uiLocked and "locked" or "unlocked")
      return
    elseif cmd == "scale" then
      local n = tonumber(val); if not n then self:Printf("Usage: /tic ui scale <number>"); return end
      self.db.profile.uiScale = n; self:UIBuild(); return
    elseif cmd == "alpha" then
      local n = tonumber(val); if not n then self:Printf("Usage: /tic ui alpha <0.1..1.0>"); return end
      self.db.profile.uiAlpha = n; self:UIBuild(); return
    elseif cmd == "cols" then
      local n = tonumber(val); if not n then self:Printf("Usage: /tic ui cols <n>"); return end
      self.db.profile.uiCols = max(1, floor(n)); self:UIBuild(); return
    elseif cmd == "reset" then
      self:UIResetAll(); return
    else
      self:Printf("Usage: /tic ui help"); return
    end
  end

  if sub == "spec" then
    local cmd, val = rest:match("^(%S*)%s*(.*)$")
    cmd = (cmd or ""):lower()
    val = (val or ""):lower()
    if cmd == "" or cmd == "get" then
      local list = table.concat(self:GetSpecListForClass(self.playerClass), ", ")
      self:Printf("Spec: %s (class=%s). Options: %s",
        self:GetSpecType(), tostring(self.playerClass or "?"), list ~= "" and list or "—")
    elseif cmd == "set" and val ~= "" then
      self:SetSpecType(val)
    elseif cmd == "next" then
      local list = self:GetSpecListForClass(self.playerClass)
      if #list == 0 then self:Printf("No spec list for class %s.", tostring(self.playerClass or "?")); return end
      local cur = self:GetSpecType()
      local idx = 1
      for i, s in ipairs(list) do if s == cur then idx = i break end end
      idx = ((idx) % #list) + 1
      self:SetSpecType(list[idx])
    elseif cmd == "prev" or cmd == "previous" then
      local list = self:GetSpecListForClass(self.playerClass)
      if #list == 0 then self:Printf("No spec list for class %s.", tostring(self.playerClass or "?")); return end
      local cur = self:GetSpecType()
      local idx = 1
      for i, s in ipairs(list) do if s == cur then idx = i break end end
      idx = ((idx - 2) % #list) + 1
      self:SetSpecType(list[idx])
    else
      self:Printf("Usage: /tic spec [get|set <spec>|next|prev]")
    end
    return
  end

  if sub == "diag" then
    local cls = tostring(self.playerClass or "?")
    local spec = self:GetSpecType()
    local rotShown = self._rotFrame and self._rotFrame:IsShown() and "yes" or "no"
    local binds = (self.bindings and #self.bindings.list) or 0
    self:Printf("diag: class=%s spec=%s rotShown=%s bindings=%d", cls, spec, rotShown, binds)
    return
  end

  self:Printf("Unknown command. Try /tic, /tic px help, /tic ui help, /tic spec")
end

-- ========================
-- Ace lifecycle
-- ========================
function Tic:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("TicDB", defaults, true)

  -- Optional: register a minimal options panel placeholder (so /tic options works)
  local ACR = LibStub("AceConfig-3.0", true); local ACD = LibStub("AceConfigDialog-3.0", true)
  if ACR and ACD and self.GetOptionsTable then
    ACR:RegisterOptionsTable("Tic", self:GetOptionsTable().general)
    self.optionsFrame = ACD:AddToBlizOptions("Tic", "Tic")
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
  -- Events
  self:RegisterEvent("UI_SCALE_CHANGED", "_OnScaleChanged")
  self:RegisterEvent("PLAYER_ENTERING_WORLD", "_OnScaleChanged")
  self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

  -- Pixels (beacons)
  self.Pixel = self.Pixel or Tic_Pixels:New(self)
  self.Pixel:ApplyAll()  -- build frames & place them

  -- Class & dynamic default spec
  local displayName, token = UnitClass("player")  -- "Druid", "DRUID"
  self.playerClass = token
  if not self.db.profile.specType or self.db.profile.specType == "" then
    local first = self.ClassSpecs[token] and self.ClassSpecs[token][1] or nil
    self.db.profile.specType = first or "auto"
    if first then
      self:Printf("No saved spec; defaulting to [%s] for class [%s].", first, token)
    else
      self:Printf("No saved spec and no class spec list found; using [auto].")
    end
  end

  -- Class bootstrap (bindings and per-spec HUD lists defined in Rotations.lua)
  if self.InitForClass then self:InitForClass(self.playerClass) end

  -- Rotation OnUpdate dispatcher (ensure frame is shown)
  if not self._rotFrame then
    self._rotFrame = CreateFrame("Frame", "TicRotationFrame")
    self._rotFrame:SetScript("OnUpdate", function(_, elapsed)
      if self.UpdateForClass then self:UpdateForClass(elapsed) end
    end)
  end
  self._rotFrame:Show()

  -- Optional OnUpdate logger
  if not self._updateFrame then
    self._updateFrame = CreateFrame("Frame", "TicUpdateFrame")
    self._updateAccum = 0
    self._updateFrame:SetScript("OnUpdate", function(_, elapsed)
      self._updateAccum = self._updateAccum + elapsed
      local thr = self.db.profile.throttle or 0.10
      if self._updateAccum >= thr then
        if self.db.profile.debugOnUpdate then
          -- self:Printf("[OnUpdate] tick (Δ=%.3f)", self._updateAccum)
        end
        self._updateAccum = 0
      end
    end)
  end
  self:_RefreshOnUpdateVisibility()

  -- HUD + minimap
  self:UIBuild()
  self:Minimap_Create()

  -- Final notes
  self:Printf("Class: %s  |  Spec: %s", tostring(self.playerClass or "?"), tostring(self.db.profile.specType or "auto"))
  self:Printf("Loaded. /tic ui  |  /tic px help  |  /tic spec")
end

function Tic:OnDisable()
  if self._updateFrame then self._updateFrame:Hide() end
  if self.Pixel then self.Pixel:Show(false) end
end

-- Exposed for Options.lua (if present)
Tic._GetAddon = function() return Tic end
