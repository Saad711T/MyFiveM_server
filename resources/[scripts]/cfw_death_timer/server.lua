RegisterCommand('revive', function(src, args)
  local target = tonumber(args[1] or src)
  if not target or target <= 0 then return end

  
  TriggerClientEvent('cfw:clientRevive', target)
end, false)
