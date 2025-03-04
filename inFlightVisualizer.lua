-- ---@class ns
-- local ns = select(2, ...)

-- -- Initialize spell history table to store landed spells
-- local spellHistory = {}
-- local MAX_HISTORY_ENTRIES = 10

-- -- Create main frame
-- local visualizerFrame = CreateFrame("Frame", "SpellFlightVisualizer", UIParent, "BackdropTemplate")
-- visualizerFrame:SetSize(400, 300)
-- visualizerFrame:SetPoint("CENTER")
-- visualizerFrame:SetBackdrop({
--     bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
--     edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
--     tile = true,
--     tileSize = 32,
--     edgeSize = 32,
--     insets = { left = 11, right = 12, top = 12, bottom = 11 }
-- })
-- visualizerFrame:SetBackdropColor(0, 0, 0, 0.8)
-- visualizerFrame:EnableMouse(true)
-- visualizerFrame:SetMovable(true)
-- visualizerFrame:RegisterForDrag("LeftButton")
-- visualizerFrame:SetScript("OnDragStart", visualizerFrame.StartMoving)
-- visualizerFrame:SetScript("OnDragStop", visualizerFrame.StopMovingOrSizing)

-- -- Add title
-- local title = visualizerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
-- title:SetPoint("TOP", 0, -20)
-- title:SetText("Spell Flight Tracker")

-- -- Add close button
-- local closeButton = CreateFrame("Button", nil, visualizerFrame, "UIPanelCloseButton")
-- closeButton:SetPoint("TOPRIGHT", -5, -5)
-- closeButton:SetScript("OnClick", function() visualizerFrame:Hide() end)

-- -- Create container for in-flight spells
-- local inFlightContainer = CreateFrame("Frame", nil, visualizerFrame)
-- inFlightContainer:SetSize(380, 80)
-- inFlightContainer:SetPoint("TOP", 0, -50)

-- local inFlightTitle = inFlightContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- inFlightTitle:SetPoint("TOPLEFT", 10, 0)
-- inFlightTitle:SetText("In-Flight Spells:")

-- local inFlightText = inFlightContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
-- inFlightText:SetPoint("TOPLEFT", 20, -20)
-- inFlightText:SetJustifyH("LEFT")
-- inFlightText:SetSize(360, 60)
-- inFlightText:SetText("None")

-- -- Create container for spell history
-- local historyContainer = CreateFrame("Frame", nil, visualizerFrame)
-- historyContainer:SetSize(380, 170)
-- historyContainer:SetPoint("TOP", inFlightContainer, "BOTTOM", 0, -10)

-- local historyTitle = historyContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
-- historyTitle:SetPoint("TOPLEFT", 10, 0)
-- historyTitle:SetText("Spell Landing History:")

-- local historyEntries = {}
-- -- Create text lines for each history entry
-- for i = 1, MAX_HISTORY_ENTRIES do
--     historyEntries[i] = historyContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
--     historyEntries[i]:SetPoint("TOPLEFT", 20, -20 - ((i - 1) * 15))
--     historyEntries[i]:SetJustifyH("LEFT")
--     historyEntries[i]:SetSize(360, 15)
--     historyEntries[i]:SetText("")
-- end

-- -- Add a toggle button to the player UI
-- local toggleButton = CreateFrame("Button", "SpellFlightVisualizerToggle", UIParent, "UIPanelButtonTemplate")
-- toggleButton:SetSize(120, 25)
-- toggleButton:SetPoint("TOPRIGHT", -150, -200)
-- toggleButton:SetText("Spell Tracker")
-- toggleButton:SetScript("OnClick", function()
--     if visualizerFrame:IsShown() then
--         visualizerFrame:Hide()
--     else
--         visualizerFrame:Show()
--     end
-- end)

