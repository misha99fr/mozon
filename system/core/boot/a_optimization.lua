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