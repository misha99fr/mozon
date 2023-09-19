--likeOS core
local bootfs = component.proxy(computer.getBootAddress())
local tmpfs = component.proxy(computer.tmpAddress())

local function getFile(fs, path)
    local file, err = fs.open(path, "rb")
    if not file then return nil, err end

    local buffer = ""
    repeat
        local data = fs.read(file, math.huge)
        buffer = buffer .. (data or "")
    until not data
    fs.close(file)

    return buffer
end

local bootfile = "/system/core/startup.lua"
if tmpfs.exists("/bootTo") then
    bootfile = assert(getFile(tmpfs, "/bootTo"))
    tmpfs.remove("/bootTo")
end

assert(load(assert(getFile(bootfs, bootfile)), "=system_startup", nil, _ENV))()