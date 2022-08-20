local fs = require("filesystem")
local paths = require("paths")

local path, data = ...

fs.makeDirectory(paths.path(path))

local file, err = fs.open(path, "wb")
if not file then return nil, err end
file.write(data)
file.close()

return true