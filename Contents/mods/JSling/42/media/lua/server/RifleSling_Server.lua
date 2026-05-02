if not RifleSling then
    return
end

local function reply(player, ok, message, action, requestId, data)
    if sendServerCommand and player then
        sendServerCommand(player, "RifleSling", RifleSling.Commands.Result, {
            ok = ok,
            message = message,
            action = action,
            requestId = requestId,
            onlineID = RifleSling.getOnlineId and RifleSling.getOnlineId(player) or -1,
            playerNum = player.getPlayerNum and player:getPlayerNum() or -1,
            data = data,
        })
    end
end

local function broadcastSync(player, action, data)
    if not sendServerCommand or not player then
        return
    end

    local payload = data or {}
    payload.action = action
    payload.onlineID = RifleSling.getOnlineId and RifleSling.getOnlineId(player) or -1
    payload.playerNum = player.getPlayerNum and player:getPlayerNum() or -1
    payload.serverTime = getTimestampMs and getTimestampMs() or nil
    sendServerCommand("RifleSling", RifleSling.Commands.Sync, payload)
end

local function applyManagedAttachmentState(player, item, attached, slotType, slotName, slotIndex)
    if not player or not item then
        return
    end

    if attached then
        if slotName and player.setAttachedItem then
            player:setAttachedItem(slotName, item)
        end
        if item.setAttachedSlot then
            item:setAttachedSlot(slotIndex or -1)
        end
        if item.setAttachedSlotType then
            item:setAttachedSlotType(slotType)
        end
        if item.setAttachedToModel then
            item:setAttachedToModel(slotName)
        end
        if item.syncItemFields then
            item:syncItemFields()
        end
        if item.transmitModData then
            item:transmitModData()
        end
        return
    end

    if player.removeAttachedItem then
        player:removeAttachedItem(item)
    end
    if item.setAttachedSlot then
        item:setAttachedSlot(-1)
    end
    if item.setAttachedSlotType then
        item:setAttachedSlotType(nil)
    end
    if item.setAttachedToModel then
        item:setAttachedToModel(nil)
    end
    if item.syncItemFields then
        item:syncItemFields()
    end
    if item.transmitModData then
        item:transmitModData()
    end
end

