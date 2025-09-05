local FIRST_JUST_FINISHED = false

-- Arrivals curb (lower level) – safe sidewalk on the street
local airportArrivals = { x = -892.35, y = -2314.23, z = 14.05, h = 60.0 }




local function tpSafe(x,y,z,h)
  local ped = PlayerPedId()
  RequestCollisionAtCoord(x,y,z)
  SetEntityCoords(ped, x,y,z, false,false,false,true)
  if h then SetEntityHeading(ped,h) end
  local ok, gz = GetGroundZFor_3dCoord(x,y,z+50.0,false)
  if ok then SetEntityCoordsNoOffset(ped, x,y,gz+0.2, false,false,false) end
end

-- Force freemode before opening editor (GTAO-style)
local function ensureFreemode()
  local model = `mp_m_freemode_01` -- default male; اللاعب يقدر يغيّر للـ female من داخل الواجهة
  RequestModel(model); while not HasModelLoaded(model) do Wait(0) end
  SetPlayerModel(PlayerId(), model)
  SetPedDefaultComponentVariation(PlayerPedId())
  SetModelAsNoLongerNeeded(model)
end

-- Open appearance WITHOUT teleporting (keeps current position)
local function openAppearance()
  ensureFreemode()
  if exports['fivem-appearance'] then
    exports['fivem-appearance']:startPlayerCustomization(function(appearance)
      if appearance then
        exports['fivem-appearance']:setPlayerAppearance(appearance)

        TriggerServerEvent('cfwchar:save', json.encode(appearance))
        FIRST_JUST_FINISHED = true 
        

      end
    end, {
      ped = true, headBlend = true, faceFeatures = true,
      headOverlays = true, components = true, props = true,
      tattoos = true, allowExit = true
    })
  else
    print('^1fivem-appearance not found or not started.^0')
  end
end


CreateThread(function()
  Wait(1500)
  tpSafe(airportArrivals.x, airportArrivals.y, airportArrivals.z, airportArrivals.h)
  openAppearance()
end)


AddEventHandler('playerSpawned', function()
  if FIRST_JUST_FINISHED then

    FIRST_JUST_FINISHED = false
    return
  end


  tpSafe(airportArrivals.x, airportArrivals.y, airportArrivals.z, airportArrivals.h)
end)




RegisterCommand('customization', function()
  openAppearance()
end)
