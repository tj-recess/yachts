package edu.ufl.java;

import java.util.ArrayList;

public class LoginManager {
        // keeps a track of currently users that are currently logged in to the chat server
        private static ArrayList<String> loggedInUsers = new ArrayList<String> (); 
        
        /* the only instance of this class */
        private static LoginManager loginmgr = new LoginManager();
        
        /* always returns the one instance */
        public static LoginManager getLoginManager(){
                return loginmgr;
        }
        
        private LoginManager(){} // singleton
        
        public boolean logoutUser(String username){
        		System.out.println("LoginManager: Removing user from logged in users list "+username);
        		boolean status = loggedInUsers.remove(username); 
        		System.out.println("LoginManager: Status: "+status);
        		return status;
        }
        
        public boolean loginUser(String username){
                /* put the user in the logged in users list */
        		System.out.println("LoginManager: Adding user to logged in users list "+username);
            	boolean status = loggedInUsers.add(username);
            	System.out.println("LoginManager: Status: "+status);
            	return status;
                
        }
        public String getLoggedInUsers(){
        	return loggedInUsers.toString();
        }
}
