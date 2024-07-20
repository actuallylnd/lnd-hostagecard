# lnd-hostagecard
A simple script where after using the card, a bookmarker appears in the place of our choice

Paste it into 
- ox_inventory/modules/items/client

```Item('hostagecard', function(data, slot)
    exports.ox_inventory:useItem(data, function(data)
        TriggerEvent('lnd-hostagecard:client:useHostageCard', data)
    end)
end)```
