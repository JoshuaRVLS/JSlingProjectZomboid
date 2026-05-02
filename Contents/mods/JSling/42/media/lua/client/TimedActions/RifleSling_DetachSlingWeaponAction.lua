require "TimedActions/ISBaseTimedAction"

RifleSling_DetachSlingWeaponAction = ISBaseTimedAction:derive("RifleSling_DetachSlingWeaponAction")

local function resolveInventoryItem(character, item)
    if not character or not item then
        return nil
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

function RifleSling_DetachSlingWeaponAction:isValid()
    if not self.character or not self.item then
        return false
    end

    self.item = resolveInventoryItem(self.character, self.item)
    if not self.item then
        return false
    end

    local inv = self.character:getInventory()
    if not self.item then
        return false
    end

    return self.item.getAttachedSlotType and self.item:getAttachedSlotType() ~= nil
end

function RifleSling_DetachSlingWeaponAction:start()
    self.item = resolveInventoryItem(self.character, self.item)
    self.item:setJobType("Unsling Weapon")
    self.item:setJobDelta(0.0)
    self:setActionAnim("WearClothing")
    self:setAnimVariable("WearClothingLocation", "Jacket")
    self:setOverrideHandModels(nil, nil)
    self.character:reportEvent("EventWearClothing")
end

function RifleSling_DetachSlingWeaponAction:update()
    if self.item then
        self.item:setJobDelta(self:getJobDelta())
    end
end

function RifleSling_DetachSlingWeaponAction:stop()
    if self.item then
        self.item:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function RifleSling_DetachSlingWeaponAction:perform()
    if self.item then
        self.item:setJobDelta(0.0)
    end

    local slotType = self.item and self.item.getAttachedSlotType and self.item:getAttachedSlotType() or nil
    local slotName = self.item and self.item.getAttachedToModel and self.item:getAttachedToModel() or nil
    local slotIndex = self.item and self.item.getAttachedSlot and self.item:getAttachedSlot() or nil

    local hotbar = self.hotbar or (getPlayerHotbar and getPlayerHotbar(self.character:getPlayerNum()) or nil)
    if hotbar then
        hotbar.chr:removeAttachedItem(self.item)
        self.item:setAttachedSlot(-1)
        self.item:setAttachedSlotType(nil)
        self.item:setAttachedToModel(nil)

        if hotbar.reloadIcons then
            hotbar:reloadIcons()
        end
    end

    ISInventoryPage.renderDirty = true
    if syncItemFields then
        syncItemFields(self.character, self.item)
    end

    if slotType and RifleSling and RifleSling.markExpectedManagedAttachment then
        RifleSling.markExpectedManagedAttachment(self.item, false, slotType, slotName, slotIndex)
    end

    if slotType and RifleSling and RifleSling.clientNotifyManagedAttachment then
        RifleSling.clientNotifyManagedAttachment(self.character, self.item, false, slotType, slotName, slotIndex)
    end

    ISBaseTimedAction.perform(self)
end

function RifleSling_DetachSlingWeaponAction:new(character, item)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.stopOnWalk = false
    o.stopOnRun = true
    o.fromHotbar = true
    o.ignoreHandsWounds = true
    o.useProgressBar = true
    o.hotbar = getPlayerHotbar and getPlayerHotbar(character:getPlayerNum()) or nil
    o.maxTime = character:isTimedActionInstant() and 1 or 25
    return o
end