-- -- Function to add a landed spell to history
-- local function AddToHistory(spellName, castTime, landTime, flightTime)
--     -- Insert at the beginning
--     table.insert(spellHistory, 1, {
--         spellName = spellName,
--         castTime = castTime,
--         landTime = landTime,
--         flightTime = flightTime
--     })

--     -- Keep only the last MAX_HISTORY_ENTRIES
--     if #spellHistory > MAX_HISTORY_ENTRIES then
--         table.remove(spellHistory, MAX_HISTORY_ENTRIES + 1)
--     end

--     -- Update display
--     UpdateHistoryDisplay()
-- end

-- -- Function to update the history display
-- function UpdateHistoryDisplay()
--     for i = 1, MAX_HISTORY_ENTRIES do
--         if spellHistory[i] then
--             local entry = spellHistory[i]
--             -- Format times to show milliseconds
--             local castTimeStr = date("%H:%M:%S", entry.castTime) .. string.format(".%03d", (entry.castTime % 1) * 1000)
--             local landTimeStr = date("%H:%M:%S", entry.landTime) .. string.format(".%03d", (entry.landTime % 1) * 1000)
--             local flightTimeStr = string.format("%.3f", entry.flightTime)

--             historyEntries[i]:SetText(string.format(
--                 "%s | Cast: %s | Land: %s | Flight Time: %s sec",
--                 entry.spellName,
--                 castTimeStr,
--                 landTimeStr,
--                 flightTimeStr
--             ))
--         else
--             historyEntries[i]:SetText("")
--         end
--     end
-- end

-- -- Function to update the in-flight display
-- local function UpdateInFlightDisplay()
--     if not SPELL_FLIGHT_TRACKER or not SPELL_FLIGHT_TRACKER.InFlightSpells then
--         inFlightText:SetText("Spell tracker not initialized")
--         return
--     end

--     local inFlightSpells = SPELL_FLIGHT_TRACKER.InFlightSpells

--     if #inFlightSpells == 0 then
--         inFlightText:SetText("None")
--         return
--     end

--     local text = ""
--     for i, spell in ipairs(inFlightSpells) do
--         local timeInFlight = GetTime() - (spell.castTime or 0)
--         text = text .. string.format("%s (%.2f sec in flight)", spell.spellName, timeInFlight)

--         if i < #inFlightSpells then
--             text = text .. "\n"
--         end
--     end

--     inFlightText:SetText(text)
-- end

-- -- Modify the SPELL_FLIGHT_TRACKER to add landing history
-- local eventFrame = CreateFrame("Frame")
-- eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

-- eventFrame:SetScript("OnEvent", function(self, event, ...)
--     if event == "COMBAT_LOG_EVENT_UNFILTERED" then
--         local timestamp, subEvent, _, sourceGUID, sourceName, sourceFlags, _, destGUID, destName, destFlags, _, spellID, spellName =
--             CombatLogGetCurrentEventInfo()

--         -- Only process events from the player
--         if sourceGUID ~= UnitGUID("player") then
--             return
--         end

--         -- When a spell lands (damage or missed)
--         if (subEvent == "SPELL_DAMAGE" or subEvent == "SPELL_MISSED") and SPELL_FLIGHT_TRACKER.SpellsWithTravelTime[spellName] then
--             -- Look for this spell in our flight tracker
--             for i, spell in ipairs(SPELL_FLIGHT_TRACKER.InFlightSpells) do
--                 if spell.spellID == spellID and spell.targetGUID == destGUID then
--                     -- Record the landing time and add to history
--                     local currentTime = GetTime()
--                     local flightTime = currentTime - spell.castTime
--                     AddToHistory(spellName, spell.castTime, currentTime, flightTime)
--                     break
--                 end
--             end
--         end
--     end
-- end)

-- -- Update the display periodically
-- local updateTimer = C_Timer.NewTicker(0.01, function()
--     UpdateInFlightDisplay()
-- end)

-- -- Show the frame by default
-- visualizerFrame:Show()
