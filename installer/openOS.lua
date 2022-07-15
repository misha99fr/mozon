local fs = require("filesystem")
local component = require("component")
if not component.isAvailable("internet") then
    print("no internet card found")
    return
end

------------------------------------

print("выберите диск который хотите сделать устоновочьным")
local count = 1
local variantes = {}
for address in component.list("filesystem") do
    print(tostring(count) .. ". " .. (address:sub(1, 4)) .. " label: " .. (component.invoke(address, "getLabel") or ""))
    count = count + 1
    table.insert(variantes, address)
end

local read = io.read()
if not read then return end
if not tonumber(read) then
    print("invalide input")
    return
end
local address = variantes[read]

------------------------------------

local function getInternetFile(url)
    local handle, data, result, reason = component.internet.request(url), ""
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
        return nil, "unvalid address"
    end
end