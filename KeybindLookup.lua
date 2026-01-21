-- KeybindLookup.lua
-- Finds keybinds for spells by scanning action bars
-- Features:
--   - Time-based cache refresh (once per second)
--   - Additive caching (transformed spells don't overwrite base spells)
--   - Simple macro support (uses displayed spell ID)
--   - Diagnostic logging for missing spells

local KeybindLookup = {}

-- Configuration
local CACHE_REFRESH_INTERVAL = 1.0 -- Refresh cache every 1 second
local MAX_ACTION_SLOTS = 180       -- WoW has up to 180 action slots
local NUM_BAR_BUTTONS = 12         -- Each bar has 12 buttons

-- Cache state
local spellKeybindCache = {} -- spellID -> keybind string
local slotKeybindCache = {}  -- slot -> keybind string
local lastCacheRefresh = 0   -- GetTime() of last refresh

-- Diagnostic logging toggle
local diagnosticLoggingEnabled = true

-- Binding patterns for each action bar
-- Maps bar type to the binding prefix used by WoW
local BINDING_PATTERNS = {
    { slots = { 1, 12 },    pattern = "ACTIONBUTTON" },          -- Main bar
    { slots = { 61, 72 },   pattern = "MULTIACTIONBAR1BUTTON" }, -- Bottom left
    { slots = { 49, 60 },   pattern = "MULTIACTIONBAR2BUTTON" }, -- Bottom right
    { slots = { 25, 36 },   pattern = "MULTIACTIONBAR3BUTTON" }, -- Right bar 1
    { slots = { 37, 48 },   pattern = "MULTIACTIONBAR4BUTTON" }, -- Right bar 2
    { slots = { 145, 156 }, pattern = "MULTIACTIONBAR5BUTTON" }, -- Bar 5
    { slots = { 157, 168 }, pattern = "MULTIACTIONBAR6BUTTON" }, -- Bar 6
    { slots = { 169, 180 }, pattern = "MULTIACTIONBAR7BUTTON" }, -- Bar 7
}

-- Stance/form bar slot ranges (pages 7-10 in WoW's system)
-- These replace the main bar when in a stance/form
local STANCE_BAR_SLOTS = {
    [1] = { 73, 84 },   -- Stance 1 (e.g., Druid Cat Form)
    [2] = { 85, 96 },   -- Stance 2 (e.g., Druid Bear Form)
    [3] = { 97, 108 },  -- Stance 3
    [4] = { 109, 120 }, -- Stance 4
}

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function Log(message)
    if diagnosticLoggingEnabled then
        print("|cff00ffffKeybindLookup:|r " .. message)
    end
end

local function LogDiagnostic(spellID, spellName, reason, extraData)
    if not diagnosticLoggingEnabled then return end

    local msg = string.format("Spell not found: %s (ID: %d) - %s",
        spellName or "unknown", spellID or 0, reason or "unknown reason")

    if extraData then
        msg = msg .. "\n  Extra data: " .. extraData
    end

    print("|cffff8800KeybindLookup DIAGNOSTIC:|r " .. msg)
end

--------------------------------------------------------------------------------
-- Slot to Keybind Mapping
--------------------------------------------------------------------------------

-- Get the binding pattern for a given slot number
local function GetBindingPatternForSlot(slot)
    -- Check stance bar slots first (when in a form/stance)
    local bonusBarOffset = GetBonusBarOffset and GetBonusBarOffset() or 0
    if bonusBarOffset > 0 and STANCE_BAR_SLOTS[bonusBarOffset] then
        local stanceRange = STANCE_BAR_SLOTS[bonusBarOffset]
        if slot >= stanceRange[1] and slot <= stanceRange[2] then
            local buttonIndex = slot - stanceRange[1] + 1
            return "ACTIONBUTTON" .. buttonIndex
        end
    end

    -- Check standard bar patterns
    for _, barInfo in ipairs(BINDING_PATTERNS) do
        if slot >= barInfo.slots[1] and slot <= barInfo.slots[2] then
            local buttonIndex = slot - barInfo.slots[1] + 1
            return barInfo.pattern .. buttonIndex
        end
    end

    -- Fallback for main bar slots 1-12 (when no stance active)
    if slot >= 1 and slot <= 12 then
        return "ACTIONBUTTON" .. slot
    end

    return nil
end

-- Get the actual keybind for a slot
local function GetKeybindForSlot(slot)
    local bindingPattern = GetBindingPatternForSlot(slot)
    if not bindingPattern then
        return nil
    end

    local key = GetBindingKey(bindingPattern)
    return key
end

--------------------------------------------------------------------------------
-- Keybind Formatting
--------------------------------------------------------------------------------

-- Abbreviate keybind for display (e.g., "SHIFT-1" -> "S1")
local function AbbreviateKeybind(key)
    if not key or key == "" then return "" end

    local result = key

    -- Abbreviate modifiers
    result = result:gsub("SHIFT%-", "S")
    result = result:gsub("CTRL%-", "C")
    result = result:gsub("ALT%-", "A")

    -- Abbreviate common keys
    result = result:gsub("BUTTON(%d+)", "M%1") -- Mouse buttons
    result = result:gsub("MOUSEWHEELUP", "MwU")
    result = result:gsub("MOUSEWHEELDOWN", "MwD")
    result = result:gsub("NUMPAD", "N")
    result = result:gsub("PAGEUP", "PgU")
    result = result:gsub("PAGEDOWN", "PgD")
    result = result:gsub("SPACE", "Spc")

    return result
end

--------------------------------------------------------------------------------
-- Cache Management
--------------------------------------------------------------------------------

-- Check if cache needs refresh
local function IsCacheStale()
    local now = GetTime()
    return (now - lastCacheRefresh) >= CACHE_REFRESH_INTERVAL
end

-- Rebuild the slot -> keybind cache
local function RefreshSlotCache()
    -- Don't wipe - we rebuild it fresh each time
    wipe(slotKeybindCache)

    for slot = 1, MAX_ACTION_SLOTS do
        local keybind = GetKeybindForSlot(slot)
        if keybind and keybind ~= "" then
            slotKeybindCache[slot] = keybind
        end
    end
end

-- Scan all action bars and build spell -> keybind mappings
-- ADDITIVE: Does not remove existing entries
local function RefreshSpellCache()
    local now = GetTime()

    -- Refresh slot cache first
    RefreshSlotCache()

    for slot = 1, MAX_ACTION_SLOTS do
        if HasAction(slot) then
            local actionType, actionID, subType, macroSpellID = GetActionInfo(slot)
            local keybind = slotKeybindCache[slot]

            if keybind and keybind ~= "" then
                local abbreviatedKeybind = AbbreviateKeybind(keybind)

                if actionType == "spell" and actionID then
                    -- Direct spell on bar
                    -- Only add if not already cached (additive)
                    if not spellKeybindCache[actionID] then
                        spellKeybindCache[actionID] = abbreviatedKeybind
                    end
                elseif actionType == "macro" then
                    -- Macro - use the displayed spell ID
                    -- macroSpellID is the spell the macro icon is showing
                    -- This handles #showtooltip and dynamic macro icons
                    if macroSpellID and macroSpellID > 0 then
                        if not spellKeybindCache[macroSpellID] then
                            spellKeybindCache[macroSpellID] = abbreviatedKeybind
                        end
                    end

                    -- Also check subType which sometimes contains spell info
                    if subType == "spell" and actionID and type(actionID) == "number" then
                        if not spellKeybindCache[actionID] then
                            spellKeybindCache[actionID] = abbreviatedKeybind
                        end
                    end
                end
            end
        end
    end

    lastCacheRefresh = now
end

-- Ensure cache is fresh
local function EnsureCacheValid()
    if IsCacheStale() then
        RefreshSpellCache()
    end
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

-- Get the keybind for a spell ID
-- Returns abbreviated keybind string or empty string if not found
function KeybindLookup.GetSpellKeybind(spellID)
    if not spellID or spellID == 0 then
        return ""
    end

    EnsureCacheValid()

    local cached = spellKeybindCache[spellID]
    if cached then
        return cached
    end

    -- Not found - log diagnostic info
    local spellName = nil
    local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
    if spellInfo then
        spellName = spellInfo.name
    end

    -- Check if this spell has a base/override relationship
    local diagnosticExtra = ""

    -- Check if this is an override spell (transformed version)
    if FindBaseSpellByID then
        local baseID = FindBaseSpellByID(spellID)
        if baseID and baseID ~= spellID then
            diagnosticExtra = diagnosticExtra .. string.format(
                "This is an OVERRIDE spell. Base spell ID: %d", baseID)

            -- Check if base spell has a keybind
            local baseKeybind = spellKeybindCache[baseID]
            if baseKeybind then
                diagnosticExtra = diagnosticExtra .. string.format(
                    " (Base spell HAS keybind: %s - consider using base spell)", baseKeybind)
            end
        end
    end

    -- Check if this spell has an override version
    if C_Spell and C_Spell.GetOverrideSpell then
        local overrideID = C_Spell.GetOverrideSpell(spellID)
        if overrideID and overrideID ~= spellID and overrideID ~= 0 then
            diagnosticExtra = diagnosticExtra .. string.format(
                " | This spell has an OVERRIDE. Override spell ID: %d", overrideID)

            -- Check if override spell has a keybind
            local overrideKeybind = spellKeybindCache[overrideID]
            if overrideKeybind then
                diagnosticExtra = diagnosticExtra .. string.format(
                    " (Override HAS keybind: %s)", overrideKeybind)
            end
        end
    end

    -- Scan bars to see if this spell exists but we missed it
    local foundInSlot = nil
    local foundActionType = nil
    for slot = 1, MAX_ACTION_SLOTS do
        if HasAction(slot) then
            local actionType, actionID, subType, macroSpellID = GetActionInfo(slot)
            if actionType == "spell" and actionID == spellID then
                foundInSlot = slot
                foundActionType = "direct spell"
                break
            elseif actionType == "macro" and macroSpellID == spellID then
                foundInSlot = slot
                foundActionType = "macro (displayed)"
                break
            end
        end
    end

    if foundInSlot then
        local slotKeybind = slotKeybindCache[foundInSlot]
        diagnosticExtra = diagnosticExtra .. string.format(
            " | Found in slot %d as %s, but slot keybind is: %s",
            foundInSlot, foundActionType, tostring(slotKeybind or "NONE"))
    end

    if diagnosticExtra ~= "" then
        LogDiagnostic(spellID, spellName, "Not in cache", diagnosticExtra)
    else
        LogDiagnostic(spellID, spellName, "Not found on any action bar", nil)
    end

    return ""
end

-- Force a cache refresh (call this after keybind changes, spec changes, etc.)
function KeybindLookup.InvalidateCache()
    lastCacheRefresh = 0
end

-- Force immediate cache refresh
function KeybindLookup.ForceRefresh()
    lastCacheRefresh = 0
    EnsureCacheValid()
end

-- Clear all cached data (for spec changes where spells completely change)
function KeybindLookup.ClearCache()
    wipe(spellKeybindCache)
    wipe(slotKeybindCache)
    lastCacheRefresh = 0
end

-- Enable/disable diagnostic logging
function KeybindLookup.SetDiagnosticLogging(enabled)
    diagnosticLoggingEnabled = enabled
end

-- Debug: dump cache contents
function KeybindLookup.DumpCache()
    Log("=== Spell Keybind Cache ===")
    local count = 0
    for spellID, keybind in pairs(spellKeybindCache) do
        local spellName = "unknown"
        local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellID)
        if spellInfo and spellInfo.name then
            spellName = spellInfo.name
        end
        Log(string.format("  %d (%s) = %s", spellID, spellName, keybind))
        count = count + 1
    end
    Log(string.format("Total: %d spells cached", count))
end

-- Debug: dump slot cache contents
function KeybindLookup.DumpSlots()
    EnsureCacheValid()
    Log("=== Slot Keybind Cache ===")
    local count = 0
    for slot = 1, MAX_ACTION_SLOTS do
        local keybind = slotKeybindCache[slot]
        if keybind then
            local actionType, actionID = GetActionInfo(slot)
            local actionDesc = "empty"
            if actionType == "spell" and actionID then
                local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(actionID)
                actionDesc = spellInfo and spellInfo.name or ("spell:" .. actionID)
            elseif actionType == "macro" then
                actionDesc = "macro"
            elseif actionType == "item" then
                actionDesc = "item"
            elseif actionType then
                actionDesc = actionType
            end
            Log(string.format("  Slot %d = %s (%s)", slot, keybind, actionDesc))
            count = count + 1
        end
    end
    Log(string.format("Total: %d slots with keybinds", count))
end

-- Debug: lookup a spell by name (for testing)
function KeybindLookup.FindSpell(spellName)
    if not spellName or spellName == "" then
        Log("Usage: KeybindLookup.FindSpell('spell name')")
        return
    end

    local spellInfo = C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellInfo(spellName)
    if not spellInfo then
        Log("Spell not found: " .. spellName)
        return
    end

    Log(string.format("Looking up: %s (ID: %d)", spellInfo.name, spellInfo.spellID))
    local keybind = KeybindLookup.GetSpellKeybind(spellInfo.spellID)
    if keybind and keybind ~= "" then
        Log(string.format("  Keybind: %s", keybind))
    else
        Log("  No keybind found")
    end
end

-- Make available globally for other addons
_G.KeybindLookup = KeybindLookup

return KeybindLookup
