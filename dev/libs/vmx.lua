--development
--не готово!

local component = component or require("component")
local computer = computer or require("computer")

-------------------------------------

local vmx = {}

function vmx.createVm(components, computerAddress)
    local eventQueue = {}

    local function tick()
        table.insert(eventQueue, {})
    end

    -------------------------------------
    
    local env = {}
    env.computer = {pullEvent = function(wait)
        if not wait then wait = math.huge end
        local startTime = computer.uptime()
        while computer.uptime() - startTime < wait do
            tick()
            if eventQueue[1] then
                local eventData = eventQueue[1]
                table.remove(eventQueue, 1)
                return table.unpack(eventData)
            end
        end
    end}
    env.component = {}

    return {

    }
end

return vmx