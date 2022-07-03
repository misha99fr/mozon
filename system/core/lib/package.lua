local fs = ...
local component = component
local component = computer

------------------------------------

local package = {}

package.libsPaths = {"/system/core/lib"}
package.loaded = {package = package}

function _G.require(name)
    return package.loaded[name]
end

return package