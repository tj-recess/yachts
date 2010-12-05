package edu.ufl.java;

import java.net.Socket;
import java.util.ArrayList;
import java.util.StringTokenizer;

public class Command
{
		private LoginManager loginManager = null;
		
		public Command()
		{
			loginManager = LoginManager.getLoginManager();
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
		public boolean loginCommand(ArrayList<String> params, Socket conn) {
			System.out.println("COMMANDPARSER: Received login command...");
			System.out.println("COMMANDPARSER: Socket Details: "+conn);

			loginManager = LoginManager.getLoginManager();
			return loginManager.loginUser(params.get(1), params.get(2), conn);
			
		}
		
		// registers a new user
		public boolean registerCommand(ArrayList<String> params) {
			System.out.println("COMMANDPARSER: Received register command...");
			DBManager dbm = new DBManager();
			
			if (dbm == null)
				return false;
			
			return dbm.registerUser(new User(params.get(3),params.get(4), params.get(1), params.get(2), params.get(5), params.get(6)));
		}

		public void createSessionCommand(ArrayList<String> params) {

			System.out.println("COMMANDPARSER: received create session command ");
			
			params.remove(0);//remove command name
			
			try{
				// register the session
				SessionManager.getSessionManager().createSession(params);
			}catch(Exception e){
				System.out.println("COMMANDPARSER: ERROR: Error in Creating Session");
				e.printStackTrace();
			}
		}
		
		public void addUsersToSessionCommand(ArrayList<String> params) {

			System.out.println("COMMANDPARSER: received add users to session command ");

			params.remove(0);//remove command name
			String sessionID = params.get(0);
			params.remove(0);//remove sessionID
			try{
				// register the session
				SessionManager.getSessionManager().addUserToSession(sessionID, params);
			}catch(Exception e){
				System.out.println("COMMANDPARSER: ERROR: Error in Add User To Session");
				e.printStackTrace();
			}
		}

		public String getAllLoggedInUsers() {
			// TODO Auto-generated method stub
			System.out.println("COMMANDPARSER: Received getAllLoggedInUsers command...");
			return LoginManager.getLoginManager().getLoggedInUsers();
		}
		
		public void removeUserFromSessionCommand(ArrayList<String> params)
		{
			SessionManager.getSessionManager().removeUserFromSession(params.get(1), params.get(2));
		}
		
		public void chat(ArrayList<String> params)
		{
			SessionManager.getSessionManager().chat(params.get(1), params.get(2), params.get(3));
		}
}
