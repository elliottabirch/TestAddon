---@class KeybindNormalizer
---@field Normalize fun(keybind: string): string

local MAJOR, MINOR = "TestAddon-KeybindNormalizer", 1
local KeybindNormalizer = LibStub:NewLibrary(MAJOR, MINOR)
if not KeybindNormalizer then return end

--------------------------------------------------------------------------------
-- Keybind String Normalization
--
-- Converts various keybind formats into a canonical form:
-- Input formats: "ACS1", "acs1", "A-C-S-1", "alt-ctrl-shift-1"
-- Output format: "ALT-CTRL-SHIFT-1"
--
-- The canonical format is:
-- - All uppercase
-- - Modifiers in order: ALT, CTRL, SHIFT
-- - Hyphen-separated
--------------------------------------------------------------------------------

--- Normalize a keybind string to canonical format
---@param keybind string Raw keybind from any source
---@return string normalized Canonical format keybind
function KeybindNormalizer.Normalize(keybind)
    if not keybind or keybind == "" then
        return ""
    end

    keybind = keybind:upper()

    local hasAlt = false
    local hasCtrl = false
    local hasShift = false
    local baseKey = keybind

    -- Handle compact format (e.g., "ACS1" where A=Alt, C=Ctrl, S=Shift)
    -- Only parse as compact if it starts with modifier letters and has more content
    if #keybind > 1 then
        local pos = 1

        -- Check for 'A' (Alt) at current position
        if baseKey:sub(pos, pos) == "A" and #baseKey > pos then
            hasAlt = true
            pos = pos + 1
            baseKey = baseKey:sub(pos)
        end

        -- Check for 'C' (Ctrl) at current position
        if baseKey:sub(1, 1) == "C" and #baseKey > 1 then
            hasCtrl = true
            baseKey = baseKey:sub(2)
        end

        -- Check for 'S' (Shift) at current position
        if baseKey:sub(1, 1) == "S" and #baseKey > 1 then
            hasShift = true
            baseKey = baseKey:sub(2)
        end
    end

    -- Handle hyphenated format (e.g., "ALT-CTRL-1")
    -- This needs to happen on the remaining baseKey
    if baseKey:match("ALT%-") then
        hasAlt = true
        baseKey = baseKey:gsub("ALT%-", "")
    end
    if baseKey:match("CTRL%-") then
        hasCtrl = true
        baseKey = baseKey:gsub("CTRL%-", "")
    end
    if baseKey:match("SHIFT%-") then
        hasShift = true
        baseKey = baseKey:gsub("SHIFT%-", "")
    end

    -- Build the normalized result
    local result = ""
    if hasAlt then
        result = result .. "ALT-"
    end
    if hasCtrl then
        result = result .. "CTRL-"
    end
    if hasShift then
        result = result .. "SHIFT-"
    end

    return result .. baseKey
end

return KeybindNormalizer
