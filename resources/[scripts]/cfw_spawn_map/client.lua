-- ============================================================
-- cfw_spawn_map — خريطة سبون تفاعلية (HTML/CSS/JS)
-- بكل دروس الاستقرار: تحكم spawnmanager، انتظار الأرض،
-- تحميل الموديل، إغلاق آمن، وريسبون افتراضي للشرطة عند الخطأ.
-- ============================================================

local menuOpen = false
local nuiReady = false

-- ===== مواقع السبون =====
local SPAWNS = {
  missionrow = vec4(428.10, -981.11, 30.71, 90.0),
  simeon     = vec4(-65.60, -1122.053, 19.42, 70.0),
  airport    = vec4(-1037.0, -2737.0, 13.76, 240.0),
  vespucci   = vec4(-1384.5, -1079.4, 4.23, 215.0),
  sandy      = vec4(1727.2, 3282.70, 34.27, 210.0),
  paleto     = vec4(-138.82, 6649.07, 37.98, 135.0),
}

-- الموقع الافتراضي الآمن (مركز الشرطة) — يُستخدم عند أي خطأ
local DEFAULT = SPAWNS.missionrow

-- ===== أدوات =====
local function ensureModel()
  local model = `mp_m_freemode_01`
  RequestModel(model)
  local tries = 0
  while not HasModelLoaded(model) and tries < 60 do Wait(50); tries = tries + 1 end
  if HasModelLoaded(model) then
    SetPlayerModel(PlayerId(), model)
    SetPedDefaultComponentVariation(PlayerPedId())
    SetModelAsNoLongerNeeded(model)
  end
end

-- تيليبورت آمن: ينتظر تحميل الأرض فعلياً (يمنع السقوط والتعليق)
local function safeTeleport(coord)
  local ped = PlayerPedId()

  DoScreenFadeOut(350)
  local t = 0
  while not IsScreenFadedOut() and t < 1500 do Wait(10); t = t + 10 end

  RequestCollisionAtCoord(coord.x, coord.y, coord.z)
  FreezeEntityPosition(ped, true)
  SetEntityCoords(ped, coord.x, coord.y, coord.z, false, false, false, true)
  SetEntityHeading(ped, coord.w)

  local waited = 0
  while not HasCollisionLoadedAroundEntity(ped) and waited < 8000 do
    RequestCollisionAtCoord(coord.x, coord.y, coord.z)
    Wait(50); waited = waited + 50
  end

  local ok, gz = GetGroundZFor_3dCoord(coord.x, coord.y, coord.z + 50.0, false)
  if ok and gz > 0.0 then
    SetEntityCoordsNoOffset(ped, coord.x, coord.y, gz + 0.2, false, false, false)
  end

  FreezeEntityPosition(ped, false)
end

-- يستعيد حالة اللاعب الطبيعية (يُستدعى دائماً بعد السبون)
local function restorePlayer()
  local ped = PlayerPedId()
  SetEntityVisible(ped, true, false)
  SetEntityInvincible(ped, false)
  SetPlayerControl(PlayerId(), true, 0)
  FreezeEntityPosition(ped, false)
  SetEntityCollision(ped, true, true)
  DisplayHud(true)
  DisplayRadar(true)
  TriggerScreenblurFadeOut(0.0)
  ShutdownLoadingScreen()
  ShutdownLoadingScreenNui()
  DoScreenFadeIn(500)
end

-- ينفّذ السبون في موقع معيّن (مع حماية shielded)
local function doSpawn(coord)
  coord = coord or DEFAULT
  pcall(ensureModel)
  pcall(safeTeleport, coord)
  pcall(restorePlayer)
  -- ضمان نهائي: مهما صار، فك الـ focus والتجميد
  SetNuiFocus(false, false)
  FreezeEntityPosition(PlayerPedId(), false)
end

