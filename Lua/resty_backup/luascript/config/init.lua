config = {}
config.root_dir = "/openresty/nginx/luascript/";

config.sms = {};
config.sms["zh_CN"] = {};
config.sms["zh_CN"]["pattern"] = "您的验证码为：%s，异常请联系客服电话，如非本人操作请忽略此短信。";
config.sms["zh_CN"]["regex"] = "([0-9]{6})";

config.mail_link = "https://account.droi.com";
--config.mail_link = "http://10.0.10.106";

config.login_expire = 86400*365;

config.fileupload = {};
config.fileupload.chunksize = 8192;
config.fileupload.tmppath = "/opt";
config.fileupload.allow = { useredit = true, stdata = true };
