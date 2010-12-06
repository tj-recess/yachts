package edu.ufl.java;

import java.net.Socket;
import java.util.ArrayList;
import java.util.StringTokenizer;

public class Command
{
		private LoginManager loginManager = null;
		private DBManager dbm = null;
		private SessionManager sessionManager = null;
		
		public Command()
		{
			loginManager = LoginManager.getLoginManager();
			sessionManager = SessionManager.getSessionManager();
			dbm = new DBManager();
		}
				
	
		// parses the input string into a string array 
		public String[] parse(String inputstring){
			String[] params = new String[10];
			int count=0;
			
			// get the parameters
			StringTokenizer st = new StringTokenizer(inputstring,"^");
			while(st.hasMoreTokens()){
				params[count++] = st.nextToken();
			}
			
			return params;
		}
		
		// login processing
		public boolean loginCommand(ArrayList<String> params, Socket conn) 
		{
			if (loginManager == null)
				return false;
			
			return loginManager.loginUser(params.get(1), params.get(2), conn);
		}
		
		// registers a new user
		public boolean registerCommand(ArrayList<String> params) 
		{			
			if (dbm == null)
				return false;
			
			return dbm.registerUser(new User(params.get(3),params.get(4), params.get(1), params.get(2), params.get(5), params.get(6)));
		}

		public void createSessionCommand(ArrayList<String> params) 
		{
			if (sessionManager == null)
				return;

			params.remove(0);//remove command name
			sessionManager.createSession(params);
		}
		
		public void addUsersToSessionCommand(ArrayList<String> params) 
		{
			if (sessionManager == null)
				return;

			params.remove(0);//remove command name
			String sessionID = params.get(0);
			params.remove(0);//remove sessionID
			sessionManager.addUserToSession(sessionID, params);
		}

		public String getAllLoggedInUsers()
		{
			if (loginManager == null)
				return null;
			
			return loginManager.getLoggedInUsers();
		}
		
		public void removeUserFromSessionCommand(ArrayList<String> params)
		{
			if (sessionManager == null)
				return;

			sessionManager.removeUserFromSession(params.get(1), params.get(2));
		}
		
		public void chat(ArrayList<String> params)
		{
			if (sessionManager == null)
				return;

			sessionManager.chat(params.get(1), params.get(2), params.get(3));
		}
}
