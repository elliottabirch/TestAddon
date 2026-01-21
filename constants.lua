---@class Constants
---@field CreateCustomFrame fun(name: string, row: number, col: number): Frame

C = {}

local FRAME_SIZE = 10
local FRAME_STRATA = "TOOLTIP"
local BASE_X = 10
local BASE_Y = -25

--- Create a colored square frame at a grid position
---@param name string Unique frame name
---@param row number Grid row (0-indexed)
---@param col number Grid column (0-indexed)
---@return Frame frame The created frame with .back texture
function C.CreateCustomFrame(name, row, col)
    local frame = CreateFrame("Frame", "TestAddon_" .. name, UIParent)
    frame:SetSize(FRAME_SIZE, FRAME_SIZE)
    frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", BASE_X + (col * FRAME_SIZE), BASE_Y - (row * FRAME_SIZE))
    frame:SetFrameStrata(FRAME_STRATA)

    frame.back = frame:CreateTexture(nil, "BACKGROUND", nil, -1)
    frame.back:SetAllPoints(frame)
    frame.back:SetColorTexture(0, 0, 0, 1)

    return frame
end

return C