-- ===== فتح/إغلاق الواجهة =====
local function openMenu()
  if menuOpen then return end
  menuOpen = true

  ShutdownLoadingScreen()
  ShutdownLoadingScreenNui()

  -- جمّد اللاعب وأخفه أثناء الاختيار
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, true)
  SetEntityInvincible(ped, true)
  SetEntityVisible(ped, false, false)
  DoScreenFadeIn(400)

  -- انتظر حتى تجهز الواجهة فعلياً قبل إعطاء focus (يمنع التعليق على صفحة فاضية)
  local waited = 0
  while not nuiReady and waited < 5000 do Wait(50); waited = waited + 50 end

  SetNuiFocus(true, true)
  SendNUIMessage({ action = 'open' })

  -- ⏱️ أمان: لو ما تفاعل اللاعب خلال 45 ثانية، يسبون تلقائي للشرطة
  CreateThread(function()
    local elapsed = 0
    while menuOpen and elapsed < 45000 do
      Wait(1000); elapsed = elapsed + 1000
    end
    if menuOpen then
      menuOpen = false
      SetNuiFocus(false, false)
      SendNUIMessage({ action = 'close' })
      doSpawn(DEFAULT)
    end
  end)
end

local function closeMenuUI()
  menuOpen = false
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'close' })
end

-- الـ NUI أبلغ إنه جاهز (الصفحة والصورة تحمّلوا)
RegisterNUICallback('nuiReady', function(_, cb)
  cb({ ok = true })
  nuiReady = true
end)

-- اللاعب اختار نقطة
RegisterNUICallback('choose', function(data, cb)
  cb({ ok = true })
  local id = data and data.id
  local coord = (id and SPAWNS[id]) or DEFAULT
  closeMenuUI()
  CreateThread(function()
    doSpawn(coord)
  end)
end)

-- إغلاق طوارئ (زر X أو ESC): يسبون افتراضي للشرطة
RegisterNUICallback('forceClose', function(_, cb)
  cb({ ok = true })
  closeMenuUI()
  CreateThread(function()
    doSpawn(DEFAULT)
  end)
end)

-- ===== التحكم في spawnmanager (يمنع الريسبون العشوائي) =====
CreateThread(function()
  while GetResourceState('spawnmanager') ~= 'started' do Wait(100) end

  exports.spawnmanager:setAutoSpawn(false)
  exports.spawnmanager:setAutoSpawnCallback(function()
    -- spawn فعلي مؤقت (مخفي) ثم افتح الخريطة
    exports.spawnmanager:spawnPlayer({
      x = DEFAULT.x, y = DEFAULT.y, z = DEFAULT.z,
      heading = DEFAULT.w, model = 'mp_m_freemode_01', skipFade = false
    }, function()
      openMenu()
    end)
  end)
  exports.spawnmanager:setAutoSpawn(true)
  Wait(300)
  exports.spawnmanager:forceRespawn()

  print('^2[cfw_spawn_map] loaded^0')
end)

-- افتح الخريطة عند الموت كذلك
AddEventHandler('baseevents:onPlayerDied', function()
  CreateThread(function()
    Wait(3000)
    openMenu()
  end)
end)

-- أمر يدوي للطوارئ
RegisterCommand('spawnmap', function() openMenu() end, false)

-- 🆘 أمر إنقاذ: يفك التعليق فوراً ويسبون للشرطة (اكتبه في F8 لو علقت)
RegisterCommand('unstuck', function()
  menuOpen = false
  SetNuiFocus(false, false)
  SendNUIMessage({ action = 'close' })
  CreateThread(function()
    doSpawn(DEFAULT)
  end)
  print('^2[cfw_spawn_map] unstuck -> spawned at PD^0')
end, false)

-- ===== أمان: لو المود توقف والواجهة مفتوحة، رجّع كل شي =====
AddEventHandler('onResourceStop', function(res)
  if res ~= GetCurrentResourceName() then return end
  SetNuiFocus(false, false)
  restorePlayer()
end)