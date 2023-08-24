local invoke = require("component").invoke
local address = ...

local signature = "--likeOS core"

local file = invoke(address, "open", "/init.lua", "rb")
if file then
    local data = invoke(address, "read", file, #signature)
    invoke(address, "close", file)

    return signature == data
end