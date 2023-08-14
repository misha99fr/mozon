local computer = require("computer")
local fs = require("filesystem")
local package = require("package")
local component = require("component")

------------------------------------

local raw_computer_pullSignal = computer.pullSignal
local computer_pullSignal = function(time)
    if package.isLoaded("thread") and package.get("thread").current() then
        if not time then time = math.huge end
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

local event = {push = computer.pushSignal}
event.listens = {}
event.interruptFlag = false
event.isListen = false --если текуший код timer/listen
event.energySaving = false
event.autoEnergySaving = true

------------------------------------

function event.errLog(data)
    fs.makeDirectory("/data")
    local file = assert(fs.open("/data/errorlog.log", "ab"))
    file.write(data .. "\n")
    file.close()
end

function event.sleep(time)
    local inTime = computer.uptime()
    repeat
        local itime = time - (computer.uptime() - inTime)
        if itime < 0.1 then itime = 0.1 end
        computer.pullSignal(itime)
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
    checkArg(1, num, "number")

    local ok = not not event.listens[num]
    if ok then
        event.listens[num].killed = true
        event.listens[num] = nil
    end
    return ok
end

--[[
event.oldinterrupttime = -math.huge
function event.interrupt()
    if computer.uptime() - event.oldinterrupttime > 2 then
        local eventData = {raw_computer_pullSignal(0)}
        if #eventData > 0 then
            computer.pushSignal(table.unpack(eventData))
        end
        event.oldinterrupttime = computer.uptime()
    end
end
]]

function event.callThreads(eventData)
    local thread = package.get("thread")
    if thread then
        local function find(tbl)
            local parsetbl = tbl.childs
            if not parsetbl then parsetbl = tbl end
            for i = #parsetbl, 1, -1 do
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
    local thread = package.get("thread")

    if event.interruptFlag and (event.interruptFlag == true or (thread and thread.current() and event.interruptFlag == thread.current().screen) or not thread) then
        event.interruptFlag = nil
        error("interrupted", 0)
    end
    time = time or math.huge
    
    
    if thread then
        local current = thread.current()
        if current then
            return computer_pullSignal(time)
        end
    end

    local minTime = event.energySaving and 0.5 or 0.1
    
    local inTime = computer.uptime()
    while true do
        local ltime = time - (computer.uptime() - inTime)
        if ltime <= 0 then return end
        local realtime = ltime

        --поиск времени до первого таймера, что обязательно на него успеть
        if not package.isLoaded("thread") then
            for k, v in pairs(event.listens) do --нет ipairs неподайдет
                if v.type == "t" and not v.killed then
                    local timerTime = v.time - (computer.uptime() - v.lastTime)
                    if timerTime < realtime then
                        realtime = timerTime
                    end
                end
            end
        else
            realtime = 0.1
        end

        if realtime < minTime then
            realtime = minTime
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
                event.errLog(err or "unknown error")
            end
        end

        for k, v in pairs(event.listens) do --нет ipairs неподайдет
            if v.type == "t" and not v.killed then
                local uptime = computer.uptime() 
                if uptime - v.lastTime >= (event.energySaving and math.max(v.time, minTime) or v.time) then
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

function event.pull(time, ...) --добавляет фильтер, не юзать без надобнасти
    local filters = {...}

    if #filters == 0 then
        return computer.pullSignal(time)
    end

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

function event.setEnergySavingMode(state)
    event.energySaving = state
end

------------------------------------

local currentUnloadState = true
local function setUnloadState(state)
    if currentUnloadState == state then return end
    currentUnloadState = state
    if state then
        setmetatable(package.cache, {__mode = 'v'})
        local calls = package.get("calls")
        if calls then
            setmetatable(calls.cache, {__mode = 'v'})
        end
    else
        setmetatable(package.cache, {})
        local calls = package.get("calls")
        if calls then
            setmetatable(calls.cache, {})
        end
    end
end

local oldFreeMemory = computer.freeMemory()
event.timer(4, function()
    local totalMemory = computer.totalMemory()
    if totalMemory < (400 * 1024) then --если обьем мения 400кб, то отключения автовыгрузки даже не обсуждаеться
        setUnloadState(true)
        return false
    else
        local freeMemory = computer.freeMemory()
        if freeMemory > oldFreeMemory then --check GC
            if freeMemory < totalMemory / 2 then
                setUnloadState(true)
            else
                setUnloadState(false)
            end
        end
        oldFreeMemory = freeMemory
    end
end, math.huge)

event.timer(5, function()
    if event.autoEnergySaving then
        if computer.energy() / computer.maxEnergy() <= 0.30 then
            event.setEnergySavingMode(true)
        else
            event.setEnergySavingMode(false)
        end
    end
end, math.huge)

return event