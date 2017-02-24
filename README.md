# MyCode

##LUA
resty_backup    复制此目录结构到本地任意位置，将api代码放在interface目录下，并将文件名添加之list.lua文件中；用root用户启动脚本openresty_start.sh文件，包括start stop reload命令；

common函数，提供string.split， string.trim， string.mask（字符串计数，汉字字母符号都计1）;

log-module  log模块，支持卓易云代码日志和openresty日志，可调整日志等级，打印table结构；

lineTopo  建立道路连接关系；

scan      scan.dump函数；

only      log函数；

urlReplace  redis url处理；

api_save_rtrpic_fromio  你看我拍上传图片接口；

##SHELL
ts2mp4    整合ts视频文件，按mp4格式输出；
setpts_atempo   实现视频音频同步加速减速功能；

##PYTHON
weather   网络天气爬虫，支持多历史天数一次爬取，最多一个月。；
downPic   下载网络图片；

##JAVA
StudentSystem 作为学习Struts2、hibernate、tomcat等javaweb知识的HelloWorld，在javabean和jsp之间的参数及结果传递，看show.jsp、show_one.jsp；同时分页逻辑、登陆验证逻辑可以参考。
