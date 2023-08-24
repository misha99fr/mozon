local component = require("component")
local computer = require("computer")
local unicode = require("unicode")
local event = require("event")
local calls = require("calls")
local colors = require("colors")
local cache = require("cache")

------------------------------------

local graphic = {}
graphic.unloaded = true
graphic.screensBuffers = {}
graphic.globalUpdated = false
graphic.updated = {}
graphic.allowBuffer = false
graphic.allowSoftwareBuffer = computer.totalMemory() / 1024 > 400 --в разработке
graphic.windows = setmetatable({}, {__mode = "v"})
graphic.inputHistory = {}
graphic.disableBuffers = {}

graphic.cursorColor = nil
graphic.selectColor = nil
graphic.selectColorFore = nil

local function valueCheck(value)
    if value ~= value or value == math.huge or value == -math.huge then
        value = 0
    end
    return math.round(value)
end

------------------------------------class window

local function set(self, x, y, background, foreground, text)
    graphic.update(self.screen)
    local gpu = graphic.findGpu(self.screen)
    if gpu then
        gpu.setBackground(background, self.isPal)
        gpu.setForeground(foreground, self.isPal)
        gpu.set(valueCheck(self.x + (x - 1)), valueCheck(self.y + (y - 1)), text)
    end
end

local function get(self, x, y)
    local gpu = graphic.findGpu(self.screen)
    if gpu then
        return gpu.get(valueCheck(self.x + (x - 1)), valueCheck(self.y + (y - 1)))
    end
end

local function fill(self, x, y, sizeX, sizeY, background, foreground, char)
    graphic.update(self.screen)
    local gpu = graphic.findGpu(self.screen)
    if gpu then
        gpu.setBackground(background, self.isPal)
        gpu.setForeground(foreground, self.isPal)
        gpu.fill(valueCheck(self.x + (x - 1)), valueCheck(self.y + (y - 1)), valueCheck(sizeX), valueCheck(sizeY), char)
    end
end

local function copy(self, x, y, sizeX, sizeY, offsetX, offsetY)
    graphic.update(self.screen)
    local gpu = graphic.findGpu(self.screen)
    if gpu then
        gpu.copy(valueCheck(self.x + (x - 1)), valueCheck(self.y + (y - 1)), valueCheck(sizeX), valueCheck(sizeY), valueCheck(offsetX), valueCheck(offsetY))
    end
end

local function clear(self, color)
    self:fill(1, 1, self.sizeX, self.sizeY, color, 0, " ")
end

local function setCursor(self, x, y)
    self.cursorX, self.cursorY = valueCheck(x), valueCheck(y)
end

local function getCursor(self)
    return self.cursorX, self.cursorY
end

local function write(self, data, background, foreground, autoln)
    graphic.update(self.screen)
    local gpu = graphic.findGpu(self.screen)

    if gpu then
        local buffer = ""
        local setX, setY = self.cursorX, self.cursorY
        local function applyBuffer()
            gpu.set(self.x + (setX - 1), self.y + (setY - 1), buffer)
            buffer = ""
            setX, setY = self.cursorX, self.cursorY
        end

        gpu.setBackground(background or (self.isPal and colors.black or 0), self.isPal)
        gpu.setForeground(foreground or (self.isPal and colors.white or 0xFFFFFF), self.isPal)

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

