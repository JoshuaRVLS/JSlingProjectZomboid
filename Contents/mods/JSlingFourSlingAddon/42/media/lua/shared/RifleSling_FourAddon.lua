if not RifleSling or not RifleSling.registerPoseFamily then
    return
end

RifleSling.registerPoseFamily("slot3", {
    menuLabel = "Adjust Sling Pose",
    poses = {
        { type = "Base.RifleSling_3", label = "Front Left", group = "Front Left", variantLabel = "Standard" },
        { type = "Base.RifleSling_3_Right", label = "Front Right", group = "Front Right", variantLabel = "Standard" },
        { type = "Base.RifleSling_3_Center", label = "Front Center", group = "Front Center", variantLabel = "Standard" },
        { type = "Base.RifleSling_3_Back", label = "Back", group = "Back", variantLabel = "Standard" },
        { type = "Base.RifleSling_3_Waist", label = "Right Waist", group = "Right Waist", variantLabel = "Standard" },
        { type = "Base.RifleSling_3_LeftWaist", label = "Left Waist", group = "Left Waist", variantLabel = "Standard" },
    },
    slotTypes = {
        "Sling3",
        "Sling3Alt",
        "Sling3Alt2",
        "Sling3Alt3",
        "Sling3Alt4",
        "Sling3Alt5",
    },
    attachmentsByIndex = {
        { Rifle = "Sling3Rifle" },
        { Rifle = "Sling3Rifle2" },
        { Rifle = "Sling3Rifle3" },
        { Rifle = "Sling3Rifle Back" },
        { Rifle = "Sling3Rifle4" },
        { Rifle = "Sling3Rifle5" },
    },
})

RifleSling.registerPoseFamily("slot4", {
    menuLabel = "Adjust Sling Pose",
    poses = {
        { type = "Base.RifleSling_4", label = "Front Left", group = "Front Left", variantLabel = "Standard" },
        { type = "Base.RifleSling_4_Right", label = "Front Right", group = "Front Right", variantLabel = "Standard" },
        { type = "Base.RifleSling_4_Center", label = "Front Center", group = "Front Center", variantLabel = "Standard" },
        { type = "Base.RifleSling_4_Back", label = "Back", group = "Back", variantLabel = "Standard" },
        { type = "Base.RifleSling_4_Waist", label = "Right Waist", group = "Right Waist", variantLabel = "Standard" },
        { type = "Base.RifleSling_4_LeftWaist", label = "Left Waist", group = "Left Waist", variantLabel = "Standard" },
    },
    slotTypes = {
        "Sling4",
        "Sling4Alt",
        "Sling4Alt2",
        "Sling4Alt3",
        "Sling4Alt4",
        "Sling4Alt5",
    },
    attachmentsByIndex = {
        { Rifle = "Sling4Rifle" },
        { Rifle = "Sling4Rifle2" },
        { Rifle = "Sling4Rifle3" },
        { Rifle = "Sling4Rifle Back" },
        { Rifle = "Sling4Rifle4" },
        { Rifle = "Sling4Rifle5" },
    },
})
