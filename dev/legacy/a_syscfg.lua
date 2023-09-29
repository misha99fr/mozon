local fs = require("filesystem")

if fs.exists("/data/syscfg.cfg") then
    _G.syscfg = unserialization(getFile("/data/syscfg.cfg"))
elseif fs.exists("/vendor/syscfg.cfg") then
    _G.syscfg = unserialization(getFile("/vendor/syscfg.cfg"))
elseif fs.exists("/system/syscfg.cfg") then
    _G.syscfg = unserialization(getFile("/system/syscfg.cfg"))
elseif fs.exists("/core/system/syscfg.cfg") then
    _G.syscfg = unserialization(getFile("/core/system/syscfg.cfg"))
end

_G.syscfg = _G.syscfg or {}
_G.vendor = _G.syscfg