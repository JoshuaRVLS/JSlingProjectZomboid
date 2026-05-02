if not RifleSling then
    return
end

require "ISUI/ISInventoryPaneContextMenu"
require "TimedActions/ISTimedActionQueue"
require "TimedActions/ISUnequipAction"

RifleSlingClient = RifleSlingClient or {}
local C = RifleSlingClient


RifleSling._nextRequestId = RifleSling._nextRequestId or 1
RifleSling._pendingRequests = RifleSling._pendingRequests or {}
RifleSling._syncRefreshQueue = RifleSling._syncRefreshQueue or {}
RifleSling._tooltipRefreshTick = RifleSling._tooltipRefreshTick or 0
RifleSling._itemIdRedirects = RifleSling._itemIdRedirects or {}
RifleSling._expectedManagedAttachmentOps = RifleSling._expectedManagedAttachmentOps or {}

local QUICK_SWAP_BINDING = "Sling Quick Swap"
local TOOLTIP_REFRESH_INTERVAL = 20
local getPoseLabel
local formatWeaponLabel
local getWornSlingSlots
local getWornManagedGearSlots
local refreshManagedSlingTooltips

local MANAGED_GEAR_CONFIG = {
    ["Base.JSling_ChestRig"] = {
        menuLabel = "Manage Chest Rig",
        slots = {
            { type = "ChestRig", label = "Left Slot" },
            { type = "ChestRigRight", label = "Right Slot" },
        },
    },
    ["Base.JSling_Webbing"] = {
        menuLabel = "Manage Webbing",
        slots = {
            { type = "ChestRig", label = "Left Slot" },
            { type = "ChestRigRight", label = "Right Slot" },
        },
    },
    ["Base.JSling_WebbingLoose"] = {
        menuLabel = "Manage Webbing",
        slots = {
            { type = "ChestRig", label = "Left Slot" },
            { type = "ChestRigRight", label = "Right Slot" },
        },
    },
    ["Base.JSling_Webbing_Military"] = {
        menuLabel = "Manage Webbing",
        slots = {
            { type = "ChestRig", label = "Left Slot" },
            { type = "ChestRigRight", label = "Right Slot" },
        },
    },
    ["Base.JSling_Webbing_MilitaryLoose"] = {
        menuLabel = "Manage Webbing",
        slots = {
            { type = "ChestRig", label = "Left Slot" },
            { type = "ChestRigRight", label = "Right Slot" },
        },
    },
    ["Base.JSling_Webbing_Black"] = {
        menuLabel = "Manage Webbing",
        slots = {
            { type = "ChestRig", label = "Left Slot" },
            { type = "ChestRigRight", label = "Right Slot" },
        },
    },
    ["Base.JSling_Webbing_BlackLoose"] = {
        menuLabel = "Manage Webbing",
        slots = {
            { type = "ChestRig", label = "Left Slot" },
            { type = "ChestRigRight", label = "Right Slot" },
        },
    },
    ["Base.JSling_TacticalVest"] = {
        menuLabel = "Manage Tactical Vest",
        slots = {
            { type = "Back2", label = "Rifle Slot" },
            { type = "Back3", label = "Melee Slot" },
        },
    },
    ["Base.JSling_BackRig"] = {
        menuLabel = "Manage Back Rig",
        slots = {
            { type = "Back2", label = "Back Slot" },
        },
    },
    ["Base.JSling_KnifeSheath"] = {
        menuLabel = "Manage Knife Sheath",
        slots = {
            { type = "KnifeSheath", label = "Thigh Sheath" },
        },
    },
    ["Base.JSling_KnifeSheathBack"] = {
        menuLabel = "Manage Knife Sheath",
        slots = {
            { type = "KnifeSheathBack", label = "Waist Sheath" },
        },
    },
    ["Base.JSling_KatanaSheath"] = {
        menuLabel = "Manage Katana Sheath",
        slots = {
            { type = "KatanaSheath", label = "Katana Sheath" },
        },
    },
}

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

local function getLocalPlayer()
    return getSpecificPlayer and getSpecificPlayer(0) or nil
end

local function getFamilySlotNumber(familyKey)
    if not familyKey or not RifleSling.getSortedFamilyKeys then
        return nil
    end

    for index, key in ipairs(RifleSling.getSortedFamilyKeys()) do
        if key == familyKey then
            return index
        end
    end

    return nil
end

local function getNowSeconds()
    if os and os.time then
        return os.time()
    end
    return 0
