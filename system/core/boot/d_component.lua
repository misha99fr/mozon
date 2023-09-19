local component = component

setmetatable(component, {
    __index = function (self, key)
        local address = component.list(key, true)()
        if address then
            return component.proxy(address)
        end
    end
})