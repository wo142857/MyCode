#### Lua 中 nil 和 ngx.null
    [轻量用户数据](http://www.lua.org/pil/28.5.html)
```
    nil 表示“无效值”；
    ngx.null 常量是一个 NULL 的轻量用户数据，一般被用来表达 Lua table 等里面的 nil (空) 值，
        类似于 lua-cjson 库中的 cjson.null 常量。
```
#### Lua 优先级
```lua
    ^                   -- 幂
    not # -             -- 取反，求数组长度，负
    * / %               -- 乘，除，求余
    + -                 
    ..                  -- 字符串连接符
    < > <= >= == ~=
    and
    or
```
#### Lua 标准库提供了几种迭代器,包括用于
```
    迭代文件中每行的(io.lines)、
    迭代 table 元素的(pairs)、  -- 只能被 LuaJIT 解释执行
    迭代数组元素的(ipairs)、    -- 时可以被 LuaJIT 编译的
    迭代字符串中单词的(string.gmatch)等。
```
    因此在性能敏感的场景,应当合理安排数据结构,避免对哈希表进行遍历。事实上,即使未来 pairs 可以被 JIT 编译,哈希表的遍历本身也不会有数组遍历那么高效,毕竟哈希表就不是为遍历而设计的数据结构。

#### 了解 ``` do break end ``` 用法。
#### Lua 函数的变长参数（``` ... ```）
```
    local function func(...)
        local temp  = {...}      -- 访问时也要用 ...
        local ans   = table.concat(temp, " ")
        print(ans)
    end
```
    值得一提的是，LuaJIT 2 尚不能 JIT 编译这种变长参数的用法,只能解释执行。所以对性能敏感的代码,应当避免使用此种形式。
#### Lua 函数的具名参数
```
    -- 声明函数
    local function change(arg)
        arg.width   = arg.width * 2
        arg.height  = arg.height * 2
    end

    -- 调用
    local rectangle = {
        width   = 20,
        height  = 50,
    }

    change(rectangle)
```
    在 Lua 中，当函数参数是 table 类型时,传递进来的是实际参数的引用,此时在函数内部对该 table 所做的修改,会直接对调用者所传递的实际参数生效。所以这里经过调用函数 change 后，即对局部变量 rectangle 作了修改，需要注意。
    常用基本类型中,除了 table 是按址传递类型外,其它的都是按值传递参数。
#### Lua 函数有多个返回值，当确定只取返回值的第一个值时，需要使用括号运算符，否则会对性能有一定影响。
```
local function init()
    return 1, 'lua'
end

print(init(), 2)    --> output 1 2
print((init()), 2)  --> output 1 2
print(2, init())    --> output 2 1 lua
print(2, (init()))  --> output 2 1
```
如果实参列表中某个函数会返回多个值,同时调用者又没有显式地使用括号运算符来筛选和过滤,则这样的表达式是不能被 LuaJIT2 所 JIT 编译的,而只能被解释执行。
#### 全动态函数调用
```
    function table_maxn(t)
        local m = 0
        for k, v in pairs(t) do
            if m < k then
                m = k
            end
        end
        return m
    end

    local function run(x, y)
        print('run', x, y)
    end

    local function attack(targetId)
        print('targetId', targetId)
    end

    local function do_action(method, ...)
        local args = {...} or {}
        method(table.unpack(args, 1, table_maxn(args)))
    end

    do_action(run, 1, 2)    --> output: run 1 2
    doz_action(attack, 100) --> output: targetId 100
```
    table.unpack(list) 函数默认依次返回第一个表结构参数的元素，遇到 nil 或非数字 key 都返回 nil；该内建函数还不能为 LuaJIT 所 JIT 编译,因此这种用法总是会被解释执行。对性能敏感的代码路径应避免这种用法。
    table_maxn 函数类似于 5.1 之前的 table.maxn 函数，之后弃用了。
```
    tbl = {[1] = "a", [2] = "b", [3] = "c", [26] = "z"}
    print("tbl 长度 ", #tbl)                --> output tbl 长度 4
    print("tbl 最大值 ", table_maxn(tbl))   --> output tbl 最大值 26
```
#### 邮件正则匹配表达式：```'^[%w_%.]+@[%w_%.]+%.[%w]+$'```
