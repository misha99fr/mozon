local function toParts(str, max)
    local strs = {}
    while #str > 0 do
        table.insert(strs, str:sub(1, max))
        str = str:sub(#strs[#strs] + 1)
    end
    return strs
end
return toParts(...)