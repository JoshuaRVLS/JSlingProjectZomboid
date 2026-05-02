local function applyParams(fullType, params)
    local item = ScriptManager.instance:getItem(fullType)
    if not item then
        return
    end
    for _, param in ipairs(params) do
        item:DoParam(param)
    end
end

local gearBoxes = {
    "Base.Bullets9mmBox",
    "Base.Bullets38Box",
    "Base.Bullets44Box",
    "Base.Bullets45Box",
    "Base.Bullets223Box",
    "Base.Bullets308Box",
    "Base.Bullets556Box",
    "Base.BulletsShotgunShellsBox",
    "Base.Bandaid",
    "Base.Bandage",
    "Base.AlcoholBandage",
    "Base.SutureNeedle",
}

for _, fullType in ipairs(gearBoxes) do
    applyParams(fullType, {"StaticModel = pouch", "AttachmentType = Gear"})
end

for _, fullType in ipairs({
    "Base.9mmClip",
    "Base.44Clip",
    "Base.45Clip",
    "Base.223Clip",
    "Base.308Clip",
    "Base.556Clip",
    "Base.M14Clip",
}) do
    applyParams(fullType, {"AttachmentType = Mag"})
end

for _, fullType in ipairs({
    "Base.WaterBottleFull",
    "Base.Pop",
    "Base.Pop2",
    "Base.Pop3",
    "Base.PopBottle",
    "Base.WaterPopBottle",
    "Base.WhiskeyFull",
    "Base.WaterBottleEmpty",
    "Base.PopBottleEmpty",
    "Base.WhiskeyEmpty",
}) do
    applyParams(fullType, {"AttachmentType = Bottle"})
end

applyParams("Base.Hat_GasMask", {"AttachmentType = Gear", "StaticModel = GasMask"})
applyParams("Base.Saw", {"AttachmentType = Saw", "primaryAnimMask = HoldingTorchRight", "secondaryAnimMask = HoldingTorchLeft"})
applyParams("Base.BlowTorch", {"AttachmentType = Tool", "primaryAnimMask = HoldingTorchRight", "secondaryAnimMask = HoldingTorchLeft"})
applyParams("Base.PetrolCan", {"AttachmentType = Gas"})
applyParams("Base.EmptyPetrolCan", {"AttachmentType = Gas"})
