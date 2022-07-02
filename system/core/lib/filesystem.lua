local component = require("component")
local paths = require("paths")

------------------------------------

local filesystem = {}
filesystem.mountList = {}

function filesystem.mount(proxy, path)
    
end

function filesystem.umount(path)
    for i, v in ipairs(filesystem.mountList) do
        if v[2] == paths.canonical(path) then
            
        end
    end
end

return filesystem