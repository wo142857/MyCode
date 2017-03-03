1. Lua 中 nil 表示“无效值”；
    ngx.null 常量是一个 NULL 的[轻量用户数据](http://www.lua.org/pil/28.5.html) ，一般被用来表达 Lua table 等里面的 nil (空) 值，类似于 lua-cjson 库中的 cjson.null 常量。

2. Lua 优先级
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

3. Lua 标准库提供了几种迭代器,包括用于
    迭代文件中每行的(io.lines)、
    迭代 table 元素的(pairs)、
    迭代数组元素的(ipairs)、
    迭代字符串中单词的(string.gmatch)等。
