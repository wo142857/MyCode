local _M = {}

_M.sleep = 60 * 0.05

_M.log = {
    level   = 1,                    -- 日志输出等级：输出大于该级别日志
    path    = "logs/",              -- 日志文件输出路径
    pattern = "[%-6s%s] %s: %s\n",
    lv_msg  = {
        D   = {1, "DEBUG",},
        I   = {2, "INFO",},
        W   = {3, "WARN",},
        E   = {4, "ERROR",},
    },
}

_M.max_num = {
    get     = 1000,
    push    = 10,
}

_M.redis = {
    host    	= '10.10.80.186',
    port    	= '7380',
    msgkey  	= 'push2.0:msgid',
    pushkey 	= 'push2.0:msgpush',
    -- unfold queue
    getpri 	= 'push2.0:getpri',
    getcom 	= 'push2.0:getcom',
    gethug 	= 'push2.0:gethug',
    -- push queue
    pushpri 	= 'push2.0:pushpri',
    pushcom 	= 'push2.0:pushcom',
    pushhug 	= 'push2.0:pushhug',

    pushfirst	= 'push2.0:pushfirst',
    -- push again
    pushagain	= 'push2.0:pushagain',
    -- push timer
    pushtimer	= 'push2.0:pushtimer',
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
