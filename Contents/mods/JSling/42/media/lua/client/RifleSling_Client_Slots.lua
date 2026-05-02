if not RifleSling or not RifleSlingClient then
    return
end

local C = RifleSlingClient

C.unwrapContextItem = function(entry)
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

C.getPoseLabel = function(item)
    if not item or not RifleSling.getPoseFamily or not RifleSling.getPoseOptions then
        return "Sling"
    end

    local familyKey = RifleSling.getPoseFamily(item)
    local options = familyKey and RifleSling.getPoseOptions(familyKey) or nil
    local fullType = item.getFullType and item:getFullType() or nil
    if not options or not fullType then
        return "Sling"
    end

    for _, option in ipairs(options) do
        if option.type == fullType then
            return option.label or "Sling"
        end
    end

    return "Sling"
end

C.formatWeaponLabel = function(item)
    if not item then
        return "Weapon"
    end

    local ok, label = pcall(function()
        if item.getDisplayName then
            local displayName = item:getDisplayName()
            if displayName and displayName ~= "" then
                return displayName
            end
        end

        if item.getName then
            local name = item:getName()
            if name and name ~= "" then
                return name
            end
        end

        return "Weapon"
    end)

    if ok and label then
        return label
    end

    return "Weapon"
end

C.getWornSlingSlots = function(player)
    local results = {}
    if not player then
        return results
    end

    local hotbar = C.refreshHotbarForPlayer(player)
    if not hotbar then
        return results
    end

    local wornItems = player.getWornItems and player:getWornItems() or nil
    if not wornItems then
        return results
    end

    for i = 0, wornItems:size() - 1 do
        local worn = wornItems:get(i)
        local item = worn and worn.getItem and worn:getItem() or nil
        if item and RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(item) then
            local slotType = RifleSling.getPoseSlotType and RifleSling.getPoseSlotType(item) or nil
            local slotIndex = slotType and hotbar.getThisSlotIndex and hotbar:getThisSlotIndex(slotType) or nil
            local slot = slotIndex and hotbar.availableSlot and hotbar.availableSlot[slotIndex] or nil
            if slot and slot.def then
                results[#results + 1] = {
                    hotbar = hotbar,
                    slotIndex = slotIndex,
                    slot = slot,
                    sling = item,
                    label = C.getPoseLabel(item),
                }
            end
        end
    end

    return results
end

RifleSling.getWornSlingSlots = C.getWornSlingSlots

C.getWornManagedGearSlots = function(player, wearableItem)
    local results = {}
    if not player or not wearableItem then
        return results
    end

    local config = C.getManagedGearConfig(wearableItem)
    if not config then
        return results
    end

    local hotbar = C.refreshHotbarForPlayer(player)
    if not hotbar then
        return results
    end

    for _, slotConfig in ipairs(config.slots or {}) do
        local slotIndex = hotbar.getThisSlotIndex and hotbar:getThisSlotIndex(slotConfig.type) or nil
        local slot = slotIndex and hotbar.availableSlot and hotbar.availableSlot[slotIndex] or nil
        if slot and slot.def then
            results[#results + 1] = {
                hotbar = hotbar,
                slotIndex = slotIndex,
                slot = slot,
                slotType = slotConfig.type,
                label = slotConfig.label,
                wearable = wearableItem,
                attachedItem = RifleSling.findAttachedWeaponForSlot and RifleSling.findAttachedWeaponForSlot(player, slotConfig.type) or nil,
            }
        end
    end

    return results
end

RifleSling.getWornManagedGearSlots = C.getWornManagedGearSlots

