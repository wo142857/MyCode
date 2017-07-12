local _M = {}

_M.threads = {
    push_sum    = 2,        -- 消息消费线程数
    push_max    = 5,        -- 消息消费线程总数
    push_speed  = 3000,     -- 消息消费速率，单位:每秒
}

_M.sleep = 60 * 0.5

_M.log = {
    level   = 1,            -- 日志输出等级：输出大于该级别日志
    path    = "/data/web/push_script/logs/",    -- 日志文件输出路径
    pattern = "[%-6s%s] %s: %s\n",
    lv_msg  = {
        D   = {1, "DEBUG",},
        I   = {2, "INFO",},
        W   = {3, "WARN",},
        E   = {4, "ERROR",},
    },
}

-- 北京沙箱
local pro_bj = {
    url     = "http://push-accelerator.droi.local:8080/api/v2/vm",
    key     = "FQu9gfpjlZvksS876JGVdZl4hfSRwZ_FMRshzTqR3GKbI4M9eXFDthE8SIJP2bjB",
    appid   = "fokvmbzhObvwMkSbBkjPLOVylhz4XEkHlQCMvT4A",
    device  = "5c5813c14145406aa6a87b87e8ecd277",
}

-- 北京沙箱
local sand_bj = {
    url     = "http://push-accelerator.droi.local:8080/api/v2/vm",
    key     = "nTRyseMqYiad5VGxte8_R3hmqNwfdj7GBK3Um0jRTgyUUIpl2bNPDyfSeYPFl9Ih",
    appid   = "fokvmbzhvmLuT_-aoz2bNNzoconw-suDlQDAbMEd",
    device  = "5c5813c14145406aa6a87b87e8ecd277",
}

-- 上海测试
local sit_sh  = {
    url     = "https://10.0.10.213:443/api/v2",
    key     = "W2vVljBc9saFa_YKnVWluidVepZfuBj1VDi2NVQiV6bMW-Kq0X8wXpiY2rMosens",
    appid   = "s67umbzhzR8Tb8bdpDcvqgOXnNSv4PLOlQDjbYwJ",
    device  = "7039647d-5788-dec5-14aa-75b26c69f7e5",
}

_M.api = {
    -- 展开并首次下发接口
    get_uri     = {
        url     = pro_bj.url .. '/expandMsg',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key, 
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
    },

    push_first     = {
        url     = pro_bj.url .. '/consumeMsg', 
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key, 
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
    },

    push_uri    = {
        url	= pro_bj.url .. '/consumeMsg',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key,
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
    },

    -- 重发接口
    push_again  = {
        url     = pro_bj.url .. '/resendMsg',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key,
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
    },

    -- 宕机重启接口
    get_msgId_where_reload  = {
        url     = pro_bj.url .. '/accident',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key,
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
    },

    -- 清理心跳接口
    clean_heart_job  = {
        url     = pro_bj.url .. '/clearHeart',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key,
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
    },

    -- 清理无效消息接口
    clean_record_job  = {
        url     = pro_bj.url .. '/clearInvalidMsg',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key,
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
    },
}

_M.max_num = {
    get     = 1000,	-- 单次展开消息数
    push    = 1000,     -- 单词下发消息数
    again   = 60 * 5,	-- 重发时间间隔基数
    max	    = 10000000,	-- 单条消息最大展开数
    radix   = 10000,	-- 控制线程集体拥堵设置的基数
	thread_cnt	= 5,
	wait	= 60 * 6,
}

_M.redis = {
    host        = '10.10.80.186',
    port        = '7380',
    msgkey      = 'push2.0:msgid',
    pushkey     = 'push2.0:msgpush',
    -- get unfold
    getpri      = 'push2.0:getpri',
    getcom      = 'push2.0:getcom',
    gethug      = 'push2.0:gethug',
    -- push first
    pushpri     = 'push2.0:pushpri',
    pushcom     = 'push2.0:pushcom',
    pushhug     = 'push2.0:pushhug',
    pushfirst   = 'push2.0:pushfirst',
    pushagain   = 'push2.0:pushagain',
    pushtimer   = 'push2.0:pushtimer',
    sorted	= 'push2.0:sorted',
}

_M.errnu = {
    OK                      = 0,
    PARAM_ERROR             = -10000,
    REDIS_CONNECT_ERROR     = -10001,
    REDIS_DO_LPUSH_ERROR    = -10002,
    REDIS_DO_BRPOP_ERROR    = -10003,
    API_CONNECT_ERROR       = -10004,
    API_SEND_ERROR          = -10005,
    API_RECEIVE_ERROR       = -10006,
    HTTPS_RESPONSE_ERROR    = -10007,
    HTTPS_REQUEST_ERROR     = -10008,
    REDIS_DO_RPOP_ERROR     = -10009,
}

_M.errmsg = {
    [0]         = 'SUCCESS',
    [-10000]    = 'get args error or args is empty!',
    [-10001]    = 'fail to connect to redis!',
    [-10002]    = 'redis do lpush error!',
    [-10003]    = 'redis do brpop error!',
    [-10004]    = 'fail to connect to get api!',
    [-10005]    = 'fail to send request by tcp socket!',
    [-10006]    = 'fail to receive response by tcp socket!',
    [-10007]    = 'https response error!',
    [-10008]    = 'https request error!',
    [-10009]    = 'redis do rpop error!',
}

return _M
