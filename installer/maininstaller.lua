local function getBestGPUOrScreenAddress(componentType) --функцию подарил игорь тимофеев
    local bestWidth, bestAddress = 0

    for address in componentc.list(componentType) do
        local width = tonumber(deviceinfo[address].width)
        if component.type(componentType) == "screen" then
            if #component.invoke(address, "getKeyboards") > 0 then --экраны с кравиатурами имеют больший приоритет
                width = width + 10
            end
        end

        if width > bestWidth then
            bestAddress, bestWidth = address, width
        end
    end

    return bestAddress
end

local gpu = component.proxy((computer.getBootGpu and computer.getBootGpu() or getBestGPUOrScreenAddress("gpu")) or error("no gpu found", 0))
local screen = (computer.getBootScreen and computer.getBootScreen() or getBestGPUOrScreenAddress("screen")) or error("no screen found", 0)
gpu.bind(screen)
local keyboards = component.invoke(screen, "getKeyboards")
local rx, ry = gpu.getResolution()
local depth = gpu.getDepth()

local drive = component.proxy(computer.getBootAddress())

------------------------------------

local function segments(path)
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

local function canonical(path)
    local result = table.concat(segments(path), "/")
    if unicode.sub(path, 1, 1) == "/" then
        return "/" .. result
    else
        return result
    end
end

local function fs_path(path)
    local parts = segments(path)
    local result = table.concat(parts, "/", 1, #parts - 1) .. "/"
    if unicode.sub(path, 1, 1) == "/" and unicode.sub(result, 1, 1) ~= "/" then
        return canonical("/" .. result)
    else
        return canonical(result)
    end
end

local function cloneTo(folder, targetDrive)
    local function recurse(path)
        for _, lpath in ipairs(drive.list(path) or {}) do
            local full_path = path

            if drive.isDirectory(full_path) then
                recurse(full_path)
            else
                local file = drive.open(full_path, "rb")
                local buffer = ""
                repeat
                    local data = drive.read(file, math.huge)
                    buffer = buffer .. (data or "")
                until not buffer
                drive.close(file)

                targetDrive.makeDirectory(fs_path(full_path))
                local file = targetDrive.open(full_path, "wb")
                targetDrive.write(file, buffer)
                targetDrive.close(file)
            end
        end
    end
    recurse(folder)
end

------------------------------------

local function isValideKeyboard(address)
    for i, v in ipairs(keyboards) do
        if v == address then
            return true
        end
    end
end

------------------------------------

local function invert()
    gpu.setBackground(gpu.setForeground(gpu.getBackground()))
end

local function setText(str, posX, posY)
    gpu.set((posX or 0) + math.floor(rx / 2 - ((#str - 1) / 2) + .5), posY or math.floor(ry / 2 + .5), str)
end

local function menu(label, strs, funcs, selected)
    local selected = selected or 1
    local function redraw()
        invert()
        setText(label, nil, 1)
        invert()
        for i, v in ipairs(strs) do
            if selected == i then invert() end
            setText(v, nil, i + 1)
            if selected == i then invert() end
        end
    end
    while true do
        
    end
end