function RifleSling.getCompatibleSlingSlotsForWeapon(player, weapon)
    local compatible = {}
    if not player or not weapon then
        return compatible
    end

    local wornSlots = C.getWornSlingSlots(player)
    for _, slotInfo in ipairs(wornSlots) do
        if slotInfo.hotbar.canBeAttached and slotInfo.hotbar:canBeAttached(slotInfo.slot, weapon) then
            compatible[#compatible + 1] = slotInfo
        end
    end

    return compatible
end

function RifleSling.getSlotInfoForSling(player, slingItem)
    if not player or not slingItem then
        return nil
    end

    local wornSlots = C.getWornSlingSlots(player)
    for _, slotInfo in ipairs(wornSlots) do
        if slotInfo.sling == slingItem then
            return slotInfo
        end
    end

    return nil
end

local function collectCompatibleWeaponsFromContainer(container, slotInfo, seen, results)
    if not container or not slotInfo or not results then
        return
    end

    local items = container.getItems and container:getItems() or nil
    if not items then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
            collectCompatibleWeaponsFromContainer(item:getInventory(), slotInfo, seen, results)
        end

        if item and item.getID and not seen[item:getID()] and RifleSling.isSupportedSlingWeapon and RifleSling.isSupportedSlingWeapon(item) then
            local attachedSlotType = item.getAttachedSlotType and item:getAttachedSlotType() or nil
            if not attachedSlotType and slotInfo.hotbar.canBeAttached and slotInfo.hotbar:canBeAttached(slotInfo.slot, item) then
                seen[item:getID()] = true
                results[#results + 1] = item
            end
        end
    end
end

function RifleSling.getAttachableWeaponsForSling(player, slingItem)
    local slotInfo = RifleSling.getSlotInfoForSling(player, slingItem)
    local results = {}
    if not player or not slingItem or not slotInfo then
        return results
    end

    local seen = {}
    local primary = player.getPrimaryHandItem and player:getPrimaryHandItem() or nil
    local secondary = player.getSecondaryHandItem and player:getSecondaryHandItem() or nil

    local function addCandidate(item)
        if not item or not item.getID or seen[item:getID()] then
            return
        end
        local attachedSlotType = item.getAttachedSlotType and item:getAttachedSlotType() or nil
        if attachedSlotType then
            return
        end
        if RifleSling.isSupportedSlingWeapon and RifleSling.isSupportedSlingWeapon(item) and slotInfo.hotbar.canBeAttached and slotInfo.hotbar:canBeAttached(slotInfo.slot, item) then
            seen[item:getID()] = true
            results[#results + 1] = item
        end
    end

    addCandidate(primary)
    addCandidate(secondary)

    local inv = player.getInventory and player:getInventory() or nil
    if inv then
        collectCompatibleWeaponsFromContainer(inv, slotInfo, seen, results)
    end

    table.sort(results, function(a, b)
        local nameA = a.getDisplayName and a:getDisplayName() or ""
        local nameB = b.getDisplayName and b:getDisplayName() or ""
        if nameA == nameB then
            return (a.getID and a:getID() or 0) < (b.getID and b:getID() or 0)
        end
        return nameA < nameB
    end)

    return results
end

local function collectAttachableItemsFromContainer(container, slotInfo, seen, results)
    if not container or not slotInfo or not slotInfo.hotbar or not slotInfo.slot or not results then
        return
    end

    local items = container.getItems and container:getItems() or nil
    if not items then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
            collectAttachableItemsFromContainer(item:getInventory(), slotInfo, seen, results)
        end

        if item and item.getID and item.getAttachmentType and not seen[item:getID()] then
            local attachedSlotType = item.getAttachedSlotType and item:getAttachedSlotType() or nil
            if not attachedSlotType and slotInfo.hotbar.canBeAttached and slotInfo.hotbar:canBeAttached(slotInfo.slot, item) then
                seen[item:getID()] = true
                results[#results + 1] = item
            end
        end
    end
end

C.getAttachableItemsForManagedSlot = function(player, slotInfo)
    local results = {}
    if not player or not slotInfo or not slotInfo.hotbar or not slotInfo.slot then
        return results
    end

    local seen = {}

    local function addCandidate(item)
        if not item or not item.getID or not item.getAttachmentType or seen[item:getID()] then
            return
        end

        local attachedSlotType = item.getAttachedSlotType and item:getAttachedSlotType() or nil
        if attachedSlotType then
            return
        end

        if slotInfo.hotbar.canBeAttached and slotInfo.hotbar:canBeAttached(slotInfo.slot, item) then
            seen[item:getID()] = true
            results[#results + 1] = item
        end
    end

    addCandidate(player.getPrimaryHandItem and player:getPrimaryHandItem() or nil)
    addCandidate(player.getSecondaryHandItem and player:getSecondaryHandItem() or nil)

    local inv = player.getInventory and player:getInventory() or nil
    if inv then
        collectAttachableItemsFromContainer(inv, slotInfo, seen, results)
    end

    table.sort(results, function(a, b)
        local nameA = a.getDisplayName and a:getDisplayName() or ""
        local nameB = b.getDisplayName and b:getDisplayName() or ""
        if nameA == nameB then
            return (a.getID and a:getID() or 0) < (b.getID and b:getID() or 0)
        end
        return nameA < nameB
    end)

    return results
end

function RifleSling.getCompatibleManagedGearSlotsForItem(player, item)
    local compatible = {}
    if not player or not item or not item.getAttachmentType then
        return compatible
    end

    local wornItems = player.getWornItems and player:getWornItems() or nil
    if not wornItems then
        return compatible
    end

    for i = 0, wornItems:size() - 1 do
        local worn = wornItems:get(i)
        local wearable = worn and worn.getItem and worn:getItem() or nil
        if wearable and C.getManagedGearConfig(wearable) then
            local slots = C.getWornManagedGearSlots(player, wearable)
            for _, slotInfo in ipairs(slots) do
                if slotInfo.hotbar.canBeAttached and slotInfo.hotbar:canBeAttached(slotInfo.slot, item) then
                    compatible[#compatible + 1] = slotInfo
                end
            end
        end
    end

    return compatible
end

C.onAttachWeaponToSling = function(player, weapon, slotInfo)
    if not player or not weapon or not slotInfo or not slotInfo.hotbar or not slotInfo.slot or not slotInfo.slotIndex then
        return
    end

    slotInfo.hotbar:attachItem(
        weapon,
        slotInfo.slot.def.attachments[weapon:getAttachmentType()],
        slotInfo.slotIndex,
        slotInfo.slot.def,
        true
    )
end

function RifleSling.attachWeaponToSlingSlot(player, weapon, slotInfo)
    return C.onAttachWeaponToSling(player, weapon, slotInfo)
end

C.onAttachManagedItem = function(player, item, slotInfo)
    if not player or not item or not slotInfo or not slotInfo.hotbar or not slotInfo.slot or not slotInfo.slotIndex then
        return
    end

    local attachmentType = item.getAttachmentType and item:getAttachmentType() or nil
    local slotName = attachmentType and slotInfo.slot.def and slotInfo.slot.def.attachments and slotInfo.slot.def.attachments[attachmentType] or nil
    if not slotName then
        return
    end

    slotInfo.hotbar:attachItem(item, slotName, slotInfo.slotIndex, slotInfo.slot.def, true)
end

C.onRemoveWeaponFromSling = function(player, weapon)
    if not player or not weapon or not getPlayerHotbar then
        return
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum())
    if not hotbar then
        return
    end

    hotbar:removeItem(weapon, true)
end

function RifleSling.removeWeaponFromSling(player, weapon)
    return C.onRemoveWeaponFromSling(player, weapon)
end

C.onRemoveManagedAttached = function(player, item)
    if not player or not item or not getPlayerHotbar then
        return
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum())
    if not hotbar then
        return
    end

    hotbar:removeItem(item, true)
end
