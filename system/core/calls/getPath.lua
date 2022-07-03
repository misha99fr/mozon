local info

for runLevel = 0, math.huge do
    info = debug.getinfo(runLevel)

    if info then
        if info.what == "main" then
            return info.source:sub(2, -1)
        end
    else
        error("Failed to get debug info for runlevel " .. runLevel)
    end
end