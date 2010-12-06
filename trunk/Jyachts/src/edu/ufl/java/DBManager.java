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
		catch(Exception sqlEx)
		{
			ConsoleLogger.log("Exception in SQL Connection : " + sqlEx.toString());
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
			synchronized(DBManager.class)
			{
				if (callProc.executeUpdate() == 1)
					return true;
				else 
					return false;
			}
		}
		catch(SQLException sqlEx)
		{
			ConsoleLogger.log("Exception in SQL Connection : " + sqlEx.toString());
			return false;
		}
	}
		
	public User loginUser(String username, String password)
	{
		try
		{
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
			ConsoleLogger.log("Exception in SQL Connection : " + sqlEx.toString());
			return null;
		}
	}
}