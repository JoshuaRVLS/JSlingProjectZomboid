if not RifleSling then
    return
end

require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/RifleSling_ChangePoseAction"
require "TimedActions/RifleSling_DetachSlingWeaponAction"
require "TimedActions/RifleSling_WearPoseAction"

local function buildToolTip(description)
    if not ISWorldObjectContextMenu or not ISWorldObjectContextMenu.addToolTip then
        return nil
    end

    local tooltip = ISWorldObjectContextMenu.addToolTip()
    tooltip.description = description
    return tooltip
end

local function getFamilySlotLabel(familyKey)
    local slotNumber = tonumber(string.match(tostring(familyKey), "(%d+)$"))
    if slotNumber then
        return "Sling Slot " .. tostring(slotNumber)
    end
    return "Sling Slot"
end

local function notify(player, message, ok)
    if not player or not message then
        return
    end

    if HaloTextHelper and HaloTextHelper.addTextWithArrow and HaloTextHelper.getColorGreen and HaloTextHelper.getColorRed then
        local color = ok and HaloTextHelper.getColorGreen() or HaloTextHelper.getColorRed()
        HaloTextHelper.addTextWithArrow(player, message, ok == true, color)
        return
    end

    if player.Say then
        player:Say(message)
    end
end

local function unwrapContextItem(entry)
    if not entry then
        return nil
    end

    if instanceof(entry, "InventoryItem") then
        return entry
    end

    if type(entry) == "table" then
        if entry.items then
            if type(entry.items) == "table" and #entry.items > 0 and instanceof(entry.items[1], "InventoryItem") then
                return entry.items[1]
            end
            if entry.items.get and entry.items.size and entry.items:size() > 0 then
                local first = entry.items:get(0)
                if first and instanceof(first, "InventoryItem") then
                    return first
                end
            end
        end
        if entry.item and instanceof(entry.item, "InventoryItem") then
            return entry.item
        end
    end

    return nil
end

local function resolveManagedSlingItem(player, item)
    if not player or not item then
        return nil
    end

    if RifleSling.resolveManagedClientItem then
        local resolved = RifleSling.resolveManagedClientItem(player, item)
        if resolved then
            return resolved
        end
    end

    if RifleSling.findItemById and item.getID then
        local resolved = RifleSling.findItemById(player, item:getID())
        if resolved then
            return resolved
        end
    end

    return item
end

local function isItemInPlayerInventory(player, item)
    if not player or not item then
        return false
    end

    local inv = player.getInventory and player:getInventory() or nil
    return inv and inv.contains and inv:contains(item) or false
end

local function isItemOwnedOrWornByPlayer(player, item)
    if not player or not item then
        return false
    end

    if isItemInPlayerInventory(player, item) then
        return true
    end

    if player.isEquippedClothing and player:isEquippedClothing(item) then
        return true
    end

    return false
end

local function ensureLocalActionState()
    RifleSling._localQueuedActions = RifleSling._localQueuedActions or {}
end

function RifleSling.markLocalQueuedAction(action, itemId)
    if not action or itemId == nil then
        return
    end

    ensureLocalActionState()
    RifleSling._localQueuedActions[action .. ":" .. tostring(itemId)] = true
end

function RifleSling.clearLocalQueuedAction(action, itemId)
    if not action or itemId == nil or not RifleSling._localQueuedActions then
        return
    end

    RifleSling._localQueuedActions[action .. ":" .. tostring(itemId)] = nil
end

local function hasQueuedOrPendingAction(action, itemId)
    if not action or itemId == nil then
        return false
    end

    local key = action .. ":" .. tostring(itemId)
    if RifleSling._localQueuedActions and RifleSling._localQueuedActions[key] then
        return true
    end

    return RifleSling.hasPendingAction and RifleSling.hasPendingAction(action, itemId) or false
end

local function getSingleSelectedManagedSling(items)
    if not items then
        return nil
    end

    local unique = {}
    local count = 0

    local function consider(entry)
        local candidate = unwrapContextItem(entry)
        if not candidate or not candidate.getID or not RifleSling.isManagedSlingItem(candidate) then
            return
        end

        local itemId = candidate:getID()
        if unique[itemId] then
            return
        end

        unique[itemId] = candidate
        count = count + 1
    end

    if items.get and items.size then
        for i = 0, items:size() - 1 do
            consider(items:get(i))
        end
    else
        for _, entry in ipairs(items) do
            consider(entry)
        end
    end

    if count ~= 1 then
        return nil
    end

    for _, candidate in pairs(unique) do
        return candidate
    end

    return nil
