package service;

import dao.StudentDAO;
import model.Student;

import java.util.List;

public class StudentService {
	public boolean saveStudent(Student student) {
		StudentDAO studentDAO = new StudentDAO();
		return studentDAO.saveStudent(student);
	}
	
	public boolean deleteStudent(Student student) {
		StudentDAO studentDAO = new StudentDAO();
		return studentDAO.deleteStudent(student);
	}
	
	public boolean updateStudent(Student student) {
		StudentDAO studentDAO = new StudentDAO();
		return studentDAO.updateStudent(student);
	}
	
	public Student selectStudent(int id) {
		StudentDAO studentDAO = new StudentDAO();
		return studentDAO.selectStudent(id);
	}
}
