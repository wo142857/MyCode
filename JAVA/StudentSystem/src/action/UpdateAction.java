package action;

import model.Student;
import service.StudentService;

import org.apache.struts2.convention.annotation.Action;
import org.apache.struts2.convention.annotation.Result;
import org.apache.struts2.convention.annotation.Results;
import com.opensymphony.xwork2.ActionSupport;

@Results({
	@Result(name="success", location="/success.jsp"),
	@Result(name="error", location="/error.jsp")
})
public class UpdateAction extends ActionSupport {
	private int id;
	private String name;
	private String gender;
	private int age;
	
	@Action(value="/update")
	public String execute() {
		Student student = new Student();
		student.setId(id);
		student.setName(name);
		student.setGender(gender);
		student.setAge(age);

		StudentService ss = new StudentService();
		boolean ret = ss.updateStudent(student);
		
		return ret == true ? SUCCESS : ERROR;
	}
	
	public int getId() {
		return id;
	}
	public void setId(int id) {
		this.id = id;
	}
	
	public String getName() {
		return name;
	}
	public void setName(String name) {
		this.name = name;
	}
	
	public String getGender() {
		return gender;
	}
	public void setGender(String gender) {
		this.gender = gender;
	}
	
	public Integer getAge() {
		return age;
	}
	public void setAge(Integer age) {
		this.age = age;
	}
}
