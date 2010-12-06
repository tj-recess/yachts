package edu.ufl.java;

import java.net.Socket;
import java.util.HashMap;
import java.util.Map;

public class LoginManager {
        // keeps a track of currently users that are currently logged in to the chat server
	
        Map<String,User> loggedInUsersMap = null;
        Map<String,Socket> loggedInUsersSockets = null;
        
        /* the only instance of this class to avoid double checked locking*/
        private static LoginManager loginmgr = new LoginManager();
        private DBManager dbm = null;
        
        // always returns the one instance 
        public static LoginManager getLoginManager(){
        		return loginmgr;
        }
        
        private LoginManager(){
	        	loggedInUsersMap = new HashMap<String,User>();
	        	loggedInUsersSockets = new HashMap<String,Socket>();
	        	dbm = new DBManager();
        } // singleton
        
        public User logoutUser(String username)
        {
    		ConsoleLogger.log("LOGINMGR: Removing user from logged in users list "+username);
    		User removedUser = loggedInUsersMap.remove(username); 
    		loggedInUsersSockets.remove(username);
    		ConsoleLogger.log("LOGINMGR: User Removed: "+ removedUser.getUsername());
    		return removedUser;
        }
        
        public boolean loginUser(String username, String password, Socket usersocket)
        {
            /* put the user in the logged in users list */
    		ConsoleLogger.log("LOGINMGR: Adding user to logged in users list: "+username);
    		if(loggedInUsersMap.containsKey(username)){
    			// user already logged in
    			ConsoleLogger.log("LOGINMGR: User already logged in.");
    			return true;
    		}
    		else
    		{
    			if (dbm == null)
    				return false;
    			User loggedInUser = dbm.loginUser(username, password);
    			if(loggedInUser != null)
    			{
    				// user added to list of logged in users.
        			loggedInUsersMap.put(username,loggedInUser);
        			loggedInUsersSockets.put(username, usersocket);
                	ConsoleLogger.log("LOGINMGR: Added User: "+username+"\t Socket Details: "+ usersocket.toString());
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
        
        public Socket getUserSocket(String username)
        {
        	return loggedInUsersSockets.get(username);
        }
}
