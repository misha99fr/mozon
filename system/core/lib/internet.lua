local component = require("component")
local internet = {}

function internet.getInternetFile(url)
    local inet = component.proxy(component.list("internet")() or "")

    if not inet then
        return nil, "no internet-card"
    end

    local handle, data, result, reason = inet.request(url), ""
    if handle then
        while true do
            result, reason = handle.read(math.huge) 
            if result then
                data = data .. result
            else
                handle.close()
                
                if reason then
                    return nil, reason
                else
                    return data
                end
            end
        end
    else
        return nil, "invalid address"
    end
end

internet.unloaded = true
return internet