end

local function getNowMs()
    if getTimestampMs then
        return getTimestampMs()
    end
    return getNowSeconds() * 1000
end

local function getExpectedManagedAttachmentKey(itemId, attached, slotType)
    if itemId == nil or not slotType then
        return nil
    end

    return table.concat({
        tostring(itemId),
        attached and "1" or "0",
        tostring(slotType),
    }, "|")
end

local function pruneExpectedManagedAttachmentOps(nowMs)
    local currentTime = nowMs or getNowMs()
    for key, entry in pairs(RifleSling._expectedManagedAttachmentOps) do
        if not entry or not entry.expiresAt or entry.expiresAt <= currentTime then
            RifleSling._expectedManagedAttachmentOps[key] = nil
        end
    end
end

function RifleSling.markExpectedManagedAttachment(item, attached, slotType, slotName, slotIndex)
    if not item or not item.getID or not slotType then
        return false
    end

    pruneExpectedManagedAttachmentOps()

    local key = getExpectedManagedAttachmentKey(item:getID(), attached == true, slotType)
    if not key then
        return false
    end

    RifleSling._expectedManagedAttachmentOps[key] = {
        slotName = slotName,
        slotIndex = slotIndex,
        expiresAt = getNowMs() + 5000,
    }

    return true
end

function RifleSling.consumeExpectedManagedAttachment(item, attached, slotType, slotName, slotIndex)
    if not item or not item.getID or not slotType then
        return false
    end

    pruneExpectedManagedAttachmentOps()

    local key = getExpectedManagedAttachmentKey(item:getID(), attached == true, slotType)
    local entry = key and RifleSling._expectedManagedAttachmentOps[key] or nil
    if not entry then
        return false
    end

    if entry.slotName and slotName and entry.slotName ~= slotName then
        return false
    end

    if entry.slotIndex ~= nil and slotIndex ~= nil and tonumber(entry.slotIndex) ~= tonumber(slotIndex) then
        return false
    end

    RifleSling._expectedManagedAttachmentOps[key] = nil
    return true
end

local function refreshPlayerModel(player)
    if not player then
        return false
    end

    if player.resetModelNextFrame then
        player:resetModelNextFrame()
    elseif player.resetModel then
        player:resetModel()
    end

    return true
end

local function markInventoryDirty()
    if ISInventoryPage then
        ISInventoryPage.renderDirty = true
    end
end

local function refreshHotbarForPlayer(player)
    if not player or not getPlayerHotbar then
        return nil
    end

    local hotbar = getPlayerHotbar(player:getPlayerNum())
    if not hotbar then
        return nil
    end

    if hotbar.refresh then
        hotbar:refresh()
    elseif hotbar.compareWornItems and hotbar:compareWornItems() and hotbar.reloadIcons then
        hotbar:reloadIcons()
    end

    return hotbar
end

local function resolveManagedClientItem(player, item)
    if not player or not item then
        return nil
    end

    local itemId = item.getID and item:getID() or nil
    if itemId ~= nil then
        local redirectedId = RifleSling._itemIdRedirects and RifleSling._itemIdRedirects[tostring(itemId)] or nil
        if redirectedId and RifleSling.findItemById then
            local redirected = RifleSling.findItemById(player, redirectedId)
            if redirected then
                return redirected
            end
        end
    end

    if RifleSling.findItemById and item.getID then
        local resolved = RifleSling.findItemById(player, item:getID())
        if resolved then
            return resolved
        end
    end

    local bodyLocation = item.getBodyLocation and item:getBodyLocation() or nil
    local fullType = item.getFullType and item:getFullType() or nil
    local poseIndex = RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(item)
        and RifleSling.getPoseIndex and RifleSling.getPoseIndex(item) or nil

    local wornItems = player.getWornItems and player:getWornItems() or nil
    if not wornItems then
        return item
    end

    local sameTypeMatch = nil
    local poseMatch = nil
    local poseMatchCount = 0
    local managedSlingCount = 0
    local singleManagedSling = nil

    for i = 0, wornItems:size() - 1 do
        local worn = wornItems:get(i)
        local wornItem = worn and worn.getItem and worn:getItem() or nil
        if wornItem then
            local isManagedSling = RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(wornItem)
            local isManagedGear = getManagedGearConfig(wornItem) ~= nil

            if isManagedSling then
                managedSlingCount = managedSlingCount + 1
                singleManagedSling = wornItem
            end

            if isManagedSling or isManagedGear then
                local wornBodyLocation = wornItem.getBodyLocation and wornItem:getBodyLocation() or nil
                local wornFullType = wornItem.getFullType and wornItem:getFullType() or nil

                if bodyLocation and wornBodyLocation == bodyLocation and (not fullType or wornFullType == fullType) then
                    return wornItem
                end

                if not sameTypeMatch and fullType and wornFullType == fullType then
                    sameTypeMatch = wornItem
                end

                if poseIndex and isManagedSling and RifleSling.getPoseIndex and RifleSling.getPoseIndex(wornItem) == poseIndex then
                    poseMatch = wornItem
                    poseMatchCount = poseMatchCount + 1
                end
            end
        end
    end

    if sameTypeMatch then
        return sameTypeMatch
    end

    if poseMatchCount == 1 and poseMatch then
        return poseMatch
    end

    if poseIndex and managedSlingCount == 1 and singleManagedSling then
        return singleManagedSling
    end

    return item
