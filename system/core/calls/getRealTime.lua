local fs = require("filesystem")
local file = assert(fs.open("/tmp/getRealTime.null", "wb"))
file.close()
local time = fs.lastModified("/tmp/getRealTime.null")
fs.remove("/tmp/getRealTime.null")

local addToClock = (...) or 0

-------------------------------------

time = time / 1000
time = time + (addToClock * 60 * 60)

local seconds = time % 60
local minutes = (time / 60) % 60
local hours = (time / (60 * 60)) % 24

return math.floor(hours), math.floor(minutes), math.floor(seconds)