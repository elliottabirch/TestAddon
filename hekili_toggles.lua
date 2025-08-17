---@class ns
local ns = select(2, ...)
---@type Constants
local constants = C

-- Only create toggle display if Hekili is available
if not Hekili then
    return
end

-- Container frame that will be moveable
local containerFrame = CreateFrame("Frame", "HekiliTogglesContainer", UIParent)
containerFrame:SetSize(10, 20) -- Fixed size for both squares
containerFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -25)
containerFrame:SetFrameStrata("LOW")

-- Make the container frame moveable
containerFrame:EnableMouse(true)
containerFrame:SetMovable(true)
containerFrame:RegisterForDrag("LeftButton")
containerFrame:SetScript("OnDragStart", containerFrame.StartMoving)
containerFrame:SetScript("OnDragStop", containerFrame.StopMovingOrSizing)

-- Create the cooldowns square (always top position)
local cooldownsFrame = CreateFrame("Frame", "HekiliCooldowns", containerFrame)
cooldownsFrame:SetSize(10, 10)
cooldownsFrame:SetPoint("TOP", containerFrame, "TOP", 0, 0)
cooldownsFrame:SetFrameStrata("LOW")

cooldownsFrame.back = cooldownsFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
cooldownsFrame.back:SetAllPoints(cooldownsFrame)
cooldownsFrame.back:SetColorTexture(0, 1, 0, 1) -- Green
cooldownsFrame:Hide()                           -- Start hidden

-- Create the essences square (always bottom position)
local essencesFrame = CreateFrame("Frame", "HekiliEssences", containerFrame)
essencesFrame:SetSize(10, 10)
essencesFrame:SetPoint("TOP", containerFrame, "TOP", 0, -10)
essencesFrame:SetFrameStrata("LOW")

essencesFrame.back = essencesFrame:CreateTexture(nil, "BACKGROUND", nil, -1)
essencesFrame.back:SetAllPoints(essencesFrame)
essencesFrame.back:SetColorTexture(1, 1, 0, 1) -- Yellow
essencesFrame:Hide()                           -- Start hidden

-- Function to update toggle displays
local function UpdateToggles()
    if not Hekili or not Hekili.DB or not Hekili.DB.profile or not Hekili.DB.profile.toggles then
        return
    end

    -- Check cooldowns toggle - show green square when toggle is OFF
    local cooldownsToggle = Hekili.DB.profile.toggles["cooldowns"]
    if cooldownsToggle and not cooldownsToggle.value then
        cooldownsFrame:Show()
    else
        cooldownsFrame:Hide()
    end

    -- Check essences toggle - show yellow square when toggle is OFF
    local essencesToggle = Hekili.DB.profile.toggles["essences"]
    if essencesToggle and not essencesToggle.value then
        essencesFrame:Show()
    else
        essencesFrame:Hide()
    end
end

-- Wait a bit for Hekili to fully load, then start the update timer
C_Timer.After(2, function()
    if Hekili and Hekili.DB and Hekili.DB.profile then
        -- Update every 100ms to catch toggle changes quickly
        local ticker = C_Timer.NewTicker(0.1, UpdateToggles)
    else
        DEFAULT_CHAT_FRAME:AddMessage("HekiliToggles: Hekili not fully loaded or profile not available")
    end
end)
