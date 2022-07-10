local calls = require("calls")
local readbit = calls.load("readbit")
local writebit = calls.load("writebit")

local bytes = {}
for i = 1, 8 do
    bytes[i] = math.random(0, 1) == 0
end



return 