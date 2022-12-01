local event = require("event")

-------------------------------------

sendTelemetry("power on")

event.timer(30, function()
    sendTelemetry()
end, math.huge)