end

local function onSelectPose(player, item, newType)
    if not player or not item or not newType then
        return
    end

    item = resolveManagedSlingItem(player, item)
    if not item then
        return
    end

    local isUsable = false
    local inv = player.getInventory and player:getInventory() or nil
    if inv and inv.contains and inv:contains(item) then
        isUsable = true
    elseif player.isEquippedClothing and player:isEquippedClothing(item) then
        isUsable = true
    end

    if not isUsable then
        return
    end

    if hasQueuedOrPendingAction("pose", item:getID()) then
        return
    end

    local attachedRecord = RifleSling.findAttachedWeaponForFamily and RifleSling.findAttachedWeaponForFamily(player, item) or nil
    RifleSling.markLocalQueuedAction("pose", item:getID())
    if attachedRecord and attachedRecord.weapon then
        ISTimedActionQueue.add(RifleSling_DetachSlingWeaponAction:new(player, attachedRecord.weapon))
        ISTimedActionQueue.add(RifleSling_ChangePoseAction:new(
            player,
            item,
            newType,
            attachedRecord.weapon:getID(),
            attachedRecord.slotType,
            attachedRecord.slotIndex
        ))
        return
    end

    ISTimedActionQueue.add(RifleSling_ChangePoseAction:new(player, item, newType))
end

local function onWearPose(playerIndex, item, newType)
    local player = getSpecificPlayer(playerIndex)
    if not player or not item or not newType then
        return
    end

    item = resolveManagedSlingItem(player, item)
    if not item then
        return
    end

    local wearType = RifleSling.resolveWearTypeForNextFreeFamily and RifleSling.resolveWearTypeForNextFreeFamily(player, newType) or nil
    if not wearType then
        notify(player, "No free sling slot available", false)
        return
    end

    if hasQueuedOrPendingAction("wear", item:getID()) then
        return
    end

    RifleSling.markLocalQueuedAction("wear", item:getID())
    ISTimedActionQueue.add(RifleSling_WearPoseAction:new(player, item, newType))
end

local function addGroupedPoseOptions(menu, playerOrIndex, item, groupedOptions, isWearMenu, player)
    local fullType = item:getFullType()

    for _, group in ipairs(groupedOptions) do
        local groupMenu = menu:getNew(menu)
        local groupParent = menu:addOption(group.label, nil, nil)
        menu:addSubMenu(groupParent, groupMenu)

        for _, pose in ipairs(group.options) do
            local option
            if isWearMenu then
                option = groupMenu:addOption(pose.variantLabel or pose.label, playerOrIndex, onWearPose, item, pose.type)
                local resolvedType, familyKey = nil, nil
                if RifleSling.resolveWearTypeForNextFreeFamily then
                    resolvedType, familyKey = RifleSling.resolveWearTypeForNextFreeFamily(player, pose.type)
                end
                if resolvedType and familyKey then
                    option.toolTip = buildToolTip("Will use " .. getFamilySlotLabel(familyKey) .. ".")
                else
                    option.notAvailable = true
                    option.toolTip = buildToolTip("No free sling slot available.")
                end
                if resolvedType and fullType == resolvedType then
                    option.toolTip = nil
                end
            else
                option = groupMenu:addOption(pose.variantLabel or pose.label, playerOrIndex, onSelectPose, item, pose.type)
                if fullType == pose.type then
                    option.notAvailable = true
                end
            end
        end
    end
end

local function onAttachSelectedWeaponToSling(player, weapon, slingItem)
    if not player or not weapon or not slingItem or not RifleSling.getSlotInfoForSling then
        return
    end

    local slotInfo = RifleSling.getSlotInfoForSling(player, slingItem)
    if not slotInfo or not RifleSling.attachWeaponToSlingSlot then
        return
    end

    RifleSling.attachWeaponToSlingSlot(player, weapon, slotInfo)
end

local function onDetachWeaponFromSling(player, slingItem)
    if not player or not slingItem or not RifleSling.findAttachedWeaponForFamily or not RifleSling.removeWeaponFromSling then
        return
    end

    local attachedRecord = RifleSling.findAttachedWeaponForFamily(player, slingItem)
    if attachedRecord and attachedRecord.weapon then
        RifleSling.removeWeaponFromSling(player, attachedRecord.weapon)
    end
