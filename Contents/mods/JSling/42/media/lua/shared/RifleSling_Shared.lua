RifleSling = RifleSling or {}

RifleSling.ITEM_FULL_TYPE = "Base.RifleSling"
RifleSling.SLING_ITEMS = RifleSling.SLING_ITEMS or {}
RifleSling.WEIGHT_MULTIPLIER = 0.70
RifleSling.ENDURANCE_RECOVERY_PER_SLUNG_WEAPON = 0.00003
RifleSling.MAX_ENDURANCE_RECOVERY = 0.00006
RifleSling.MODDATA_ATTACHED = "RifleSlingAttached"
RifleSling.MODDATA_BUFFED = "RifleSlingBuffApplied"
RifleSling.MODDATA_ORIGINAL_WEIGHT = "RifleSlingOriginalWeight"
RifleSling.MODDATA_SLING_ITEM_TYPE = "RifleSlingItemType"
RifleSling.MODDATA_TRANSFER_TOKEN = "RifleSlingTransferToken"
RifleSling.Commands = RifleSling.Commands or {
    SetAttached = "SetAttached",
    SetPose = "SetPose",
    WearPose = "WearPose",
    Notify = "Notify",
    Result = "Result",
    Sync = "Sync",
}
RifleSling._buffedByPlayer = RifleSling._buffedByPlayer or {}
RifleSling.PoseFamilies = RifleSling.PoseFamilies or {}
RifleSling.AttachmentBySlotType = RifleSling.AttachmentBySlotType or {}
RifleSling.ManagedAttachmentSlotTypes = RifleSling.ManagedAttachmentSlotTypes or {
    ChestRig = true,
    ChestRigRight = true,
    KnifeSheath = true,
    KnifeSheathBack = true,
    KatanaSheath = true,
    Back2 = true,
    Back3 = true,
}
RifleSling.PoseVariantLabels = RifleSling.PoseVariantLabels or {
    "Front Left",
    "Front Right",
    "Front Center",
    "Back",
    "Right Waist",
    "Left Waist",
}
RifleSling.PoseMenuLabels = RifleSling.PoseMenuLabels or {}
RifleSling.AttachmentReplacements = RifleSling.AttachmentReplacements or {
    RifleSling = "SlingRifleBag",
}

local function makePoseEntry(itemType, label, group, variantLabel)
    return {
        type = itemType,
        label = label,
        group = group or label,
        variantLabel = variantLabel or "Standard",
    }
end

local function addUnique(list, value)
    for _, existing in ipairs(list) do
        if existing == value then
            return
        end
    end
    table.insert(list, value)
end

local function markManagedSlotTypes(slotTypes)
    if not slotTypes then
        return
    end

    for _, slotType in ipairs(slotTypes) do
        RifleSling.ManagedAttachmentSlotTypes[slotType] = true
    end
end

