local natives = require("natives")
local computer = require("computer")
local package = require("package")
local cache = require("cache")
local event = require("event")
local lastinfo = require("lastinfo")
local system = {}

-------------------------------------------------

function system.getSelfScriptPath()
    local info

    for runLevel = 0, math.huge do
        info = debug.getinfo(runLevel)

        if info then
            if info.what == "main" then
                return info.source:sub(2, -1)
            end
        else
            error("Failed to get debug info for runlevel " .. runLevel)
        end
    end
end

function system.getDeviceType()
    local function isType(ctype)
        return natives.component.list(ctype)() and ctype
    end
    
    local function isServer()
        local obj = lastinfo.deviceinfo[computer.address()]
        if obj and obj.description and obj.description:lower() == "server" then
            return "server"
        end
    end
    
    return isType("tablet") or isType("microcontroller") or isType("drone") or isType("robot") or isServer() or isType("computer") or "unknown"
end

function system.getCpuLevel()
    local processor = -1

    for _, value in pairs(lastinfo.deviceinfo) do
        if value.class == "processor" then
            if value.clock == "1500" or value.clock == "1000+1280/1280/160/2560/640/1280" or value.clock == "1500+2560/2560/320/5120/1280/2560" then
                processor = 3
                break
            elseif value.clock == "1000" or value.clock == "500+640/640/40/1280/320/640" then
                processor = 2
                break
            elseif value.clock == "500" then
                processor = 1
                break
            end
        end
    end

    return processor
end

-------------------------------------------------

local currentUnloadState
function system.setUnloadState(state)
    checkArg(1, state, "boolean")
    if currentUnloadState == state then return end
    currentUnloadState = state

    if state then
        setmetatable(package.cache, {__mode = 'v'})
        local calls = package.get("calls")
        if calls then
            setmetatable(calls.cache, {__mode = 'v'})
        end
    else
        setmetatable(package.cache, {})
        local calls = package.get("calls")
        if calls then
            setmetatable(calls.cache, {})
        end
    end
end
system.setUnloadState(false)

system.timerId = event.timer(1, function()
    --check RAM
    if computer.freeMemory() < computer.totalMemory() / 3 then
        system.setUnloadState(true)
        cache.clearCache()
    else
        system.setUnloadState(false)
    end
end, math.huge)

return system