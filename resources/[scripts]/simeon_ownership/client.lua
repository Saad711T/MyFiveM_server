local nearSimeon = false
local nearPD = false
local showroomOpen = false

local function help(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- ===== Safe spawn helpers =====
local function findGroundZ(x, y, zDefault)
    local found, z = GetGroundZFor_3dCoord(x + 0.0, y + 0.0, zDefault or 1000.0, false)
    return found and z or (zDefault or 30.0)
end

local function isAreaClear(pos, radius)
    return not IsAnyVehicleNearPoint(pos.x, pos.y, pos.z, radius or 3.0)
end

local function trySpawnPointAround(origin, baseDist)
    local attempts = 12
    local step = 4.0
    local start = baseDist or 8.0

    for r = start, start + (attempts - 1) * step, step do
        for a = 0, 330, 30 do
            local rad = math.rad(a)
            local x = origin.x + math.cos(rad) * r
            local y = origin.y + math.sin(rad) * r
            local z = findGroundZ(x, y, origin.z + 2.0)

            if IsPointOnRoad(x, y, z, 0) and isAreaClear(vector3(x, y, z), 3.0) then
                local heading = GetHeadingFromVector_2d(origin.x - x, origin.y - y)
                return vector3(x, y, z + 0.2), heading
            end
        end
    end

    return origin, Config.PDSpawnHeading or 0.0
end
-- ===================================

-- ===== Map Blips =====
CreateThread(function()
    for _, b in ipairs(Config.Blips or {}) do
        local blip = AddBlipForCoord(b.pos.x, b.pos.y, b.pos.z)
        SetBlipSprite(blip, b.sprite or 1)
        SetBlipColour(blip, b.color or 0)
        SetBlipScale(blip, b.scale or 0.9)
        SetBlipAsShortRange(blip, true)
        BeginTextCommandSetBlipName('STRING')
        AddTextComponentSubstringPlayerName(b.label or 'Blip')
        EndTextCommandSetBlipName(blip)
    end
end)
-- =====================

-- Draw markers + proximity detection
CreateThread(function()
    while true do
        local sleep = 1000
        local ped = PlayerPedId()
        local pcoords = GetEntityCoords(ped)

        -- Simeon
        local d1 = #(pcoords - Config.Simeon)
        if d1 < 25.0 then
            sleep = 0
            DrawMarker(1, Config.Simeon.x, Config.Simeon.y, Config.Simeon.z-1.0, 0.0,0.0,0.0, 0.0,0.0,0.0, 1.5,1.5,0.5, 0,150,255, 180, false,true,2,false,nil,nil,false)
        end
        nearSimeon = (d1 <= Config.InteractDist)

        -- Police station
        local d2 = #(pcoords - Config.PDSpawn)
        if d2 < 25.0 then
            sleep = 0
            DrawMarker(36, Config.PDSpawn.x, Config.PDSpawn.y, Config.PDSpawn.z, 0,0,0, 0,0,0, 0.8,0.8,0.8, 0,255,100, 180, false,true,2,false,nil,nil,false)
        end
        nearPD = (d2 <= Config.InteractDist)

        Wait(sleep)
    end
end)

-- Interaction prompts
CreateThread(function()
    while true do
        Wait(0)
        if showroomOpen then
            Wait(200)
        elseif nearSimeon then
            help("~INPUT_CONTEXT~ Open Simeon showroom")
            if IsControlJustReleased(0, Config.KeyInteract) then
                TriggerServerEvent('so:requestShowroom')
            end
        elseif nearPD then
            help("~INPUT_CONTEXT~ Open your garage (spawn cars)")
            if IsControlJustReleased(0, Config.KeyInteract) then
                TriggerServerEvent('so:requestOwned')
            end
        end
    end
end)

-- ===== Showroom NUI =====
RegisterNetEvent('so:showShowroom')
AddEventHandler('so:showShowroom', function(vehicles, owned, balance)
    showroomOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action   = 'open',
        vehicles = vehicles,
        owned    = owned or {},
        balance  = balance or 0
    })
end)

-- اللاعب ضغط Buy في الواجهة
RegisterNUICallback('buy', function(data, cb)
    cb({ ok = true })
    if data and data.model then
        TriggerServerEvent('so:tryBuyVehicle', data.model)
    end
end)

-- اللاعب أغلق الواجهة
RegisterNUICallback('close', function(_, cb)
    cb({ ok = true })
    showroomOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
end)

-- تحديث الواجهة بعد الشراء (بدون إغلاق)
RegisterNetEvent('so:updateShowroom')
AddEventHandler('so:updateShowroom', function(owned, balance)
    SendNUIMessage({
        action  = 'update',
        owned   = owned or {},
        balance = balance or 0
    })
end)

-- ===== Owned cars: garage with spawn-location picker =====
RegisterNetEvent('so:receiveOwned')
AddEventHandler('so:receiveOwned', function(list)
    if not nearPD then
        TriggerEvent('chat:addMessage', { args={'Garage','^1Go to the police station to view your cars'} })
        return
    end
    if #list == 0 then
        TriggerEvent('chat:addMessage', { args={'Garage','^3You do not own any cars'} })
        return
    end
    TriggerEvent('chat:addMessage', { args={'Garage','^5Your owned cars:'} })
    for i, v in ipairs(list) do
        TriggerEvent('chat:addMessage', { args={'Garage', ('^2[%d]^7 %s (^3%s^7)'):format(i, v.label, v.model)} })
    end
    -- اعرض أماكن الريسبون المتاحة
    local spots = {}
    for _, sp in ipairs(Config.SpawnPoints or {}) do
        spots[#spots+1] = sp.id
    end
    TriggerEvent('chat:addMessage', { args={'Garage','^7Spawn locations: ^2' .. table.concat(spots, ', ')} })
    TriggerEvent('chat:addMessage', { args={'Garage','^7Use: ^2/spawncar <model> [location]^7  (location optional, default = pd)'} })
end)

RegisterCommand('spawncar', function(_, args)
    if not nearPD then
        TriggerEvent('chat:addMessage', { args={'Garage','^1You must be at the police station to spawn cars'} })
        return
    end
    local model = args[1]
    if not model then
        TriggerEvent('chat:addMessage', { args={'Garage','^1Usage: /spawncar <model> [location]'} })
        return
    end
    local locId = args[2] or 'pd'
    TriggerServerEvent('so:spawnOwned', model, locId)
end)

-- اطلب من السيرفر التحقق ثم اطلع السيارة في الموقع المختار
RegisterNetEvent('so:doClientSpawn')
AddEventHandler('so:doClientSpawn', function(model, locId)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        TriggerEvent('chat:addMessage', { args={'Garage','^1Invalid model in this Game Build'} })
        return
    end

    -- حدد الموقع المطلوب
    local origin = Config.PDSpawn
    local baseHeading = Config.PDSpawnHeading or 0.0
    for _, sp in ipairs(Config.SpawnPoints or {}) do
        if sp.id == locId then
            origin = vector3(sp.pos.x, sp.pos.y, sp.pos.z)
            baseHeading = sp.pos.w
            break
        end
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local spawnPos, spawnHead = trySpawnPointAround(origin, 8.0)
    local veh = CreateVehicle(hash, spawnPos.x, spawnPos.y, spawnPos.z, (spawnHead or baseHeading or 0.0), true, false)

    SetVehicleOnGroundProperly(veh)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetVehicleNumberPlateText(veh, "OWNED")
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(hash)
end)