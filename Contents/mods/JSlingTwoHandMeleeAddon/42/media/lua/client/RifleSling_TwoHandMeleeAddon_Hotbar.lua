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

local function isSlingSlotDef(slotDef)
    if not slotDef or not slotDef.type then
        return false
    end

    return string.find(slotDef.type, "Sling") ~= nil
end

local function patchDefinitions()
    if not ISHotbarAttachDefinition then
        return
    end

    for _, slotDef in ipairs(ISHotbarAttachDefinition) do
        local rifleLocation = slotDef.attachments and slotDef.attachments.Rifle or nil
        if isSlingSlotDef(slotDef) and rifleLocation then
            slotDef.attachments = slotDef.attachments or {}
            slotDef.attachments.BigBlade = rifleToWeaponLocation(rifleLocation)
            slotDef.attachments.BigBonk = rifleToWeaponLocation(rifleLocation)
            slotDef.attachments.BigWeapon = rifleToWeaponLocation(rifleLocation)
            slotDef.attachments.Shovel = rifleToShovelLocation(rifleLocation)
        end
    end

    local replacements = {
        ShovelSling = "SlingShovelBag",
        BigWeaponSling = "SlingWeaponBag",
        BigBladeSling = "SlingBladeBag",
        BigBonkSling = "SlingBladeBag",
    }

    if ISHotbarAttachDefinition.replacements then
        for _, entry in ipairs(ISHotbarAttachDefinition.replacements) do
            local replacementTable = entry and entry.replacement or nil
            local entryType = entry and entry.type or nil
            if replacementTable and entryType and string.find(entryType, "Sling") then
                for key, value in pairs(replacements) do
                    replacementTable[key] = value
                end
            end
        end
    end
end

patchDefinitions()

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(patchDefinitions)
end
