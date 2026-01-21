---@class ColorDisplay
---@field Create fun(name: string, row: number, col: number): ColorDisplayFrame
---@field SetColor fun(frame: ColorDisplayFrame, r: number, g: number, b: number)
---@field Clear fun(frame: ColorDisplayFrame)

local MAJOR, MINOR = "TestAddon-ColorDisplay", 1
local ColorDisplay = LibStub:NewLibrary(MAJOR, MINOR)
if not ColorDisplay then return end

--------------------------------------------------------------------------------
-- Color Display Frame Management
--
-- Handles creation and updates of UI frames that display keybind colors.
-- Completely decoupled from how keybind data is obtained or converted.
--------------------------------------------------------------------------------

---@class ColorDisplayFrame
---@field frame Frame
---@field back Texture

local DEFAULT_SIZE = 10
local DEFAULT_STRATA = "TOOLTIP"

--------------------------------------------------------------------------------
-- Frame Factory
--------------------------------------------------------------------------------

--- Create a color display frame at the specified grid position
---@param name string Unique identifier for this frame
---@param row number Grid row (0-indexed)
---@param col number Grid column (0-indexed)
---@return ColorDisplayFrame
function ColorDisplay.Create(name, row, col)
    local frame = CreateFrame("Frame", "ColorDisplay_" .. name, UIParent)
    frame:SetSize(DEFAULT_SIZE, DEFAULT_SIZE)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10 + (col * DEFAULT_SIZE), -25 - (row * DEFAULT_SIZE))
    frame:SetFrameStrata(DEFAULT_STRATA)

    local back = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    back:SetAllPoints(frame)
    back:SetColorTexture(0, 0, 0, 1)

    return {
        frame = frame,
        back = back,
    }
end

--- Create a color display frame using the legacy CreateCustomFrame if available
--- Falls back to standard creation if not available
---@param name string Unique identifier
---@param row number Grid row
---@param col number Grid column
---@return ColorDisplayFrame
function ColorDisplay.CreateWithLegacy(name, row, col)
    -- Try to use the existing C.CreateCustomFrame if available
    if C and C.CreateCustomFrame then
        local legacyFrame = C.CreateCustomFrame(name, row, col)
        return {
            frame = legacyFrame,
            back = legacyFrame.back,
        }
    end

    return ColorDisplay.Create(name, row, col)
end

--------------------------------------------------------------------------------
-- Frame Updates
--------------------------------------------------------------------------------

--- Set the display color
---@param displayFrame ColorDisplayFrame
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a? number Alpha component (0-1), defaults to 1
function ColorDisplay.SetColor(displayFrame, r, g, b, a)
    a = a or 1
    displayFrame.back:SetColorTexture(r, g, b, a)
end

--- Clear the display (set to black)
---@param displayFrame ColorDisplayFrame
function ColorDisplay.Clear(displayFrame)
    displayFrame.back:SetColorTexture(0, 0, 0, 1)
end

--- Show the display frame
---@param displayFrame ColorDisplayFrame
function ColorDisplay.Show(displayFrame)
    displayFrame.frame:Show()
end

--- Hide the display frame
---@param displayFrame ColorDisplayFrame
function ColorDisplay.Hide(displayFrame)
    displayFrame.frame:Hide()
end

return ColorDisplay
