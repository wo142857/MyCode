/**
 * 
 */
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
public class AddAction extends ActionSupport {
	private int id;
	private String name;
	private String gender;
	private int age;

	@Action(value="/add")
	public String execute() {

		Student s = new Student();
		s.setId(id);
		s.setName(name);
		s.setGender(gender);
		s.setAge(age);
		
		StudentService ss = new StudentService();
		boolean ret = ss.saveStudent(s);

		return ret == true ? SUCCESS : ERROR;
	}
	
	public Integer getId() {
		return id;
	}
	public void setId(Integer id) {
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
