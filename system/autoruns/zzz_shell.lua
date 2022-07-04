local component = require("component")
local computer = require("computer")
local calls = require("calls")
local event = require("event")
local graphic = require("graphic")
local fs = require("filesystem")

local blinkScreen = "d31ef4a4-0509-4099-8e8f-8c50bd00e3d9"

local windows = {}
do
    local graphicInit = calls.load("graphicInit")

    for address in component.list("screen") do
        if address ~= blinkScreen then
            local gpu = graphic.findGpu(address)
            if gpu then
                graphicInit(gpu)
                table.insert(windows, graphic.classWindow:new(address, 1, 1, 25, 5))
                table.insert(windows, graphic.classWindow:new(address, 1, 7, 25, 5))
                windows.depth = 1
            end
        end
    end
end

local bWin1 = graphic.classWindow:new(blinkScreen, 1, 1, 25, 5)
local bWin2 = graphic.classWindow:new(blinkScreen, 1, 7, 25, 5)

local blink = false
event.timer(0.1, function()
    if blink then
        bWin1:clear(0)
        bWin2:clear(0xFFFFFF)
    else
        bWin1:clear(0xFFFFFF)
        bWin2:clear(0)
    end
    blink = not blink
end, math.huge)

computer.beep(200)

local readers = {}
for i, window in ipairs(windows) do
    window:clear(0xFFFFFF)
    --[[
    for i = 1, 0xFFFFFF, 0xFFFFFF / 256 do
        window:clear(i)
    end
    for i = 1, 2 do
        if windows.depth == 1 then
            window:write(tostring(i) .. "\n", 0, 0x00AAFF)
        else
            window:write(tostring(i) .. "\n", 0xFFFF00, 0x00AAFF)
        end
    end
    ]]

    local cx, cy = window:getCursor()
    --window:set(1, 6, 0xFF0000, 0x00AAFF, tostring(cx))
    --window:set(4, 6, 0xFF0000, 0x00AAFF, tostring(cy))
    if windows.depth == 1 then
        table.insert(readers, window:read(cx, cy, window.sizeX, 0, 0x00FF00))
    else
        table.insert(readers, window:read(cx, cy, window.sizeX, 0xFF00FF, 0x00FF00))
    end
end

while true do
    local eventData = {computer.pullSignal()}
    for i, v in ipairs(windows) do
        local lEventData = v:uploadEvent(eventData)
        if lEventData then
            if lEventData[1] == "touch" then
                v:set(lEventData[3], lEventData[4], 0xFF00FF, 0xFFFF00, "*")
                computer.beep(2000, 0.001)
            elseif lEventData[1] == "drag" then
                v:set(lEventData[3], lEventData[4], 0xFF00FF, 0xFFFF00, "*")
            elseif lEventData[1] == "drop" then
                computer.beep(100, 0.2)
            end
        end
    end
    for i = #readers, 1, -1 do
        local out = (readers[i]).uploadEvent(eventData)
        if out then
            if out == true then
                table.remove(readers, i)
            else
                local speech = component.proxy(component.list("speech")())
                speech.say(out)
            end
        end
    end
end