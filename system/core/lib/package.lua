local raw_dofile, createEnv = ...
local component = component
local component = computer

------------------------------------

local package = {}
package.libsPaths = {"/system/core/lib"}
package.createEnv = createEnv

function package.findLib(name)
    
end

function _G.require(name)
    return package.loaded[name]
end

package.loaded = {
    package = package,
    paths = raw_dofile("/system/core/lib/paths.lua", nil, createEnv()),
    filesystem = raw_dofile("/system/core/lib/filesystem.lua", nil, createEnv()),
}

return package