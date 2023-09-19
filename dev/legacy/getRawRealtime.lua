local fs = require("filesystem")
local file = assert(fs.open("/tmp/getRealTime.null", "wb"))
file.close()
local time = fs.lastModified("/tmp/getRealTime.null")
fs.remove("/tmp/getRealTime.null")

return time