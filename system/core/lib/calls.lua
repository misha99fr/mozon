local fs = require("filesystem")
local unicode = require("unicode")
local paths = require("paths")

------------------------------------

local calls = {} --calls позваляет вызывать функции с жеского диска, что экономит оперативную память
calls.paths = {"/system/core/calls", "/system/calls"}
calls.loaded = {}
--calls.loaded нужен на случай, если необходимо чтобы call был загружен в память постоянно, авто кеширования тут нет,
--но в случаи если вы хотите вы можете поместить туда функцию чтобы избежать дублирования(после добавления кеша, используйте loaded в ситуации которая произошла в //system/core/calls/writebit.lua(ленб разписывать))
calls.cache = {}
setmetatable(calls.cache, {__mode = "v"})

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
    if calls.loaded[name] or calls.cache[name] then return calls.loaded[name] or calls.cache[name] end

    local path = calls.find(name)
    if not path then return nil, "no such call" end

    local file, err = fs.open(path, "rb")
    if not file then return nil, err end
    local data = file.readAll()
    file.close()

    local code, err = load(data, "=" .. path, nil, _G)
    if not code then return nil, err end

    calls.cache[name] = code
    return code --не _ENV потому что там "личьные" глобалы в _G то что нужно системным вызовам
end

function calls.call(name, ...)
    return calls.load(name)(...)
end

setmetatable(_G, {__index = function(self, key)
    return calls.load(key)
end})

return calls