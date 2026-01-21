---@class KeybindColorConverter
---@field ConvertToRGB fun(keybind: string): number, number, number
---@field GetModifierValue fun(keybind: string): number
---@field GetKeyValue fun(keybind: string): number

local MAJOR, MINOR = "TestAddon-KeybindColorConverter", 1
local KeybindColorConverter = LibStub:NewLibrary(MAJOR, MINOR)
if not KeybindColorConverter then return end

--------------------------------------------------------------------------------
-- Constants
--------------------------------------------------------------------------------

-- Modifier combinations mapped to red channel values (0-70 range, divided by 255)
local MODIFIER_VALUES = {
    ["ALT-CTRL-SHIFT-"] = 70,
    ["ALT-CTRL-"] = 60,
    ["ALT-SHIFT-"] = 50,
    ["ALT-"] = 40,
    ["CTRL-SHIFT-"] = 30,
    ["CTRL-"] = 20,
    ["SHIFT-"] = 10,
    [""] = 0,
}

-- Special keys that don't use ASCII byte values
local SPECIAL_KEY_VALUES = {
    -- Function keys
    F1 = 149,
    F2 = 150,
    F3 = 151,
    F4 = 152,
    F5 = 153,
    F6 = 154,
    F7 = 155,
    F8 = 156,
    F9 = 157,
    F10 = 158,
    F11 = 159,
    F12 = 160,
    -- Numpad
    N0 = 106,
    N1 = 97,
    N2 = 98,
    N3 = 99,
    N4 = 100,
    N5 = 101,
    N6 = 102,
    N7 = 103,
    N8 = 104,
    N9 = 105,
    -- Arrow keys
    LEFT = 37,
    RIGHT = 39,
    UP = 38,
    DN = 40,
    -- Other
    DELETE = 46,
    MWU = 161, -- Mouse wheel up
    MWD = 162, -- Mouse wheel down
}

--------------------------------------------------------------------------------
-- Internal helpers
--------------------------------------------------------------------------------

--- Extract the modifier prefix from a normalized keybind string
---@param keybind string Normalized keybind (e.g., "ALT-CTRL-Q")
---@return string modifierPrefix The modifier portion (e.g., "ALT-CTRL-")
---@return string baseKey The key without modifiers (e.g., "Q")
local function SplitModifiersAndKey(keybind)
    local modifiers = ""
    local remaining = keybind

    -- Check for each modifier in order: ALT, CTRL, SHIFT
    if remaining:match("^ALT%-") then
        modifiers = modifiers .. "ALT-"
        remaining = remaining:gsub("^ALT%-", "")
    end
    if remaining:match("^CTRL%-") then
        modifiers = modifiers .. "CTRL-"
        remaining = remaining:gsub("^CTRL%-", "")
    end
    if remaining:match("^SHIFT%-") then
        modifiers = modifiers .. "SHIFT-"
        remaining = remaining:gsub("^SHIFT%-", "")
    end

    return modifiers, remaining
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Get the modifier value component (used for red and blue channels)
---@param keybind string Normalized keybind string
---@return number value 0-70 range value for the modifier combination
function KeybindColorConverter.GetModifierValue(keybind)
    local modifiers, _ = SplitModifiersAndKey(keybind)
    return MODIFIER_VALUES[modifiers] or 0
end

--- Get the key value component (used for green channel)
---@param keybind string Normalized keybind string
---@return number value 0-162 range value for the base key
function KeybindColorConverter.GetKeyValue(keybind)
    local _, baseKey = SplitModifiersAndKey(keybind)

    -- Check special keys first
    if SPECIAL_KEY_VALUES[baseKey] then
        return SPECIAL_KEY_VALUES[baseKey]
    end

    -- Single character: use ASCII byte value
    if #baseKey == 1 then
        return string.byte(baseKey)
    end

    return 0
end

--- Convert a normalized keybind string to RGB color values
---@param keybind string Normalized keybind string (e.g., "ALT-CTRL-Q")
---@return number red 0-1 range
---@return number green 0-1 range
---@return number blue 0-1 range
function KeybindColorConverter.ConvertToRGB(keybind)
    if not keybind or keybind == "" then
        return 0, 0, 0
    end

    local modifierValue = KeybindColorConverter.GetModifierValue(keybind)
    local keyValue = KeybindColorConverter.GetKeyValue(keybind)

    local red = modifierValue / 255
    local green = keyValue / 255
    local blue = modifierValue / 255 -- Same as red in original implementation

    return red, green, blue
end

return KeybindColorConverter
