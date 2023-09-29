local event = require("event")
local computer = require("computer")
local component = require("component")
local bootloader = require("bootloader")
local lastinfo = {}
lastinfo.deviceinfo = computer.getDeviceInfo()
lastinfo.keyboards = {}

local function updateKeyboards()
    lastinfo.keyboards = {}
    for address in component.list("screen") do
        local result = {pcall(component.invoke, address, "getKeyboards")}
        if result[1] and type(result[2]) == "table" then
            lastinfo.keyboards[address] = result[2]
        end
    end
end
updateKeyboards()

event.hyperListen(function (eventType, componentUuid, componentType)
    if bootloader.runlevel ~= "init" then
        if eventType == "component_added" or eventType == "component_removed" then
            lastinfo.deviceinfo = computer.getDeviceInfo()

            if componentType == "keyboard" then
                updateKeyboards()
            end
        end
    end
end)

function lastinfo.update()
    lastinfo.deviceinfo = computer.getDeviceInfo()
    updateKeyboards()
end

return lastinfo