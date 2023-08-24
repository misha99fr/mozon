local unicode = require("unicode")
local gui_container = require("gui_container")
local colors = gui_container.colors
local syntaxHighlighting = {}
local keywords = {
    ["function"] = colors.magenta,
    ["return"] = colors.magenta,

    ["true"] = colors.blue,
    ["false"] = colors.blue,
    ["nil"] = colors.blue,
    
    ["local"] = colors.blue,

    ["until"] = colors.purple,
    ["repeat"] = colors.purple,
    ["while"] = colors.purple,
    ["for"] = colors.purple,
    ["if"] = colors.purple,
    ["then"] = colors.purple,
    ["end"] = colors.purple,
    ["do"] = colors.purple
}

function syntaxHighlighting.parse(code)
    local function spl(str)
        local lst = {}
        local oldChrType
        for i = 1, unicode.len(str) do
            local chr = unicode.sub(str, i, i)
            local chrType
            if chr >= "0" and chr <= "9" then
                chrType = 1
            elseif (chr >= "A" and chr <= "Z") or (chr >= "a" and chr <= "z") then
                chrType = 2
            elseif chr == "[" then
                chrType = 3
            elseif chr == "]" then
                chrType = 4
            elseif  chr == "-" then
                chrType = 5
            end

            if not chrType or oldChrType ~= chrType or #lst == 0 then
                table.insert(lst, "")
                oldChrType = chrType
            end

            lst[#lst] = lst[#lst] .. chr
        end
        return lst
    end

    local obj = {}
    local gcomment = false
    local counter = 1
    for posY, str in ipairs(split2(unicode, code, {"\n"})) do
        local posX = 1
        local lcomment = false
        local lostr = false
        local lostr2 = false
        for _, lstr in ipairs(spl(str)) do
            if lstr ~= "" then
                local lcolor

                if lstr == "--" then
                    lcomment = true
                elseif lstr == "[[" then
                    gcomment = true
                end

                local isred = lostr or lostr2
                if lstr == "\"" then
                    lostr = not lostr
                elseif lstr == "'" then
                    lostr2 = not lostr2
                end

                if lcomment or gcomment then
                    lcolor = colors.green
                elseif lostr or lostr2 or isred then
                    lcolor = colors.orange
                else
                    lcolor = keywords[lstr] or colors.white
                end
                
                if lstr == "]]" then
                    gcomment = false
                end

                table.insert(obj, {posX, posY, lstr, lcolor, counter})
            end
            posX = posX + unicode.len(lstr)
            counter = counter + unicode.len(lstr)
        end
    end
    return obj
end

function syntaxHighlighting.draw(x, y, obj, gpu)
    for index, value in ipairs(obj) do
        gpu.setForeground(value[4])
        gpu.set((x - 1) + value[1], (y - 1) + value[2], value[3])
    end
end

syntaxHighlighting.unloaded = true
return syntaxHighlighting