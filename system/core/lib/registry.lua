local fs = require("filesystem")

--------------------------------

local registry = {}
registry.path = "/data/registry.dat"

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
    local data = registry.get()
    return data[key]
end

function registry.write(key, value)
    local data = registry.get()
    data[key] = value
    registry.set(data)
end

setmetatable(registry, {__newindex = function(tbl, key, value)
    rawset(tbl, key, nil)
    registry.write(key, value)
end, __index = function(tbl, key)
    return registry.read(key)
end})

return registry