-- @author: wo142857@droi.com
-- @brief:  LOG日志函数

local cfg   = require("config")
local scan  = require("scan")
local _M    = {}

local function util_split(s, p)
    local rt= {}
    string.gsub(s, '[^'..p..']+', function(w) table.insert(rt, w) end )
    return rt
end

local function split(fullname)
    local f = util_split(fullname, "/")
    return util_split(f[#f], ".")[1]
end

local function seek_file_name()
    local n, ret = 1, {}
    local f_name, f_info = '', ''
    while true do
        local info = debug.getinfo(n, "Sl")
        if not info then
            ret["filename"] = f_name
            ret["fileinfo"] = f_info
            return ret
        else
            f_name          = ret['filename']
            f_info          = ret['fileinfo']
            local filename  = split(info.short_src)
            ret["filename"] = filename
            ret["fileinfo"] = filename .. ":" .. info.currentline
        end
        n = n + 1
    end
end

local function msg_format(level, msg)
    -- 格式化
    local time      = os.date("%Y-%m-%d %H:%M:%S") 
    local log_info  = seek_file_name()["fileinfo"]

    return string.format(
        cfg.log.pattern,
        level,
        time,
        log_info,
        msg
    )
end

local function log_file(level, msg)
    local errmsg    = msg_format(level, msg)
    local name      = seek_file_name()["filename"]
    local time      = os.date("%Y%m")

    local file_name = cfg.log.path ..
                        name ..
                        time ..
                        ".log"
    if os.getenv(file_name) then
        io.write(msg)
    else
        local f = assert(io.open(file_name, "a"))
        f:write(errmsg .. "\n")
        f:close()
    end
end

local function log(level, msg)
    -- 日志等级检查
    if level[1] < cfg.log.level then return end

    -- 日志内容检查
    if not msg then return end

    -- 外部日志文件
    log_file(level[2], scan.dump(msg))
end

function _M.E(msg)
    log(cfg.log.lv_msg["E"], msg)
end

function _M.W(msg)
    log(cfg.log.lv_msg["W"], msg)
end

function _M.I(msg)
    log(cfg.log.lv_msg["I"], msg)
end

function _M.D(msg)
    log(cfg.log.lv_msg["D"], msg)
end

return _M
