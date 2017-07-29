
replace_list = replace_list or {};

function init_user_data( db, openid, imsi )
        local _result = { result = 0};

        local _rcode, _user = user_getinfo( db, openid );
        if _rcode == 0 then
                _result.username = _user.username;
		_result.avatar = _user.avatar;
                _result.score = _user.score;
		_result.cancheckin = _user.cancheckin;
		_result.openweibo = _user.openweibo;
		_result.openqq = _user.openqq;
		_result.contact = _user.contact;
		_result.shared = _user.shared;
		_result.lottery_count = _user.lottery_count;
		_result.lastlotteryday = _user.lastlotteryday;
		_result.nickname = _user.nickname or _user.username;
	else 
		if( imsi ) then
			local _imsiinfo = get_imsi_data( db, imsi );
			_result.guest =_imsiinfo;
		end;
		_result.result = _rcode;
        end;
	G_USERINFO = {};
	if( _result.username and G_WHITELIST[_result.username] ) then
		return nil;
	end;
	G_USERINFO = _result;
        return _result;
end;

function replace_list.JSVAR()
	local _ret = "";
	if( G_USERINFO ) then
		_ret = "var userinfo = "..cjson_safe.encode( G_USERINFO )..";\n";
	end;
	return _ret;
end;

function replace_list.USERNAME()
        return G_USERINFO.username or "<a class='loginpanel' href='javascript:do_login();this.blur();'>请登录</a>";
end;

function replace_list.NICKNAME()
	if( G_USERINFO.result == 0 ) then
		if( G_USERINFO.nickname ) then
			return G_USERINFO.nickname;
		else
			if type(G_USERINFO.openweibo) == "table" then
				return "微博用户";
			elseif type(G_USERINFO.openqqq) == "table" then
				return "QQ用户";
			else
				return "无名氏";
			end;
		end;
	else
        	return G_USERINFO.nickname or "<a class='loginpanel' href='javascript:do_login();this.blur();'>请登录</a>";
	end;
end;

function replace_list.GUESTNAME()
        return G_USERINFO.nickname or "游客";
end;

function replace_list.SCORE()
        return tostring(G_USERINFO.score or 0);
end;
function replace_list.SPEND()
        return tostring(G_USERINFO.spend or 0);
end;

function replace_list.USERDIV()
	local _ret = [[
	<div class="action-bar">
       	  <div class="name_info">
            <div class="name_info_01"><img src="/ui/imgs/user_head.png"/><span>]]..replace_list.NICKNAME()..[[</span></div>
            <div class="name_info_02"><img src="/ui/imgs/coin.png"/><span>]]..replace_list.SCORE()..[[积分</span></div>
          </div>
	</div>]];
	return _ret;
end;
function replace_list.GUESTDIV()
        local _ret = [[
        <div class="action-bar">
          <div class="name_info">
            <div class="name_info_01"><img src="/ui/imgs/user_head.png"/><span>]]..replace_list.GUESTNAME()..[[</span></div>
            <div class="name_info_02"><img src="/ui/imgs/coin.png"/><span>]]..replace_list.SCORE()..[[积分</span></div>
          </div>
        </div>]];
        return _ret;
end;
function html_replace( mm )
        if( type(replace_list[mm]) == "function" ) then
                return replace_list[mm]();
        end;
        return "";
end;
