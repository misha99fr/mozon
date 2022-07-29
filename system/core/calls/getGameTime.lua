local time = os.time()

local seconds = time % 60
local minutes = (time / 60) % 60
local hours = (time / (60 * 60)) % 24

return math.floor(hours), math.floor(minutes), math.floor(seconds)