local function read(self, x, y, sizeX, background, foreground, preStr, hidden, buffer, clickCheck, syntax, disHistory, sizeY)
    local oldX
    if preStr then
        oldX = x
        x = x + #preStr
        sizeX = sizeX - #preStr
    end

    sizeY = sizeY or 1
    local isMultiline = sizeY ~= 1

    local maxX, maxY = self.x + (x - 1) + (sizeX - 1), self.y + (y - 1) + (sizeY - 1)
    
    local keyboards = component.invoke(self.screen, "getKeyboards")
    local buffer = buffer or ""
    local lastBuffer = ""
    local allowUse = not clickCheck
    local historyIndex
    
    local cursorColor = graphic.cursorColor
    if not cursorColor then
        if self.isPal then
            cursorColor = colors.lightgreen
        else
            local gpu = graphic.findGpu(self.screen)
            local depth = gpu.getDepth()
            if depth == 8 then
                cursorColor = 0x00ff00
            elseif depth == 4 then
                cursorColor = gpu.getPaletteColor(colors.lightgreen)
            else
                cursorColor = foreground
            end
        end
    end

    local selectColor, selectColorFore = graphic.selectColor, graphic.selectColorFore
    --selectColorFore - актуален только для мониторов первого тира
    if not selectColor then
        if self.isPal then
            selectColor = colors.blue
        else
            local gpu = graphic.findGpu(self.screen)
            local depth = gpu.getDepth()

            if depth == 8 then
                selectColor = 0x0000ff
            elseif depth == 4 then
                selectColor = gpu.getPaletteColor(colors.blue)
            else
                selectColor = 0xffffff
                selectColorFore = 0x000000
            end
        end
    end

    local selectFrom
    local selectTo

    local offsetX = 0
    local offsetY = 0

    if disHistory == nil then
        disHistory = not not hidden
    end

    local function getBackCol(i)
        if selectFrom then
            return (i >= selectFrom and i <= selectTo) and selectColor or background
        else
            return background
        end
    end

    local function getForeCol(i, def)
        if selectFrom and selectColorFore then
            return (i >= selectFrom and i <= selectTo) and selectColorFore or def
        else
            return def
        end
    end
    
    local function redraw()
        graphic.update(self.screen)
        local gpu = graphic.findGpu(self.screen)

        if gpu then
            local cursorPos
            local str = buffer
            if allowUse and self.selected then
                --str = str .. "\0"
                cursorPos = unicode.len(str) + 1
            end
            str = str .. lastBuffer

            --[[
            local num = (unicode.len(str) - sizeX) + 1
            if num < 1 then num = 1 end
            str = unicode.sub(str, num, unicode.len(str))

            str = str .. newLastBuffer
            if unicode.len(str) < sizeX then
                str = str .. string.rep(" ", sizeX - unicode.len(str))
            elseif unicode.len(str) > sizeX then
                str = unicode.sub(str, 1, sizeX)
            end
            ]]

            --local newstr = {}
            --[[
            local cursorPos
            for i = 1, unicode.len(str) do
                if unicode.sub(str, i, i) == "\0" then
                    cursorPos = i
                else
                    table.insert(newstr, unicode.sub(str, i, i))
                end
            end
            ]]


            local chars = {}
            for i = 1, unicode.len(str) do
                table.insert(chars, {unicode.sub(str, i, i), getForeCol(i, foreground), getBackCol(i)})
            end
            if syntax == "lua" then
                for index, value in ipairs(require("syntaxHighlighting").parse(str)) do
                    for i = 1, unicode.len(value[3]) do
                        chars[value[5] + (i - 1)] = {unicode.sub(value[3], i, i), getForeCol(i, value[4]), getBackCol(value[5] + (i - 1))}
                    end
                end
            end

            if hidden then
                for i, data in ipairs(chars) do
                    data[1] = "*"
                end
            end

            if cursorPos then
                local cursorChar = {"|", getForeCol(cursorPos, cursorColor), getBackCol(cursorPos)}
                if not pcall(table.insert, chars, cursorPos, cursorChar) then
                    table.insert(chars, cursorChar)
                end
            end

            -- draw
            local xpos = (self.x + (x - 1)) + offsetX
            local ypos = (self.y + (y - 1)) + offsetY

            gpu.setForeground(foreground, self.isPal)
            gpu.setBackground(background, self.isPal)
            gpu.fill(xpos, ypos, sizeX, sizeY, " ")
            if oldX then
                gpu.set(oldX, y, preStr)
            end

            if chars[1] then
                local oldFore = chars[1][2]
                local oldBack = chars[1][3]
                local buff = ""

                local addy = 0
                for index, value in ipairs(chars) do
                    local newy = ypos + addy + offsetY

                    if oldFore ~= value[2] or oldBack ~= value[3] or ypos ~= newy then
                        local str = {}
                        for i = 1, unicode.len(buff) do
                            if unicode.sub(buff, i, i) == "\n" then
                                addy = addy + 1
                                break
                            else
                                table.insert(str, unicode.sub(buff, i, i))
                            end
                        end
                        str = table.concat(str)

                        local lmax = xpos + (unicode.len(str) - 1)
                        if lmax > maxX then
                            str = unicode.sub(str, 1, constrain(unicode.len(str) - (lmax - maxX), 0, math.huge))
                        end

                        if ypos <= maxY then
                            gpu.setForeground(oldFore, self.isPal)
                            gpu.setBackground(oldBack, self.isPal)
                            gpu.set(xpos, ypos, str)
                        end

                        buff = ""
                        xpos = self.x + ((x + index) - 2) + offsetX
                        ypos = newy
                        oldFore = value[2]
                        oldBack = value[3]
                    end
                    buff = buff .. value[1]
                end

                local lmax = xpos + (unicode.len(buff) - 1)
                if lmax > maxX then
                    buff = unicode.sub(buff, 1, constrain(unicode.len(buff) - (lmax - maxX), 0, math.huge))
                end
                if ypos <= maxY then
                    gpu.setForeground(oldFore, self.isPal)
                    gpu.setBackground(oldBack, self.isPal)
                    gpu.set(xpos, ypos, buff)
                end
            end
        end    
    end
    redraw()

    local function isEmpty(str)
        for i = 1, unicode.len(str) do
            if unicode.sub(str, i, i) ~= " " then
                return false
            end
        end
        return true
    end

    local function addToHistory(newBuff)
        if not disHistory and graphic.inputHistory[1] ~= newBuff and not isEmpty(newBuff) then
            table.insert(graphic.inputHistory, 1, newBuff)
            while #graphic.inputHistory > 64 do
                table.remove(graphic.inputHistory, #graphic.inputHistory)
            end
        end
    end

    local function removeSelect()
        selectFrom = nil
        selectTo = nil
    end

    local function removeSelectedContent()
        if selectFrom then
            local newbuff = buffer .. lastBuffer
            local removed = unicode.sub(newbuff, selectFrom, selectTo)
            buffer = unicode.sub(newbuff, 1, selectFrom - 1)
            lastBuffer = unicode.sub(newbuff, selectTo + 1, unicode.len(buffer))
            removeSelect()
            return removed
        end
    end

    local function add(inputStr)
        historyIndex = nil
        removeSelectedContent()
        for i = 1, unicode.len(inputStr) do
            local chr = unicode.sub(inputStr, i, i)
            if not unicode.isWide(chr) then
                buffer = buffer .. chr
            end
        end
        redraw()
    end

    local function clipboard(inputStr)
        if not disHistory and inputStr then --при отключенной истории вставка не работает
            add(inputStr)

            for i = 1, unicode.len(buffer) do
                if not isMultiline and unicode.sub(buffer, i, i) == "\n" then --да в таком случаи содержимое lastBuffer не вернеться
                    addToHistory(unicode.sub(buffer, 1, i - 1))
                    return buffer
                end
            end
        end
    end

    return {uploadEvent = function(eventData)
        --вызывайте функцию и передавайте туда эвенты которые сами читаете, 
        --если функция чтото вернет, это результат, если он TRUE(не false) значет было нажато ctrl+w
        if allowUse then
            local ok
            for i, v in ipairs(keyboards) do
                if eventData[2] == v then
                    ok = true
                    break
                end
            end
            if ok and self.selected then
                if eventData[1] == "key_down" then
                    if eventData[4] == 28 then
                        historyIndex = nil

                        if isMultiline then
                            buffer = buffer .. "\n"
                        else
                            local newBuff = buffer .. lastBuffer
                            removeSelect()
                            addToHistory(newBuff)
                            return newBuff
                        end
                    elseif eventData[4] == 200 then --up
                        if not disHistory then
                            historyIndex = (historyIndex or 0) + 1
                            if not graphic.inputHistory[historyIndex] then
                                historyIndex = #graphic.inputHistory
                            end
                            if graphic.inputHistory[historyIndex] then
                                buffer = graphic.inputHistory[historyIndex]
                                removeSelect()
                                redraw()
                            else
                                historyIndex = nil
                            end
                        end
                    elseif eventData[4] == 208 then --down
                        if not disHistory and historyIndex then
                            if graphic.inputHistory[historyIndex - 1] then
                                historyIndex = historyIndex - 1
                                buffer = graphic.inputHistory[historyIndex]
                                lastBuffer = ""
                            else
                                historyIndex = nil
                                buffer = ""
                                lastBuffer = ""
                            end
                            removeSelect()
                            redraw()
                        end
                    elseif eventData[4] == 203 then -- <
                        if selectFrom then
                            lastBuffer = removeSelectedContent()
                        elseif unicode.len(buffer) > 0 then
                            lastBuffer = unicode.sub(buffer, -1, -1) .. lastBuffer
                            buffer = unicode.sub(buffer, 1, unicode.len(buffer) - 1)
                        end
                        redraw()
                    elseif eventData[4] == 205 then -- >
                        if selectFrom then
                            buffer = removeSelectedContent()
                        elseif unicode.len(lastBuffer) > 0 then
                            buffer = buffer .. unicode.sub(lastBuffer, 1, 1)
                            lastBuffer = unicode.sub(lastBuffer, 2, unicode.len(lastBuffer))
                        end
                        redraw()
                    elseif eventData[4] == 14 then --backspace
                        historyIndex = nil

                        if selectFrom then
                            removeSelectedContent()
                        elseif unicode.len(buffer) > 0 then
                            buffer = unicode.sub(buffer, 1, unicode.len(buffer) - 1)
                            removeSelect()
                        end
                        redraw()
                    elseif eventData[3] == 23 and eventData[4] == 17 then --ctrl+w
                        historyIndex = nil
                        removeSelect()
                        return true --exit ctrl+w
                    elseif eventData[3] == 1 and eventData[4] == 30 then --ctrl+a
                        buffer = buffer .. lastBuffer
                        lastBuffer = ""
                        selectFrom = 1
                        selectTo = #buffer
                        redraw()
                    elseif eventData[3] == 3 and eventData[4] == 46 then --ctrl+c
                        if selectFrom then
                            cache.copiedText = unicode.sub(buffer .. lastBuffer, selectFrom, selectTo)
                            redraw()
                        end
                    elseif eventData[3] == 24 and eventData[4] == 45 then --ctrl+x
                        if selectFrom then
                            cache.copiedText = removeSelectedContent()
                            redraw()
                        end
                    elseif eventData[3] == 22 and eventData[4] == 47 then --вставка с игравого clipboard
                        local str = clipboard(cache.copiedText)
                        if str then return end
                    elseif eventData[4] == 211 then  --del
                        historyIndex = nil

                        if selectFrom then
                            removeSelectedContent()
                            redraw()
                        elseif unicode.len(lastBuffer) > 0 then
                            lastBuffer = unicode.sub(lastBuffer, 2, unicode.len(lastBuffer))
                            removeSelect()
                            redraw()
                        end
                    elseif eventData[4] == 15 then --tab
                        add("  ")
                    elseif eventData[3] > 0 then --any char
                        historyIndex = nil
                        local char = unicode.char(eventData[3])
                        if not unicode.isWide(char) then
                            add(char)
                        end
                    end
                elseif eventData[1] == "clipboard" then --вставка с реального clipboard
                    local str = clipboard(eventData[3])
                    if str then return end
                end
            end
        end

        if clickCheck then
            if eventData[1] == "touch" and eventData[2] == self.screen and eventData[5] == 0 then
                if eventData[3] >= x and eventData[3] < x + sizeX and eventData[4] == y then
                    allowUse = true
                    redraw()
                else
                    allowUse = false
                    redraw()
                end
            end
        end
    end, redraw = redraw, getBuffer = function()
        return buffer .. lastBuffer
    end, setBuffer = function(v)
        buffer = v
        lastBuffer = ""
    end, setAllowUse = function(state)
        allowUse = state
    end}
end

function graphic.createWindow(screen, x, y, sizeX, sizeY, selected, isPal)
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
        get = get,
        fill = fill,
        copy = copy,
        clear = clear,
        uploadEvent = uploadEvent,
        write = write,
        getCursor = getCursor,
        setCursor = setCursor,
        isPal = isPal or false,
    }

    if selected ~= nil then
        obj.selected = selected
    else
        local gpu = graphic.findGpu(screen)
        obj.selected = gpu and gpu.getDepth() == 1
    end

    if obj.selected then
        for i, window in ipairs(graphic.windows) do
            window.selected = false
        end
    end

    table.insert(graphic.windows, obj)
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
            if not graphic.gpuPrivateList[address] and (deep or component.invoke(address, "getScreen") == screen) then
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

        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            if not graphic.screensBuffers[screen] then
                gpu.setActiveBuffer(0)
                graphic.screensBuffers[screen] = gpu.allocateBuffer(gpu.getResolution())
            end

            gpu.setActiveBuffer(graphic.screensBuffers[screen])
        else
            if gpu.setActiveBuffer then
                gpu.setActiveBuffer(0)
            end
        end

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

