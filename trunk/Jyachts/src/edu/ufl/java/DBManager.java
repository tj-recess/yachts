package src.edu.ufl.java;

import java.io.PrintWriter;
import java.net.Socket;
import java.util.ArrayList;
import org.hibernate.HibernateException;
import org.hibernate.Session;               
import org.hibernate.Transaction;           
import org.hibernate.criterion.Restrictions;

/* manage all database stuff */ 
public class DBManager {
	
	public boolean addUserToDB(User newuser){
		Session session = HibernateUtils.getSession();			    
		Transaction tx = null;
		try{
			tx=session.beginTransaction();
			session.save(newuser);
			session.getTransaction().commit();
		}
		catch (HibernateException he) {
			if (tx!=null) tx.rollback();
			throw he;
		}
		finally {
			session.close();
		}
		return true;
	}
	
	public boolean login(String username, String password,String socketinfo, Socket conn){
		
		ArrayList<User> u = new ArrayList<User>(); 
		
		System.out.println("DBMGR: Searching for username: "+username+" and password: "+password);
		
		Session session = HibernateUtils.getSession();			    
		Transaction tx = null;
		tx=session.beginTransaction();
		
		try{
			// search for users in the database which matches the specified username
			u = (ArrayList) (session.createCriteria(User.class)
					.add( Restrictions.eq("Username", username))
					.list());
		
			// received user data
			System.out.println("DBMGR: Received user data..\n # of records: "+u.size());
			
			// match the password
			if (u.get(0).getPassword().equals(password)){
					System.out.println("DBMGR: User authenticated successfully...");
					
					// add this user to the list of logged in users.
					LoginManager.getLoginManager().loginUser(username,socketinfo,conn);
					
					return true;
			}
		 	else{
				System.out.println("DBMGR: User login error! Check your credentials");
				return false;
			}
		}
		catch (HibernateException he) {
			if (tx!=null) tx.rollback();
			throw he;
		}
		finally {
			session.close();
		}
		//System.out.println("User name: "+userarray.get(0).getFirstName());
	}
	public static User getUser(String username){
		
			ArrayList<User> u = new ArrayList<User>(); 
			
			System.out.println("DBMGR: Searching for username: "+username);
			
			Session session = HibernateUtils.getSession();			    
			Transaction tx = null;
			tx=session.beginTransaction();
			
			try{
				// search for users in the database which matches the specified username
				u = (ArrayList) (session.createCriteria(User.class)
						.add( Restrictions.eq("Username", username))
						.list());
			
				// received user data
				System.out.println("DBMGR: Received user data..\n # of records: "+u.size());
				if (u.size()>0)
					return u.get(0);
				else 
					return null;
			}
			catch (HibernateException he) {
				if (tx!=null) tx.rollback();
				throw he;
			}
			finally {
				session.close();
			}		
	}
}