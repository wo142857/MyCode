package dao;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.PreparedStatement;

public class UserDAO {
	private String name;
	
	private Connection conn;
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
	
	public String userLogin(String synName, String password) {
		Connection co = getConnection();
		
		try {
			String sql = String.format("select name from login where user = '%s' and password = '%s';",
					synName, password);
			System.out.println(sql);
			PreparedStatement ps = co.prepareStatement(sql);
			ResultSet rs = ps.executeQuery();
			
			if(rs.absolute(1)) {
				name = rs.getString(1);
			} else {
				name = null;
			}
		} catch(SQLException se) {
			se.printStackTrace();
		} finally {
			if(null != co) {
	    		try{
	    			co.close();
	    		} catch(SQLException se) {
	    			se.printStackTrace();
	    		}
			}
		}
		return name;
	}
}
