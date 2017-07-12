-- get msg array

package.path    = package.path .. ';./open/?.lua;'
package.cpath   = package.cpath .. ';./open/?.so;'

local copas     = require('copas')
local redis     = require('redis')
local http      = require('copas.http')
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

local function unfold_func(request, msg_tab)
    log.D('unfold request: ' .. scan.dump(request))
    -- local mark
    for i = 1, 3 do
        local req   = config.api.get_uri
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
                -- mark = response.Result.lastId
                return response.Result.lastId, response.Result.stop
	    end

	    if response.Code ~= 0 then
                client = nil
                client = redis_connect()
                local r, e = client:lpush(config.redis.gethug,
                    cjson.encode(msg_tab))
                if not r then
                    log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
                end
            end
            break
        else
            if i == 3 then
                --[[
                msg_tab.id      = mark
                msg_tab.count   = msg_tab.count - msg_tab.offset
                ]]
                local client = redis_connect()
                local r, e = client:lpush(config.redis.gethug,
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

local function push_first_func(request, msg_tab)
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
            log.D('push first success!')
            break
        else
            if i == 3 then
                local client = redis_connect()
                local r, e = client:lpush(config.redis.gethug,
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

local function handle(msg_tab)
    if not msg_tab then return end
    -- 请求展开并第一次推送接口
    --[[
    local off   = msg_tab.off or 0
    local size  = config.max_num.get
    ]]
    local id, stop
    local n = 0

    repeat
        n = n + 1
        local request_body  = {
            msgId   = msg_tab.msgId,
            lastId  = msg_tab.id or id,
            --[[
            size    = size,
            ]]
        }
        -- 请求展开接口
        id, stop = unfold_func(request_body, msg_tab)
        if not id or not stop then
            log.E(common.resp(config.errnu.HTTPS_REQUEST_ERROR))
            return
        end

        if not stop then
            local client = redis_connect()
            local r, e = client:lpush(config.redis.gethug, cjson.encode(msg_tab))
            if not r then
                log.E('fail to lpush to get hug task list: ' .. e)
                log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
            end
        end

        --[[
        if n == 1 then
            -- 首次请求成功后插入下发队列
            local client = redis_connect()
            local r, e = client:lpush(config.redis.pushhug, cjson.encode(msg_tab))
            if not r then
                log.E('fail to lpush to push hug task list: ' .. e)
                log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
            end
        end
        ]]

        --[[
        -- 请求第一次推送接口
        push_first_func({
            msgId   = msg_tab.msgId,
        }, mst_tab)]]
        --[[
        off = off + size
        msg_tab.count = msg_tab.count - msg_tab.offset
        ]]
    until stop and (tonumber(stop) == 1)

    n = 0
    -- androi 类型需要插入重发队列
    if msg_tab.ostype or (msg_tab.ostype == 1) then
        local client = redis_connect()
        local r, e = client:lpush(config.redis.pushagain, cjson.encode{
            msgId   = msg_tab.msgId,
            try     = 1,
            modify  = os.time(),
        })
        if not r then
            log.E('fail to lpush to push again task list: ' .. e)
            log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
        end
    end
end

repeat
    local t1 = os.time()
    local client = redis_connect()
    if not client then return end
    local ret, err = client:brpop(config.redis.gethug, 0)
    if not ret then
        break
    end
    ret = ret[2] and cjson.decode(ret[2]) or nil
    log.D('brpop' .. scan.dump(ret))
    copas.addthread(handle, ret)
    client = nil
    copas.loop()
    log.D('stop: ' .. (os.time() - t1))
until false
