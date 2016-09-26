package action;

import dao.PageDAO;
import model.Student;
import utils.HibernateUtil;

import java.util.List;

import com.opensymphony.xwork2.ActionSupport;
import org.apache.struts2.convention.annotation.Action;
import org.apache.struts2.convention.annotation.Result;
import org.apache.struts2.convention.annotation.Results;

@Results({
	@Result(name="success", location="/show.jsp"),
	@Result(name="error", location="/error.jsp")
})
public class PageAction extends ActionSupport {
	private List<Student> students;
	private int pageNow = 1;	// 初始化为1，默认从第一页开始显示
	private int pageSize = 5;	// 初始化为5，默认每页显示5条
	private int pageCount;
	
	private PageDAO pageDAO = new PageDAO();
	
	public List<Student> getStudents() {
		return students;
	}
	public void setStudents(List<Student> students) {
		this.students = students;
	}
	
	public int getPageNow() {
		return pageNow;
	}
	public void setPageNow(int pageNow) {
		this.pageNow = pageNow;
	}
	
	public int getPageSize() {
		return pageSize;
	}
	public void setPageSize(int pageSize) {
		this.pageSize = pageSize;
	}
	
	public int getPageCount() {
		int rowCount = pageDAO.getRow();
		return (rowCount + pageSize-1) / pageSize;
	}
	public void setPageCount() {
		int rowCount = pageDAO.getRow();
		pageCount = (rowCount + pageSize-1) / pageSize;
	}
	
	@Action(value="/show")
	public String execute() throws Exception{
		System.out.println("Welcome!!!");
		
		students = pageDAO.queryByPage(pageSize, pageNow, pageCount);
		System.out.println(students.size());
		return SUCCESS;
	}
}
