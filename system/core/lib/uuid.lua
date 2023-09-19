local r = math.random
local uuid = {}

function uuid.next()
    return string.format("%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x",
    r(0,255),r(0,255),r(0,255),r(0,255),
    r(0,255),r(0,255),
    r(64,79),r(0,255),
    r(128,191),r(0,255),
    r(0,255),r(0,255),r(0,255),r(0,255),r(0,255),r(0,255))
end

uuid.unloaded = true
return uuid