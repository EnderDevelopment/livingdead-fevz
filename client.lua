local zombies = {}
local lastZombieAttack = {}
local zombieGroup
local lastSpawnAt = 0
local modelLoadTimeout = 5000

local function debugPrint(message)
    if Config.Debug then
        print(('[ender_zombies] %s'):format(message))
    end
end

local function requestModel(model)
    local modelHash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(modelHash) or not IsModelValid(modelHash) then
        debugPrint(('Invalid zombie model: %s'):format(tostring(model)))
        return nil
    end

    RequestModel(modelHash)
    local timeoutAt = GetGameTimer() + modelLoadTimeout
    while not HasModelLoaded(modelHash) and GetGameTimer() < timeoutAt do
        Wait(0)
    end

    if not HasModelLoaded(modelHash) then
        debugPrint(('Timed out loading model: %s'):format(tostring(model)))
        return nil
    end

    return modelHash
end

local function setupRelationships()
    AddRelationshipGroup(Config.Zombie.relationshipGroup)
    zombieGroup = GetHashKey(Config.Zombie.relationshipGroup)
    SetRelationshipBetweenGroups(5, zombieGroup, GetHashKey('PLAYER'))
    SetRelationshipBetweenGroups(5, GetHashKey('PLAYER'), zombieGroup)
end

local function removeZombie(index)
    local zombie = zombies[index]
    if zombie then
        lastZombieAttack[zombie] = nil
        if DoesEntityExist(zombie) then
            SetEntityAsMissionEntity(zombie, true, true)
            DeletePed(zombie)
        end
    end
    table.remove(zombies, index)
end

local function cleanupZombies(playerPed)
    local playerCoords = GetEntityCoords(playerPed)
    for index = #zombies, 1, -1 do
        local zombie = zombies[index]
        local shouldRemove = not DoesEntityExist(zombie)

        if not shouldRemove then
            local zombieCoords = GetEntityCoords(zombie)
            shouldRemove = IsEntityDead(zombie) or #(zombieCoords - playerCoords) > Config.Spawn.despawnDistance
        end

        if shouldRemove then
            removeZombie(index)
        end
    end
end

local function findSpawnPoint(playerCoords)
    local angle = math.random() * math.pi * 2.0
    local distance = Config.Spawn.minimumDistance + math.random() * (Config.Spawn.maximumDistance - Config.Spawn.minimumDistance)
    local x = playerCoords.x + math.cos(angle) * distance
    local y = playerCoords.y + math.sin(angle) * distance
    local probeHeight = Config.Spawn.groundProbeHeight

    RequestCollisionAtCoord(x, y, playerCoords.z)
    local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, playerCoords.z + probeHeight, false)
    if not foundGround then
        return nil
    end

    return vector3(x, y, groundZ)
end

local function configureZombie(zombie, playerPed)
    SetEntityAsMissionEntity(zombie, true, true)
    SetEntityMaxHealth(zombie, Config.Zombie.health)
    SetEntityHealth(zombie, Config.Zombie.health)
    SetPedAccuracy(zombie, Config.Zombie.accuracy)
    SetPedMoveRateOverride(zombie, Config.Zombie.moveRate)
    SetPedCombatAbility(zombie, Config.Zombie.combatAbility)
    SetPedCombatRange(zombie, Config.Zombie.combatRange)
    SetPedCombatMovement(zombie, Config.Zombie.combatMovement)
    SetPedCanSwitchWeapon(zombie, false)
    SetPedDropsWeaponsWhenDead(zombie, Config.Zombie.dropWeapons)
    SetPedRelationshipGroupHash(zombie, zombieGroup)
    SetPedAsEnemy(zombie, true)
    SetBlockingOfNonTemporaryEvents(zombie, true)
    SetPedFleeAttributes(zombie, 0, false)
    SetPedCombatAttributes(zombie, 5, true)
    SetPedCombatAttributes(zombie, 46, true)
    SetPedSeeingRange(zombie, Config.Zombie.sightRange)
    SetPedHearingRange(zombie, Config.Zombie.hearingRange)
    SetPedKeepTask(zombie, true)
    TaskCombatPed(zombie, playerPed, 0, 16)
end

local function spawnZombie(playerPed)
    if #Config.ZombieModels == 0 then
        debugPrint('No zombie models are configured')
        return false
    end

    local spawnPoint = findSpawnPoint(GetEntityCoords(playerPed))
    if not spawnPoint then
        return false
    end

    local model = Config.ZombieModels[math.random(1, #Config.ZombieModels)]
    local modelHash = requestModel(model)
    if not modelHash then
        return false
    end

    local zombie = CreatePed(4, modelHash, spawnPoint.x, spawnPoint.y, spawnPoint.z, math.random(0, 359) + 0.0, false, false)
    SetModelAsNoLongerNeeded(modelHash)
    if not DoesEntityExist(zombie) then
        return false
    end

    configureZombie(zombie, playerPed)
    zombies[#zombies + 1] = zombie
    debugPrint(('Spawned zombie (%d/%d)'):format(#zombies, Config.Spawn.maximumZombies))
    return true
end

local function attackNearbyPlayer(zombie, playerPed)
    if not DoesEntityExist(zombie) or IsEntityDead(zombie) or IsEntityDead(playerPed) then
        return
    end

    if #(GetEntityCoords(zombie) - GetEntityCoords(playerPed)) > Config.Zombie.attackRange then
        return
    end

    local now = GetGameTimer()
    local lastAttack = lastZombieAttack[zombie] or 0
    if now - lastAttack < Config.Zombie.attackInterval then
        return
    end

    lastZombieAttack[zombie] = now
    ApplyDamageToPed(playerPed, Config.Zombie.attackDamage, false)
end

CreateThread(function()
    math.randomseed(GetGameTimer())
    setupRelationships()

    while true do
        if not Config.Enabled then
            Wait(1000)
        else
            local playerPed = PlayerPedId()
            if IsEntityDead(playerPed) then
                cleanupZombies(playerPed)
                Wait(1000)
            else
                cleanupZombies(playerPed)
                local now = GetGameTimer()
                if #zombies < Config.Spawn.maximumZombies and now - lastSpawnAt >= Config.Spawn.interval then
                    lastSpawnAt = now
                    spawnZombie(playerPed)
                end
                Wait(500)
            end
        end
    end
end)

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        for index = #zombies, 1, -1 do
            local zombie = zombies[index]
            if DoesEntityExist(zombie) then
                attackNearbyPlayer(zombie, playerPed)
            else
                lastZombieAttack[zombie] = nil
                table.remove(zombies, index)
            end
        end
        Wait(100)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then
        return
    end

    for index = #zombies, 1, -1 do
        removeZombie(index)
    end
end)
