local fs = require("filesystem")
local paths = require("paths")
local calls = {} --calls позваляет вызывать функции с жеского диска, что экономит оперативную память

function calls.load(name)
    local full_path = paths.concat("/system/core/calls", name .. ".lua")
    if not fs.exists(full_path) then
        return nil, "call " .. name .. " is not found"
    end

    local file = assert(fs.open(full_path, "rb"))
    local data = file.readAll()
    file.close()

    return assert(load(data, "=" .. full_path, nil, _G)) --не _ENV потому что там "личьные" глобалы в _G то что нужно системным вызовам
end

function calls.call(name, ...)
    return calls.load(name)(...)
end

return calls