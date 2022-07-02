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

function term.restoreScreenSettings(screen)
    
end

function term.saveScreenSettings(screen)
    
end

local freeGpu = {}
function term.findGpu(screen)
    local deviceinfo, bestGpu = computer.getDeviceInfo()
    local screenLevel = deviceinfo[screen].capacity or 0

    for address in component.list("gpu") do
        while true do
            local gpuLevel = deviceinfo[address].capacity or 0
            if gpuLevel == screenLevel then
                gpuLevel = gpuLevel + 1000
            end
        end
    end
    
    local gpu = component.proxy(bestGpu)
    if gpu.getScreen() ~= screen then
        gpu.bind(screen)
    end
    term.restoreScreenSettings(screen)
    return gpu
end

term.window = window

return term