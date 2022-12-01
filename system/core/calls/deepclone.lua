local cache = {}
local function recurse(tbl, newtbl)
    local newtbl = newtbl or {}

    for k, v in pairs(tbl) do
        if type(v) == "table" then
            local ltbl = cache[v]
            if not ltbl then
                cache[v] = {}
                ltbl = cache[v]
                recurse(v, cache[v])
            end
            newtbl[k] = ltbl
        else
            newtbl[k] = v
        end
    end

    return newtbl
end

return recurse(...)