local event = require("event")
local likenet = require("likenet")
local computer = require("computer")
local server = likenet.create("publicnet", "1234")

local delaytime = 1
local text = "test"

event.listen("client_package", function(...)
    local args = {...}

    if args[2] == server then
        if args[4] == "delay" then
            delaytime = args[5]
        elseif args[4] == "text" then
            text = args[5]
        end
    end
end)

while true do
    for i, client in ipairs(server.getClients()) do
        computer.beep(100, 0.1)
    end
    server.sendToClients(text)
    event.sleep(delaytime)
end