--math
function math.round(number)
    return math.floor(number + 0.5)
end

function math.map(value, low, high, low_2, high_2)
    local relative_value = (value - low) / (high - low)
    local scaled_value = low_2 + (high_2 - low_2) * relative_value
    return scaled_value
end

function math.clamp(value, min, max)
    return math.min(math.max(value, min), max)
end

function math.roundTo(number, numbers)
    numbers = numbers or 3
    return tonumber(string.format("%." .. tostring(math.floor(numbers)) .. "f", number))
end

--table
function table.deepclone(tbl, newtbl)
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

    return recurse(tbl, newtbl)
end

--bit32
function bit32.readbit(byte, index)
    return byte >> index & 1 == 1
end

function bit32.writebit(byte, index, value)
    local current = bit32.readbit(byte, index)

    if current ~= value then
        byte = byte + (2 ^ index)
    end

    return math.floor(byte)
end