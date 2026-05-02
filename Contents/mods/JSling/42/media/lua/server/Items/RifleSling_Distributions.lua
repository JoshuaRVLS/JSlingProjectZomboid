if not ProceduralDistributions or not ProceduralDistributions.list then
    return
end

local function getSetting(name, default)
    local vars = SandboxVars and SandboxVars.JSling or nil
    local value = vars and vars[name]
    if value == nil then
        return default
    end
    return value
end

local ENABLE_SLING_LOOT = getSetting("EnableSlingLoot", true)
local SLING_LOOT_MULTIPLIER = tonumber(getSetting("SlingLootMultiplier", 1)) or 1

local function addProcedural(name, fullType, weight)
    local dist = ProceduralDistributions.list[name]
    if not dist or not dist.items then
        return
    end

    table.insert(dist.items, fullType)
    table.insert(dist.items, weight)
end

local procedural = {
    PoliceLockers = {
        {"Base.RifleSling", 0.45},
    },
    PoliceStorageGuns = {
        {"Base.RifleSling", 0.90},
    },
    PoliceStorageAmmunition = {
        {"Base.RifleSling", 0.12},
    },
    GunStoreDisplayCase = {
        {"Base.RifleSling", 0.15},
    },
    GunStoreShelf = {
        {"Base.RifleSling", 0.35},
    },
    HuntingLockers = {
        {"Base.RifleSling", 0.55},
    },
    RangerLockers = {
        {"Base.RifleSling", 0.45},
    },
    ArmyStorageGuns = {
        {"Base.RifleSling", 1.10},
    },
    ArmyStorageAmmunition = {
        {"Base.RifleSling", 0.18},
    },
    ArmyStorageOutfit = {
        {"Base.RifleSling", 0.80},
    },
    ArmySurplusBackpacks = {
        {"Base.RifleSling", 0.75},
    },
    ArmySurplusOutfit = {
        {"Base.RifleSling", 0.55},
    },
    LockerArmyBedroom = {
        {"Base.RifleSling", 0.35},
    },
    LockerArmyBedroomHome = {
        {"Base.RifleSling", 0.20},
    },
}

if ENABLE_SLING_LOOT and SLING_LOOT_MULTIPLIER > 0 then
    for distName, entries in pairs(procedural) do
        for _, entry in ipairs(entries) do
            addProcedural(distName, entry[1], entry[2] * SLING_LOOT_MULTIPLIER)
        end
    end
end
