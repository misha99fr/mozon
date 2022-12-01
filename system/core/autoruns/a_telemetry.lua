local event = require("event")

-------------------------------------

sendTelemetry("power on")

event.timer(60 * 5, function()
    sendTelemetry()
end, math.huge)