local package = {}

package.paths = {}
package.loaded = {}

function _G.require(name)
    return package.loaded[name]
end

return package