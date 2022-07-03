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
    table.insert(event.listens, {time = time, func = func, times = times or 1, type = "t"})
end

local computer_pullSignal = computer.pullSignal
function computer.pullSignal(time)
    local realtime = 0
    local time = time or math.huge
    
    
end

return event