-- ---@type ns
-- local ns = select(2, ...)
-- ---@type Constants
-- local constants = C

-- local spellHistory = {}

-- local function shouldCombustion()
--     local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(
--         "player")
--     local spellCooldownInfo = C_Spell.GetSpellCooldown("Combustion")
--     if not C_Spell.IsCurrentSpell("Combustion") and (name == "Fireball" and endTimeMS and (endTimeMS - GetTime() * 1000) < 400 and spellCooldownInfo.startTime == 0) then
--         print("fireball combustion remains ", endTimeMS - GetTime() * 1000)
--         return 1
--     end
--     return 0
-- end

-- local function shouldFireball()
--     local auraData = C_UnitAuras.GetAuraDataBySpellName("player", "Combustion")
--     local spellCooldownInfo = C_Spell.GetSpellCooldown("Combustion")
--     local name, _, _, _, endTimeMS = UnitCastingInfo("player")
--     if (not auraData and spellCooldownInfo and spellCooldownInfo.duration == 0 and not name) then
--         return 1
--     end
--     return 0
-- end

-- local function shouldFireBlast()
--     local name, _, _, _, endTimeMS = UnitCastingInfo("player")
--     local hasHotStreak = C_UnitAuras.GetAuraDataBySpellName("player", "Hot Streak!") ~= nil
--     local hasHeatingUp = C_UnitAuras.GetAuraDataBySpellName("player", "Heating Up") ~= nil
--     local fireBlastCharges = C_Spell.GetSpellCharges("Fire Blast")

--     local lastSpell = spellHistory[1]

--     if fireBlastCharges and fireBlastCharges.currentCharges > 0 and not C_Spell.IsCurrentSpell("Fire Blast") and not C_Spell.IsCurrentSpell("scorch") then
--         -- First condition: If we're about to finish casting Fireball and don't have Hot Streak yet
--         if (name == "Fireball" and endTimeMS and (endTimeMS - GetTime() * 1000) < 800 and not hasHotStreak) then
--             print("casting FB because fireball remains ", endTimeMS - GetTime() * 1000)
--             return 1
--         end

--         -- Second condition (updated): Advanced Pyroblast -> Fire Blast logic for Hot Streak management
--         if lastSpell == "Pyroblast" and not hasHotStreak then
--             -- Check if we just consumed a Hot Streak with Pyroblast
--             -- We need to ensure we'll have another Hot Streak ready by the end of the GCD

--             -- Count spells in flight (assuming they will all crit)
--             local spellsInFlight = SPELL_FLIGHT_TRACKER.GetInFlightCount()

--             -- If we have no Heating Up buff and no other spells in flight besides the Pyroblast we just cast
--             -- then we need to Fire Blast to set up the next Hot Streak
--             if not hasHeatingUp and spellsInFlight <= 1 then
--                 print("last spell pyroblast, no other spells in flight, need to Fire Blast")
--                 return 1
--                 -- If we already have Heating Up, then we only need one more crit to get Hot Streak
--                 -- So if there are no spells in flight that can provide that crit, we need to Fire Blast
--             elseif hasHeatingUp and spellsInFlight == 0 then
--                 print("last spell pyroblast, have Heating Up, no spells in flight, need to Fire Blast")
--                 return 1
--             end
--         end
--     end
--     return 0
-- end
-- local function shouldPF()
--     local hasHotStreak = C_UnitAuras.GetAuraDataBySpellName("player", "Hot Streak!") ~= nil
--     local hasHyperThermia = C_UnitAuras.GetAuraDataBySpellName("player", "Hyperthermia") ~= nil
--     local hasHeatingUp = C_UnitAuras.GetAuraDataBySpellName("player", "Heating Up") ~= nil
--     local hasHeatingUpCount = hasHeatingUp and 1 or 0
--     local fireBlastCharges = C_Spell.GetSpellCharges("Fire Blast")
--     local PFCharges = C_Spell.GetSpellCharges("Phoenix Flames")

