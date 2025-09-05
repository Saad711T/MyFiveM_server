local function licOf(src)
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:sub(1,8) == 'license:' then return id end
  end
  return ('temp:%d'):format(src)
end

local function keyDefault(lic) return ('cfw:appearance:%s'):format(lic) end
local function keyList(lic)    return ('cfw:skins:%s'):format(lic) end
local function keySkin(lic,nm) return ('cfw:skin:%s:%s'):format(lic, nm:lower()) end

local function loadList(lic)
  local j = GetResourceKvpString(keyList(lic))
  return (j and json.decode(j)) or {}
end

local function saveList(lic, t)
  SetResourceKvp(keyList(lic), json.encode(t or {}))
end

local function addToList(lic, nm)
  local t = loadList(lic)
  if not t[nm] then t[nm] = true; saveList(lic, t) end
end

local function removeFromList(lic, nm)
  local t = loadList(lic)
  t[nm] = nil
  saveList(lic, t)
end

RegisterNetEvent('cfwapp:reqAppearance', function()
  local src = source
  local lic = licOf(src)
  local data = GetResourceKvpString(keyDefault(lic))
  TriggerClientEvent('cfwapp:haveAppearance', src, data or '')
end)






RegisterNetEvent('cfwapp:saveAppearance', function(jsonStr)
  if type(jsonStr) ~= 'string' or #jsonStr == 0 then return end
  local src = source
  local lic = licOf(src)
  SetResourceKvp(keyDefault(lic), jsonStr)
  TriggerClientEvent('chat:addMessage', src, { args={'CFW','^2Default skin saved.'} })
end)


RegisterNetEvent('cfwapp:saveNamed', function(name, jsonStr)
  if type(name) ~= 'string' or #name == 0 then return end
  if type(jsonStr) ~= 'string' or #jsonStr == 0 then return end
  local src = source
  local lic = licOf(src)
  local nm = name:lower()
  SetResourceKvp(keySkin(lic, nm), jsonStr)
  addToList(lic, nm)
  TriggerClientEvent('chat:addMessage', src, { args={'CFW',('^2Skin "%s" saved.'):format(nm)} })
end)



RegisterNetEvent('cfwapp:loadNamed', function(name)
  if type(name) ~= 'string' or #name == 0 then return end
  local src = source
  local lic = licOf(src)
  local nm = name:lower()
  local data = GetResourceKvpString(keySkin(lic, nm)) or ''
  TriggerClientEvent('cfwapp:receiveNamed', src, nm, data)
end)


RegisterNetEvent('cfwapp:listNamed', function()
  local src = source
  local lic = licOf(src)
  TriggerClientEvent('cfwapp:receiveList', src, loadList(lic))
end)

RegisterNetEvent('cfwapp:deleteNamed', function(name)
  if type(name) ~= 'string' or #name == 0 then return end
  local src = source
  local lic = licOf(src)
  local nm = name:lower()
  SetResourceKvp(keySkin(lic, nm), '')
  removeFromList(lic, nm)
  TriggerClientEvent('chat:addMessage', src, { args={'CFW',('^3Skin "%s" deleted.'):format(nm)} })
end)


RegisterCommand('cfw_reset', function(_, args)
  local id = tonumber(args[1] or '')
  if not id then print('usage: cfw_reset <serverId>'); return end
  local lic = licOf(id)
  SetResourceKvp(keyDefault(lic), '')
  saveList(lic, {})
  print(('reset default + list for %d'):format(id))
end, true)
