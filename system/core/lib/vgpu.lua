local unicode = require("unicode")
local graphic = require("graphic")
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
    --local currentBackgroundsPal = {}
    --local currentForegroundsPal = {}
    local currentChars = {}

    local backgrounds = {}
    local foregrounds = {}
    --local backgroundsPal = {}
    --local foregroundsPal = {}
    local chars = {}

    local currentBack, currentBackPal = gpu.getBackground()
    local currentFore, currentForePal = gpu.getForeground()
    local rx, ry = gpu.getResolution()
    local rsmax = (rx - 1) + ((ry - 1) * rx)
    local origCurrentBack, origCurrentFore = currentBack, currentFore

    local concat = table.concat

    for i = 0, rsmax do
        backgrounds[i] = 0
        currentBackgrounds[i] = 0

        foregrounds[i] = 0xffffff
        currentForegrounds[i] = 0xffffff

        --backgroundsPal[i] = false
        --currentBackgroundsPal[i] = false

        --foregroundsPal[i] = false
        --currentForegroundsPal[i] = false

        chars[i] = " "
        currentChars[i] = " "
    end

    for key, value in pairs(gpu) do
        obj[key] = value
    end

    function obj.getBackground()
        return origCurrentBack, currentBackPal
    end

    function obj.getForeground()
        return origCurrentFore, currentForePal
    end

    function obj.setBackground(col, isPal)
        --checkArg(1, col, "number")
        --checkArg(2, isPal, "boolean", "nil")

        local old = currentBack
        local oldPal = currentBackPal
        if isPal then
            currentBack = gpu.getPaletteColor(col)
        else
            currentBack = col
        end
        origCurrentBack = col
        currentBackPal = not not isPal
        return old, oldPal
    end

    function obj.setForeground(col, isPal)
        --checkArg(1, col, "number")
        --checkArg(2, isPal, "boolean", "nil")
        
        local old = currentFore
        local oldPal = currentForePal
        if isPal then
            currentFore = gpu.getPaletteColor(col)
        else
            currentFore = col
        end
        origCurrentFore = col
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
        local currentBack, _, currentFore, _, text = graphic._formatColor(gpu, currentBack, currentBackPal, currentFore, currentForePal, text, true)
        x = math.floor(x)
        y = math.floor(y)

        for i = 1, unicode.len(text) do
            if x + (i - 1) > rx then break end
            local index = ((x + (i - 1)) - 1) + ((y - 1) * rx)
            backgrounds[index] = currentBack
            foregrounds[index] = currentFore
            --backgroundsPal[index] = currentBackPal
            --foregroundsPal[index] = currentForePal
            chars[index] = unicode.sub(text, i, i)
        end

        updated = true
    end

    function obj.fill(x, y, sizeX, sizeY, char)
        local currentBack, _, currentFore, _, char = graphic._formatColor(gpu, currentBack, currentBackPal, currentFore, currentForePal, char, true)
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
                --backgroundsPal[index] = currentBackPal
                --foregroundsPal[index] = currentForePal
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
        local newB, newF, newC = {}, {}, {}
        --local newBP, newFP = {}, {}
        for ix = x, x + (sx - 1) do 
            for iy = y, y + (sy - 1) do
                local index = (ix - 1) + ((iy - 1) * rx)
                local newindex = ((ix + ox) - 1) + (((iy + oy) - 1) * rx)

                newB[newindex] = backgrounds[index]
                newF[newindex] = foregrounds[index]
                --newBP[newindex] = backgroundsPal[index]
                --newFP[newindex] = foregroundsPal[index]
                newC[newindex] = chars[index]
            end
        end

        for newindex in pairs(newC) do
            backgrounds[newindex] = newB[newindex]
            foregrounds[newindex] = newF[newindex]
            --backgroundsPal[newindex] = newBP[newindex]
            --foregroundsPal[newindex] = newFP[newindex]
            chars[newindex] = newC[newindex]
            
            currentBackgrounds[newindex] = newB[newindex] --чтобы это не требовалось перерисовывать(так как этот метод применяет изображения сразу)
            currentForegrounds[newindex] = newF[newindex]
            --currentBackgroundsPal[newindex] = newBP[newindex]
            --currentForegroundsPal[newindex] = newFP[newindex]
            currentChars[newindex] = newC[newindex]
        end
    end

    function obj.update()
        if updated then
            init()

            local index, buff, buffI, back, fore
            local i = 0
            --local backPal, forePal
            while i <= rsmax do
                if backgrounds[i] and (
                    backgrounds[i] ~= currentBackgrounds[i] or
                    foregrounds[i] ~= currentForegrounds[i] or
                    --backgroundsPal[i] ~= currentBackgroundsPal[i] or
                    --foregroundsPal[i] ~= currentForegroundsPal[i] or
                    chars[i] ~= currentChars[i] or
                    (i + 1) % rx == 0) then
                    buff = {}
                    buffI = 1
                    back = backgrounds[i]
                    fore = foregrounds[i]
                    --backPal = backgroundsPal[i]
                    --forePal = foregroundsPal[i]
                    index = i
                    while true do
                        buff[buffI] = chars[i]
                        buffI = buffI + 1
                        if back == backgrounds[i + 1] and fore == foregrounds[i + 1] and
                        --backPal == backgroundsPal[i + 1] and forePal == foregroundsPal[i + 1] and
                        (i + 1) % rx ~= 0 then
                            currentBackgrounds[i] = backgrounds[i]
                            currentForegrounds[i] = foregrounds[i]
                            --currentBackgroundsPal[i] = backgroundsPal[i]
                            --currentForegroundsPal[i] = foregroundsPal[i]
                            currentChars[i] = chars[i]
                            i = i + 1
                        else
                            break
                        end
                    end
                    --gpu.setBackground(back, backPal)
                    --gpu.setForeground(fore, forePal)
                    gpu.setBackground(back)
                    gpu.setForeground(fore)
                    gpu.set((index % rx) + 1, (index // rx) + 1, concat(buff))
                end

                currentBackgrounds[i] = backgrounds[i]
                currentForegrounds[i] = foregrounds[i]
                --currentBackgroundsPal[i] = backgroundsPal[i]
                --currentForegroundsPal[i] = foregroundsPal[i]
                currentChars[i] = chars[i]
                i = i + 1
            end

            updated = false
        end
    end

    return obj
end

function vgpu.createStub(gpu)
    local obj = {}
    for key, value in pairs(gpu) do
        obj[key] = value
    end

    local back, backPal = gpu.getBackground()
    local fore, forePal = gpu.getForeground()
    local bgUpdated, fgUpdated = false, false

    function obj.getBackground()
        return back, backPal
    end

    function obj.getForeground()
        return fore, forePal
    end

    function obj.setBackground(col, pal)
        bgUpdated = true
        local old, oldPal = fore, forePal
        back, backPal = col, pal
        return old, oldPal
    end

    function obj.setForeground(col, pal)
        fgUpdated = true
        local old, oldPal = fore, forePal
        fore, forePal = col, pal
        return old, oldPal
    end

    function obj.set(x, y, text)
        local newBack, newBackPal, newFore, newForePal, text = graphic._formatColor(gpu, back, backPal, fore, forePal, text)
        if bgUpdated then
            gpu.setBackground(newBack, newBackPal)
            gpu.setForeground(newFore, newForePal)
        end
        gpu.set(x, y, text)
    end

    function obj.fill(x, y, sx, sy, char)
        local newBack, newBackPal, newFore, newForePal, char = graphic._formatColor(gpu, back, backPal, fore, forePal, char)
        if fgUpdated then
            gpu.setBackground(newBack, newBackPal)
            gpu.setForeground(newFore, newForePal)
        end
        gpu.fill(x, y, sx, sy, char)
    end

    return obj
end

vgpu.unloadable = true
return vgpu