function RifleSling.registerPoseFamily(familyKey, config)
    if not familyKey or not config or not config.slotTypes then
        return
    end

    local poses = config.poses
    local items = config.items

    if not poses and items then
        poses = {}
        local labels = config.poseLabels or RifleSling.PoseVariantLabels
        for index, itemType in ipairs(items) do
            poses[#poses + 1] = makePoseEntry(
                itemType,
                labels[index] or RifleSling.PoseVariantLabels[index] or ("Pose " .. tostring(index))
            )
        end
    end

    if not poses or not items and not poses[1] then
        return
    end

    items = items or {}
    if #items == 0 then
        for _, pose in ipairs(poses) do
            items[#items + 1] = pose.type
        end
    end

    RifleSling.PoseFamilies[familyKey] = {
        items = items,
        poses = poses,
        slotTypes = config.slotTypes,
        poseLabels = config.poseLabels or RifleSling.PoseVariantLabels,
    }
    RifleSling.PoseMenuLabels[familyKey] = config.menuLabel or ("Adjust " .. tostring(familyKey) .. " Pose")
    markManagedSlotTypes(config.slotTypes)

    for _, itemType in ipairs(items) do
        addUnique(RifleSling.SLING_ITEMS, itemType)
    end

    if config.attachmentsByIndex then
        for index, slotType in ipairs(config.slotTypes) do
            local target = RifleSling.AttachmentBySlotType[slotType] or {}
            local additions = config.attachmentsByIndex[index] or {}
            for attachmentType, locationName in pairs(additions) do
                target[attachmentType] = locationName
            end
            RifleSling.AttachmentBySlotType[slotType] = target
            if RifleSling.applyAttachmentExtensions then
                RifleSling.applyAttachmentExtensions(slotType, target)
            end
        end
    end
end

function RifleSling.isManagedAttachmentSlotType(slotType)
    if not slotType then
        return false
    end
    return RifleSling.ManagedAttachmentSlotTypes[slotType] == true
end

function RifleSling.isManagedSlingSlotType(slotType)
    if not slotType then
        return false
    end
    return string.find(tostring(slotType), "Sling") ~= nil
end

function RifleSling.getPoseOptions(familyKey)
    local family = RifleSling.PoseFamilies[familyKey]
    if not family then
        return nil
    end

    local options = {}
    for index, pose in ipairs(family.poses or {}) do
        options[#options + 1] = {
            type = pose.type,
            label = pose.label or family.poseLabels[index] or RifleSling.PoseVariantLabels[index] or ("Pose " .. tostring(index)),
            group = pose.group or pose.label or ("Pose " .. tostring(index)),
            variantLabel = pose.variantLabel or "Standard",
        }
    end
    return options
end

function RifleSling.getGroupedPoseOptions(familyKey)
    local options = RifleSling.getPoseOptions(familyKey)
    if not options then
        return nil
    end

    local groupsByName = {}
    local groups = {}

    for _, option in ipairs(options) do
        local groupName = option.group or option.label or "Pose"
        local group = groupsByName[groupName]
        if not group then
            group = {
                label = groupName,
                options = {},
            }
            groupsByName[groupName] = group
            groups[#groups + 1] = group
        end

        group.options[#group.options + 1] = option
    end

    return groups
end

function RifleSling.getPoseMenuLabel(familyKey)
    return RifleSling.PoseMenuLabels[familyKey] or "Adjust Sling Pose"
end

function RifleSling.getSortedFamilyKeys()
    local keys = {}
    for familyKey in pairs(RifleSling.PoseFamilies) do
        table.insert(keys, familyKey)
    end

    table.sort(keys, function(a, b)
        local na = tonumber(string.match(a, "(%d+)$")) or math.huge
        local nb = tonumber(string.match(b, "(%d+)$")) or math.huge
        if na == nb then
            return tostring(a) < tostring(b)
        end
        return na < nb
    end)

    return keys
end

function RifleSling.getPoseIndex(itemOrType)
    local fullType = RifleSling.getItemFullType(itemOrType)
    if not fullType then
        return nil
    end

    for _, family in pairs(RifleSling.PoseFamilies) do
        for index, itemType in ipairs(family.items) do
            if itemType == fullType then
                return index
            end
        end
    end

    return nil
end

function RifleSling.getTypeForFamilyPose(familyKey, poseIndex)
    local family = RifleSling.PoseFamilies[familyKey]
    if not family or not poseIndex then
        return nil
    end

    return family.items[poseIndex]
end

function RifleSling.getEquippedSlingFamilies(player)
    local occupied = {}
    if not player or not player.getWornItems then
        return occupied
    end

    local wornItems = player:getWornItems()
    if not wornItems then
        return occupied
    end

    for i = 0, wornItems:size() - 1 do
        local worn = wornItems:get(i)
        local item = worn and worn.getItem and worn:getItem() or nil
        local familyKey = item and RifleSling.getPoseFamily(item) or nil
        if familyKey then
            occupied[familyKey] = true
        end
    end

    return occupied
end

function RifleSling.getNextFreeWearFamily(player)
    local occupied = RifleSling.getEquippedSlingFamilies(player)
    for _, familyKey in ipairs(RifleSling.getSortedFamilyKeys()) do
        if not occupied[familyKey] then
            return familyKey
        end
    end
    return nil
end

function RifleSling.resolveWearTypeForNextFreeFamily(player, desiredType)
    local poseIndex = RifleSling.getPoseIndex(desiredType)
    if not poseIndex then
        return nil
    end

    local targetFamily = RifleSling.getNextFreeWearFamily(player)
    if not targetFamily then
        return nil
    end

    return RifleSling.getTypeForFamilyPose(targetFamily, poseIndex), targetFamily
end

RifleSling.registerPoseFamily("slot1", {
    menuLabel = "Adjust Sling Pose",
    poses = {
        makePoseEntry("Base.RifleSling", "Front Left", "Front Left", "Standard"),
        makePoseEntry("Base.RifleSling_Right", "Front Right", "Front Right", "Standard"),
        makePoseEntry("Base.RifleSling_Center", "Front Center", "Front Center", "Standard"),
        makePoseEntry("Base.RifleSling_Back", "Back", "Back", "Standard"),
        makePoseEntry("Base.RifleSling_Waist", "Right Waist", "Right Waist", "Standard"),
        makePoseEntry("Base.RifleSling_LeftWaist", "Left Waist", "Left Waist", "Standard"),
    },
    slotTypes = {
        "Sling1",
        "Sling1Alt",
        "Sling1Alt2",
        "Sling1Alt3",
        "Sling1Alt4",
        "Sling1Alt5",
    },
    attachmentsByIndex = {
        { Rifle = "Sling1Rifle" },
        { Rifle = "Sling1Rifle2" },
        { Rifle = "Sling1Rifle3" },
        { Rifle = "Sling1Rifle Back" },
        { Rifle = "Sling1Rifle4" },
        { Rifle = "Sling1Rifle5" },
    },
})

RifleSling.registerPoseFamily("slot2", {
    menuLabel = "Adjust Sling Pose",
    poses = {
        makePoseEntry("Base.RifleSling_2", "Front Left", "Front Left", "Standard"),
        makePoseEntry("Base.RifleSling_2_Right", "Front Right", "Front Right", "Standard"),
        makePoseEntry("Base.RifleSling_2_Center", "Front Center", "Front Center", "Standard"),
        makePoseEntry("Base.RifleSling_2_Back", "Back", "Back", "Standard"),
        makePoseEntry("Base.RifleSling_2_Waist", "Right Waist", "Right Waist", "Standard"),
        makePoseEntry("Base.RifleSling_2_LeftWaist", "Left Waist", "Left Waist", "Standard"),
    },
    slotTypes = {
        "Sling2",
        "Sling2Alt",
        "Sling2Alt2",
        "Sling2Alt3",
        "Sling2Alt4",
        "Sling2Alt5",
    },
    attachmentsByIndex = {
        { Rifle = "Sling2Rifle" },
        { Rifle = "Sling2Rifle2" },
        { Rifle = "Sling2Rifle3" },
        { Rifle = "Sling2Rifle Back" },
        { Rifle = "Sling2Rifle4" },
        { Rifle = "Sling2Rifle5" },
    },
})
local function safeTransmit(item)
    if not item then
        return
    end

    if item.syncItemFields then
        item:syncItemFields()
    elseif syncItemFields and getPlayer then
        local player = getPlayer()
        if player then
            syncItemFields(player, item)
        end
    end

    if item.transmitModData then
        item:transmitModData()
    end
end

local function copyItemState(sourceItem, targetItem)
    if not sourceItem or not targetItem then
        return
    end

    local oldData = sourceItem.getModData and sourceItem:getModData() or nil
    local newData = targetItem.getModData and targetItem:getModData() or nil
    if oldData and newData then
        for k, v in pairs(oldData) do
            newData[k] = v
        end
    end

    if sourceItem.getCondition and targetItem.setCondition then
        targetItem:setCondition(sourceItem:getCondition())
    end
    if sourceItem.getFavorite and targetItem.setFavorite then
        targetItem:setFavorite(sourceItem:getFavorite())
    end
    if sourceItem.isCustomName and sourceItem:isCustomName() and sourceItem.getName and targetItem.setName then
        targetItem:setName(sourceItem:getName())
    end

    local sourceVisual = sourceItem.getVisual and sourceItem:getVisual() or nil
    local targetVisual = targetItem.getVisual and targetItem:getVisual() or nil
    if sourceVisual and targetVisual then
        if targetVisual.setTint and sourceItem.getClothingItem then
            targetVisual:setTint(sourceVisual:getTint(sourceItem:getClothingItem()))
        end
        if targetVisual.setBaseTexture then
            targetVisual:setBaseTexture(sourceVisual:getBaseTexture())
        end
        if targetVisual.setTextureChoice then
            targetVisual:setTextureChoice(sourceVisual:getTextureChoice())
        end
        if targetVisual.copyDirt then
            targetVisual:copyDirt(sourceVisual)
        end
        if targetVisual.copyBlood then
            targetVisual:copyBlood(sourceVisual)
        end
        if targetVisual.copyHoles then
            targetVisual:copyHoles(sourceVisual)
        end
        if targetVisual.copyPatches then
            targetVisual:copyPatches(sourceVisual)
        end
    end

    if sourceItem.getColor and targetItem.setColor then
        targetItem:setColor(sourceItem:getColor())
    end
    if sourceItem.IsClothing and sourceItem:IsClothing() and sourceItem.getWetness and targetItem.setWetness then
        targetItem:setWetness(sourceItem:getWetness())
    end
    if sourceItem.copyPatchesTo and targetItem.IsClothing and targetItem:IsClothing() then
        sourceItem:copyPatchesTo(targetItem)
    end
    if targetItem.synchWithVisual then
        targetItem:synchWithVisual()
    end
end

local function removeInventoryItemFully(player, item)
    if not item then
        return false
    end

    local container = item.getContainer and item:getContainer() or nil
    if not container then
        return false
    end

    if player and player.removeFromHands then
        player:removeFromHands(item)
    end
    if player and player.isEquippedClothing and player:isEquippedClothing(item) and player.removeWornItem then
        player:removeWornItem(item, false)
    end

    if container.DoRemoveItem then
        container:DoRemoveItem(item)
    elseif container.Remove then
        container:Remove(item)
    end

    if container.contains and container:contains(item) and container.Remove then
        container:Remove(item)
    end

    if container.setDrawDirty then
        container:setDrawDirty(true)
    end

    return container.contains and not container:contains(item)
end

local function finalizeClothingUpdate(player, item)
    if not player then
        return
    end

    if triggerEvent then
        triggerEvent("OnClothingUpdated", player)
    end
    if sendClothing and item and item.getBodyLocation then
        sendClothing(player, item:getBodyLocation(), item)
    end
    if syncVisuals then
        syncVisuals(player)
    end
end

local function getPlayerKey(player)
    if not player then
        return "0"
    end

    if player.getOnlineID then
        local onlineId = player:getOnlineID()
        if onlineId and onlineId >= 0 then
            return tostring(onlineId)
        end
    end

    if player.getPlayerNum then
        return tostring(player:getPlayerNum())
    end

    return "0"
end

function RifleSling.getOnlineId(player)
    if not player or not player.getOnlineID then
        return -1
    end

    local onlineId = player:getOnlineID()
    if onlineId and onlineId >= 0 then
        return onlineId
    end

    return -1
end

local function getItemKey(item)
    if item and item.getID then
        return tostring(item:getID())
    end
    return tostring(item)
end

local function makeTransferToken(player, item, targetType)
    local playerPart = player and getPlayerKey(player) or "0"
    local itemPart = item and item.getID and tostring(item:getID()) or tostring(ZombRand(1000000))
    local typePart = tostring(targetType or "sling")
    local randPart = tostring(ZombRand(1000000))
    return table.concat({ "jsling", playerPart, itemPart, typePart, randPart }, ":")
end

function RifleSling.getItemFullType(itemOrType)
    if type(itemOrType) == "string" then
        return itemOrType
    end
    if itemOrType and itemOrType.getFullType then
        return itemOrType:getFullType()
    end
    return nil
end

local function collectManagedSlingItems(container, token, results)
    if not container or not results then
        return
    end

    local items = container.getItems and container:getItems() or nil
    if not items then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(item) then
            local modData = item.getModData and item:getModData() or nil
            if modData and modData[RifleSling.MODDATA_TRANSFER_TOKEN] == token then
                results[#results + 1] = item
            end
        end

        if item and item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
            collectManagedSlingItems(item:getInventory(), token, results)
        end
    end
end

function RifleSling.cleanupTransferredDuplicates(player, token, preferredItem)
    if not player or not token then
        return
    end

    local inv = player.getInventory and player:getInventory() or nil
    if not inv then
        return
    end

    local matches = {}
    collectManagedSlingItems(inv, token, matches)
    if #matches == 0 then
        return
    end

    local keep = preferredItem
    if not keep then
        for _, item in ipairs(matches) do
            if player.isEquippedClothing and player:isEquippedClothing(item) then
                keep = item
                break
            end
        end
    end
    keep = keep or matches[1]

    for _, item in ipairs(matches) do
        if item ~= keep then
            removeInventoryItemFully(player, item)
        end
    end

    local keepData = keep and keep.getModData and keep:getModData() or nil
    if keepData then
        keepData[RifleSling.MODDATA_TRANSFER_TOKEN] = nil
    end
    safeTransmit(keep)
end

function RifleSling.getPoseFamily(itemOrType)
    local fullType = RifleSling.getItemFullType(itemOrType)
    if not fullType then
        return nil
    end

    for familyKey, family in pairs(RifleSling.PoseFamilies) do
        for _, itemType in ipairs(family.items) do
            if itemType == fullType then
                return familyKey, family
            end
        end
    end

    return nil
end

function RifleSling.getPoseSlotType(itemOrType)
    local fullType = RifleSling.getItemFullType(itemOrType)
    if not fullType then
        return nil
    end

    for _, family in pairs(RifleSling.PoseFamilies) do
        for index, itemType in ipairs(family.items) do
            if itemType == fullType then
                return family.slotTypes[index]
            end
        end
    end

    return nil
end

function RifleSling.isManagedSlingItem(itemOrType)
    return RifleSling.getPoseFamily(itemOrType) ~= nil
end

function RifleSling.getPoseFamilySlotTypes(itemOrType)
    local _, family = RifleSling.getPoseFamily(itemOrType)
    return family and family.slotTypes or nil
end

function RifleSling.findAttachedWeaponForSlot(player, slotType)
    if not player or not player.getAttachedItems or not slotType then
        return nil
    end

    local attachedItems = player:getAttachedItems()
    if not attachedItems then
        return nil
    end

    for i = 0, attachedItems:size() - 1 do
        local attached = attachedItems:get(i)
        local item = attached and attached.getItem and attached:getItem() or nil
        if item and item.getAttachedSlotType and item:getAttachedSlotType() == slotType then
            return item
        end
    end

    return nil
end

function RifleSling.findAttachedWeaponForFamily(player, itemOrType)
    if not player then
        return nil
    end

    local slotTypes = RifleSling.getPoseFamilySlotTypes(itemOrType)
    if not slotTypes then
        return nil
    end

    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if not attachedItems then
        return nil
    end

    for i = 0, attachedItems:size() - 1 do
        local attached = attachedItems:get(i)
        local item = attached and attached.getItem and attached:getItem() or nil
        if item and item.getAttachedSlotType then
            local itemSlotType = item:getAttachedSlotType()
            for _, familySlotType in ipairs(slotTypes) do
                if itemSlotType == familySlotType then
                    return {
                        weapon = item,
                        slotType = itemSlotType,
                        slotIndex = item.getAttachedSlot and item:getAttachedSlot() or -1,
                    }
                end
            end
        end
    end

    return nil
end

function RifleSling.resolveAttachmentSlot(weapon, slotType)
    if not weapon or not weapon.getAttachmentType then
        return nil
    end

    local attachmentType = weapon:getAttachmentType()
    local mapping = RifleSling.AttachmentBySlotType[slotType]
    if not attachmentType or not mapping then
        return nil
    end

    local slotName = mapping[attachmentType]
    if not slotName then
        return nil
    end

    if string.find(slotName, " Back") then
        local replacementKey = attachmentType .. "Sling"
        local replacement = RifleSling.AttachmentReplacements[replacementKey]
        if replacement then
            slotName = replacement
        end
    end

    return slotName
end

function RifleSling.moveAttachedWeaponToPose(player, weapon, oldSlotType, newSlotType, oldSlotIndex)
    if not player or not weapon or not oldSlotType or not newSlotType or oldSlotType == newSlotType then
        return
    end

    local newSlotName = RifleSling.resolveAttachmentSlot(weapon, newSlotType)
    if not newSlotName then
        return
    end

    if player.removeAttachedItem then
        player:removeAttachedItem(weapon)
    end

    if weapon.setAttachedSlot then
        weapon:setAttachedSlot(-1)
    end
    if weapon.setAttachedSlotType then
        weapon:setAttachedSlotType(nil)
    end
    if weapon.setAttachedToModel then
        weapon:setAttachedToModel(nil)
    end

    if player.setAttachedItem then
        player:setAttachedItem(newSlotName, weapon)
    end

    if weapon.setAttachedSlot then
        weapon:setAttachedSlot(oldSlotIndex or -1)
    end
    if weapon.setAttachedSlotType then
        weapon:setAttachedSlotType(newSlotType)
    end
    if weapon.setAttachedToModel then
        weapon:setAttachedToModel(newSlotName)
    end
end

function RifleSling.swapSlingPose(player, oldItem, newType, detachedWeapon, detachedSlotType, detachedSlotIndex)
    if not player or not oldItem or not newType then
        return nil
    end

    local inv = player:getInventory()
    if not inv then
        return nil
    end

    local oldType = RifleSling.getItemFullType(oldItem)
    if oldType == newType then
        return oldItem
    end

    local oldSlotType = RifleSling.getPoseSlotType(oldType)
    local newSlotType = RifleSling.getPoseSlotType(newType)
    local attachedRecord = RifleSling.findAttachedWeaponForFamily(player, oldType)
    if not attachedRecord and detachedWeapon and detachedSlotType then
        attachedRecord = {
            weapon = detachedWeapon,
            slotType = detachedSlotType,
            slotIndex = detachedSlotIndex or -1,
        }
    end

    local bodyLocation = oldItem.getBodyLocation and oldItem:getBodyLocation() or nil
    local wasEquipped = false
    if bodyLocation and player.isEquippedClothing and player:isEquippedClothing(oldItem) then
        wasEquipped = true
        if player.removeWornItem then
            player:removeWornItem(oldItem)
        end
    end

    local newItem = inv:AddItem(newType)
    if not newItem then
        return nil
    end

    local transferToken = makeTransferToken(player, oldItem, newType)
    local oldData = oldItem.getModData and oldItem:getModData() or nil
    if oldData then
        oldData[RifleSling.MODDATA_TRANSFER_TOKEN] = transferToken
    end

    copyItemState(oldItem, newItem)
    local newData = newItem.getModData and newItem:getModData() or nil
    if newData then
        newData[RifleSling.MODDATA_TRANSFER_TOKEN] = transferToken
    end

    removeInventoryItemFully(player, oldItem)

    if wasEquipped and bodyLocation and player.setWornItem then
        player:setWornItem(bodyLocation, newItem)
        finalizeClothingUpdate(player, newItem)
    end

    if attachedRecord and attachedRecord.weapon then
        RifleSling.moveAttachedWeaponToPose(
            player,
            attachedRecord.weapon,
            attachedRecord.slotType or oldSlotType,
            newSlotType,
            attachedRecord.slotIndex
        )
    end

    if player.resetModelNextFrame then
        player:resetModelNextFrame()
    elseif player.resetModel then
        player:resetModel()
    end

    RifleSling.cleanupTransferredDuplicates(player, transferToken, newItem)

    return newItem
end

function RifleSling.wearSlingToNextFreeFamily(player, oldItem, desiredType)
    if not player or not oldItem or not desiredType then
        return nil, "Invalid sling item"
    end

    local inv = player.getInventory and player:getInventory() or nil
    if not inv or not inv.contains or not inv:contains(oldItem) then
        return nil, "Could not find sling item"
    end

    if player.isEquippedClothing and player:isEquippedClothing(oldItem) then
        return oldItem, "Sling is already worn"
    end

    local resolvedType, familyKey = RifleSling.resolveWearTypeForNextFreeFamily(player, desiredType)
    if not resolvedType or not familyKey then
        return nil, "No free sling slot available"
    end

    local wearItem = oldItem
    if oldItem.getFullType and oldItem:getFullType() ~= resolvedType then
        wearItem = inv:AddItem(resolvedType)
        if not wearItem then
            return nil, "Could not prepare sling pose"
        end

        local transferToken = makeTransferToken(player, oldItem, resolvedType)
        local oldData = oldItem.getModData and oldItem:getModData() or nil
        if oldData then
            oldData[RifleSling.MODDATA_TRANSFER_TOKEN] = transferToken
        end

        copyItemState(oldItem, wearItem)
        local newData = wearItem.getModData and wearItem:getModData() or nil
        if newData then
            newData[RifleSling.MODDATA_TRANSFER_TOKEN] = transferToken
        end

        removeInventoryItemFully(player, oldItem)
        RifleSling.cleanupTransferredDuplicates(player, transferToken, wearItem)
    end

    local bodyLocation = wearItem.getBodyLocation and wearItem:getBodyLocation() or nil
    if not bodyLocation or not player.setWornItem then
        return nil, "Could not wear sling"
    end

    player:setWornItem(bodyLocation, wearItem)
    finalizeClothingUpdate(player, wearItem)

    if player.resetModelNextFrame then
        player:resetModelNextFrame()
    elseif player.resetModel then
        player:resetModel()
    end

    return wearItem, familyKey
end

function RifleSling.isLongGun(item)
    if not item or not instanceof(item, "HandWeapon") then
        return false
    end

    if item.isRanged and not item:isRanged() then
        return false
    end

    local swingAnim = item.getSwingAnim and item:getSwingAnim() or nil
    if swingAnim == "Rifle" or swingAnim == "Shotgun" then
        return true
    end

    if item.isTwoHandWeapon and item:isTwoHandWeapon() then
        return true
    end

    return false
end

function RifleSling.isSupportedSlingWeapon(item)
    if not item or not instanceof(item, "HandWeapon") then
        return false
    end

    if RifleSling.isLongGun(item) then
        return true
    end

    local attachmentType = item.getAttachmentType and item:getAttachmentType() or nil
    if not attachmentType then
        return false
    end

    for slotType, mapping in pairs(RifleSling.AttachmentBySlotType or {}) do
        if RifleSling.isManagedSlingSlotType and RifleSling.isManagedSlingSlotType(slotType)
            and mapping and mapping[attachmentType] then
            return true
        end
    end

    return false
end

function RifleSling.isSlingAttached(weapon)
    if not weapon then
        return false
    end

    local modData = weapon:getModData()
    return modData and modData[RifleSling.MODDATA_ATTACHED] == true
end

function RifleSling.findSlingInInventory(player)
    if not player or not player.getInventory then
        return nil
    end

    local inv = player:getInventory()
    if not inv then
        return nil
    end

    for _, fullType in ipairs(RifleSling.SLING_ITEMS) do
        local found = inv:FindAndReturn(fullType)
        if found then
            return found
        end
    end

    return nil
end

function RifleSling.setSlingAttached(weapon, attached)
    if not weapon then
        return
    end

    local modData = weapon:getModData()
    modData[RifleSling.MODDATA_ATTACHED] = attached and true or false
    safeTransmit(weapon)
end

function RifleSling.applyWeaponBuff(weapon)
    if not weapon then
        return
    end

    local modData = weapon:getModData()
    if modData[RifleSling.MODDATA_BUFFED] then
        return
    end

    local originalWeight = weapon.getActualWeight and weapon:getActualWeight() or weapon:getWeight()
    if not originalWeight then
        return
    end

    modData[RifleSling.MODDATA_ORIGINAL_WEIGHT] = originalWeight

    local reducedWeight = math.max(0.1, originalWeight * RifleSling.WEIGHT_MULTIPLIER)
    if weapon.setActualWeight then
        weapon:setActualWeight(reducedWeight)
    end
    if weapon.setWeight then
        weapon:setWeight(reducedWeight)
    end

    modData[RifleSling.MODDATA_BUFFED] = true
    safeTransmit(weapon)
end

function RifleSling.restoreWeaponBuff(weapon)
    if not weapon then
        return
    end

    local modData = weapon:getModData()
    if not modData[RifleSling.MODDATA_BUFFED] then
        return
    end

    local originalWeight = tonumber(modData[RifleSling.MODDATA_ORIGINAL_WEIGHT])
    if originalWeight then
        if weapon.setActualWeight then
            weapon:setActualWeight(originalWeight)
        end
        if weapon.setWeight then
            weapon:setWeight(originalWeight)
        end
    end

    modData[RifleSling.MODDATA_BUFFED] = nil
    modData[RifleSling.MODDATA_ORIGINAL_WEIGHT] = nil
    safeTransmit(weapon)
end

function RifleSling.refreshPlayerBuffs(player)
    if not player then
        return
    end

    local playerKey = getPlayerKey(player)
    local previous = RifleSling._buffedByPlayer[playerKey] or {}
    local current = {}
    local slungWeaponCount = 0

    local function processHandItem(item)
        if not item or not RifleSling.isLongGun(item) then
            return
        end

        local itemKey = getItemKey(item)
        if RifleSling.isSlingAttached(item) then
            RifleSling.applyWeaponBuff(item)
            current[itemKey] = item
        else
            RifleSling.restoreWeaponBuff(item)
        end
    end

    processHandItem(player:getPrimaryHandItem())
    processHandItem(player:getSecondaryHandItem())

    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local attached = attachedItems:get(i)
            local attachedItem = attached and attached.getItem and attached:getItem() or nil
            if attachedItem and RifleSling.isLongGun(attachedItem) and RifleSling.isSlingAttached(attachedItem) then
                local itemKey = getItemKey(attachedItem)
                RifleSling.applyWeaponBuff(attachedItem)
                current[itemKey] = attachedItem
                slungWeaponCount = slungWeaponCount + 1
            end
        end
    end

    for itemKey, oldWeapon in pairs(previous) do
        if not current[itemKey] then
            RifleSling.restoreWeaponBuff(oldWeapon)
        end
    end

    RifleSling._buffedByPlayer[playerKey] = current

    if slungWeaponCount > 0 and player.getStats then
        local isAiming = player.isAiming and player:isAiming() or false
        local isRunning = player.isRunning and player:isRunning() or false
        local isSprinting = player.isSprinting and player:isSprinting() or false
        local isAsleep = player.isAsleep and player:isAsleep() or false
        if not isAiming and not isRunning and not isSprinting and not isAsleep then
            local stats = player:getStats()
            if stats and stats.getEndurance and stats.setEndurance then
                local currentEndurance = stats:getEndurance()
                local bonus = math.min(
                    RifleSling.MAX_ENDURANCE_RECOVERY,
                    slungWeaponCount * RifleSling.ENDURANCE_RECOVERY_PER_SLUNG_WEAPON
                )
                if currentEndurance and currentEndurance < 1.0 then
                    stats:setEndurance(math.min(1.0, currentEndurance + bonus))
                end
            end
        end
    end
end

function RifleSling.reconcileManagedWornItems(player)
    if not player or not player.getInventory or not player.getWornItems then
        return false
    end

    local isClientOnly = isClient and isClient() and not (isServer and isServer())
    if isClientOnly then
        if not (player.isLocalPlayer and player:isLocalPlayer()) then
            return false
        end
    end

    local inv = player:getInventory()
    local wornItems = player:getWornItems()
    if not inv or not wornItems or not inv.contains or not inv.AddItem then
        return false
    end

    local repaired = false

    for i = 0, wornItems:size() - 1 do
        local worn = wornItems:get(i)
        local item = worn and worn.getItem and worn:getItem() or nil
        if item and RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(item) and not inv:contains(item) then
            local container = item.getContainer and item:getContainer() or nil
            if container and container ~= inv then
                if container.DoRemoveItem then
                    container:DoRemoveItem(item)
                elseif container.Remove then
                    container:Remove(item)
                end
            end

            inv:AddItem(item)
            repaired = true
            if not isClientOnly then
                safeTransmit(item)
            end
        end
    end

    if repaired then
        finalizeClothingUpdate(player)
        if player.resetModelNextFrame then
            player:resetModelNextFrame()
        elseif player.resetModel then
            player:resetModel()
        end
    end

    return repaired
end

function RifleSling.attachToWeapon(player, weapon, slingItem)
    if not player or not weapon then
        return false, "Invalid player or weapon"
    end

    if not RifleSling.isSupportedSlingWeapon or not RifleSling.isSupportedSlingWeapon(weapon) then
        return false, "Only supported sling weapons can use a rifle sling"
    end

    if RifleSling.isSlingAttached(weapon) then
        return false, "Sling is already attached"
    end

    local inv = player:getInventory()
    local sling = slingItem or RifleSling.findSlingInInventory(player)
    if not sling then
        return false, "You need a Rifle Sling item"
    end

    local slingType = sling.getFullType and sling:getFullType() or RifleSling.ITEM_FULL_TYPE
    RifleSling.setSlingAttached(weapon, true)
    weapon:getModData()[RifleSling.MODDATA_SLING_ITEM_TYPE] = slingType
    safeTransmit(weapon)

    if inv and inv.contains and inv:contains(sling) then
        inv:Remove(sling)
    end

    RifleSling.refreshPlayerBuffs(player)
    return true, "Sling attached"
end

function RifleSling.attachToManagedSling(player, weapon, slingItemOrType)
    if not player or not weapon then
        return false, "Invalid player or weapon"
    end

    if not RifleSling.isSupportedSlingWeapon or not RifleSling.isSupportedSlingWeapon(weapon) then
        return false, "Only supported sling weapons can use a rifle sling"
    end

    if RifleSling.isSlingAttached(weapon) then
        return false, "Sling is already attached"
    end

    RifleSling.setSlingAttached(weapon, true)

    local slingType = RifleSling.getItemFullType and RifleSling.getItemFullType(slingItemOrType) or nil
    if slingType then
        weapon:getModData()[RifleSling.MODDATA_SLING_ITEM_TYPE] = slingType
    end

    safeTransmit(weapon)
    RifleSling.refreshPlayerBuffs(player)
    return true, "Sling attached"
end

function RifleSling.detachFromWeapon(player, weapon)
    if not player or not weapon then
        return false, "Invalid player or weapon"
    end

    if not RifleSling.isSlingAttached(weapon) then
        return false, "No sling is attached"
    end

    RifleSling.setSlingAttached(weapon, false)
    RifleSling.restoreWeaponBuff(weapon)

    local inv = player:getInventory()
    if inv and inv.AddItem then
        local slingType = weapon:getModData()[RifleSling.MODDATA_SLING_ITEM_TYPE] or RifleSling.ITEM_FULL_TYPE
        inv:AddItem(slingType)
    end

    weapon:getModData()[RifleSling.MODDATA_SLING_ITEM_TYPE] = nil
    safeTransmit(weapon)

    RifleSling.refreshPlayerBuffs(player)
    return true, "Sling removed"
end

function RifleSling.detachFromManagedSling(player, weapon)
    if not player or not weapon then
        return false, "Invalid player or weapon"
    end

    if not RifleSling.isSlingAttached(weapon) then
        return false, "No sling is attached"
    end

    RifleSling.setSlingAttached(weapon, false)
    RifleSling.restoreWeaponBuff(weapon)
    weapon:getModData()[RifleSling.MODDATA_SLING_ITEM_TYPE] = nil
    safeTransmit(weapon)

    RifleSling.refreshPlayerBuffs(player)
    return true, "Sling removed"
end

function RifleSling.findItemById(player, itemId)
    if not player or not itemId then
        return nil
    end

    local numericId = tonumber(itemId)
    if not numericId then
        return nil
    end

    local function matches(item)
        return item and item.getID and item:getID() == numericId
    end

    local function findInContainer(container)
        if not container then
            return nil
        end

        local items = container:getItems()
        if not items then
            return nil
        end

        for i = 0, items:size() - 1 do
            local item = items:get(i)
            if item and item.getID and item:getID() == numericId then
                return item
            end

            if item and item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
                local nested = findInContainer(item:getInventory())
                if nested then
                    return nested
                end
            end
        end

        return nil
    end

    local primary = player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    if matches(primary) then
        return primary
    end

    local secondary = player.getSecondaryHandItem and player:getSecondaryHandItem() or nil
    if matches(secondary) then
        return secondary
    end

    local wornItems = player.getWornItems and player:getWornItems() or nil
    if wornItems then
        for i = 0, wornItems:size() - 1 do
            local worn = wornItems:get(i)
            local wornItem = worn and worn.getItem and worn:getItem() or nil
            if matches(wornItem) then
                return wornItem
            end
        end
    end

    local attachedItems = player.getAttachedItems and player:getAttachedItems() or nil
    if attachedItems then
        for i = 0, attachedItems:size() - 1 do
            local attached = attachedItems:get(i)
            local attachedItem = attached and attached.getItem and attached:getItem() or nil
            if matches(attachedItem) then
                return attachedItem
            end
        end
    end

    return findInContainer(player:getInventory())
end

local function onHandItemChanged(player, _item)
    RifleSling.refreshPlayerBuffs(player)
end

local function onPlayerUpdate(player)
    RifleSling.reconcileManagedWornItems(player)
    RifleSling.refreshPlayerBuffs(player)
end

if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(onPlayerUpdate)
end
if Events and Events.OnEquipPrimary then
    Events.OnEquipPrimary.Add(onHandItemChanged)
end
if Events and Events.OnEquipSecondary then
    Events.OnEquipSecondary.Add(onHandItemChanged)
end
