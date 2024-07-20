RegisterNetEvent('lnd-hostagecard:server:createNewPed', function(coords, pedModel, rotation)
    local src = source
    if #(GetEntityCoords(GetPlayerPed(src)) - coords) > Config.rayCastingDistance + 10 then 
        return 
    end
    TriggerClientEvent('lnd-hostagecard:client:playHostageAnimation', src, pedModel, coords, rotation)
    exports.ox_inventory:RemoveItem(src, "hostagecard", 1)
end)
