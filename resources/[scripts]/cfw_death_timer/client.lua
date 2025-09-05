-- CFW: downed timer + revive + auto hospital respawn

local DOWN_TIME = 60         -- ثواني
local isDown = false
local downEndsAt = 0
local lastPos = nil

-- Pillbox Hospital
local HOSPITAL = { x = 298.47, y = -584.73, z = 43.26, h = 70.0 }





local function drawHelp(text)
  SetTextFont(4); SetTextScale(0.45, 0.45)
  SetTextColour(255,255,255,220)
  SetTextOutline()
  SetTextCentre(true)
  BeginTextCommandDisplayText("STRING")
  AddTextComponentSubstringPlayerName(text)
  EndTextCommandDisplayText(0.5, 0.90)
end

local function disableControlsWhileDown()
  DisableAllControlActions(0)
  EnableControlAction(0, 245, true) -- T chat
  EnableControlAction(0, 249, true) -- N push-to-talk
end

local function resurrectHere()
  local ped = PlayerPedId()
  local coords = GetEntityCoords(ped)
  NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, GetEntityHeading(ped), true, true, false)
  ClearPedBloodDamage(ped)
  SetEntityHealth(ped, 200)
  ClearPedTasksImmediately(ped)
end

local function reviveAtHospital()
  local ped = PlayerPedId()
  NetworkResurrectLocalPlayer(HOSPITAL.x, HOSPITAL.y, HOSPITAL.z, HOSPITAL.h, true, true, false)
  ClearPedBloodDamage(ped)
  SetEntityHealth(ped, 200)
  ClearPedTasksImmediately(ped)
end


RegisterNetEvent('cfw:clientRevive')
AddEventHandler('cfw:clientRevive', function()
  isDown = false
  downEndsAt = 0
  resurrectHere()
end)


AddEventHandler('baseevents:onPlayerDied', function(killerType, deathCoords)
  if isDown then return end
  isDown = true
  downEndsAt = GetGameTimer() + (DOWN_TIME * 1000)
  lastPos = GetEntityCoords(PlayerPedId())

  CreateThread(function()
    DoScreenFadeIn(500)
    while isDown do
      Wait(0)
      disableControlsWhileDown()

      local remaining = math.max(0, math.ceil((downEndsAt - GetGameTimer())/1000))
      drawHelp(("~r~You are downed~s~. EMS can revive you.\nAuto-respawn in ~y~%ds~s~."):format(remaining))


      if GetGameTimer() >= downEndsAt then
        isDown = false
        reviveAtHospital()
      end
    end
  end)
end)




AddEventHandler('baseevents:onPlayerKilled', function(killerId, weaponHash, deathCoords)
  TriggerEvent('baseevents:onPlayerDied', 0, deathCoords)
end)
