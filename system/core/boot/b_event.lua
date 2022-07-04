local event = require("event")
local component = require("component")
local computer = require("computer")

local timer, isKeyboard
event.listen(nil, function(eventType, uuid, ctype)
    if eventType == "component_added" or eventType == "component_removed" then
        if timer then
            event.cancel(timer)
        end
        timer = event.timer(1, function()
            computer.beep(2000)
            timer = nil
            computer.deviceinfo = computer.originalGetDeviceInfo()
            if isKeyboard then
                component.refreshKeyboard()
            end
            isKeyboard = nil
        end, 1)
        if ctype == "keyboard" then
            isKeyboard = true
        end
    end
end)