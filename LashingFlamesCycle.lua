-- ---@class ns
-- local ns = select(2, ...)

-- function LashingFlamesCycle()
--     local count = 0

--     for i = 1, C_NamePlate.GetNumNamePlates() do
--         local nameplate = C_NamePlate.GetNamePlateForUnit("nameplate" .. i)
--         if nameplate then
--             local unit = nameplate.UnitFrame.unit
--             local hasLashingFlames = false
--             local unitDebuffs = UnitAuraSlots(unit, "HARMFUL")

--             for j = 1, unitDebuffs do
--                 local aura = C_UnitAuras.GetAuraDataBySlot(unit, j)
--                 if aura and aura.name == "Lashing Flames" then
--                     hasLashingFlames = true
--                     break
--                 end
--             end

--             if UnitAffectingCombat(unit) and not hasLashingFlames and C_Spell.IsSpellInRange("Lava Lash", unit) == 1 then
--                 count = count + 1
--             end
--         end
--     end

--     return count > 1
-- end
