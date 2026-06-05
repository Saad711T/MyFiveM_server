local VEHICLES = {}
local OWNED = {}     -- [license] = { {model=.., label=..}, ... }
local OWNED_FILE = nil

-- ===== تحميل الملفات =====
local function loadVehicles()
    local vjson = LoadResourceFile(GetCurrentResourceName(), 'vehicles.json')
    if vjson then
        local ok, data = pcall(json.decode, vjson)
        if ok and data and data.vehicles then
            VEHICLES = data.vehicles
        else
            print('^1[SO] vehicles.json parsing failed^0')
        end
    else
        print('^1[SO] vehicles.json not found^0')
    end
end

local function saveOwned()
    if not OWNED_FILE then return end
    local ok, content = pcall(json.encode, OWNED)
    if ok then
        SaveResourceFile(GetCurrentResourceName(), OWNED_FILE, content, -1)
    end
end

local function loadOwned()
    OWNED_FILE = Config and Config.OwnedFileName or 'owned_vehicles.json'
    local raw = LoadResourceFile(GetCurrentResourceName(), OWNED_FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then OWNED = data end
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    loadVehicles()
    loadOwned()
    print(('^2[SO] Loaded %d vehicles^0'):format(#VEHICLES))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    saveOwned()
end)

-- ===== هوية اللاعب =====
local function getLicenseId(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1,8) == 'license:' then return id end
    end
    return nil
end

-- يرجّع قائمة موديلات يملكها اللاعب (للواجهة)
local function getOwnedModels(license)
    local models = {}
    for _, ov in ipairs(OWNED[license] or {}) do
        models[#models+1] = ov.model
    end
    return models
end

-- ===== فتح المعرض =====
RegisterNetEvent('so:requestShowroom')
AddEventHandler('so:requestShowroom', function()
    local src = source
    local license = getLicenseId(src)
    if not license then return end
    -- الرصيد من النظام الموحّد cfw_money (نستخدم البنك للسيارات)
    local bal = exports.cfw_money:GetMoney(src, 'bank')
    TriggerClientEvent('so:showShowroom', src, VEHICLES, getOwnedModels(license), bal)
end)

-- ===== شراء سيارة =====
RegisterNetEvent('so:tryBuyVehicle')
AddEventHandler('so:tryBuyVehicle', function(model)
    local src = source
    local license = getLicenseId(src)
    if not license then
        TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^1تعذر تحديد هوية اللاعب'} })
        return
    end

    local found
    for _, v in ipairs(VEHICLES) do
        if v.model:lower() == tostring(model):lower() then found = v; break end
    end
    if not found then
        TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^1الموديل غير موجود في المعرض'} })
        return
    end

    OWNED[license] = OWNED[license] or {}
    for _, ov in ipairs(OWNED[license]) do
        if ov.model == found.model then
            TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^3أنت تمتلك هذه السيارة بالفعل'} })
            return
        end
    end

    -- تحقق الرصيد والخصم عبر النظام الموحّد cfw_money (من البنك)
    if not exports.cfw_money:CanAfford(src, 'bank', found.price or 0) then
        TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^1رصيدك غير كافٍ لشراء هذه السيارة'} })
        return
    end

    -- خصم الفلوس (لو فشل لأي سبب، أوقف)
    if not exports.cfw_money:RemoveMoney(src, 'bank', found.price or 0) then
        TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^1فشل خصم المبلغ'} })
        return
    end

    -- أضف السيارة + احفظ الملكية
    table.insert(OWNED[license], { model = found.model, label = found.label })
    saveOwned()

    local newBal = exports.cfw_money:GetMoney(src, 'bank')
    TriggerClientEvent('chat:addMessage', src, { args={'Simeon', ('^2تم الشراء: %s مقابل $%s'):format(found.label, found.price)} })
    -- حدّث الواجهة فوراً بدون إغلاق
    TriggerClientEvent('so:updateShowroom', src, getOwnedModels(license), newBal)
end)

-- ===== جلب السيارات المملوكة =====
RegisterNetEvent('so:requestOwned')
AddEventHandler('so:requestOwned', function()
    local src = source
    local license = getLicenseId(src)
    TriggerClientEvent('so:receiveOwned', src, OWNED[license] or {})
end)

-- ===== التحقق من الملكية ثم الريسبون في الموقع المختار =====
RegisterNetEvent('so:spawnOwned')
AddEventHandler('so:spawnOwned', function(model, locId)
    local src = source
    local license = getLicenseId(src)
    local ok = false
    for _, v in ipairs(OWNED[license] or {}) do
        if v.model:lower() == tostring(model):lower() then ok = true; break end
    end
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { args={'Garage', '^1هذه السيارة غير مملوكة لك'} })
        return
    end
    TriggerClientEvent('so:doClientSpawn', src, model, locId)
end)
