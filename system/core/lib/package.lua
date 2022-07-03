local raw_dofile, createEnv = ...
local component = component
local computer = computer
local unicode = unicode

------------------------------------

local package = {}
package.libsPaths = {"/system/core/lib"}
package.createEnv = createEnv

function package.findLib(name)
    
end

function _G.require(name)
    return package.loaded[name]
end

------------------------------------

package.loaded = {package = package}

package.loaded.component = component
package.loaded.computer = computer
package.loaded.unicode = unicode

package.loaded.paths = raw_dofile("/system/core/lib/paths.lua", nil, createEnv())
package.loaded.filesystem = raw_dofile("/system/core/lib/filesystem.lua", nil, createEnv())

------------------------------------

return package