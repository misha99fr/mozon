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

do
    local fs = require("filesystem")
    local paths = require("paths")
    local programs = require("programs")

    do
        local function unittests(path)
            for _, file in ipairs(fs.list(path) or {}) do
                local lpath = paths.concat(path, file)
                local ok, state, log = assert(programs.execute(lpath))
                if not ok then
                    error("unittest error " .. (state or "unknown error") .. " in unittest " .. file, 0)
                elseif not state then
                    error("warning utittest " .. file .. (log and (", log:\n" .. log) or ""), 0)
                end
            end
        end
        unittests("/system/core/unittests")
        unittests("/system/unittests")
    end

    if fs.exists("/system/main.lua") then
        assert(xpcall(assert(programs.load("/system/main.lua")), debug.traceback))
    end
end