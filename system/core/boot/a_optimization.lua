local computer = require("computer")
local component = require("component")

do --оптимизация для computer.getDeviceInfo
    computer.originalGetDeviceInfo = computer.getDeviceInfo
    local deviceinfo = computer.originalGetDeviceInfo()

    computer.deviceinfo = deviceinfo
    function computer.getDeviceInfo()
        return deviceinfo
    end
end

do
    component.keyboards = {}
    component.originalInvoke = component.invoke

    function component.refreshKeyboard()
        for address in component.list("screen") do
            local newtbl = component.originalInvoke(address, "getKeyboards")
            local keyboards = component.keyboards[address]
            if keyboards then
                for k, v in pairs(keyboards) do
                    keyboards[k] = nil
                end
                for k, v in pairs(newtbl) do
                    keyboards[k] = v
                end
                keyboards.n = #keyboards
            else
                component.keyboards[address] = newtbl
            end
        end
    end
    component.refreshKeyboard()
    
    function component.invoke(address, method, ...)
        if component.type(address) == "screen" and method == "getKeyboards" then
            return component.keyboards[address]
        else
            local eventData = {pcall(component.originalInvoke, address, method, ...)}
            if eventData[1] then
                return table.unpack(eventData, 2)
            else
                error(eventData[2], 0)
            end
        end
    end
end