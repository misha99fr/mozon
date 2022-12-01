local computer = require("computer")

local pullSignal = computer.pullSignal
local pushSignal = computer.pushSignal
local remove = table.remove
local insert = table.insert
local unpack = table.unpack

local queue = {}

function computer.pullSignal(...)
    if #queue == 0 then
        return pullSignal(...)
    else
        local data = queue[1]
        remove(queue, 1)
        return unpack(data)
    end
end

function computer.pushSignal(...)
    insert(queue, {...})
end