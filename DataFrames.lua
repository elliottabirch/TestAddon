---@class ns
local ns = select(2, ...)
---@type Constants
local constants = C



local mouseover_interrupt = C.CreateCustomFrame("mouseover_interruptBorder", 0, 2)
local focus_interrupt = C.CreateCustomFrame("focus_interruptBorder", 0, 3)

function IsUnitCastingSpell(unit, spellNames)
    if not constants.IsValidUnit(unit, constants.blacklisted_mobs) then
        return 0
    end

    local spellName = UnitCastingInfo(unit)
    if not spellName then
        spellName = UnitChannelInfo(unit)
    end
    if spellName and spellNames[spellName] and C_Spell.IsSpellInRange(47528, unit) and C_Spell.GetSpellCooldown(47528).startTime == 0 then
        return 1
    end

    return 0
end

local function updateFrames()
    mouseover_interrupt.back:SetColorTexture(IsUnitCastingSpell("mouseover", constants.important_interruptable_spells), 0,
        0)
    focus_interrupt.back:SetColorTexture(IsUnitCastingSpell("focus", constants.important_interruptable_spells), 0, 0)
end


local ticker = C_Timer.NewTicker(0.01, updateFrames)
