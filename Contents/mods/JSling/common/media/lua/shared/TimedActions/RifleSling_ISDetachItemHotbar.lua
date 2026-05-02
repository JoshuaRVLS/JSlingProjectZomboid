local function getManagedSlotType(item)
    if not item or not item.getAttachedSlotType then
        return nil
    end

    local slotType = item:getAttachedSlotType()
    if RifleSling and RifleSling.isManagedAttachmentSlotType and RifleSling.isManagedAttachmentSlotType(slotType) then
        return slotType
    end
    return nil
end

local function patchDetachItemHotbar()
    if not ISDetachItemHotbar or not ISDetachItemHotbar.perform then
        return
    end

    if ISDetachItemHotbar._RifleSlingPatched then
        return
    end

    local originalPerform = ISDetachItemHotbar.perform

    function ISDetachItemHotbar:perform()
        local slotType = getManagedSlotType(self.item)
        local slotName = self.item and self.item.getAttachedToModel and self.item:getAttachedToModel() or nil
        local slotIndex = self.item and self.item.getAttachedSlot and self.item:getAttachedSlot() or nil
        local character = self.character
        local item = self.item

        originalPerform(self)

        if slotType and RifleSling and RifleSling.markExpectedManagedAttachment then
            RifleSling.markExpectedManagedAttachment(item, false, slotType, slotName, slotIndex)
        end

        if slotType and RifleSling and RifleSling.clientNotifyManagedAttachment then
            RifleSling.clientNotifyManagedAttachment(character, item, false, slotType, slotName, slotIndex)
        end
    end

    ISDetachItemHotbar._RifleSlingPatched = true
end

patchDetachItemHotbar()

if Events and Events.OnGameBoot then
    Events.OnGameBoot.Add(patchDetachItemHotbar)
end
