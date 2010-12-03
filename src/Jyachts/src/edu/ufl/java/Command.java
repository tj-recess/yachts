package Jyachts.src.edu.ufl.java;

import java.io.PrintWriter;
import java.net.Socket;
import java.util.ArrayList;
import java.util.StringTokenizer;
import org.apache.commons.lang.*;

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
		public boolean loginCommand(String commandstring,String socketinfo,Socket conn) {
			System.out.println("COMMANDPARSER: Received login command...");
			System.out.println("COMMANDPARSER: Socket Details: "+conn);
			
			String[] params = new String[10];
			
			params = parse(commandstring);
			DBManager dbm = new DBManager();
			
			return dbm.login(params[1], params[2],socketinfo,conn);
			
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

		public String createSessionCommand(String inputstring) {
			// TODO Auto-generated method stub
			System.out.println("COMMANDPARSER: received create session command ");
			String[] params = new String[10];
			String userList="", successmesg="";
			ArrayList<String> usersInSession = new ArrayList<String>();
			
			params = parse(inputstring);
			
			try{
				// register the session
				Session session = new Session(true); // this is a group chat - true for all cases
				
				for (int i=1; i<=StringUtils.countMatches(inputstring, "^");i++){
					User u = DBManager.getUser(params[i]);
					session.addUser(u); // add all users to session
					userList += "^"+params[i];
					usersInSession.add(params[i]);
					System.out.println("User's connection details: "+LoginManager.getLoginManager().loggedInUsersSockets.get(params[i]));
				}
				successmesg = "CreateSessionResponse^SUCCESS^"+session.getSessionID()+userList;
				// send message to all users in session
				
				// inform to each user
				for (int j=0;j<usersInSession.size();j++){
					Socket s = LoginManager.getLoginManager().loggedInUsersSockets.get(usersInSession.get(j));
					PrintWriter pw = new PrintWriter(s.getOutputStream());
					pw.println(successmesg);
					pw.flush();
				}
					
				return successmesg;
				
			}catch(Exception e){
				System.out.println("COMMANDPARSER: ERROR: Error in Creating Session");
				e.printStackTrace();
				return "CreateSessionResponse^ERROR";
			}
		}

		public String getAllLoggedInUsers(String inputstring) {
			// TODO Auto-generated method stub
			System.out.println("COMMANDPARSER: Received getAllLoggedInUsers command...");
			return LoginManager.getLoginManager().getLoggedInUsers();
		}
}
