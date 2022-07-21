--likeOS classic boot loader

do --main
    local raw_loadfile = ...

    local component = component
    local computer = computer
    local unicode = unicode

    pcall(computer.setArchitecture, "Lua 5.3")

    ------------------------------------

    _G._COREVERSION = "v0.5"
    _G._COREVERSIONID = 4

    local function createEnv() --создает _ENV для программы, где _ENV будет личьный, а _G обший
        return setmetatable({_G = _G}, {__index = _G})
    end

    local function raw_dofile(path, mode, env, ...)
        return assert(raw_loadfile(path, mode, env))(...)
    end

    do --package
        local package = raw_dofile("/system/core/lib/package.lua", nil, createEnv(), raw_dofile, createEnv)

        _G.computer = nil
        _G.component = nil
        _G.unicode = nil
    end

    do --boot scripts
        local fs = require("filesystem")
        local paths = require("paths")
    
        local path = "/system/core/boot"
        for i, v in ipairs(fs.list(path) or {}) do
            raw_dofile(paths.concat(path, v), nil, _G)
        end
    end
end

do --unittests
    local fs = require("filesystem")
    local paths = require("paths")
    local programs = require("programs")

    local function unittests(path)
        for _, file in ipairs(fs.list(path) or {}) do
            local lpath = paths.concat(path, file)
            local ok, state, log = assert(programs.execute(lpath))
            if not ok then
                error("error " .. (state or "unknown error") .. " in unittest " .. file, 0)
            elseif not state then
                error("warning utittest " .. file .. (log and (", log:\n" .. log) or ""), 0)
            end
        end
    end
    unittests("/system/core/unittests")
    unittests("/system/unittests")
end

do --используйте автозагрузку для программ выполняешихся быстно, и не требуюших взаимодействий
    local fs = require("filesystem")
    local paths = require("paths")
    local event = require("event")
    local programs = require("programs")

    local function autorunsIn(path)
        for i, v in ipairs(fs.list(path) or {}) do
            local full_path = paths.concat(path, v)
    
            local func, err = programs.load(full_path)
            if not func then
                event.errLog("err " .. (err or "unknown error") .. ", to load programm " .. full_path)
            else
                local ok, err = pcall(func)
                if not ok then
                    event.errLog("err " .. (err or "unknown error") .. ", in programm " .. full_path)
                end
            end        
        end
    end
    autorunsIn("/system/core/autoruns")
    autorunsIn("/system/autoruns")
end

do --используйте main.lua для запуска оболочьки, или основной программы
    local fs = require("filesystem")
    local programs = require("programs")

    if fs.exists("/system/main.lua") then
        local code, err = programs.load("/system/main.lua")
        if not code then
            error("failed to loading main.lua" .. (err), 0)
        end
        code()
    end
end