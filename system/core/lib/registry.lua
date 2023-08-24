local fs = require("filesystem")

--------------------------------

local registry = {}
registry.data = {}
registry.path = "/data/registry.dat"
registry.unloaded = true

function registry.get()
    if fs.exists(registry.path) then
        return unserialization(getFile(registry.path))
    end
    return {}
end

function registry.set(data)
    saveFile(registry.path, serialization(data))
end

function registry.read(key)
    return registry.data[key]
end

function registry.write(key, value)
    registry.data[key] = value
    registry.set(registry.data)
end

setmetatable(registry, {__newindex = function(tbl, key, value)
    if registry.data[key] ~= value then
        registry.data[key] = value
        registry.set(registry.data)
    end
end, __index = function(tbl, key)
    return registry.data[key]
end})

registry.data = registry.get()
return registry