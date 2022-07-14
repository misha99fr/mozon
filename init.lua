--в ОС присутствует код из mineOS от Игоря Тимофеева https://github.com/IgorTimofeev/MineOS
--[[
likeOS, "чистая" ос без оболочьки, с низкими сис требованиями
предназначена для автоматизации(роботов, упровления аэс)
ядро ос содержит простой api для работы с графикой, который поможет вам в осрисовки интерфейсов
даный api позволит вам работать на нескольких мониторах, а заботу переключения gpu возмет на себя сам api
однако для работы на нескольких мониторах стоит использовать несколько видеокарт(так будет быстрее)
]]

local bootaddress, invoke = computer.getBootAddress(), component.invoke
local function raw_loadfile(path, mode, env)
    local file, err = invoke(bootaddress, "open", path, "rb")
    if not file then return nil, err end
    local buffer = ""
    repeat
        local data = invoke(bootaddress, "read", file, math.huge)
        buffer = buffer .. (data or "")
    until not data
    return load(buffer, "=" .. path, mode or "bt", env or _G)
end
local code, err = raw_loadfile("/system/core/boot.lua")
if not code then
    error("err to load bootloader " .. (err or "unknown error"), 0)
end
code(raw_loadfile)