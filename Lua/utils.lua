local pkcs7 = require("resty.nettle.padding.pkcs7")
local des = require("resty.nettle.des")

local config = require("common.config")

local sgsub   = string.gsub
local ssub    = string.sub
local sformat = string.format
local sbyte   = string.byte
local schar   = string.char

local _M = {}

_M.strim = function(s)
    return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

_M.hex2str = function(s)
    return (sgsub(s, "(.)", function(c) return sformat("%02x", sbyte(c)) end))
end

_M.str2hex = function(s)
    local h2b = {
        ["0"] = 0,
        ["1"] = 1,
        ["2"] = 2,
        ["3"] = 3,
        ["4"] = 4,
        ["5"] = 5,
        ["6"] = 6,
        ["7"] = 7,
        ["8"] = 8,
        ["9"] = 9,
        ["a"] = 10,
        ["b"] = 11,
        ["c"] = 12,
        ["d"] = 13,
        ["e"] = 14,
        ["f"] = 15,
        ["A"] = 10,
        ["B"] = 11,
        ["C"] = 12,
        ["D"] = 13,
        ["E"] = 14,
        ["F"] = 15,
    }
    return (sgsub(s, "(.)(.)", function(h, l)
        return schar(h2b[h]*16 + h2b[l])
    end))
end

_M.encrypt_des = function(s)
    local key = ssub(config.des_key, 1, 8)
    local ds, wk = des.new(key, 'ecb')
    return _M.hex2str(ds:encrypt(pkcs7.pad(s)))
end

_M.decrypt_des = function(s)
    local key = ssub(config.des_key, 1, 8)
    local ds, wk = des.new(key, 'ecb')
    return (pkcs7.unpad(ds:decrypt(_M.str2hex(s)), 8))
end

return _M
