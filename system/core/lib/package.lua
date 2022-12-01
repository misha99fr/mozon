local raw_dofile, createEnv = ...
local component = component
local computer = computer
local unicode = unicode

------------------------------------

local package = {}
package.paths = {"/system/core/lib", "/system/lib", "/data/lib", "/vendor/lib"}
package.loaded = {package = package}
package.cache = {}
setmetatable(package.cache, {__mode = "v"})

function package.find(name)
    if unicode.sub(name, 1, 1) == "/" then
        return name
    else
        local fs = require("filesystem")
        local paths = require("paths")

        for i, v in ipairs(package.paths) do
            local path = paths.concat(v, name .. ".lua")
            if fs.exists(path) then
                return path
            end
        end
    end
end

function _G.require(name)
    if not package.loaded[name] and not package.cache[name] then
        local finded = package.find(name)
        if not finded then
            error("lib " .. name .. " is not found", 0)
        end
        local fs = require("filesystem")
        local calls = require("calls")

        local file = assert(fs.open(finded, "rb"))
        local data = file.readAll()
        file.close()

        local lib = assert(load(data, "=" .. finded, nil, calls.call("createEnv")))()
        if type(lib) == "table" and lib.unloaded then
            package.cache[name] = lib
        else
            package.loaded[name] = lib
        end
    end
    if not package.loaded[name] and not package.cache[name] then
        error("lib " .. name .. " is not found" , 0)
    end
    return package.loaded[name] or package.cache[name]
end

function package.get(name)
    return package.loaded[name] or package.cache[name]
end

function package.isLoaded(name)
    return not not package.get(name)
end

------------------------------------

package.loaded.component = component
package.loaded.computer = computer
package.loaded.unicode = unicode

package.loaded.paths = raw_dofile("/system/core/lib/paths.lua", nil, createEnv()) --подгрузить зарания во избежании проблемм
package.loaded.filesystem = raw_dofile("/system/core/lib/filesystem.lua", nil, createEnv())
package.loaded.calls = raw_dofile("/system/core/lib/calls.lua", nil, createEnv())

raw_dofile = nil --чтобы навярника выгрузилось
createEnv = nil

------------------------------------

return package