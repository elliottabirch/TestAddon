---@class TestAddon
--------------------------------------------------------------------------------
-- TestAddon - Test Harness
--
-- Simplified test version that uses static data to verify the color pipeline.
-- No external dependencies (Hekili, WeakAuras, etc.)
--
-- Slash Commands:
--   /ta next     - Show next test keybind
--   /ta prev     - Show previous test keybind
--   /ta delay    - Toggle delay state (black = delayed)
--   /ta auto     - Start/stop auto-cycling through keybinds
--   /ta status   - Show current keybind and RGB values
--
-- Keybind Lookup Commands:
--   /ta kb dump    - Show all cached spell keybinds
--   /ta kb slots   - Show slot -> keybind mappings
--   /ta kb find X  - Look up keybind for spell name X
--   /ta kb refresh - Force cache refresh
--   /ta kb clear   - Clear all cached data
--   /ta kb diag    - Toggle diagnostic logging
--------------------------------------------------------------------------------

TestAddon = LibStub("AceAddon-3.0"):NewAddon("TestAddon", "AceConsole-3.0", "AceEvent-3.0")

-- Module references
local ColorConverter
local Normalizer
local Display
local DataSource
local KeybindLookup

-- UI State
local mainDisplay
local autoCycleTimer = nil

--------------------------------------------------------------------------------
-- Core Processing Pipeline
--------------------------------------------------------------------------------

--- Process the current keybind and update display
local function UpdateDisplay()
    local keybind = DataSource.GetCurrentKeybind()

    if DataSource.IsDelayed() then
        -- Delayed state: show black
        Display.Clear(mainDisplay)
        return
    end

    -- Normalize and convert
    local normalized = Normalizer.Normalize(keybind)
    local r, g, b = ColorConverter.ConvertToRGB(normalized)

    -- Update display
    Display.SetColor(mainDisplay, r, g, b)
end

--- Print current status to chat
local function PrintStatus()
    local keybind = DataSource.GetCurrentKeybind()
    local normalized = Normalizer.Normalize(keybind)
    local r, g, b = ColorConverter.ConvertToRGB(normalized)

    local index = DataSource.GetIndex()
    local total = DataSource.GetCount()
    local delayed = DataSource.IsDelayed() and "YES" or "NO"

    DEFAULT_CHAT_FRAME:AddMessage(string.format(
        "|cff00ff00TestAddon|r [%d/%d]: %s -> %s | RGB(%.3f, %.3f, %.3f) | Delayed: %s",
        index, total, keybind, normalized, r, g, b, delayed
    ))
end

--------------------------------------------------------------------------------
-- Keybind Lookup Slash Commands
--------------------------------------------------------------------------------

local function HandleKeybindLookupCommand(args)
    if not KeybindLookup then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: KeybindLookup module not loaded")
        return
    end

    local subCmd = args:match("^(%S+)") or ""
    local remainder = args:match("^%S+%s+(.+)") or ""
    subCmd = subCmd:lower()

    if subCmd == "" or subCmd == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon Keybind Lookup Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb dump       - Show all cached spell keybinds")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb slots      - Show slot -> keybind mappings")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb find <name> - Look up keybind for a spell")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb refresh    - Force cache refresh")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb clear      - Clear all cached data")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb diag on|off - Toggle diagnostic logging")
    elseif subCmd == "dump" then
        KeybindLookup.DumpCache()
    elseif subCmd == "slots" then
        KeybindLookup.DumpSlots()
    elseif subCmd == "find" then
        if remainder ~= "" then
            KeybindLookup.FindSpell(remainder)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Usage: /ta kb find <spell name>")
        end
    elseif subCmd == "refresh" then
        KeybindLookup.ForceRefresh()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Keybind cache refreshed")
    elseif subCmd == "clear" then
        KeybindLookup.ClearCache()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Keybind cache cleared")
    elseif subCmd == "diag" then
        if remainder == "on" then
            KeybindLookup.SetDiagnosticLogging(true)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Diagnostic logging enabled")
        elseif remainder == "off" then
            KeybindLookup.SetDiagnosticLogging(false)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Diagnostic logging disabled")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Usage: /ta kb diag on|off")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Unknown kb command. Type /ta kb help")
    end
end

--------------------------------------------------------------------------------
-- Main Slash Commands
--------------------------------------------------------------------------------

local function HandleSlashCommand(input)
    local cmd = input:lower():trim()

    -- Check for keybind lookup subcommands
    if cmd:match("^kb%s*") or cmd == "kb" then
        local kbArgs = cmd:match("^kb%s*(.*)") or ""
        HandleKeybindLookupCommand(kbArgs)
        return
    end

    if cmd == "next" or cmd == "n" then
        DataSource.NextKeybind()
        UpdateDisplay()
        PrintStatus()
    elseif cmd == "prev" or cmd == "p" then
        DataSource.PrevKeybind()
        UpdateDisplay()
        PrintStatus()
    elseif cmd == "delay" or cmd == "d" then
        local newState = DataSource.ToggleDelayed()
        UpdateDisplay()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Delay " .. (newState and "ON (black)" or "OFF (showing color)"))
    elseif cmd == "auto" or cmd == "a" then
        if autoCycleTimer then
            autoCycleTimer:Cancel()
            autoCycleTimer = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Auto-cycle STOPPED")
        else
            autoCycleTimer = C_Timer.NewTicker(1.0, function()
                DataSource.NextKeybind()
                UpdateDisplay()
                PrintStatus()
            end)
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Auto-cycle STARTED (1 sec interval)")
        end
    elseif cmd == "status" or cmd == "s" or cmd == "" then
        PrintStatus()
    elseif cmd == "help" or cmd == "?" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta next (n)   - Next keybind")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta prev (p)   - Previous keybind")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta delay (d)  - Toggle delay state")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta auto (a)   - Toggle auto-cycle")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta status (s) - Show current state")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb         - Keybind lookup commands (type /ta kb help)")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta <keybind>  - Test arbitrary keybind (e.g., /ta CTRL-Q)")
    else
        -- Try to parse as a direct keybind test
        local normalized = Normalizer.Normalize(input)
        local r, g, b = ColorConverter.ConvertToRGB(normalized)
        Display.SetColor(mainDisplay, r, g, b)
        DEFAULT_CHAT_FRAME:AddMessage(string.format(
            "|cff00ff00TestAddon|r: Testing '%s' -> %s | RGB(%.3f, %.3f, %.3f)",
            input, normalized, r, g, b
        ))
    end
end

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function TestAddon:OnInitialize()
    -- Get module references
    ColorConverter = LibStub("TestAddon-KeybindColorConverter")
    Normalizer = LibStub("TestAddon-KeybindNormalizer")
    Display = LibStub("TestAddon-ColorDisplay")
    DataSource = LibStub("TestAddon-TestDataSource")

    -- KeybindLookup is a standalone module (not LibStub)
    -- It's loaded globally when the file loads
    KeybindLookup = _G.KeybindLookup or KeybindLookup

    -- Create display frame
    mainDisplay = Display.CreateWithLegacy("main", 0, 0)

    -- Register slash commands
    self:RegisterChatCommand("ta", HandleSlashCommand)
    self:RegisterChatCommand("testaddon", HandleSlashCommand)

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Loaded. Type /ta help for commands.")
end

function TestAddon:OnEnable()
    -- Show initial keybind
    UpdateDisplay()
    PrintStatus()
end

return TestAddon
