function Tic:Test()

end

-- function Tic:IsValidAttackableTarget()
--     local unit = "target"

--     -- Check if the target exists, is alive, and is attackable
--     if not UnitExists(unit) then return false end
--     if UnitIsDeadOrGhost(unit) then return false end
--     if not UnitCanAttack("player", unit) then return false end

--     -- Check if the target is in range (e.g., 40 yards for a harmful spell)
--     if not IsSpellInRange("Attack", unit) == 1 then return false end

--     -- Check if the target is visible (line of sight)
--     if not UnitIsVisible(unit) then return false end

--     return true
-- end



function Tic:IsValidAttackableTarget()
    if not UnitExists("target") then return false end
    if UnitIsDead("target") then return false end
    if UnitIsFriend("player","target") then return false end
    if not UnitCanAttack("player","target") then return false end
    return true
end

function Tic:IsSpellReady(spellName)
    local start, duration, enabled = GetSpellCooldown(spellName)
    if enabled == 0 then
        return false  -- cooldown data not available (e.g., spell not learned)
    end
    return start == 0 or (start + duration - GetTime()) <= 0
end

function Tic:AmInMoonkinForm()
    -- Get the shapeshift form index (0 = none)
    local formIndex = GetShapeshiftForm()
    if formIndex == 0 then
        return false
    end

    -- Get the name of the current form
    local _, formName, active = GetShapeshiftFormInfo(formIndex)
    return active and formName == "Moonkin Form"
end