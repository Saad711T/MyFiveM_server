

local Accounts = {}
local dirty = false

local function save()
    local ok, content = pcall(json.encode, Accounts)
    if ok then
        SaveResourceFile(GetCurrentResourceName(), Config.SaveFile, content, -1)
        dirty = false
    end
end

local function load()
    local raw = LoadResourceFile(GetCurrentResourceName(), Config.SaveFile)
    if raw and raw ~= '' then
        local ok, data = pcall(json.decode, raw)
        if ok and type(data) == 'table' then Accounts = data end
    end
end


local function getLicense(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:sub(1, 8) == 'license:' then return id end
    end
    return nil
end




local function ensureAccount(license)
    if not Accounts[license] then
        Accounts[license] = {
            cash = Config.StartingCash,
            bank = Config.StartingBank
        }
        dirty = true
    end
    return Accounts[license]
end



local function getMoney(license, account)
    local acc = ensureAccount(license)
    return acc[account] or 0
end

local function addMoney(license, account, amount)
    if amount <= 0 then return false end
    local acc = ensureAccount(license)
    acc[account] = (acc[account] or 0) + amount
    dirty = true
    return true
end

local function removeMoney(license, account, amount)
    if amount <= 0 then return false end
    local acc = ensureAccount(license)
    if (acc[account] or 0) < amount then return false end
    acc[account] = acc[account] - amount
    dirty = true
    return true
end


local function syncClient(src)
    local license = getLicense(src)
    if not license then return end
    local acc = ensureAccount(license)
    TriggerClientEvent('cfw_money:sync', src, acc.cash, acc.bank)
end


local function withLicense(src, fn)
    local license = getLicense(src)
    if not license then return false end
    return fn(license)
end





exports('GetMoney', function(src, account)
    return withLicense(src, function(license)
        return getMoney(license, account or 'cash')
    end) or 0
end)


exports('GetAccounts', function(src)
    local license = getLicense(src)
    if not license then return 0, 0 end
    local acc = ensureAccount(license)
    return acc.cash, acc.bank
end)


exports('AddMoney', function(src, account, amount)
    local result = withLicense(src, function(license)
        return addMoney(license, account or 'cash', amount)
    end)
    if result then syncClient(src) end
    return result or false
end)


exports('RemoveMoney', function(src, account, amount)
    local result = withLicense(src, function(license)
        return removeMoney(license, account or 'cash', amount)
    end)
    if result then syncClient(src) end
    return result or false
end)


exports('CanAfford', function(src, account, amount)
    return withLicense(src, function(license)
        return getMoney(license, account or 'cash') >= amount
    end) or false
end)



RegisterCommand('cash', function(src)
    local license = getLicense(src)
    if not license then return end
    local acc = ensureAccount(license)
    TriggerClientEvent('chat:addMessage', src, {
        args = { 'Bank', ('^2Cash: %s%d ^7| ^5Bank: %s%d'):format(
            Config.CurrencySymbol, acc.cash, Config.CurrencySymbol, acc.bank) }
    })
end, false)


RegisterCommand('pay', function(src, args)
    local target = tonumber(args[1])
    local amount = tonumber(args[2])
    if not target or not amount or amount <= 0 then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', '^1Usage: /pay <id> <amount>' } })
        return
    end
    if not GetPlayerName(target) then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', '^1Player not found' } })
        return
    end

    local senderLic = getLicense(src)
    local targetLic = getLicense(target)
    if not senderLic or not targetLic then return end

    if not removeMoney(senderLic, 'cash', amount) then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', '^1Not enough cash' } })
        return
    end
    addMoney(targetLic, 'cash', amount)
    syncClient(src); syncClient(target)

    TriggerClientEvent('chat:addMessage', src, { args = { 'Pay', ('^2Sent %s%d to %s'):format(Config.CurrencySymbol, amount, GetPlayerName(target)) } })
    TriggerClientEvent('chat:addMessage', target, { args = { 'Pay', ('^2Received %s%d from %s'):format(Config.CurrencySymbol, amount, GetPlayerName(src)) } })
end, false)







RegisterCommand('givemoney', function(src, args)

    if src ~= 0 and not IsPlayerAceAllowed(src, 'command') then
        TriggerClientEvent('chat:addMessage', src, { args = { 'Admin', '^1No permission' } })
        return
    end
    local target = tonumber(args[1])
    local account = args[2]  -- cash أو bank
    local amount = tonumber(args[3])
    if not target or not account or not amount then
        local msg = '^1Usage: /givemoney <id> <cash|bank> <amount>'
        if src == 0 then print(msg) else TriggerClientEvent('chat:addMessage', src, { args = { 'Admin', msg } }) end
        return
    end
    local targetLic = getLicense(target)
    if not targetLic then return end
    addMoney(targetLic, account, amount)
    syncClient(target)
    local done = ('^2Gave %s%d (%s) to %s'):format(Config.CurrencySymbol, amount, account, GetPlayerName(target))
    if src == 0 then print(done) else TriggerClientEvent('chat:addMessage', src, { args = { 'Admin', done } }) end
end, false)





AddEventHandler('onResourceStart', function(res)
    if res ~= GetCurrentResourceName() then return end
    load()
    print('^2[cfw_money] loaded accounts^0')
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    save()
end)

AddEventHandler('playerJoining', function()
    local src = source
    local license = getLicense(src)
    if license then ensureAccount(license) end
end)



RegisterNetEvent('cfw_money:requestSync', function()
    syncClient(source)
end)





AddEventHandler('playerDropped', function()
    if dirty then save() end
end)




CreateThread(function()
    while true do
        Wait(Config.AutoSaveInterval * 1000)
        if dirty then save() end
    end
end)



AddEventHandler('txAdmin:events:serverShuttingDown', function()
    save()
end)