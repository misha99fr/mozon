local event = require("event")
local likenet = require("likenet")
local computer = require("computer")

local client = assert(likenet.connect(likenet.list()[1], "1234", "tupo client"))
client.sendToServer("delay", 3)
client.sendToServer("text", "asdqwe")

local count = 1

while true do
    local eventData = {event.pull()}

    if eventData[1] == "server_package" and eventData[2] == client then
        computer.beep(2000)
        count = count + 1
    end

    if count > 5 then
        client.destroy()
        return
    end
end