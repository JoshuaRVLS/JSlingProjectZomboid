if not ISHotbarAttachDefinition then return end

local function addSlot(slotType, name, animset, rifleLocation)
    table.insert(ISHotbarAttachDefinition, {
        type = slotType,
        name = name,
        animset = animset,
        attachments = {
            Rifle = rifleLocation,
        },
    })
end

addSlot("Sling3", "Sling 3 Front Left", "belt left", "Sling3Rifle")
addSlot("Sling3Alt", "Sling 3 Front Right", "belt left", "Sling3Rifle2")
addSlot("Sling3Alt2", "Sling 3 Front Center", "belt left", "Sling3Rifle3")
addSlot("Sling3Alt3", "Sling 3 Back", "back", "Sling3Rifle Back")
addSlot("Sling3Alt4", "Sling 3 Right Waist", "belt left", "Sling3Rifle4")
addSlot("Sling3Alt5", "Sling 3 Left Waist", "belt left", "Sling3Rifle5")

addSlot("Sling4", "Sling 4 Front Left", "belt left", "Sling4Rifle")
addSlot("Sling4Alt", "Sling 4 Front Right", "belt left", "Sling4Rifle2")
addSlot("Sling4Alt2", "Sling 4 Front Center", "belt left", "Sling4Rifle3")
addSlot("Sling4Alt3", "Sling 4 Back", "back", "Sling4Rifle Back")
addSlot("Sling4Alt4", "Sling 4 Right Waist", "belt left", "Sling4Rifle4")
addSlot("Sling4Alt5", "Sling 4 Left Waist", "belt left", "Sling4Rifle5")
