local graphic = require("graphic")
local screen, x, y, sx, sy = ...
local gpu = graphic.findGpu(screen)

local tbl = {}
for cy = y, y + (sy - 1) do
    for cx = x, x + (sx - 1) do
        local ok, data1, data2, data3 = pcall(gpu.get, cx, cy)
        if ok then
            table.insert(tbl, {cx, cy, {data1, data2, data3}})
        else
            table.insert(tbl, {cx, cy, {" ", 0, 0}})
        end
    end
end

return function()
    local gpu = graphic.findGpu(screen)
    graphic.update(screen)

    local oldFore, oldBack, oldX, oldY = tbl[1][3][2], tbl[1][3][3], tbl[1][1], tbl[1][2]
    local buff = ""
    for i, v in ipairs(tbl) do
        local fore, back, char = v[3][2], v[3][3], v[3][1]
        if fore ~= oldFore or back ~= oldBack or oldY ~= v[2] then
            gpu.setForeground(oldFore)
            gpu.setBackground(oldBack)
            gpu.set(oldX, oldY, buff)

            oldFore = fore
            oldBack = back
            oldX = v[1]
            oldY = v[2]
            buff = char
        else
            buff = buff .. char
        end
    end

    gpu.setForeground(oldFore)
    gpu.setBackground(oldBack)
    gpu.set(oldX, oldY, buff)
end