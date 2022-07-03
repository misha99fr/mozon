local component = require("component")
local unicode = require("unicode")

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
        cursorX = 1,
        cursorY = 1,
    }

    setmetatable(obj, self)
    return obj
end

function window:set(x, y, background, foreground, text)
    local gpu = term.findGpu(self.screen)
    if gpu then
        gpu.setBackground(background)
        gpu.setForeground(foreground)
        gpu.set(self.x + (x - 1), self.y + (y - 1), text)
    end
end

function window:fill(x, y, sizeX, sizeY, background, foreground, char)
    local gpu = term.findGpu(self.screen)
    if gpu then
        gpu.setBackground(background)
        gpu.setForeground(foreground)
        gpu.fill(self.x + (x - 1), self.y + (y - 1), sizeX, sizeY, char)
    end
end

function window:copy(x, y, sizeX, sizeY, offsetX, offsetY)
    local gpu = term.findGpu(self.screen)
    if gpu then
        gpu.copy(self.x + (x - 1), self.y + (y - 1), sizeX, sizeY, offsetX, offsetY)
    end
end

function window:clear(color)
    self:fill(1, 1, self.sizeX, self.sizeY, color, 0, " ")
end

function window:write(data, background, foreground)
    local gpu = term.findGpu(self.screen)
    if gpu then
        gpu.setBackground(background or 0)
        gpu.setForeground(foreground or 0xFFFFFF)
        gpu.set(self.cursorX, self.cursorY, data)
    end
end

term.classWindow = window

------------------------------------

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
        return gpu
    end
end

return term