local redis  = require('redis_pool_api')
local only   = require('only')
local scan   = require('scan')
local utils  = require('utils')
local json   = require('cjson')
local socket = require('socket')
local sha    = require('sha1')

local function gen_sign(T, secret)
        local kv_table = {}
        for k,v in pairs(T) do
        	if type(v) ~= "table" then
                	if k ~= "sign" then
                                print(k)
                    		table.insert(kv_table, k)
                	end
        	end
        end
        table.insert(kv_table, "secret")
        table.sort(kv_table)
        local sign_string = kv_table[1] .. T[kv_table[1]]
        for i = 2, #kv_table do
        	if kv_table[i] == 'secret' then
                	sign_string = sign_string .. kv_table[i] .. secret
        	else
                	sign_string = sign_string .. kv_table[i] .. T[kv_table[i]]
        	end
        end
        
        print(sign_string)
        local result = sha.sha1(sign_string)
        local sign_result = string.upper(result)
        
        return sign_result
end


local function send_data(cfg)
        status, res = pcall(json.decode, cfg.body)
        if status == nil then
                return
	end
	
	local appkey = '3055426974'
	--get secret--
	local secret  = '5C50FDD60E5261251A6135D1202F640030485EC0'
	res.appkey    = appkey
	res.accountid = 'xxxxxxxxxx'
	res.timestamp = '1445625467'
	
	local sign = gen_sign(res, secret)
	
	res['appkey'] = nil
	res['sign'] = nil
	res['accountid'] = nil
	res['timestamp'] = nil
	local http_body = json.encode(res)
	
	local tcp = socket.tcp()
	if tcp == nil then
		error('load tcp failed')
		return
	end
	
	local ret = tcp:connect(cfg.ip, cfg.port)
	if ret == nil then error('fail to connect to server')  return end
	
	local data = 'POST ' .. cfg.path ..  ' HTTP/1.0\r\n' ..
	'Host:stat.daoke.me\r\n' ..
	'Content-Length:' .. tostring(#http_body) .. '\r\n' ..
	'appkey:' .. appkey .. '\r\n' ..
	'sign:' .. sign .. '\r\n' ..
	'accountid:xxxxxxxxxx' ..'\r\n' ..
	'timestamp:1445625467' .. '\r\n' ..
	'Content-Type:application/x-www-form-urlencoded;charset=utf-8\r\n\r\n' ..
	http_body
	
	print(data)
	ret = tcp:send(data)
	-- print('tcp:send', ret)
	
	ret = tcp:receive('*a')
	print(ret)
	
	tcp:shutdown('both')
end

--功  能:url处理函数
--参  数:redis取出结果
--返回值:替换完成的table
local function url_process(arg)
	local ret = {}
	for k,v in ipairs(arg) do
		local_, member = pcall(json.decode, v)
--		only.log('D',string.format('member type is %s',type(member)))
--		only.log('D',string.format('member is %s',scan.dump(member)))
		repeat
		if type(member) == 'string' then
			break
		else
			local url = member['url'] or ""
--			only.log('D',string.format('url is %s', url))
		
			--替换%%为%
			local url_re = string.gsub(url,'%%%%','%%')
--			only.log('D',string.format('url gsub is %s', url))
			
			member['url'] = url_re
			table.insert(ret, member)
			break
		end
		until true
	end
	only.log('D',string.format('arg ret is %s', scan.dump(ret)))
	return ret	
end

--功能：

local function handle()

	--从redis取出所有的key
	local ok, keys = redis.cmd('rtr_redis','','keys','*')
	if not ok or not next(keys) then
		only.log('E','Get keys from redis error!')
		return
	end

	--将keys写入文件
	local file  = '/home/liu/keys'
	local f = assert(io.open(file,'w'))
	for k,v in ipairs(keys) do
		f:write(v,'\n')	
	end
	f:close()

	--逐个key调用新接口
	local iter_key = io.lines(file)      --iterator
	local cnt = 0
	while true do
		local key = iter_key()
		if key then
			only.log('D',string.format(
				'Key is %s ',scan.dump(key)))
		else
			break                --最后一个key
		end

		--从redis中取出member(set格式)
		local ok, ret = redis.cmd(
			'rtr_redis','','ZREVRANGEBYSCORE',key,'+inf','-inf'
		)
		if not ok or not next(ret) then
			only.log('E','Key:%s get data error!', scan.dump(key))
		end		

		--处理url
		local new_ret = url_process(ret)

		--删除原有key
--		local ok, ret_key = redis.cmd('rtr_redis','','DEL',key)		

		--调用API接口重新存入redis
		for k,v in ipairs(new_ret) do

--			only.log('D',string.format('v is %s', scan.dump(v)))
			
			local member = {}
			if not v["ok"] then
				member["longitude"] = v["longitude"]
				member["latitude"]  = v["latitude"]
				member["altitude"]  = v["altitude"] or 0
				member["speed"]     = v["speed"] or 0
				member["direction"] = v["direction"]
				member["GPSTime"]   = v["time"]
				member["url"]       = v["url"]
				member["ot"]        = "m"
				member["mediatype"] = v["mediatype"]
			else
				member["longitude"] = v["E"]
				member["latitude"]  = v["N"]
				member["altitude"]  = v["A"] or 0
				member["speed"]     = v["V"] or 0
				member["direction"] = v["D"]
				member["GPSTime"]   = v["T"]
				member["url"]       = v["ok"]
				member["ot"]        = v["ot"]
				member["mediatype"] = v["ft"]
			
			end

			only.log('D',string.format('member is %s', scan.dump(member)))

			--判断url为空值情况
			local url_ok = not (member["ok"] == "" or member["ok"] == "nil" or member[""] == "null")

			--2016-06-06 00：00：00 之后的数据
			if tonumber(member["GPSTime"] or 0) >= 1465142400 and url_ok then
				cnt = cnt + 1
				local _,body = pcall(json.encode, member)
		
				local cfg = {
--					ip   = 'mapapi.daoke.me',
					ip   = "127.0.0.1",	
					port = 80,
					path = '/rtrTraffic/v2/saveRtrPicBySgid',
					body = body
				}
				send_data(cfg)
			end
		end
	end
	print(cnt)
	only.log("D",string.format("count is %d", cnt))
end

handle()
