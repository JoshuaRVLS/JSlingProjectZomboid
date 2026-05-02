if isClient and isClient() and not (isServer and isServer()) then
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

local POLICE_OUTFITS = {
    Police = true,
    PoliceState = true,
    PoliceRiot = true,
    Police_SWAT = true,
    Sheriff_Deputy = true,
}

local MILITARY_OUTFITS = {
    ArmyCamoDesert = true,
    ArmyCamoGreen = true,
    ArmyInstructor = true,
    ArmyServiceUniform = true,
    PrivateMilitia = true,
}

local SLING_TYPES = {
    "Base.RifleSling",
    "Base.RifleSling_Back",
}

local MILITARY_FIREARMS = {
    "Base.AssaultRifle",
    "Base.AssaultRifle2",
    "Base.HuntingRifle",
    "Base.Shotgun",
}

local function randomPercent(chance)
    if not chance or chance <= 0 then
        return false
    end
    return ZombRand(100) < chance
end

local function pickRandom(list)
    if not list or #list == 0 then
        return nil
    end
    return list[ZombRand(#list) + 1]
end

local function getOutfitName(zombie)
    if not zombie or not zombie.getOutfitName then
        return nil
    end
    return zombie:getOutfitName()
end

local function wearSlingOnZombie(zombie, slingType)
    if not zombie or not slingType then
        return nil
    end

    local inv = zombie.getInventory and zombie:getInventory() or nil
    if not inv then
        return nil
    end

    local sling = inv:AddItem(slingType)
    if not sling then
        return nil
    end

    local bodyLocation = sling.getBodyLocation and sling:getBodyLocation() or nil
    if not bodyLocation or not zombie.setWornItem then
        return nil
    end

    zombie:setWornItem(bodyLocation, sling)
    return sling
end

local function attachWeaponToSlingZombie(zombie, weapon, slingItem)
    if not zombie or not weapon or not slingItem or not RifleSling then
        return false
    end

    local slotType = RifleSling.getPoseSlotType and RifleSling.getPoseSlotType(slingItem) or nil
    if not slotType then
        return false
    end

    local location = RifleSling.resolveAttachmentSlot and RifleSling.resolveAttachmentSlot(weapon, slotType) or nil
    if not location then
        return false
    end

    if zombie.setAttachedItem then
        zombie:setAttachedItem(location, weapon)
    else
        return false
    end

    if weapon.setAttachedSlot then
        weapon:setAttachedSlot(-1)
    end
    if weapon.setAttachedSlotType then
        weapon:setAttachedSlotType(slotType)
    end
    if weapon.setAttachedToModel then
        weapon:setAttachedToModel(location)
    end

    return true
end

local function addMilitarySlungFirearm(zombie, slingItem)
    if not zombie or not slingItem then
        return
    end

    local inv = zombie.getInventory and zombie:getInventory() or nil
    if not inv then
        return
    end

    local firearmType = pickRandom(MILITARY_FIREARMS)
    if not firearmType then
        return
    end

    local weapon = inv:AddItem(firearmType)
    if not weapon then
        return
    end

    attachWeaponToSlingZombie(zombie, weapon, slingItem)
end

local function onZombieCreate(zombie)
    if not zombie or zombie:isSkeleton() then
        return
    end

    if not getSetting("EnableZombieSlings", true) then
        return
    end

    local outfit = getOutfitName(zombie)
    if not outfit then
        return
    end

    local slingChance = nil
    if POLICE_OUTFITS[outfit] then
        slingChance = tonumber(getSetting("PoliceZombieSlingChance", 4)) or 4
    elseif MILITARY_OUTFITS[outfit] then
        slingChance = tonumber(getSetting("MilitaryZombieSlingChance", 8)) or 8
    else
        return
    end

    if not randomPercent(slingChance) then
        return
    end

    local sling = wearSlingOnZombie(zombie, pickRandom(SLING_TYPES))
    if not sling then
        return
    end

    local militaryFirearmChance = tonumber(getSetting("MilitaryZombieFirearmChance", 2)) or 2
    if MILITARY_OUTFITS[outfit] and randomPercent(militaryFirearmChance) then
        addMilitarySlungFirearm(zombie, sling)
    end
end

if Events and Events.OnZombieCreate then
    Events.OnZombieCreate.Add(onZombieCreate)
end
