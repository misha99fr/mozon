local graphic = require("graphic")
local screen, x, y, sx, sy = ...
local gpu = graphic.findGpu(screen)

local index = 1
local chars = {}
local fores = {}
local backs = {}
for cy = y, y + (sy - 1) do
    for cx = x, x + (sx - 1) do
        local ok, char, fore, back = pcall(gpu.get, cx, cy)
        if ok then
            chars[index] = char
            fores[index] = fore
            backs[index] = back
        end
        index = index + 1
    end
end

return function()
    local gpu = graphic.findGpu(screen)
    graphic.update(screen)

    local oldFore, oldBack, oldX, oldY = fores[1], backs[1], x, y
    local buff = ""

    local cx, cy = x, y
    for i = 1, index do
        local fore, back, char = fores[i], backs[i], chars[i]

        if char then
            if fore ~= oldFore or back ~= oldBack or oldY ~= cy then
                gpu.setForeground(oldFore)
                gpu.setBackground(oldBack)
                gpu.set(oldX, oldY, buff)

                oldFore = fore
                oldBack = back
                oldX = cx
                oldY = cy
                buff = char
            else
                buff = buff .. char
            end
        end

        cx = cx + 1
        if cx >= x + sx then
            cx = x
            cy = cy + 1
        end
    end

    if oldFore then
        gpu.setForeground(oldFore)
        gpu.setBackground(oldBack)
        gpu.set(oldX, oldY, buff)
    end
end