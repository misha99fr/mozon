local raw_dofile, bootfs = ...
local component = component
local computer = computer
local unicode = unicode

------------------------------------

local package = {}
package.paths = {"/data/lib",  "/vendor/lib", "/system/lib", "/system/core/usr/lib", "/system/core/lib"} --позиция по мере снижения приоритета(первый элемент это самый высокий приоритет)
package.loaded = {["package"] = package}
for key, value in pairs(_G) do
    if type(value) == "table" then
        package.loaded[key] = value
    end
end
package.cache = {}

function package.find(name)
    local fs = require("filesystem")
    local paths = require("paths")

    local function resolve(path, deep)
        if fs.exists(path) then
            if fs.isDirectory(path) then
                local lpath = paths.concat(path, "init.lua")
                if fs.exists(lpath) and not fs.isDirectory(lpath) then
                    return lpath
                end
            else
                return path
            end
        end

        if not deep then
            return resolve(path .. ".lua", true)
        end
    end
    
    if unicode.sub(name, 1, 1) == "/" then
        return resolve(name)
    else
        for i, v in ipairs(package.paths) do
            local path = resolve(paths.concat(v, name))
            if path then
                return path
            end
        end
    end
end

function package.require(name)
    if not package.loaded[name] and not package.cache[name] then
        local finded = package.find(name)
        if not finded then
            error("lib " .. name .. " is not found", 2)
        end
        local fs = require("filesystem")

        local file = assert(fs.open(finded, "rb"))
        local data = file.readAll()
        file.close()

        local lib = assert(load(data, "=" .. finded, nil, createEnv()))()
        if type(lib) == "table" and lib.unloaded then
            package.cache[name] = lib
        else
            package.loaded[name] = lib
        end
    end
    if not package.loaded[name] and not package.cache[name] then
        error("lib " .. name .. " is not found" , 2)
    end
    return package.loaded[name] or package.cache[name]
end

function package.get(name)
    return package.loaded[name] or package.cache[name]
end

function package.isLoaded(name)
    return not not package.get(name)
end

function package.isInstalled(name)
    return not not package.find(name)
end

------------------------------------

_G.require = package.require

package.loaded.component = component
package.loaded.computer = computer
package.loaded.unicode = unicode

local function raw_reg(name, path)
    if bootfs.exists(path) then
        local lib = raw_dofile(path, nil, createEnv())
        if type(lib) == "table" and lib.unloaded then
            package.cache[name] = lib
        else
            package.loaded[name] = lib
        end
    end
end

raw_reg("vcomponent", "/system/core/usr/lib/vcomponent.lua") --подгрузить зарания во избежании проблемм
raw_reg("paths",      "/system/core/lib/paths.lua")      --подгрузить зарания во избежании проблемм
raw_reg("filesystem", "/system/core/lib/filesystem.lua")
raw_reg("calls",      "/system/core/lib/calls.lua")
package.loaded.natives = _G.natives

------------------------------------

return package