-- get msg array

package.path    = package.path .. ';./open/?.lua;'
package.cpath   = package.cpath .. ';./open/?.so;'

local https     = require('ssl.https')
local http     	= require('socket.http')
local ltn12     = require('ltn12')
local cjson     = require('cjson')
local common    = require('common')
local config    = require('config')
local log       = require('log')
local scan      = require('scan')

for i = 1, 3 do
    local req   = config.api.clean_record_job
    local request       = {}
    local request_body  = cjson.encode(request)
    local response_body = {}

    req.source  = ltn12.source.string(request_body)
    req.sink    = ltn12.sink.table(response_body)
    req.create  = req.create and nil
    req.headers["Content-Length"] = #request_body                                           

    local res, code, headers, status = http.request(req)                                   
    if code == 200 then
        local response = cjson.decode(table.concat(response_body, ''))
        if response.Code ~= 0 then
            log.E('API server error: ' .. e)
            log.E(common.resp(config.errnu.API_RECIEVE_ERROR))
        end
        os.exit(0)
    else
        -- 三次重发
        if i == 3 then
            log.E(common.resp(config.errnu.HTTPS_REQUEST_ERROR))
            log.E(cjson.encode{
                res     = res,
                code    = code,
                headers = headers,
                status  = status,
                respon  = response,
            })
            os.exit(10)
        end
    end
end
