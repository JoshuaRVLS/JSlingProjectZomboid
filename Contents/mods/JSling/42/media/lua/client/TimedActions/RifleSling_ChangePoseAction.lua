require "TimedActions/ISBaseTimedAction"

RifleSling_ChangePoseAction = ISBaseTimedAction:derive("RifleSling_ChangePoseAction")

local function resolveInventoryItem(character, item)
    if not character or not item then
        return nil
    end

    if RifleSling and RifleSling.resolveManagedClientItem then
        local resolved = RifleSling.resolveManagedClientItem(character, item)
        if resolved then
            return resolved
        end
    end

    if RifleSling and RifleSling.findItemById and item.getID then
        local resolved = RifleSling.findItemById(character, item:getID())
        if resolved then
            return resolved
        end
    end

    local inv = character:getInventory()
    if not inv or not item.getID then
        return item
    end

    local resolved = inv:getItemById(item:getID())
    return resolved or item
end

function RifleSling_ChangePoseAction:isValid()
    if not self.character or not self.item or not self.newType then
        return false
    end

    self.item = resolveInventoryItem(self.character, self.item)
    if not self.item then
        return false
    end

    if not (self.character.isEquippedClothing and self.character:isEquippedClothing(self.item)) then
        return false
    end

    return self.item:getFullType() ~= self.newType
end

function RifleSling_ChangePoseAction:start()
    self.item = resolveInventoryItem(self.character, self.item)

    self.item:setJobType("Adjust Sling Pose")
    self.item:setJobDelta(0.0)
    self:setActionAnim("WearClothing")
    self:setAnimVariable("WearClothingLocation", "Jacket")
    self:setOverrideHandModels(nil, nil)
    self.character:reportEvent("EventWearClothing")
    self.sound = self.character:playSound("RummageInInventory")
    self.soundNoTrigger = true
end

function RifleSling_ChangePoseAction:update()
    if self.item then
        self.item:setJobDelta(self:getJobDelta())
    end
end

function RifleSling_ChangePoseAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        if self.soundNoTrigger then
            self.character:getEmitter():stopSound(self.sound)
        else
            self.character:stopOrTriggerSound(self.sound)
        end
    end
end

function RifleSling_ChangePoseAction:stop()
    if RifleSling and RifleSling.clearLocalQueuedAction and self.itemId then
        RifleSling.clearLocalQueuedAction("pose", self.itemId)
    end

    if self.item then
        self.item:setJobDelta(0.0)
    end
    self:stopSound()
    ISBaseTimedAction.stop(self)
end

function RifleSling_ChangePoseAction:perform()
    if RifleSling and RifleSling.clearLocalQueuedAction and self.itemId then
        RifleSling.clearLocalQueuedAction("pose", self.itemId)
    end

    self:stopSound()

    if self.item then
        self.item:setJobDelta(0.0)
    end

    if isClient() and sendClientCommand then
        if RifleSling.hasPendingAction and RifleSling.hasPendingAction("pose", self.item:getID()) then
            ISBaseTimedAction.perform(self)
            return
        end

        local requestId = RifleSling.beginRequest and RifleSling.beginRequest("pose", self.item:getID()) or nil
        sendClientCommand("RifleSling", RifleSling.Commands.SetPose, {
            itemId = self.item:getID(),
            newType = self.newType,
            weaponId = self.detachedWeaponId,
            oldSlotType = self.oldSlotType,
            oldSlotIndex = self.oldSlotIndex,
            requestId = requestId,
        })
    else
        local detachedWeapon = self.detachedWeaponId and RifleSling.findItemById and RifleSling.findItemById(self.character, self.detachedWeaponId) or nil
        RifleSling.swapSlingPose(self.character, self.item, self.newType, detachedWeapon, self.oldSlotType, self.oldSlotIndex)
        if RifleSling.refreshLocalPlayer then
            RifleSling.refreshLocalPlayer()
        end
    end

    ISBaseTimedAction.perform(self)
end

function RifleSling_ChangePoseAction:new(character, item, newType, detachedWeaponId, oldSlotType, oldSlotIndex)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.itemId = item and item.getID and item:getID() or nil
    o.newType = newType
    o.detachedWeaponId = detachedWeaponId
    o.oldSlotType = oldSlotType
    o.oldSlotIndex = oldSlotIndex
    o.maxTime = character:isTimedActionInstant() and 1 or 45
    o.stopOnWalk = true
    o.stopOnRun = true
    o.clothingAction = true
    o.fromHotbar = true
    return o
end
