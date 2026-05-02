require "ISUI/ISPanelJoypad"

local MANAGED_WEARABLES = {
    ["Base.JSling_TacticalVest"] = true,
    ["Base.JSling_ChestRig"] = true,
    ["Base.JSling_Webbing"] = true,
    ["Base.JSling_WebbingLoose"] = true,
    ["Base.JSling_Webbing_Military"] = true,
    ["Base.JSling_Webbing_MilitaryLoose"] = true,
    ["Base.JSling_Webbing_Black"] = true,
    ["Base.JSling_Webbing_BlackLoose"] = true,
    ["Base.JSling_BackRig"] = true,
    ["Base.JSling_KnifeSheath"] = true,
    ["Base.JSling_KnifeSheathBack"] = true,
    ["Base.JSling_KatanaSheath"] = true,
}

local originalActivateSlot = ISHotbar.activateSlot

function ISHotbar:activateSlot(slotIndex)
    local item = self.attachedItems[slotIndex]
    if not item or not item.getFullType or not MANAGED_WEARABLES[item:getFullType()] then
        return originalActivateSlot(self, slotIndex)
    end

    if item:isEquipped() then
        ISTimedActionQueue.add(ISUnequipAction:new(self.chr, item, 50))
    else
        ISTimedActionQueue.add(ISWearClothing:new(self.chr, item, 50))
    end
end
