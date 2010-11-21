package edu.ufl.java;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;

public class LoginManager {
	// keeps a track of currently users that are currently logged in to the chat server
	ArrayList<User> loggedInUsers; 
	
	/* the only instance of this class */
	private static LoginManager loginmgr = new LoginManager();
	
	/* always returns the one instance */
	public static LoginManager getLoginManager(){
		return loginmgr;
	}
	
	private LoginManager(){} // singleton
	
	
	
	public boolean logoutUser(User user){
		return LoginManager.getLoginManager().loggedInUsers.remove(user);
	}
	public /*User*/ boolean loginUser(String username, String password){
		
		/* find the user based on username and password */
		User u = null;
		
		/* put the user in the logged in users list */
		return LoginManager.getLoginManager().loggedInUsers.add(u);
	}
	//creates user and store it’s fields to database
	 //public User registerUser(String fname, String lname, String password, String username,String location,String email) throws NoSuchAlgorithmException, UnsupportedEncodingException {
		 //return new User(fname, lname, password,username,location,email);
		 
	 //}
}
