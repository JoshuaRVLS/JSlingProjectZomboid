if getActivatedMods():contains("\\nattachments") then return end

local _RifleSling_originalAttachPerform = ISAttachItemHotbar.perform

local function isBack(slot)
    if not slot then return false end
    return string.find(slot, " Back")
end

local function isSling(attachmentType, slot)
    if slot and string.find(slot, "Sling") then
        return attachmentType .. "Sling"
    end
    return attachmentType
end

local function isSlingSlotDef(slotDef)
    if not slotDef or not slotDef.type then
        return false
    end
    return string.find(slotDef.type, "Sling") ~= nil
end

local function isManagedSlotDef(slotDef)
    return slotDef and slotDef.type and RifleSling and RifleSling.isManagedAttachmentSlotType
        and RifleSling.isManagedAttachmentSlotType(slotDef.type)
end

function ISAttachItemHotbar:perform()
    if not isManagedSlotDef(self.slotDef) then
        return _RifleSling_originalAttachPerform(self)
    end

    local attachmentType = isSling(self.item:getAttachmentType(), self.slot)

    if self.hotbar
        and self.hotbar.attachedItems
        and self.hotbar.attachedItems[self.slotIndex] then
        local current = self.hotbar.attachedItems[self.slotIndex]
        self.hotbar.chr:removeAttachedItem(current)
        current:setAttachedSlot(-1)
        current:setAttachedSlotType(nil)
        current:setAttachedToModel(nil)
    end

    if self.hotbar
        and self.hotbar.replacements
        and self.hotbar.replacements[attachmentType]
        and isBack(self.slot) then
        self.slot = self.hotbar.replacements[attachmentType]
        if self.slot == "null" then
            self.hotbar:removeItem(self.item)
            return
        end
    end

    self.hotbar.chr:setAttachedItem(self.slot, self.item)
    self.item:setAttachedSlot(self.slotIndex)

    if self.slotDef and self.slotDef.type then
        self.item:setAttachedSlotType(self.slotDef.type)
    end

    self.item:setAttachedToModel(self.slot)

    if self.hotbar.reloadIcons then
        self.hotbar:reloadIcons()
    end

    if ISInventoryPage then
        ISInventoryPage.renderDirty = true
    end

    if RifleSling and RifleSling.markExpectedManagedAttachment then
        RifleSling.markExpectedManagedAttachment(
            self.item,
            true,
            self.slotDef and self.slotDef.type or nil,
            self.slot,
            self.slotIndex
        )
    end

    if RifleSling and RifleSling.clientNotifyManagedAttachment then
        RifleSling.clientNotifyManagedAttachment(
            self.hotbar and self.hotbar.chr or self.character,
            self.item,
            true,
            self.slotDef and self.slotDef.type or nil,
            self.slot,
            self.slotIndex
        )
    end

    ISBaseTimedAction.perform(self)
end
