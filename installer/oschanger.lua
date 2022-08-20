local computer = computer or require("computer")
local fs = require("filesystem")
local component = require("component")

local function getPath()
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
local driveAddress = fs.get(assert(getPath())).address

if not computer.setBootAddress then
    print("¯\\_(ツ)_/¯ усп, ваш биос не поддерживает устоновку загрузочьного насителя, попробуйте сами загрузиться с диска через биос, инструкция должна быть написана в описании вашего биоса")
    if component.isAvailable("eeprom") then
        print("ваш биос был определен как \"" .. (component.eeprom.getLabel() or "unknown") .. "\"")
    end
    return
end

computer.setBootAddress(driveAddress)
if computer.setBootFile then
    computer.setBootFile("/init.lua")
end
computer.shutdown("fast")