-- glob functions
function md5hex(s)
        local _md5o = md5.new()
        _md5o:update(s)
        return sstr.to_hex(_md5o:final())
end

string.split = function(s, p)
    local rt = {}
    string.gsub(s, '[^' .. p ..']+', function(w) table.insert(rt, w) end )
    return rt
end

table.imerge = function(table1, table2)
	for i, v in ipairs(table2) do
		table.insert(table1, v)
	end
	return table1
end

function _LOG(...)
	ngx.log(ngx.NOTICE, ...)
end

function _ERR(...)
	ngx.log(ngx.ERR, ...)
end

function _DEBUG(...)
	ngx.log(ngx.DEBUG, ...)
end

function _SAY(...)
	ngx.say(...)
end

function _JSON(...)
	return cjson.encode(...)
end



