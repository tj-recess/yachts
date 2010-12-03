package Jyachts.src.edu.ufl.java;

import java.net.Socket;
import java.util.HashMap;
import java.util.Map;

public class LoginManager {
        // keeps a track of currently users that are currently logged in to the chat server
        //private static ArrayList<String> loggedInUsers = new ArrayList<String> ();  - need to store both username 
		// and their ip/port config - so using hashmap instead
	
        Map<String,String> loggedInUsersMap = new HashMap<String,String>();
        Map<String,Socket> loggedInUsersSockets = new HashMap<String,Socket>();
        
        /* the only instance of this class */
        private static LoginManager loginmgr = new LoginManager();
        
        /* always returns the one instance */
        public static LoginManager getLoginManager(){
                return loginmgr;
        }
        
        private LoginManager(){} // singleton
        
        public boolean logoutUser(String username){
        		System.out.println("LOGINMGR: Removing user from logged in users list "+username);
        		String userremoved = loggedInUsersMap.remove(username); 
        		loggedInUsersSockets.remove(username);
        		System.out.println("LOGINMGR: User Removed: "+userremoved);
        		return true;
        }
        
        public boolean loginUser(String username,String socketinfo, Socket usersocket){
                /* put the user in the logged in users list */
        		System.out.println("LOGINMGR: Adding user to logged in users list: "+username);
        		if(loggedInUsersMap.containsKey(username)){
        			// user already logged in
        			System.out.println("LOGINMGR: User already logged in. Doing nothing");
        			return true;
        		}
        		else{
        			// user added to list of logged in users.
        			loggedInUsersMap.put(username,socketinfo);
        			loggedInUsersSockets.put(username, usersocket);
                	System.out.println("LOGINMGR: Added User: "+username+"\t Socket Details: "+socketinfo);
                	return true;
        		}
        }
        
        public String getLoggedInUsers(){
        	return "LoggedInUsers^"+loggedInUsersMap.keySet().toString().replace('[', ' ').replace(']', ' ').replace(',','^').replaceAll(" ", "");
        }
}
