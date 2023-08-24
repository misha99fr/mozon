--likeOS core
--[[
likeOS, "чистая" ос без оболочьки, с низкими сис требованиями, предназначена для автоматизации(роботов, упровления аэс)
ос имеет очень низкий разход оперативной памяти благодаря системме calls, которыя позволяет обрашяться к функциям лежашие на hdd
имееться умная автовыгрузка библиотек
ядро ос содержит простой api для работы с графикой, который поможет вам в осрисовки интерфейсов
данный api позволит вам работать на нескольких мониторах, а заботу переключения gpu возмет на себя сам api
однако для работы на нескольких мониторах стоит использовать несколько видеокарт(так будет быстрее)
если вы хотите использовать ос на компьютере, могу посоветовать дистрибутив liked(https://github.com/igorkll/liked) официальный дистрибутив likeOS для компьютеров и планшетов

структура файловой системмы
/system/core - ядро ос, туда лутще не лезть без крайней необходимости
/system - файлы дистрибутива, при создании дистрибутива программы и библиотеки закидывайте сюда
/data - данные ос и юзера(расположения файлов юзера зависит от дистрибутива, но всегда расположены в папке data в liked это /data/userdata)
]]

pcall(computer.setArchitecture, "Lua 5.3")

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

assert(load(assert(getFile(bootfs, bootfile)), "=init", nil, _ENV))()