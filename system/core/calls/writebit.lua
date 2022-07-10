--простите что я не смог сделать номальную функция, но я глупый, сильно глупый, и не понямаю в битовых сдвигах

local calls = require("calls")
local readbit = calls.load("readbit")

local byte, index, value = ...
local current = readbit(byte, index)

if current ~= value then
    byte = byte + (2 ^ index)
end

return math.floor(byte)