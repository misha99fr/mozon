local raw_dofile, createEnv = ...
local component = component
local component = computer

------------------------------------

local package = {}
package.libsPaths = {"/system/core/lib"}
package.createEnv = createEnv

function _G.require(name)
    return package.loaded[name]
end

function package.findLib(name)
    
end

package.loaded = {package = package}
package.loaded.paths = raw_dofile("/system/core/lib/paths.lua", nil, createEnv())
package.loaded.filesystem = raw_dofile("/system/core/lib/filesystem.lua", nil, createEnv())

return package