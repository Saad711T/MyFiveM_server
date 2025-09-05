local VEHICLES = {}
local OWNED = {}  -- [license] = { {model=.., label=..}, ... }
local OWNED_FILE = nil

-- تحميل ملف JSON من داخل الريسورس
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
    else
        print('^1[SO] FAILED to encode owned data^0')
    end
end

local function loadOwned()
    OWNED_FILE = Config and Config.OwnedFileName or 'owned_vehicles.json'
    local raw = LoadResourceFile(GetCurrentResourceName(), OWNED_FILE)
    if raw then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then
            OWNED = data
        end
    end
end

AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    loadVehicles()
    loadOwned()
    print(('^2[SO] Loaded %d vehicles; owned entries: %d^0'):format(#VEHICLES, (OWNED and #OWNED) or 0))
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    saveOwned()
end)

-- جلب معرف اللاعب license: من identifiers
local function getLicenseId(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1,8) == 'license:' then
            return id
        end
    end
    return nil
end

-- إعطاء قائمة المعرض للكلنت
RegisterNetEvent('so:requestShowroom')
AddEventHandler('so:requestShowroom', function()
    local src = source
    TriggerClientEvent('so:showShowroom', src, VEHICLES)
end)

-- محاولة شراء سيارة
RegisterNetEvent('so:tryBuyVehicle')
AddEventHandler('so:tryBuyVehicle', function(model)
    local src = source
    local license = getLicenseId(src)
    if not license then
        TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^1تعذر تحديد هوية اللاعب (license)'} })
        return
    end

    local found
    for _, v in ipairs(VEHICLES) do
        if v.model:lower() == tostring(model):lower() then
            found = v
            break
        end
    end

    if not found then
        TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^1الموديل غير موجود في المعرض'} })
        return
    end

    OWNED[license] = OWNED[license] or {}
    -- منع التكرار بنفس الموديل (اختياري)
    for _, ov in ipairs(OWNED[license]) do
        if ov.model == found.model then
            TriggerClientEvent('chat:addMessage', src, { args={'Simeon', '^3أنت تمتلك هذه السيارة بالفعل'} })
            return
        end
    end

    table.insert(OWNED[license], { model = found.model, label = found.label })
    saveOwned()
    TriggerClientEvent('chat:addMessage', src, { args={'Simeon', ('^2تم الشراء: %s مقابل $%s'):format(found.label, found.price)} })
end)

-- إرسال السيارات المملوكة للاعب
RegisterNetEvent('so:requestOwned')
AddEventHandler('so:requestOwned', function()
    local src = source
    local license = getLicenseId(src)
    local list = OWNED[license] or {}
    TriggerClientEvent('so:receiveOwned', src, list)
end)

-- تحقق من الملكية ثم اطلب من الكلينت الرسبنة
RegisterNetEvent('so:spawnOwned')
AddEventHandler('so:spawnOwned', function(model, coords, heading)
    local src = source
    local license = getLicenseId(src)
    local list = OWNED[license] or {}
    local ok = false
    for _, v in ipairs(list) do
        if v.model:lower() == tostring(model):lower() then
            ok = true
            break
        end
    end
    if not ok then
        TriggerClientEvent('chat:addMessage', src, { args={'PD Garage', '^1هذه السيارة غير مملوكة لك'} })
        return
    end
    TriggerClientEvent('so:doClientSpawn', src, model, coords, heading)
end)
