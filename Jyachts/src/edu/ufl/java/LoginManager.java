package edu.ufl.java;

import java.net.Socket;
import java.util.HashMap;
import java.util.Map;

public class LoginManager {
        // keeps a track of currently users that are currently logged in to the chat server
        //private static ArrayList<String> loggedInUsers = new ArrayList<String> ();  - need to store both username 
		// and their ip/port config - so using hashmap instead
	
        Map<String,User> loggedInUsersMap = null;
        Map<String,Socket> loggedInUsersSockets = null;
        
        /* the only instance of this class to avoid double checked locking*/
        private static LoginManager loginmgr = new LoginManager();
        
        // always returns the one instance 
        public static synchronized LoginManager getLoginManager(){
        		return loginmgr;
        }
        
        private LoginManager(){
        	loggedInUsersMap = new HashMap<String,User>();
        	loggedInUsersSockets = new HashMap<String,Socket>(); 
        } // singleton
        
        public boolean logoutUser(String username){
        		System.out.println("LOGINMGR: Removing user from logged in users list "+username);
        		User removedUser = loggedInUsersMap.remove(username); 
        		loggedInUsersSockets.remove(username);
        		System.out.println("LOGINMGR: User Removed: "+ removedUser.getUsername());
        		return true;
        }
        
        public boolean loginUser(String username, String password, Socket usersocket){
                /* put the user in the logged in users list */
        		System.out.println("LOGINMGR: Adding user to logged in users list: "+username);
        		if(loggedInUsersMap.containsKey(username)){
        			// user already logged in
        			System.out.println("LOGINMGR: User already logged in.");
        			return true;
        		}
        		else{
        			DBManager dbm = new DBManager();
        			if (dbm == null)
        				return false;
        			User loggedInUser = dbm.loginUser(username, password);
        			if(loggedInUser != null)
        			{
        				// user added to list of logged in users.
            			loggedInUsersMap.put(username,loggedInUser);
            			loggedInUsersSockets.put(username, usersocket);
                    	System.out.println("LOGINMGR: Added User: "+username+"\t Socket Details: "+ usersocket.toString());
                    	return true;
        			}
        		}
        		//control here means unsuccessful in logging in
        		return false;
        }
        
        public User getUserInfo(String username)
        {
        	return loggedInUsersMap.get(username);
        }
        
        public String getLoggedInUsers(){
        	return "LoggedInUsers^"+loggedInUsersMap.keySet().toString().replace('[', ' ').replace(']', ' ').replace(',','^').replaceAll(" ", "");
        }
        
        public synchronized Socket getUserSocket(String username)
        {
        	return loggedInUsersSockets.get(username);
        }
}
