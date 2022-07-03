local raw_loadfile = ...

----------------------------------

local component = component
local computer = computer
local unicode = unicode

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

do --boot scripts
    local fs = require("filesystem")
    local paths = require("paths")
    local calls = require("calls")
    local createEnv = calls.load("createEnv")

    local path = "/system/core/boot"
    for i, v in ipairs(fs.list(path) or {}) do
        --component.proxy(component.list("gpu")()).set(1, 1, v)
        local full_path = paths.concat(path, v)
        if fs.exists(full_path) then
            raw_dofile(full_path, nil, createEnv())
        end
    end
end

----------------------------------

local windows = {}
do
    local calls = require("calls")
    local graphicInit = calls.load("graphicInit")

    for address in component.list("screen") do
        local term = require("term")
        local gpu = term.findGpu(address)
        if gpu then
            graphicInit(gpu)
            table.insert(windows, term.classWindow:new(address, 1, 1, 25, 5))
            table.insert(windows, term.classWindow:new(address, 1, 7, 25, 5))
        end
    end
end

for i, window in ipairs(windows) do
    window:clear(math.random(0, 0xFFFFFF))
    for i = 1, 3 do
        window:write(tostring(i) .. "\n", math.random(0, 0xFFFFFF), math.random(0, 0xFFFFFF))
        os.sleep(1)
    end
end