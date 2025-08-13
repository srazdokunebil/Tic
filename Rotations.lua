--[[
update logs:
8-11-26
added display spell icon
added debuff check function
added affliction warlock rotation.

8-12-26
added frost dk rotation.

]]--

local AceAddon = LibStub("AceAddon-3.0")
local Tic = AceAddon:GetAddon("Tic", true)
if not Tic then
  DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Tic]|r Rotations.lua loaded too early; check TOC order.")
  return
end

-- Mark inits so we don’t double-bind
Tic._classInited = Tic._classInited or {}


function ouch_getdebuff(unit, spell, filter, seconds_to_cast_before_spell_falls_off)
	if filter and not filter:upper():find("FUL") then
		filter = filter.."|HARMFUL"
		if seconds_to_cast_before_spell_falls_off == nil then seconds_to_cast_before_spell_falls_off = 0 end
	for i = 1, 125 do
		local name, _, _, _, _, _, expirationTime, _, _, _, spellId = UnitAura(unit, i, filter)
		if not name then 
			return end
		if (spell == spellId or spell == name) and ((expirationTime - GetTime()) < seconds_to_cast_before_spell_falls_off ) then
			return end

		if spell == spellId or spell == name then
		  return UnitAura(unit, i, filter)

		end
	  end
	end

end		
--draw spell icon on screen
-- Global references to the frame and texture for easy access in functions
local MySpellIconFrame;
local spellTexture;
local spellCastButton; -- Global reference for the button
-- Global reference to the frame and texture for easy access in functions
local MySpellIconFrame; 
local spellTexture; 

-- Function to set the spell icon and schedule the reset
function SetSpellIcon(spellID)
    -- Ensure the frame and texture exist
    if not MySpellIconFrame then
        -- This part will only run once when the addon loads initially
        MySpellIconFrame = CreateFrame("Frame", "MySpellIconFrame", UIParent);
        MySpellIconFrame:SetSize(64, 64);
        MySpellIconFrame:SetPoint("CENTER", UIParent, "CENTER");
        MySpellIconFrame:SetFrameStrata("BACKGROUND");

        MySpellIconFrame:EnableMouse(true); 
        MySpellIconFrame:SetMovable(true);
        MySpellIconFrame:RegisterForDrag("LeftButton"); 

        MySpellIconFrame:SetScript("OnDragStart", function(self)
            self:StartMoving();
        end);

        MySpellIconFrame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing();
        end);

        spellTexture = MySpellIconFrame:CreateTexture(nil, "BACKGROUND");
        spellTexture:SetAllPoints(MySpellIconFrame);
        MySpellIconFrame:Show(); --

    end

    local _, _, spellIcon = GetSpellInfo(spellID); 

    if spellIcon then
        spellTexture:SetTexture(spellIcon);

    else
        print("Error: Could not retrieve spell icon for Spell ID:", spellID);
    end
end
-- =========================================================
-- Class Initializers (bind keys once, and register per-spec UI toggles)
-- =========================================================
--DEATHKNIGHT init
function Tic:_Init_DEATHKNIGHT()
  if self._classInited.DEATHKNIGHT then return end
  self:Printf("DEATHKNIGHT class initializing buttons")
  
  -- Bindings (shared across specs for now)
    local deathKnightAbilities = {
      "Icy Touch",
      "Plague Strike",
      "Pestilence",
      "Frost Strike",
      "Obliterate",
      "Horn of Winter",
      "Howling Blast",
      "Blood Strike",
      "Auto Attack",
      "Unbreakable Armor"
    }

  -- Bindings (shared across specs for now)
  for i, abilityName in ipairs(deathKnightAbilities) do -- Use the new variable name here
    tic_bind_key(abilityName)
  end
  -- Register UI toggles PER SPEC so the HUD shows the right set on spec change
  -- heal (resto) — empty example (add what you want visible in healer HUD)
  self:RegisterSpecTogglesFor("DEATHKNIGHT", "blood", {
    -- e.g., "Rejuvenation", "Regrowth", "Lifebloom"
  })

  -- mdps (feral cat) — placeholder
  self:RegisterSpecTogglesFor("DEATHKNIGHT", "frost", deathKnightAbilities) -- Use the new variable name here

  -- rdps (balance / moonkin)
  self:RegisterSpecTogglesFor("DEATHKNIGHT", "unholy", {

  })

  -- tank (bear) — placeholder
  self:RegisterSpecTogglesFor("DEATHKNIGHT", "tank", {
    -- e.g., "Mangle (Bear)", "Lacerate", "Swipe (Bear)"
  })

  self._classInited.DEATHKNIGHT = true
