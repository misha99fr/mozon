local event = require("event")
local component = require("component")
local computer = require("computer")

local timer, isKeyboard
event.listen(nil, function(eventType, uuid, ctype) --тут происходит обновления getDeviceInfo и getKeyboard, так как в ос они используються часто
    if eventType == "component_added" or eventType == "component_removed" then
        if timer then
            event.cancel(timer)
        end
        if ctype == "keyboard" then
            isKeyboard = true
        end
        timer = event.timer(1, function()
            timer = nil
            computer.deviceinfo = nil
            if isKeyboard then
                component.refreshKeyboards()
            end
            isKeyboard = nil
        end, 1)
    end
end)