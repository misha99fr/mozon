local component = require("component")
local calls = require("calls")

local windows = {}
do
    local graphicInit = calls.load("graphicInit")

    for address in component.list("screen") do
        local term = require("term")
        local gpu = term.findGpu(address)
        if gpu then
            graphicInit(gpu)
            table.insert(windows, term.classWindow:new(address, 1, 1, 25, 5))
            table.insert(windows, term.classWindow:new(address, 1, 7, 25, 5))
        end
    end
end

local readers = {}
for i, window in ipairs(windows) do
    window:clear(0x0000FF)
    for i = 1, 2 do
        window:write(tostring(i) .. "\n", 0xFFFF00, 0x00AAFF)
    end
    local cx, cy = window:getCursor()
    table.insert(readers, window:read(cx, cy, window.sizeX, 0xFF00FF, 0x00FF00))
end

while true do
    local eventData = {computer.pullSignal()}
    for i, v in ipairs(readers) do
        
    end
end