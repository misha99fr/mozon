if _G.DISABLE_TELEMETRY then return end

local component = require("component")
local computer = require("computer")

local telemetrytype, telemetrydata = ...
if not telemetrytype then telemetrytype = "any" end
if not telemetrydata then telemetrydata = "" end

telemetrydata = table.concat(split2(string, telemetrydata, {"\n"}), ";")

--------------------------------------------------

local internet = component.proxy(component.list("internet")() or "")
if internet then
    local tcp = internet.connect("176.53.161.98", 1236)

    local str = 
    "telemetry\n" .. 
    tostring(_COREVERSION) .. "\n" ..
    (_OSVERSION and tostring(_OSVERSION) or "unknown") .. "\n" ..
    tostring(internet.address) .. "\n" ..
    tostring(math.floor(computer.totalMemory() + 0.5)) .. "\n" ..
    tostring(computer.uptime()) .. "\n" ..
    tostring(getRawRealtime()) .. "\n" ..
    telemetrytype .. "\n" ..
    telemetrydata

    tcp.finishConnect()
    tcp.write(str)
    tcp.close()
end