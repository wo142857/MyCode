local only  = require('only')
local utils = require('utils')
local redis = require('redis_pool_api')
local msg   = require('msg')
local gosay = require('gosay')
local ngx   = require('ngx')
local safe  = require('safe')
local scan  = require('scan')
local json  = require('cjson')
local mysql_api = require('mysql_pool_api')

local county_city = require ("table_county_city")

local NUM   = 20
local REDIS = 'RtrPic_v2'

local url_tab={
	type_name = 'system',
	app_key = nil,
	client_body = nil,
	client_host = nil,
}

local function checkParameter(args)

	safe.sign_check(args, url_tab)

    	if not args['SGID'] or not args['SGID'] == '' then
        	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'SGID')
    	elseif not args['sorttype'] or not args['sorttype'] == '' then
        	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'sorttype')
	elseif not args['resulttype'] or not args['resulttype'] == '' then
        	gosay.go_false(url_tab, msg['MSG_ERROR_REQ_ARG'], 'resulttype')
    	end
end

local function orderByDist(tab)
	if #tab == 0 then
		return tab
	end 
	local dir = tab[1]['direction']
	if dir >= 45 and dir < 135 then
		table.sort(tab, function(a,b)
			return tonumber(a["longitude"] or 0) < tonumber(b["longitude"] or 0)
		end)
	elseif dir >= 135 and dir < 225 then
		table.sort(tab, function(a,b)
			return tonumber(a["latitude"] or 0) > tonumber(b["latitude"] or 0)
		end)
	elseif dir >= 225 and dir < 315 then
		table.sort(tab, function(a,b)
			return tonumber(a["longitude"] or 0) > tonumber(b["longitude"] or 0)
		end)
	else
		table.sort(tab, function(a,b)
			return tonumber(a["latitude"] or 0) < tonumber(b["latitude"] or 0)
		end)
	end
	return tab
end

local function assign(ori_tab, ret_tab)
        ret_tab["ok"]          	= ori_tab["ok"]
        ret_tab["ot"]          	= ori_tab["ot"]
        ret_tab["speed"]       	= tonumber(ori_tab["speed"])
        ret_tab["direction"]   	= tonumber(ori_tab["direction"])
        ret_tab["weather"]     	= ori_tab["weather"]  
        ret_tab["temperature"] 	= tonumber(ori_tab["temperature"])
        ret_tab["altitude"]    	= tonumber(ori_tab["altitude"]) 
        ret_tab["mediatype"]   	= ori_tab["mediatype"]
        ret_tab["longitude"]   	= tonumber(ori_tab["longitude"])
        ret_tab["latitude"]    	= tonumber(ori_tab["latitude"])
        ret_tab["GPSTime"]     	= tonumber(ori_tab["GPSTime"])
        ret_tab["HT"]     	= tonumber(ori_tab["HT"])
end

local function getWeatherInfo(countyCode, GPSTime)
	--转换成cityCode
	local cityCode, weather, temperature
	
	cityCode = county_city.table_county_city[countyCode]

	only.log("D", string.format("cityCode is %s", cityCode))

	local cur_time = os.date('%Y-%m-%d',GPSTime)
        local select_weather_sql = string.format(
                'SELECT text, temperature FROM weatherInfo' ..
                " WHERE cityCode = %d and date = '%s 08:00:00';",
                cityCode, cur_time)
        local ok, ret_weather = mysql_api.cmd('weather','SELECT',select_weather_sql)

	only.log("D",string.format("weather: %s; %s", scan.dump(ret_weather or ''), scan.dump(select_weather_sql)))

        if not ok or not ret_weather then
                only.log('E', string.format('SELECT weather ERROR! %s', scan.dump(select_weather_sql)))
        elseif ok and not next(ret_weather) then
                weather     = ''
                temperature = 0
        elseif ok and next(ret_weather) then
		weather     = ret_weather[1]['text']
		temperature = ret_weather[1]['temperature']
        end
	return weather, temperature
end

local function getCountyCode(args)
	local ok, ret = redis.cmd('match_road', 'hmget', 'LOCATE', args['longitude'], args['latitude'], args['direction'])
	if ok and next(ret) then
		return ret[4]
	else
		return ''
	end
end

local function getSetN(set)
	local i = 0
	for k,v in pairs(set) do
		i = i + 1
	end
	return i
end

local function getRTInfo(time, cur_time)
	only.log("D","%s, %s", time, cur_time)	
	-- 15分钟
	local point_time = cur_time - 900

	if time >= point_time then
		return 0
	else
		return 1
	end
end

local function zincrby (parameter)
	local ok, ret = redis.cmd("rtr_pic_count", "ZINCRBY", parameter["key"], parameter["incr"], parameter["member"])
	if not ok or not ret then return nil end
	
	return true
end

local function counter(parameter)
	
	local date = os.date("%Y-%m-%d")

	--> 某用户的图片某天被请求计数
	local user_ok = true
	if parameter["accountID"] then
		local user_pic_count = {
				key	= string.format("%s:userPicDownCount", date),
				incr	= 1,
				member	= parameter["accountID"],
		}
		
		user_ok =  zincrby(user_pic_count)
	end
	
	--> 某图片被请求计数
	local pic_count = {
			key	= "PicDownCount",
			incr	= 1,
			member	= string.format("%s,%s", parameter["ok"], parameter["ot"])
	}
	local pic_ok = zincrby(pic_count)
		
	return user_ok or pic_ok

