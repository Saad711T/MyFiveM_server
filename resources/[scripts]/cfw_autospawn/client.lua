local SPAWN = { x = 428.10, y = -981.11, z = 30.71, heading = 90.0 }


local function safeTeleport(x, y, z, h)
    local ped = PlayerPedId()
    DoScreenFadeOut(300)
    local t = 0
    while not IsScreenFadedOut() and t < 1500 do Wait(10); t = t + 10 end

    RequestCollisionAtCoord(x, y, z)
    FreezeEntityPosition(ped, true)
    SetEntityCoords(ped, x, y, z, false, false, false, true)
    SetEntityHeading(ped, h)

    local waited = 0
    while not HasCollisionLoadedAroundEntity(ped) and waited < 8000 do
        RequestCollisionAtCoord(x, y, z)
        Wait(50); waited = waited + 50
    end



    local ok, gz = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    if ok and gz > 0.0 then
        SetEntityCoordsNoOffset(ped, x, y, gz + 0.2, false, false, false)
    end

    FreezeEntityPosition(ped, false)
    DoScreenFadeIn(500)
end


local function ensureModel()
    local model = `mp_m_freemode_01`
    RequestModel(model)
    local tries = 0
    while not HasModelLoaded(model) and tries < 50 do Wait(50); tries = tries + 1 end
    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(model)
end

-- التحكم في spawnmanager
CreateThread(function()
    while GetResourceState('spawnmanager') ~= 'started' do Wait(100) end

    exports.spawnmanager:setAutoSpawn(false)

    exports.spawnmanager:setAutoSpawnCallback(function()
        print('^2[cfw_autospawn] spawning at police station^0')
        exports.spawnmanager:spawnPlayer({
            x = SPAWN.x, y = SPAWN.y, z = SPAWN.z,
            heading = SPAWN.heading,
            model = 'mp_m_freemode_01',
            skipFade = false
        }, function()
            ensureModel()

            local ped = PlayerPedId()
            local ok, gz = GetGroundZFor_3dCoord(SPAWN.x, SPAWN.y, SPAWN.z + 50.0, false)
            if ok and gz > 0.0 then
                SetEntityCoordsNoOffset(ped, SPAWN.x, SPAWN.y, gz + 0.2, false, false, false)
            end
            SetEntityHeading(ped, SPAWN.heading)
        end)
    end)

    exports.spawnmanager:setAutoSpawn(true)
    Wait(300)
    exports.spawnmanager:forceRespawn()

    print('^2[cfw_autospawn] loaded — auto-spawn at Mission Row PD^0')
end)




RegisterCommand('pd', function()
    safeTeleport(SPAWN.x, SPAWN.y, SPAWN.z, SPAWN.heading)
end, false)