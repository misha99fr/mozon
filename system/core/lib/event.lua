local computer = require("computer")
local fs = require("filesystem")
local package = require("package")

------------------------------------

local raw_computer_pullSignal = computer.pullSignal
local computer_pullSignal = function(time)
    if package.loaded.thread and package.loaded.thread.current() then
        local inTime = computer.uptime()
        repeat
            local eventData = {coroutine.yield()}
            if #eventData > 0 then
                return table.unpack(eventData)
            end
        until computer.uptime() - inTime > time
    else
        return raw_computer_pullSignal(time)
    end
end

local function tableInsert(tbl, value)
    for i = 1, #tbl + 1 do
        if not tbl[i] then
            tbl[i] = value
            return i
        end
    end
end

local event = {}
event.listens = {}
event.interruptFlag = false
event.isListen = false --если текуший код timer/listen

------------------------------------

function event.tmpLog(data)
    local file = assert(fs.open("/tmplog.log", "ab"))
    file.write(data .. "\n")
    file.close()
end

function event.sleep(time)
    local inTime = computer.uptime()
    repeat
        computer.pullSignal(time - (computer.uptime() - inTime))
    until computer.uptime() - inTime > time
end

function event.listen(eventType, func)
    checkArg(1, eventType, "string", "nil")
    checkArg(2, func, "function")
    return tableInsert(event.listens, {eventType = eventType, func = func, type = "l"}) --нет класический table.insert не подайдет, так как он не дает понять, нуда вставил значения
end

function event.timer(time, func, times)
    checkArg(1, time, "number")
    checkArg(2, func, "function")
    checkArg(3, times, "number", "nil")
    return tableInsert(event.listens, {time = time, func = func, times = times or 1,
    type = "t", lastTime = computer.uptime()})
end

function event.cancel(num)
    local ok = not not event.listens[num]
    event.listens[num].killed = true
    event.listens[num] = nil
    return ok
end

function event.interrupt()
    local eventData = {computer.pullSignal(0.2)}
    if #eventData > 0 then
        computer.pushSignal(table.unpack(eventData))
    end
end

function event.callThreads(eventData)
    local thread = package.loaded.thread
    if thread then
        local function find(tbl)
            local parsetbl = tbl.childs
            if not parsetbl then parsetbl = tbl end
            for i = #parsetbl, 1, -1 do
                event.interrupt()
                local v = parsetbl[i]
                if not v.thread or coroutine.status(v.thread) == "dead" then
                    table.remove(parsetbl, i)
                else
                    --computer.beep(2000, 0.1)
                    v.out = {coroutine.xpcall(v.thread, table.unpack(v.args or eventData))}
                    v.args = nil
                    find(v)
                end
            end
        end
        find(thread.threads)
    end
end

function computer.pullSignal(time)
    if event.interruptFlag then
        event.interruptFlag = false
        error("interrupted", 0)
    end
    time = time or math.huge
    
    local thread = package.loaded.thread
    if thread then
        local current = thread.current()
        if current then
            return computer_pullSignal(time)
        end
    end
    
    local inTime = computer.uptime()
    while true do
        local ltime = time - (computer.uptime() - inTime)
        if ltime <= 0 then return end
        local realtime = ltime

        --поиск времени до первого таймера, что обязательно на него успеть
        for k, v in pairs(event.listens) do --нет ipairs неподайдет
            if v.type == "t" and not v.killed then
                local timerTime = v.time - (computer.uptime() - v.lastTime)
                if timerTime < realtime then
                    realtime = timerTime
                end
            end
        end

        local eventData = {computer_pullSignal(realtime)} --обязательно повисеть в pullSignal
        if not event.isListen then
            event.callThreads(eventData)
        end

        local function runCallback(func, index, ...)
            local oldState = event.isListen
            event.isListen = true
            local ok, err = pcall(func, ...)
            event.isListen = oldState
            if ok then
                if err == false then --таймер/слушатель хочет отключиться
                    event.listens[index] = nil
                end
            else
                event.tmpLog((err or "unknown error") .. "\n")
            end
        end

        for k, v in pairs(event.listens) do --нет ipairs неподайдет
            if v.type == "t" and not v.killed then
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
                if v.type == "l" and not v.killed then
                    if not v.eventType or v.eventType == eventData[1] then
                        runCallback(v.func, k, table.unpack(eventData))
                    end
                end
            end
            return table.unpack(eventData)
        end
    end
end

event.push = computer.pushSignal

function event.pull(time, ...) --добавляет фильтер, не юзать без надобнасти
    local filters = {...}
    if not time then
        time = math.huge
    end
    if type(time) == "string" then
        table.insert(filters, 1, time)
        time = math.huge
    end
    
    local inTime = computer.uptime()
    while true do
        local ltime = time - (computer.uptime() - inTime)
        if ltime <= 0 then break end
        local eventData = {computer.pullSignal(ltime)}

        local ok = true
        for i, v in ipairs(filters) do
            if v ~= eventData[i] then
                ok = false
                break
            end
        end

        if ok then
            return table.unpack(eventData)
        end
    end
end

return event