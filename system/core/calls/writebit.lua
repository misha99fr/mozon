--простите что я не смог сделать номальную функция, но я глупый, сильно глупый, и не понямаю в битовых сдвигах

local calls = require("calls")
if not calls.loaded.readbit then --для того чтобы избежать лишней нагрузки на диск
    calls.loaded.readbit = calls.load("readbit")
end
local readbit = calls.loaded.readbit

local byte, index, value = ...
local current = readbit(byte, index)

if current ~= value then
    byte = byte + (2 ^ index)
end

return math.floor(byte)