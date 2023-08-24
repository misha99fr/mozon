local fs = require("filesystem")
local paths = require("paths")

local path, data = ...

fs.makeDirectory(paths.path(path))

local file, err = fs.open(path, "wb")
if not file then return nil, err end
local success, err = file.write(data)
if not success then return nil, err end
file.close()

return true