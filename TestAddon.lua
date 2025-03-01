---@type ns
local ns = select(2, ...)

TestAddon = LibStub("AceAddon-3.0"):NewAddon("TestAddon", "AceConsole-3.0", "AceEvent-3.0")
local LSR = LibStub("SpellRange-1.0")

local weakAurasStatus = false

local f = CreateFrame("Frame", "TestBorder", UIParent)
f:SetSize(2, 2)
f:SetPoint("TOPLEFT")
f:SetFrameStrata("TOOLTIP")


f.back = f:CreateTexture(nil, "BACKGROUND", nil, -1)
f.back:SetAllPoints(f)
f.back:SetTexture(255 / 255, 100, 100)

local cycle = C.CreateCustomFrame("cycleBorder", 0, 2)


-- Импортируем WeakAuras, если он не обнаружен
DEFAULT_CHAT_FRAME:AddMessage("TestAddon: Waiting for a response from WeakAuras")
C_Timer.After(5, function()
    if not weakAurasStatus then
        DEFAULT_CHAT_FRAME:AddMessage(
            "TestAddon: Timed out waiting for a response from WeakAuras, if this is the first launch of the program, import the configuration in the modal window. Otherwise, refuse")
        if not WeakAuras.IsTWW() then
            WeakAuras.Import(
                "!WA:2!9r1tVnoru8nBpGKfSSKdrRG9WOGuPvGsraA5eiItDudK201XLURqi3XEEoEOoZmAMXj17XioWbeh6hHCMt5JW(jWQA)e0lCVhqIB8CCkIfTflznVzM3F(9(9EZRr)MtBYAY(LpslZTzCbOhDsWWbh5Dfn3Mk1JuwUuyCuFmJBuz0Ia4cByIupLAdvHw(uiKviOt5XH2unysLzScDXOKedy)1VEfveJU5yjxyJ65DuGNVIC3UQExd1dJZnw50knorXOwWhMbc71iOKOc84t5mBQBxCRMgVgIpX3yPARtucxWnPoU4ID7lzYWAFDwu9Q6pO5AAiiM1zG5a4CEgFOKYag5RidmDzSrI6970U(22764WticPLCxwAtbbrPXCCN2bPaP(Yk01JASK58SmIuKvqMl1NtqNviZjiUZPz4HP0z3AcHlWSildyDiKNJkftfKjGLWXGBj)W85Z7eNRnasutGoXYP7nxoFpkJHmWEPR9Xp2P9UeqWwy18jtaT5bBR3i(NU2cfu286CdesZMtlmwDoC21M8O1e848Ke(fRc71DCq44GU(blzqeEyaAN(aVHh3)KH)J2hRbuB)Xh7nCyPZl7LIq8qWyOta3CK9JQQYG2hBpaJZcJcYYgWmo1wBup(aVVBWWbH(E9gD4HEhTF3GbJok8KJrbVv1LRWkehHKIn34hNcXNx6u2u9Bj5I119Dc)eYA3fUPR62T0iKlSfHC2Uoe8dz9)VY3ADQ(E9AxOpGKmYM78M9kEJd(FZM3a7JrOcvP3I(uod57lZfBQaTkBEF17v1YodcQp6qjd(97PAF3VkMkzHOFHZuBF3kLbtOXfHjzsPoDb2OXovtvloDJGBIuyvpSVM)cYtZPm0FusqWsSw6dtQEa9(TkBDfUnIgF(eCCGG5MH8t)iSHet9w(tZZSChxSmg3Q8lD8JZOgtLKRH)cOsyrvqgJBENRmPuMC(ZQNdS1s96yu1f5ArSFjvWNUMPEs5d6)sGAGXwniMytFRYwUcPaUITHlx3bGT8XsbZSOs1k3u21DkLl6x(nObLDlDl7vUpU(U)3tU0azj1ZFChfem6q1hE3KOsdXCdg0TuFWBuRAb)kLzlRqeVE(O(I6mDOu)tyLNNu4o0RFWsRmEgcEuNh1i8VAZzx)69xB4PNxB9JV3Qen(yb5cS8S1n1dp7xDuvohnUNVN3rryCt4tC(SCoBL1xpy4U72B6tpWpwMj1F7w43Q)f4V)Q6y0B9TnA0yRL4RwGTEe6p)2R4I6KcXyl1J4tesnSzSVxvpVNwl1M0Bqge0cA23xNpN304)fD(0oFEZzV6z)n")
        else
            WeakAuras.Import(
                "!WA:2!9r1tVnoru8TBpSswWQTfPOvWEyuqQQvGs1IelIdGuDQdnqAtxhx6UcHCh7554HApZOzgN0ShJ4aiXP(risCdUKlCF)eyvXNGELB9aN5z70vi0w8f)M38M379737pR1BZ8nzBY(PT1YcBgxa6HNemO)rE(XYmP(Rxh)wY4gvgDwaCH9(6zdtsmG9x(YLurCQuFSKlSrD9okWZxr(xMgMi15uBOk0YZHvNwt9O4cJvMxzXjkg1c(WeqyVMwGAPwE8PCMn1Dp8OMgB5sH5z(glvBDC5cUDRlzYWgFCwuZF1Frl00qqmPtFZbW58m(ajLbmYxq6gUhJnuyWBQfAUy72nM1EhhhEcriTK7Yf2uqquAeKB3oifibGXIEskit5zzePiBgzQuFob9ZmzbbZ5cAgQmLobinUIWficYYawhc5LOrXubzmyjCmUwY3nD60oXfAdGK0yOtSmF3PYP7sRcJz30AF89DAVdbeSOeKfmPoZTA(4XG28WT0Re)Bx7mfuUX1fgiKMnLoZy1fWzxBkIQj5rfjj8lwg2DVrbHJc2ZpyzddgMYzvp8wdpwdOH(Jo2BWGsNx3nfZYdbJHogClWIquvrg0LBO(5KcrDvA7WpMu)2Wv9a3EKgHzVDwiNTJdb)qE6)JRRTP67neDOpGmcc9TF7oeVXPIyQV1OEYbEFt)b9d996o8Wd9oA)9c6p8OWtogf8MBuqwwFMX5wKxrzry1Xwy8JtH4ZlD8f0CW4CdBgkWJ3hZ2keMUGbridgGVqFG3GJ7DYGlleRi)wLBCF1gvDStGGgvhkzWVDpv77EOixYcrNdNP26UnkdgtJNfMKjL60lnqwsZmN7WGGHh6Mifw1J6P5VI88ckdDhLeeSalL(W4QXN3VvzRRWJr04ZhJZ5cMBgY39Cn8xbT8ZlYSChxKyIBv(zo(XzuJPskcBzrgTsCEvqgHM)UrgzHogI45kP2ELjLYKtFrZoH1xORJyfb5ArGmhhmyNQPQ5NUs4sQGNxZMpR8H9kB5kKc41a1aJSAqm2M(GRyR476sdouelfmZ8kBQCC5(U5uUaFB5(LEpOSx5xvEak(E)xnlWoyGvVn5hFh1hE38RsdXCdgW1xbNx2aNNCp9fnsdK6Fa7w4jZCh41lyHvgpbZm8jpETF)pAZzQnEt3A1IRUuJ9tk4SLwFD)b7St38NFWYen2vHOeRpRFtZUZEvQQav0OU(EEhP(G3Aw2i4xLSSiKns4JDuF0DdOv9TH2unysLzSzxHBxX4nuvVp1zzdo7wVIFT1wB9fvCmF1LCrJ7WtBTefJbV6jRZupMpwi1Wk3uR1tRLAt6nydjOf0SVTHx(1nnrFANN(5DE6Mt(Zx8pp")
        end
    end
end)

