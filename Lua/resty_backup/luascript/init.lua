-- init module.
-- auther: qox
-- env setup.

-- package.path = package.path ..";$prefix/luascript/?.lua;$prefix/luascript/?/init.lua;"

ngx.log(ngx.INFO, "AppStore初始化...")

-- require modules .
---- system module
cjson       = require("cjson")
cjson_safe  = require("cjson.safe")
sstr        = require("resty.string")
md5         = require("resty.md5")

require("global")
require("config")
require("db")
require("interface")

function Do_LAPI()
    ngx.header["Content-type"] = "text/html;charset=utf-8"
    local _res = if_route()
    local _ret = ""

    if type(_res) == "table" then
        _ret = _JSON(_res)
    elseif type(_res) == "string" then
        _ret = _res
    end
    ngx.header["Content-Length"] = #_ret
    _SAY(_ret)
end

function str_crypt(str)
    local _orig_array = {
        ['a']='o',['2']='D',['c']='U',['b']='W',['e']='B',['d']='j',['g']='h',
        ['f']='3',['i']='7',['h']='Y',['k']='z',['j']='y',['m']='u',['l']='t',
        ['/']='c',['n']='J',['1']='F',['0']='s',['3']='E',['r']='e',['5']='f',
        ['t']='l',['7']='g',['v']='q',['9']='2',['8']='i',['+']='Q',['z']='b',
        ['4']='P',['o']='O',['u']='V',['s']='T',['A']='L',['p']='N',['C']='S',
        ['B']='w',['E']='K',['D']='+',['G']='p',['F']='0',['I']='4',['H']='M',
        ['K']='Z',['J']='d',['M']='k',['L']='1',['O']='6',['N']='X',['Q']='C',
        ['P']='R',['S']='H',['R']='m',['U']='9',['T']='/',['W']='8',['V']='n',
        ['Y']='5',['X']='r',['q']='G',['Z']='I',['x']='A',['w']='x',['6']='v',
        ['y']='a',[' ']='Q'
    }

    local _crypt_array = {
        ['a']='y',['/']='T',['c']='/',['b']='z',['e']='r',['d']='J',['g']='7',
        ['f']='5',['i']='8',['h']='g',['k']='M',['j']='d',['m']='R',['l']='t',
        ['o']='a',['n']='V',['q']='v',['p']='G',['s']='0',['r']='X',['u']='m',
        ['t']='l',['7']='i',['6']='O',['9']='U',['8']='W',['+']='D',['z']='k',
        ['0']='F',['w']='B',['v']='6',['y']='j',['A']='x',['x']='w',['C']='Q',
        ['B']='e',['E']='3',['D']='2',['G']='q',['F']='1',['I']='Z',['H']='S',
        ['K']='E',['J']='n',['M']='H',['L']='A',['O']='o',['N']='p',['Q']='+',
        ['P']='4',['S']='C',['R']='P',['U']='c',['T']='s',['W']='b',['V']='u',
        ['Y']='h',['X']='N',['1']='L',['Z']='K',['3']='f',['2']='9',['5']='Y',
        ['4']='I',[' ']='D'
    }

    local _rstr = ""    -- 返回字符串
    if type(str) ~= "string" or #str == 0 then
        return nil
    end

    for i = 1, #str do
        local _idx = string.char(str:byte(i))
        local _char = _orig_array[_idx]

        if _char == nil then
            return nil
        end
        _rstr = _rstr .. _char
    end

    return _rstr
end
