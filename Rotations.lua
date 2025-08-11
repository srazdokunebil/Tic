local AceAddon = LibStub("AceAddon-3.0")
local Tic = AceAddon:GetAddon("Tic", true)
if not Tic then
  DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Tic]|r Rotations.lua loaded too early; check TOC order.")
  return
end

-- Mark inits so we don’t double-bind
Tic._classInited = Tic._classInited or {}

-- =========================================================
-- Class Initializers (bind keys once, and register per-spec UI toggles)
-- =========================================================

-- DRUID init
function Tic:_Init_DRUID()
  if self._classInited.DRUID then return end
  self:Printf("druid class initializing buttons")

  -- Bindings (shared across specs for now)
  tic_bind_key("Moonkin Form")
  tic_bind_key("Faerie Fire")
  tic_bind_key("Moonfire")
  tic_bind_key("Insect Swarm")
  tic_bind_key("Wrath")
  tic_bind_key("Starfire")
  tic_bind_key("Starfall")

  -- Register UI toggles PER SPEC so the HUD shows the right set on spec change
  -- heal (resto) — empty example (add what you want visible in healer HUD)
  self:RegisterSpecTogglesFor("DRUID", "heal", {
    -- e.g., "Rejuvenation", "Regrowth", "Lifebloom"
  })

  -- mdps (feral cat) — placeholder
  self:RegisterSpecTogglesFor("DRUID", "mdps", {
    -- e.g., "Mangle (Cat)", "Rip", "Rake"
  })

  -- rdps (balance / moonkin)
  self:RegisterSpecTogglesFor("DRUID", "rdps", {
    "Faerie Fire",
    "Moonfire",
    "Insect Swarm",
    "Wrath",
    "Starfire",
    "Starfall",
  })

  -- tank (bear) — placeholder
  self:RegisterSpecTogglesFor("DRUID", "tank", {
    -- e.g., "Mangle (Bear)", "Lacerate", "Swipe (Bear)"
  })

  self._classInited.DRUID = true
end

-- WARLOCK init
function Tic:_Init_WARLOCK()
  if self._classInited.WARLOCK then return end
  self:Printf("warlock class initializing buttons")

  -- Bindings (shared across specs for now)
  tic_bind_key("Corruption")
  tic_bind_key("Unstable Affliction")
  tic_bind_key("Shadow Bolt")
  tic_bind_key("Haunt")
  tic_bind_key("Curse of Agony")

  -- Per‑spec HUD toggles
  self:RegisterSpecTogglesFor("WARLOCK", "dsr", { -- demo/sac/ruin (your nomenclature)
    -- add your dsr toggles here
  })
  self:RegisterSpecTogglesFor("WARLOCK", "md", {  -- meta/destro? (your nomenclature)
    -- add your md toggles here
  })
  self:RegisterSpecTogglesFor("WARLOCK", "sm", {  -- affliction? (your nomenclature)
    "Corruption",
    "Unstable Affliction",
    "Haunt",
    "Curse of Agony",
    "Shadow Bolt",
  })

  self._classInited.WARLOCK = true
end

-- Other classes (stubs; register per-spec HUD lists here as you build them)
function Tic:_Init_DEATHKNIGHT() if self._classInited.DEATHKNIGHT then return end; self._classInited.DEATHKNIGHT = true end
function Tic:_Init_HUNTER()      if self._classInited.HUNTER      then return end; self._classInited.HUNTER = true end
function Tic:_Init_MAGE()        if self._classInited.MAGE        then return end; self._classInited.MAGE = true end
function Tic:_Init_PALADIN()     if self._classInited.PALADIN     then return end; self._classInited.PALADIN = true end
function Tic:_Init_PRIEST()      if self._classInited.PRIEST      then return end; self._classInited.PRIEST = true end
function Tic:_Init_ROGUE()       if self._classInited.ROGUE       then return end; self._classInited.ROGUE = true end
function Tic:_Init_SHAMAN()      if self._classInited.SHAMAN      then return end; self._classInited.SHAMAN = true end
function Tic:_Init_WARRIOR()     if self._classInited.WARRIOR     then return end; self._classInited.WARRIOR = true end

-- Called by Core.lua after it sets self.playerClass
function Tic:InitForClass(eng)
  local fn = self["_Init_"..eng]
  if fn then fn(self) else self:Printf("No init for class %s", tostring(eng)) end
end