local function CalculateIsNotDelayed()
    if Hekili.DisplayPool.Primary.Buttons[1] then
        if not Hekili.DisplayPool.Primary.Buttons[1].delayIconShown then
            return true
        end
    end
    return false
end




local allowAcceptNew = false
local shouldPressKeybind = ""

function TestAddon_Process(keyBind, recomendAbilityId)
    if keyBind == nil then
        keyBind = shouldPressKeybind
    else
        shouldPressKeybind = keyBind
    end
    keyBind = normalizeModifiers(keyBind)
    if CalculateIsNotDelayed() then
        local red = getRed(keyBind)
        local green = getGreen(keyBind)
        local blue = getBlue(keyBind)
        f.back:SetColorTexture(red, green, blue)
    else
        f.back:SetColorTexture(0, 0, 0)
    end
end

-- Вызывается из WeakAuras.
-- Hekili отправляет рекомендуемую для нажатия способность в WeakAuras
-- Так мы понимаем, что WeakAuras и Hekili работают нормально
-- Изменяем код Hekili, чтобы получить доступ к keybind
function TestAddon_Recomend(abilityId)
    local shouldCycle = false
    if abilityId then
        if LSR.SpellHasRange(abilityId) == 1 then
            local isInRange = LSR.IsSpellInRange(abilityId, "target")

            if isInRange == 0 then
                -- If the target is not in range, check all nameplates
                for i = 1, 40 do -- Assuming 40 is the max number of nameplates
                    local unit = "nameplate" .. i
                    if C.IsValidUnit(unit, C.blacklisted_mobs) and LSR.IsSpellInRange(abilityId, unit) == 1 then
                        shouldCycle = true
                        break
                    end
                end
            end
            if shouldCycle then
                print("cycle")
                cycle.back:SetColorTexture(1, 0, 0)
            else
                cycle.back:SetColorTexture(0, 0, 0)
            end
        else
            cycle.back:SetColorTexture(0, 0, 0)
        end
    end

    allowAcceptNew = true
    if not weakAurasStatus then
        DEFAULT_CHAT_FRAME:AddMessage("TestAddon: WeakAuras detected and working correctly")
        weakAurasStatus = true
        local GetBindingForAction = Hekili.GetBindingForAction
        Hekili.GetBindingForAction = function(key, display, i)
            local result, secondResult = GetBindingForAction(key, display, i)
            if allowAcceptNew then
                TestAddon_Process(result, abilityId)
                allowAcceptNew = false
            end
            return result, secondResult
        end
    end
    TestAddon_Process(nil, abilityId)
