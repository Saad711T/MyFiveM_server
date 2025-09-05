
local lastJSON = nil

local function msg(t) TriggerEvent('chat:addMessage', { args={'CFW', t} }) end

local function ensureFreemodeMale()
  local m = `mp_m_freemode_01`
  RequestModel(m) while not HasModelLoaded(m) do Wait(0) end
  SetPlayerModel(PlayerId(), m)
  SetPedDefaultComponentVariation(PlayerPedId())
  SetModelAsNoLongerNeeded(m)
end

-- ====== NORMALIZE + FIX ======
local function clampNonNeg(v)
  v = tonumber(v or 0) or 0
  if v < 0 then v = 0 end
  return math.floor(v)
end

local function normalizeAppearance(app)
  if not app then return end

  app.hair = app.hair or {}
  local h = app.hair
  h.style     = h.style     or h.drawable or 0
  h.texture   = h.texture   or h.tex or 0
  h.color     = clampNonNeg(h.color or h.primaryColor or h.colour)
  h.highlight = clampNonNeg(h.highlight or h.secondaryColor or h.highlightColor)



  app.headOverlays = app.headOverlays or app.overlays or app.overlay or {}
  local ov = app.headOverlays

  ov.beard = ov.beard or ov["1"] or ov.Beard
  if ov.beard then
    ov.beard.index   = ov.beard.index   or ov.beard.style or 0
    ov.beard.opacity = (ov.beard.opacity and ov.beard.opacity > 0) and ov.beard.opacity or 1.0
    ov.beard.color   = clampNonNeg(ov.beard.color or ov.beard.primaryColor)
    ov["1"] = ov.beard

  end

  ov.eyebrows = ov.eyebrows or ov["2"] or ov.Eyebrows
  if ov.eyebrows then
    ov.eyebrows.index   = ov.eyebrows.index   or ov.eyebrows.style or 0
    ov.eyebrows.opacity = (ov.eyebrows.opacity and ov.eyebrows.opacity > 0) and ov.eyebrows.opacity or 1.0
    ov.eyebrows.color   = clampNonNeg(ov.eyebrows.color or ov.eyebrows.primaryColor)
    ov["2"] = ov.eyebrows
  end

  ov.lipstick = ov.lipstick or ov["8"] or ov.Lipstick
  if ov.lipstick then
    ov.lipstick.index   = ov.lipstick.index   or ov.lipstick.style or 0
    ov.lipstick.opacity = (ov.lipstick.opacity and ov.lipstick.opacity > 0) and ov.lipstick.opacity or 1.0
    ov.lipstick.color   = clampNonNeg(ov.lipstick.color or ov.lipstick.primaryColor)
    ov["8"] = ov.lipstick
  end

  app.headOverlays = ov
end

local function applyAppearanceSafe(app)
  if not app or not exports['fivem-appearance'] then return end
  normalizeAppearance(app)

  exports['fivem-appearance']:setPlayerAppearance(app)


  local ped = PlayerPedId()


  local h = app.hair or {}
  local style   = tonumber(h.style) or 0
  local tex     = tonumber(h.texture) or 0


  local color   = clampNonNeg(h.color)
  local hiColor = clampNonNeg(h.highlight)

  SetPedComponentVariation(ped, 2, style, tex, 0)
  SetPedHairColor(ped, color, hiColor)

  local ov = app.headOverlays or {}
  local beard = ov["1"]
  if beard then
    local bIndex   = tonumber(beard.index) or 0
    local bOpacity = (beard.opacity and beard.opacity > 0) and beard.opacity or 1.0
    local bColor   = clampNonNeg(beard.color)
    SetPedHeadOverlay(ped, 1, bIndex, bOpacity)
    SetPedHeadOverlayColor(ped, 1, 1, bColor, bColor) -- palette 1 = hair
  end

  local brows = ov["2"]
  if brows then
    local eIndex   = tonumber(brows.index) or 0
    local eOpacity = (brows.opacity and brows.opacity > 0) and brows.opacity or 1.0
    local eColor   = clampNonNeg(brows.color)
    SetPedHeadOverlay(ped, 2, eIndex, eOpacity)
    SetPedHeadOverlayColor(ped, 2, 1, eColor, eColor)
  end

  local lips = ov["8"]
  if lips then
    local lIndex   = tonumber(lips.index) or 0
    local lOpacity = (lips.opacity and lips.opacity > 0) and lips.opacity or 1.0
    local lColor   = clampNonNeg(lips.color)
    SetPedHeadOverlay(ped, 8, lIndex, lOpacity)
    SetPedHeadOverlayColor(ped, 8, 2, lColor, lColor) -- palette 2
  end
