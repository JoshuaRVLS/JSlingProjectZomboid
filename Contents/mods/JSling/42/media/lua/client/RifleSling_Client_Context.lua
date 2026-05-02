if not RifleSling or not RifleSlingClient then
    return
end

require "TimedActions/RifleSling_DetachSlingWeaponAction"

local C = RifleSlingClient

local function addManagedGearContextMenu(player, context, wearableItem)
    if not player or not context or not wearableItem then
        return
    end

    wearableItem = C.resolveManagedClientItem(player, wearableItem)
    if not wearableItem then
        return
    end

    local isWorn = false
    if player.isEquippedClothing and player:isEquippedClothing(wearableItem) then
        isWorn = true
    elseif player.isEquipped and player:isEquipped(wearableItem) then
        isWorn = true
    end

    if not isWorn then
        return
    end

    local config = C.getManagedGearConfig(wearableItem)
    if not config then
        return
    end

    local slotInfos = C.getWornManagedGearSlots(player, wearableItem)
    if #slotInfos == 0 then
        return
    end

    local wearLabel = getText and getText("ContextMenu_Wear") or "Wear"
    if context.removeOptionByName then
        context:removeOptionByName(wearLabel)
    end

    local submenu = context:getNew(context)
    local parent = context:addOption(config.menuLabel or (wearableItem.getDisplayName and wearableItem:getDisplayName() or "Manage Gear"), nil, nil)
    context:addSubMenu(parent, submenu)

    local unequipLabel = getText and getText("ContextMenu_Unequip") or "Unequip"
    submenu:addOption(unequipLabel, wearableItem, ISInventoryPaneContextMenu.unequipItem, player:getPlayerNum())

    for _, slotInfo in ipairs(slotInfos) do
        local slotMenu = submenu:getNew(submenu)
        local slotParent = submenu:addOption(C.getManagedSlotLabel(slotInfo), nil, nil)
        submenu:addSubMenu(slotParent, slotMenu)

        if slotInfo.attachedItem then
            slotMenu:addOption("Remove " .. C.formatWeaponLabel(slotInfo.attachedItem), player, C.onRemoveManagedAttached, slotInfo.attachedItem)
        else
            local emptyOption = slotMenu:addOption("Empty", nil, nil)
            emptyOption.notAvailable = true
        end

        local candidates = C.getAttachableItemsForManagedSlot(player, slotInfo)
        if #candidates == 1 then
            slotMenu:addOption("Attach " .. C.formatWeaponLabel(candidates[1]), player, C.onAttachManagedItem, candidates[1], slotInfo)
        elseif #candidates > 1 then
            local attachMenu = slotMenu:getNew(slotMenu)
            local attachParent = slotMenu:addOption("Attach Item", nil, nil)
            slotMenu:addSubMenu(attachParent, attachMenu)
            for _, candidate in ipairs(candidates) do
                attachMenu:addOption(C.formatWeaponLabel(candidate), player, C.onAttachManagedItem, candidate, slotInfo)
            end
        else
            local noOption = slotMenu:addOption("No compatible item", nil, nil)
            noOption.notAvailable = true
        end
    end
end

local function onFillWeaponAttachContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player or not items then
        return
    end

    local selectedItem = nil
    if items.get and items.size then
        for i = 0, items:size() - 1 do
            local candidate = C.unwrapContextItem(items:get(i))
            if candidate and candidate.getAttachmentType then
                selectedItem = candidate
                break
            end
        end
    else
        for _, entry in ipairs(items) do
            local candidate = C.unwrapContextItem(entry)
            if candidate and candidate.getAttachmentType then
                selectedItem = candidate
                break
            end
        end
    end

    if not selectedItem then
        return
    end

    local attachedSlotType = selectedItem.getAttachedSlotType and selectedItem:getAttachedSlotType() or nil
    if attachedSlotType and RifleSling.isManagedAttachmentSlotType and RifleSling.isManagedAttachmentSlotType(attachedSlotType) then
        local label = attachedSlotType
        if string.find(attachedSlotType, "Sling") then
            label = "Sling"
            context:addOption("Remove from Sling", player, C.onRemoveWeaponFromSling, selectedItem)
            return
        end

        local translated = getTextOrNull and getTextOrNull("IGUI_HotbarAttachment_" .. attachedSlotType) or nil
        context:addOption("Remove from " .. tostring(translated or label), player, C.onRemoveManagedAttached, selectedItem)
        return
    end

    local compatibleSling = {}
    if RifleSling.isSupportedSlingWeapon and RifleSling.isSupportedSlingWeapon(selectedItem) then
        compatibleSling = RifleSling.getCompatibleSlingSlotsForWeapon(player, selectedItem)
    end
    local compatibleGear = RifleSling.getCompatibleManagedGearSlotsForItem and RifleSling.getCompatibleManagedGearSlotsForItem(player, selectedItem) or {}

    if #compatibleSling == 0 and #compatibleGear == 0 then
        return
    end

    if #compatibleSling == 1 then
        context:addOption("Attach to Sling", player, C.onAttachWeaponToSling, selectedItem, compatibleSling[1])
    elseif #compatibleSling > 1 then
        local submenu = context:getNew(context)
        local parent = context:addOption("Attach to Sling", nil, nil)
        context:addSubMenu(parent, submenu)

        for _, slotInfo in ipairs(compatibleSling) do
            submenu:addOption(slotInfo.label, player, C.onAttachWeaponToSling, selectedItem, slotInfo)
        end
    end

    if #compatibleGear == 1 then
        context:addOption("Attach to " .. C.getManagedSlotLabel(compatibleGear[1]), player, C.onAttachManagedItem, selectedItem, compatibleGear[1])
    elseif #compatibleGear > 1 then
        local submenu = context:getNew(context)
        local parent = context:addOption("Attach to Gear", nil, nil)
        context:addSubMenu(parent, submenu)

        for _, slotInfo in ipairs(compatibleGear) do
            submenu:addOption(C.getManagedSlotLabel(slotInfo), player, C.onAttachManagedItem, selectedItem, slotInfo)
        end
    end
