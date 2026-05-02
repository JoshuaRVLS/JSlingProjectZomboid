require "Items/Distributions"
require "Items/ProceduralDistributions"
require "Vehicles/VehicleDistributions"

local function getSetting(name, default)
    local vars = SandboxVars and SandboxVars.JSling or nil
    local value = vars and vars[name]
    if value == nil then
        return default
    end
    return value
end

local ENABLE_ACCESSORY_LOOT = getSetting("EnableAccessoryLoot", true)
local ACCESSORY_LOOT_MULTIPLIER = tonumber(getSetting("AccessoryLootMultiplier", 1)) or 1

local function addProcedural(name, fullType, weight)
    local dist = ProceduralDistributions and ProceduralDistributions.list and ProceduralDistributions.list[name]
    if not dist or not dist.items then
        return
    end
    table.insert(dist.items, fullType)
    table.insert(dist.items, weight)
end

local function addSuburb(key, fullType, weight)
    if not SuburbsDistributions then
        return
    end
    local first, second = key:match("^([^.]+)%.(.+)$")
    local dist = second and SuburbsDistributions[first] and SuburbsDistributions[first][second] or SuburbsDistributions[key]
    if not dist or not dist.items then
        return
    end
    table.insert(dist.items, fullType)
    table.insert(dist.items, weight)
end

local function addVehicle(key, fullType, weight)
    if not VehicleDistributions then
        return
    end
    local first, second = key:match("^([^.]+)%.(.+)$")
    local dist = second and VehicleDistributions[first] and VehicleDistributions[first][second] or VehicleDistributions[key]
    if not dist or not dist.items then
        return
    end
    table.insert(dist.items, fullType)
    table.insert(dist.items, weight)
end

local procedural = {
    PoliceStorageOutfit = {
        {"Base.JSling_Webbing_Black", 0.35},
    },
    PoliceLockers = {
        {"Base.JSling_Webbing_Black", 0.25},
        {"Base.JSling_KnifeSheath", 0.10},
    },
    ArmyStorageOutfit = {
        {"Base.JSling_Webbing_Military", 0.55},
        {"Base.JSling_TacticalVest", 0.10},
    },
    LockerArmyBedroom = {
        {"Base.JSling_Webbing_Military", 0.35},
    },
    ArmySurplusOutfit = {
        {"Base.JSling_Webbing_Military", 0.45},
        {"Base.JSling_ChestRig", 0.20},
        {"Base.JSling_TacticalVest", 0.08},
    },
    ArmySurplusMisc = {
        {"Base.JSling_Webbing", 0.45},
        {"Base.JSling_ChestRig", 0.35},
        {"Base.JSling_KnifeSheath", 0.15},
    },
    ArmySurplusTools = {
        {"Base.JSling_KnifeSheath", 0.20},
        {"Base.JSling_KnifeSheathBack", 0.12},
    },
    FirearmWeapons = {
        {"Base.JSling_ChestRig", 0.30},
        {"Base.JSling_Webbing", 0.20},
    },
    GarageFirearms = {
        {"Base.JSling_ChestRig", 0.08},
        {"Base.JSling_Webbing", 0.12},
    },
    GunStoreShelf = {
        {"Base.JSling_Webbing", 0.18},
        {"Base.JSling_ChestRig", 0.25},
        {"Base.JSling_KnifeSheath", 0.06},
    },
    CampingStoreGear = {
        {"Base.JSling_BackRig", 0.30},
        {"Base.JSling_Webbing", 0.12},
    },
    CampingStoreBackpacks = {
        {"Base.JSling_BackRig", 0.20},
    },
    PawnShopGunsSpecial = {
        {"Base.JSling_ChestRig", 0.20},
        {"Base.JSling_Webbing", 0.12},
    },
    PawnShopKnives = {
        {"Base.JSling_KnifeSheath", 0.45},
        {"Base.JSling_KnifeSheathBack", 0.30},
        {"Base.JSling_KatanaSheath", 0.12},
    },
    PlankStashGun = {
        {"Base.JSling_ChestRig", 0.18},
        {"Base.JSling_Webbing", 0.12},
    },
    MeleeWeapons = {
        {"Base.JSling_KnifeSheath", 0.35},
        {"Base.JSling_KnifeSheathBack", 0.18},
        {"Base.JSling_KatanaSheath", 0.10},
    },
    WardrobeRedneck = {
        {"Base.JSling_ChestRig", 0.06},
        {"Base.JSling_Webbing", 0.05},
        {"Base.JSling_KnifeSheath", 0.10},
    },
    DrugLabGuns = {
        {"Base.JSling_Webbing", 0.12},
        {"Base.JSling_ChestRig", 0.08},
    },
}

if ENABLE_ACCESSORY_LOOT and ACCESSORY_LOOT_MULTIPLIER > 0 then
    for distName, entries in pairs(procedural) do
        for _, entry in ipairs(entries) do
            addProcedural(distName, entry[1], entry[2] * ACCESSORY_LOOT_MULTIPLIER)
        end
    end
    for _, entry in ipairs({
        {"SurvivorCache1.SurvivorCrate", "Base.JSling_ChestRig", 0.12},
        {"SurvivorCache1.SurvivorCrate", "Base.JSling_Webbing", 0.25},
        {"SurvivorCache2.SurvivorCrate", "Base.JSling_ChestRig", 0.12},
        {"SurvivorCache2.SurvivorCrate", "Base.JSling_Webbing", 0.25},
        {"Bag_WeaponBag", "Base.JSling_ChestRig", 0.10},
        {"Bag_WeaponBag", "Base.JSling_Webbing", 0.10},
        {"Bag_WeaponBag", "Base.JSling_KnifeSheath", 0.08},
        {"Bag_SurvivorBag", "Base.JSling_ChestRig", 0.10},
        {"Bag_SurvivorBag", "Base.JSling_Webbing", 0.10},
        {"Bag_SurvivorBag", "Base.JSling_KnifeSheath", 0.08},
    }) do
        addSuburb(entry[1], entry[2], entry[3] * ACCESSORY_LOOT_MULTIPLIER)
    end

    for _, entry in ipairs({
        {"Police.TruckBed", "Base.JSling_Webbing_Black", 0.20},
        {"SurvivalistTruckBed", "Base.JSling_ChestRig", 0.22},
        {"SurvivalistTruckBed", "Base.JSling_Webbing", 0.25},
        {"SurvivalistTruckBed", "Base.JSling_KnifeSheath", 0.20},
        {"HunterTruckBed", "Base.JSling_BackRig", 0.25},
    }) do
        addVehicle(entry[1], entry[2], entry[3] * ACCESSORY_LOOT_MULTIPLIER)
    end
end
