--в ОС присутствует код из mineOS от Игоря Тимофеева https://github.com/IgorTimofeev/MineOS

local bootaddress, invoke = computer.getBootAddress(), component.invoke
local function raw_loadfile(path, mode, env)
    local file, err = invoke(bootaddress, "open", path, "rb")
    if not file then return nil, err end
    local buffer = ""
    repeat
        local data = invoke(bootaddress, "read", file, math.huge)
        buffer = buffer .. (data or "")
    until not data
    return load(buffer, "=" .. path, mode or "bt", env or _G)
end
local code, err = raw_loadfile("/system/core/boot.lua")
if not code then
    error("err to load bootloader " .. (err or "unknown error"), 0)
end
code(raw_loadfile)


do
    local fs = require("filesystem")
    local paths = require("paths")
    local programs = require("programs")

    

    if fs.exists("/system/main.lua") then
        local ok, err = xpcall(assert(programs.load("/system/main.lua")), debug.traceback)
        if not ok then
            error(err, 0)
        end
    end
end