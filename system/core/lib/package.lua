local raw_dofile, createEnv = ...
local component = component
local computer = computer
local unicode = unicode
local paths

------------------------------------

local package = {}
package.libsPaths = {"/system/core/lib"}
package.createEnv = createEnv

function package.findLib(name)
    local fs = require("filesystem")
    local path

    for i, v in ipairs(package.libsPaths) do
        local lpath = paths.concat(v, name .. ".lua")
        if fs.exists(lpath) then
            path = lpath
            break
        end
    end

    return path
end

function _G.require(name)
    if not package.loaded[name] then
        local finded = package.findLib(name)
        if not finded then
            error("lib " .. name .. " is not found", 0)
        end
        local fs = require("filesystem")

        local file = assert(fs.open(finded, "rb"))
        local data = file.readAll()
        file.close()

        package.loaded[name] = data
    end
    return package.loaded[name]
end

------------------------------------

package.loaded = {package = package}

package.loaded.component = component
package.loaded.computer = computer
package.loaded.unicode = unicode

paths = raw_dofile("/system/core/lib/paths.lua", nil, createEnv())
package.loaded.paths = paths
package.loaded.filesystem = raw_dofile("/system/core/lib/filesystem.lua", nil, createEnv())

------------------------------------

return package