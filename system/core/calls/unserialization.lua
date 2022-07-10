local data = ...

checkArg(1, data, "string")
local result, reason = load("return " .. data, "=data", nil, {math={huge=math.huge}})
if not result then
    return nil, reason
end
local ok, output = pcall(result)
if not ok then
    return nil, output
end
return output