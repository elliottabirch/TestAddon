--------------------------------------------------------------------------------
-- TestAddon.lua
-- Main Entry Point
--
-- Test harness for keybind-to-color conversion system.
-- Supports two modes:
--   TEST mode: Cycles through static test keybinds (/ta next, /ta prev)
--   LIVE mode: Polls C_AssistedCombat for currently suggested spell (/ta live)
--
-- Slash Commands:
--   /ta next     - Show next test keybind
--   /ta prev     - Show previous test keybind
--   /ta delay    - Toggle delay state (black = delayed)
--   /ta auto     - Start/stop auto-cycling through keybinds
--   /ta status   - Show current keybind and RGB values
--   /ta live     - Toggle live mode (Assisted Combat)
--   /ta ls       - Show live mode status
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

-- Live mode state
local liveModeEnabled = false
local liveUpdateTicker = nil
local LIVE_UPDATE_INTERVAL = 0.05 -- 50ms = 20 updates/sec

--------------------------------------------------------------------------------
-- Live Mode: Assisted Combat Integration
--------------------------------------------------------------------------------

--- Get keybind for currently suggested spell from Assisted Combat
local function GetAssistedCombatKeybind()
    if not C_AssistedCombat or not C_AssistedCombat.GetNextCastSpell then
        return nil, nil, nil
    end

    local success, spellID = pcall(C_AssistedCombat.GetNextCastSpell, true)

    if not success or not spellID or type(spellID) ~= "number" or spellID == 0 then
        return nil, nil, nil
    end

    -- Get spell name for display
    local spellName = nil
    if C_Spell and C_Spell.GetSpellInfo then
        local info = C_Spell.GetSpellInfo(spellID)
        spellName = info and info.name
    end

    -- Get keybind via KeybindLookup
    local keybind = nil
    if KeybindLookup and KeybindLookup.GetSpellKeybind then
        keybind = KeybindLookup.GetSpellKeybind(spellID)
    end

    return keybind, spellName, spellID
end

--- Update display from live Assisted Combat data
local function UpdateDisplayLive()
    local keybind, spellName, spellID = GetAssistedCombatKeybind()

    if not keybind then
        -- No keybind found - show black
        Display.SetColor(mainDisplay, 0, 0, 0)
        return
    end

    -- Normalize and convert to color
    local normalized = Normalizer.Normalize(keybind)
    local r, g, b = ColorConverter.ConvertToRGB(normalized)

    Display.SetColor(mainDisplay, r, g, b)
end

--- Start live mode (continuous updates from Assisted Combat)
local function StartLiveMode()
    if liveUpdateTicker then return end

    -- Stop test mode auto-cycle if running
    if autoCycleTimer then
        autoCycleTimer:Cancel()
        autoCycleTimer = nil
    end

    liveModeEnabled = true
    liveUpdateTicker = C_Timer.NewTicker(LIVE_UPDATE_INTERVAL, UpdateDisplayLive)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Live mode |cff00ff00STARTED|r")
end

--- Stop live mode
local function StopLiveMode()
    if liveUpdateTicker then
        liveUpdateTicker:Cancel()
        liveUpdateTicker = nil
    end
    liveModeEnabled = false
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Live mode |cffffff00STOPPED|r")
end

--- Print live mode status
local function PrintLiveStatus()
    local keybind, spellName, spellID = GetAssistedCombatKeybind()

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon Live Status:|r")
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Mode: %s",
        liveModeEnabled and "|cff00ff00LIVE|r" or "|cffffff00TEST|r"))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Spell: %s (ID: %s)",
        spellName or "None", tostring(spellID or "nil")))
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  Keybind: %s", keybind or "None"))

    if keybind then
        local normalized = Normalizer.Normalize(keybind)
        local r, g, b = ColorConverter.ConvertToRGB(normalized)
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Normalized: %s", normalized))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("  RGB: (%.3f, %.3f, %.3f)", r, g, b))
    end

    -- API check
    local apiAvailable = C_AssistedCombat and C_AssistedCombat.GetNextCastSpell
    DEFAULT_CHAT_FRAME:AddMessage(string.format("  API: %s",
        apiAvailable and "|cff00ff00Available|r" or "|cffff0000Not Available|r"))

    if not apiAvailable then
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00Tip: /console assistedMode 1|r")
    end
