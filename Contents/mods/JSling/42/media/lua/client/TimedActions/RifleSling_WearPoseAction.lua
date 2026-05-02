require "TimedActions/ISBaseTimedAction"

RifleSling_WearPoseAction = ISBaseTimedAction:derive("RifleSling_WearPoseAction")

local function resolveInventoryItem(character, item)
    if not character or not item then
        return nil
    end

    local inv = character:getInventory()
    if not inv or not item.getID then
        return item
    end

    local resolved = inv:getItemById(item:getID())
    return resolved or item
end

function RifleSling_WearPoseAction:isValid()
    if not self.character or not self.item or not self.desiredType then
        return false
    end

    self.item = resolveInventoryItem(self.character, self.item)
    if not self.item or not self.character:getInventory():contains(self.item) then
        return false
    end

    if self.character.isEquippedClothing and self.character:isEquippedClothing(self.item) then
        return false
    end

    if RifleSling and RifleSling.resolveWearTypeForNextFreeFamily then
        local resolvedType = RifleSling.resolveWearTypeForNextFreeFamily(self.character, self.desiredType)
        return resolvedType ~= nil
    end

    return true
end

function RifleSling_WearPoseAction:start()
    self.item = resolveInventoryItem(self.character, self.item)

    self.item:setJobType("Wear Rifle Sling")
    self.item:setJobDelta(0.0)
    self:setActionAnim("WearClothing")
    self:setAnimVariable("WearClothingLocation", "Jacket")
    self:setOverrideHandModels(nil, nil)
    self.character:reportEvent("EventWearClothing")
    self.sound = self.character:playSound("RummageInInventory")
    self.soundNoTrigger = true
end

function RifleSling_WearPoseAction:update()
    if self.item then
        self.item:setJobDelta(self:getJobDelta())
    end
end

function RifleSling_WearPoseAction:stopSound()
    if self.sound and self.character:getEmitter():isPlaying(self.sound) then
        if self.soundNoTrigger then
            self.character:getEmitter():stopSound(self.sound)
        else
            self.character:stopOrTriggerSound(self.sound)
        end
    end
end

function RifleSling_WearPoseAction:stop()
    if RifleSling and RifleSling.clearLocalQueuedAction and self.itemId then
        RifleSling.clearLocalQueuedAction("wear", self.itemId)
    end

    if self.item then
        self.item:setJobDelta(0.0)
    end
    self:stopSound()
    ISBaseTimedAction.stop(self)
end

function RifleSling_WearPoseAction:perform()
    if RifleSling and RifleSling.clearLocalQueuedAction and self.itemId then
        RifleSling.clearLocalQueuedAction("wear", self.itemId)
    end

    self:stopSound()

    if self.item then
        self.item:setJobDelta(0.0)
    end

    if isClient() and sendClientCommand then
        if RifleSling.hasPendingAction and RifleSling.hasPendingAction("wear", self.item:getID()) then
            ISBaseTimedAction.perform(self)
            return
        end

        local requestId = RifleSling.beginRequest and RifleSling.beginRequest("wear", self.item:getID()) or nil
        sendClientCommand("RifleSling", RifleSling.Commands.WearPose, {
            itemId = self.item:getID(),
            desiredType = self.desiredType,
            requestId = requestId,
        })
    else
        local ok = RifleSling.wearSlingToNextFreeFamily(self.character, self.item, self.desiredType)
        if ok and RifleSling.refreshLocalPlayer then
            RifleSling.refreshLocalPlayer()
        end
    end

    ISBaseTimedAction.perform(self)
end

function RifleSling_WearPoseAction:new(character, item, desiredType)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.itemId = item and item.getID and item:getID() or nil
    o.desiredType = desiredType
    o.maxTime = character:isTimedActionInstant() and 1 or 45
    o.stopOnWalk = true
    o.stopOnRun = true
    o.clothingAction = true
    o.fromHotbar = false
    return o
end
