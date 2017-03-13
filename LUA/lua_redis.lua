-- get msg array

package.path    = package.path .. ';./open/?.lua;'
package.cpath   = package.cpath .. ';./open/?.so;'

local redis     = require('redis')
local https     = require('ssl.https')
local ltn12     = require('ltn12')
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
    local ret, err = client:brpop(config.redis.msgkey, 0)
    if not ret then
        log.E(common.resp(config.errnu.REDIS_DO_BRPOP_ERROR))
        return
    end
    log.D('brpop' .. scan.dump(ret))
    local taskid = ret[2]
    local off, flag = 1, 0
    repeat
        do
            local response_body = {}
            local request_body  = cjson.encode{
                                    taskId  = taskid,
                                    off     = off,
                                    size    = config.max_num.get,
                                }
            
            log.D('send request body: ' .. scan.dump(request_body))
            local req   = config.api.get_uri
            --[[
            get_uri     = {
                url     = 'https://10.0.10.213:443/api/v2/expandMsg',
                method  = 'POST',
                headers = {
                    ["X-Droi-Api-Key"]  = "W2vVljBc9saFa_YKnVWluidVepZfuBj1VDi2NVQiV6bMW-Kq0X8wXpiY2rMosens",
                    ["X-Droi-AppID"]    = "s67umbzhzR8Tb8bdpDcvqgOXnNSv4PLOlQDjbYwJ",
                    ["X-Droi-DeviceID"] = "5c5813c14145406aa6a87b87e8ecd277",
                    ["Content-Type"]    = "application/json",
                },
            }
            ]]

            req.source  = ltn12.source.string(request_body)
            req.sink    = ltn12.sink.table(response_body)
            req.create  = req.create and nil
            req.headers["Content-Length"] = #request_body
            
            local res, code, headers, status = https.request(req)
            if code ~= 200 then
                log.E(common.resp(config.errnu.HTTPS_REQUEST_ERROR))
            end
    
            log.D('get response body: ' .. scan.dump(response_body))
    
            -- 防止返回长度过长的数组结构
            local response = cjson.decode(table.concat(response_body, ''))
            if response.Code == 0 and response.Result.list then
                -- 遍历单个插入
                for k, v in ipairs(response.Result.list) do
                    local r, e = client:lpush(config.redis.pushkey, cjson.encode{taskid, v})
                    if not r then
                        log.E('fail to lpush to task list: ' .. e)
                        log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
                    end
                end

                -- 批量插入
                -- 调用 loadstring 函数，字符串中的变量都为全局变量
                --[[
                client  = client
                key     = config.redis.pushkey
                local str = 'client:lpush(key'
                for k, v in ipairs(response.Result.list) do
                    str = str .. ', ' .. v
                end
                str = str .. ')'
                local fr, fe = assert(loadstring(str))()
                if not fr then
                    log.E('fail to lpush to task list: ' .. e)
                    log.E(common.resp(config.errnu.REDIS_DO_LPUSH_ERROR))
                end
                ]]

                flag = response.Result.stop
            else
                break
            end
        end    
        off = off - 1 + config.max_num.get
    until flag == 1
until false
