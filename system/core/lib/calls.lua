local fs = require("filesystem")
local paths = require("paths")
local calls = {}

function calls.call(name)
    local full_path = paths.concat("/system/core/calls", name .. ".lua")
    if not fs.exists(full_path) then
        return nil, "call " .. name .. " is not found"
    end

    local file = assert(fs.open(full_path, "rb"))
    local data = file.readAll()
    file.close()

    return data
end

return calls