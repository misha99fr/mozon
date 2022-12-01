local env = {
    _VERSION = _VERSION,

    rawset = rawset,
    rawget = rawget,
    rawlen = rawlen,
    rawequal = rawequal,

    table = deepclone(table),
    unicode = deepclone(unicode),
    math = deepclone(math),
    utf8 = deepclone(utf8),
    string = deepclone(string),
    coroutine = deepclone(string),
    os = deepclone(string),
    debug = deepclone(debug),


    type = type,
    assert = assert,
    error = error,
    checkArg = checkArg,

    next = next,
    select = select,
    
    pairs = pairs,
    ipairs = ipairs,
    
    tostring = tostring,
    tonumber = tonumber,

    setmetatable = setmetatable,
    getmetatable = getmetatable,

    
    load = load,
    pcall = pcall,
    xpcall = xpcall,
}
env._G = env
return env