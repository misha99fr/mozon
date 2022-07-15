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

------------------------------------

