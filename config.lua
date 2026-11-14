Config = {}

Config.Enabled = true
Config.ZombieModels = {
    'u_m_y_zombie_01'
}

Config.Spawn = {
    interval = 5000,
    minimumDistance = 18.0,
    maximumDistance = 45.0,
    maximumZombies = 12,
    despawnDistance = 100.0,
    groundProbeHeight = 50.0
}

Config.Zombie = {
    health = 200,
    accuracy = 10,
    moveRate = 1.0,
    attackDamage = 10,
    attackInterval = 1500,
    attackRange = 1.5,
    hearingRange = 45.0,
    sightRange = 30.0,
    ragdollOnDeath = true,
    dropWeapons = false,
    combatAbility = 0,
    combatRange = 0,
    combatMovement = 1,
    relationshipGroup = 'ENDER_ZOMBIES'
}

Config.Loot = {
    enabled = true,
    dropChance = 65,
    pickupDistance = 2.0,
    lifetime = 300000,
    interactionKey = 38,
    drawDistance = 20.0,
    items = {
        {
            name = 'canned_food',
            label = 'Canned Food',
            minimum = 1,
            maximum = 2,
            weight = 45,
            prop = 'prop_cs_burger_01'
        },
        {
            name = 'bandage',
            label = 'Bandage',
            minimum = 1,
            maximum = 2,
            weight = 35,
            prop = 'prop_ld_health_pack'
        },
        {
            name = 'scrap',
            label = 'Scrap',
            minimum = 1,
            maximum = 3,
            weight = 20,
            prop = 'prop_rub_scrap_02'
        }
    }
}

Config.Debug = false
