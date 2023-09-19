--likeOS classic bootloader

local raw_loadfile, bootfs = ...

-------------------------------------- initialization

do
    function createEnv() --создает _ENV для программы, где _ENV будет личьный, а _G обший
        return setmetatable({_G = _G}, {__index = _G})
    end

    local function raw_dofile(path, mode, env, ...)
        return assert(raw_loadfile(path, mode, env))(...)
    end

    if not bit32 then --на lua 5.3 нет встроеной либы bit32, но она нужна для совместимости, так что хай будет
        _G.bit32 = raw_dofile("/system/core/lib/bit32.lua", nil, createEnv(), raw_dofile)
    end
    raw_dofile("/system/core/boot/a_functions.lua", nil, _G) --загружаю зарания, так как это нужно для инициализации natives
    _G.natives = raw_dofile("/system/core/lib/natives.lua", nil, createEnv(), raw_dofile) --natives позваляет получить доступ к нетронутым методами библиотек computer и component

    do --бут скрипты, тут инициализации всего и вся
        local path = "/system/core/boot/"
        for i, v in ipairs(bootfs.list(path) or {}) do
            raw_dofile(path .. v, nil, _G)
        end
    end

    raw_dofile("/system/core/lib/package.lua", nil, createEnv(), raw_dofile, bootfs) --package инициализирует библиотеки

    _G.computer = nil
    _G.component = nil
    _G.unicode = nil
    _G.natives = nil

    require("event")
    require("system")
end

-------------------------------------- unittests

do
    local fs = require("filesystem")
    local paths = require("paths")
    local programs = require("programs")

    function unittests(path, ...) --доступно глобально
        for _, file in ipairs(fs.list(path)) do
            local lpath = paths.concat(path, file)
            local ok, state, log = assert(programs.execute(lpath, ...))
            if not ok then
                error("error \"" .. (state or "unknown error") .. "\" in unittest: " .. file, 0)
            elseif not state then
                error("warning unittest \"" .. file .. "\" \"" .. (log and (", log:\n" .. log) or "") .. "\"", 0)
            end
        end
    end
    unittests("/system/core/unittests")
    unittests("/system/unittests")
    --unittests("/vendor/unittests") --дабовляйте сами в свой дистрибутив при необходимости(так как может быть необходим запуск после инициализации)
    --unittests("/data/unittests") --дабовляйте сами в свой дистрибутив при необходимости(так как может быть необходим запуск после инициализации)
end

-------------------------------------- используйте автозагрузку для программ выполняешихся быстно, и не требуюших взаимодействий

do
    local fs = require("filesystem")
    local paths = require("paths")
    local event = require("event")
    local programs = require("programs")

    function autorunsIn(path, ...) --доступно глобально
        for i, v in ipairs(fs.list(path)) do
            local full_path = paths.concat(path, v)
    
            local func, err = programs.load(full_path)
            if not func then
                event.errLog("err \"" .. (err or "unknown error") .. "\", to load programm: " .. full_path)
            else
                local ok, err = pcall(func, ...)
                if not ok then
                    event.errLog("err \"" .. (err or "unknown error") .. "\", in programm: " .. full_path)
                end
            end        
        end
    end
    autorunsIn("/system/core/autoruns")
    autorunsIn("/system/autoruns")
    --autorunsIn("/vendor/autoruns") --дабовляйте сами в свой дистрибутив при необходимости(так как может быть необходим запуск после инициализации)
    --autorunsIn("/data/autoruns") --дабовляйте сами в свой дистрибутив при необходимости(так как может быть необходим запуск после инициализации)
end

--------------------------------------используйте main.lua для запуска оболочьки, или основной программы

bootSplash("Running main.lua...")
if require("filesystem").exists("/system/main.lua") then
    local code, err = require("programs").load("/system/main.lua")
    if not code then
        error("failed to loading main.lua" .. err, 0)
    end
    code()
else
    bootSplash("main.lua does not exist. press enter to continue")
    waitEnter()
end