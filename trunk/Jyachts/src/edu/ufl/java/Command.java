package edu.ufl.java;

import java.net.Socket;
import java.util.ArrayList;

public class Command
{
		private LoginManager loginManager = null;
		private DBManager dbm = null;
		private SessionManager sessionManager = null;
		
		public Command()
		{
			//get instance of all the utilities required to operate various commands
			loginManager = LoginManager.getLoginManager();
			sessionManager = SessionManager.getSessionManager();
			dbm = new DBManager();
		}
		
		// login processing
		public boolean loginCommand(ArrayList<String> params, Socket conn) 
		{
			if (loginManager == null)
				return false;
			//simply pass on the request to loginManager if it's not null
			return loginManager.loginUser(params.get(1), params.get(2), conn);
		}
		
		// registers a new user
		public boolean registerCommand(ArrayList<String> params) 
		{			
			if (dbm == null)
				return false;
			//simply pass on the request to Database manager so that user is permanently registered in database
			return dbm.registerUser(new User(params.get(3),params.get(4), params.get(1), params.get(2), params.get(5), params.get(6)));
		}

		public void createSessionCommand(ArrayList<String> params) 
		{
			if (sessionManager == null)
				return;

			params.remove(0);//remove command name and pass on rest of the parameters to session manager 
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

		/*
		 * return all users who are logged in so that client can 
		 * pick some user to chat with
		 */
		public String getAllLoggedInUsers()
		{
			if (loginManager == null)
				return null;
		
			return loginManager.getLoggedInUsers();
		}
		
		/*
		 * user can request to remove himself/herself from the session
		 * this commands is redirected to session manager
		 */
		public void removeUserFromSessionCommand(ArrayList<String> params)
		{
			if (sessionManager == null)
				return;

			sessionManager.removeUserFromSession(params.get(1), params.get(2));
		}
		
		/*
		 * send some text message to specified chat (session) 
		 * username, session id, text msg are the intended parameters
		 */
		public void chat(ArrayList<String> params)
		{
			if (sessionManager == null)
				return;

			sessionManager.chat(params.get(1), params.get(2), params.get(3));
		}
}
