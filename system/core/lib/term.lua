local term = {}

------------------------------------class window

local window = {}
window.__index = window

function window:new(screen, x, y, sizeX, sizeY)
    local obj = {}

    setmetatable(obj, self)
    return obj
end

------------------------------------

term.window = window

return term