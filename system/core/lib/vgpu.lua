local unicode = require("unicode")
local vgpu = {}

function vgpu.create(gpu)
    local obj = {}
    
    local updated = false

    local currentBackgrounds = {}
    local currentForegrounds = {}
    local currentChars = {}

    local backgrounds = {}
    local foregrounds = {}
    local chars = {}

    local currentBack = gpu.getBackground()
    local currentFore = gpu.getForeground()
    local rx, ry = gpu.getResolution()
    local rsmax = (rx - 1) + ((ry - 1) * rx)

    local concat = table.concat

    for i = 0, rsmax do
        backgrounds[i] = 0
        currentBackgrounds[i] = 0
        foregrounds[i] = 0xffffff
        currentForegrounds[i] = 0xffffff
        chars[i] = " "
        currentChars[i] = " "
    end

    for key, value in pairs(gpu) do
        obj[key] = value
    end

    function obj.getBackground()
        return currentBack
    end

    function obj.getForeground()
        return currentFore
    end

    function obj.setBackground(col, isPal)
        if isPal then
            local old = currentBack
            currentBack = gpu.getPaletteColor(col)
            return old
        else
            local old = currentBack
            currentBack = col
            return old
        end
    end

    function obj.setForeground(col, isPal)
        if isPal then
            local old = currentFore
            currentFore = gpu.getPaletteColor(col)
            return old
        else
            local old = currentFore
            currentFore = col
            return old
        end
    end

    function obj.getResolution()
        return rx, ry
    end

    function obj.setResolution(x, y)
        gpu.setResolution(x, y)
        rx, ry = x, y
        rsmax = (rx - 1) + ((ry - 1) * rx)
    end

    function obj.get(x, y)
        local index = (x - 1) + ((y - 1) * rx)
        return chars[index], foregrounds[index], backgrounds[index]
    end

    function obj.set(x, y, text)
        for i = 1, unicode.len(text) do
            if x + (i - 1) > rx then break end
            local index = ((x + (i - 1)) - 1) + ((y - 1) * rx)
            backgrounds[index] = currentBack
            foregrounds[index] = currentFore
            chars[index] = unicode.sub(text, i, i)
        end
        updated = true
    end

    function obj.fill(x, y, sizeX, sizeY, char)
        for ix = x, x + (sizeX - 1) do
            for iy = y, y + (sizeY - 1) do
                local index = (ix - 1) + ((iy - 1) * rx)
                backgrounds[index] = currentBack
                foregrounds[index] = currentFore
                chars[index] = char
            end
        end
        updated = true
    end

    function obj.update()
        if updated then
            local i = 0
            while i <= rsmax do
                if backgrounds[i] ~= currentBackgrounds[i] or foregrounds[i] ~= currentForegrounds[i] or chars[i] ~= currentChars[i] or (i + 1) % rx == 0 then
                    local buff = {}
                    local buffI = 1
                    local back = backgrounds[i]
                    local fore = foregrounds[i]
                    local index = i
                    while true do
                        buff[buffI] = chars[i]
                        buffI = buffI + 1
                        if back == backgrounds[i + 1] and fore == foregrounds[i + 1] and (i + 1) % rx ~= 0 then
                            currentBackgrounds[i] = backgrounds[i]
                            currentForegrounds[i] = foregrounds[i]
                            currentChars[i] = chars[i]
                            i = i + 1
                        else
                            break
                        end
                    end
                    gpu.setBackground(back)
                    gpu.setForeground(fore)
                    gpu.set((index % rx) + 1, (index // rx) + 1, concat(buff))
                end

                currentBackgrounds[i] = backgrounds[i]
                currentForegrounds[i] = foregrounds[i]
                currentChars[i] = chars[i]
                i = i + 1
            end
        end
    end

    return obj
end

vgpu.unloadable = true
return vgpu