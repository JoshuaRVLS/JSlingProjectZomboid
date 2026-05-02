if not ISHotbarAttachDefinition then return end

local function addSlingSlot(slotType, name, animset, rifleLocation)
    table.insert(ISHotbarAttachDefinition, {
        type = slotType,
        name = name,
        animset = animset,
        attachments = {
            Rifle = rifleLocation,
        },
    })
end

addSlingSlot("Sling1", "Sling 1 Front Left", "belt left", "Sling1Rifle")
addSlingSlot("Sling1Alt", "Sling 1 Front Right", "belt left", "Sling1Rifle2")
addSlingSlot("Sling1Alt2", "Sling 1 Front Center", "belt left", "Sling1Rifle3")
addSlingSlot("Sling1Alt3", "Sling 1 Back", "back", "Sling1Rifle Back")
addSlingSlot("Sling1Alt4", "Sling 1 Right Waist", "belt left", "Sling1Rifle4")
addSlingSlot("Sling1Alt5", "Sling 1 Left Waist", "belt left", "Sling1Rifle5")

addSlingSlot("Sling2", "Sling 2 Front Left", "belt left", "Sling2Rifle")
addSlingSlot("Sling2Alt", "Sling 2 Front Right", "belt left", "Sling2Rifle2")
addSlingSlot("Sling2Alt2", "Sling 2 Front Center", "belt left", "Sling2Rifle3")
addSlingSlot("Sling2Alt3", "Sling 2 Back", "back", "Sling2Rifle Back")
addSlingSlot("Sling2Alt4", "Sling 2 Right Waist", "belt left", "Sling2Rifle4")
addSlingSlot("Sling2Alt5", "Sling 2 Left Waist", "belt left", "Sling2Rifle5")

local extraSlots = {
    {
        type = "ChestRig",
        name = "Chest Rig Left",
        animset = "belt left",
        attachments = {
            Mag = "Chest Rig Mag Left",
            Holster = "Chest Rig",
            Knife = "Chest Rig Knife",
            Nightstick = "Nightstick Left",
            BigBlade = "Blade On Back",
            Shotgun = "Shotgun On Back",
            Gear = "Chest Rig Gear",
            ChestLight = "Chest Light",
            Walkie = "Chest Rig Walkie",
            Bottle = "Chest Rig Bottle",
            Screwdriver = "Chest Rig Walkie",
        },
    },
    {
        type = "ChestRigRight",
        name = "Chest Rig Right",
        animset = "belt right",
        attachments = {
            Mag = "Chest Rig Mag Right",
            ChestLight = "Chest Light Right",
            Knife = "Belt Left Upside",
            BigBlade = "Blade On Back",
            Walkie = "Chest Rig Walkie Right",
            Bottle = "Chest Rig Bottle Right",
            Flashlight = "Belt Left",
            Screwdriver = "Chest Rig Walkie Right",
            Gear = "Chest Rig Gear Right",
        },
    },
    {
        type = "KnifeSheath",
        name = "Knife Sheath",
        animset = "belt right",
        attachments = {
            Knife = "Claf in Sheath (Leg)",
            NotKnife = "Claf in Sheath (Leg)",
            MeatCleaver = "Claf in Sheath (Leg)",
            Screwdriver = "Knife Sheath",
            BigBlade = "Claf in Sheath (Leg)",
        },
    },
    {
        type = "KnifeSheathBack",
        name = "Knife Sheath Back",
        animset = "belt right",
        attachments = {
            Knife = "Claf in Sheath (Back)",
            NotKnife = "Claf in Sheath (Back)",
            MeatCleaver = "Claf in Sheath (Back)",
            Screwdriver = "Knife Sheath",
            BigBlade = "Claf in Sheath (Back)",
        },
    },
    {
        type = "KatanaSheath",
        name = "Katana Sheath",
        animset = "back",
        attachments = {
            Sword = "Katana in Sheath",
            BigBlade = "Katana in Sheath",
            BigBonk = "Blade On Back",
        },
    },
    {
        type = "Back2",
        name = "Tactical Vest Rifle",
        animset = "back",
        attachments = {
            Rifle = "Rifle On Back2",
            Shotgun = "Rifle On Back2",
        },
    },
    {
        type = "Back3",
        name = "Tactical Vest Melee",
        animset = "back",
        attachments = {
            BigBlade = "Blade On Back2",
            BigBonk = "Blade On Back2",
            BigWeapon = "Blade On Back2",
            Shovel = "Blade On Back2",
        },
    },
}

for _, def in ipairs(extraSlots) do
    table.insert(ISHotbarAttachDefinition, def)
end

local replacements = {
    RifleSling = "SlingRifleBag",
}

local replacementTable = ISHotbarAttachDefinition.replacements
    and ISHotbarAttachDefinition.replacements[1]
    and ISHotbarAttachDefinition.replacements[1].replacement

if replacementTable then
    for k, v in pairs(replacements) do
        replacementTable[k] = v
    end
end

for _, definition in ipairs(ISHotbarAttachDefinition) do
    if definition.type == "Back" and definition.attachments and not definition.attachments.BigBonk then
        definition.attachments.BigBonk = "Blade On Back"
    end
end
