local fs = require("filesystem")
local paths = require("paths")

------------------------------------

local calls = {} --calls позваляет вызывать функции с жеского диска, что экономит оперативную память
calls.paths = {"/system/core/calls", "/system/calls"}
calls.loaded = {}
--calls.loaded нужен на случай, если необходимо чтобы call был загружен в память постоянно, авто кеширования тут нет,
--но в случаи если вы хотите вы можете поместить туда функцию чтобы избежать дублирования

function calls.find(name)
    if unicode.sub(name, 1, 1) == "/" then
        return name
    else
        for i, v in ipairs(calls.paths) do
            local path = paths.concat(v, name .. ".lua")
            if fs.exists(path) then
                return path
            end
        end
    end
end

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