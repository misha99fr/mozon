local fs = require("filesystem")
local unicode = require("unicode")
local paths = require("paths")
local calls = require("calls")

------------------------------------

local programs = {}
programs.paths = {"/system/core/bin", "/system/bin"}

function programs.find(name)
    if unicode.sub(name, 1, 1) == "/" then
        return name
    else
        for i, v in ipairs(programs.paths) do
            local path = paths.concat(v, name .. ".lua")
            if fs.exists(path) then
                return path
            end
        end
    end
end

function programs.load(name, mode, env)
    local path = programs.find(name)
    if not path then return nil, "no such programm" end

    local file, err = fs.open(path, "rb")
    if not file then return nil, err end
    local data = file.readAll()
    file.close()
    
    local code, err = load(data, "=" .. path, mode, env or calls.call("createEnv"))
    if not code then return nil, err end

    return code
end

function programs.execute(name, ...)
    return pcall(assert(programs.load(name)), ...)
end

return programs