package action;

import model.Student;
import service.StudentService;

import org.apache.struts2.convention.annotation.Action;
import org.apache.struts2.convention.annotation.Result;
import org.apache.struts2.convention.annotation.Results;
import com.opensymphony.xwork2.ActionSupport;

@Results({
	@Result(name="success", location="/show_one.jsp"),
	@Result(name="error", location="/error.jsp")
})
public class SelectAction extends ActionSupport {
	private int id;
	private Student student;
	
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	
	public Student getStudent() {
		return student;
	}
	public void setStudent(Student student) {
		this.student = student;
	}
	
	@Action(value="/select")
	public String execute() {
		StudentService ss = new StudentService();
		student = ss.selectStudent(id);
		return SUCCESS;
	}
}
