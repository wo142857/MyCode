package action;

import java.util.Map;

import org.apache.struts2.convention.annotation.Action;
import org.apache.struts2.convention.annotation.Result;
import org.apache.struts2.convention.annotation.Results;

import com.opensymphony.xwork2.ActionSupport;
import com.opensymphony.xwork2.ActionContext;
import com.opensymphony.xwork2.validator.annotations.RequiredFieldValidator;

import service.UserService;

@Results({
	@Result(name="success", location="/login_success.jsp"),
	@Result(name="error", location="/login.jsp")
})
public class LoginAction extends ActionSupport {
	private static final long serialVersionUID = 1L;
	private String synName;
	private String password;
	private String name;
	
	@Action(value="/login")
	public String execute() {
		System.out.println("User: " + synName);
		System.out.println("Password: " + password);
		UserService us = new UserService();
		name = us.userLogin(synName, password);
		
		Map<String, Object> attibutes = ActionContext.getContext().getSession();  
	    
		attibutes.put("login_name", name);   
		
		return null == name ? ERROR : SUCCESS;
	}
	
	public String getSynName() {
		return synName;
	}
	@RequiredFieldValidator(message = "The name is required!")
	public void setSynName(String synName) {
		this.synName = synName;
	}
	
	public String getPassword() {
		return password;
	}
	public void setPassword(String password) {
		this.password = password;
	}
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
}
