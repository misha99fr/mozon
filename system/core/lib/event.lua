local computer = require("computer")
local fs = require("filesystem")

------------------------------------

local event = {}
event.listens = {}

function event.tmpLog(data)
    local file = assert(fs.open("/tmp/tmplog.log", "ab"))
    file.write(data .. "\n")
    file.close()
end

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
        local ltime = time - (computer.uptime() - inTime)
        if ltime <= 0 then return end
        local realtime = ltime

        --поиск времени до первого таймера, что обязательно на него успеть
        for k, v in pairs(event.listens) do --нет ipairs неподайдет
            if v.type == "t" then
                local timerTime = v.time - (computer.uptime() - v.lastTime)
                if timerTime < realtime then
                    realtime = timerTime
                end
            end
        end

        local eventData = {computer_pullSignal(realtime)} --обязательно повисеть в pullSignal

        for k, v in pairs(event.listens) do --нет ipairs неподайдет
            if v.type == "t" then
                local uptime = computer.uptime() 
                if uptime - v.lastTime >= v.time then
                    v.lastTime = uptime --ДО выполнения функции ресатаем таймер, чтобы тайминги не поплывали при долгих функциях
                    local ok, err = pcall(v.func)
                    if ok then
                        if err == false then --таймер хочем отключиться
                            event.listens[k] = nil
                        end
                    else
                        event.tmpLog((err or "unknown error") .. "\n")
                    end
                end
            end
        end

        if #eventData > 0 then

            return table.unpack(eventData)
        end
    end
end

return event