do
    local gpu = component.proxy(component.list("gpu")() or "")

    if gpu and gpu.setActiveBuffer then
        event.timer(0.1, function()
            graphic.forceUpdate()
        end, math.huge)
    end
end

function graphic.forceUpdate()
    if not graphic.allowBuffer then return end
    if graphic.globalUpdated then
        for address, ctype in component.list("screen") do
            if graphic.isBufferAllow(address) then
                if graphic.updated[address] then
                    graphic.updated[address] = nil
                    graphic.findGpu(address).bitblt()
                end
            end
        end
        graphic.globalUpdated = false
    end
end

function graphic.getResolution(screen)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.getResolution()
    end
end

function graphic.maxResolution(screen)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.maxResolution()
    end
end

function graphic.setResolution(screen, x, y)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            local activeBuffer = gpu.getActiveBuffer()

            local palette
            if gpu.getDepth() > 1 then
                palette = {}
                for i = 0, 15 do
                    table.insert(palette, graphic.getPaletteColor(screen, i) or 0)
                end
                gpu.setActiveBuffer(activeBuffer) --graphic.getPaletteColor ставит нулевой буфер, и нада вернуть на место
            end
            
            local newBuffer = gpu.allocateBuffer(x, y)
            if newBuffer then
                graphic.screensBuffers[screen] = newBuffer

                gpu.bitblt(newBuffer, nil, nil, nil, nil, activeBuffer)
                gpu.freeBuffer(activeBuffer)

                if palette then
                    gpu.setActiveBuffer(newBuffer)
                    for i, color in ipairs(palette) do
                        gpu.setPaletteColor(i - 1, color)
                    end
                    
                    gpu.setActiveBuffer(0)
                    for i, color in ipairs(palette) do
                        gpu.setPaletteColor(i - 1, color)
                    end
                else
                    gpu.setActiveBuffer(0)
                end
            else
                graphic.screensBuffers[screen] = nil
            end
        end
        return gpu.setResolution(x, y)
    end
