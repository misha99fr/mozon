local component = require("component")
local computer = require("computer")
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

computer.beep(200)

local readers = {}
for i, window in ipairs(windows) do
    window:clear(0x0000FF)
    for i = 1, 2 do
        window:write(tostring(i) .. "\n", 0xFFFF00, 0x00AAFF)
    end
    local cx, cy = window:getCursor()
    --window:set(1, 6, 0xFF0000, 0x00AAFF, tostring(cx))
    --window:set(4, 6, 0xFF0000, 0x00AAFF, tostring(cy))
    table.insert(readers, window:read(cx, cy, window.sizeX, 0xFF00FF, 0x00FF00))
end

while true do
    local eventData = {computer.pullSignal()}
    for i = #readers, 1, -1 do
        local out = (readers[i])(eventData)
        if out then
            if out == true then
                table.remove(readers, i)
            else
                computer.beep(out)
            end
        end
    end
end