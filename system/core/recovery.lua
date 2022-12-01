local gpu, bootfs = ...

------------------------------------

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

local function saveFile(fs, path, data)
    local file, err = fs.open(path, "wb")
    if not file then return nil, err end

    fs.write(file, data)
    fs.close(file)

    return true
end

local function raw_loadfile(path, mode, env)
    local data, err = getFile(bootfs, path)
    if not data then return nil, err end
    return load(data, "=" .. path, mode or "bt", env or _G)
end

local cache = {}
function require(name)
    if _G[name] then
        return _G[name]
    end

    --[[
    if name == "filesystem" then
        return setmetatable({
            open = function(path, mode)
                local file, err = selectedfs.open(path, mode or "rb")
                if not file then return nil, err end

                return {
                    read = function(...) return selectedfs.read(file, ...) end,
                    write = function(...) return selectedfs.write(file, ...) end,
                    close = function(...) return selectedfs.close(file, ...) end,
                    seek = function(...) return selectedfs.seek(file, ...) end,
                    readAll = function()
                        local buffer = ""
                        repeat
                            local data = selectedfs.read(file, math.huge)
                            buffer = buffer .. (data or "")
                        until not data
                        return buffer
                    end,
                    handle = file,
                }
            end
        }, {__index = selectedfs})
    end
    ]]--

    if not cache[name] then
        cache[name] = assert(raw_loadfile("/system/core/lib/" .. name .. ".lua"))()
    end
    return cache[name]
end

local paths = require("paths")
local fs = require("filesystem")


setmetatable(_G, {__index = function(_, key)
    local code = raw_loadfile("/system/core/calls/" .. key .. ".lua")
    if code then
        return code
    end
end})

------------------------------------

local rx, ry = gpu.getResolution()

local function clearColor()
    gpu.setBackground(0)
    gpu.setForeground(0xFFFFFF)
end

local function clear()
    clearColor()
    gpu.fill(1, 1, rx, ry, " ")
end

local function invert()
    gpu.setBackground(gpu.setForeground(gpu.getBackground()))
end

local function menu(title, strs, selected)
    local selected = selected or 1
    
    local function redraw()
        clear()
        gpu.set(1, 1, title)
        gpu.fill(1, 2, rx, 1, "-")


        for i, str in ipairs(strs) do
            if i == selected then invert() end
            gpu.set(1, i + 2, str)
            if i == selected then invert() end
        end
    end

    redraw()

    while true do
        local eventData = {computer.pullSignal()}
        if eventData[1] == "key_down" then
            if eventData[4] == 208 then
                if selected < #strs then
                    selected = selected + 1
                    redraw()
                end
            elseif eventData[4] == 200 then
                if selected > 1 then
                    selected = selected - 1
                    redraw()
                end
            elseif eventData[4] == 28 then
                return selected
            end
        end
    end
end

local function yesno(title)
    return menu(title, {"no", "no", "no", "no", "no", "no", "no", "no", "yes", "no", "no", "no"}) == 9
end

local function status(text, wait)
    clear()
    gpu.set(1, 1, text)

    if wait then
        gpu.set(1, 2, "press enter to contionue")
    end

    while wait do
        local eventData = {computer.pullSignal()}
        if eventData[1] == "key_down" and eventData[4] == 28 then
            break
        end
    end
end

------------------------------------

local function filePicker(title)
    local filesystems = {"cancel"}
    local addresses = {false}
    for address, ctype in component.list("filesystem") do
        table.insert(filesystems, (component.invoke(address, "getLabel") or "no label") .. ":" .. address:sub(1, 5) .. (address == bootfs.address and ":sys" or ""))
        table.insert(addresses, address)
    end

    local cfs = component.proxy(addresses[menu("select disk", filesystems)] or "")
    if not cfs then return end

    ------------------------------------
    
    local path = "/"
    local function getFiles()
        local files = {}
        for i, file in ipairs(cfs.list(path)) do
            table.insert(files, file)
        end
        return files
    end
    
    while true do
        local files = getFiles()
        table.insert(files, 1, "back")
        table.insert(files, 1, "cancel")
        local selected = menu(title .. " : " .. path, files)
        if selected == 1 then
            return
        elseif selected == 2 then
            path = paths.path(path)
        else
            local file = paths.concat(path, files[selected])
        
            if cfs.isDirectory(file) then
                path = paths.concat(path, paths.name(file))
            else
                return cfs, file
            end
        end
    end
end

local function logs()
    local logs = {}
    for i, str in ipairs(split(assert(getFile(bootfs, "/data/errorlog.log")), "\n")) do
        local strs = toPartsUnicode(str, rx)
        local exists
        for i, str in ipairs(strs) do
            table.insert(logs, str)
            exists = true
        end
        if not exists then
            table.insert(logs, "")
        end
    end

    local scroll = 1

    while true do
        clear()
        local count = 1
        for i, str in ipairs(logs) do
            if i >= scroll then
                gpu.set(1, count, str)
                if count > ry then
                    break
                end
                count = count + 1
            end
        end

        local eventData = {computer.pullSignal()}
        if eventData[1] == "key_down" then
            if eventData[4] == 28 then
                break
            elseif eventData[4] == 200 then --up
                if scroll > 1 then
                    scroll = scroll - 1
                end
            elseif eventData[4] == 208 then --down
                if scroll < #logs - ry then
                    scroll = scroll + 1
                end
            end
        end
    end
end

------------------------------------

pcall(sendTelemetry, "recovery", "recovery open")

local selected
while true do
    selected = menu("likeOS-" .. _COREVERSION .. " recovery menu",
    {
        "Wipe data/factory reset",
        "Flash afpx archive",
        "Run Lua Script",
        "View Logs",
        "Shutdown",
        "Reboot"
    }, selected)

    if selected == 1 then
        if yesno("wipe data?") then
            pcall(sendTelemetry, "data wiped")
            bootfs.remove("/data")
        end
    elseif selected == 2 then
        local cfs, path = filePicker("Select System Archive")

        if cfs then
            if paths.extension(path) == "afpx" then
                if cfs ~= bootfs then
                    if yesno("flash this file? all data will be deleted!") then
                        fs.mountList = {}
                        
                        pcall(sendTelemetry, "flashing firmware", path)
                        status("flashing...")

                        local afpx = require("afpx")
                        bootfs.remove("/")
                        fs.mount(bootfs, "/sys")
                        fs.mount(cfs, "/disk")
                        assert(afpx.unpack(paths.concat("/disk", path), "/sys"))
                        _G.DISABLE_TELEMETRY = true
                        computer.shutdown(true)
                    end
                else
                    status("you cannot install the firmware from this disk", true)
                end
            else
                status("is not AFPX file", true)
            end
        end
    elseif selected == 3 then
        local cfs, path = filePicker("select lua scripts")

        if cfs then
            pcall(sendTelemetry, "recovery", "runing lua script", path)
            local code, err = load(getFile(cfs, path), "=luascripts", "bt", setmetatable({gpu = gpu}, {__index = _G}))
            if not code then
                pcall(sendTelemetry, "recovery", "runing lua script result: " .. tostring(err or "unknown"))
                error(err, 0)
                return
            end
            code()
        end
    elseif selected == 4 then
        if bootfs.exists("/data/errorlog.log") then
            logs()
        else
            status("Logs Not Found", true)
        end
    elseif selected == 5 then
        computer.shutdown()
    elseif selected == 6 then
        computer.shutdown(true)
    end
end