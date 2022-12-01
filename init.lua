--в ОС присутствует код из mineOS от Игоря Тимофеева https://github.com/IgorTimofeev/MineOS
--[[
likeOS, "чистая" ос без оболочьки, с низкими сис требованиями
предназначена для автоматизации(роботов, упровления аэс)
ос имеет очень низкий разход оперативной памяти благодаря системме calls
которыя позволяет обрашяться к функциям лежашие на hdd
имееться умная автовыгрузка библиотек

ядро ос содержит простой api для работы с графикой, который поможет вам в осрисовки интерфейсов
даный api позволит вам работать на нескольких мониторах, а заботу переключения gpu возмет на себя сам api
однако для работы на нескольких мониторах стоит использовать несколько видеокарт(так будет быстрее)
если вы хотите использовать ос на компьютере, могу посоветовать дистрибутив liked(https://github.com/igorkll/liked)
ос имеет очень низкий разход оперативной памяти благодаря системме calls
которыя позволяет обрашяться к функциям лежашие на hdd

для создания собственного дистрибутива, я рекомендую скопировать ядро в репозиторий, так как при обновлении ваш дистрибутив может поломаться, дабы этого избежать, скопируйте текушию версию ядра к себе в репозиторий и обновляйте в ручьную, где нада - допиливайте

likeOS разпостраняеться без лиценции по этому вы имеете полное право на копирования хоть всего кода, так как я терпеть не могу всякого рода ограничалки для кода, код обший и принадлежит всем и каждому

структура файловой системмы
/system/core - ядро ос, туда лутще не лезть без крайней необходимости
/system - файлы дистрибутива, при создании дистрибутива программы и библиотеки закидывайте сюда
/data - данные ос и юзера(расположения файлов юзера зависит от дистрибутива, но всегда расположены в папке data в liked это /data/userdata)
]]

------------------------------------base init

local component, computer, unicode = component, computer, unicode
pcall(computer.setArchitecture, "Lua 5.3")
_G._COREVERSION = "v1.1"

local bootaddress = computer.getBootAddress()
local bootfs = component.proxy(bootaddress)

------------------------------------background

do
    local shutdown = computer.shutdown
    function computer.shutdown(reboot)
        if sendTelemetry then
            pcall(sendTelemetry, "power off", (reboot and "reboot" or "shutdown"))
        end
        return shutdown(reboot)
    end
end

------------------------------------base funcs

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

------------------------------------registry

local registry = {}

do
    local registryPath = "/data/registry.dat"

    local mainRegistryPath
    if bootfs.exists("/vendor/registry.dat") then
        mainRegistryPath = "/vendor/registry.dat"
    elseif bootfs.exists("/system/registry.dat") then
        mainRegistryPath = "/system/registry.dat"
    elseif bootfs.exists("/system/core/registry.dat") then
        mainRegistryPath = "/system/core/registry.dat"
    end

    if mainRegistryPath and bootfs.exists(mainRegistryPath) and not bootfs.exists(registryPath) then
        bootfs.makeDirectory("/data")
        saveFile(bootfs, registryPath, getFile(bootfs, mainRegistryPath))
    end

    if bootfs.exists(registryPath) then
        local file = bootfs.open(registryPath, "rb")
        if file then
            local buffer = ""
            repeat
                local data = bootfs.read(file, math.huge)
                buffer = buffer .. (data or "")
            until not data
            bootfs.close(file)

            local code = load("return " .. buffer)
            if code then
                local result = {pcall(code)}
                if result[1] and type(result[2]) == "table" then
                    registry = result[2]
                end
            end
        end
    end
end

------------------------------------functions

local function initScreen(gpu, screen)
    if gpu.getScreen() ~= screen then
        gpu.bind(screen, false)
    end
    gpu.setDepth(1)
    gpu.setDepth(gpu.maxDepth())
    gpu.setResolution(50, 16)
    gpu.setBackground(0)
    gpu.setForeground(0xFFFFFF)
    gpu.fill(1, 1, 50, 16, " ")
end

do
    local gpu = component.proxy(component.list("gpu")() or "")
    if gpu then
        for screen in component.list("screen") do
            initScreen(gpu, screen)
        end
    end
end

function printText(text)
    if registry.disableLogo then return end

    local gpu = component.proxy(component.list("gpu")() or "")
    if gpu then
        for screen in component.list("screen") do
            initScreen(gpu, screen)
            
            local logoPath
            if bootfs.exists("/data/logo.lua") then
                logoPath = "/data/logo.lua"
            elseif bootfs.exists("/vendor/logo.lua") then
                logoPath = "/vendor/logo.lua"
            elseif bootfs.exists("/system/logo.lua") then
                logoPath = "/system/logo.lua"
            elseif bootfs.exists("/system/core/logo.lua") then
                logoPath = "/system/core/logo.lua"
            end

            local logo = raw_loadfile(logoPath, nil, setmetatable({gpu = gpu, text = text, unicode = unicode, computer = computer, component = component}, {__index = _G}))
            if logo then
                logo()
            end
        end
    end
end

------------------------------------recovery menu

if not registry.disableRecovery then
    printText("Press R to open recovery menu...")

    local gpu = component.proxy(component.list("gpu")() or "")

    if gpu and component.list("screen")() then
        local recoveryScreen
        for i = 1, 5 do
            local eventData = {computer.pullSignal(0.5)}
            if eventData[1] == "key_down" and eventData[4] == 19 then
                for address in component.list("screen") do
                    local keyboards = component.invoke(address, "getKeyboards")
                    for i, keyboard in ipairs(keyboards) do
                        if keyboard == eventData[2] then
                            recoveryScreen = address
                            goto exit
                        end
                    end
                end
            end
        end
        ::exit::

        if recoveryScreen then
            printText("RECOVERY MOD")
            initScreen(gpu, recoveryScreen)

            local recoveryPath
            if bootfs.exists("/data/recovery.lua") then
                recoveryPath = "/data/recovery.lua"
            elseif bootfs.exists("/vendor/recovery.lua") then
                recoveryPath = "/vendor/recovery.lua"
            elseif bootfs.exists("/system/recovery.lua") then
                recoveryPath = "/system/recovery.lua"
            elseif bootfs.exists("/system/core/recovery.lua") then
                recoveryPath = "/system/core/recovery.lua"
            end

            if recoveryPath then
                assert(xpcall(raw_loadfile(recoveryPath), debug.traceback, gpu, bootfs))
            else
                printText("RECOVERY MOD IS MOD SUPPORTED")

                while true do
                    computer.pullSignal()
                end
            end
        end
    end
end

------------------------------------main init

printText("booting...")

local invoke = component.invoke

------------------------------------check error

local ok, err = xpcall(function()
    local code, err = raw_loadfile("/system/core/boot.lua")
    if not code then
        error("err to load bootloader " .. (err or "unknown error"), 0)
    end

    code(raw_loadfile)
end, debug.traceback)

if not err then
    err = "unknown"
end

pcall(sendTelemetry, "globalError", err)

------------------------------------log error

if require and pcall then
    local function local_require(name)
        local result = {pcall(require, name)}
        if result[1] and type(result[2]) == "table" then
            return result[2]
        end
    end
    local event = local_require("event")
    if event and event.errLog then
        pcall(event.errLog, "\nglobal error: " .. err .. "\n")
    end
end

------------------------------------error output

computer.shutdown(true)
--error(err, 0)