end

RifleSling.resolveManagedClientItem = resolveManagedClientItem

local function rememberItemRedirect(oldItemId, newItemId)
    if oldItemId == nil or newItemId == nil or tostring(oldItemId) == tostring(newItemId) then
        return
    end

    RifleSling._itemIdRedirects[tostring(oldItemId)] = tonumber(newItemId) or newItemId
end

local function cleanupRedirectedManagedItem(player, oldItemId, newItemId)
    if not player or not oldItemId or not newItemId or tostring(oldItemId) == tostring(newItemId) then
        return
    end

    if not RifleSling.findItemById then
        return
    end

    local oldItem = RifleSling.findItemById(player, oldItemId)
    local newItem = RifleSling.findItemById(player, newItemId)
    if not oldItem or not newItem or oldItem == newItem then
        return
    end

    if not (RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(oldItem)) then
        return
    end

    if player.isEquippedClothing and player:isEquippedClothing(oldItem) then
        return
    end

    local container = oldItem.getContainer and oldItem:getContainer() or nil
    if not container then
        return
    end

    if container.DoRemoveItem then
        container:DoRemoveItem(oldItem)
    elseif container.Remove then
        container:Remove(oldItem)
    end

    if container.contains and container:contains(oldItem) and container.Remove then
        container:Remove(oldItem)
    end

    if container.setDrawDirty then
        container:setDrawDirty(true)
    end

    markInventoryDirty()
end

local function getManagedGearConfig(item)
    if not item or not item.getFullType then
        return nil
    end
    return MANAGED_GEAR_CONFIG[item:getFullType()]
end

local function getManagedSlotLabel(slotInfo)
    if not slotInfo then
        return "Slot"
    end

    local slotType = slotInfo.slot and slotInfo.slot.slotType or slotInfo.slotType
    local translated = slotType and getTextOrNull and getTextOrNull("IGUI_HotbarAttachment_" .. tostring(slotType)) or nil
    if translated then
        return translated
    end

    if slotInfo.label then
        return slotInfo.label
    end

    if slotInfo.slot and slotInfo.slot.name then
        return slotInfo.slot.name
    end

    return "Slot"
end

local function refreshObservedPlayerByOnlineId(onlineId)
    if onlineId == nil then
        return false
    end

    local localPlayer = getLocalPlayer()
    if localPlayer and localPlayer.getOnlineID and localPlayer:getOnlineID() == onlineId then
        refreshPlayerModel(localPlayer)
        if RifleSling.refreshPlayerBuffs then
            RifleSling.refreshPlayerBuffs(localPlayer)
        end
        return true
    end

    if getPlayerByOnlineID then
        local remotePlayer = getPlayerByOnlineID(onlineId)
        if remotePlayer then
            return refreshPlayerModel(remotePlayer)
        end
    end

    return false
end

local function refreshObservedPlayer(args)
    if not args then
        return false
    end

    local onlineId = args.onlineID
    if refreshObservedPlayerByOnlineId(onlineId) then
        return true
    end

    local playerNum = tonumber(args.playerNum)
    if playerNum ~= nil and getSpecificPlayer then
        local candidate = getSpecificPlayer(playerNum)
        if candidate then
            if refreshPlayerModel(candidate) and RifleSling.refreshPlayerBuffs and candidate.isLocalPlayer and candidate:isLocalPlayer() then
                RifleSling.refreshPlayerBuffs(candidate)
            end
            return true
        end
    end

    return false
end