end

local function onFillManagedWearableContextMenu(playerIndex, context, items)
    local player = getSpecificPlayer(playerIndex)
    if not player or not items then
        return
    end

    local wearable = nil
    if items.get and items.size then
        for i = 0, items:size() - 1 do
            local candidate = C.unwrapContextItem(items:get(i))
            if candidate and C.getManagedGearConfig(candidate) then
                wearable = candidate
                break
            end
        end
    else
        for _, entry in ipairs(items) do
            local candidate = C.unwrapContextItem(entry)
            if candidate and C.getManagedGearConfig(candidate) then
                wearable = candidate
                break
            end
        end
    end

    if wearable then
        addManagedGearContextMenu(player, context, wearable)
    end
end

local function tryQuickSwapCurrentWeapon(key)
    if not getCore or key ~= getCore():getKey(C.QUICK_SWAP_BINDING) then
        return
    end

    local player = C.getLocalPlayer()
    if not player then
        return
    end

    local weapon = player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    if not weapon or not RifleSling.isSupportedSlingWeapon or not RifleSling.isSupportedSlingWeapon(weapon) then
        weapon = player.getSecondaryHandItem and player:getSecondaryHandItem() or nil
    end

    if not weapon or not RifleSling.isSupportedSlingWeapon or not RifleSling.isSupportedSlingWeapon(weapon) then
        C.notify(player, "No supported sling weapon equipped", false)
        return
    end

    local attachedSlotType = weapon.getAttachedSlotType and weapon:getAttachedSlotType() or nil
    if attachedSlotType and string.find(attachedSlotType, "Sling") then
        C.notify(player, "Weapon is already on a sling", false)
        return
    end

    local compatible = RifleSling.getCompatibleSlingSlotsForWeapon(player, weapon)
    if #compatible == 0 then
        C.notify(player, "No free compatible sling available", false)
        return
    end

    C.onAttachWeaponToSling(player, weapon, compatible[1])
end

local function registerQuickSwapKeybind()
    if not keyBinding then
        return
    end

    for _, bind in ipairs(keyBinding) do
        if bind and bind.value == C.QUICK_SWAP_BINDING then
            return
        end
    end

    local header = { value = "[RifleSling]" }
    local bind = { value = C.QUICK_SWAP_BINDING, key = 0 }
    table.insert(keyBinding, header)
    table.insert(keyBinding, bind)
end

registerQuickSwapKeybind()

if Events and Events.OnFillInventoryObjectContextMenu then
    Events.OnFillInventoryObjectContextMenu.Add(onFillWeaponAttachContextMenu)
    Events.OnFillInventoryObjectContextMenu.Add(onFillManagedWearableContextMenu)
end
if Events and Events.OnKeyPressed then
    Events.OnKeyPressed.Add(tryQuickSwapCurrentWeapon)
end

local _RifleSling_originalUnequipItem = ISInventoryPaneContextMenu.unequipItem

function ISInventoryPaneContextMenu.unequipItem(item, player)
    if RifleSling._forceVanillaUnequip then
        return _RifleSling_originalUnequipItem(item, player)
    end

    local playerObj = getSpecificPlayer(player)
    local isManagedSling = item and RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(item)
    local isManagedGear = item and C.getManagedGearConfig(item) ~= nil

    if not playerObj or not item or (not isManagedSling and not isManagedGear) then
        return _RifleSling_originalUnequipItem(item, player)
    end

    local resolvedItem = C.resolveManagedClientItem(playerObj, item) or item

    local isWorn = false
    if playerObj.isEquippedClothing and playerObj:isEquippedClothing(resolvedItem) then
        isWorn = true
    elseif playerObj.isEquipped and playerObj:isEquipped(resolvedItem) then
        isWorn = true
    end

    if not isWorn then
        return _RifleSling_originalUnequipItem(resolvedItem, player)
    end

    local attachedRecord = isManagedSling and RifleSling.findAttachedWeaponForFamily and RifleSling.findAttachedWeaponForFamily(playerObj, resolvedItem) or nil
    if isManagedSling and attachedRecord and attachedRecord.weapon then
        ISTimedActionQueue.add(RifleSling_DetachSlingWeaponAction:new(playerObj, attachedRecord.weapon))
        ISTimedActionQueue.add(ISUnequipAction:new(playerObj, resolvedItem, 50))
        return
    end

    return _RifleSling_originalUnequipItem(resolvedItem, player)
end
