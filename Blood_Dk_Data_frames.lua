---@class ns
local ns = select(2, ...)
---@type Constants
local constants = C

if UnitName("player") == "Bbjewelctwo" then
    local aggro = C.CreateCustomFrame("aggroBorder", 0, 5)
    local singleAggro = C.CreateCustomFrame("singleAggroBorder", 0, 6)

    function IsMouseoverTanked()
        if constants.IsValidUnit("mouseover", constants.blacklisted_mobs) then
            -- Check if Blood Boil is in range
            local inRange = C_Spell.IsSpellInRange(56222, "mouseover")
            if not inRange then
                return false
            end
            -- Check threat status - returns 0 (no threat), 1 (have threat but not tanking), 2 (tanking), 3 (secure tanking lead)
            local isTanking = UnitDetailedThreatSituation("player", "mouseover")

            if inRange and not isTanking and C_Spell.GetSpellCooldown(56222).startTime == 0 then
                return true
            end
        end
    end

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
                        return true
                    end
                end
            end
        end

        return false
    end

    local function updateFrames()
        if IsNameplateInRangeWithoutAggro() then
            aggro.back:SetColorTexture(1, 0, 0)
        else
            aggro.back:SetColorTexture(0, 0, 0)
        end

        if IsMouseoverTanked() then
            print("taunt")
            singleAggro.back:SetColorTexture(1, 0, 0)
        else
            singleAggro.back:SetColorTexture(0, 0, 0)
        end
    end


    local ticker = C_Timer.NewTicker(0.01, updateFrames)
end
