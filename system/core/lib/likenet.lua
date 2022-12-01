local event = require("event")
local component = require("component")
local computer = require("computer")

--------------------------------------------

local likenet = {}
likenet.port = 432
likenet.servers = {}
likenet.clients = {}

function likenet.create(name, password, devices)
    checkArg(1, name, "string")
    checkArg(2, password, "string", "nil")
    password = password or "0000"

    if devices then
        for device in pairs(devices) do
            if component.type(device) == "modem" then
                component.invoke(device, "open", likenet.port)
            end
        end
    end

    ------------------------------------

    local host = {}
    host.clients = {}
    host.echoMode = true

    --вернет таблицу обектов клиентов в формате {{name = "clientname", deviceType == "modem"/"tunnel", device = "address", address = "address", connected = true}}, для передачи данных клиенту нужно будет передавать в функцию sendToClient обект из этой таблицы
    function host.getClients() 
        return host.clients
    end

    function host.sendToClient(client, ...)
        if not client.connected and client.disconnected then return nil, "client disconnected" end
        local packageType = client.connected and "package" or "disconnected"

        if not client.connected then
            client.disconnected = true
        end

        if client.deviceType == "modem" then
            return component.invoke(client.device, "send", client.address, likenet.port, packageType, ...)
        elseif client.deviceType == "tunnel" then
            return component.invoke(client.device, "send", packageType, ...)
        end

        return nil, "device unsupported"
    end

    function host.sendToClients(...)
        for i, client in ipairs(host.getClients()) do
            host.sendToClient(client, ...)
        end
    end

    function host.disconnect(client)
        client.connected = false
        for i, lclient in ipairs(host.clients) do
            if lclient == client then
                table.remove(host.clients, i)
                break
            end
        end
        host.sendToClient(client)
    end

    ------------------------------------

    function host.remove()
        event.cancel(host.listen)
        event.cancel(host.timer)
        for i, client in ipairs(host.getClients()) do
            client:disconnect()
        end

        for k, v in pairs(host) do
            host[k] = nil
        end

        for i, sv in ipairs(likenet.servers) do
            if sv == host then
                table.remove(likenet.servers, i)
                break
            end
        end
    end

    function host.echo()
        if devices then
            for device in pairs(devices) do
                if component.type(device) == "modem" then
                    component.invoke(device, "broadcast", likenet.port, "host", name)
                elseif component.type(device) == "tunnel" then
                    component.invoke(device, "send", "host", name)
                end
            end
        else
            for address in component.list("modem") do
                component.invoke(address, "open", likenet.port)
                component.invoke(address, "broadcast", likenet.port, "host", name)
            end
            for address in component.list("tunnel") do
                component.invoke(address, "send", "host", name)
            end
        end
    end

    host.listen = event.listen("modem_message", function(_, modemAddress, clientModemAddress, port, dist, packageType, ...)
        local args = {...}
        
        if type(modemAddress) == "string" and (not devices or devices[modemAddress]) and (port == 0 or port == likenet.port) then
            local deviceType = component.type(modemAddress)

            if deviceType == "modem" or deviceType == "tunnel" then
                if packageType == "connect" then
                    local function sendResult(...)
                        if deviceType == "modem" then
                            component.invoke(modemAddress, "send", clientModemAddress, likenet.port, ...)
                        else
                            component.invoke(modemAddress, "send", ...)
                        end
                    end
                    if args[2] == password then
                        for i, client in ipairs(host.getClients()) do
                            if client.address == clientModemAddress then
                                sendResult("connectResult", false, "you are already connected")
                                return
                            end
                        end
                        table.insert(host.clients, {
                            host = host,
                            name = args[1],
                            address = clientModemAddress,
                            device = modemAddress,
                            deviceType = deviceType,
                            connected = true,
                            disconnect = host.disconnect,
                            sendToClient = host.sendToClient,
                        })
                        sendResult("connectResult", true)
                    else
                        sendResult("connectResult", false, "incorrect password")
                    end
                elseif packageType == "disconnect" then
                    for i, client in ipairs(host.getClients()) do
                        if client.address == clientModemAddress then
                            host.disconnect(client)
                            break
                        end
                    end
                elseif packageType == "clientPackage" then
                    local client
                    for i, lclient in ipairs(host.getClients()) do
                        if lclient.address == clientModemAddress then
                            client = lclient
                            break
                        end
                    end
                    if client then
                        event.push("client_package", host, client, table.unpack(args)) --likeOS поддерживает передачу таблиц через event
                    end
                end
            end
        end
    end)
    host.timer = event.timer(1, function()
        if not host.echoMode then return end
        host.echo()
    end, math.huge)

    table.insert(likenet.servers, host)
    return host
