local redis = require('redis_pool_api')
local mysql = require('mysql_pool_api')
local only  = require('only')
local utils = require('utils')
local gosay = require('gosay')
local msg   = require('msg')
local ngx   = require('ngx')
local safe  = require('safe')
local scan  = require('scan')
local json  = require('cjson')

local T_MAX = 10000
local P_MAX = 1000
local REDIS = 'RtrPic_v2'

local Send = require ("SendChannelMsg")

local url_tab={
	type_name = 'system',
	app_key = nil,
	client_body = nil,
	client_host = nil,
}
local function checkParameter(args)
	if not args['ml'] then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'ml')
	end
	if args['ml'] then
		for k,v in ipairs(args['ml']) do
			if not v['ft'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'ft')
			elseif not v['ok'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'ok')
			elseif not v['ot'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'ot')
			elseif not v['T'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'T')
			elseif not v['N'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'N')
			elseif not v['E'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'E')
			elseif not v['V'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'V')
			elseif not v['A'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'A')
			elseif not v['D'] then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'D')
			end

			if v['ft'] ~= 'jpg' and v['ft'] ~= 'png' then
			        gosay.go_false(url_tab,msg['MSG_ERROR_REQ_ARG'],'ft type error!')
			end
		end
	end
end

local function linkPMR(lon, lat, dir)
	local lon = tonumber(lon)
	local lat = tonumber(lat)
	local dir = tonumber(dir)

	local ok, ret = redis.cmd('match_road','hmget','LOCATE',lon,lat,dir)
	
	only.log('D',string.format('ret is %s',scan.dump(ret)))

	return ret
end

local function toStore(key, score, member)
	local _, str_member = pcall(json.encode,member) 
	only.log('D','member is %s',scan.dump(member))
	
	--判断已有数量超限
	local min   = '-inf'	
	local max   = '+inf'
	local ok, cnt = redis.cmd(REDIS,'ZCOUNT',key,min,max)  --获取统计值
	if not ok or not cnt then
        	only.log('E','ZCOUNT false!')
		return
	end
	
	if tonumber(cnt) >= P_MAX then
        	local ok, rem_num = redis.cmd(REDIS,'ZREMRANGEBYRANK',key,0,0) --删除时间最早一条记录
        	if not ok or not rem_num then 
        		only.log('E','ZREMRANGEBYRANK false!')
			return
        	end
		
        	local ok, zadd_num = redis.cmd(REDIS,'ZADD',key,score,str_member)  --以有序队列存入
        	if not ok or not zadd_num then
        		only.log('E','ZADD false!')
			return
        	end
    	else
        	local ok, zadd_num = redis.cmd(REDIS,'ZADD',key,score,str_member)
        	if not ok or not zadd_num then
            		only.log('E','ZADD false!')
			return
        	end
	end
end

local function zincrby (parameter)
	local ok, ret = redis.cmd("rtr_pic_count", "ZINCRBY", parameter["key"], parameter["incr"], parameter["member"])
	if not ok or not ret then return nil end
	
	return true
end

local function getCityCode (countyCode)
	if math.floor(countyCode / 10000) == 11 then
		return 110000     --北京市
	elseif math.floor(countyCode / 10000) == 12 then
		return 120000     --天津市
	elseif math.floor(countyCode / 10000) == 31 then
		return 310000     --上海市
	elseif math.floor(countyCode / 10000) == 50 then
		return 500000     --重庆市
	else
		return math.floor(countyCode / 100) * 100
	end
end

local function counter(parameter)
	
	local date = os.date("%Y-%m-%d")

	if parameter["county"] then		-- 上传成功
		--> 某用户某天上传图片计数
		local user_pic_count = {
				key	= string.format("%s:userPicUpOkCount", date),
				incr	= 1,
				member	= parameter["user"],
		}
		local user_ok = zincrby(user_pic_count)
	
		--> 某appKey某天上传图片计数
		local app_pic_count = {
				key	= string.format("%s:appKeyPicUpOkCount", date),
				incr	= 1,
				member	= parameter["appkey"],
		}
		local app_ok = zincrby(app_pic_count)

		--> 某地区某天上传图片计数
		local cityCode = getCityCode(tonumber(parameter["county"]))

		local city_pic_count = {
				key	= string.format("%s:cityPicUpOkCount", date),
				incr	= 1,
				member	= cityCode,
		}
		local city_ok = zincrby(city_pic_count)

		return user_ok or app_ok or city_ok
	else					-- 上传失败
		--> 某用户某天上传图片计数
		local user_pic_count = {
				key	= string.format("%s:userPicUpFailCount", date),
				incr	= 1,
				member	= parameter["user"],
		}
		local user_ok = zincrby(user_pic_count)
		
		--> 某appKey某天上传图片计数
		local app_pic_count = {
				key	= string.format("%s:appKeyPicUpFailCount", date),
				incr	= 1,
				member	= parameter["appkey"],
		}

		local app_ok = zincrby(app_pic_count)

		return user_ok or app_ok

	end	
end


