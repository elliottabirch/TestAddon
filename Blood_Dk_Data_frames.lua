---@class ns
local ns = select(2, ...)
---@type Constants
local constants = C

if UnitName("player") == "Bbjewelctwo" then
    local aggro = C.CreateCustomFrame("aggroBorder", 0, 4)
    local singleAggro = C.CreateCustomFrame("singleAggroBorder", 0, 5)
    local shouldAMS = C.CreateCustomFrame("singleAggroBorder", 0, 6)

    ---@return number
    function IsMouseoverTanked()
        if constants.IsValidUnit("mouseover", constants.blacklisted_mobs) then
            -- Check if Blood Boil is in range
            local inRange = C_Spell.IsSpellInRange(56222, "mouseover")
            if not inRange then
                return 0
            end
            -- Check threat status - returns 0 (no threat), 1 (have threat but not tanking), 2 (tanking), 3 (secure tanking lead)
            local isTanking = UnitDetailedThreatSituation("player", "mouseover")

            if inRange and not isTanking and C_Spell.GetSpellCooldown(56222).startTime == 0 then
                return 1
            end
        end
        return 0
    end

    ---@return number
    function IsNameplateInRangeWithoutAggro()
        if C_Spell.GetSpellCharges(50842).currentCharges >= 1 then
            for i = 1, 40 do -- Assuming 40 is the max number of nameplates
                local unit = "nameplate" .. i
                if constants.IsValidUnit(unit, constants.blacklisted_mobs) then
                    -- Check if Blood Boil is in range
                    local inRange = C_Spell.IsSpellInRange("Heart Strike", unit)

                    -- Check threat status - returns 0 (no threat), 1 (have threat but not tanking), 2 (tanking), 3 (secure tanking lead)
                    local isTanking = UnitDetailedThreatSituation("player", unit)
                    if inRange and not isTanking then
                        return 1
                    end
                end
            end
        end

        return 0
    end

    ---@return number
    function ShouldCastAMS()
        -- Check if AMS is on cooldown
        local amsCooldownInfo = C_Spell.GetSpellCooldown(48707) -- Anti-Magic Shell spell ID

        -- Return 0 if AMS is on cooldown
        if amsCooldownInfo and amsCooldownInfo.startTime > 0 then
            return 0
        end

        -- Check nearby enemies
        for i = 1, 40 do -- Check all nameplates
            local unit = "nameplate" .. i
            if constants.IsValidUnit(unit, constants.blacklisted_mobs) then
                -- Check if the unit is casting
                local spellName, _, _, _, endTime, _, _, _, spellID = UnitCastingInfo(unit)
                if not spellName then
                    -- Check channeled spells if no cast found
                    spellName, _, _, _, endTime, _, _, spellID = UnitChannelInfo(unit)
                end

                -- Check if the spell is in the AMS list and targeting the player
                if spellName and C.ams_spells[spellName] then
                    return 1
                end
            end
        end

        -- No dangerous casts found targeting player
        return 0
    end

    local function updateFrames()
        aggro.back:SetColorTexture(IsNameplateInRangeWithoutAggro(), 0, 0)


        singleAggro.back:SetColorTexture(IsMouseoverTanked(), 0, 0)
        shouldAMS.back:SetColorTexture(ShouldCastAMS(), 0, 0)
    end


    local ticker = C_Timer.NewTicker(0.01, updateFrames)
end
