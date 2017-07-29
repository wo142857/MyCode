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
    -- push 重发接口
    push_again  = {
        url     = pro_bj.url .. '/resendMsg',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = pro_bj.key,
            ["X-Droi-AppID"]    = pro_bj.appid,
            ["X-Droi-DeviceID"] = pro_bj.device,
            ["Content-Type"]    = "application/json",
        },
        request = {},
    },

    -- weather
    weather  = {
        url     = 'https://api.droibaas.com/api/v2/weather/public/all.json?location=WTW4X8D1EZCZ',
        method  = 'GET',
        headers = {
            ["X-Droi-Api-Key"]  = 'pQq8XCeYiLI1ltG7_rpM14X4vXVSxXvYZLs5N-I8e6TACu9Bx-qazpcf-wCNU1FL',
            ["X-Droi-AppID"]    = 'mfpvmbzhM9iqko8nk2u5klmoBREpPQNElQCYlSQN',
            ["Content-Type"]    = "application/json",
        },
    },

    -- saleStatistics
    saleStatistics  = {
        url     = 'https://api.droibaas.com/api/v2/saleStatistics',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = '5T35qoYd4x0OxpLVYmzV3panRNByJjLW_EpsWATx9_vrUz3ezuo2U3I-uV7bOQxz',
            ["X-Droi-AppID"]    = 'n6svmbzhkY4CH_c-mNDeWU4JSwdSxUwNlQDozOoK',
            ["Content-Type"]    = "application/json",
        },
        request = {
            cipher  = 'test',
        },
    },

    -- feedback
    feedback = {
        url     = 'https://api.droibaas.com/api/v2/feedback/web/getall',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = '1CaaxdccQXTNLeaaKlGZf3b_KrbKA-Oe1PgyiHpSLq97KlCveDYMKVcN0kMfDMKS',
            ["X-Droi-AppID"]    = '46dvmbzhSbtLcf4hgDF6UAwazupGDHHvlQBahesA',
            ["Content-Type"]    = "application/json",
        },
        request = {
            appId  = '46dvmbzhSbtLcf4hgDF6UAwazupGDHHvlQBahesA',
        },
    },

    -- AutoUpdate
    AutoUpdatge = {
        url     = 'https://api.droibaas.com/api/v2/droiupdate/getall',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = 'xtHT20H1yeyYhtacXkZ-OUN0wj7k6Ua1kmmm5ovrzP9Bd0H7yXUY36alfK37ebbV',
            ["X-Droi-AppID"]    = 'rzdvmbzhOrRE7IK96EBpAw2dpOk8Ypq9lQDwdQgA',
            ["Content-Type"]    = "application/json",
        },
        request = {
            appId  = 'rzdvmbzhOrRE7IK96EBpAw2dpOk8Ypq9lQDwdQgA',
        },
    },

    -- 短信
    getsmscode  = {
        url     = 'https://api.droibaas.com/api/v2/droisms/1/getsmscode',
        method  = 'POST',
        headers = {
            ["X-Droi-Api-Key"]  = 'GYExJWEShW4aA39HaHoPw11ihzWlRg8tYg-DhYIdM_rg93njgi19WpPhdbYIrVow',
            ["X-Droi-AppID"]    = 'r6pumbzhA4kNy2jO3kdl71C4wD3jP2S8lQCZlMkF',
            ["Content-Type"]    = "application/json",
        },
        request = {},
    },
}

return _M
