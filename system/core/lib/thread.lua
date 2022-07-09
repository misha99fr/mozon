local event = require("event")

------------------------------------

local thread = {}
thread.threads = {}

function thread.current()
    local currentT = coroutine.running()
    local function find(tbl)
        if tbl == thread.threads then
            for i, v in ipairs(tbl) do
                if v.thread == currentT then
                    return v
                else
                    local obj = find(v)
                    if obj then
                        return obj
                    end
                end
            end
        else
            for i, v in ipairs(tbl.childs) do
                if v.thread == currentT then
                    return v
                else
                    local obj = find(v)
                    if obj then
                        return obj
                    end
                end
            end
        end
    end
    return find(thread.threads)
end

function thread.attachThread(t)
    local obj = thread.current()
    if obj then
        table.insert(obj.childs, t)
        return true
    end
    table.insert(thread.threads, t)
    return true
end

function thread.create(func, ...)
    local t = coroutine.create(func, ...)
    local obj = 
    {thread = t, enable = false, args = {...},
    raw_kill, kill, childs = {}}
    thread.attachThread(obj)
    return obj
end

------------------------------------thread functions

function raw_kill(t) --не стоит убивать паток сырым kill
    t.killed = true
end

function kill(t) --вы сможете переопределить это в своем потоке, наример чтобы закрыть таймеры
    t:raw_kill()
end

function resume(t)
    t.enable = true
end

function suspend(t)
    t.enable = false
end

return thread