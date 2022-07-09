local event = require("event")

------------------------------------

local thread = {}
thread.threads = {}
thread.mainthread = coroutine.running()

function thread.current()
    local currentT = coroutine.running()
    local function find(tbl)
        local parsetbl = tbl.childs
        if not parsetbl then parsetbl = tbl end
        for i = #parsetbl, 1, -1 do
            local v = parsetbl[i]
            if not v.thread then
                table.remove(parsetbl, i)
            else
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
    local obj = {
        args = {...},
        childs = {},
        thread = t,
        enable = false,
        raw_kill = raw_kill,
        kill = kill,
        resume = resume,
        suspend = suspend,
        status = status
    }
    thread.attachThread(obj)
    return obj
end

------------------------------------thread functions

function raw_kill(t) --не стоит убивать паток сырым kill
    t.thread = nil
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

function status(t)
    return coroutine.status(t)
end

------------------------------------кстыли

event.timer(0.1, function() --сокрашяет время физического висения в pullSignal до 0.1
    
end, math.huge)

return thread