end

function normalizeModifiers(keyBind)
    keyBind = keyBind:upper()
    local result = ""
    local withAlt = false
    local withCtrl = false
    local withShift = false
    if keyBind:len() > 1 and keyBind:match("^A") ~= nil then
        withAlt = true
        keyBind = keyBind:sub(2)
    end
    if keyBind:len() > 1 and keyBind:match("^C") ~= nil then
        withCtrl = true
        keyBind = keyBind:sub(2)
    end
    if keyBind:len() > 1 and keyBind:match("^S") ~= nil then
        withShift = true
        keyBind = keyBind:sub(2)
    end
    if withShift then
        result = "SHIFT\-" .. result
    end
    if withCtrl then
        result = "CTRL\-" .. result
    end
    if withAlt then
        result = "ALT\-" .. result
    end
    return result .. keyBind
end

function getRed(keyBind)
    local red = 0
    if keyBind:match('ALT.CTRL.SHIFT.') ~= nil then
        red = 70 / 255
    elseif keyBind:match("ALT.CTRL.") ~= nil then
        red = 60 / 255
    elseif keyBind:match("ALT.SHIFT.") ~= nil then
        red = 50 / 255
    elseif keyBind:match("ALT.") ~= nil then
        red = 40 / 255
    elseif keyBind:match("CTRL.SHIFT.") ~= nil then
        red = 30 / 255
    elseif keyBind:match("CTRL.") ~= nil then
        red = 20 / 255
    elseif keyBind:match("SHIFT.") ~= nil then
        red = 10 / 255
    end
    return red
end

