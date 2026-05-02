local group = BodyLocations.getGroup("Human")

local function registerManagedBodyLocation(name)
    local itemBodyLocation = ItemBodyLocation.get(ResourceLocation.new("jsling", name))
    if itemBodyLocation then
        group:getOrCreateLocation(itemBodyLocation)
    end
end

for _, name in ipairs({
    "slinga",
    "slingb",
    "hunkvest",
    "knifesheathback",
    "katanasheath",
    "back2",
    "back3",
    "chestrig",
    "torsorig",
    "backrig",
    "knifesheath",
    "bandolier",
}) do
    registerManagedBodyLocation(name)
end
