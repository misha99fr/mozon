local fs = require("filesystem")
local component = require("component")
local term = require("term")
if not component.isAvailable("internet") then
    print("no internet card found")
    return
end

local function readFunc()
    io.write("[Y/n] ")
    local read = term.read()
    if not read then return end
    return read:sub(1, #read - 1)
end

------------------------------------

local count = 1
local variantes = {}
for address in component.list("filesystem") do
    if not component.invoke(address, "isReadOnly") then
        print(tostring(count) .. ". " .. address:sub(1, 4) .. " label: " .. (component.invoke(address, "getLabel") or ""))
        count = count + 1
        table.insert(variantes, address)
    end
end

print("выберите диск который хотите сделать устоновочьным")
print("ВСЕ ДАННЫЕ С ДИСКА БУДУТ УДАЛЕНЫ")
local read = readFunc()
if not read then return end
if not tonumber(read) then
    print("invalide input")
    return
end
local address = variantes[tonumber(read)]
local proxy = component.proxy(address)

print("вы уверены сделать диск " .. address:sub(1, 4) .. ":" .. (component.invoke(address, "getLabel") or "") .. " устоновочьным диском likeOS?")
print("ВСЕ ДАННЫЕ С ДИСКА БУДУТ УДАЛЕНЫ")

local ok = readFunc()
if not ok or ok:lower() ~= "y" then
    return
end

local mountPath = "/free/tempMounts/installdrive"
fs.umount(mountPath)
fs.mount(proxy, mountPath)

proxy.remove("/")

------------------------------------

local function getInternetFile(url)
    local handle, data, result, reason = component.internet.request(url), ""
    if handle then
        while true do
            result, reason = handle.read(math.huge) 
            if result then
                data = data .. result
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return data
                end
            end
        end
    else
        return nil, "unvalid address"
    end
end

local function split(str, sep)
    local parts, count, i = {}, 1, 1
    while 1 do
        if i > #str then break end
        local char = str:sub(i, i - 1 + #sep)
        if not parts[count] then parts[count] = "" end
        if char == sep then
            count = count + 1
            i = i + #sep
        else
            parts[count] = parts[count] .. str:sub(i, i)
            i = i + 1
        end
    end
    if str:sub(#str - (#sep - 1), #str) == sep then t.insert(parts, "") end
    return parts
end

local url = "https://raw.githubusercontent.com/igorkll/likeOS/main"
local filelist = split(assert(getInternetFile(url .. "/installer/filelist.txt")), "\n")

for i, path in ipairs(filelist) do
    local full_url = url .. path
    local data = assert(getInternetFile(full_url))

    local lpath = fs.concat(mountPath, "core", path)
    fs.makeDirectory(fs.path(lpath))
    local file = assert(io.open(lpath, "wb"))
    file:write(data)
    file:close()
end

proxy.makeDirectory("/boot/kernel")
proxy.rename("/init.lua", "/boot/kernel/likemode")

local file = io.open(fs.concat(mountPath, "init.lua"), "wb")
file:write(assert(getInternetFile(url .. "/installer/maininstaller.lua")))
file:close()

local file = io.open(fs.concat(mountPath, ".install"), "wb")
file:write(assert(getInternetFile(url .. "/installer/oschanger.lua")))
file:close()

-----------------------------------------------------------------------------

local function downloadDistribution(url, folder)
    local filelist = split(assert(getInternetFile(url .. "/installer/filelist.txt")), "\n")

    for i, path in ipairs(filelist) do
        local full_url = url .. path
        local data = assert(getInternetFile(full_url))

        local lpath = fs.concat(mountPath, "distributions", folder, path)
        fs.makeDirectory(fs.path(lpath))
        local file = assert(io.open(lpath, "wb"))
        file:write(data)
        file:close()
    end
end

local filelist = split(assert(getInternetFile("https://raw.githubusercontent.com/igorkll/likeOS/main/installer/list.txt")), "\n")
for i, v in ipairs(filelist) do
    downloadDistribution(table.unpack(split(v, ";")))
end

print("создания загрузочьного диска завершено")