local fs = require("filesystem")
local serialization = require("serialization")

--------------------------------

local registry = {unloaded = true, data = {}, path = "/data/registry.dat"}
if fs.exists(registry.path) then
    local content = fs.readFile(registry.path)
    if content then
        local result = {pcall(serialization.unserialization, content)}
        if result[1] and type(result[2]) == "table" then
            registry.data = result[2]
        end
    end
end

function registry.save()
    fs.writeFile(registry.path, serialization.serialization(registry.data))
end

setmetatable(registry, {__newindex = function(tbl, key, value)
    if registry.data[key] ~= value then
        registry.data[key] = value
        registry.save()
    end
end, __index = function(tbl, key)
    return registry.data[key]
end})

return registry