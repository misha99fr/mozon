local fs = require("filesystem")
local unicode = require("unicode")
local paths = require("paths")
local package = require("package")
local calls = require("calls")
local event = require("event")

------------------------------------

local programs = {}
programs.paths = {"/system/core/bin", "/system/bin"}
programs.unloaded = true

function programs.find(name)
    if unicode.sub(name, 1, 1) == "/" then
        if fs.exists(name) then
            if fs.isDirectory(name) then
                if fs.exists(paths.concat(name, "main.lua")) then
                    return paths.concat(name, "main.lua")
                end
            else
                return name
            end
        end
    else
        for i, v in ipairs(programs.paths) do
            if fs.exists(paths.concat(v, name .. ".lua")) and
            not fs.isDirectory(paths.concat(v, name .. ".lua")) then
                return paths.concat(v, name .. ".lua")
            elseif fs.exists(paths.concat(v, name, "main.lua")) and
            fs.isDirectory(paths.concat(v, name)) and
            not fs.isDirectory(paths.concat(v, name, "main.lua")) then
                return paths.concat(v, name, "main.lua")
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
    local code, err = programs.load(name)
    if not code then return nil, err end

    local thread = package.get("thread")
    if not thread then
        return pcall(code, ...)
    else
        local t = thread.create(code, ...)
        t:resume() --потому что по умолчанию поток спит
        while t:status() ~= "dead" do event.sleep(0.1) end
        return table.unpack(t.out or {true})
    end
end

return programs