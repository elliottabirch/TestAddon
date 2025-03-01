---@class ns
local ns = select(2, ...)

-- Global spell flight tracker
SPELL_FLIGHT_TRACKER = SPELL_FLIGHT_TRACKER or {}

-- Initialize the global constants if they don't exist
SPELL_FLIGHT_TRACKER.InFlightSpells = SPELL_FLIGHT_TRACKER.InFlightSpells or {}
SPELL_FLIGHT_TRACKER.SpellsWithTravelTime = {
    ["Fireball"] = true,
    ["Scorch"] = true,
    ["Phoenix Flames"] = true,
    ["Pyroblast"] = true
}

-- Configuration
local CLEANUP_TIMEOUT = 0.75 -- Time in seconds after which to remove a spell if no landing event is detected

-- Helper function to add a spell to the in-flight array
local function AddSpellToInFlight(spellID, spellName, targetGUID, castTime)
    local entry = {
        spellID = spellID,
        spellName = spellName,
        targetGUID = targetGUID,
        castTime = castTime,
        expireTime = GetTime() + CLEANUP_TIMEOUT,
        timer = nil
    }

    -- Create a timer to auto-remove the spell after the timeout
    entry.timer = C_Timer.NewTimer(CLEANUP_TIMEOUT, function()
        for i, spell in ipairs(SPELL_FLIGHT_TRACKER.InFlightSpells) do
            if spell == entry then
                table.remove(SPELL_FLIGHT_TRACKER.InFlightSpells, i)
                break
            end
        end
    end)

    table.insert(SPELL_FLIGHT_TRACKER.InFlightSpells, entry)

    -- We've removed debug output for cleaner implementation
end

-- Helper function to remove a spell from the in-flight array
local function RemoveSpellFromInFlight(spellID, targetGUID)
    for i, spell in ipairs(SPELL_FLIGHT_TRACKER.InFlightSpells) do
        if spell.spellID == spellID and spell.targetGUID == targetGUID then
            -- Cancel the timer to prevent it from firing
            if spell.timer then
                spell.timer:Cancel()
            end
            C_Timer.NewTimer(.1, function() table.remove(SPELL_FLIGHT_TRACKER.InFlightSpells, i) end)


            -- Removed debug output for cleaner implementation
            return
        end
    end
end

-- Simple function to get the current in-flight spells (mainly for debugging if needed)
function SPELL_FLIGHT_TRACKER.GetInFlightSpells()
    return SPELL_FLIGHT_TRACKER.InFlightSpells
end

-- Function to get the count of in-flight spells
function SPELL_FLIGHT_TRACKER.GetInFlightCount()
    return #SPELL_FLIGHT_TRACKER.InFlightSpells
end

-- Function to get the count of in-flight spells by name
function SPELL_FLIGHT_TRACKER.GetInFlightCountByName(spellName)
    local count = 0
    for _, spell in ipairs(SPELL_FLIGHT_TRACKER.InFlightSpells) do
        if spell.spellName == spellName then
            count = count + 1
        end
    end
    return count
end

-- Function to get in-flight spells targeted at a specific GUID
function SPELL_FLIGHT_TRACKER.GetInFlightSpellsForTarget(targetGUID)
    local spells = {}
    for _, spell in ipairs(SPELL_FLIGHT_TRACKER.InFlightSpells) do
        if spell.targetGUID == targetGUID then
            table.insert(spells, spell)
        end
    end
    return spells
end

-- Create the event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- Event handler
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName =
            CombatLogGetCurrentEventInfo()

        -- Only process events from the player
        if sourceGUID ~= UnitGUID("player") then
            return
        end

        -- Track spell casts with travel time
        if subEvent == "SPELL_CAST_SUCCESS" and SPELL_FLIGHT_TRACKER.SpellsWithTravelTime[spellName] then
            AddSpellToInFlight(spellID, spellName, destGUID, GetTime())
        end

        -- Remove spells when they hit or are interrupted
        if (subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_MISSED") then
            RemoveSpellFromInFlight(spellID, destGUID)
        end
    end
end)

-- No need to return anything since we're using a global variable
-- Other scripts can access SPELL_FLIGHT_TRACKER directly
