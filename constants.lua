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
    ["Trickshot"] = true,
    ["Surveying Beam"] = true,
    ["Cinderblast"] = true,
    ["Fireball Volley"] = true,
    ["Mole Frenzy"] = true,
    ["Explosive Flame"] = true,
    ["Flaming Tether"] = true,
    ["Drain Light"] = true,
    ["Free Samples?"] = true,
    ["Bee-stial Wrath"] = true,
    ["Honey Volley"] = true,
    ["Toxic Blades"] = true,
    ["Rock Lance"] = true,
    ["Furious Quake"] = true,
    ["Detonate"] = true,
    ["Giga-Wallop"] = true,
    ["Bone Spear"] = true,

    ["Iced Spritzer"] = true,
    ["Transmute: Enemy to Goo"] = true,
    ["Tectonic Barrier"] = true,
    ["Rejuvenating Honey"] = true,
    ["Unholy Fervor"] = true,
    ["Demoralizing Shout"] = true,

    ["Spirit Frost"] = true,
    ["Meat Shield"] = true,
    ["Withering Discharge"] = true,
    ["Necromantic Bolt"] = true,
    ["Necrotic Bolt"] = true,
}


C.ams_spells = {
}

C.tank_busters = {
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
    frame:SetSize(20, 20)
    frame:SetPoint("TOPLEFT")
    frame:SetFrameStrata("TOOLTIP")
    frame:AdjustPointsOffset(column * 20, row * -20)


    frame.back = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    frame.back:SetAllPoints(frame)
    frame.back:SetTexture(255 / 255, 100, 100)

    return frame
end
