/**
 * 
 */
package utils;

import org.hibernate.Session;
import org.hibernate.SessionFactory;
import org.hibernate.cfg.Configuration;

/**
 * @author Administrator
 *
 */
public class HibernateUtil {
	private static SessionFactory sessionFactory;
	//因为sessionFactory一旦生成就不需要关闭,即使配置文件修改也不会影响，所以放在静态代码片段中，类加载时就生成
	static{
		sessionFactory = new Configuration().configure().buildSessionFactory();
	}
	
	public static Session openSession(){
		Session session = sessionFactory.openSession();
		return session;
	}
	
	public static void close(Session session){
		if(session != null)
		{
			session.close();
		}
	}
}
