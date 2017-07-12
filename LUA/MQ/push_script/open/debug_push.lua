local _M = {}

_M.log = {
    level   = 1,            -- 日志输出等级：输出大于该级别日志
    path    = "./logs/",    -- 日志文件输出路径
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
    url     = "http://api.droibaas.com/api/v2/vm",
    key     = "FQu9gfpjlZvksS876JGVdZl4hfSRwZ_FMRshzTqR3GKbI4M9eXFDthE8SIJP2bjB",
    appid   = "fokvmbzhObvwMkSbBkjPLOVylhz4XEkHlQCMvT4A",
    device  = "5c5813c14145406aa6a87b87e8ecd277",
}

_M.api = {
    -- push 1.0
    push_1  = {
        url     = 'http://push_service.droi.cn:2200/api/send',
        method  = 'POST',
        headers = {
            ["appkey"]  = 'hchvmbzhx2s3vbdp70nTH_aO6dnhALKAlQAAYKkp',
            ["Content-Type"]    = "application/json",
        },
        request = {
		osType	= 1,
		msgType	= 4,
		payload	= {
			displayType	= 4,
			body	= {
				title	= "aa",
				text	= "测试"
			},
		},
	},
    },

}

return _M
