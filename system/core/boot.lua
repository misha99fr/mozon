local raw_loadfile = ...

----------------------------------

local component = component
local computer = computer
local unicode = unicode

_G.COREVERSION = "v1.0"
_G._OSVERSION = "likeOS (core " .. _G.COREVERSION .. ")"

local function createEnv()
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

local lastTime = computer.uptime() --удаляю лишнии эвенты
while true do
    local eventData = {computer.pullSignal(0.5)}
    if eventData[1] == "component_added" or eventData[1] == "component_removed" then
        lastTime = computer.uptime()
    end
    if computer.uptime() - lastTime > 1 then
        break
    end
end

do --boot scripts
    local fs = require("filesystem")
    local paths = require("paths")

    local path = "/system/core/boot"
    for i, v in ipairs(fs.list(path) or {}) do
        raw_dofile(paths.concat(path, v), nil, _G)
    end
end

do
    local fs = require("filesystem")
    local paths = require("paths")
    local event = require("event")
    local programs = require("programs")

    local function autorunsIn(path)
        for i, v in ipairs(fs.list(path) or {}) do
            local full_path = paths.concat(path, v)
    
            local func, err = programs.load(full_path)
            if not func then
                event.tmpLog("err " .. (err or "unknown error") .. ", to load programm " .. full_path)
            else
                local ok, err = pcall(func)
                if not ok then
                    event.tmpLog("err " .. (err or "unknown error") .. ", in programm " .. full_path)
                end
            end        
        end
    end
    autorunsIn("/system/core/autoruns")
    autorunsIn("/system/autoruns")
end