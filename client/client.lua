local ox_target = exports.ox_target

function RotationToDirection(rot)
    local rotZ = math.rad(rot.z)
    local rotX = math.rad(rot.x)
    local cosOfRotX = math.abs(math.cos(rotX))
    return vector3(-math.sin(rotZ) * cosOfRotX, math.cos(rotZ) * cosOfRotX, math.sin(rotX))
end

function RayCastCamera(dist)
    local camRot = GetGameplayCamRot()
    local camPos = GetGameplayCamCoord()
    local dir = RotationToDirection(camRot)
    local dest = camPos + (dir * dist)
    local ray = StartShapeTestRay(camPos, dest, 17, -1, 0)
    local _, hit, endPos, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit == 0 then endPos = dest end
    return hit, endPos, entityHit, surfaceNormal
end

function playHostageAnimation (ped)
    local animDict = "missprologueig_2"
    local animClip = "idle_on_floor_malehostage02"

    lib.requestAnimDict(animDict)

    TaskPlayAnim(ped, animDict, animClip, 8.0, 8.0, -1, 1, 0, false, false, false)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
end

function placePed(pedModel, coords, rotation)
    local hostage = CreatePed(4, pedModel, coords.x, coords.y, coords.z, rotation, true, true)

    addTarget(hostage, pedModel)

    lib.notify({
        description = Config.Tranlation.Hostageplaced
    })
end

function UseCard()
    local plyPed = cache.ped

    if GetVehiclePedIsIn(plyPed, false) ~= 0 then
        lib.notify({
            description = Config.Tranlation.WhileInCar
        })
        return
    end

    local pedModel = Config.PedModels[math.random(#Config.PedModels)]
    local hashModel = GetHashKey(pedModel)
    lib.requestModel(hashModel)

    lib.showTextUI('Uzyj Karty [E]  Anuluj [G]', {
        position = "left-center",
        icon = "person",
    })

    local placed = false
    local rotation = 0.0
    local raycastPed = nil

    local function createRaycastPed(coords, heading)
        local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, true)
        raycastPed = CreatePed(4, hashModel, coords.x, coords.y, groundZ, heading, false, false)
        SetEntityCollision(raycastPed, false, false)
        SetEntityHeading(raycastPed, heading)
        playHostageAnimation(raycastPed)
    end

    local function updatePedPosition(dest)
        SetEntityCoords(raycastPed, dest.x, dest.y, dest.z, true, false, false, false)
    end

    local function rotatePed()
        if IsControlJustPressed(0, 14) or IsControlJustPressed(0, 16) then
            rotation = rotation + 7.0
            if rotation >= 360.0 then rotation = 0.0 end
            SetEntityHeading(raycastPed, rotation)
        elseif IsControlJustPressed(0, 15) or IsControlJustPressed(0, 17) then
            rotation = rotation - 7.0
            if rotation <= 0.0 then rotation = 360.0 end
            SetEntityHeading(raycastPed, rotation)
        end
    end

    local function handleControls(hit, dest)
        if hit == 1 then
            updatePedPosition(dest)
            if IsControlJustPressed(0, 38) then
                placed = true
                lib.hideTextUI()
                DeleteEntity(raycastPed)
                placePed(pedModel, dest, rotation)
            elseif IsControlJustPressed(0, 47) then
                placed = true
                lib.hideTextUI()
                DeleteEntity(raycastPed)
            end
        else
            local coords = GetEntityCoords(plyPed)
            local heading = GetEntityHeading(plyPed)
            local forwardVector = GetEntityForwardVector(plyPed)
            _, groundZ = GetGroundZFor_3dCoord(coords.x + (forwardVector.x * .5), coords.y + (forwardVector.y * .5), coords.z + (forwardVector.z * .5), true)
            SetEntityCoords(raycastPed, coords.x + (forwardVector.x * .5), coords.y + (forwardVector.y * .5), groundZ, true, false, false, false)
            SetEntityHeading(raycastPed, heading)
            if IsControlJustPressed(0, 38) then
                placed = true
                local coords = GetEntityCoords(raycastPed)
                lib.hideTextUI()
                DeleteEntity(raycastPed)
                placePed(pedModel, coords, heading)
            elseif IsControlJustPressed(0, 47) then
                placed = true
                lib.hideTextUI()
                DeleteEntity(raycastPed)
            end
        end
    end

    createRaycastPed(GetEntityCoords(plyPed), GetEntityHeading(plyPed))

    while not placed do
        Wait(0)
        hit, dest = RayCastCamera(Config.rayCastingDistance)
        rotatePed()
        handleControls(hit, dest)
    end
end

function ReleaseHostage(hostage)
    ClearPedTasks(hostage)
    FreezeEntityPosition(hostage, false)
    TaskReactAndFleePed(hostage, cache.ped)
    SetEntityInvincible(hostage, false)

    lib.timer(10000, function()
        if DoesEntityExist(hostage) then
            DeleteEntity(hostage)
        end
    end, true)
end

function addTarget(ped, pedModel)

    if not DoesEntityExist(ped) then
        return
    end

    local netId = NetworkGetNetworkIdFromEntity(ped)
    TriggerServerEvent("lnd-hostagecard/addPed", netId)

    SetBlockingOfNonTemporaryEvents(ped, true)

    playHostageAnimation(ped)
    
    ox_target:addModel(pedModel, {
        {
            name = 'hostage',
            icon = 'fa-solid fa-person',
            label = Config.Tranlation.ReleaseHostage,
            distance = 1.2,
            canInteract = function (entity)
                return GlobalState.UsedPeds[NetworkGetNetworkIdFromEntity(entity)]
            end,
            onSelect = function(data)
                local entity = data.entity

                local netId = NetworkGetNetworkIdFromEntity(entity)
                TriggerServerEvent("lnd-hostagecard/removePed", netId)

                ReleaseHostage(entity)
            end
        }
    })
end

exports("UseCard", UseCard)
