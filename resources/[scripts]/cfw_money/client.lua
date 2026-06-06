-- ============================================================
-- cfw_money — client: يعرض الرصيد ويزامن مع السيرفر
-- ============================================================

local myCash = 0
local myBank = 0
local showHud = true

-- استقبال المزامنة من السيرفر
RegisterNetEvent('cfw_money:sync', function(cash, bank)
    myCash = cash or 0
    myBank = bank or 0
end)

-- اطلب مزامنة عند تحميل الكلاينت
CreateThread(function()
    Wait(2000)
    TriggerServerEvent('cfw_money:requestSync')
end)

-- HUD بسيط أعلى يمين الشاشة
CreateThread(function()
    while true do
        Wait(0)
        if showHud then
            -- النقد
            SetTextFont(4)
            SetTextScale(0.0, 0.45)
            SetTextColour(120, 255, 120, 255)
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentString(('Cash: $%d'):format(myCash))
            DrawText(0.86, 0.02)
            -- البنك
            SetTextFont(4)
            SetTextScale(0.0, 0.45)
            SetTextColour(120, 200, 255, 255)
            SetTextOutline()
            SetTextEntry('STRING')
            AddTextComponentString(('Bank: $%d'):format(myBank))
            DrawText(0.86, 0.06)
        else
            Wait(500)
        end
    end
end)

-- أمر لإخفاء/إظهار الـ HUD
RegisterCommand('togglemoney', function()
    showHud = not showHud
end, false)

-- ============================================================
-- عرض في الـ Main Menu (شاشة Pause/ESC) — مثل صورة OxSaad
-- يعرض: الاسم | التاريخ والوقت | BANK $ و CASH $
-- ============================================================
local function drawPauseText(text, x, y, scale, r, g, b)
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, 255)
    SetTextOutline()
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(x, y)
end

CreateThread(function()
    while true do
        if IsPauseMenuActive() then
            Wait(0)
            -- اسم اللاعب
            local name = GetPlayerName(PlayerId())
            -- التاريخ والوقت داخل اللعبة
            local day = GetClockDayOfWeek()
            local days = { [0]='SUNDAY', [1]='MONDAY', [2]='TUESDAY', [3]='WEDNESDAY', [4]='THURSDAY', [5]='FRIDAY', [6]='SATURDAY' }
            local hour = GetClockHours()
            local minute = GetClockMinutes()
            local timeStr = ('%s %02d:%02d'):format(days[day] or 'DAY', hour, minute)

            -- اللوحة أعلى يسار شاشة الـ pause
            drawPauseText(name, 0.122, 0.04, 0.55, 255, 255, 255)
            drawPauseText(timeStr, 0.122, 0.075, 0.42, 200, 200, 200)
            drawPauseText(('BANK $%d   CASH $%d'):format(myBank, myCash), 0.122, 0.105, 0.42, 120, 255, 160)
        else
            Wait(300)
        end
    end
end)

-- exports client-side للاستخدام المحلي (للعرض فقط)
exports('GetCashClient', function() return myCash end)
exports('GetBankClient', function() return myBank end)