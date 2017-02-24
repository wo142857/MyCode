GV_IFS = GV_IFS or {}

local _module_ = (...):match("^.*%.(.*)$") 

GV_IFS[_module_] = {
	name        = _module_,  
	cname       = "Default",
	desc        = "Default Module",
	base_param  = {},
	opt_param   = {},
}

GV_IFS[_module_]['callback'] = function(_REQ, _FILE)  
	return "It's OK!"
end
