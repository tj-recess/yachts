package edu.ufl.java;

import java.util.StringTokenizer;

public class Command {
		
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
		public boolean loginCommand(String commandstring,String socketinfo) {
			System.out.println("COMMANDPARSER: Received login command...");
			String[] params = new String[10];
			
			params = parse(commandstring);
			DBManager dbm = new DBManager();
			
			return dbm.login(params[1], params[2],socketinfo);
			
		}
		
		// registers a new user
		public boolean registerCommand(String commandstring) {
			System.out.println("COMMANDPARSER: Received register command...");
			String[] params = new String[10];
			
			params = parse(commandstring);
			
			// register the user
			User newuser = new User(params[1], params[2], params[3], params[4],params[5],params[6]);
			DBManager dbm = new DBManager();
			dbm.addUserToDB(newuser);
			
			System.out.println("COMMANDPARSER: User added to database");
			return true;
		}

		public boolean createSessionCommand(String inputstring) {
			// TODO Auto-generated method stub
			
			return false;
		}

		public String getAllLoggedInUsers(String inputstring) {
			// TODO Auto-generated method stub
			System.out.println("COMMANDPARSER: Received getAllLoggedInUsers command...");
			return LoginManager.getLoginManager().getLoggedInUsers();
		}
}
