local event = require("event")

------------------------------------

local thread = {}
thread.threads = {}
thread.mainthread = coroutine.running()
thread.unloaded = true

function coroutine.xpcall(co, ...)
    local output = {coroutine.resume(co, ...)}
    if not output[1] then
        return nil, output[2], debug.traceback(co)
    end
    return table.unpack(output)
end

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

function thread.attachThread(t, obj)
    local obj = obj or thread.current()
    if obj then
        if obj.childs then
            table.insert(obj.childs, t)
        else
            table.insert(obj, t)
        end
        return true
    end
    table.insert(thread.threads, t)
    return true
end

local function create(func, ...)
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
    return obj
end

function thread.create(func, ...)
    local obj = create(func, ...)
    thread.attachThread(obj)
    return obj
end

function thread.createTo(func, connectTo, ...)
    local obj = create(func, ...)
    thread.attachThread(obj, connectTo)
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
    if not t.thread then return "dead" end
    return coroutine.status(t.thread)
end

return thread