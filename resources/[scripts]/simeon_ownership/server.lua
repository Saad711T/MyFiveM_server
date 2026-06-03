local VEHICLES = {}
local OWNED = {}     -- [license] = { {model=.., label=..}, ... }
local BALANCE = {}   -- [license] = number
local OWNED_FILE = nil
local BALANCE_FILE = 'balances.json'

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

local function saveBalances()
    local ok, content = pcall(json.encode, BALANCE)
    if ok then
        SaveResourceFile(GetCurrentResourceName(), BALANCE_FILE, content, -1)
    end
end

local function loadBalances()
    local raw = LoadResourceFile(GetCurrentResourceName(), BALANCE_FILE)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then BALANCE = data end
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    loadVehicles()
    loadOwned()
    loadBalances()
    print(('^2[SO] Loaded %d vehicles^0'):format(#VEHICLES))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    saveOwned()
    saveBalances()
end)

-- ===== هوية اللاعب =====
local function getLicenseId(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1,8) == 'license:' then return id end
    end
    return nil
end

-- يضمن وجود رصيد ابتدائي للاعب
local function ensureBalance(license)
    if BALANCE[license] == nil then
        BALANCE[license] = (Config and Config.StartingBalance) or 0
    end
    return BALANCE[license]
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
    local bal = ensureBalance(license)
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

    -- تحقق الرصيد
    local bal = ensureBalance(license)
    if bal < (found.price or 0) then
        TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^1رصيدك غير كافٍ لشراء هذه السيارة'} })
        return
    end

    -- خصم + إضافة + حفظ
    BALANCE[license] = bal - found.price
    table.insert(OWNED[license], { model = found.model, label = found.label })
    saveOwned()
    saveBalances()

    TriggerClientEvent('chat:addMessage', src, { args={'Simeon', ('^2تم الشراء: %s مقابل $%s'):format(found.label, found.price)} })
    -- حدّث الواجهة فوراً بدون إغلاق
    TriggerClientEvent('so:updateShowroom', src, getOwnedModels(license), BALANCE[license])
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