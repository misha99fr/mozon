local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")
local calls = require("calls")

------------------------------------

local graphic = {}
graphic.unloaded = true

------------------------------------class window

local function set(self, x, y, background, foreground, text)
    local gpu = graphic.findGpu(self.screen)
    if gpu then
        gpu.setBackground(background)
        gpu.setForeground(foreground)
        gpu.set(self.x + (x - 1), self.y + (y - 1), text)
    end
end

local function fill(self, x, y, sizeX, sizeY, background, foreground, char)
    local gpu = graphic.findGpu(self.screen)
    if gpu then
        gpu.setBackground(background)
        gpu.setForeground(foreground)
        gpu.fill(self.x + (x - 1), self.y + (y - 1), sizeX, sizeY, char)
    end
end

local function copy(self, x, y, sizeX, sizeY, offsetX, offsetY)
    local gpu = graphic.findGpu(self.screen)
    if gpu then
        gpu.copy(self.x + (x - 1), self.y + (y - 1), sizeX, sizeY, offsetX, offsetY)
    end
end

local function clear(self, color)
    self:fill(1, 1, self.sizeX, self.sizeY, color, 0, " ")
end

local function setCursor(self, x, y)
    self.cursorX, self.cursorY = x, y
end

local function getCursor(self)
    return self.cursorX, self.cursorY
end

local function write(self, data, background, foreground, autoln)
    local gpu = graphic.findGpu(self.screen)

    if gpu then
        local buffer = ""
        local setX, setY = self.cursorX, self.cursorY
        local function applyBuffer()
            gpu.set(self.x + (setX - 1), self.y + (setY - 1), buffer)
            buffer = ""
            setX, setY = self.cursorX, self.cursorY
        end

        gpu.setBackground(background or 0)
        gpu.setForeground(foreground or 0xFFFFFF)

        for i = 1, unicode.len(data) do
            local char = unicode.sub(data, i, i)
            local ln = autoln and self.cursorX > self.sizeX
            local function setChar()
                --gpu.set(self.x + (self.cursorX - 1), self.y + (self.cursorY - 1), char)
                buffer = buffer .. char
                self.cursorX = self.cursorX + 1
            end
            if char == "\n" or ln then
                self.cursorY = self.cursorY + 1
                self.cursorX = 1
                applyBuffer()
                if ln then
                    setChar()
                end
            else
                setChar()
            end
        end

        applyBuffer()
    end
end

local function uploadEvent(self, eventData)
    local newEventData = {} --пустая таблица, чтобы не чекать на nil
    if eventData then
        if eventData[2] == self.screen and
        (eventData[1] == "touch" or eventData[1] == "drop" or eventData[1] == "drag" or eventData[1] == "scroll") then
            local oldSelected = self.selected
            local rePosX = (eventData[3] - self.x) + 1
            local rePosY = (eventData[4] - self.y) + 1
            self.selected = false
            if rePosX >= 1 and rePosY >= 1
            and rePosX <= self.sizeX and rePosY <= self.sizeY then
                self.selected = true
                newEventData = {eventData[1], eventData[2], rePosX, rePosY, eventData[5], eventData[6]}
            end
            if eventData[1] == "drop" then
                self.selected = oldSelected
            end
        elseif eventData[1] == "key_down" or eventData[1] == "key_up" or eventData[1] == "clipboard" then
            local ok
            for i, v in ipairs(component.invoke(self.screen, "getKeyboards")) do
                if eventData[2] == v then
                    ok = true
                    break
                end
            end
            if ok then
                newEventData = eventData
            end
        end
    end
    if self.selected then
        return newEventData
    end
    return {}
end

local function toRealPos(self, x, y)
    return self.x + (x - 1), self.y + (y - 1)
end

