local component = require("component")

local proxyOrAddress = ...
local proxyGpu
if type(proxyOrAddress) == "string" then
    proxyGpu = component.proxy(...)
else
    proxyGpu = proxyOrAddress
end

proxyGpu.setDepth(proxyGpu.maxDepth())
local rx, ry = proxyGpu.maxResolution()
proxyGpu.setResolution(rx, ry)
proxyGpu.setBackground(0)
proxyGpu.setForeground(0xFFFFFF)
proxyGpu.fill(1, 1, rx, ry, " ")