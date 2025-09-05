RegisterCommand('revive', function(src, args)
  local target = tonumber(args[1] or src)
  if not target or target <= 0 then return end

  -- if not IsPlayerAceAllowed(src, 'command.revive') then
  --   TriggerClientEvent('chat:addMessage', src, { args={'CFW','^1No permission.'} })
  --   return
  -- end

  TriggerClientEvent('cfw:clientRevive', target)
end, false)