--     -- Check for Pyroblast in flight using SPELL_FLIGHT_TRACKER

--     -- Check if GCD is available
--     local GCD = C_Spell.GetSpellCooldown(61304) -- Using Fireball to check GCD
--     local isGCDDown = (GCD.startTime == 0 or (GetTime() - GCD.startTime) >= GCD.duration)


--     if isGCDDown and not hasHyperThermia and fireBlastCharges and fireBlastCharges.currentCharges < 1
--         and PFCharges and PFCharges.currentCharges > 0
--         and not C_Spell.IsCurrentSpell("Phoenix Flames")
--         and not C_Spell.IsCurrentSpell("Scorch") then
--         if not hasHotStreak and SPELL_FLIGHT_TRACKER.GetInFlightCount() + hasHeatingUpCount < 2 then
--             return 1
--         end
--     end
--     return 0
-- end

-- local function shouldScorch()
--     local hasHotStreak = C_UnitAuras.GetAuraDataBySpellName("player", "Hot Streak!") ~= nil
--     local hasHyperThermia = C_UnitAuras.GetAuraDataBySpellName("player", "Hyperthermia") ~= nil
--     local hasHeatingUp = C_UnitAuras.GetAuraDataBySpellName("player", "Heating Up") ~= nil
--     local hasHeatingUpCount = hasHeatingUp and 1 or 0
--     local PFCharges = C_Spell.GetSpellCharges("Phoenix Flames")
--     local fireBlastCharges = C_Spell.GetSpellCharges("Fire Blast")

--     -- Check for Pyroblast in flight using SPELL_FLIGHT_TRACKER

--     -- Check if GCD is available
--     local GCD = C_Spell.GetSpellCooldown(61304) -- Using Fireball to check GCD
--     local isGCDDown = (GCD.startTime == 0 or (GetTime() - GCD.startTime) >= GCD.duration)

--     if isGCDDown and not hasHyperThermia
--         and fireBlastCharges and fireBlastCharges.currentCharges < 1
--         and PFCharges and PFCharges.currentCharges < 1
--         and not C_Spell.IsCurrentSpell("Scorch") then
--         if not hasHotStreak and (SPELL_FLIGHT_TRACKER.GetInFlightCount() + hasHeatingUpCount) < 2 then
--             return 1
--         end
--     end
--     return 0
-- end
-- local function shouldPyroblast()
--     local hasHotStreak = C_UnitAuras.GetAuraDataBySpellName("player", "Hot Streak!") ~= nil
--     local hasHyperThermia = C_UnitAuras.GetAuraDataBySpellName("player", "Hyperthermia") ~= nil
--     local name, text, texture, startTimeMS, endTimeMS, isTradeSkill, castID, notInterruptible, spellId = UnitCastingInfo(
--         "player")
--     if name ~= "Fireball" and hasHotStreak or hasHyperThermia and not C_Spell.IsCurrentSpell("Pyroblast") then
--         return 1
--     end
--     return 0
-- end



-- local function OnCombatLogEvent(self, event, unit, target, castGUID, spellID)
--     local epochTime = time()

--     -- Format the time to hh:mm:ss
--     local formattedTime = date("%H:%M:%S", epochTime)

--     -- Get milliseconds using debugprofilestop
--     local milliseconds = debugprofilestop() % 1000

--     -- Combine to get hh:mm:ss:ms
--     local timeWithMilliseconds = string.format("%s:%03d", formattedTime, milliseconds)
--     if event == "UNIT_SPELLCAST_SENT" then
--         print(C_Spell.GetSpellInfo(spellID).name, " attempted to be cast ", timeWithMilliseconds)
--     end


--     if event == "COMBAT_LOG_EVENT_UNFILTERED" then
--         local timestamp, subEvent, _, sourceGUID, _, _, _, destGUID, _, _, _, spellId, spellName =
--             CombatLogGetCurrentEventInfo()

