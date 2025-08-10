local Tic = LibStub("AceAddon-3.0"):GetAddon("Tic")

-- Track per-class init so we don’t bind duplicates
Tic._classInited = Tic._classInited or {}

-- ---- Class initializers ----

function Tic:_Init_DRUID()
  if self._classInited.DRUID then return end
  self:Printf("druid class initializing buttons")

  tic_bind_key("Moonkin Form")  -- #1 -> CTRL-1
  tic_bind_key("Faerie Fire")   -- #2 -> CTRL-2
  tic_bind_key("Moonfire")      -- #3 -> CTRL-3
  tic_bind_key("Insect Swarm")  -- #4 -> CTRL-4
  tic_bind_key("Wrath")         -- #5 -> CTRL-5
  tic_bind_key("Starfire")      -- #6 -> CTRL-6
  tic_bind_key("Starfall")      -- #7 -> CTRL-7

  self._classInited.DRUID = true
end

-- Skeletons for the rest; fill as you go
function Tic:_Init_DEATHKNIGHT() if self._classInited.DEATHKNIGHT then return end; self:Printf("death knight init"); self._classInited.DEATHKNIGHT = true end
function Tic:_Init_HUNTER()      if self._classInited.HUNTER      then return end; self:Printf("hunter init");      self._classInited.HUNTER = true end
function Tic:_Init_MAGE()        if self._classInited.MAGE        then return end; self:Printf("mage init");        self._classInited.MAGE = true end
function Tic:_Init_PALADIN()     if self._classInited.PALADIN     then return end; self:Printf("paladin init");     self._classInited.PALADIN = true end
function Tic:_Init_PRIEST()      if self._classInited.PRIEST      then return end; self:Printf("priest init");      self._classInited.PRIEST = true end
function Tic:_Init_ROGUE()       if self._classInited.ROGUE       then return end; self:Printf("rogue init");       self._classInited.ROGUE = true end
function Tic:_Init_SHAMAN()      if self._classInited.SHAMAN      then return end; self:Printf("shaman init");      self._classInited.SHAMAN = true end
function Tic:_Init_WARLOCK()     if self._classInited.WARLOCK     then return end; self:Printf("warlock init");     self._classInited.WARLOCK = true end
function Tic:_Init_WARRIOR()     if self._classInited.WARRIOR     then return end; self:Printf("warrior init");     self._classInited.WARRIOR = true end

-- ---- Dispatcher called by Core.lua after load ----
function Tic:InitForClass(eng)
  local fn = self["_Init_"..eng]
  if fn then fn(self) else self:Printf("No init for class %s", tostring(eng)) end
end

-- ---- Per-frame rotation updaters (stubs) ----
function Tic:_Update_DRUID(elapsed)
  --print("aaaaaaaaaaaaaaaaaaaaaaaaaaa")
  if Tic:IsValidAttackableTarget() then
    local hasFaerieFire, _, _, _, _, _, expireFaerieFire = UnitDebuff("target", "Faerie Fire")
		local hasInsectSwarm, _, _, _, _, _, expireInsectSwarm = UnitDebuff("target", "Insect Swarm")
		local hasMoonfire, _, _, _, _, _, expireMoonfire = UnitDebuff("target", "Moonfire")
		local haveLunarEclipse, _, _, _, _, _, expireLunarEclipse = UnitBuff("player", "Eclipse (Lunar)")
		local haveSolarEclipse, _, _, _, _, _, expireSolarEclipse = UnitBuff("player", "Eclipse (Solar)")
		local starfallReady = Tic:IsSpellReady("Starfall")

    if not hasMoonfire then
      Tic_castSpellByName("Moonfire")
		elseif not hasInsectSwarm then --and ouch_castSpellByName("Insect Swarm") then
			--OuchLog("[DRU] 2.2 Insect Swarm")
			Tic_castSpellByName("Insect Swarm")
			return
    end
  end

  -- Example logic (very naive demo):
  -- if need to refresh Moonfire -> signal that one:
  -- Tic_castSpellByName("Moonfire")
  -- else pick Wrath:
  -- Tic_castSpellByName("Wrath")
  --
  -- NOTE: You just signal; your AHK presses CTRL+<index>.
end

function Tic:_Update_DEATHKNIGHT(elapsed) end
function Tic:_Update_HUNTER(elapsed)      end
function Tic:_Update_MAGE(elapsed)        end
function Tic:_Update_PALADIN(elapsed)     end
function Tic:_Update_PRIEST(elapsed)      end
function Tic:_Update_ROGUE(elapsed)       end
function Tic:_Update_SHAMAN(elapsed)      end
function Tic:_Update_WARLOCK(elapsed)     end
function Tic:_Update_WARRIOR(elapsed)     end

-- ---- Dispatcher run every OnUpdate from Core.lua ----
function Tic:UpdateForClass(elapsed)
  if not self.playerClass then return end
  local fn = self["_Update_"..self.playerClass]
  if fn then fn(self, elapsed) end
end