local function handle()
	only.log('D','API START')
	local req_method = ngx.var.request_method
	local req_header = ngx.req.get_headers()
	only.log('D',string.format('req_header is %s',scan.dump(req_header)))

	local body, args
	if req_method == 'POST' then
		body = ngx.req.get_body_data()
        	if not body then
        		gosay.go_false(url_tab, msg['SYSTEM_ERROR'])
        	end
		args = json.decode(body)
		only.log('D',string.format('body args is %s',scan.dump(args)))
	else
        	args = ngx.req.get_uri_args()
	end
	url_tab['client_host'] = ngx.var.remote_addr
	url_tab['client_body'] = body
	url_tab['app_key'] = req_header['appKey']

	local sign_tab = {}
	sign_tab['appKey'] = req_header['appKey'] or ''
	sign_tab['sign'] = req_header['sign'] or ''
	sign_tab['timestamp'] = req_header['timestamp'] or ''
	sign_tab['accountID'] = req_header['accountID'] or ''
	sign_tab['tokenCode'] = req_header['tokenCode'] or ''

	safe.sign_check(sign_tab, url_tab)

--	safe.token_check(sign_tab, url_tab)

	checkParameter(args)
    
	--CountInfo
	local cur_time = os.time()
	local cur_day = os.date('%Y-%m-%d',cur_time)  --以天为单位
	local appKey = req_header['appKey']
	
	local i = 0

	for k,v in pairs(args["ml"]) do
		repeat	
	        --INCR key_cnt
		local pic_sour = v['ot']   --平台编号
		local key_cnt = string.format(
		        '%s:%s:%s:cnt',
	        	appKey, cur_day, pic_sour)
	
		local ok, ret = redis.cmd('rtr_pic_count','INCR',key_cnt)     

		local member = {}
		member["GPSTime"]   = v["T"]
		member["longitude"] = v["E"]
		member["latitude"]  = v["N"]
		member["direction"] = v["D"]
		member["ok"]        = v["ok"]
		member["ot"]        = v["ot"]
		member["mediatype"] = v["ft"]
		member["altitude"]  = v["A"]
		member["speed"]     = v["V"]
		member["accountID"] = req_header["accountID"]

		--PMR
		local lon = member["longitude"]
		local lat = member["latitude"]
		local dir = member["direction"]
		local road_info = linkPMR(lon, lat, dir)
		local RR = road_info[1]
		local SG = road_info[2]
		local cc = road_info[4]

		--> counter
		local parameter = {
			user	= req_header["accountID"],
			appkey	= req_header["appKey"],
			county	= cc,
		}
	
		local ok_count = counter(parameter)
		if not ok_count then only.log("E", "counter something wrong!") end

		if not RR or not SG then
			break
		end
		member["weather"], member["temperature"] = '', 0
	
		--> 消息推送
		local groupid_city	= string.format("LC%d", math.floor(tonumber(cc) / 100) * 100)
		local groupid_rr	= string.format("LR%d", RR)
		local groupid_sg	= string.format("LS%d%03d", RR, SG)
	
		--> get road name
		local ok_name, ret_name = redis.cmd("mapSGInfo", "HGETALL", string.format("%d,%d:SGInfo", RR, SG))
		if not ok_name or not ret_name then
			only.log("E", "get SGID name error!")
		end
	
		only.log("D",string.format("SGInfo is %s.", scan.dump(ret_name)))
	
		local sgbegin, sgend = ret_name["SGSC"], ret_name["SGEC"]
	
		local ok_msg_send = Send.MsgSend {
					opt	= "msg",
					groupID	= string.format("%s,%s,%s",groupid_city, groupid_rr, groupid_sg),
					msgType	= "DL",
					msgObj	= {
						SGID		= tonumber(string.format("%d%03d", RR, SG)),
						roadID		= tonumber(RR),
						roadName	= road_info[6],
						cityCode	= math.floor(tonumber(cc) / 100) * 100,
						sgbegin		= sgbegin,
						sgend		= sgend,
						lon		= tonumber(lon),
						lat		= tonumber(lat),
						alt		= tonumber(member["altitude"]),
						speed		= tonumber(member["speed"]),
						dir		= tonumber(dir),
						updateTime	= tonumber(member["GPSTime"]),
						ok		= member["ok"],
						ot		= member["ot"],
						mediatype	= member["mediatype"],
						userID		= req_header["accountID"],
					},
					appKey		= req_header["appKey"],
					accountID	= req_header["accountID"],
					timestamp 	= req_header["timestamp"],
					sign 		= req_header["sign"],
		}
	
		only.log("D", string.format("send result: %s", scan.dump(ok_msg_send)))
	

		--存入redis
		local key   = string.format("%d%03d:CamTraffic",RR,SG)
		local sgid  = string.format("%d%03d",RR,SG)
		local score = tonumber(member["GPSTime"])
		toStore(key, score, member)
		i = i + 1
		break
		until true
	end
	if i == 0 then
		gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'PMR定位失败！')
	end
	gosay.go_success(url_tab,msg['MSG_SUCCESS'])
end    
safe.main_call(handle)
