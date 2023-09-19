local time = getRawRealtime()
local addToClock = (...) or 0

-------------------------------------

time = time / 1000
time = time + (addToClock * 60 * 60)

local seconds = time % 60
local minutes = (time / 60) % 60
local hours = (time / (60 * 60)) % 24

return math.floor(hours), math.floor(minutes), math.floor(seconds)