end

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
  tic_bind_key("Drain Soul")
  tic_bind_key("Life Tap")
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
	"Drain Soul",
	"Life Tap",
  })

  self._classInited.WARLOCK = true
end

-- Other classes (stubs; register per-spec HUD lists here as you build them)
--function Tic:_Init_DEATHKNIGHT() if self._classInited.DEATHKNIGHT then return end; self._classInited.DEATHKNIGHT = true end
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
    if ((UnitCastingInfo("player")) or UnitChannelInfo("player"))then Tic:ClearPixels() return end
    local hasCorruption = UnitDebuff("target", "Corruption")
    local hasCurseOfAgony = UnitDebuff("target", "Curse of Agony")
    local hasHaunt = UnitDebuff("target", "Haunt")
    local hasUnstableAffliction = UnitDebuff("target", "Unstable Affliction")
	local haveLifeTap, _, _, _, _, _, expireLifeTap = UnitBuff("player", "Life Tap")

		if (UnitHealth("player") / UnitHealthMax("player") > 0.10) and not haveLifeTap then
			Tic_castSpellByName("Life Tap")
			SetSpellIcon("Life Tap")
			return
		end

		if (UnitHealth("player") / UnitHealthMax("player") > 0.10) and (UnitPower("player",0) / UnitPowerMax("player", 0)) < 0.10 then
			Tic_castSpellByName("Life Tap")
			SetSpellIcon("Life Tap")
			return
		end	

		if not ouch_getdebuff("target", "Corruption", "player") then
			Tic_castSpellByName("Corruption")
			SetSpellIcon("Corruption")
			return
		end

		if not ouch_getdebuff("target", "Haunt", "player", 4) then
			Tic_castSpellByName("Haunt")
			SetSpellIcon("Haunt")
			return
		end

		if not ouch_getdebuff("target", "Unstable Affliction", "player",1) then
			Tic_castSpellByName("Unstable Affliction")
			SetSpellIcon("Unstable Affliction")
			return
		end

		if not ouch_getdebuff("target", "Curse of Agony", "player") and (UnitHealth("target") / UnitHealthMax("target") > 0.02) then
			Tic_castSpellByName("Curse of Agony")
			SetSpellIcon("Curse of Agony")
			return
		end


		if (UnitHealth("target") / UnitHealthMax("target") > 0.25) then
			Tic_castSpellByName("Shadow Bolt")
			SetSpellIcon("Shadow Bolt")
			return	
		else
			Tic_castSpellByName("Drain Soul")
			SetSpellIcon("Drain Soul")
		end

  else
    Tic:ClearPixels()
  end
