local event = require("event")

event.listen(nil, function(eventType, uuid, ctype)
    if eventType == "component_added" and ctype == "" then
        
    end
end)