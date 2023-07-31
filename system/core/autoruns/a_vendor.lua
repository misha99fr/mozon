local fs = require("filesystem")

if fs.exists("/vendor/config.cfg") then
    _G.vendor = unserialization(getFile("/vendor/config.cfg"))
else
    _G.vendor = {}
end