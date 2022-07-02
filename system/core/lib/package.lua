local package = {}

package.libsPaths = {}
package.loaded = {package = package}

function _G.require(name)
    return package.loaded[name]
end

return package