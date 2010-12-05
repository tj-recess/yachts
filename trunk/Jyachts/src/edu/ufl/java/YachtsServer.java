package edu.ufl.java;

import java.io.*;
import java.net.*;
import java.util.ArrayList;

public class YachtsServer {

	private ServerSocket server;
	private Socket connection;
	int concurrentconnectioncount=0;
	
	public YachtsServer(int port) throws IOException {
		server = new ServerSocket(port);
		Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				try {
					System.out.println("\nYACHTSERVER: Shutting down server");
					server.close();
				} catch (IOException e) {}
			}
		});
	}

	private void runServer() {
		try {
			while(true) {
				connection = server.accept();
				concurrentconnectioncount++;
				System.out.println("YACHTSERVER: Got connection #: "+concurrentconnectioncount+
						"\nYACHTSERVER: Conn: connection.getRemoteSocketAddress(): "+connection.getRemoteSocketAddress());
				
				ConnectionHandler conn = new ConnectionHandler(connection);
				conn.start();
			}
		} catch (IOException e) {
			System.err.println("YACHTSERVER: Error in server process: " + e.getMessage());
			e.printStackTrace();
		}
	}
	
	public static void main(String arg[]) throws Throwable {
		YachtsServer server = null;
		if(arg.length == 0) {
			server = new YachtsServer(5255);
			System.out.println("YACHTSERVER: Starting Server on port 5255");
		} else if(arg.length == 1) {
			server = new YachtsServer(Integer.parseInt(arg[0]));
			System.out.println("YACHTSERVER: Starting Server on port " + arg[0]);
		} else {
			System.out.println("YACHTSERVER: Usage: java YachtsServer      -> starts server on default port 5255");
			System.out.println("       java YachtsServer port -> starts server on given port");
			System.exit(1);
		}
		
		// start session manager 
//		SessionManager sessionmanager = SessionManager.getSessionManager();
		
		// start login manager 
//		LoginManager loginmanager = LoginManager.getLoginManager();
		
		// start server
		server.runServer();
	}
	
	private static class ConnectionHandler extends Thread {
		
		private Socket conn;
		private BufferedReader in;
		private PrintWriter out;
		
		public ConnectionHandler(Socket connection) {
			this.conn = connection;
		}
		
		public String processCommand(String inputstring){
			// get the command
			ArrayList<String> tokensList = Utils.parse(inputstring);
			boolean status;

			Command cmd = new Command();
			String cmdName = tokensList.get(0);
			System.out.println("YACHTSERVER: Extracted command: "+ cmdName);
				
			if(cmdName.equalsIgnoreCase("REGISTER"))
			{
				status = cmd.registerCommand(tokensList);
				if (status)
					return "RegisterResponse^success^You have been Registered Successfully";
				else
					return "RegisterResponse^failure^Registration Failed";
			}				
			else if(cmdName.equalsIgnoreCase("LOGIN"))
			{
				System.out.println("YACHTSERVER: Login: Client socket details: "+this.conn);
				status = cmd.loginCommand(tokensList,this.conn);
				
				if (status){
					// logged in success message
					return "LoginResponse^success^User authenticated successfully";
				}
				
				return "LoginResponse^failure^Login Error. Check your credentials";
			}
			
			else if(cmdName.equalsIgnoreCase("CreateSession"))
			{
				cmd.createSessionCommand(tokensList);
			}
			
			else if(cmdName.equalsIgnoreCase("AddUsersToSession"))
			{
				cmd.addUsersToSessionCommand(tokensList);
			}
			
			else if(cmdName.equalsIgnoreCase("getAllLoggedInUsers")){
				String userlist = cmd.getAllLoggedInUsers();
				System.out.println("YACHTSERVER: User list: "+userlist);
				return userlist;
			}
			else if(cmdName.equalsIgnoreCase("Chat")){
				cmd.chat(tokensList);
			}
			else if(cmdName.equalsIgnoreCase("removeUserFromSession"))
			{
				cmd.removeUserFromSessionCommand(tokensList);
			}
			else{
				// unknown command
				System.out.println("YACHTSERVER: ERROR: Unknown command from Client: " + inputstring);
//				return "Error: Unknown command received: "+inputstring;
			}
			return null;

		}
		
		public void run() {
			
			try {
				in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
				out = new PrintWriter(conn.getOutputStream());
				String serverresp;
				boolean logout = false;
				/*for erlang*/
				
				while(!logout)
				{
		
					char[] cbuf = new char[2000];
		 			in.read(cbuf);
		 			String cmd = new String(cbuf);
		 			System.out.println("CMD PRINTED:::: \t" + cmd);
		 			System.out.println("some string to be printed" + "\0");
		 			//parse server response into parts
		 			//System.out.println("User"+userID+" : Server Response: "+response);
		 			ArrayList<String> commandsReceived = Utils.parseMessage(cmd);
					
					for(String command:commandsReceived)
					{
						// receive command
						System.out.println("YACHTSERVER: Got command: " + command);
						
						// process command
						serverresp = processCommand(command);
						if(serverresp != null)
						{   System.out.println("server response to client: " + serverresp);
						
							out.print(serverresp + "~");
							out.flush();
						}
					}
				}
				in.close();
				out.close();
				conn.close();
			} catch (IOException e) {
				System.err.println("ERROR: " + e.getMessage());
				e.printStackTrace();
			}

			
		}
		
	}	
}