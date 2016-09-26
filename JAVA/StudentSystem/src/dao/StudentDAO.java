package dao;


import model.Student;
import utils.HibernateUtil;

import java.util.List;

import org.hibernate.Session;
import org.hibernate.Query;
import org.hibernate.Transaction;

public class StudentDAO {
	public boolean saveStudent(Student student) {
		boolean flag;
		//开启session,相当于一个数据库连接对象
		Session session = HibernateUtil.openSession();
		Transaction tx = session.beginTransaction();
		//开启事务
		try {
			//插入
			session.save(student);
			tx.commit();
			flag = true;
		} catch (Exception ex) {
			if (null != tx) {
				tx.rollback();
				//失败回滚
			}
			flag = false;
		 
		} finally {
			//关闭session
			HibernateUtil.close(session);
		}
		return flag;
	}
	
	public boolean deleteStudent(Student student) {
		boolean flag;
		//开启session,相当于一个数据库连接对象
		Session session = HibernateUtil.openSession();
		Transaction tx = session.beginTransaction();
		//开启事务
		try {
			System.out.println(student.getName());
			// 删除
			session.delete(student);
			tx.commit();
			flag = true;
		} catch (Exception ex) {
			if (null != tx) {
				tx.rollback();
				//失败回滚
			}
			flag = false;
		 
		} finally {
			//关闭session
			HibernateUtil.close(session);
		}
		return flag;
	}
	
	public boolean updateStudent(Student student) {
		boolean flag;
		//开启session,相当于一个数据库连接对象
		Session session = HibernateUtil.openSession();
		Transaction tx = session.beginTransaction();
		//开启事务
		try {
			// 更新
			session.update(student);
			tx.commit();
			flag = true;
		} catch (Exception e) {
			e.printStackTrace();
			if (null != tx) {
				tx.rollback();
				//失败回滚
			}
			flag = false;
		 
		} finally {
			//关闭session
			HibernateUtil.close(session);
		}
		return flag;
	}
	
	public Student selectStudent(int id) {
		Student student;
		//开启session,相当于一个数据库连接对象
		Session session = HibernateUtil.openSession();
		Transaction tx = session.beginTransaction();
		//开启事务
		try {
			student = (Student) session.get(Student.class, id);
			tx.commit();
		} catch (Exception e) {
			e.printStackTrace();
			student = null;
		}
		return student;
	}
	
	public Student getStuById(int id) {
		Student ret = null;
		//开启session,相当于一个数据库连接对象
		Session session = HibernateUtil.openSession();
		Transaction tx = session.beginTransaction();
		//开启事务
		try {			
			Student s = (Student)session.get(Student.class, new Integer(id));
			tx.commit();
			ret = s;
		} catch (Exception e) {
			e.printStackTrace();
		}
		return ret;
	}
}
