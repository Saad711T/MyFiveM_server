local shownThisSession, menuOpen = false, false

local SPAWNS = {
  missionrow = { label = "Mission Row PD",        pos = vec4(428.10, -981.11, 30.71, 90.0) },
  pillbox    = { label = "Pillbox Hill Hospital", pos = vec4(298.47, -584.73, 43.26, 70.0) },
  ulsa       = { label = "ULSA (University)",      pos = vec4(-1694.00, -292.00, 51.88, 210.0) },
  simeon     = { label = "Simeon's PDM",          pos = vec4(-47.16, -1095.12, 26.42, 70.0) },
  sandypd    = { label = "Sandy Shores Sheriff",  pos = vec4(1853.20, 3686.90, 34.27, 210.0) },
  paleto_clo = { label = "Paleto Clothing",       pos = vec4(-138.82, 6649.07, 37.98, 135.0) },
}

local function tpSafe(x,y,z,h)
  local ped = PlayerPedId()
  RequestCollisionAtCoord(x,y,z)
  SetEntityCoords(ped, x,y,z, false,false,false,true)
  if h then SetEntityHeading(ped, h) end
  local ok, gz = GetGroundZFor_3dCoord(x,y,z+50.0,false)
  if ok and gz > 0.0 then SetEntityCoordsNoOffset(ped, x,y,gz+0.2, false,false,false) end
end

local function setFrozen(flag)
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, flag)
  SetEntityInvincible(ped, flag)
  SetPedCanRagdoll(ped, not flag)
  SetEntityCollision(ped, not flag, not flag)
  SetEntityVisible(ped, not flag, false)
end

local function blockControlsLoop()
  CreateThread(function()
    while menuOpen do
      Wait(0)
      DisableAllControlActions(0)
      EnableControlAction(0, 245, true) -- T chat
      EnableControlAction(0, 249, true) -- N voice
    end
  end)
end

local function sendOpen()
  local opts = {
    { id="missionrow", label=SPAWNS.missionrow.label },
    { id="pillbox",    label=SPAWNS.pillbox.label    },
    { id="ulsa",       label=SPAWNS.ulsa.label       },
    { id="simeon",     label=SPAWNS.simeon.label     },
    { id="sandypd",    label=SPAWNS.sandypd.label    },
    { id="paleto_clo", label=SPAWNS.paleto_clo.label },
  }
  SendNUIMessage({ action = "open", options = opts })
end

local function openSpawnMenu()
  if menuOpen then return end
  menuOpen = true
  setFrozen(true)
  SetNuiFocus(true, true)
  Wait(100)          -- امنح الـNUI وقتًا ليجهز
  sendOpen()
  blockControlsLoop()

  -- Watchdog: أعِد إرسال open كل 1ث طالما القائمة مفتوحة (لو علقّت الرسالة الأولى)
  CreateThread(function()
    while menuOpen do
      Wait(1000)
      SendNUIMessage({ action = "poke" }) -- غير مؤذية
      sendOpen()
    end
  end)
end

-- اختيار من الواجهة
RegisterNUICallback('chooseSpawn', function(data, cb)
  local id = data and data.id
  cb({ ok = id ~= nil })
  if not id or not SPAWNS[id] then return end

  local p = SPAWNS[id].pos
  tpSafe(p.x, p.y, p.z, p.w)

  -- أغلق الواجهة
  SendNUIMessage({ action = "close" })
  SetNuiFocus(false, false)
  menuOpen = false

  -- استرجع كل شيء طبيعي
  CreateThread(function()
    local ped = PlayerPedId()
    SetEntityVisible(ped, true, false)
    SetEntityInvincible(ped, false)
    SetPedCanRagdoll(ped, true)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    DisplayHud(true); DisplayRadar(true)
    ShutdownLoadingScreen(); ShutdownLoadingScreenNui()
    TriggerScreenblurFadeOut(0)
    if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(300) end
  end)
end)

RegisterNUICallback('noClose', function(_, cb) cb({}) end)

-- افتح القائمة أول مرّة في الجلسة
AddEventHandler('playerSpawned', function()
  if shownThisSession then return end
  shownThisSession = true
  CreateThread(function()
    Wait(600)
    openSpawnMenu()
  end)
end)

-- أمر طوارئ
RegisterCommand('spawnmenu', function() openSpawnMenu() end)