end

local function onFillInventoryObjectContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player or not items then
        return
    end

    local slingItem = getSingleSelectedManagedSling(items)
    if not slingItem then
        return
    end

    local familyKey = RifleSling.getPoseFamily(slingItem)
    local groupedPoseOptions = RifleSling.getGroupedPoseOptions and RifleSling.getGroupedPoseOptions(familyKey) or nil
    if not groupedPoseOptions then
        return
    end

    slingItem = resolveManagedSlingItem(player, slingItem)
    if not slingItem then
        return
    end

    if not isItemOwnedOrWornByPlayer(player, slingItem) then
        return
    end

    local isWorn = player.isEquippedClothing and player:isEquippedClothing(slingItem)

    if not isWorn then
        local wearLabel = getText and getText("ContextMenu_Wear") or "Wear"
        if context.removeOptionByName then
            context:removeOptionByName(wearLabel)
        end

        local submenu = context:getNew(context)
        local parent = context:addOption(wearLabel, nil, nil)
        context:addSubMenu(parent, submenu)

        addGroupedPoseOptions(submenu, playerIndex, slingItem, groupedPoseOptions, true, player)
        return
    end

    local submenu = context:getNew(context)
    local parent = context:addOption(RifleSling.getPoseMenuLabel and RifleSling.getPoseMenuLabel(familyKey) or "Adjust Sling Pose", nil, nil)
    context:addSubMenu(parent, submenu)

    local unequipLabel = getText and getText("ContextMenu_Unequip") or "Unequip"
    submenu:addOption(unequipLabel, slingItem, ISInventoryPaneContextMenu.unequipItem, playerIndex)

    addGroupedPoseOptions(submenu, player, slingItem, groupedPoseOptions, false, player)

    local slotInfo = RifleSling.getSlotInfoForSling and RifleSling.getSlotInfoForSling(player, slingItem) or nil
    if slotInfo then
        local attachableWeapons = RifleSling.getAttachableWeaponsForSling and RifleSling.getAttachableWeaponsForSling(player, slingItem) or {}
        local attachedRecord = RifleSling.findAttachedWeaponForFamily and RifleSling.findAttachedWeaponForFamily(player, slingItem) or nil

        if attachedRecord and attachedRecord.weapon then
            context:addOption("Detach Weapon from Sling", player, onDetachWeaponFromSling, slingItem)
        end

        if #attachableWeapons == 1 then
            context:addOption("Attach Weapon to Sling", player, onAttachSelectedWeaponToSling, attachableWeapons[1], slingItem)
        elseif #attachableWeapons > 1 then
            local attachMenu = context:getNew(context)
            local attachParent = context:addOption("Attach Weapon to Sling", nil, nil)
            context:addSubMenu(attachParent, attachMenu)
            for _, weapon in ipairs(attachableWeapons) do
                local label = weapon.getDisplayName and weapon:getDisplayName() or "Weapon"
                attachMenu:addOption(label, player, onAttachSelectedWeaponToSling, weapon, slingItem)
            end
        elseif not attachedRecord then
            local disabled = context:addOption("Attach Weapon to Sling", nil, nil)
            disabled.notAvailable = true
        end
    end
end

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
end

local _RifleSling_originalWearItem = ISInventoryPaneContextMenu.wearItem

ISInventoryPaneContextMenu.wearItem = function(item, player)
    if not RifleSling or not RifleSling.isManagedSlingItem or not RifleSling.isManagedSlingItem(item) then
        return _RifleSling_originalWearItem(item, player)
    end

    local playerObj = getSpecificPlayer(player)
    if not playerObj or not item then
        return
    end

    ISInventoryPaneContextMenu.transferIfNeeded(playerObj, item)

    item = resolveManagedSlingItem(playerObj, item)
    if not item or not playerObj:getInventory():contains(item) then
        return _RifleSling_originalWearItem(item, player)
    end

    if hasQueuedOrPendingAction("wear", item:getID()) then
        return
    end

    local desiredType = item.getFullType and item:getFullType() or nil
    if not desiredType then
        return
    end

    RifleSling.markLocalQueuedAction("wear", item:getID())
    ISTimedActionQueue.add(RifleSling_WearPoseAction:new(playerObj, item, desiredType))
end
