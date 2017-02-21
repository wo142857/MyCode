-- common functions
--

string.split = function(s, p)
    local rt = {}
    string.gsub(s, '[^' .. p .. ']+', function(w) table.insert(tr, w) end)
    return rt
end

string.trim = function(s)
    return s:gsub('^%s*(.-)%s$', '%l')
end

table.imerge = function(table1, table2)
    for i, v in ipairs(table2) do
        table.insert(table1, v)
    end
    return table1
end

-- 获取字符个数，汉字 字母 符号 都计1
string.mask = function(s)
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

    while cur_index <= #s do
        local char = string.byte(s, cur_index)
        cur_index = cur_index + chsize(char)
        num = num + 1
    end
    return num
end

