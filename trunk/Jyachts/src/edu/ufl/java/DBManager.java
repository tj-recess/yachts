package edu.ufl.java;


import java.sql.*;

/* manage all database stuff */ 
public class DBManager {
	
	private String connString = "jdbc:mysql://localhost/yachts";
	private Connection conn = null;
	
	public DBManager()
	{
		try
		{
			Class.forName("com.mysql.jdbc.Driver").newInstance();
			conn = DriverManager.getConnection(connString,"root","root");
		}
		catch(SQLException sqlEx)
		{
			System.out.println("Exception in SQL Connection : " + sqlEx.toString());
		} catch (InstantiationException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (IllegalAccessException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (ClassNotFoundException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	public boolean registerUser(User aUser)
	{
		try{
			CallableStatement callProc = conn.prepareCall("{call RegisterUser(?,?,?,?,?,?)}");

			callProc.setString("Username", aUser.getUsername());
			callProc.setString("Password", aUser.getPassword());
			callProc.setString("FirstName", aUser.getFirstName());
			callProc.setString("LastName", aUser.getLastName());
			callProc.setString("Location", aUser.getLocation());
			callProc.setString("EmailId", aUser.getEmailAddress());
			if (callProc.executeUpdate() == 1)
				return true;
			else 
				return false;
		}
		catch(SQLException sqlEx)
		{
			System.out.println("Exception in SQL Connection : " + sqlEx.toString());
			return false;
		}
	}
	
/*	
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
			u = (ArrayList<User>) (session.createCriteria(User.class)
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
	*/
	
	public User loginUser(String username, String password)
	{
		try{
			CallableStatement callProc = conn.prepareCall("{call GetUserInfo(?,?)}");

			callProc.setString("someUsername", username);
			callProc.setString("somePassword", password);
			
			ResultSet rs = callProc.executeQuery();
			if (rs.next())
				return new User(rs.getString("FirstName"), rs.getString("LastName"), username, password, rs.getString("Location"), rs.getString("EmailID"));				
			else
				return null;
		}
		catch(SQLException sqlEx)
		{
			System.out.println("Exception in SQL Connection : " + sqlEx.toString());
			return null;
		}
	}
}