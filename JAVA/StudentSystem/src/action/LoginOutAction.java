package action;

import java.util.Map;

import org.apache.struts2.convention.annotation.Action;
import org.apache.struts2.convention.annotation.Result;
import org.apache.struts2.convention.annotation.Results;

import com.opensymphony.xwork2.ActionContext;
import com.opensymphony.xwork2.ActionSupport;

@Results({
	@Result(name="success", location="/login.jsp"),
	@Result(name="error", location="/error.jsp")
})
public class LoginOutAction extends ActionSupport {

	private static final long serialVersionUID = 1L;
	private String name;

	@Override
	@Action(value="/login_out")
    public String execute() throws Exception {
        Map<String, Object> attibutes = ActionContext.getContext().getSession();

        System.out.println(attibutes.remove("login_name"));

        return SUCCESS; 
    }
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
}