--         -- Only track player casts
--         if sourceGUID == UnitGUID("player") then
--             if subEvent == "SPELL_CAST_SUCCESS" then
--                 table.insert(spellHistory, 1, spellName) -- Insert at the start
--                 if #spellHistory > 10 then
--                     table.remove(spellHistory, 11)       -- Limit history to 10 entries
--                 end
--                 print(spellHistory[1], " ", timeWithMilliseconds)
--             end
--         end
--     end
-- end

-- if UnitName("player") == "Elfyoursellf" then
--     local combustion = C.CreateCustomFrame("combustionBorder", 5, 0)
--     local fireball = C.CreateCustomFrame("fireballBorder", 5, 1)
--     local fireBlast = C.CreateCustomFrame("fireBlastBorder", 5, 2)
--     local PF = C.CreateCustomFrame("PFBorder", 5, 3)
--     local pyroblast = C.CreateCustomFrame("pyroblastBorder", 5, 4)
--     local scorch = C.CreateCustomFrame("scorchBorder", 5, 5)


--     local eventFrame = CreateFrame("Frame")
--     eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
--     eventFrame:RegisterEvent("UNIT_SPELLCAST_SENT")

--     eventFrame:SetScript("OnEvent", OnCombatLogEvent)
--     local prevCombustionValue = shouldCombustion()
--     local prevFireballValue = shouldFireball()
--     local prevFireBlastValue = shouldFireBlast()
--     local prevPFValue = shouldPF()
--     local prevPyroblastValue = shouldPyroblast()
--     local prevScorchValue = shouldScorch()

--     combustion.back:SetColorTexture(prevCombustionValue, 0, 0)
--     fireball.back:SetColorTexture(prevFireballValue, 0, 0)
--     fireBlast.back:SetColorTexture(prevFireBlastValue, 0, 0)
--     PF.back:SetColorTexture(prevPFValue, 0, 0)
--     pyroblast.back:SetColorTexture(prevPyroblastValue, 0, 0)
--     scorch.back:SetColorTexture(prevScorchValue, 0, 0)
--     local function updateFrames()
--         -- Check and update Combustion frame
--         local currentCombustionValue = shouldCombustion()
--         if prevCombustionValue ~= currentCombustionValue then
--             prevCombustionValue = currentCombustionValue
--             combustion.back:SetColorTexture(currentCombustionValue, 0, 0)
--         end

--         -- Check and update Fireball frame
--         local currentFireballValue = shouldFireball()
--         if prevFireballValue ~= currentFireballValue then
--             prevFireballValue = currentFireballValue
--             fireball.back:SetColorTexture(currentFireballValue, 0, 0)
--         end

--         -- Check and update Fire Blast frame
--         local currentFireBlastValue = shouldFireBlast()
--         if prevFireBlastValue ~= currentFireBlastValue then
--             prevFireBlastValue = currentFireBlastValue
--             fireBlast.back:SetColorTexture(currentFireBlastValue, 0, 0)
--         end

--         -- Check and update PF frame
--         local currentPFValue = shouldPF()
--         if prevPFValue ~= currentPFValue then
--             prevPFValue = currentPFValue
--             PF.back:SetColorTexture(currentPFValue, 0, 0)
--         end

--         -- Check and update Pyroblast frame
--         local currentPyroblastValue = shouldPyroblast()
--         if prevPyroblastValue ~= currentPyroblastValue then
--             prevPyroblastValue = currentPyroblastValue
--             pyroblast.back:SetColorTexture(currentPyroblastValue, 0, 0)
--         end

--         -- Check and update Scorch frame
--         local currentScorchValue = shouldScorch()
--         if prevScorchValue ~= currentScorchValue then
--             prevScorchValue = currentScorchValue
--             scorch.back:SetColorTexture(currentScorchValue, 0, 0)
--         end
--     end


--     local ticker = C_Timer.NewTicker(0.001, updateFrames)
-- end