end

--------------------------------------------------------------------------------
-- Test Mode: Static Data Processing
--------------------------------------------------------------------------------

--- Process the current test keybind and update display
local function UpdateDisplay()
    local keybind = DataSource.GetCurrentKeybind()

    if DataSource.IsDelayed() then
        -- Delayed state: show black
        Display.SetColor(mainDisplay, 0, 0, 0)
        return
    end

    -- Normalize and convert
    local normalized = Normalizer.Normalize(keybind)
    local r, g, b = ColorConverter.ConvertToRGB(normalized)

    -- Update display
    Display.SetColor(mainDisplay, r, g, b)
end

--- Print current test status to chat
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
-- Keybind Lookup Subcommands
--------------------------------------------------------------------------------

local function HandleKeybindLookupCommand(args)
    if not KeybindLookup then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000TestAddon|r: KeybindLookup module not loaded")
        return
    end

    -- Parse subcommand
    local subCmd = args:match("^(%S+)") or ""
    local remainder = args:match("^%S+%s+(.+)") or ""
    subCmd = subCmd:lower()

    if subCmd == "" or subCmd == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon Keybind Lookup:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb dump       - Show all cached spell keybinds")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb slots      - Show slot -> keybind mappings")
        DEFAULT_CHAT_FRAME:AddMessage("  /ta kb find <n> - Look up keybind for spell")
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

    -- Live mode commands
    if cmd == "live" or cmd == "l" then
        if liveModeEnabled then
            StopLiveMode()
        else
            StartLiveMode()
        end
        return
    end

    if cmd == "livestatus" or cmd == "ls" then
        PrintLiveStatus()
        return
    end

    -- Test mode commands
    if cmd == "next" or cmd == "n" then
        if liveModeEnabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Stop live mode first (/ta live)")
            return
        end
        DataSource.NextKeybind()
        UpdateDisplay()
        PrintStatus()
    elseif cmd == "prev" or cmd == "p" then
        if liveModeEnabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Stop live mode first (/ta live)")
            return
        end
        DataSource.PrevKeybind()
        UpdateDisplay()
        PrintStatus()
    elseif cmd == "delay" or cmd == "d" then
        if liveModeEnabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Delay not applicable in live mode")
            return
        end
        local newState = DataSource.ToggleDelayed()
        UpdateDisplay()
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Delay " .. (newState and "ON (black)" or "OFF (showing color)"))
    elseif cmd == "auto" or cmd == "a" then
        if liveModeEnabled then
            DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Stop live mode first (/ta live)")
            return
        end
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
        if liveModeEnabled then
            PrintLiveStatus()
        else
            PrintStatus()
        end
    elseif cmd == "help" or cmd == "?" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00Live Mode:|r")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta live (l)   - Toggle live mode (Assisted Combat)")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta ls         - Show live mode status")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00Test Mode:|r")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta next (n)   - Next keybind")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta prev (p)   - Previous keybind")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta delay (d)  - Toggle delay state")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta auto (a)   - Toggle auto-cycle")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta status (s) - Show current state")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00Keybind Lookup:|r")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta kb         - Keybind lookup commands")
        DEFAULT_CHAT_FRAME:AddMessage("  |cffffff00Direct Test:|r")
        DEFAULT_CHAT_FRAME:AddMessage("    /ta <keybind>  - Test any keybind (e.g., /ta CTRL-Q)")
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

    -- KeybindLookup is global (not LibStub)
    KeybindLookup = _G.KeybindLookup

    -- Create display frame
    mainDisplay = Display.CreateWithLegacy("main", 0, 0)

    -- Register slash commands
    self:RegisterChatCommand("ta", HandleSlashCommand)
    self:RegisterChatCommand("testaddon", HandleSlashCommand)

    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Loaded. Type /ta help for commands.")
end

function TestAddon:OnEnable()
    -- Check if Assisted Combat API is available
    if C_AssistedCombat and C_AssistedCombat.GetNextCastSpell then
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00TestAddon|r: Assisted Combat API available. Use /ta live to start.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00TestAddon|r: Assisted Combat API not available. Enable with /console assistedMode 1")
    end

    -- Show initial test keybind
    StartLiveMode()
    UpdateDisplay()
    PrintStatus()
end

return TestAddon