local function queueObservedPlayerRefresh(onlineId)
    if onlineId == nil then
        return
    end

    RifleSling._syncRefreshQueue[tostring(onlineId)] = 90
end

function RifleSling.beginRequest(action, itemId)
    local requestId = tostring(RifleSling._nextRequestId or 1)
    RifleSling._nextRequestId = (RifleSling._nextRequestId or 1) + 1
    RifleSling._pendingRequests[requestId] = {
        action = action,
        itemId = itemId,
        createdAt = getNowSeconds(),
    }
    return requestId
end

function RifleSling.finishRequest(requestId)
    if not requestId then
        return nil
    end
    local pending = RifleSling._pendingRequests[requestId]
    RifleSling._pendingRequests[requestId] = nil
    return pending
end

function RifleSling.hasPendingAction(action, itemId)
    local now = getNowSeconds()
    for _, pending in pairs(RifleSling._pendingRequests) do
        if pending.createdAt and now > 0 and (now - pending.createdAt) > 15 then
            pending.stale = true
        end
        if pending.action == action and (itemId == nil or pending.itemId == itemId) then
            return true
        end
    end
    return false
end

function RifleSling.refreshLocalPlayer()
    local player = getLocalPlayer()
    if not player then
        return
    end

    refreshPlayerModel(player)
    markInventoryDirty()
    if RifleSling.refreshPlayerBuffs then
        RifleSling.refreshPlayerBuffs(player)
    end
    refreshManagedSlingTooltips(player)
end

local function isItemWornByPlayer(player, item)
    if not player or not item or not player.isEquippedClothing then
        return false
    end

    local resolved = resolveManagedClientItem(player, item)
    return resolved and player:isEquippedClothing(resolved) or false
end

local function getPoseDetails(item)
    if not item or not RifleSling.getPoseFamily or not RifleSling.getPoseOptions then
        return {
            label = "Sling",
            variantLabel = "Standard",
        }
    end

    local familyKey = RifleSling.getPoseFamily(item)
    local options = familyKey and RifleSling.getPoseOptions(familyKey) or nil
    local fullType = item.getFullType and item:getFullType() or nil
    if not options or not fullType then
        return {
            label = "Sling",
            variantLabel = "Standard",
        }
    end

    for _, option in ipairs(options) do
        if option.type == fullType then
            return {
                label = option.label or "Sling",
                variantLabel = option.variantLabel or "Standard",
            }
        end
    end

    return {
        label = "Sling",
        variantLabel = "Standard",
    }
end

