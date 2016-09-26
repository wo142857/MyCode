package utils;

import java.util.Map;

import org.apache.struts2.ServletActionContext;

import com.opensymphony.xwork2.ActionContext;
import com.opensymphony.xwork2.ActionInvocation;
import com.opensymphony.xwork2.interceptor.AbstractInterceptor;

public class LoginInterceptor extends AbstractInterceptor {

	private static final long serialVersionUID = 1L;

	@Override
	public String intercept(ActionInvocation invocation) throws Exception {
		// 取得请求的action名
				String actionName = invocation.getInvocationContext().getName();
				if("login".equals(actionName)) {
					// 用户请求登陆
					return invocation.invoke();
				} else {
					// 取得session
					ActionContext ac = invocation.getInvocationContext();
					Map session = (Map)ac.get(ServletActionContext.SESSION);
					
					if(null == session) {
						// 如果 session 为空，让用户登陆
						return "login";
					} else {
						// 如果 session 非空，检查用户消息
						String userName = (String)session.get("synname");
						if(null == userName) {
							// session 中没有用户信息，让用户登录
							return "login";
						} else {
							// 用户已经登陆，放行
							return invocation.invoke();
						}
					}
				}
		
	}

}