end

function graphic.setPaletteColor(screen, i, v)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(graphic.screensBuffers[screen])
            gpu.setPaletteColor(i, v)
            gpu.setActiveBuffer(0)
        end
        return gpu.setPaletteColor(i, v)
    end
end

function graphic.getPaletteColor(screen, i)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.getPaletteColor(i)
    end
end

function graphic.getDepth(screen)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.getDepth()
    end
end

function graphic.setDepth(screen, v)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.setDepth(v)
    end
end

function graphic.maxDepth(screen)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.maxDepth()
    end
end

function graphic.getViewport(screen)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.getViewport()
    end
end

function graphic.setViewport(screen, x, y)
    local gpu = graphic.findGpu(screen)
    if gpu then
        if gpu.setActiveBuffer and graphic.isBufferAllow(screen) then
            gpu.setActiveBuffer(0)
        end
        return gpu.setViewport(x, y)
    end
end

function graphic.update(screen)
    graphic.globalUpdated = true
    graphic.updated[screen] = true
end

function graphic.setAllowBuffer(state)
    if not state then
        for address, ctype in component.list("gpu") do
            component.invoke(address, "setActiveBuffer", 0)
        end
    end
    graphic.allowBuffer = state
end

function graphic.isBufferAvailable()
    local gpu = component.proxy(component.list("gpu")() or "")
    if gpu then
        return not not gpu.setActiveBuffer
    end
    return false
end

function graphic.isBufferAllow(screen)
    return graphic.allowBuffer and not graphic.disableBuffers[screen]
end

function graphic.setBufferStateOnScreen(screen, state)
    graphic.disableBuffers[screen] = not state
    if not state then
        local gpu = graphic.findGpu(screen)
        if gpu then
            gpu.setActiveBuffer(0)
        end
    end
end

function graphic.getBufferStateOnScreen(screen)
    return not graphic.disableBuffers[screen]
end

return graphic