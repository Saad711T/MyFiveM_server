-- ============================================================
-- cfw_inventory — المرحلة 1: client
-- يفتح/يقفل الواجهة بزر I، يستقبل البيانات من السيرفر
-- ============================================================

local invOpen = false
local nuiReady = false
local invData = {}
local slotCount = 24
local equippedWeapon = nil  -- { hash, slot } السلاح المجهّز حالياً

-- تأكيد التحميل + فحص الـ config
CreateThread(function()
    if Config and Config.Items then
        print('^2[cfw_inventory] client loaded OK. SlotCount=' .. tostring(Config.SlotCount) .. '^0')
    else
        print('^1[cfw_inventory] ERROR: Config not loaded! (config.lua مشكلة)^0')
    end
end)

-- ===== استقبال البيانات =====
RegisterNetEvent('cfw_inv:sync', function(items, slots)
    invData = items or {}
    slotCount = slots or 24
    -- لو الواجهة مفتوحة، حدّثها
    if invOpen then
        SendNUIMessage({ action = 'update', items = invData, slots = slotCount })
    end
end)

-- اطلب مزامنة عند البداية
CreateThread(function()
    while not nuiReady do Wait(100) end
    Wait(500)
    TriggerServerEvent('cfw_inv:requestSync')
end)

-- ===== فتح/إغلاق =====
local function openInv()
    if invOpen then return end
    invOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', items = invData, slots = slotCount })
    print('^2[cfw_inventory] inventory opened^0')
end

local function closeInv()
    if not invOpen then return end
    invOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end

-- ===== زر I لفتح/إغلاق (عبر RegisterKeyMapping الرسمي) =====
-- يقدر اللاعب يغيّر الزر من Settings > Key Bindings > FiveM
RegisterCommand('+toggleInv', function()
    if invOpen then closeInv() else openInv() end
end, false)
RegisterCommand('-toggleInv', function() end, false)
RegisterKeyMapping('+toggleInv', 'فتح/إغلاق الإنفنتوري', 'keyboard', 'I')

-- ESC يقفل
CreateThread(function()
    while true do
        if invOpen then
            Wait(0)
            if IsControlJustReleased(0, 322) then  -- ESC
                closeInv()
            end
        else
            Wait(300)
        end
    end
end)

-- ===== NUI Callbacks =====
RegisterNUICallback('nuiReady', function(_, cb)
    cb({ ok = true })
    nuiReady = true
end)

RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
    invOpen = false
    SetNuiFocus(false, false)
end)

-- سحب وإفلات (نقل بين خليتين)
RegisterNUICallback('moveItem', function(data, cb)
    cb({ ok = true })
    if data and data.from ~= nil and data.to ~= nil then
        TriggerServerEvent('cfw_inv:move', data.from, data.to)
    end
end)

-- إسقاط
RegisterNUICallback('dropItem', function(data, cb)
    cb({ ok = true })
    if data and data.slot ~= nil then
        TriggerServerEvent('cfw_inv:drop', data.slot)
    end
end)

-- استخدام
RegisterNUICallback('useItem', function(data, cb)
    cb({ ok = true })
    if data and data.slot ~= nil then
        TriggerServerEvent('cfw_inv:use', data.slot)
    end
end)

-- ===== إزالة سلاح (عند إسقاطه) =====
RegisterNetEvent('cfw_inv:removeWeapon', function(weaponName)
    local ped = PlayerPedId()
    local hash = GetHashKey(weaponName)
    RemoveWeaponFromPed(ped, hash)
    -- لو هو السلاح المجهّز حالياً، نظّف المتغير
    if equippedWeapon and equippedWeapon.hash == hash then
        equippedWeapon = nil
    end
end)

-- ===== تنفيذ الأكل (أنيميشن) =====
RegisterNetEvent('cfw_inv:doEat', function(itemName, heal, isDrink)
    local ped = PlayerPedId()
    -- اختر الأنيميشن: شرب أو أكل
    local dict = isDrink and 'mp_player_intdrink' or 'mp_player_inteat@burger'
    local anim = isDrink and 'loop_bottle' or 'mp_player_int_eat_burger'
    RequestAnimDict(dict)
    local tries = 0
    while not HasAnimDictLoaded(dict) and tries < 50 do Wait(20); tries = tries + 1 end
    TaskPlayAnim(ped, dict, anim, 3.0, -1, 3000, 49, 0, false, false, false)
    Wait(3000)
    ClearPedTasks(ped)
    -- شفاء
    if heal and heal > 0 then
        local hp = GetEntityHealth(ped)
        local maxHp = GetEntityMaxHealth(ped)
        SetEntityHealth(ped, math.min(hp + heal, maxHp))
    end
end)

-- ===== تجهيز السلاح (بالذخيرة المحفوظة) =====
RegisterNetEvent('cfw_inv:doEquipWeapon', function(weaponName, ammo, slot)
    local ped = PlayerPedId()
    local hash = GetHashKey(weaponName)
    -- لو فيه سلاح مجهّز من قبل، احفظ ذخيرته أول
    if equippedWeapon then
        local cur = GetAmmoInPedWeapon(ped, equippedWeapon.hash)
        TriggerServerEvent('cfw_inv:updateAmmo', equippedWeapon.slot, cur)
    end
    -- أعط السلاح بالذخيرة المحفوظة
    GiveWeaponToPed(ped, hash, ammo, false, true)
    SetCurrentPedWeapon(ped, hash, true)
    equippedWeapon = { hash = hash, slot = slot }
    -- أغلق الإنفنتوري بعد التجهيز
    invOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end)

-- نحفظ ذخيرة السلاح المجهّز كل فترة (عشان تنحفظ لو فتح الإنفنتوري)
CreateThread(function()
    while true do
        Wait(2000)
        if equippedWeapon then
            local ped = PlayerPedId()
            if HasPedGotWeapon(ped, equippedWeapon.hash, false) then
                local cur = GetAmmoInPedWeapon(ped, equippedWeapon.hash)
                TriggerServerEvent('cfw_inv:updateAmmo', equippedWeapon.slot, cur)
            end
        end
    end
end)

-- ===== أمان =====
AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    SetNuiFocus(false, false)
end)

-- أمر احتياطي
RegisterCommand('inv', function() openInv() end, false)