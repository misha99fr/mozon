local component = require("component")

local function isType(ctype)
    return component.list(ctype)() and ctype
end

return isType("tablet") or isType("microcontroller") or isType("drone") or isType("robot") or isType("computer") or "unknown"