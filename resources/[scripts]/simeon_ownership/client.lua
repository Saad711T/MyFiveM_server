
local nearSimeon = false
local nearPD = false

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

-- Draw markers
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






CreateThread(function()
    while true do
        Wait(0)
        if nearSimeon then
            help("~INPUT_CONTEXT~ Open Simeon showroom")
            if IsControlJustReleased(0, Config.KeyInteract) then
                TriggerServerEvent('so:requestShowroom')
            end
        elseif nearPD then
            help("~INPUT_CONTEXT~ Show your owned cars (spawn here)")
            if IsControlJustReleased(0, Config.KeyInteract) then
                TriggerServerEvent('so:requestOwned')
            end
        end
    end
end)

-- Show showroom list
RegisterNetEvent('so:showShowroom')
AddEventHandler('so:showShowroom', function(list)
    TriggerEvent('chat:addMessage', { args = { 'Simeon', '^5Available cars for purchase:' } })
    for i, v in ipairs(list) do
        TriggerEvent('chat:addMessage', { args = { 'Simeon',
            ('^3%s^7 | model: ^2%s^7 | Price: ^2$%s'):format(v.label, v.model, v.price) } })
    end
    TriggerEvent('chat:addMessage', { args = { 'Simeon',
        '^7Use: ^2/buycar <model> ^7while inside the showroom area' } })
end)

-- Buy  command
RegisterCommand('buycar', function(_, args)
    if not nearSimeon then
        TriggerEvent('chat:addMessage', { args={'Simeon','^1You must be inside Simeon showroom area'} })
        return
    end
    local model = args[1]
    if not model then
        TriggerEvent('chat:addMessage', { args={'Simeon','^1Usage: /buycar <model>'} })
        return
    end
    TriggerServerEvent('so:tryBuyVehicle', model)
end)


RegisterNetEvent('so:receiveOwned')
AddEventHandler('so:receiveOwned', function(list)
    if not nearPD then
        TriggerEvent('chat:addMessage', { args={'PD Garage','^1Go to the police station to view your cars'} })
        return
    end
    if #list == 0 then
        TriggerEvent('chat:addMessage', { args={'PD Garage','^3You do not own any cars'} })
        return
    end
    TriggerEvent('chat:addMessage', { args={'PD Garage','^5Your owned cars:'} })
    for i, v in ipairs(list) do
        TriggerEvent('chat:addMessage', { args={'PD Garage', ('^2[%d]^7 %s (^3%s^7)'):format(i, v.label, v.model)} })
    end
    TriggerEvent('chat:addMessage', { args={'PD Garage','^7Use: ^2/spawncar <model> ^7to spawn your car'} })
end)


RegisterCommand('spawncar', function(_, args)
    if not nearPD then
        TriggerEvent('chat:addMessage', { args={'PD Garage','^1You must be at the police station to spawn cars'} })
        return
    end
    local model = args[1]
    if not model then
        TriggerEvent('chat:addMessage', { args={'PD Garage','^1Usage: /spawncar <model>'} })
        return
    end
    TriggerServerEvent('so:spawnOwned', model, Config.PDSpawn, Config.PDSpawnHeading)
end)





RegisterNetEvent('so:doClientSpawn')




AddEventHandler('so:doClientSpawn', function(model, coords, heading)
    local hash = GetHashKey(model)
    if not IsModelInCdimage(hash) then
        TriggerEvent('chat:addMessage', { args={'PD Garage','^1Invalid model in this Game Build'} })
        return
    end

    RequestModel(hash)
    while not HasModelLoaded(hash) do Wait(0) end

    local origin = coords or Config.PDSpawn
    local spawnPos, spawnHead = trySpawnPointAround(origin, 8.0)
    local veh = CreateVehicle(hash, spawnPos.x, spawnPos.y, spawnPos.z, (spawnHead or heading or Config.PDSpawnHeading or 0.0), true, false)

    SetVehicleOnGroundProperly(veh)
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetVehicleNumberPlateText(veh, "OWNED")
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(hash)


    
end)
