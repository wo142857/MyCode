-- @author: wo142857@droi.com
-- @brief:  LOG日志函数

local cfg   = require("cfg")
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
    while true do
        local info = debug.getinfo(n, "Sl")
        if not info then
            return ret
        else
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
    local log_info = seek_file_name()["fileinfo"]

    return string.format(
        cfg.PATTERN, 
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

    local file_name = cfg.LOG_PATH ..
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

local function droi_log(level, msg)
    local errmsg =  string.format(cfg.PATTERN,
                        level,
                        Droi.Time.Time.Now():Format(),
                        "",
                        msg
                    )
    Droi.CloudLogger.log(level, errmsg)
end

local function log(level, msg)
    -- 日志等级检查
    if level[1] < cfg["LOG_LV"] then return end

    -- 日志内容检查
    if not msg then return end

    -- 卓易云日志
    if cfg.LOG_DROI == 1 then
        droi_log(level[3], scan.dump(msg))
    end

    -- 外部日志文件
    if cfg.LOG_FILE == 1 then
        log_file(level[2], scan.dump(msg))
    end
end

function _M.E(msg)
    log(cfg["E"], msg)
end

function _M.W(msg)
    log(cfg["W"], msg)
end

function _M.I(msg)
    log(cfg["I"], msg)
end

function _M.D(msg)
    log(cfg["D"], msg)
end

return _M