local function collectManagedSlingsFromContainer(container, seen, results)
    if not container or not results then
        return
    end

    local items = container.getItems and container:getItems() or nil
    if not items then
        return
    end

    for i = 0, items:size() - 1 do
        local item = items:get(i)
        if item and item.IsInventoryContainer and item:IsInventoryContainer() and item.getInventory then
            collectManagedSlingsFromContainer(item:getInventory(), seen, results)
        end

        if item and item.getID and RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(item) then
            local itemId = item:getID()
            if not seen[itemId] then
                seen[itemId] = true
                results[#results + 1] = item
            end
        end
    end
end

local function collectManagedWornSlings(player, seen, results)
    if not player or not player.getWornItems then
        return
    end

    local wornItems = player:getWornItems()
    if not wornItems then
        return
    end

    for i = 0, wornItems:size() - 1 do
        local worn = wornItems:get(i)
        local item = worn and worn.getItem and worn:getItem() or nil
        if item and item.getID and RifleSling.isManagedSlingItem and RifleSling.isManagedSlingItem(item) then
            local itemId = item:getID()
            if not seen[itemId] then
                seen[itemId] = true
                results[#results + 1] = item
            end
        end
    end
end

local function getManagedSlingItems(player)
    local results = {}
    if not player then
        return results
    end

    local seen = {}
    local inventory = player.getInventory and player:getInventory() or nil
    if inventory then
        collectManagedSlingsFromContainer(inventory, seen, results)
    end
    collectManagedWornSlings(player, seen, results)
    return results
end

local function buildSlingTooltip(player, item)
    if not player or not item then
        return nil
    end

    local pose = getPoseDetails(item)
    local lines = {
        "Pose: " .. tostring(pose.label or "Sling"),
        "Preset: " .. tostring(pose.variantLabel or "Standard"),
    }

    if isItemWornByPlayer(player, item) then
        local familyKey = RifleSling.getPoseFamily and RifleSling.getPoseFamily(item) or nil
        local slotNumber = getFamilySlotNumber(familyKey)
        local attachedRecord = RifleSling.findAttachedWeaponForFamily and RifleSling.findAttachedWeaponForFamily(player, item) or nil

        lines[#lines + 1] = "Status: Worn"
        if slotNumber then
            lines[#lines + 1] = "Slot: Sling Slot " .. tostring(slotNumber)
        end
        local weaponLabel = "Empty"
        if attachedRecord and attachedRecord.weapon then
            local formatter = C and C.formatWeaponLabel or formatWeaponLabel
            weaponLabel = formatter and formatter(attachedRecord.weapon) or "Weapon"
        end
        lines[#lines + 1] = "Weapon: " .. tostring(weaponLabel)
    else
        local desiredType = item.getFullType and item:getFullType() or nil
        local targetFamily = nil
        if RifleSling.resolveWearTypeForNextFreeFamily then
            local _, resolvedFamily = RifleSling.resolveWearTypeForNextFreeFamily(player, desiredType)
            targetFamily = resolvedFamily
        end

        lines[#lines + 1] = "Status: Inventory"
        if targetFamily then
            local slotNumber = getFamilySlotNumber(targetFamily)
            if slotNumber then
                lines[#lines + 1] = "Next Slot: Sling Slot " .. tostring(slotNumber)
            end
        else
            lines[#lines + 1] = "Next Slot: None free"
        end
    end

    local scriptItem = item.getScriptItem and item:getScriptItem() or nil
    local scriptTooltip = scriptItem and scriptItem.getTooltip and scriptItem:getTooltip() or nil
    if scriptTooltip and scriptTooltip ~= "" and getText then
        lines[#lines + 1] = getText(scriptTooltip)
    end

    return table.concat(lines, " <LINE> ")
end

local function safeBuildSlingTooltip(player, item)
    local ok, tooltip = pcall(buildSlingTooltip, player, item)
    if ok then
        return tooltip
    end

    return nil
end

refreshManagedSlingTooltips = function(player)
    if not player then
        return
    end

    for _, item in ipairs(getManagedSlingItems(player)) do
        if item and item.setTooltip then
            item:setTooltip(safeBuildSlingTooltip(player, item))
        end
    end
end

local function processSyncQueue(player)
    if not player or (player.isLocalPlayer and not player:isLocalPlayer()) then
        return
    end

    local now = getNowSeconds()
    pruneExpectedManagedAttachmentOps()

    for requestId, pending in pairs(RifleSling._pendingRequests) do
        if pending.stale or (pending.createdAt and now > 0 and (now - pending.createdAt) > 15) then
            RifleSling._pendingRequests[requestId] = nil
        end
    end

    for onlineId, attemptsLeft in pairs(RifleSling._syncRefreshQueue) do
        local numericId = tonumber(onlineId)
        if refreshObservedPlayerByOnlineId(numericId) or attemptsLeft <= 0 then
            RifleSling._syncRefreshQueue[onlineId] = nil
        else
            RifleSling._syncRefreshQueue[onlineId] = attemptsLeft - 1
        end
    end

    RifleSling._tooltipRefreshTick = (RifleSling._tooltipRefreshTick or 0) + 1
    if RifleSling._tooltipRefreshTick >= TOOLTIP_REFRESH_INTERVAL then
        RifleSling._tooltipRefreshTick = 0
        refreshManagedSlingTooltips(player)
    end
end

function RifleSling.clientRequestSetAttached(player, weapon, attached, slotType, slotName, slotIndex)
    if not player or not weapon then
        return
    end

    if not slotType or not RifleSling.isManagedAttachmentSlotType or not RifleSling.isManagedAttachmentSlotType(slotType) then
        return
    end

    if isClient and isClient() and sendClientCommand then
        if RifleSling.hasPendingAction and RifleSling.hasPendingAction("attach", weapon:getID()) then
            return
        end
        local requestId = RifleSling.beginRequest("attach", weapon:getID())
        sendClientCommand("RifleSling", RifleSling.Commands.SetAttached, {
            weaponId = weapon:getID(),
            attached = attached and true or false,
            slotType = slotType,
            slotName = slotName,
            slotIndex = slotIndex,
            requestId = requestId,
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
    else
        return
    end
    notify(player, message, ok)
end

function RifleSling.clientNotifyManagedAttachment(player, item, attached, slotType, slotName, slotIndex)
    if not player or not item or not slotType then
        return
    end

    if not RifleSling.isManagedAttachmentSlotType or not RifleSling.isManagedAttachmentSlotType(slotType) then
        return
    end

    if not RifleSling.consumeExpectedManagedAttachment or not RifleSling.consumeExpectedManagedAttachment(item, attached, slotType, slotName, slotIndex) then
        return
    end

    if RifleSling.isManagedSlingSlotType and RifleSling.isManagedSlingSlotType(slotType) then
        return RifleSling.clientRequestSetAttached(player, item, attached, slotType, slotName, slotIndex)
    end

    if isClient and isClient() and sendClientCommand then
        if RifleSling.hasPendingAction and RifleSling.hasPendingAction("attach", item:getID()) then
            return
        end
        local requestId = RifleSling.beginRequest("attach", item:getID())
        sendClientCommand("RifleSling", RifleSling.Commands.SetAttached, {
            weaponId = item:getID(),
            attached = attached and true or false,
            slotType = slotType,
            slotName = slotName,
            slotIndex = slotIndex,
            requestId = requestId,
        })
        return
    end

    RifleSling.refreshLocalPlayer()
end

local function onServerCommand(module, command, args)
    if module ~= "RifleSling" then
        return
    end

    local player = getLocalPlayer()
    if not player or not args then
        return
    end

    if command == RifleSling.Commands.Result then
        if args.data then
            rememberItemRedirect(args.data.oldItemId, args.data.newItemId)
            cleanupRedirectedManagedItem(player, args.data.oldItemId, args.data.newItemId)
        end
        RifleSling.finishRequest(args.requestId)
        RifleSling.refreshLocalPlayer()
        if not refreshObservedPlayer(args) then
            queueObservedPlayerRefresh(args.onlineID)
        end
        notify(player, tostring(args.message or "Rifle Sling updated"), args.ok ~= false)
        return
    end

    if command == RifleSling.Commands.Sync then
        rememberItemRedirect(args.oldItemId, args.newItemId)
        cleanupRedirectedManagedItem(player, args.oldItemId, args.newItemId)
        if not refreshObservedPlayer(args) then
            queueObservedPlayerRefresh(args.onlineID)
        end
        if RifleSling.refreshLocalPlayer then
            RifleSling.refreshLocalPlayer()
        end
        return
    end

    if command == RifleSling.Commands.Notify then
        notify(player, tostring(args.message or "Rifle Sling updated"), args.ok ~= false)
    end
end

local function onHandItemChanged(player, item)
    if not player or not item then
        return
    end
    if not RifleSling.isLongGun(item) or not RifleSling.isSlingAttached(item) then
        return
    end

    if (not player.isLocalPlayer) or player:isLocalPlayer() then
        notify(player, "Rifle sling active", true)
    end
end

C.QUICK_SWAP_BINDING = QUICK_SWAP_BINDING
C.notify = notify
C.getLocalPlayer = getLocalPlayer
C.getFamilySlotNumber = getFamilySlotNumber
C.getNowSeconds = getNowSeconds
C.refreshPlayerModel = refreshPlayerModel
C.markInventoryDirty = markInventoryDirty
C.refreshHotbarForPlayer = refreshHotbarForPlayer
C.resolveManagedClientItem = resolveManagedClientItem
C.rememberItemRedirect = rememberItemRedirect
C.cleanupRedirectedManagedItem = cleanupRedirectedManagedItem
C.getManagedGearConfig = getManagedGearConfig
C.getManagedSlotLabel = getManagedSlotLabel
C.refreshObservedPlayerByOnlineId = refreshObservedPlayerByOnlineId
C.refreshObservedPlayer = refreshObservedPlayer
C.queueObservedPlayerRefresh = queueObservedPlayerRefresh
C.isItemWornByPlayer = isItemWornByPlayer
C.getPoseDetails = getPoseDetails
C.refreshManagedSlingTooltips = refreshManagedSlingTooltips

require "RifleSling_Client_Slots"
require "RifleSling_Client_Context"

formatWeaponLabel = C.formatWeaponLabel or formatWeaponLabel

if Events and Events.OnServerCommand then
    Events.OnServerCommand.Add(onServerCommand)
end
if Events and Events.OnEquipPrimary then
    Events.OnEquipPrimary.Add(onHandItemChanged)
end
if Events and Events.OnEquipSecondary then
    Events.OnEquipSecondary.Add(onHandItemChanged)
end
if Events and Events.OnPlayerUpdate then
    Events.OnPlayerUpdate.Add(processSyncQueue)
end
