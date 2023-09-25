local bootloader = bootloader
local component = component
local computer = computer
local unicode = unicode

local screen = ...
local gpu = component.proxy(component.list("gpu")() or "")
if not gpu then return end
bootloader.initScreen(gpu, screen)
local rx, ry = gpu.getResolution()
local centerY = math.floor(ry / 2)
local keyboard = component.invoke(screen, "getKeyboards")[1]

local function invertColor()
    gpu.setBackground(gpu.setForeground(gpu.getBackground()))
end

local function centerPrint(y, text)
    gpu.set(((rx / 2) - (unicode.len(text) / 2)) + 1, y, text)
end

local function screenFill(y)
    gpu.fill(8, y, rx - 15, 1, " ")
end

local function clearScreen()
    gpu.fill(1, 1, rx, ry, " ")
end

local function menu(label, strs, funcs, withoutBackButton)
    local selected = 1

    if not withoutBackButton then
        table.insert(strs, "Back")
    end

    local function redraw()
        clearScreen()
        invertColor()
        centerPrint(2, label)
        invertColor()

        for i, str in ipairs(strs) do
            if i == selected then
                invertColor()
                screenFill(3 + i)
            end
            centerPrint(3 + i, str)
            if i == selected then invertColor() end
        end
    end
    redraw()

    while true do
        local eventData = {computer.pullSignal()}
        if eventData[1] == "key_down" and eventData[2] == keyboard then
            if eventData[4] == 28 then
                if funcs[selected] then
                    if funcs[selected](strs[selected]) then
                        break
                    else
                        redraw()
                    end
                else
                    break
                end
            elseif eventData[4] == 200 then
                selected = selected - 1
                if selected < 1 then
                    selected = 1
                else 
                    redraw()
                end
            elseif eventData[4] == 208 then
                selected = selected + 1
                if selected > #strs then
                    selected = #strs
                else
                    redraw()
                end
            end
        end
    end
end

local function info(text)
    clearScreen()
    centerPrint(centerY, text)
    centerPrint(centerY + 1, "Press Enter To Continue")
    while true do
        local eventData = {computer.pullSignal()}
        if eventData[1] == "key_down" and eventData[2] == keyboard then
            if eventData[4] == 28 then
                break
            end
        end
    end
end

--------------------------------------------------------------

menu(bootloader.coreversion .. " recovery", {
    "Wipe Data / Factory Reset",
}, {function (str)
    menu(str, {
        "No",
        "No",
        "No",
        "No",
        "No",
        "No",
        "Yes",
        "No",
        "No",
        "No"
    }, {nil, nil, nil, nil, nil, nil,
    function ()
        local result = {bootloader.bootfs.remove("/data")}
        if not result[1] then
            info(result[2] or "No Data Partition Found")
        else
            info("Data Successfully Wiped")
        end
        return true
    end}, true)
end})