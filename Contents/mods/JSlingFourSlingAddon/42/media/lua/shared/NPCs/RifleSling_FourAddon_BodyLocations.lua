local group = BodyLocations.getGroup("Human")

local function registerBodyLocation(name)
    local itemBodyLocation = ItemBodyLocation.get(ResourceLocation.new("jslingfour", name))
    if itemBodyLocation then
        group:getOrCreateLocation(itemBodyLocation)
    end
end

registerBodyLocation("slingc")
registerBodyLocation("slingd")
