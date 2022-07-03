--в ОС присутствует код из mineOS от Игоря Тимофеева https://github.com/IgorTimofeev/MineOS

do
    local bootaddress, invoke = computer.getBootAddress(), component.invoke
    local function raw_loadfile(path, mode, env)
        local file, buffer = assert(invoke(bootaddress, "open", path, "rb")), ""
        repeat
            local data = invoke(bootaddress, "read", file, math.huge)
            buffer = buffer .. (data or "")
        until not data
        return load(buffer, "=" .. path, mode or "bt", env or _G)
    end
    assert(xpcall(assert(raw_loadfile("/system/core/boot.lua")), debug.traceback, raw_loadfile))
end

local programs = require("programs")
assert(xpcall(assert(programs.load("shell")), debug.traceback))