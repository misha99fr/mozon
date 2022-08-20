local fs = require("filesystem")

local path = ...

local file, err = fs.open(path, "rb")
if not file then return nil, err end
local data = file.readAll()
file.close()

return data