local lib = {}

function lib.sha256(msg)
    return sha256(msg)
end

lib.unloaded = true
return lib