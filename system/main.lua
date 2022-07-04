local graphic = require("graphic")
local component = require("component")
local event = require("event")
local calls = require("calls")

------------------------------------

local screen = "20108ef5-444e-46bc-bd6c-48aee518009e"
local gpu = graphic.findGpu(screen)
calls.call("graphicInit", gpu)
gpu.setResolution(80, 25)
gpu.setDepth(4)

local colorsArray = { --computercraft colors
    white     = 0xF0F0F0,
    orange    = 0xF2B233,
    magenta   = 0xE57FD8,
    lightBlue = 0x99B2F2,
    yellow    = 0xDEDE6C,
    lime      = 0x7FCC19,
    pink      = 0xF2B2CC,
    gray      = 0x4C4C4C,
    lightGray = 0x999999,
    cyan      = 0x4C99B2,
    purple    = 0xB266E5,
    blue      = 0x3366CC,
    brown     = 0x7F664C,
    green     = 0x57A64E,
    red       = 0xCC4C4C,
    black     = 0x191919
}

local count = 0
for i, v in pairs(colorsArray) do
    gpu.setPaletteColor(count, v)
    count = count + 1
end

local rx, ry = gpu.getResolution()

local function warn(str)
    local cx, cy = gpu.getResolution()
    cx = cx / 2
    cy = cy / 2
    cx = cx - 16
    cy = cy - 4
    cx = math.floor(cx)
    cy = math.floor(cy)

    local window = graphic.classWindow:new(screen, cx, cy, 32, 8)

    window:fill(2, 2, window.sizeX, window.sizeY, colorsArray.gray, 0, " ")
    window:clear(colorsArray.lightGray)
    window:set(10, 2, colorsArray.lightGray, colorsArray.white, str)

    window:set(2, 2, colorsArray.lightGray, colorsArray.yellow, "  █")
    window:set(2, 3, colorsArray.lightGray, colorsArray.yellow, " ███ ")
    window:set(2, 4, colorsArray.lightGray, colorsArray.yellow, "█████")
    window:set(4, 3, colorsArray.yellow, colorsArray.white, "!")

    window:set(32 - 4, 7, colorsArray.blue, colorsArray.white, " ok ")

    while true do
        local eventData = {event.pull()}
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[4] == 7 and windowEventData[3] > (32 - 5) and windowEventData[3] <= ((32 - 5) + 4) then
            break
        end
    end
end

local function main()
    local window = graphic.classWindow:new(screen, 1, 1, rx, ry)

    local function redraw()
        window:clear(colorsArray.lightBlue)
        window:set(1, 1, colorsArray.lightGray, colorsArray.white, "12:00" .. string.rep(" ", window.sizeX - 5))
        window:set(1, 2, colorsArray.blue, colorsArray.white, "open")
    end
    redraw()

    while true do
        local eventData = {event.pull()}
        local windowEventData = window:uploadEvent(eventData)
        if windowEventData[4] == 2 and windowEventData[3] >= 1 and windowEventData[3] <= 4 then
            warn("WARN LALALA!!")
            redraw()
        end
    end
end

main()