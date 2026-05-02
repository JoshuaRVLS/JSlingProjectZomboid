require "TimedActions/ISBaseTimedAction"

RifleSling_ManagedUnequipAction = ISBaseTimedAction:derive("RifleSling_ManagedUnequipAction")

local function resolveManagedItem(character, item)
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

    return item
end

function RifleSling_ManagedUnequipAction:isValid()
    if not self.character or not self.item then
        return false
    end

    self.item = resolveManagedItem(self.character, self.item)
    if not self.item then
        return false
    end

    if self.character.isEquippedClothing and self.character:isEquippedClothing(self.item) then
        return true
    end

    if self.character.isEquipped and self.character:isEquipped(self.item) then
        return true
    end

    return false
end

function RifleSling_ManagedUnequipAction:start()
    self.item = resolveManagedItem(self.character, self.item)
    if self.item then
        self.item:setJobType("Unequip")
        self.item:setJobDelta(0.0)
    end
    self:setActionAnim("WearClothing")
    self:setAnimVariable("WearClothingLocation", "Jacket")
    self:setOverrideHandModels(nil, nil)
    self.character:reportEvent("EventWearClothing")
end

function RifleSling_ManagedUnequipAction:update()
    if self.item then
        self.item:setJobDelta(self:getJobDelta())
    end
end

function RifleSling_ManagedUnequipAction:stop()
    if self.item then
        self.item:setJobDelta(0.0)
    end
    ISBaseTimedAction.stop(self)
end

function RifleSling_ManagedUnequipAction:perform()
    if self.item then
        self.item:setJobDelta(0.0)
    end

    local resolved = resolveManagedItem(self.character, self.item)
    if resolved and ISInventoryPaneContextMenu and ISInventoryPaneContextMenu.unequipItem then
        RifleSling._forceVanillaUnequip = true
        ISInventoryPaneContextMenu.unequipItem(resolved, self.character:getPlayerNum())
        RifleSling._forceVanillaUnequip = nil
    end

    ISBaseTimedAction.perform(self)
end

function RifleSling_ManagedUnequipAction:new(character, item, maxTime)
    local o = ISBaseTimedAction.new(self, character)
    o.character = character
    o.item = item
    o.maxTime = character:isTimedActionInstant() and 1 or (maxTime or 35)
    o.stopOnWalk = true
    o.stopOnRun = true
    o.clothingAction = true
    o.fromHotbar = true
    return o
end