end
-- Other classes (stubs)
function Tic:_Update_DEATHKNIGHT(elapsed)
  if self.db.profile.debug then print("deathknight spec:"..tostring(self.db.profile.specType)) end

  local spec = self.db.profile.specType
  if spec == "blood" then
    Tic:ClearPixels()

  elseif spec == "frost" then
    if not self:IsValidAttackableTarget() then Tic:ClearPixels() return end
    if ((UnitCastingInfo("player")) or UnitChannelInfo("player"))then Tic:ClearPixels() return end
    local BloodStrikeReady   = IsUsableSpell("Blood Strike") and (GetSpellCooldown("Blood Strike") == 0)
    local PestilenceReady  = IsUsableSpell("Blood Strike") and (GetSpellCooldown("Pestilence") == 0)
    local UnbreakableArmorReady  = IsUsableSpell("Unbreakable Armor") and (GetSpellCooldown("Unbreakable Armor") == 0)
    local HornofWinterReady  = IsUsableSpell("Horn of Winter") and (GetSpellCooldown("Horn of Winter") == 0)

    local haveKillingMachine, _, _, _, _, _, expireKillingMachine = UnitBuff("player", "Killing Machine")
    local haveHornofWinter, _, _, _, _, _, expireHornofWinter = UnitBuff("player", "Horn of Winter")
    local haveFreezingFog, _, _, _, _, _, expireFreezingFog = UnitBuff("player", "Freezing Fog")
    local haveUnbreakableArmor, _, _, _, _, _, expireUnbreakableArmor = UnitBuff("player", "Unbreakable Armor")

    local dkt_runes = {}
    local runicPower = UnitPower("player", 6) --6 is for runic power http://wowprogramming.com/docs/api_types#powerType
    --local spellrandom = math.random(1, 100)
    function dkt_isRuneReady(runeType)
      local runeReady = false
      -- There are 6 rune slots for Death Knights.
      for i = 1, 6 do
          local start, duration, currentRuneReady = GetRuneCooldown(i)
  
          -- If the rune is off cooldown, proceed to check its type.
          if currentRuneReady then
              -- The script will attempt to guess the rune type based on the rune index and potentially some heuristics.
              -- This is an approximation and might not be perfectly accurate in all situations, 
              -- but it's the closest that can be done without GetRuneType.
              -- A more robust approach might involve tracking rune conversions, but that's more complex.
  
              -- Example: Assume the first two are Blood, the next two are Frost, and the last two are Unholy.
              -- This is a very common Death Knight setup.
              if runeType == "BLOOD" and (i == 1 or i == 2) then
                  runeReady = true
                  break
              elseif runeType == "FROST" and (i == 3 or i == 4) then
                  runeReady = true
                  break
              elseif runeType == "UNHOLY" and (i == 5 or i == 6) then
                  runeReady = true
                  break
              -- Handling Death Runes: Death Runes act as any type, so if a Death Rune is ready, it's ready for any type.
              elseif runeType == "DEATH" then -- (Death runes count as a wildcard of any type)
                  runeReady = true
                  break
              end
          end
      end
      return runeReady
  end

    if dkt_isRuneReady("FROST") and not ouch_getdebuff("target", "Frost Fever", "player") then
			Tic_castSpellByName("Icy Touch")
			SetSpellIcon("Icy Touch")
      return
		end

    if dkt_isRuneReady("UNHOLY") and not ouch_getdebuff("target", "Blood Plague", "player") then
			Tic_castSpellByName("Plague Strike")
			SetSpellIcon("Plague Strike")
      return
		end

    if dkt_isRuneReady("UNHOLY") and dkt_isRuneReady("FROST") then
			Tic_castSpellByName("Obliterate")
			SetSpellIcon("Obliterate")
      return
		end
 
    if (ouch_getdebuff("target", "Frost Fever", "player", 10)) and BloodStrikeReady and (dkt_isRuneReady("BLOOD") or dkt_isRuneReady("DEATH")) then
          Tic_castSpellByName("Blood Strike")
          SetSpellIcon("Blood Strike")
          return
        end

         
    if PestilenceReady and (dkt_isRuneReady("BLOOD") or dkt_isRuneReady("DEATH")) then
      Tic_castSpellByName("Pestilence")
      SetSpellIcon("Pestilence")
      return
    end

		if runicPower >= 40 and haveKillingMachine then
			Tic_castSpellByName("Frost Strike")
			SetSpellIcon("Frost Strike")			
			return
		end

    if UnbreakableArmorReady and (dkt_isRuneReady("FROST") or dkt_isRuneReady("DEATH"))then
			Tic_castSpellByName("Unbreakable Armor")
			SetSpellIcon("Unbreakable Armor")
			return
		end
		-- added mana check
		if haveFreezingFog then
			Tic_castSpellByName("Howling Blast")
			SetSpellIcon("Howling Blast")			
			return
		end

    if (not haveHornofWinter) and HornofWinterReady then
			Tic_castSpellByName("Horn of Winter")
			SetSpellIcon("Horn of Winter")
			return
		end

		if runicPower >= 99  then
			Tic_castSpellByName("Frost Strike")
			SetSpellIcon("Frost Strike")
			return	
		else
			Tic_castSpellByName("Auto Attack")
			SetSpellIcon("Auto Attack")
		end


  elseif spec == "unholy" then
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
