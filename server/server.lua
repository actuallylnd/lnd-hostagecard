local ox_inventory = exports.ox_inventory
local UsedPeds = {}
GlobalState.UsedPeds = UsedPeds

RegisterNetEvent('lnd-hostagecard/addPed', function(netId)
    local src = source
    local card = ox_inventory:GetItemCount(src, 'hostagecard')
    if card >= 1 then

        lib.print.info("Added: ", netId)
        UsedPeds[netId] = true
        GlobalState.UsedPeds = UsedPeds

        ox_inventory:RemoveItem(src, "hostagecard", 1)
    end
end)

RegisterNetEvent('lnd-hostagecard/removePed')
AddEventHandler('lnd-hostagecard/removePed', function(netId)
    UsedPeds[netId] = nil
    GlobalState.UsedPeds = UsedPeds
    lib.print.info("Removed: ", netId)
end)