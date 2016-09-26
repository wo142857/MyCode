package dao;

import model.Student;

import java.sql.Connection;  
import java.sql.DriverManager;  
import java.sql.PreparedStatement;  
import java.sql.ResultSet;  
import java.sql.SQLException;  
import java.util.ArrayList;  
import java.util.List; 

public class PageDAO {
	private Student student;
	
	private Connection conn;
    private PreparedStatement pstmt;  
    private ResultSet rs;
    
    private static final String DRIVER = "com.mysql.jdbc.Driver";  
    private static final String URL = "jdbc:mysql://localhost:3306/test";  
    private static final String USERNAME = "root";
    private static final String PASSWORD = "root";
    
    // 数据库连接
    public synchronized Connection getConnection() {
    	try{
    		// 加载SQL驱动
    		Class.forName(DRIVER);
    		// 建立连接
    		conn = DriverManager.getConnection(URL, USERNAME, PASSWORD);
    	} catch(ClassNotFoundException cnfe) {
    		// Class.forName() 无法定位类
    		cnfe.printStackTrace();
    		return null;
    	} catch(SQLException se) {
    		// DriverManager.getConnection() 发生数据库访问错误
    		se.printStackTrace();
    		return null;
    	}
    	return conn;
    }
    
    // 分页查询
    public List<Student> queryByPage(int pageSize, int pageNow, int pageCount) {
    	System.out.println("page size: " + pageSize);
    	System.out.println("page now: " + pageNow);
    	System.out.println("page count: " + pageCount);
    	List<Student> list = new ArrayList<Student>();
    	try{
    		if(null != this.getConnection() && pageSize > 0 && pageNow >0) {
    			// 创建一个 PreparedStatement 对象来将参数化的 SQL 语句发送到数据库。
    			pstmt = this.getConnection().prepareStatement(
    					"select * from students order by id limit " +
    							(pageSize * pageNow - pageSize) + ", " +
    							pageSize + ";"
    					);
    			// 在此 PreparedStatement 对象中执行 SQL 查询，并返回该查询生成的 ResultSet 对象。
    			rs = pstmt.executeQuery();
    			
    			while(rs.next()) {
    				System.out.println("Row: " + rs.getRow());
    				student = new Student();
    				// 数据库表中的每一行数据封装成一个student对象，
    				student.setId(rs.getInt(1));
    				student.setName(rs.getString(2));
    				student.setGender(rs.getString(3));
    				student.setAge(rs.getInt(4));
    				
    				list.add(student);
    			}
    		}
    	} catch(SQLException se) {
    		se.printStackTrace();
    	} finally{
    		if(null != conn) {
    			try{
    				conn.close();
    			} catch(SQLException se) {
    				se.printStackTrace();
    			}
    		}
    	}
    	return list;
    }
    
    // 获取总记录条数
    public int getRow() {
    	int rowCount = -1;
    	
    	try {
    		if(null != this.getConnection()) {
    			pstmt = this.getConnection().prepareStatement(
    					"select * from students;"
    					);
    			rs = pstmt.executeQuery();
    			rs.last(); 
    			rowCount = rs.getRow();
    		} 
    	} catch(SQLException se) {
    		se.printStackTrace();
    	} finally{
    		if(null != conn) {
    			try{
    				conn.close();
    			} catch(SQLException se) {
    				se.printStackTrace();
    			}
    		}
    	}
    	System.out.println("Row Count: " + rowCount);
    	return rowCount;
    }
}
