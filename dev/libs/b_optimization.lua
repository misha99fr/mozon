local component, computer = component, computer

-- оптимизация для computer.getDeviceInfo
computer.originalGetDeviceInfo = computer.getDeviceInfo
function computer.getDeviceInfo()
    if not computer.deviceinfo then
        computer.deviceinfo = computer.originalGetDeviceInfo()
    end
    return computer.deviceinfo
end

-- оптимизация для getKeyboards
component.keyboards = {}
component.originalInvoke = component.invoke

function component.refreshKeyboard(address)
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
    return component.keyboards[address]
end

function component.refreshKeyboards()
    for address in component.list("screen") do
        component.refreshKeyboard(address)
    end
end

function component.invoke(address, method, ...)
    if component.type(address) == "screen" and method == "getKeyboards" then
        return component.keyboards[address] or component.refreshKeyboard(address)
    else
        local eventData = {pcall(component.originalInvoke, address, method, ...)}
        if eventData[1] then
            return table.unpack(eventData, 2)
        else
            error(eventData[2], 2)
        end
    end
end

-- тут происходит обновления getDeviceInfo и getKeyboard, так как в ос они используються часто
local function func(eventType, uuid, ctype) 
    if eventType == "component_added" or eventType == "component_removed" then
        computer.deviceinfo = nil
        component.keyboards = {}
    end
end

local pullSignal = computer.pullSignal
local unpack = table.unpack
function computer.pullSignal(...) --листен с самым высоким приоритетом
    local eventData = {pullSignal(...)}
    func(unpack(eventData))
    return unpack(eventData)
end