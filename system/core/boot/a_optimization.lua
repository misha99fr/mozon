local computer = require("computer")
local component = require("component")

do --оптимизация для computer.getDeviceInfo
    local computer_pullSignal = computer.pullSignal
    local deviceinfo = computer.getDeviceInfo()

    function computer.getDeviceInfo()
        return deviceinfo
    end
    function computer.pullSignal(time)
        local eventData = {computer_pullSignal(time)}
        if eventData[1] == "component_added" or eventData[1] == "component_removed" then
            deviceinfo = computer.getDeviceInfo()
        end
        return table.unpack(eventData)
    end
end

do
    component.keyboards = {}
    component.originalInvoke = component.invoke

    function component.refreshKeyboard()
        for address in component.list("screen") do
            component.keyboards[address] = component.originalInvoke(address, "getKeyboards")
        end
    end
    
    function component.invoke(address, method, ...)
        if component.type(address) == "screen" and method == "getKeyboards" then
            return component.keyboards[address]
        else
            local eventData = {pcall(component.originalInvoke, address, method, ...)}
            if eventData[1] then
                return table.unpack(eventData)
            else
                error(eventData[2], 0)
            end
        end
    end
end