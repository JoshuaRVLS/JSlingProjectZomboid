if getActivatedMods():contains("\\nattachments") then return end

local _RifleSling_originalAttachItem = ISHotbar.attachItem
local _RifleSling_originalRemoveItem = ISHotbar.removeItem

local function isSlingSlotDef(slotDef)
	if not slotDef or not slotDef.type then return false end
	return string.find(slotDef.type, "Sling") ~= nil
end

local function isManagedSlotDef(slotDef)
	if not slotDef or not slotDef.type or not RifleSling or not RifleSling.isManagedAttachmentSlotType then
		return false
	end
	return RifleSling.isManagedAttachmentSlotType(slotDef.type)
end

function ISHotbar:attachItem (item, slot, slotIndex, slotDef, doAnim)
	if not isManagedSlotDef(slotDef) then
		return _RifleSling_originalAttachItem(self, item, slot, slotIndex, slotDef, doAnim)
	end

	local attachmentType = isSling(item:getAttachmentType(),slot)
	if doAnim then
		if self.replacements and self.replacements[attachmentType] and isBack(slot) then
			slot = self.replacements[attachmentType];
		end
		self:setAttachAnim(item, slotDef);
		ISInventoryPaneContextMenu.transferIfNeeded(self.chr, item)
		if self.attachedItems[slotIndex] then
			ISTimedActionQueue.add(ISDetachItemHotbar:new(self.chr, self.attachedItems[slotIndex]));
		end
		ISTimedActionQueue.add(ISAttachItemHotbar:new(self.chr, item, slot, slotIndex, slotDef));
	else
		if self.replacements and self.replacements[attachmentType] and isBack(slot) then
			slot = self.replacements[attachmentType];
			if slot == "null" then
				self:removeItem(item, false);
				return;
			end
		end
		self.chr:setAttachedItem(slot, item);
		item:setAttachedSlot(slotIndex);
		item:setAttachedSlotType(slotDef.type);
		item:setAttachedToModel(slot);

		self:reloadIcons();

		if RifleSling and RifleSling.markExpectedManagedAttachment then
			RifleSling.markExpectedManagedAttachment(item, true, slotDef.type, slot, slotIndex)
		end

		if RifleSling and RifleSling.clientNotifyManagedAttachment then
			RifleSling.clientNotifyManagedAttachment(self.chr, item, true, slotDef.type, slot, slotIndex)
		end
	end
end

function ISHotbar:removeItem(item, doAnim)
	if not item or not item.getAttachedSlotType then
		return _RifleSling_originalRemoveItem(self, item, doAnim)
	end

	local slotType = item:getAttachedSlotType()
	local slotName = item.getAttachedToModel and item:getAttachedToModel() or nil
	local slotIndex = item.getAttachedSlot and item:getAttachedSlot() or nil
	if not RifleSling or not RifleSling.isManagedAttachmentSlotType or not RifleSling.isManagedAttachmentSlotType(slotType) then
		return _RifleSling_originalRemoveItem(self, item, doAnim)
	end

	if doAnim then
		return _RifleSling_originalRemoveItem(self, item, doAnim)
	end

	if RifleSling and RifleSling.markExpectedManagedAttachment then
		RifleSling.markExpectedManagedAttachment(item, false, slotType, slotName, slotIndex)
	end

	_RifleSling_originalRemoveItem(self, item, doAnim)

	if RifleSling and RifleSling.clientNotifyManagedAttachment then
		RifleSling.clientNotifyManagedAttachment(self.chr, item, false, slotType, slotName, slotIndex)
	end
end

function isBack(slot)
	if not slot then return false end
	return string.find(slot," Back");
end

function isSling(attachmentType,slot)
	if slot and (string.find(slot,"Sling")) then
		return attachmentType.."Sling"
	end
	return attachmentType
end
