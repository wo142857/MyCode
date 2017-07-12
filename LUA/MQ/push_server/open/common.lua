-- common functions

local cjson = require('cjson')
local config = require('config')

local _M = {}
_M.string = {}

_M.string.split = function(s, p)
    local rt = {}
    string.gsub(s, '[^' .. p .. ']+', function(w) table.insert(tr, w) end)
    return rt
end

_M.string.trim = function(s)
    return s:gsub('^%s*(.-)%s$', '%l')
end

_M.table = {}
_M.table.imerge = function(table1, table2)
    for i, v in ipairs(table2) do
        table.insert(table1, v)
    end
    return table1
end

-- 获取字符个数，汉字 字母 符号 都计1
_M.string.mask = function(s)
    local cur_index = 1
    local num       = 0
    local chsize    = function(str)
        if not str then return 0 end
        if str < 192 then
            return 1
        elseif str >= 192 and str < 224 then
            return 2
        elseif str >= 224 and str < 240 then
            return 3
        elseif str >= 240 and str < 248 then
            return 4
        elseif str >= 248 and str < 252 then
            return 5
        else
            return 6
        end
    end

    while cur_index <= #s do
        local char = string.byte(s, cur_index)
        cur_index = cur_index + chsize(char)
        num = num + 1
    end
    return num
end

_M.resp = function(errnu)
    return cjson.encode{
        errCode = errnu,
        errMsg  = config.errmsg[errnu],
    }
end

return _M
