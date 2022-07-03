local windows = {}
do
    local calls = require("calls")
    local graphicInit = calls.load("graphicInit")

    for address in component.list("screen") do
        local term = require("term")
        local gpu = term.findGpu(address)
        if gpu then
            graphicInit(gpu)
            table.insert(windows, term.classWindow:new(address, 1, 1, 25, 5))
            table.insert(windows, term.classWindow:new(address, 1, 7, 25, 5))
        end
    end
end

for i, window in ipairs(windows) do
    window:clear(math.random(0, 0xFFFFFF))
    for i = 1, 3 do
        window:write(tostring(i) .. "\n", math.random(0, 0xFFFFFF), math.random(0, 0xFFFFFF))
        os.sleep(1)
    end
end