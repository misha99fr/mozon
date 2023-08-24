local natives = require("natives")
local computer = require("computer")

local function isType(ctype)
    return natives.component.list(ctype)() and ctype
end

local function isServer()
    local obj = computer.getDeviceInfo()[computer.address()]
    if obj and obj.description and obj.description:lower() == "server" then
        return "server"
    end
end

return isType("tablet") or isType("microcontroller") or isType("drone") or isType("robot") or isServer() or isType("computer") or "unknown"