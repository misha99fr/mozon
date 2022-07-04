local graphic = require("graphic")
local component = require("component")
local event = require("event")

------------------------------------

local screen = component.list("screen")()
local gpu = graphic.findGpu(screen)
local rx, ry = gpu.getResolution()

local function main()
    local mainWindow = graphic.classWindow:new(screen, 1, 2, rx, ry - 1)
    mainWindow:clear(0x00AAFF)
    mainWindow:set(1, 1, 0x0000FF, 0xFFFFFF, "open")

    while true do
        local eventData = {event.pull()}
    end
end

main()