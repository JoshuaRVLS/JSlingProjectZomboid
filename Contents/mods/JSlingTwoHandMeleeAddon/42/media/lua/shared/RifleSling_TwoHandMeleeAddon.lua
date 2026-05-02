if not RifleSling then
    return
end

local function rifleToWeaponLocation(rifleLocation)
    if not rifleLocation then
        return nil
    end
    return string.gsub(rifleLocation, "Rifle", "Weapon", 1)
end

local function rifleToShovelLocation(rifleLocation)
    if not rifleLocation then
        return nil
    end
    return string.gsub(rifleLocation, "Rifle", "Shovel", 1)
end

function RifleSling.applyAttachmentExtensions(slotType, mapping)
    if not mapping then
        return
    end

    local rifleLocation = mapping.Rifle
    if not rifleLocation then
        return
    end

    mapping.BigBlade = rifleToWeaponLocation(rifleLocation)
    mapping.BigBonk = rifleToWeaponLocation(rifleLocation)
    mapping.BigWeapon = rifleToWeaponLocation(rifleLocation)
    mapping.Shovel = rifleToShovelLocation(rifleLocation)
end

for slotType, mapping in pairs(RifleSling.AttachmentBySlotType) do
    RifleSling.applyAttachmentExtensions(slotType, mapping)
end

RifleSling.AttachmentReplacements = RifleSling.AttachmentReplacements or {}
RifleSling.AttachmentReplacements.ShovelSling = "SlingShovelBag"
RifleSling.AttachmentReplacements.BigWeaponSling = "SlingWeaponBag"
RifleSling.AttachmentReplacements.BigBladeSling = "SlingBladeBag"
RifleSling.AttachmentReplacements.BigBonkSling = "SlingBladeBag"