local function onClientCommand(module, command, player, args)
    if module ~= "RifleSling" then
        return
    end

    if not player then
        return
    end

    local requestId = args and args.requestId or nil

    if command == RifleSling.Commands.WearPose then
        local itemId = args and args.itemId or nil
        local desiredType = args and args.desiredType or nil
        local sling = RifleSling.findItemById(player, itemId)

        if not sling or not desiredType or not RifleSling.isManagedSlingItem(sling) then
            reply(player, false, "Could not wear sling", "wear", requestId)
            return
        end

        if player.isEquippedClothing and player:isEquippedClothing(sling) then
            reply(player, false, "Sling is already worn", "wear", requestId)
            return
        end

        local newItem, familyKeyOrMessage = RifleSling.wearSlingToNextFreeFamily(player, sling, desiredType)
        local familyKey = newItem and familyKeyOrMessage or nil
        local message = newItem and "Sling worn" or tostring(familyKeyOrMessage or "Could not wear sling")

        if newItem then
            broadcastSync(player, "wear", {
                oldItemId = itemId,
                newItemId = newItem and newItem.getID and newItem:getID() or nil,
                newType = newItem and newItem.getFullType and newItem:getFullType() or desiredType,
                family = familyKey,
            })
        end

        reply(player, newItem ~= nil, message, "wear", requestId, {
            oldItemId = itemId,
            newItemId = newItem and newItem.getID and newItem:getID() or nil,
            newType = newItem and newItem.getFullType and newItem:getFullType() or desiredType,
            family = familyKey,
        })
        return
    end

    if command == RifleSling.Commands.SetPose then
        local itemId = args and args.itemId or nil
        local newType = args and args.newType or nil
        local weaponId = args and args.weaponId or nil
        local oldSlotType = args and args.oldSlotType or nil
        local oldSlotIndex = args and args.oldSlotIndex or nil
        local sling = RifleSling.findItemById(player, itemId)

        if not sling or not newType or not RifleSling.isManagedSlingItem(sling) then
            reply(player, false, "Could not adjust sling pose", "pose", requestId)
            return
        end

        local oldFamily = RifleSling.getPoseFamily(sling)
        local newFamily = RifleSling.getPoseFamily(newType)
        if not oldFamily or oldFamily ~= newFamily then
            reply(player, false, "Invalid sling pose", "pose", requestId)
            return
        end

        if not player.isEquippedClothing or not player:isEquippedClothing(sling) then
            reply(player, false, "Sling must be worn to change pose", "pose", requestId)
            return
        end

        local detachedWeapon = weaponId and RifleSling.findItemById(player, weaponId) or nil
        local newItem = RifleSling.swapSlingPose(player, sling, newType, detachedWeapon, oldSlotType, oldSlotIndex)
        if newItem then
            broadcastSync(player, "pose", {
                oldItemId = itemId,
                newItemId = newItem and newItem.getID and newItem:getID() or nil,
                newType = newType,
                family = oldFamily,
            })
        end
        reply(player, newItem ~= nil, newItem and "Sling pose adjusted" or "Could not adjust sling pose", "pose", requestId, {
            oldItemId = itemId,
            newItemId = newItem and newItem.getID and newItem:getID() or nil,
            newType = newType,
        })
        return
    end

    if command ~= RifleSling.Commands.SetAttached then
        return
    end

    local weaponId = args and args.weaponId or nil
    local attached = args and args.attached == true
    local slotType = args and args.slotType or nil
    local slotName = args and args.slotName or nil
    local slotIndex = args and args.slotIndex or nil

    if not slotType or not RifleSling.isManagedAttachmentSlotType or not RifleSling.isManagedAttachmentSlotType(slotType) then
        reply(player, false, "Invalid managed attachment slot", "attach", requestId, {
            weaponId = weaponId,
            attached = attached,
        })
        return
    end

    local weapon = RifleSling.findItemById(player, weaponId)
    if not weapon then
        reply(player, false, "Could not find target weapon", "attach", requestId)
        return
    end

    if not (RifleSling.isManagedSlingSlotType and RifleSling.isManagedSlingSlotType(slotType)) then
        applyManagedAttachmentState(player, weapon, attached, slotType, slotName, slotIndex)
        broadcastSync(player, "attach", {
            weaponId = weaponId,
            attached = attached,
            slotType = slotType,
            slotName = slotName,
            slotIndex = slotIndex,
        })
        reply(player, true, attached and "Attachment updated" or "Attachment removed", "attach", requestId, {
            weaponId = weaponId,
            attached = attached,
            slotType = slotType,
            slotName = slotName,
            slotIndex = slotIndex,
        })
        return
    end

    local ok, message
    if RifleSling.isManagedSlingSlotType and RifleSling.isManagedSlingSlotType(slotType) then
        if attached then
            ok, message = RifleSling.attachToManagedSling(player, weapon, nil)
        else
            ok, message = RifleSling.detachFromManagedSling(player, weapon)
        end
    end

    if ok then
        applyManagedAttachmentState(player, weapon, attached, slotType, slotName, slotIndex)
        broadcastSync(player, "attach", {
            weaponId = weaponId,
            attached = attached,
            slingAttached = RifleSling.isSlingAttached and RifleSling.isSlingAttached(weapon) or attached,
            slotType = slotType,
            slotName = slotName,
            slotIndex = slotIndex,
        })
    end

    reply(player, ok, message, "attach", requestId, {
        weaponId = weaponId,
        attached = attached,
        slotType = slotType,
        slotName = slotName,
        slotIndex = slotIndex,
    })
end

if Events and Events.OnClientCommand then
    Events.OnClientCommand.Add(onClientCommand)
end
