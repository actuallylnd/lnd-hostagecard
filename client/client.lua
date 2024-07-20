local RotationToDirection = function(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

local RayCastCamera = function(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

local playHostageAnimation = function(pedEntity)
    RequestAnimDict("missprologueig_2")
    while not HasAnimDictLoaded("missprologueig_2") do
        Wait(0)
    end
    TaskPlayAnim(pedEntity, "missprologueig_2", "idle_on_floor_malehostage02", 8.0, 8.0, -1, 1, 0, false, false, false)
end

local placePed = function(ped, pedModel, coords, rotation)
    
    TriggerServerEvent('lnd-hostagecard:server:createNewPed', coords, pedModel, rotation)
     lib.notify({
        description = 'Postawiłeś Zakładnika',
    })
  
end

RegisterNetEvent('lnd-hostagecard:client:placePed', function()

    local ped = PlayerPedId()
    if GetVehiclePedIsIn(PlayerPedId(), false) ~= 0 then
        lib.notify({
            description = 'Nie możesz użyć karty siedząc w pojeździe',
        })
        return
    end

    local pedModel = Config.PedModels[math.random(#Config.PedModels)]

    local hashModel = GetHashKey(pedModel)
    RequestModel(hashModel)
    while not HasModelLoaded(hashModel) do Wait(0) end

    lib.showTextUI('Uzyj Karty [E]  Anuluj [G]', {
        position = "left-center",
        icon = "person",
    })

    local hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)
    local coords = GetEntityCoords(ped)
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)

    local pedEntity = CreatePed(4, hashModel, coords.x, coords.y, groundZ, 0.0, false, false)
    SetEntityCollision(pedEntity, false, false)
    --SetEntityAlpha(pedEntity, 200, true)
    SetEntityHeading(pedEntity, 0.0)
    playHostageAnimation(pedEntity)

    local placed = false
    local rotation = 0.0
    while not placed do
        Wait(0)
        hit, dest, _, _ = RayCastCamera(Config.rayCastingDistance)

        if hit == 1 then
            SetEntityCoords(pedEntity, dest.x, dest.y, dest.z)

            if IsControlJustPressed(0, 14) or IsControlJustPressed(0, 16) then
                rotation = rotation + 7.0
                if rotation >= 360.0 then
                    rotation = 0.0
                end
                SetEntityHeading(pedEntity, rotation)
            end

            if IsControlJustPressed(0, 15) or IsControlJustPressed(0, 17) then
                rotation = rotation - 7.0
                if rotation <= 0.0 then
                    rotation = 360.0
                end
                SetEntityHeading(pedEntity, rotation)
            end

            if IsControlJustPressed(0, 38) then
                placed = true
                lib.hideTextUI()
                DeleteEntity(pedEntity)
                placePed(ped, pedModel, dest, rotation)
                return
            end

            if IsControlJustPressed(0, 47) then
                placed = true
                lib.hideTextUI()
                DeleteEntity(pedEntity)
                return
            end

        else
            coords = GetEntityCoords(ped)
            local heading = GetEntityHeading(ped)
            local forwardVector = GetEntityForwardVector(ped)
            _, groundZ = GetGroundZFor_3dCoord(coords.x + (forwardVector.x * .5), coords.y + (forwardVector.y * .5), coords.z + (forwardVector.z * .5), true)

            SetEntityCoords(pedEntity, coords.x + (forwardVector.x * .5), coords.y + (forwardVector.y * .5), groundZ)
            SetEntityHeading(pedEntity, heading)
            if IsControlJustPressed(0, 38) then
                placed = true
                local coords = GetEntityCoords(pedEntity)
                lib.hideTextUI()
                DeleteEntity(pedEntity)
                placePed(ped, pedModel, coords, heading)
                return
            end

            if IsControlJustPressed(0, 47) then
                placed = true
                lib.hideTextUI()
                DeleteEntity(pedEntity)
                return
            end
        end
    end
end)

RegisterNetEvent('lnd-hostagecard:client:useHostageCard', function(data)
    TriggerEvent('lnd-hostagecard:client:placePed')
end)

RegisterNetEvent('lnd-hostagecard:client:playHostageAnimation', function (pedModel, coords, rotation)
    RequestModel(pedModel)
    while not HasModelLoaded(pedModel) do
        Wait(0)
    end
    local pedEntity = CreatePed(4, pedModel, coords.x, coords.y, coords.z , rotation, true, true)
    FreezeEntityPosition(pedEntity, true)
    SetBlockingOfNonTemporaryEvents(pedEntity, true)

    playHostageAnimation(pedEntity)

    exports.ox_target:addLocalEntity(pedEntity, {
        {
            name = 'hostage',
            icon = 'fa-solid fa-person',
            label = 'Pusc Zakladnika',
            distance = 1.2,
            onSelect = function()
                ClearPedTasks(pedEntity)
                FreezeEntityPosition(pedEntity, false)
                TaskReactAndFleePed(pedEntity, PlayerPedId())
                exports.ox_target:removeLocalEntity(pedEntity, "hostage")

                Citizen.SetTimeout(10000, function()
                    if DoesEntityExist(pedEntity) then
                        DeleteEntity(pedEntity)
                    end
                end)
            end
        }
    })
end)
