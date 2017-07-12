-- 重发队列

package.path    = package.path .. ';/data/web/push_script/open/?.lua;'
package.cpath   = package.cpath .. ';/data/web/push_script/open/?.so;'

local redis     = require('redis')
local http      = require('ssl.https')  -- 线上环境配置了局域网访问，需要改成 socket.http
local ltn12     = require('ltn12')
local cjson     = require('cjson')
local common    = require('common')
local config    = require('config')
local log       = require('log')
local scan      = require('scan')
local zero      = require('debug_zero')

local function handle()
    for k, v in pairs(zero.api) do
        log.D('API name: ' .. k)
        if v.method == 'POST' then
            local request   = v.request
            v.request = nil
            local req   = v
            local request_body  = cjson.encode(request)
            local response_body = {}

            req.source  = ltn12.source.string(request_body)
            req.sink    = ltn12.sink.table(response_body)
            req.create  = req.create and nil
            req.headers["Content-Length"] = #request_body                                           

            local res, code, headers, status = http.request(req)                                   
            
            log.D('get response body: ' .. scan.dump(response_body))
            log.D('res: ' .. scan.dump(res) .. '; code: ' .. scan.dump(code)
                .. '; headers: ' .. scan.dump(headers)
                .. '; status: ' .. scan.dump(status))
        elseif v.method == 'GET' then
            local response_body = {}
            v.sink    = ltn12.sink.table(response_body)
            local res, code, headers, status = http.request(v)                                   
            
            log.D('get response body: ' .. scan.dump(response_body))
            log.D('res: ' .. scan.dump(res) .. '; code: ' .. scan.dump(code)
                .. '; headers: ' .. scan.dump(headers)
                .. '; status: ' .. scan.dump(status))
        end
    end
end

handle()