-- =========================================================
-- Rotations (spec switch handled INSIDE the class updater)
-- =========================================================

-- DRUID per-frame rotation (your logic with spec switch)
function Tic:_Update_DRUID(elapsed)
  if self.db.profile.debug then print("druid spec:"..tostring(self.db.profile.specType)) end

  local spec = self.db.profile.specType
  if spec == "heal" then
    Tic:ClearPixels()

  elseif spec == "mdps" then
    Tic:ClearPixels()

  elseif spec == "rdps" then
    if not self:IsValidAttackableTarget() then Tic:ClearPixels() return end

    local inMoonkinForm   = Tic:AmInMoonkinForm() or nil
    local hasFaerieFire   = UnitDebuff("target", "Faerie Fire")
    local hasInsectSwarm  = UnitDebuff("target", "Insect Swarm")
    local hasMoonfire     = UnitDebuff("target", "Moonfire")
    local haveLunarEclipse= UnitBuff("player", "Eclipse (Lunar)")
    local haveSolarEclipse= UnitBuff("player", "Eclipse (Solar)")
    local starfallReady   = IsUsableSpell("Starfall") and (GetSpellCooldown("Starfall") == 0)

    if not inMoonkinForm then
      Tic_castSpellByName("Moonkin Form")
    elseif haveLunarEclipse then
      Tic_castSpellByName("Starfire"); return
    elseif haveSolarEclipse then
      Tic_castSpellByName("Wrath"); return
    elseif not hasFaerieFire and self:IsSpellEnabled("Faerie Fire") then
      Tic_castSpellByName("Faerie Fire"); return
    elseif not hasMoonfire then
      Tic_castSpellByName("Moonfire"); return
    elseif not hasInsectSwarm then
      Tic_castSpellByName("Insect Swarm"); return
    elseif starfallReady and hasMoonfire and hasInsectSwarm then
      Tic_castSpellByName("Starfall"); return
    elseif not haveLunarEclipse and hasMoonfire and hasInsectSwarm and self:IsSpellEnabled("Wrath") then
      Tic_castSpellByName("Wrath"); return
    else
      Tic:ClearPixels()
    end

  elseif spec == "tank" then
    Tic:ClearPixels()
  else
    -- unknown spec token -> do nothing
    Tic:ClearPixels()
  end
end

-- WARLOCK per-frame rotation (your logic with spec switch)
function Tic:_Update_WARLOCK(elapsed)
  if self.db.profile.debug then print("warlock spec:"..tostring(self.db.profile.specType)) end

  local spec = self.db.profile.specType
  if spec == "dsr" then
    Tic:ClearPixels()

  elseif spec == "md" then
    Tic:ClearPixels()

  elseif spec == "sm" then
    if not self:IsValidAttackableTarget() then Tic:ClearPixels() return end
    local hasCorruption = UnitDebuff("target", "Corruption")
    local hasCurseOfAgony = UnitDebuff("target", "Curse of Agony")
    local hasHaunt = UnitDebuff("target", "Haunt")
    local hasUnstableAffliction = UnitDebuff("target", "Unstable Affliction")

    if not hasUnstableAffliction then
      Tic_castSpellByName("Unstable Affliction"); return
    elseif not hasCorruption then
      Tic_castSpellByName("Corruption"); return
    elseif not hasHaunt then
      Tic_castSpellByName("Haunt"); return
    elseif not hasCurseOfAgony then
      Tic_castSpellByName("Curse of Agony"); return
    elseif hasCurseOfAgony and hasCorruption and hasHaunt then
      Tic_castSpellByName("Shadow Bolt"); return
    else
      Tic:ClearPixels()
    end

  else
    Tic:ClearPixels()
  end
end

-- Other classes (stubs)
function Tic:_Update_DEATHKNIGHT(elapsed) end
function Tic:_Update_HUNTER(elapsed)      end
function Tic:_Update_MAGE(elapsed)        end
function Tic:_Update_PALADIN(elapsed)     end
function Tic:_Update_PRIEST(elapsed)      end
function Tic:_Update_ROGUE(elapsed)       end
function Tic:_Update_SHAMAN(elapsed)      end
function Tic:_Update_WARRIOR(elapsed)     end

-- Dispatcher called every frame from Core.lua
function Tic:UpdateForClass(elapsed)
  if not self.playerClass then return end
  local fn = self["_Update_"..self.playerClass]  -- ONLY class-generic updater
  if fn then fn(self, elapsed) end
end
