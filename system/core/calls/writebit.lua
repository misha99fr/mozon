local byte, index, value = ...
local current = readbit(byte, index)

if current ~= value then
    byte = byte + (2 ^ index)
end

return math.floor(byte)