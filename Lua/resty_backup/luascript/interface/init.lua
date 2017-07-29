-- interface code.
require "interface.list"
require "interface.multipart"
require "interface.helper"
require "interface.ui_common"

-- check param
GV_SIGNKEY = "ZYK_ac17c4b0bb1d5130bf8e0646ae2b4eb4"

function check_sign(value, sign)
	local _md5o = md5.new()
	_md5o:update(value .. GV_SIGNKEY)
	local _data = sstr.to_hex(_md5o:final())
	return _data == sign, _data
end

function get_table_value(t)
	if type(t) ~= "table" then
		return t
	end

	for k, v in pairs(t) do
		if (type(v) == "string" and #v > 0) then
			return v
		end	
	end
	return nil
end;

function check_param (cmd, _GET, _POST, _FILE)
	local _pattern = GV_IFS[cmd]
	if _pattern == nil then	
		return "PARAM ERROR"
	end

	_POST = _POST or {}

	local _signdata = ""
	local _sign     = nil
	local _REQ      = {}

	for __k, v in pairs(_pattern.base_param) do
		local k         = v.name
		local _value    = get_table_value(_GET[k]) or get_table_value(_POST[k])

		if(type(_value) == "nil") then
			return string.format("Param [%s] must exist.", k)
		end

		_REQ[k] = _value

		if(k ~= "sign") then
			_signdata = _signdata .. _value
		else
			_sign = _value
		end

		local _vpat         = v.pattern
		local _vlen         = v.length or {0, 9999}
		local _vlen_min     = _vlen[1] or 0
		local _vlen_max     = _vlen[2] or 9999
		local _tmp_vlen     = string.len(_value)
		local _tmp_range    = table.concat({_vlen_min, _vlen_max}, ",")
		
		if (_tmp_vlen < _vlen_min) or (_tmp_vlen > _vlen_max) then
			return string.format("Param [%s] length=%d, out of range[%s].",
                k, _tmp_vlen, _tmp_range)
		end

		if type(_vpat) == "string" then
			local _vmatch = string.match(_value, _vpat)
			if _vmatch ~= _value then
				return string.format(
                    "Param [%s] value, has invalid charactors.", k)
			end
		elseif type(_vpat) == "table" then
			local _matched = false
			for _k, _v in pairs(_vpat) do
				if( _v == _value ) then
					_matched = true
					break
				end
			end

			if(not _matched) then
				return string.format("Param [%s] value, out of range[%s].", 
                    k, table.concat(_vpat, ","))
			end
		end
	end

	for k, v in pairs(_pattern.opt_param) do
		local k         = v.name
		local _value    = get_table_value(_GET[k]) or get_table_value(_POST[k])
		local _vpat     = v.pattern
		local _vlen     = v.length or {0, 9999}
		if type(_value) == "nil" or #_value == 0 then
			_value = nil
			if v.default then
				_value = v.default
			end
		end
		if type(_value) ~= "nil" then
			_REQ[k] = _value

			local _vlen_min     = _vlen[1] or 0
			local _vlen_max     = _vlen[2] or 9999
			local _tmp_vlen     = string.len(_value)
			local _tmp_range    = table.concat({_vlen_min, _vlen_max}, ",")
		
			if (_tmp_vlen < _vlen_min) or (_tmp_vlen > _vlen_max) then
				return string.format("Param [%s] length=%d, out of range[%s].",
                    k, _tmp_vlen, _tmp_range)
			end

			if type(_vpat) == "string" then
				local _vmatch = string.match(_value, _vpat)
				if _vmatch ~= _value then
					return string.format(
                        "Param [%s] value, has invalid charactors.", k)
				end
			elseif type(_vpat) == "table" then
				local _matched = false
				for _k, _v in pairs(_vpat) do
					if _v == _value then 
						_matched = true
						break
					end
				end

				if not _matched then
					return string.format(
                        "Param [%s] value, out of range[%s].",
                        k, table.concat(_vpat, ","))
				end
			end

			if v.checksign then
				_signdata = _signdata .. _value
			end
		else 
			if v.type == "file" then
				_value = _FILE [k]
			end
		end
	end

	if _sign then
		local _result, _rightsign = check_sign(_signdata, _sign)
		if not _result then
			return "Check sign error: " .. _rightsign
		end
	end
	return nil, _REQ
end

function if_route( ) 
	local _ret, _result
	local _errcode      = -10000
	local _URI          = string.lower(ngx.var.uri)
	local _METHOD       = ngx.var.request_method
	local _GET          = ngx.req.get_uri_args()
	local _urlsplits    = string.split(_URI, '/')
	local _PATH         = _urlsplits[1]
	local _COMMAND      = _urlsplits[2] or ""
	
	if _PATH == 'oauth' then
		if type(GV_IFS[_COMMAND]) == 'table' then
			local _rcode, _postarray, _filearray = proc_multipart_form(_COMMAND)
			if _rcode < 0 then
				return _ERR(_rcode)
			end
			local _result, _reqarray 
                = check_param(_COMMAND, _GET, _postarray, _filearray)
			if _result then
				_errcode = -10001   -- illegal param
				return _ERR(_errcode, _result)
			end
			local _ret = GV_IFS[_COMMAND]['callback'](_reqarray, _filearray)
			return _ret
		else
			_errcode = -10000   -- illegal function
		end
	end

	return _ERR(_errcode)
end

function get_html_pattern(mod)
	local _html = ""
	for _line in 
        io.lines(config.root_dir .. "interface/html/" .. mod .. ".html") do
		_html = _html .. _line
	end
	return _html
end

for k, v in ipairs(GV_IFLIST) do
	if not v:match("^%-%-") then
		require("interface." .. v)
	end
end

function parse_devinfo(devinfo)
    local _de_devstr = str_crypt(devinfo)
    if _de_devstr == nil then
        return
    end

    local _plain_devstr = ngx.decode_base64(_de_devstr)
    local _obj          = cjson_safe.decode(_plain_devstr)

    if type(_obj) == "table" then
        return _obj
    end
    return nil
end
