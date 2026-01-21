---@class TestDataSource
---@field GetTestKeybinds fun(): table
---@field GetCurrentKeybind fun(): string
---@field NextKeybind fun(): string
---@field IsDelayed fun(): boolean
---@field SetDelayed fun(delayed: boolean)

local MAJOR, MINOR = "TestAddon-TestDataSource", 1
local TestDataSource = LibStub:NewLibrary(MAJOR, MINOR)
if not TestDataSource then return end

--------------------------------------------------------------------------------
-- Test Data Source
--
-- Provides static test data for verifying the keybind-to-color pipeline.
-- Replaces HekiliKeybindSource during testing.
--------------------------------------------------------------------------------

-- Test keybinds covering various modifier combinations and keys
local TEST_KEYBINDS = {
    -- No modifiers
    "1", "2", "3", "4", "5",
    "Q", "E", "R", "T",
    "F", "G", "Z", "X", "C", "V",

    -- Single modifiers
    "SHIFT-1", "SHIFT-2", "SHIFT-Q", "SHIFT-E",
    "CTRL-1", "CTRL-2", "CTRL-Q", "CTRL-E",
    "ALT-1", "ALT-2", "ALT-Q", "ALT-E",

    -- Double modifiers
    "CTRL-SHIFT-1", "CTRL-SHIFT-Q",
    "ALT-SHIFT-1", "ALT-SHIFT-Q",
    "ALT-CTRL-1", "ALT-CTRL-Q",

    -- Triple modifiers
    "ALT-CTRL-SHIFT-1", "ALT-CTRL-SHIFT-Q",

    -- Function keys
    "F1", "F2", "F3", "F4",
    "SHIFT-F1", "CTRL-F1",

    -- Numpad
    "N1", "N2", "N3",
    "SHIFT-N1",

    -- Special keys
    "MWU", "MWD",
    "SHIFT-MWU", "CTRL-MWD",
}

local currentIndex = 1
local isDelayed = false

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

--- Get the full list of test keybinds
---@return table keybinds Array of test keybind strings
function TestDataSource.GetTestKeybinds()
    return TEST_KEYBINDS
end

--- Get the current test keybind
---@return string keybind Current keybind in the rotation
function TestDataSource.GetCurrentKeybind()
    return TEST_KEYBINDS[currentIndex]
end

--- Advance to the next keybind and return it
---@return string keybind The new current keybind
function TestDataSource.NextKeybind()
    currentIndex = currentIndex + 1
    if currentIndex > #TEST_KEYBINDS then
        currentIndex = 1
    end
    return TEST_KEYBINDS[currentIndex]
end

--- Go to the previous keybind and return it
---@return string keybind The new current keybind
function TestDataSource.PrevKeybind()
    currentIndex = currentIndex - 1
    if currentIndex < 1 then
        currentIndex = #TEST_KEYBINDS
    end
    return TEST_KEYBINDS[currentIndex]
end

--- Set a specific keybind by index
---@param index number The index to set (1-indexed)
function TestDataSource.SetIndex(index)
    if index >= 1 and index <= #TEST_KEYBINDS then
        currentIndex = index
    end
end

--- Get the current index
---@return number index Current position in the test data
function TestDataSource.GetIndex()
    return currentIndex
end

--- Get total number of test keybinds
---@return number count Total keybinds in test set
function TestDataSource.GetCount()
    return #TEST_KEYBINDS
end

--- Check if currently in "delayed" state (simulates Hekili delay)
---@return boolean isDelayed
function TestDataSource.IsDelayed()
    return isDelayed
end

--- Set the delayed state for testing
---@param delayed boolean
function TestDataSource.SetDelayed(delayed)
    isDelayed = delayed
end

--- Toggle the delayed state
---@return boolean newState The new delayed state
function TestDataSource.ToggleDelayed()
    isDelayed = not isDelayed
    return isDelayed
end

return TestDataSource
