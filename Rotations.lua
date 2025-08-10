local AceAddon = LibStub("AceAddon-3.0")
local Tic = AceAddon:GetAddon("Tic", true)
if not Tic then
  DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Tic]|r Rotations.lua loaded too early; check TOC order.")
  return
end

local Tic = LibStub("AceAddon-3.0"):GetAddon("Tic")

-- Mark inits so we don’t double-bind
Tic._classInited = Tic._classInited or {}

-- DRUID init (binds spells -> CTRL+1..)
function Tic:_Init_DRUID()
  if self._classInited.DRUID then return end
  self:Printf("druid class initializing buttons")
  tic_bind_key("Moonkin Form")
  tic_bind_key("Faerie Fire")
  tic_bind_key("Moonfire")
  tic_bind_key("Insect Swarm")
  tic_bind_key("Wrath")
  tic_bind_key("Starfire")
  tic_bind_key("Starfall")

  -- Make these appear as toggles in the UI (enable/disable per spell)
  self:RegisterSpecToggles({
    "Faerie Fire",
    "Moonfire",
    "Insect Swarm",
    "Wrath",
    "Starfire",
    "Starfall",
  })

  self._classInited.DRUID = true
end

-- WARLOCK init (binds spells -> CTRL+1..)
function Tic:_Init_WARLOCK()
  if self._classInited.WARLOCK then return end
  self:Printf("warlock class initializing buttons")
  tic_bind_key("Corruption")
  tic_bind_key("Shadow Bolt")

  -- Make these appear as toggles in the UI (enable/disable per spell)
  self:RegisterSpecToggles({
    "Corruption",
    "Shadow Bolt",
  })

  self._classInited.WARLOCK = true
end


-- Other classes (stubs)
function Tic:_Init_DEATHKNIGHT() if self._classInited.DEATHKNIGHT then return end; self._classInited.DEATHKNIGHT = true end
function Tic:_Init_HUNTER()      if self._classInited.HUNTER      then return end; self._classInited.HUNTER = true end
function Tic:_Init_MAGE()        if self._classInited.MAGE        then return end; self._classInited.MAGE = true end
function Tic:_Init_PALADIN()     if self._classInited.PALADIN     then return end; self._classInited.PALADIN = true end
function Tic:_Init_PRIEST()      if self._classInited.PRIEST      then return end; self._classInited.PRIEST = true end
function Tic:_Init_ROGUE()       if self._classInited.ROGUE       then return end; self._classInited.ROGUE = true end
function Tic:_Init_SHAMAN()      if self._classInited.SHAMAN      then return end; self._classInited.SHAMAN = true end
function Tic:_Init_WARLOCK()     if self._classInited.WARLOCK     then return end; self._classInited.WARLOCK = true end
function Tic:_Init_WARRIOR()     if self._classInited.WARRIOR     then return end; self._classInited.WARRIOR = true end

-- Called by Core.lua after it sets self.playerClass
function Tic:InitForClass(eng)
  local spec = self:GetSpecType()
  local fn
  if spec ~= "auto" then
    fn = self["_Init_"..eng.."_"..spec]
  end
  if not fn then
    fn = self["_Init_"..eng]
  end
  if fn then fn(self) else self:Printf("No init for class %s", tostring(eng)) end
end

-- DRUID per-frame rotation (YOUR logic)
function Tic:_Update_DRUID(elapsed)
  -- Loud print so you can confirm it runs
  if self.db.profile.debug then print("druid spec:"..tostring(self.db.profile.specType)) end

  if self.db.profile.specType == "holy" then
    Tic:ClearPixels()
  elseif self.db.profile.specType == "mdps" then
    Tic:ClearPixels()
  elseif self.db.profile.specType == "rdps" then
    if not self:IsValidAttackableTarget() then Tic:ClearPixels() return end

    local inMoonkinForm = Tic:AmInMoonkinForm()
    local hasFaerieFire = UnitDebuff("target", "Faerie Fire")
    local hasInsectSwarm = UnitDebuff("target", "Insect Swarm")
    local hasMoonfire = UnitDebuff("target", "Moonfire")
    local haveLunarEclipse = UnitBuff("player", "Eclipse (Lunar)")
    local haveSolarEclipse = UnitBuff("player", "Eclipse (Solar)")
    local starfallReady = IsUsableSpell("Starfall") and (GetSpellCooldown("Starfall") == 0)

    if not inMoonkinForm then
      Tic_castSpellByName("Moonkin Form")
    elseif haveLunarEclipse then
      Tic_castSpellByName("Starfire")
      return
    elseif haveSolarEclipse then
      Tic_castSpellByName("Wrath")
      return
    elseif not hasFaerieFire and self:IsSpellEnabled("Faerie Fire") then
      Tic_castSpellByName("Faerie Fire")
      return
    elseif not hasMoonfire then
      Tic_castSpellByName("Moonfire")
      return
    elseif not hasInsectSwarm then
      Tic_castSpellByName("Insect Swarm")
      return
    elseif starfallReady and hasMoonfire and hasInsectSwarm then
      Tic_castSpellByName("Starfall")
       return
    elseif not haveLunarEclipse and hasMoonfire and hasInsectSwarm and self:IsSpellEnabled("Wrath") then
      Tic_castSpellByName("Wrath")
      return
    else
      Tic:ClearPixels()
    end
  elseif self.db.profile.specType == "tank" then
    Tic:ClearPixels()
  end

  -- add your other conditions…
end

-- WARLOCK per-frame rotation (YOUR logic)
function Tic:_Update_WARLOCK(elapsed)
  -- Loud print so you can confirm it runs
  if self.db.profile.debug then print("warlock spec:"..tostring(self.db.profile.specType)) end

  if self.db.profile.specType == "dsr" then
    Tic:ClearPixels()
  elseif self.db.profile.specType == "md" then
    Tic:ClearPixels()
  elseif self.db.profile.specType == "sm" then
    if not self:IsValidAttackableTarget() then Tic:ClearPixels() return end
    local hasCorruption = UnitDebuff("target", "Corruption")
    if not hasCorruption then
      Tic_castSpellByName("Corruption")
    elseif hasCorruption then
      Tic_castSpellByName("Shadow Bolt")
      return
    else
      Tic:ClearPixels()
    end
  end

  -- add your other conditions…
end

-- Other classes (stubs)
function Tic:_Update_DEATHKNIGHT(elapsed) end
function Tic:_Update_HUNTER(elapsed)      end
function Tic:_Update_MAGE(elapsed)        end
function Tic:_Update_PALADIN(elapsed)     end
function Tic:_Update_PRIEST(elapsed)      end
function Tic:_Update_ROGUE(elapsed)       end
function Tic:_Update_SHAMAN(elapsed)      end
function Tic:_Update_WARLOCK(elapsed)     end
function Tic:_Update_WARRIOR(elapsed)     end

-- Dispatcher called every frame from Core.lua
function Tic:UpdateForClass(elapsed)
  if not self.playerClass then return end
  local spec = self:GetSpecType()
  local fn
  if spec ~= "auto" then
    fn = self["_Update_"..self.playerClass.."_"..spec]  -- e.g., _Update_DRUID_rdps
  end
  if not fn then
    fn = self["_Update_"..self.playerClass]             -- fallback: class-generic
  end
  if fn then fn(self, elapsed) end
end


