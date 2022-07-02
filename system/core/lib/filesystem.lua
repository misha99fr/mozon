local component = require("component")
local paths = require("paths")

------------------------------------

local filesystem = {}
filesystem.mountList = {}

function filesystem.mount(proxy, path)
    path = paths.canonical(path)
    for i, v in ipairs(filesystem.mountList) do
        if v[2] == path then
            return "another filesystem is already mounted here"
        end
    end
    table.insert(filesystem.mountList, {proxy, path})
end

function filesystem.umount(path)
    path = paths.canonical(path)
    for i, v in ipairs(filesystem.mountList) do
        if v[2] == path then
            table.remove(filesystem.mountList, i)
            break
        end
    end
end

return filesystem