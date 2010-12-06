package edu.ufl.java;

import java.io.*;
import java.net.*;
import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class YachtsServer {

	private ServerSocket server;
	private Socket connection;
	int concurrentconnectioncount=0;
	private Command cmd = null;
	private static ExecutorService executor; 

	
	public YachtsServer(int port) throws IOException {
		server = new ServerSocket(port);
		cmd = Command.getCommandInstance();
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
				
				executor.execute(new ConnectionHandler(connection, cmd));
				
				/* Can be used for one-thread-per-user scenario
				ConnectionHandler conn = new ConnectionHandler(connection, cmd);
				conn.start();*/
			}
		} catch (IOException e) {
			System.err.println("YACHTSERVER: Error in server process: " + e.toString());
		}
	}
	
	public static void main(String arg[]) throws Throwable {
		YachtsServer server = null;
		if(arg.length == 0) {
			server = new YachtsServer(3000);
			System.out.println("YACHTSERVER: Starting Server on port 5255");
		} else if(arg.length == 1) {
			server = new YachtsServer(Integer.parseInt(arg[0]));
			System.out.println("YACHTSERVER: Starting Server on port " + arg[0]);
		} else {
			System.out.println("YACHTSERVER: Usage: java YachtsServer      -> starts server on default port 5255");
			System.out.println("       java YachtsServer port -> starts server on given port");
			System.exit(1);
		}
		
		// start server
		executor = Executors.newCachedThreadPool();
		server.runServer();
	}
	
	private static class ConnectionHandler extends Thread {
		
		private Socket conn;
		private BufferedReader in;
		private PrintWriter out;
		private Command cmd = null;
		
		public ConnectionHandler(Socket connection, Command cmd) 
		{
			this.conn = connection;
			this.cmd = cmd;
		}
		
		public String processCommand(String inputstring) throws IOException{
			// get the command
			ArrayList<String> tokensList = Utils.parse(inputstring);
			boolean status;

			
			String cmdName = tokensList.get(0);
			ConsoleLogger.log("YACHTSERVER: Extracted command: "+ cmdName + "\n");
				
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
				ConsoleLogger.log("YACHTSERVER: Login: Client socket details: "+this.conn);
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
				ConsoleLogger.log("YACHTSERVER: User list: "+userlist+ "\n");
				return userlist;
			}
			else if(cmdName.equalsIgnoreCase("Chat")){
				cmd.chat(tokensList);
			}
			else if(cmdName.equalsIgnoreCase("removeUserFromSession"))
			{
				cmd.removeUserFromSessionCommand(tokensList);
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
		 			int charsRead = in.read(cbuf);
		 			if (charsRead == -1)
		 			{
		 				logout = true;
		 				break;
		 			}
		 			String cmd = new String(cbuf);
		 			ArrayList<String> commandsReceived = Utils.parseMessage(cmd);
					
					for(String command:commandsReceived)
					{
						// process command
						serverresp = processCommand(command);
						if(serverresp != null)
						{   ConsoleLogger.log("server response to client: " + serverresp);
						
							out.print(serverresp + "~");
							out.flush();
						}
					}
				}
			} catch (IOException e) {
				ConsoleLogger.log("error in connection with client" + e.toString() + "\n") ;
			}
			finally{
				try {
					out.close();
					conn.close();
					in.close();
				} catch (IOException e) {
					ConsoleLogger.log("error in closing socket : " + e.toString() + "\n") ;
				}				
			}

			
		}
		
	}	
}