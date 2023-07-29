local unicode = require("unicode")

local function toParts(str, max)
    local strs = {}
    while unicode.wlen(str) > 0 do
        table.insert(strs, unicode.sub(str, 1, max))
        str = unicode.sub(str, unicode.wlen(strs[#strs]) + 1)
    end
    return strs
end
return toParts(...)