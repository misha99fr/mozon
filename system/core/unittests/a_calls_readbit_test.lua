local calls = require("calls")
local readbit, err = calls.load("readbit")
if not readbit then
    return false, "failed to load readbit " .. (err or "unknown error")
end
if not pcall(readbit, 0, 2) then
    return false, "failed to run readbit " .. (err or "unknown error")
end

local values = {
    {
        [0] = 0,
        false,
        false,
        false,
        false,
        false,
        false,
        false,
        false
    },
    {
        [0] = 255,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        true
    },
    {
        [0] = 1,
        true,
        false,
        false,
        false,
        false,
        false,
        false,
        false
    },
    {
        [0] = 2,
        false,
        true,
        false,
        false,
        false,
        false,
        false,
        false
    },
    {
        [0] = 3,
        true,
        true,
        false,
        false,
        false,
        false,
        false,
        false
    },
    {
        [0] = 4,
        false,
        false,
        true,
        false,
        false,
        false,
        false,
        false
    },
    {
        [0] = 5,
        true,
        false,
        true,
        false,
        false,
        false,
        false,
        false
    },
    {
        [0] = 6,
        false,
        true,
        true,
        false,
        false,
        false,
        false,
        false
    },
    {
        [0] = 127,
        true,
        true,
        true,
        true,
        true,
        true,
        true,
        false
    },
}

local okcount, errs = 0, {}
for i, v in ipairs(values) do
    local isErr

    for i = 1, 8 do
        local out = readbit(v[0], i - 1)
        if out ~= v[i] then
            table.insert(errs,
                "value " .. tostring(math.floor(v[0])) .. ", \n" ..
                "index " .. tostring(math.floor(i)) .. ", \n" ..
                "out " .. tostring(out) .. ", \n" ..
                "target " .. tostring(v[i])
            )
            isErr = true
        end
    end

    if not isErr then
        okcount = okcount + 1
    end
end

return okcount == #values, table.concat(errs, ", \n\n")