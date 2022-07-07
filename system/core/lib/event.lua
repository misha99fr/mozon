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

function event.sleep(time)
    local inTime = computer.uptime()
    repeat
        computer.pullSignal(time - (computer.uptime() - inTime))
    until computer.uptime() - inTime > time
end

function event.pull()
    
end

function event.listen(eventType, func)
    checkArg(1, eventType, "string", "nil")
    checkArg(2, func, "function")
    table.insert(event.listens, {eventType = eventType, func = func, type = "l"})
    return #event.listens
end

function event.timer(time, func, times)
    checkArg(1, time, "number")
    checkArg(2, func, "function")
    checkArg(3, times, "number", "nil")
    table.insert(event.listens, {time = time, func = func, times = times or 1,
    type = "t", lastTime = computer.uptime()})
    return #event.listens
end

event.interruptFlag = false

local computer_pullSignal = computer.pullSignal
function computer.pullSignal(time) --НАДА СДЕЛАТЬ рабочий times!! это переменная которая хранит количествой вызовов функции таймера
    if event.interruptFlag then
        event.interruptFlag = false
        error("interrupted", 0)
    end
    
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

        local function runCallback(func, index, ...)
            local ok, err = pcall(func, ...)
            if ok then
                if err == false then --таймер/слушатель хочет отключиться
                    event.listens[index] = nil
                end
            else
                event.tmpLog((err or "unknown error") .. "\n")
            end
        end

        for k, v in pairs(event.listens) do --нет ipairs неподайдет
            if v.type == "t" then
                local uptime = computer.uptime() 
                if uptime - v.lastTime >= v.time then
                    v.lastTime = uptime --ДО выполнения функции ресатаем таймер, чтобы тайминги не поплывали при долгих функциях
                    if v.times <= 0 then
                        event.listens[k] = nil
                    else
                        runCallback(v.func, k)
                        v.times = v.times - 1
                        if v.times <= 0 then
                            event.listens[k] = nil
                        end
                    end
                end
            end
        end

        if #eventData > 0 then
            for k, v in pairs(event.listens) do
                if v.type == "l" then
                    if not v.eventType or v.eventType == eventData[1] then
                        runCallback(v.func, k, table.unpack(eventData))
                    end
                end
            end
            return table.unpack(eventData)
        end
    end
end

function event.cancel(num)
    event.listens[num] = nil
end

event.pull = computer.pullSignal

return event