-- helper
GV_IFS = GV_IFS or {}

local _module_      = (...):match("^.*%.(.*)$")
local p_interface   = "";
local replace_list  = {};

GV_IFS[_module_] = {
	name        = _module_,
	base_param  = {},
	opt_param   = {
		{
            name    = "interface",
            pattern = GV_IFLIST, 
            helper  = {"接口说明",""},
            default = "default",
        },
		{
            name    = "ui",
            pattern = ".+",
            length  = {1,},
            helper  = {"UI说明",""},
        },
	},
}

function replace_list.IF_LIST()
	local _if_list = ""

	for k, v in ipairs(GV_IFLIST) do
		if(v:match("^%-%-")) then
			_if_list = _if_list 
                .. string.format("<span class=subheading>%s</span><br>", v)
		elseif(v:match("ui_.*")) then

		else
			if( v ~= "helper" ) then
				_if_list = _if_list .. string.format(
                    "<a href=/oauth/helper?interface=%s>%s</a><br/>\n",
                    v, GV_IFS[v].cname)
			end
		end
	end
	return _if_list
end

function replace_list.IF_NAME()
	local _ifname = p_interface

	if p_ui then
		local _p_ui = p_ui 
            .. "?openid=54044e40c2309952890001ce&token=5404e862c230991e0b00002e"
            .. "&devinfo=rjnlhbH8o8Zko2GRhsakKsawHdGdp2akoCZ0ZRtlKbM8o8ZFpdxBHs"
            .. "3Bp2Z9p2hkpk+8AQnGzNpGZda8p2hBH23wH2+jpd+9Hk/FZVF"
		return [[<div class="phone"><iframe frameborder=1 src="/oauth/]]
            .. _p_ui .. [["></iframe></div>]]
	else
		if(GV_IFS[p_interface] and GV_IFS[p_interface].cname) then
            _ifname = _ifname .. ":" .. tostring(GV_IFS[ p_interface ].cname)
        end
		return "<h1>" .. _ifname .. "</h1>"
	end
end

function replace_list.IF_UI()
	local _ret = ""

	for k, v in pairs(GV_IFLIST) do
		if v:match("ui_.*") then
			_ret = _ret .. string.format(
                "<a href=/oauth/helper?ui=%s>%s</a><br/>\n", v, v)
		end
	end

	return _ret
end

function value_desc(desc, len, range)
	local _ret = ""
	if(type(range) == "table") then
		_ret = "[" .. table.concat(range, ",") .. "]"
	else
		_ret = desc
		if type(len) == "table" then
			if(len[2] == len[1]) then
				_ret = _ret .. ", 长度:" .. len[1]
			else
				local _len_max = len[2] or "1024K"

				_ret = _ret .. ", 长度:[" .. len[1] .. "," .. _len_max .. "]"
			end
		end
	end
	
	return _ret
end

function replace_list.IF_BODY()
	local _ret = ""
	if p_ui then

    elseif(p_interface and p_interface ~= "helper") then
		local _signlist     = "["
		local _multipart    = ""

		if GV_IFS[p_interface].multipart then
            _multipart = 'enctype="multipart/form-data"'
        end

		_ret = [[<form method=POST action=/oauth/]] .. p_interface
            .. ' ' .. _multipart .. [[ target=_res>]]
		    .. "<table class=func_desc >\n"
		    .. "<tr><td class=tt0 colspan=4>接口URL：<b>http://"
            .. ngx.req.get_headers()["Host"] .. "/oauth/" .. p_interface
            .. "</b></td></tr>\n"
		    .. "<tr><td class=tt1 colspan=4>接口说明："
            .. (GV_IFS[p_interface].desc or "") .. "</td></tr>\n"
		if type(GV_IFS[p_interface].base_param) == "table" 
            and #GV_IFS[ p_interface ].base_param > 0 then
            _ret = _ret .. "<tr><td class=tt2 colspan=4>固定参数</td></tr>"
			    .. "<tr><td width=80>参数名</td><td width=80>参数含义</td>"
                .. "<td>取值约束</td><td width=220>测试值</td></tr>\n"
		end

		local _needsign = false
        for k, v in ipairs(GV_IFS[p_interface].base_param) do
			local _value = ""

			if(v.name ~= "sign") then
                _signlist = _signlist..v.name.." "
            else
                _value      = "1234567890abcdef0123456789abcdef"
                _needsign   = true
            end
            v.type = v.type or 'text'
            
            local _p = string.format("<tr><td>%s</td><td>%s</td><td>%s</td>"
                .. "<td><input class=testv type=" .. v.type
                .. " name=%s value='%s'></td></tr>\n", v.name, v.helper[1],
                value_desc(v.helper[2],v.length,v.pattern), v.name, _value)
            
            _ret = _ret .. _p
        end
		
        if type(GV_IFS[p_interface].opt_param) == "table" 
            and #GV_IFS[ p_interface ].opt_param > 0 then
	        _ret = _ret .. "<tr><td colspan=4 class=tt2>可选参数</td></tr>"
                .. "<tr><td>参数名</td><td>参数含义</td><td>取值约束</td>"
                .. "<td>测试值</td></tr>\n"

        	for k, v in ipairs(GV_IFS[p_interface].opt_param) do
				v.type = v.type or 'text'

                local _p = string.format("<tr><td>%s</td><td>%s</td><td>%s</td>"
                    .. "<td><input class=testv type=" .. v.type
                    .. " name=%s value=''></td></tr>\n", v.name, v.helper[1],
                    value_desc( v.helper[2], v.length, v.pattern), v.name)
 	            
                _ret = _ret .. _p
				
                if(v.checksign) then
                    _signlist = _signlist .. v.name .. " "
                end
        	end
		end

		if _needsign then
			_ret = _ret .. "<tr><td>签名计算</td><td colspan=3>" .. _signlist
                .. "]</td></tr>\n"
		end

		_ret = _ret .. "<tr><td colspan=4 class=tdcenter><input type=submit "
            .. "value='GoGoGo Test!'></td></tr>\n"
		    .. "<tr><td colspan=4><iframe width=100% height=120 id=_res "
            .. "name=_res frameborder=0></iframe></td></tr>\n</table></form>\n"
        end

	return _ret
end

local function div_replace(mm)
	if(type(replace_list[mm]) == "function") then
		return replace_list[mm]()
	end
	return ""
end;

local _html_pattern = [[
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="zh" lang="zh-CN">
<head>
<title>oauth helper page</title>
<meta http-equiv="content-type" content="application/xhtml+xml; charset=UTF-8" />
<meta name="author" content="qox@163.com" />
<meta name="keywords" content="lua api" />
<meta name="description" content="lua api" />
<style>
iframe,body {
  margin: 0px;
  padding: 0px;
  font-family: "微软雅黑",verdana, arial, helvetica, sans-serif;
  font-size: 14px;
  line-height: 24px;
  color: #000;
  background-color: #EEE;
  text-align: center;
}
td {
  text-align: left;
  font-size: 12px;
  padding-left: 5px;
}
.testv {
  width:220px;
}

.tt0 { text-align: left;  background-color: #9b0;}
.tt1 { text-align: left;  background-color: #DDD;}
.tt2 { text-align: center;  background-color: #EEE; }
.tdcenter {
  text-align: center;
  padding-left: 5px;

}
h1 {
  font-size: 14px;
  font-weight: bold;
  color: #690;
}

h2 {
  font-size: 14px;
  font-weight: bold;
  color: #D0AD67;
}

.subheading {
  font-size: 14px;
  font-weight: bold;
  color: #069;
}

h3 {
  font-size: 14px;
  font-weight: bold;
  color: #069;
}
.func_desc {
  width:100%;
  BORDER: #ff6600 2px dotted;
}

.func_desc td{border:1px solid #777} 
.phone{ background-image:url("/ui/imgs/phone.jpg");
	background-repeat:no-repeat;
	-webkit-background-size:cover;
	-moz-background-size:cover;
	-o-background-size: cover;
	background-size: cover;
	height:788px;
	width:410px;
}
.phone > iframe{border: #999 1px dotted ;position:relative;top:70px;left:-2px;width:360px;height:640px}

.title {
  font-size: 20px;
  font-weight: bold;
  text-align:left;
  color: #690;
  border-left: 5px solid #F90;
  padding-left: 5px;
}

.subtitle {
  font-size: 14px;
  font-weight: bold;
  color: #333;
  border-left: 5px solid #FFF;
  padding-left: 5px;
}

#lpanel .heading {
  background-color: #690;
  font-size: 14px;
  font-weight: bold;
  color: #FFF;
  text-align: center;
  padding: 0px;
  margin-top: 5px;
  margin-bottom: 5px;
}

#lpanel a {
  color: #333;
  text-decoration: none;
  text-align: left;
  font-weight: bold;
  font-size: 12px;
  padding-left: 5px;
}

#lpanel a:hover {
  color: #690;
  text-align: left;
}

a {
  color: #690;
  text-decoration: none;
  padding: 1px;
}

a:hover {
  color: #666;
  background-color: #EEE;
}

img {
  float: right;
  padding-left: 10px;
  padding-right: 10px;
}

#header {
  width: 948px;
  height: 65px;
  margin: 5px;
  padding: 10px;
  background-color: #FFF;
  border: 1px solid #DDD;
}

#title {
  position: absolute;
  top: 20px;
  left: 20px;
  padding: 10px;
  background-color: #FFF;
}

#lpanel {
  position: absolute;
  top: 72px;
  left: 0px;
  text-align:left;
  margin: 5px;
  padding: 10px;
  background-color: #FFF;
  border: 1px solid #DDD;
  width: 200px;
}

#content {
  width: 721px;
  margin: 0px 200px 5px 232px;
  padding: 10px;
  background-color: #FFF;
  border: 1px solid #DDD;
}

#footer {
  width: 721px;
  margin: 5px 200px 5px 232px;
  padding: 10px;
  background-color: #FFF;
  border: 1px solid #DDD;
  text-align: right;
}

.plaintext{
  text-align: left;
  font-size: 12px;
}
</style>
</head>
<body>
<div id="header"></div>
<div id="title">
  <div class="title">卓悠用户接口 LAPI </div>
  <div class="subtitle">base on nginx & lua, a fast and high-performance platform.</div>
</div>
<div id="lpanel">
  <div class="heading">UI列表</div>
  <div class="plaintext">
  <!--LP_BEGIN--## IF_UI ##--LP_END-->
  <div class="heading">接口列表</div>
  <!--LP_BEGIN--## IF_LIST ##--LP_END-->
  </div>
</div>
<div id="content">
  <!--LP_BEGIN--## IF_NAME ##--LP_END-->
  <!--LP_BEGIN--## IF_BODY ##--LP_END-->

</div>
<div id="footer">
  <div>&copy; Copyright 2014 <a href="http://zhuoyoutech.com.cn">Zhuoyou Network</a></div>
  <div>This api write by a NB boy : <a href="mailto:yangxd@tydtech.com">Yang</a></div>
</div>
<div>&nbsp;</div>
</body>
</html>

]];

GV_IFS[_module_]['callback'] = function(_REQ, _FILE)
	p_interface = _REQ['interface']
	p_ui        = _REQ['ui']

	local _html_out = string.gsub(_html_pattern, 
        "<!%-%-LP_BEGIN%-%-## ([A-Z_]+) ##%-%-LP_END%-%->", div_replace)
	return _html_out
end

