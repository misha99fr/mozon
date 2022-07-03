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

do --оптимизация для computer.getDeviceInfo
    local computer_pullSignal = computer.pullSignal
    local deviceinfo = computer.getDeviceInfo()

    function computer.getDeviceInfo()
        return deviceinfo
    end
    function computer.pullSignal(time)
        local eventData = {computer_pullSignal(time)}
        if eventData[1] == "component_added" or eventData[1] == "component_removed" then
            deviceinfo = computer.getDeviceInfo()
        end
        return table.unpack(eventData)
    end
end

do --package
    local package = raw_dofile("/system/core/lib/package.lua", nil, createEnv(), raw_dofile, createEnv)

    _G.computer = nil
    _G.component = nil
    _G.unicode = nil
end

----------------------------------

local windows = {}
for address in component.list("screen") do
    local term = require("term")
    local gpu = term.findGpu(address)
    if gpu then
        table.insert(windows, term.classWindow:new(address, 1, 1, 25, 5))
        table.insert(windows, term.classWindow:new(address, 1, 7, 25, 5))
    end
end

for i, window in ipairs(windows) do
    window:clear(math.random(0, 0xFFFFFF))
    window:write("1")
end