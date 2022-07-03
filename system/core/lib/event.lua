local computer = require("computer")


------------------------------------

local event = {}
event.listens = {}

function event.pull()
    
end

function event.push()
    
end

function event.listen()
    
end

function event.timer(time, func, times)
    checkArg(1, time, "number")
    checkArg(2, func, "function")
    checkArg(3, times, "number", "nil")
    table.insert(event.listens, {time = time, func = func, times = times or 1,
    type = "t", lastTime = computer.uptime()})
end

local computer_pullSignal = computer.pullSignal
function computer.pullSignal(time)
    time = time or math.huge

    local inTime = computer.uptime()
    while true do
        local time = time - (computer.uptime() - inTime)
        if time <= 0 then return end

        for k, v in pairs(event.listens) do --нет ipairs неподайдет
            if v.
        end
    end
end

return event