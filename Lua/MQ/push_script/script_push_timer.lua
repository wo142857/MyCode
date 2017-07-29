-- get msg array

package.path    = package.path .. ';./open/?.lua;'
package.cpath   = package.cpath .. ';./open/?.so;'

local redis     = require('redis')
local cjson     = require('cjson')
local common    = require('common')
local config    = require('config')
local log       = require('log')
local scan      = require('scan')

local client = redis.connect{
    host    = config.redis.host,
    port    = config.redis.port,
}
if not client then
    log.E(common.resp(config.errnu.REDIS_CONNECT_ERROR))
    return
end

repeat
    local ret, err = client:brpop(config.redis.pushtimer, 0)
    if not ret then
        log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
        return
    end
    ret = cjson.decode(ret[2])
    log.D('brpop' .. scan.dump(ret))
    local t1 = os.time()

    if t1 < tonumber(ret.timer) then
        local ok, err = client:lpush(config.redis.pushtimer, cjson.encode{
            msgId   = ret.msgId,
            timer   = ret.timer,
            count   = ret.count,
            ostype  = ret.ostype,
            expand  = ret.expand,
        })
        if not ok then
            log.E('fail to lpush to push timer task list: ' .. e)
            log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
            return
        end
        os.execute('sleep 5')
    else
        --[[ androi 单播消息插入重发队列
        if ret.expand and (ret.ostype == 1) then
            local r, e = client:rpush(config.redis.pushagain, cjson.encode{
                msgId   = ret.msgId,
                try     = 1,
                modify  = os.time(),
            })
            if not r then
                log.E('fail to rpush to push again task list: ' .. e)
                log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
            end
        else]]
            if ret.count <= 10000 then
                local ok, err = client:rpush(config.redis.getpri, cjson.encode{
                        msgId   = ret.msgId,
                        count   = ret.count,
                        ostype  = ret.ostype,
                    })
                if not ok then
                    log.E('fail to rpush to push get pri task list: ' .. e)
                    log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
                end
            elseif ret.count <= 100000 then
                local ok, err = client:rpush(config.redis.getcom, cjson.encode{
                        msgId   = ret.msgId,
                        count   = ret.count,
                        ostype  = ret.ostype,
                    })
                if not ok then
                    log.E('fail to rpush to push get com task list: ' .. e)
                    log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
                end
            else
                local ok, err = client:rpush(config.redis.gethug, cjson.encode{
                        msgId   = ret.msgId,
                        count   = ret.count,
                        ostype  = ret.ostype,
                    })
                if not ok then
                    log.E('fail to rpush to push get hug task list: ' .. e)
                    log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
                end
            end
        --end                                                                             
    end
until false
