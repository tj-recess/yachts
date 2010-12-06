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
			//load the JDBC driver first
			Class.forName("com.mysql.jdbc.Driver").newInstance();
			//get the connection instance by passing connection string, user name and password 
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
			//call the stored procedure RegisterUser with the given parameters
			CallableStatement callProc = conn.prepareCall("{call RegisterUser(?,?,?,?,?,?)}");
			//set all the parameters for the call
			callProc.setString("Username", aUser.getUsername());
			callProc.setString("Password", aUser.getPassword());
			callProc.setString("FirstName", aUser.getFirstName());
			callProc.setString("LastName", aUser.getLastName());
			callProc.setString("Location", aUser.getLocation());
			callProc.setString("EmailId", aUser.getEmailAddress());
			
			synchronized(this)
			{
				//kept in synchronized block to avoid conflicting access  
				if (callProc.executeUpdate() == 1)
					return true; //if one row is updated return true
				else 			//else if no row is updated or unexpected number of rows are updated
					return false;//user is not guaranteed registered, so return false
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
			//call a stored procedure GetUserInfo to verify if user is registered
			//if user is registered, relevant info is returned
			CallableStatement callProc = conn.prepareCall("{call GetUserInfo(?,?)}");

			callProc.setString("someUsername", username);
			callProc.setString("somePassword", password);
			
			ResultSet rs = callProc.executeQuery();
			if (rs.next())	//just get the first row
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