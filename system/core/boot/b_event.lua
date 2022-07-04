local event = require("event")

event.listen(nil, function(eventType, uuid, ctype)
    if eventType == "component_added" and ctype == "keyboard" then
        
    end
end)