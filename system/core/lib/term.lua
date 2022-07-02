local component = require("component")

------------------------------------

local term = {}

------------------------------------class window

local window = {}
window.__index = window

function window:new(screen, x, y, sizeX, sizeY)
    local obj = {
        screen = screen,
        x = x,
        y = y,
        sizeX = sizeX,
        sizeY = sizeY,
    }

    setmetatable(obj, self)
    return obj
end

function window:clear()
    
end

------------------------------------

local freeGpu = {}
function term.findGpu(screen)
    local deviceinfo, gpu = computer.getDeviceInfo()
    local screenCapacity = deviceinfo[screen].capacity

    for address in component.list() do
        
    end
    while true do
        local gpuCapacity = deviceinfo[screen].capacity
    end

    return component.proxy(gpu)
end

term.window = window

return term