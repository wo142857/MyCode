-- get msg array

package.path    = package.path .. ';./open/?.lua;'
package.cpath   = package.cpath .. ';./open/?.so;'

local copas     = require('copas')
local redis     = require('redis')
local http      = require('socket.http')
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
    end
    return client
end

local function rand(cnt)
    -- 防止集体拥堵
    -- math.randomseed(os.time())
    return (math.random(0, 10000 * math.modf(cnt / config.max_num.radix)) * 0.000001)
end

local function push_first_func(request)
    for i = 1, 3 do
        local req   = config.api.push_first
        local request_body  = cjson.encode(request)
        local response_body = {}

        req.source  = ltn12.source.string(request_body)
        req.sink    = ltn12.sink.table(response_body)
        req.create  = req.create and nil
        req.headers["Content-Length"] = #request_body                                           

        local res, code, headers, status = http.request(req)                                   
        if code == 200 then
            log.D('get response body: ' .. scan.dump(response_body))
            local response = cjson.decode(table.concat(response_body, ''))
            if response.Code == 0 and response.Result.rCode == 0 then
                return response.Result.stop
            end
            break
        else
            if i == 3 then
                local client = redis_connect()
                local r, e = client:lpush(config.redis.pushagain,
                    cjson.encode(msg_tab))
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
                return
            end
        end
    end
end

repeat
    local t1 = os.time()
    local client = redis_connect()
    if not client then return end
    local ret, err = client:brpop(config.redis.pushcom, 0)
    if not ret then
        log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
        return
    end
    ret = cjson.decode(ret[2])
    log.D('brpop' .. scan.dump(ret))
    
    -- 请求推送接口
    local stop
    repeat
        local request_body = {
            msgId   = ret.msgId,
        }
        stop = push_first_func(request_body, ret)
        if not stop then
            os.execute('sleep 1')
        end
    until stop and (tonumber(stop) == 1)

    -- androi 类型需要插入重发队列
    if ret.ostype or (ret.ostype == 1) then
        local client = redis_connect()
        local r, e = client:lpush(config.redis.pushagain, cjson.encode{
            msgId   = ret.msgId,
            try     = 1,
            modify  = os.time(),
        })
        if not r then
            log.E('fail to lpush to push again task list: ' .. e)
            log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
        end
    end                                                        
    log.D('stop: ' .. (os.time() - t1))
until false
