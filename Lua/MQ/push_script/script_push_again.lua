-- 重发队列

package.path    = package.path .. ';./open/?.lua;'
package.cpath   = package.cpath .. ';./open/?.so;'

local redis     = require('redis')
local http      = require('socket.http')  -- 线上环境配置了局域网访问，需要改成 socket.http
local ltn12     = require('ltn12')
local cjson     = require('cjson')
local common    = require('common')
local config    = require('config')
local log       = require('log')
local scan      = require('scan')

local threads   = {}

local function redis_connect()
    local client = redis.connect{
        host    = config.redis.host,
        port    = config.redis.port,
    }
    if not client then
        log.E(common.resp(config.errnu.REDIS_CONNECT_ERROR))
        return
    end
    return client
end

local client = redis_connect()

local function handle(request, ret)
    log.D('response: ' .. scan.dump(request))
    log.D('ret: ' .. scan.dump(ret))
    for i = 1, 3 do
        local req   = config.api.push_again
        local request_body  = cjson.encode(request)
        local response_body = {}

        req.source  = ltn12.source.string(request_body)
        req.sink    = ltn12.sink.table(response_body)
        req.create  = req.create and nil
        req.headers["Content-Length"] = #request_body                                           

        -- os.execute('sleep ' .. math.random(1, 1000) * 0.001)
        local res, code, headers, status = http.request(req)                                   
        if code == 200 then
            log.D('get response body: ' .. scan.dump(response_body))
            local response = cjson.decode(table.concat(response_body, ''))
            if response.Code == 0 and response.Result.rCode == 0 then
                if response.Result.stop and (response.Result.stop == 1) then
                    -- 本次下发重发，插入重发队列末尾
                    if response.Result.goon then
                        client = nil
                        client = redis_connect()
                        local r, e = client:lpush(config.redis.pushagain,
                            cjson.encode(ret))
                        if not r then
                            log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
                        end
                    end
                else
                    -- 防止异常信息造成的死循环
                    if config.max_num.max <= request.off then break end
                    -- 重发消息需要继续展开
                    request.off = request.off + request.size
                    handle(request, ret)
                end
	    else
                client = nil
                client = redis_connect()
                local r, e = client:lpush(config.redis.pushagain,
                    cjson.encode(ret))
                if not r then
                    log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
                end
            end
            break
        else
            if i == 3 then
                local r, e = client:lpush(config.redis.pushagain,
                    cjson.encode(ret))
                if not r then
                    log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
                    return
                end
                log.E(common.resp(config.errnu.HTTPS_REQUEST_ERROR))
                log.E(cjson.encode{
                    res     = res,
                    code    = code,
                    headers = headers,
                    status  = status,
                    respon  = response,
                    off     = request.off,
                })
            end
        end
    end
end

local function sorted_queue()
    local client = redis_connect()
    local ret, err = client:lrange(config.redis.pushagain, 0, -1)
    if not ret then
        return
    end
    client:del(config.redis.pushagain)
    for k, v in pairs(ret) do
        v = cjson.decode(v)
        if 'table' ~= type(v) then break end
        client:zadd(config.redis.sorted, v.modify, cjson.encode(v))
    end
    local r, e = client:zrangebyscore(config.redis.sorted, '-inf', '+inf')
    if not r then
        return
    end
    for k, v in pairs(r) do
        client:lpush(config.redis.pushagain, v)
    end
    client:del(config.redis.sorted)
end

repeat
    repeat
        client = nil
        client = redis_connect()
        local ret, err = client:brpop(config.redis.pushagain, 0)
        if not ret then
            log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
            return
        end

        ret = cjson.decode(ret[2])
        log.D('again task list brpop: ' .. scan.dump(ret))
        
        local null_flag
        if 'table' ~= type(ret) then break end

        repeat
            -- 重发时间间隔
            if os.time() < ret.modify then
                -- 重发队列排序
                local st = ret.modify - os.time() - 1
                if st >= config.max_num.wait then
                    sorted_queue()
                end

                -- 队列循环时间按重发时间间隔控制
                client = nil
                --[[ sleep 直到下次重发的前一秒
                local st = ret.modify + (config.max_num.again * ret.try) 
                    - os.time() - 1
                -- sleep 时间范围：1 --> 重发常量
                st = (st < 0) and 1 or st
                st = (st > config.max_num.again) and (config.max_num.again) or st
                --os.execute('sleep ' .. st)]]
                os.execute('sleep 5')

                client = redis_connect()
                -- 插入重发队列末尾
                local r, e = client:lpush(config.redis.pushagain,
                    cjson.encode(ret))
                if not r then
                    log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
                    return
                end
                break
            else
                ret.try     = ret.try + 1

                local delay = config.max_num.again * 
                    (ret.try > 5 and 5 or ret.try)
                ret.modify  = os.time() + delay
        
                local off, size = ret.off or 0, config.max_num.push
                local request_body  = {
                    msgId   = ret.msgId,
                    off     = off,
                    size    = size,
                }
        
                handle(request_body, ret)
            end
        until true
    until not null_flag -- 防止异常数据
until false
