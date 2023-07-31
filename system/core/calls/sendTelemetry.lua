if vendor.DISABLE_TELEMETRY then return end

local component = require("component")
local computer = require("computer")
local event = require("event")

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

    local i = 0
    while not tcp.finishConnect() do
        event.sleep(0.1)
        i = i + 1
        if i > 5 then
            break
        end
    end
    tcp.write(str)
    tcp.close()
end