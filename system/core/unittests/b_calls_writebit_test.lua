local calls = require("calls")
local readbit = calls.load("readbit")
local writebit = calls.load("writebit")

for i = 1, 16 do
    local bytes = {}
    local byte = math.random(0, 255)
    for i = 1, 8 do
        bytes[i] = math.random(0, 1) == 0
        byte = writebit(byte, i - 1, bytes[i])
    end
    
    for i, v in ipairs(bytes) do
        if readbit(byte, i - 1) ~= v then
            return false
        end
    end
end

return true