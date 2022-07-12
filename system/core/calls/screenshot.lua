local graphic = require("graphic")
local screen, x, y, sx, sy = ...
local gpu = graphic.findGpu(screen)

local tbl = {}
for cx = x, x + (sx - 1) do
    for cy = y, y + (sy - 1) do
        local ok, data1, data2, data3 = pcall(gpu.get, cx, cy)
        if ok then
            table.insert(tbl, {cx, cy, {data1, data2, data3}})
        end
    end
end

return function()
    local gpu = graphic.findGpu(screen)
    for i, v in ipairs(tbl) do
        gpu.setForeground(v[3][2])
        gpu.setBackground(v[3][3])
        gpu.set(v[1], v[2], v[3][1])
    end
end