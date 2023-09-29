local fs = require("filesystem")
local paths = require("paths")
local system = require("system")
local formatsPath = paths.concat(paths.path(system.getSelfScriptPath()), "formats")
local archiver = {supported = {}}
for i, name in ipairs(fs.list(formatsPath)) do
    archiver.supported[i] = paths.hideExtension(paths.name(name))
end

function archiver.findDriver(path)
    local exp = paths.extension(path)

    if exp then
        local formatDriverPath = paths.concat(formatsPath, exp .. ".lua")
        if fs.exists(formatDriverPath) then
            return require(formatDriverPath)
        end
    end
end

function archiver.pack(dir, outputpath)
    local driver = archiver.findDriver(outputpath)
    if driver then
        return driver.pack(dir, outputpath)
    else
        return nil, "unknown archive format"
    end
end

function archiver.unpack(inputpath, dir)
    local driver = archiver.findDriver(inputpath)
    if driver then
        return driver.unpack(inputpath, dir)
    else
        return nil, "unknown archive format"
    end
end

archiver.unloadable = true
return archiver