end

function likenet.list() --выведет список доступных сетей для подключения в формате {{name = "name", serverDevice = "address", clientDeviceType = "modem"/"tunnel", clientDevice = "address"} этот обект нужно будет передать в функцию подключения к сети
    local list = {}

    for address in component.list("modem") do
        component.invoke(address, "open", likenet.port)
    end

    local lastpackage = computer.uptime()
    while computer.uptime() - lastpackage <= 2 do
        local eventData = {event.pull(0.1)}
        if eventData[1] == "modem_message" and type(eventData[2]) == "string" and (component.type(eventData[2]) == "modem" or component.type(eventData[2]) == "tunnel") and (eventData[4] == 0 or eventData[4] == likenet.port) and eventData[6] == "host" and type(eventData[7]) == "string" then
            local finded
            for i, v in ipairs(list) do
                if v.serverDevice == eventData[3] then
                    finded = true
                    break
                end
            end

            if not finded then
                lastpackage = computer.uptime()
                table.insert(list, {
                    name = eventData[6],
                    clientDeviceType = component.type(eventData[2]),
                    serverDevice = eventData[3],
                    clientDevice = eventData[2],
                })
            end
        end
    end

    return list
end

function likenet.connect(host, password, connectingName)
    checkArg(1, host, "table")
    checkArg(2, password, "string", "nil")
    checkArg(3, connectingName, "string", "nil")
    password = password or "0000"
    connectingName = connectingName or computer.address()

    local function raw_send(...)
        if host.clientDeviceType == "tunnel" then
            component.invoke(host.clientDevice, "send", ...)
        else
            component.invoke(host.clientDevice, "send", host.serverDevice, likenet.port, ...)
        end
    end

    local function isValidPackage(eventData)
        return eventData[1] == "modem_message" and type(eventData[2]) == "string" and (component.type(eventData[2]) == "modem" or component.type(eventData[2]) == "tunnel") and (eventData[4] == 0 or eventData[4] == likenet.port)
    end

    local function wait_result(packageType)
        local starttime = computer.uptime()
        while computer.uptime() - starttime <= 2 do
            local eventData = {event.pull(0.1)}
            if isValidPackage(eventData) and (not packageType or eventData[6] == packageType) then
                return table.unpack(eventData, 6)
            end
        end
    end

    raw_send("connect", connectingName, password)
    local packageType, state, err = wait_result("connectResult")

    if not packageType then
        return nil, "connection error"
    end

    if not state then
        return nil, err or "unknown error"
    end

    ------------------------------------

    local client = {}
    client.connected = true
    client.host = host

    local function disconnect()
        event.cancel(client.listen)
        client.connected = false
        event.push("disconnected", client, host)

        for i, cl in ipairs(likenet.clients) do
            if cl == client then
                table.remove(likenet.clients, i)
                break
            end
        end
    end

    function client.sendToServer(...)
        raw_send("clientPackage", ...)
    end

    function client.disconnect()
        raw_send("disconnect")
        disconnect()
    end

    client.listen = event.listen("modem_message", function(...)
        if not client.connected then return false end

        local args = {...}
        if isValidPackage(args) then
            if args[6] == "disconnected" then
                disconnect()
            elseif args[6] == "package" then
                event.push("server_package", client, host, table.unpack(args, 7))
            end
        end
    end)

    return client
end

return likenet