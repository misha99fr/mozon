local fs = require("filesystem")
local paths = require("paths")
local system = require("system")
local computer = require("computer")
local component = require("component")
local serialization = require("serialization")
local lastinfo = require("lastinfo")

------------------------------------

local function write(key, value)
    fs.makeDirectory("/external-data")
    local file = fs.open(paths.concat("/external-data", key .. ".dat"), "wb")
    if file then
        file.write(value)
        file.close()
    end
end

------------------------------------

if not vendor.doNotWriteExternalData then
    write("devicetype", system.getDeviceType())
    write("deviceaddress", computer.address())
    write("deviceinfo", serialization.serialization(lastinfo.deviceinfo))
    write("ram", tostring(computer.totalMemory()))

    local components = {}
    for address, ctype in component.list() do
        components[ctype] = components[ctype] or {}
        table.insert(components[ctype], address)
    end
    write("components", serialization.serialization(components))
end