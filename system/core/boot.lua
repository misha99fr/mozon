local raw_loadfile = ...

local function dofile(path)
    return assert(raw_loadfile(path))
end

do
    local package = dofile("/system/core/lib/package.lua")
    package.loaded.computer = computer
    package.loaded.component = component
    package.loaded.unicode = unicode

    _G.computer = nil
    _G.component = nil
    _G.unicode = nil
end