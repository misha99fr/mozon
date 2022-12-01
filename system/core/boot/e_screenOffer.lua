local computer = require("computer")
local component = require("component")
local shutdown = computer.shutdown
function computer.shutdown(mode)
    pcall(function()
        local gpu = component.proxy(component.list("gpu")() or "")
        for screen in component.list("screen") do
            if gpu.getScreen() ~= screen then
                gpu.bind(screen, false)
            end
            gpu.setActiveBuffer(0)
            gpu.setDepth(1)
            gpu.setDepth(gpu.maxDepth())
            gpu.setResolution(50, 16)
            gpu.setBackground(0)
            gpu.setForeground(0xFFFFFF)
            gpu.fill(1, 1, 50, 16, " ")
        end
    end)
    shutdown(mode)
end