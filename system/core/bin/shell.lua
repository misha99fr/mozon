local component = require("component")
local computer = require("computer")
local calls = require("calls")
local event = require("event")
local term = require("term")

local blinkScreen = "d31ef4a4-0509-4099-8e8f-8c50bd00e3d9"

local windows = {}
do
    local graphicInit = calls.load("graphicInit")

    for address in component.list("screen") do
        if address ~= blinkScreen then
            local gpu = term.findGpu(address)
            if gpu then
                graphicInit(gpu)
                table.insert(windows, term.classWindow:new(address, 1, 1, 25, 5))
                table.insert(windows, term.classWindow:new(address, 1, 7, 25, 5))
            end
        end
    end
end

local bWin1 = term.classWindow:new(blinkScreen, 1, 1, 25, 5)
local bWin2 = term.classWindow:new(blinkScreen, 1, 7, 25, 5)

event.timer(1, )

computer.beep(200)

local readers = {}
for i, window in ipairs(windows) do
    computer.beep(1000)
    window:clear(0x0000FF)
    for i = 1, 2 do
        window:write(tostring(i) .. "\n", 0xFFFF00, 0x00AAFF)
    end
    local cx, cy = window:getCursor()
    --window:set(1, 6, 0xFF0000, 0x00AAFF, tostring(cx))
    --window:set(4, 6, 0xFF0000, 0x00AAFF, tostring(cy))
    table.insert(readers, window:read(cx, cy, window.sizeX, 0xFF00FF, 0x00FF00))
    computer.beep(2000)
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