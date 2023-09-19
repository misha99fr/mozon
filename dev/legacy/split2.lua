local function split(tool, str, seps)
    local parts = {""}

    local index = 1
    local strlen = tool.len(str)
    while index <= strlen do
        while true do
            local isBreak
            for i, sep in ipairs(seps) do
                if tool.sub(str, index, index + (tool.len(sep) - 1)) == sep then
                    table.insert(parts, "")
                    index = index + tool.len(sep)
                    isBreak = true
                    break
                end
            end
            if not isBreak then break end
        end

        parts[#parts] = parts[#parts] .. tool.sub(str, index, index)
        index = index + 1
    end

    return parts
end

return split(...)