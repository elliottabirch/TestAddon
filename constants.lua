---@class ns
local ns = select(2, ...)
---@class Constants
---@field IsValidUnit fun(unit: string, nameBlackList: table<string, boolean> ): boolean
---@field CreateCustomFrame fun(name: string, column: number , row: number ): table
C = {}

---@type table<string, boolean>
C.blacklisted_mobs = {
    ["Training Dummy"] = true,
    ["Friendly NPC"] = true,
}
---@type table<string, boolean>
C.important_interruptable_spells = {
    ["Tormenting Beam"] = true,
    ["Hearthstone"] = true,
    ["Night Bolt"] = true,
    ["Shadow Bolt"] = true,

    ["Mole Frenzy"] = true,
    -- Explosive Flame
    ["Explosive Flame"] = true,
    -- Flaming Tether
    ["Flaming Tether"] = true,
    -- Paranoid Mind
    ["Paranoid Mind"] = true,
    -- Call Darkspawn
    ["Call Darkspawn"] = true,
    -- Drain Light
    ["Drain Light"] = true
}

C.ams_spells = {
    ["Tormenting Beam"] = true,
    ["Night Bolt"] = true,
    ["Shadow Bolt"] = true,

    ["Mole Frenzy"] = true,
    -- Explosive Flame
    ["Explosive Flame"] = true,
    -- Flaming Tether
    ["Flaming Tether"] = true,
    -- Paranoid Mind
    ["Paranoid Mind"] = true,
    -- Call Darkspawn
    ["Call Darkspawn"] = true,
    -- Drain Light
    ["Drain Light"] = true
}

C.tank_busters = {
    ["Tormenting Beam"] = true,
    ["Night Bolt"] = true,
    ["Shadow Bolt"] = true,

    ["Mole Frenzy"] = true,
    -- Explosive Flame
    ["Explosive Flame"] = true,
    -- Flaming Tether
    ["Flaming Tether"] = true,
    -- Paranoid Mind
    ["Paranoid Mind"] = true,
    -- Call Darkspawn
    ["Call Darkspawn"] = true,
    -- Drain Light
    ["Drain Light"] = true
}


C.IsValidUnit = function(unit, nameBlacklist)
    if not UnitExists(unit) then
        return false
    end

    if UnitIsDead(unit) then
        return false
    end

    if not UnitAffectingCombat(unit) then
        return false
    end

    if not UnitIsEnemy("player", unit) then
        return false
    end

    local unitName = UnitName(unit)
    if unitName and nameBlacklist[unitName] then
        return false
    end

    return true
end

C.CreateCustomFrame = function(name, column, row)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetSize(2, 2)
    frame:SetPoint("TOPLEFT")
    frame:SetFrameStrata("TOOLTIP")
    frame:AdjustPointsOffset(column * 2, row * -2)


    frame.back = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    frame.back:SetAllPoints(frame)
    frame.back:SetTexture(255 / 255, 100, 100)

    return frame
end
