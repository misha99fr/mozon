local paths = {}

function paths.segments(path)
    local parts = {}
    for part in path:gmatch("[^\\/]+") do
        local current, up = part:find("^%.?%.$")
        if current then
            if up == 2 then
                table.remove(parts)
            end
        else
            table.insert(parts, part)
        end
    end
    return parts
end

function paths.concat(...)
    local set = table.pack(...)
    for index, value in ipairs(set) do
      checkArg(index, value, "string")
    end
    return paths.canonical(table.concat(set, "/"))
end

function paths.xconcat(...) --работает как concat но пути начинаюшиеся со / НЕ обрабатываються как отновительные а откидывают путь в начало
    local set = table.pack(...)
    for index, value in ipairs(set) do
        checkArg(index, value, "string")
    end
    for index, value in ipairs(set) do
        if value:sub(1, 1) == "/" and index > 1 then
            local newset = {}
            for i = index, #set do
                table.insert(newset, set[i])
            end
            return paths.xconcat(table.unpack(newset))
        end
    end
    return paths.canonical(table.concat(set, "/"))
end

function paths.sconcat(main, ...) --работает так же как concat но если итоговый путь не указывает на целевой обьект первого путя то вернет false
    main = paths.canonical(main)
    local path = paths.concat(main, ...)
    if unicode.sub(path, 1, unicode.len(main)) == main then
        return path
    end
    return false
end

function paths.canonical(path)
    local result = table.concat(paths.segments(path), "/")
    if unicode.sub(path, 1, 1) == "/" then
        return "/" .. result
    else
        return result
    end
end

function paths.path(path)
    local parts = paths.segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return "/" .. result
    else
        return result
    end
end
  
function paths.name(path)
    checkArg(1, path, "string")
    local parts = paths.segments(path)
    return parts[#parts]
end

--из mineOS от игоря тимофеева https://github.com/IgorTimofeev/MineOS
function paths.path(path)
	return path:match("^(.+%/).") or "/"
end

function paths.name(path)
	return path:match("%/?([^%/]+%/?)$")
end

function paths.extension(path)
	local data = path:match("[^%/]+(%.[^%/]+)%/?$")
    if data then
        return unicode.sub(data, 2, unicode.len(data))
    end
    return nil
end

function paths.hideExtension(path)
	return path:match("(.+)%..+") or path
end

function paths.isHidden(path)
	return path:sub(1, 1)
end

function paths.removeSlashes(path)
	return path:gsub("/+", "/")
end

return paths