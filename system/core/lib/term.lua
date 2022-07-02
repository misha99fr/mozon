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
        gpu = term.findGpu(screen),
    }

    setmetatable(obj, self)
    return obj
end

function window:fill(x, y, sizeX, sizeY, background, foreground, char)
    self.gpu.setBackground(background)
    self.gpu.setBackground(foreground)
    self.gpu.fill(self.x + (x - 1), self.x + (y - 1), sizeX, sizeY, char)
end

function window:clear(color)
    self.fill(1, 1, self.sizeX, self.sizeY, color, 0, " ")
end

------------------------------------

function term.restoreScreenSettings(screen)
    
end

function term.saveScreenSettings(screen)
    
end

function term.findGpu(screen)
    local deviceinfo = computer.getDeviceInfo()
    local screenLevel = deviceinfo[screen].capacity or 0

    local gpuLevel, bestGpu, bestGpuLevel
    for address in component.list("gpu") do
        gpuLevel = deviceinfo[address].capacity or 0
        if gpuLevel == screenLevel then
            gpuLevel = gpuLevel + 1000
        elseif gpuLevel > screenLevel then
            gpuLevel = gpuLevel + 800
        end
        if gpuLevel > bestGpuLevel then
            bestGpuLevel = gpuLevel
            bestGpu = address
        end
    end
    
    if bestGpu then
        local gpu = component.proxy(bestGpu)
        if gpu.getScreen() ~= screen then
            gpu.bind(screen, false)
        end
        term.restoreScreenSettings(screen)
        return gpu
    end
end

term.window = window

return term