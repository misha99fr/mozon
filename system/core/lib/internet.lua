local component = require("component")
local internet = {}

function internet.getInternetFile(url)
    local inet = component.proxy(component.list("internet")() or "")

    if not inet then
        return nil, "no internet-card"
    end

    local handle = inet.request(url)
    local data = {}
    local dataI = 1
    if handle then
        while true do
            local result, reason = handle.read(math.huge) 
            if result then
                data[dataI] = result
                dataI = dataI + 1
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return table.concat(data)
                end
            end
        end
    else
        return nil, "invalid address"
    end
end

internet.unloadable = true
return internet