local function read(self, x, y, sizeX, background, foreground, preStr, crypto, buffer)
    local keyboards = component.invoke(self.screen, "getKeyboards")
    local buffer = buffer or ""
    local function redraw()
        local gpu = graphic.findGpu(self.screen)
        if gpu then
            gpu.setBackground(background)
            gpu.setForeground(foreground)
            local newBuffer = buffer
            if crypto then
                newBuffer = string.rep("*", unicode.len(newBuffer))
            end
            
            local str = (preStr or "") .. newBuffer .. "_"

            local num = (unicode.len(str) - sizeX) + 1
            if num < 1 then num = 1 end
            str = unicode.sub(str, num, unicode.len(str))

            if unicode.len(str) < sizeX then
                str = str .. string.rep(" ", sizeX - unicode.len(str))
            end

            gpu.set(self.x + (x - 1), self.y + (y - 1), str)
        end
    end
    redraw()

    return {uploadEvent = function(eventData)
        --вызывайте функцию и передавайте туда эвенты которые сами читаете, 
        --если функция чтото вернет, это результат, если он TRUE(не false) значет было нажато ctrl+c
        if eventData[1] == "key_down" then
            local ok
            for i, v in ipairs(keyboards) do
                if eventData[2] == v then
                    ok = true
                    break
                end
            end
            if ok and self.selected then
                if eventData[4] == 28 then
                    return buffer
                elseif eventData[4] == 14 then
                    if #buffer > 0 then
                        buffer = unicode.sub(buffer, 1, unicode.len(buffer) - 1)
                        redraw()
                    end
                elseif eventData[3] == 3 and eventData[4] == 46 then
                    return true --exit ctrl + c
                elseif eventData[3] > 0 then
                    buffer = buffer .. unicode.char(eventData[3])
                    redraw()
                end
            end
        elseif eventData[1] == "clipboard" and not crypto then
            buffer = buffer .. eventData[3]
            redraw()
            if buffer:byte(#buffer) == 13 then return buffer end
        end
    end, redraw = redraw, getBuffer = function()
        return buffer
    end, setBuffer = function(v)
        buffer = v
    end}
end

function graphic.createWindow(screen, x, y, sizeX, sizeY, selected)
    local obj = {
        screen = screen,
        x = x,
        y = y,
        sizeX = sizeX,
        sizeY = sizeY,
        cursorX = 1,
        cursorY = 1,

        read = read,
        toRealPos = toRealPos,
        set = set,
        fill = fill,
        copy = copy,
        clear = clear,
        uploadEvent = uploadEvent,
        write = write,
        getCursor = getCursor,
        setCursor = setCursor
    }
    if selected ~= nil then
        obj.selected = selected
    else
        local gpu = graphic.findGpu(screen)
        obj.selected = gpu and gpu.getDepth() == 1
    end

    return obj
end

------------------------------------

graphic.gpuPrivateList = {} --для приватизации видеокарт, дабы избежать "кражи" другими процессами, добовляйте так graphic.gpuPrivateList[gpuAddress] = true

--local bindCache = {}
function graphic.findGpu(screen)
    --от кеша слишком много проблемм, а findGpu и так довольно быстрая, за счет оптимизированого getDeviceInfo
    --if bindCache[screen] and bindCache[screen].getScreen() == screen then return bindCache[screen] end
    local deviceinfo = computer.getDeviceInfo()
    local screenLevel = tonumber(deviceinfo[screen].capacity) or 0

    local bestGpuLevel, gpuLevel, bestGpu = 0
    local function check(deep)
        for address in component.list("gpu") do
            if not graphic.gpuPrivateList[address] and deep or component.invoke(address, "getScreen") == screen then
                gpuLevel = tonumber(deviceinfo[address].capacity) or 0
                if component.invoke(address, "getScreen") == screen and gpuLevel == screenLevel then --уже подключенная видео карта, казырный туз, но только если она того же уровня что и монитор!
                    gpuLevel = gpuLevel + 99999999999999999999
                elseif gpuLevel == screenLevel then
                    gpuLevel = gpuLevel + 999999999
                elseif gpuLevel > screenLevel then
                    gpuLevel = gpuLevel + 999999
                end
                if gpuLevel > bestGpuLevel then
                    bestGpuLevel = gpuLevel
                    bestGpu = address
                end
            end
        end
    end
    check()
    check(true)
    
    if bestGpu then
        local gpu = component.proxy(bestGpu)
        if gpu.getScreen() ~= screen then
            gpu.bind(screen, false)
        end
        --bindCache[screen] = gpu
        return gpu
    end
end

--[[
event.listen(nil, function(eventType, _, ctype)
    if (eventType == "component_added" or eventType == "component_removed") and (ctype == "filesystem" or ctype == "gpu") then
        bindCache = {} --да, тупо создаю новую табличьку
    end
end)
]]

return graphic