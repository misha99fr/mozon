local calls = require("calls")
local readbit = calls.load("readbit")

local values = {
    {
        [0] = 0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    {
        [0] = 255,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        1
    },
    {
        [0] = 1,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    },
    {
        [0] = 2,
        0,
        1,
        0,
        0,
        0,
        0,
        0,
        0
    },
    {
        [0] = 3,
        1,
        1,
        0,
        0,
        0,
        0,
        0,
        0
    },
    {
        [0] = 4,
        0,
        0,
        1,
        0,
        0,
        0,
        0,
        0
    },
    {
        [0] = 5,
        1,
        0,
        1,
        0,
        0,
        0,
        0,
        0
    },
    {
        [0] = 6,
        0,
        1,
        1,
        0,
        0,
        0,
        0,
        0
    },
    {
        [0] = 127,
        1,
        1,
        1,
        1,
        1,
        1,
        1,
        0
    },
}

local okcount, errs = 0, {}
for i, v in ipairs(values) do
    local isErr

    for i = 1, 8 do
        local out = readbit(v[0], i)
        if out ~= v[i] then
            table.insert(errs,
                "value " .. tostring(math.floor(v[0])) .. "\n" ..
                "index " .. tostring(math.floor(i)) .. "\n" ..
                "out " .. tostring(math.floor(out)) .. "\n" ..
                "target " .. tostring(math.floor(v[i])) .. "\n" ..
            )
            isErr = true
        end
    end

    if not isErr then
        okcount = okcount + 1
    end
end

return okcount == #values, table.concat(errs, ", \n")