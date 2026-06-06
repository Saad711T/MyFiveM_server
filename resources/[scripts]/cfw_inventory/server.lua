-- ============================================================
-- cfw_inventory — المرحلة 1: التخزين + المزامنة
-- يخزّن إنفنتوري كل لاعب في JSON بالـ license
-- ============================================================

local Inventories = {}  -- [license] = { [slot] = item, ... }
local dirty = false

-- ===== الحفظ والتحميل =====
local function save()
    local ok, content = pcall(json.encode, Inventories)
    if ok then
        SaveResourceFile(GetCurrentResourceName(), Config.SaveFile, content, -1)
        dirty = false
    end
end

local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.SaveFile)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then Inventories = data end
    end
end

-- ===== هوية اللاعب =====
local function getLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end

-- إنفنتوري ابتدائي للاعب جديد (عناصر تجريبية للاختبار)
local function startingInventory()
    return {
        ['0'] = { name = 'pistol', type = 'weapon', count = 1, ammo = 50, slot = 0 },
        ['1'] = { name = 'water',  type = 'food',   count = 3, slot = 1 },
        ['2'] = { name = 'bread',  type = 'food',   count = 2, slot = 2 },
        ['5'] = { name = 'money',  type = 'money',  count = 1000, slot = 5 },
    }
end

local function ensureInventory(license)
    if not Inventories[license] then
        Inventories[license] = startingInventory()
        dirty = true
    end
    return Inventories[license]
end

-- يبني بيانات كاملة للإرسال للواجهة (يدمج معلومات الـ config)
local function buildClientData(license, src)
    local inv = ensureInventory(license)
    local items = {}
    for slot, item in pairs(inv) do
        local cfg = Config.Items[item.name]
        local count = item.count or 1
        -- الفلوس: اقرأ القيمة الحقيقية من cfw_money (لو موجود)
        if item.name == 'money' and src and GetResourceState('cfw_money') == 'started' then
            local ok, cash = pcall(function() return exports.cfw_money:GetMoney(src, 'cash') end)
            if ok and cash then count = cash end
        end
        items[slot] = {
            name = item.name,
            label = cfg and cfg.label or item.name,
            type = item.type,
            count = count,
            ammo = item.ammo,
            slot = item.slot,
        }
    end
    return items
end

-- مزامنة الواجهة عند اللاعب
local function syncClient(src)
    local license = getLicense(src)
    if not license then return end
    TriggerClientEvent('cfw_inv:sync', src, buildClientData(license, src), Config.SlotCount)
end

-- ===== الأحداث =====
RegisterNetEvent('cfw_inv:requestSync', function()
    syncClient(source)
end)

-- نقل عنصر بين خليتين (سحب وإفلات)
RegisterNetEvent('cfw_inv:move', function(from, to)
    local src = source
    local license = getLicense(src)
    if not license then return end
    local inv = ensureInventory(license)
    local fromKey, toKey = tostring(from), tostring(to)

    local moving = inv[fromKey]
    if not moving then return end

    local target = inv[toKey]
    if target then
        -- تبديل: نفس النوع وقابل للتكديس؟ ادمج، وإلا بدّل
        if target.name == moving.name and Config.Items[moving.name] and Config.Items[moving.name].stackable then
            target.count = (target.count or 1) + (moving.count or 1)
            inv[fromKey] = nil
        else
            -- تبديل المكانين
            inv[toKey] = moving; moving.slot = to
            inv[fromKey] = target; target.slot = from
        end
    else
        -- خلية فاضية: انقل
        inv[toKey] = moving; moving.slot = to
        inv[fromKey] = nil
    end

    dirty = true
    syncClient(src)
end)

-- إسقاط/إتلاف عنصر
RegisterNetEvent('cfw_inv:drop', function(slot)
    local src = source
    local license = getLicense(src)
    if not license then return end
    local inv = ensureInventory(license)
    local key = tostring(slot)
    local item = inv[key]
    if not item then return end

    local cfg = Config.Items[item.name]

    -- الكاش: اخصمه بالكامل من cfw_money
    if item.name == 'money' and GetResourceState('cfw_money') == 'started' then
        pcall(function()
            local cash = exports.cfw_money:GetMoney(src, 'cash')
            if cash and cash > 0 then
                exports.cfw_money:RemoveMoney(src, 'cash', cash)
            end
        end)
    end

    -- السلاح: أزله من اللاعب فعلياً (خانة الأسلحة)
    if cfg and cfg.type == 'weapon' and cfg.weapon then
        TriggerClientEvent('cfw_inv:removeWeapon', src, cfg.weapon)
    end

    -- احذف العنصر واحفظ فوراً
    inv[key] = nil
    save()  -- حفظ فوري (مو ننتظر الخروج)
    syncClient(src)
end)

-- استخدام عنصر (السيرفر يتحقق ثم يأمر الكلاينت)
RegisterNetEvent('cfw_inv:use', function(slot)
    local src = source
    local license = getLicense(src)
    if not license then return end
    local inv = ensureInventory(license)
    local key = tostring(slot)
    local item = inv[key]
    if not item then return end

    local cfg = Config.Items[item.name]
    if not cfg then return end

    if cfg.type == 'food' then
        -- استخدام أكل/شرب: قلّل الكمية، أمر الكلاينت بالأنيميشن
        TriggerClientEvent('cfw_inv:doEat', src, item.name, cfg.heal or 0, cfg.drink or false)
        item.count = (item.count or 1) - 1
        if item.count <= 0 then inv[key] = nil end
        save()
        syncClient(src)
    elseif cfg.type == 'weapon' then
        -- تجهيز السلاح: أمر الكلاينت بإعطاء السلاح بالذخيرة المحفوظة
        TriggerClientEvent('cfw_inv:doEquipWeapon', src, cfg.weapon, item.ammo or cfg.maxAmmo or 0, slot)
    end
end)

-- تحديث ذخيرة سلاح (لما يرجّعه اللاعب للإنفنتوري)
RegisterNetEvent('cfw_inv:updateAmmo', function(slot, ammo)
    local src = source
    local license = getLicense(src)
    if not license then return end
    local inv = ensureInventory(license)
    local item = inv[tostring(slot)]
    if item and item.type == 'weapon' then
        item.ammo = ammo
        dirty = true
        syncClient(src)
    end
end)

-- ===== EXPORTS (لباقي المودات لاحقاً) =====
exports('GetInventory', function(src)
    local license = getLicense(src)
    if not license then return {} end
    return ensureInventory(license)
end)

-- ===== دورة الحياة =====
AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    load()
    print('^2[cfw_inventory] loaded^0')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    save()
end)

AddEventHandler('playerDropped', function()
    if dirty then save() end
end)

-- حفظ تلقائي كل دقيقتين
CreateThread(function()
    while true do
        Wait(120000)
        if dirty then save() end
    end
end)