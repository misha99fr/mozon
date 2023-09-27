local unicode = require("unicode")
local vgpu = {}

function vgpu.create(gpu, screen)
    local obj = {}
    
    local function init()
        if gpu.getScreen() ~= screen then
            gpu.bind(screen, false)
        end
        if gpu.setActiveBuffer and gpu.getActiveBuffer() ~= 0 then
            gpu.setActiveBuffer(0)
        end
    end
    init()

    local updated = false

    local currentBackgrounds = {}
    local currentForegrounds = {}
    local currentBackgroundsPal = {}
    local currentForegroundsPal = {}
    local currentChars = {}

    local backgrounds = {}
    local foregrounds = {}
    local backgroundsPal = {}
    local foregroundsPal = {}
    local chars = {}

    local currentBack, currentBackPal = gpu.getBackground()
    local currentFore, currentForePal = gpu.getForeground()
    local rx, ry = gpu.getResolution()
    local rsmax = (rx - 1) + ((ry - 1) * rx)

    local concat = table.concat

    for i = 0, rsmax do
        backgrounds[i] = 0
        currentBackgrounds[i] = 0

        foregrounds[i] = 0xffffff
        currentForegrounds[i] = 0xffffff

        backgroundsPal[i] = false
        currentBackgroundsPal[i] = false

        foregroundsPal[i] = false
        currentForegroundsPal[i] = false

        chars[i] = " "
        currentChars[i] = " "
    end

    for key, value in pairs(gpu) do
        obj[key] = value
    end

    function obj.getBackground()
        return currentBack, currentBackPal
    end

    function obj.getForeground()
        return currentFore, currentForePal
    end

    function obj.setBackground(col, isPal)
        local old = currentBack
        local oldPal = currentBackPal
        currentBack = col
        currentBackPal = not not isPal
        return old, oldPal
    end

    function obj.setForeground(col, isPal)
        local old = currentFore
        local oldPal = currentForePal
        currentFore = col
        currentForePal = not not isPal
        return old, oldPal
    end

    function obj.getResolution()
        return rx, ry
    end

    function obj.setResolution(x, y)
        x = math.floor(x)
        y = math.floor(y)
        init()

        gpu.setResolution(x, y)
        rx, ry = x, y
        rsmax = (rx - 1) + ((ry - 1) * rx)
    end

    function obj.get(x, y)
        x = math.floor(x)
        y = math.floor(y)

        local index = (x - 1) + ((y - 1) * rx)
        return chars[index], foregrounds[index], backgrounds[index]
    end

    function obj.set(x, y, text)
        x = math.floor(x)
        y = math.floor(y)

        for i = 1, unicode.len(text) do
            if x + (i - 1) > rx then break end
            local index = ((x + (i - 1)) - 1) + ((y - 1) * rx)
            backgrounds[index] = currentBack
            foregrounds[index] = currentFore
            backgroundsPal[index] = currentBackPal
            foregroundsPal[index] = currentForePal
            chars[index] = unicode.sub(text, i, i)
        end

        updated = true
    end

    function obj.fill(x, y, sizeX, sizeY, char)
        x = math.floor(x)
        y = math.floor(y)
        sizeX = math.floor(sizeX)
        sizeY = math.floor(sizeY)

        --[[
        --фактически делаем заливка
        gpu.setBackground(currentBack)
        gpu.setForeground(currentFore)
        gpu.fill(x, y, sizeX, sizeY, char)

        for ix = x, x + (sizeX - 1) do
            for iy = y, y + (sizeY - 1) do
                local index = (ix - 1) + ((iy - 1) * rx)

                backgrounds[index] = currentBack
                foregrounds[index] = currentFore
                chars[index] = char

                currentBackgrounds[index] = currentBack --чтобы это не требовалось перерисовывать(так как этот метод применяет изображения сразу)
                currentForegrounds[index] = currentFore
                currentChars[index] = char
            end
        end
        ]]
        
        for ix = x, x + (sizeX - 1) do
            for iy = y, y + (sizeY - 1) do
                local index = (ix - 1) + ((iy - 1) * rx)
                backgrounds[index] = currentBack
                foregrounds[index] = currentFore
                backgroundsPal[index] = currentBackPal
                foregroundsPal[index] = currentForePal
                chars[index] = char
            end
        end

        updated = true
    end

    function obj.copy(x, y, sx, sy, ox, oy)
        x = math.floor(x)
        y = math.floor(y)
        sx = math.floor(sx)
        sy = math.floor(sy)
        ox = math.floor(ox)
        oy = math.floor(oy)

        --обновляем картинку на экране
        if updated then
            obj.update()
        else
            init()
        end

        --фактически копируем картинку
        gpu.copy(x, y, sx, sy, ox, oy)

        --капируем картинку в буфере
        local newB, newF, newBP, newFP, newC = {}, {}, {}, {}, {}
        for ix = x, x + (sx - 1) do 
            for iy = y, y + (sy - 1) do
                local index = (ix - 1) + ((iy - 1) * rx)
                local newindex = ((ix + ox) - 1) + (((iy + oy) - 1) * rx)

                newB[newindex] = backgrounds[index]
                newF[newindex] = foregrounds[index]
                newBP[newindex] = backgroundsPal[index]
                newFP[newindex] = foregroundsPal[index]
                newC[newindex] = chars[index]
            end
        end

        for newindex in pairs(newC) do
            backgrounds[newindex] = newB[newindex]
            foregrounds[newindex] = newF[newindex]
            backgroundsPal[newindex] = newBP[newindex]
            foregroundsPal[newindex] = newFP[newindex]
            chars[newindex] = newC[newindex]
            
            currentBackgrounds[newindex] = newB[newindex] --чтобы это не требовалось перерисовывать(так как этот метод применяет изображения сразу)
            currentForegrounds[newindex] = newF[newindex]
            currentBackgroundsPal[newindex] = newBP[newindex]
            currentForegroundsPal[newindex] = newFP[newindex]
            currentChars[newindex] = newC[newindex]
        end
    end

    function obj.update()
        if updated then
            init()

            local i, index, buff, buffI, back, backPal, fore, forePal = 0
            while i <= rsmax do
                if backgrounds[i] and (
                    backgrounds[i] ~= currentBackgrounds[i] or
                    foregrounds[i] ~= currentForegrounds[i] or
                    backgroundsPal[i] ~= currentBackgroundsPal[i] or
                    foregroundsPal[i] ~= currentForegroundsPal[i] or
                    chars[i] ~= currentChars[i] or
                    (i + 1) % rx == 0) then
                    buff = {}
                    buffI = 1
                    back, backPal = backgrounds[i], backgroundsPal[i]
                    fore, forePal = foregrounds[i], foregroundsPal[i]
                    index = i
                    while true do
                        buff[buffI] = chars[i]
                        buffI = buffI + 1
                        if back == backgrounds[i + 1] and fore == foregrounds[i + 1] and
                        backPal == backgroundsPal[i + 1] and forePal == foregroundsPal[i + 1] and
                        (i + 1) % rx ~= 0 then
                            currentBackgrounds[i] = backgrounds[i]
                            currentForegrounds[i] = foregrounds[i]
                            currentBackgroundsPal[i] = backgroundsPal[i]
                            currentForegroundsPal[i] = foregroundsPal[i]
                            currentChars[i] = chars[i]
                            i = i + 1
                        else
                            break
                        end
                    end
                    gpu.setBackground(back, backPal)
                    gpu.setForeground(fore, forePal)
                    gpu.set((index % rx) + 1, (index // rx) + 1, concat(buff))
                end

                currentBackgrounds[i] = backgrounds[i]
                currentForegrounds[i] = foregrounds[i]
                currentBackgroundsPal[i] = backgroundsPal[i]
                currentForegroundsPal[i] = foregroundsPal[i]
                currentChars[i] = chars[i]
                i = i + 1
            end

            updated = false
        end
    end

    return obj
end

vgpu.unloadable = true
return vgpu