end
-- ====== /NORMALIZE + FIX ======

local function applyJSON(jsonStr)
  if not jsonStr or #jsonStr == 0 then return end
  local ok, app = pcall(json.decode, jsonStr)
  if not ok or not app then return end
  applyAppearanceSafe(app)
end

RegisterNetEvent('cfwapp:haveAppearance', function(j)
  if j and #j > 0 then
    lastJSON = j
    applyJSON(lastJSON)
  else

    ensureFreemodeMale()
    local app = exports['fivem-appearance']:getPedAppearance(PlayerPedId())
    lastJSON = json.encode(app)
    TriggerServerEvent('cfwapp:saveAppearance', lastJSON)
    TriggerServerEvent('cfwapp:saveNamed', 'player', lastJSON)
    msg('^2Default "player" created. Use ^3/skin load player ^2anytime.')
  end
end)


CreateThread(function()
  Wait(1000)
  TriggerServerEvent('cfwapp:reqAppearance')
end)


AddEventHandler('playerSpawned', function()
  if lastJSON then
    CreateThread(function()
      Wait(300)
      applyJSON(lastJSON)
    end)
  end
end)


local function openCustomization()
  if not exports['fivem-appearance'] then return msg('^1fivem-appearance not found') end
  exports['fivem-appearance']:startPlayerCustomization(function(app)
    if app then
      applyAppearanceSafe(app)
      lastJSON = json.encode(app)
      TriggerServerEvent('cfwapp:saveAppearance', lastJSON)
      msg('^2Saved as default. Use ^3/skin save <name> ^2to keep a named copy.')
    end
  end, { ped=true, headBlend=true, faceFeatures=true, headOverlays=true, components=true, props=true, tattoos=true, allowExit=true })
end

RegisterCommand('customization', function() openCustomization() end)


RegisterCommand('skin', function(_, args)
  local sub = (args[1] or ''):lower()
  if sub == 'save' then
    local name = args[2] or 'player'
    if not exports['fivem-appearance'] then return end
    local app = exports['fivem-appearance']:getPedAppearance(PlayerPedId())
    local payload = json.encode(app)
    lastJSON = payload
    TriggerServerEvent('cfwapp:saveNamed', name, payload)
    if name == 'player' then
      TriggerServerEvent('cfwapp:saveAppearance', payload)
    end
  elseif sub == 'load' then
    local name = args[2]; if not name then return msg('^1Usage: /skin load <name>') end
    TriggerServerEvent('cfwapp:loadNamed', name)
  elseif sub == 'list' then
    TriggerServerEvent('cfwapp:listNamed')
  elseif sub == 'del' then
    local name = args[2]; if not name then return msg('^1Usage: /skin del <name>') end
    TriggerServerEvent('cfwapp:deleteNamed', name)
  else
    msg('^2/skin save [name]^7, ^2/skin load <name>^7, ^2/skin list^7, ^2/skin del <name>')
  end
end)

RegisterNetEvent('cfwapp:receiveNamed', function(name, j)
  if j and #j > 0 then
    lastJSON = j
    applyJSON(lastJSON)
    msg(('^2Loaded skin "%s".'):format(name))
  else
    msg(('^1Skin "%s" not found.'):format(name))
  end
end)

RegisterNetEvent('cfwapp:receiveList', function(t)
  local names = {}
  for k in pairs(t or {}) do names[#names+1] = k end
  table.sort(names)
  if #names == 0 then msg('^3No saved skins.')
  else msg('^2Skins:^7 '..table.concat(names, ', ')) end
end)
