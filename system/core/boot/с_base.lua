local computer = require("computer")

function os.sleep(time)
    local inTime = computer.uptime()
    repeat
        computer.pullSignal(time - (computer.uptime() - inTime))
    until computer.uptime() - inTime > time
end