end

local function getCam(key,sorttype,resulttype)
	--从redis里获取,1小时以内的照片
   	local max = os.time()		--当前时间戳
   	local min = max - 604800	--7天以前时间戳
--    	local max = '+inf'		--当前时间戳
--    	local min = '-inf'		--1小时以前时间戳
	local ok, info = redis.cmd(REDIS,'ZREVRANGEBYSCORE',key,max,min,'LIMIT',0,NUM)
    	if not ok or not info then
       		only.log('E','ZREVRANGEBYSCORE false!')
		gosay.go_false(url_tab,msg['MSG_DO_REDIS_FAILED'])
    	end

	--解析member
	local tmp = {}
	local url_set = {}
	for k,v in ipairs(info) do
		local _, mem = pcall(json.decode, v)
		
		--url去重
	 	local url_cnt_init = getSetN(url_set)
  		local url = mem['ok'] or ''
   		url_set[url] = true
    		local url_cnt_add = getSetN(url_set)
		only.log('D','url set cnt is init:%d, add:%d', url_cnt_init,url_cnt_add)

		--添加天气信息,实时信息
		local countyCode = getCountyCode(mem)
     		if url_cnt_init + 1 == url_cnt_add then
			if countyCode ~= '' then
				mem['weather'], mem['temperature'] = getWeatherInfo(countyCode, mem['GPSTime'])
				mem['HT'] = getRTInfo(mem['GPSTime'], max)
			end

			--> counter
			local ok_counter = counter(mem)
			if not ok_counter then
				only.log("E", "something wrong in counter!")
			end

			table.insert(tmp,mem)
		end
	end

	only.log('D', 'tmp origin is %s',scan.dump(tmp))

	--根据sorttype排序
	if sorttype == 0 then     --根据时间排序
		sort_ret = tmp
	elseif sorttype == 1 then --根据距离排序
		sort_ret = orderByDist(tmp)
	end

	only.log('D', 'sort_ret  = %s', scan.dump(sort_ret))

	--根据resulttype返回对应值
	local media_ret = {["rtrpic"] = {}}
	if resulttype == 0 then                --pic
		local j = 1
		for k,v in pairs(sort_ret) do
			local mark = v["mediatype"]
			if mark == 'jpg' or mark == 'png' then
				media_ret["rtrpic"][j] = {}
				assign(v,media_ret["rtrpic"][j])
				j = j + 1
			end
		end
	elseif resulttype == 1 then            --video
		local j = 1 
    		for k,v in pairs(sort_ret) do
			local mark = v["mediatype"]
			if mark == 'mp4' or mark == 'avi' then
				media_ret["rtrpic"][j] = {}
				assign(v,media_ret["rtrpic"][j])
				j = j + 1
			end
		end
	elseif resulttype == 2 then            --pic&video
		local j = 1 
    		for k,v in pairs(sort_ret) do
			media_ret["rtrpic"][j] = {}
			assign(v,media_ret["rtrpic"][j])
			j = j + 1
		end
	end
	
	only.log('D','media_ret is %s',scan.dump((media_ret)))
	
	return media_ret
end 

local function handle()
	only.log('D',"API START")
	local req_method = ngx.var.request_method
	local req_header = ngx.req.get_headers()
	only.log('D',"req_header is %s",scan.dump(req_header))
	local body, args
	if req_method == 'POST' then
        	body = ngx.req.get_body_data()
		only.log('D',"body is %s",scan.dump(body))

        	if not body then
            		gosay.go_false(url_tab, msg["SYSTEM_ERROR"])
        	end
        	ok, args = pcall(json.decode, body)
	else
        	args = ngx.req.get_uri_args()
    	end
    	url_tab['client_host'] = ngx.var.remote_addr
    	url_tab['client_body'] = body
    	url_tab['app_key'] = req_header['appKey']
	
	args['appKey'] = req_header['appKey'] or ''
	args['sign'] = req_header['sign'] or ''
	args['timestamp'] = req_header['timestamp'] or ''
	args['accountID'] = req_header['accountID'] or ''

    	checkParameter(args)

	local sorttype = tonumber(args['sorttype'])
	local resulttype = tonumber(args['resulttype'])

	local sgid_list = utils.str_split(args['SGID'], ',')	
	
	local result = {SGPic = {}}
	local tmp_table = {}
	for i = 1, #sgid_list do
		local tmp_table = {}
		local sgid = tonumber(sgid_list[i])
		
		local key = string.format('%d:CamTraffic', sgid)
		only.log('D','key is %s',scan.dump(key))
	    	local tab = getCam(key,sorttype,resulttype)

		tmp_table = {SGID = sgid ,rtrpic = tab['rtrpic']}

		table.insert(result["SGPic"], tmp_table)
	end

	only.log('D','last table is %s',scan.dump(result))
	local ok,table =pcall(json.encode,result)
	if not ok or not table then
		only.log('E', 'json the end encode error!')
		return
	end
	table = string.gsub(table,'{}','[]')
	gosay.go_success(url_tab, msg['MSG_SUCCESS_WITH_RESULT'], table)

end

safe.main_call(handle)