-- ` = 96
-- 1 = 49
-- 2 = 50
-- 3 = 51
-- 4 = 52
-- 5 = 53
-- 6 = 54
-- 7 = 55
-- 8 = 56
-- 9 = 57
-- 0 = 48
-- - = 45
-- = = 61
-- Q = 81
-- W = 87
-- E = 69
-- R = 82
-- T = 84
-- Y = 89
-- U = 85
-- I = 73
-- O = 79
-- P = 80
-- [ = 91
-- ] = 93
-- A = 65
-- S = 83
-- D = 68
-- F = 70
-- G = 71
-- H = 72
-- J = 74
-- K = 75
-- L = 76
-- ; = 59
-- ' = 39
-- Z = 90
-- X = 88
-- C = 67
-- V = 86
-- B = 66
-- N = 78
-- M = 77
-- , = 44
-- . = 46
-- / = 47
-- F1 = 149
-- F2 = 150
-- F3 = 151
-- F4 = 152
-- F5 = 153
-- F6 = 154
-- F7 = 155
-- F8 = 156
-- F9 = 157
-- F10 = 158
-- F11 = 159
-- F12 = 160
-- MWU = 161
-- MWD = 162
function getGreen(keyBind)
    local green = 0
    keyBind = keyBind:gsub("ALT.", ""):gsub("CTRL.", ""):gsub("SHIFT.", "")
    if keyBind:len() == 1 then
        green = keyBind:byte() .. ""
        green = green * 1
        green = green / 255
    elseif keyBind:match("^F") ~= nil then
        if keyBind:match("^F12$") ~= nil then
            green = 160 / 255
        elseif keyBind:match("^F11$") ~= nil then
            green = 159 / 255
        elseif keyBind:match("^F10$") ~= nil then
            green = 158 / 255
        elseif keyBind:match("^F9$") ~= nil then
            green = 157 / 255
        elseif keyBind:match("^F8$") ~= nil then
            green = 156 / 255
        elseif keyBind:match("^F7$") ~= nil then
            green = 155 / 255
        elseif keyBind:match("^F6$") ~= nil then
            green = 154 / 255
        elseif keyBind:match("^F5$") ~= nil then
            green = 153 / 255
        elseif keyBind:match("^F4$") ~= nil then
            green = 152 / 255
        elseif keyBind:match("^F3$") ~= nil then
            green = 151 / 255
        elseif keyBind:match("^F2$") ~= nil then
            green = 150 / 255
        elseif keyBind:match("^F1$") ~= nil then
            green = 149 / 255
        end
    elseif keyBind:match("^N") ~= nil then
        if keyBind:match("^N1$") ~= nil then
            green = 97 / 255
        elseif keyBind:match("^N2$") ~= nil then
            green = 98 / 255
        elseif keyBind:match("^N3$") ~= nil then
            green = 99 / 255
        elseif keyBind:match("^N4$") ~= nil then
            green = 100 / 255
        elseif keyBind:match("^N5$") ~= nil then
            green = 101 / 255
        elseif keyBind:match("^N6$") ~= nil then
            green = 102 / 255
        elseif keyBind:match("^N7$") ~= nil then
            green = 103 / 255
        elseif keyBind:match("^N8$") ~= nil then
            green = 104 / 255
        elseif keyBind:match("^N9$") ~= nil then
            green = 105 / 255
        elseif keyBind:match("^N0$") ~= nil then
            green = 106 / 255
        end
    elseif keyBind:match("^LEFT$") ~= nil then
        green = 37 / 255
    elseif keyBind:match("^RIGHT$") ~= nil then
        green = 39 / 255
    elseif keyBind:match("^UP$") ~= nil then
        green = 38 / 255
    elseif keyBind:match("^DN$") ~= nil then
        green = 40 / 255
    elseif keyBind:match("^DELETE$") ~= nil then
        green = 46 / 255
    elseif keyBind:match("^MWU$") ~= nil then
        green = 161 / 255
    elseif keyBind:match("^MWD$") ~= nil then
        green = 162 / 255
    end
    return green
end

function getBlue(keyBind)
    return getRed(keyBind)
end
