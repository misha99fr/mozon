local event = require("event")
local component = require("component")
local computer = require("computer")

local function func(eventType, uuid, ctype) --тут происходит обновления getDeviceInfo и getKeyboard, так как в ос они используються часто
    if eventType == "component_added" or eventType == "component_removed" then
        computer.deviceinfo = nil
        component.keyboards = {}
    end
end

local pullSignal = computer.pullSignal
local unpack = table.unpack
function computer.pullSignal(...) --листен с самым высоким приоритетом ЛОЛ
    local eventData = {pullSignal(...)}
    func(unpack(eventData))
    return unpack(eventData)
end