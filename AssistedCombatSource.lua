--------------------------------------------------------------------------------
-- AssistedCombatSource.lua
-- Gets the currently suggested spell from WoW's Assisted Combat (1-button rotation)
-- and resolves its keybind via KeybindLookup
--------------------------------------------------------------------------------

local AssistedCombatSource = LibStub:NewLibrary("TestAddon-AssistedCombatSource", 1)
if not AssistedCombatSource then return end

-- Dependency: KeybindLookup must be loaded first
local KeybindLookup = nil

-- Cache for current state
local currentSpellID = nil
local currentSpellName = nil
local currentKeybind = nil

--------------------------------------------------------------------------------
-- Core API: C_AssistedCombat.GetNextCastSpell
--------------------------------------------------------------------------------

--- Get the spell ID Blizzard recommends you cast next
-- @param checkForVisibleButton boolean: true = only visible action bar spells,
--                                       false = include abilities behind macro conditionals
-- @return number|nil Spell ID, or nil if no recommendation
local function GetNextCastSpell(checkForVisibleButton)
    -- Default to true (only visible buttons) - less flicker
    if checkForVisibleButton == nil then
        checkForVisibleButton = true
    end

    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return nil
    end

    local success, result = pcall(C_AssistedCombat.GetNextCastSpell, checkForVisibleButton)
    if success and result and type(result) == "number" and result > 0 then
        return result
    end
    return nil
end

--- Get spell info for a spell ID
-- @param spellID number
-- @return table|nil { name, iconID } or nil
local function GetSpellInfo(spellID)
    if not spellID or spellID == 0 then return nil end

    if C_Spell and C_Spell.GetSpellInfo then
        return C_Spell.GetSpellInfo(spellID)
    end

    -- Legacy fallback
    local name, _, icon = GetSpellInfo(spellID)
    if name then
        return { name = name, iconID = icon }
    end
    return nil
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Initialize with KeybindLookup reference
-- Call this after KeybindLookup is loaded
function AssistedCombatSource.Init()
    KeybindLookup = _G.KeybindLookup
    if not KeybindLookup then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000AssistedCombatSource|r: KeybindLookup not found!")
        return false
    end
    return true
end

--- Update current spell and keybind
-- Call this on a timer or in response to events
-- @return boolean True if spell changed
function AssistedCombatSource.Update()
    local newSpellID = GetNextCastSpell(true)

    -- No spell recommended
    if not newSpellID then
        local changed = currentSpellID ~= nil
        currentSpellID = nil
        currentSpellName = nil
        currentKeybind = nil
        return changed
    end

    -- Same spell, no update needed
    if newSpellID == currentSpellID then
        return false
    end

    -- Spell changed - resolve keybind
    currentSpellID = newSpellID

    local spellInfo = GetSpellInfo(newSpellID)
    currentSpellName = spellInfo and spellInfo.name or "Unknown"

    -- Get keybind via KeybindLookup
    if KeybindLookup then
        currentKeybind = KeybindLookup.GetKeybindForSpell(newSpellID)
    else
        currentKeybind = nil
    end

    return true
end

--- Get the current keybind string
-- @return string|nil Keybind like "SHIFT-1" or "F", or nil if none
function AssistedCombatSource.GetCurrentKeybind()
    return currentKeybind
end

--- Get the current spell ID
-- @return number|nil
function AssistedCombatSource.GetCurrentSpellID()
    return currentSpellID
end

--- Get the current spell name
-- @return string|nil
function AssistedCombatSource.GetCurrentSpellName()
    return currentSpellName
end

--- Check if Assisted Combat API is available
-- @return boolean, string|nil (isAvailable, failureReason)
function AssistedCombatSource.IsAvailable()
    if not C_AssistedCombat then
        return false, "C_AssistedCombat API not available"
    end
    if not C_AssistedCombat.GetNextCastSpell then
        return false, "GetNextCastSpell not available"
    end
    if not C_AssistedCombat.IsAvailable then
        return true, nil -- API exists, assume available
    end

    local success, isAvailable, reason = pcall(C_AssistedCombat.IsAvailable)
    if success then
        return isAvailable, reason
    end
    return false, "API call failed"
end

--- Print diagnostic info
function AssistedCombatSource.PrintStatus()
    local available, reason = AssistedCombatSource.IsAvailable()
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00AssistedCombatSource|r Status:")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  API Available: %s%s",
        available and "|cff00ff00YES|r" or "|cffff0000NO|r",
        reason and (" (" .. reason .. ")") or ""))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Current Spell: %s (ID: %s)",
        currentSpellName or "None",
        tostring(currentSpellID or "nil")))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Current Keybind: %s",
        currentKeybind or "None"))
end

return AssistedCombatSource
