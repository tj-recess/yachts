package edu.ufl.java;

import java.io.*;
import java.net.*;
import java.util.ArrayList;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class YachtsServer {

	private ServerSocket server;
	private Socket connection;
	private static int concurrentconnectioncount=0;
	private static ExecutorService executor;	//cached thread pool is used for creating user threads 
	//this helps in dynamically reducing server load when clients are not active
	
	public YachtsServer(int port)
	{
		try
		{
			server = new ServerSocket(port);
			//query run time if server is killed unexpectedly so that all clean up tasks can be done.
			Runtime.getRuntime().addShutdownHook(new Thread() 
			{
				public void run() {
					try {
						System.out.println("\nYACHTSERVER: Shutting down server");
						server.close();
					} 
					catch (IOException e)
					{
						ConsoleLogger.log("Exception while closing the server : " + e.toString());
					}
					finally{						
						//close the logger
						ConsoleLogger.closeLogging();
					}
				}
			});
		}
		catch(Exception ex)
		{
			System.out.println("Can't start server process, check logs for more details...");
			ConsoleLogger.log("Can't start Server, " + ex.toString());
			ConsoleLogger.closeLogging();
		}
	}

	private void runServer() {
		try {
			while(true)		//run in infinite loop to accept clients 
			{
				connection = server.accept();
				concurrentconnectioncount++;
				ConsoleLogger.log("YACHTSERVER: Got connection #: "+concurrentconnectioncount+
						"\nYACHTSERVER: Conn: connection.getRemoteSocketAddress(): "+connection.getRemoteSocketAddress());
				
				executor.execute(new ConnectionHandler(connection));
				//assign the runnables to executor for thread pooling, cached threadpool is used
				
				/* Can be used for one-thread-per-user scenario
				ConnectionHandler conn = new ConnectionHandler(connection, cmd);
				conn.start();*/
			}
		} catch (IOException e) {
			System.out.println("Server is unable to accpet client request. Check logs for more details");
			ConsoleLogger.log("YACHTSERVER: Server is unable to accpet client request: " + e.toString());
		}
	}
	
	public static void decreaseConnectionCount()
	{
		concurrentconnectioncount--;
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
	
	private static class ConnectionHandler extends Thread 
	{		
		private Socket conn;
		private BufferedReader in;
		private PrintWriter out;
		private Command cmd = null;		//a command object to take actions based on user's input
		
		public ConnectionHandler(Socket connection) 
		{
			this.conn = connection;
			this.cmd = new Command();
		}
		
		/*
		 * Processes the command by matching them with those which server accepts
		 * ignore rest of the junk commands. also returns response for 
		 * login and register which are to be sent to only one user. 
		 * Those requests which might involve multiple users, send their response themselves 
		 */
		public String processCommand(String inputstring) throws IOException
		{
			// get the command
			ArrayList<String> tokensList = Utils.parse(inputstring);
			boolean status;
			
			String cmdName = tokensList.get(0);
				
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
				status = cmd.loginCommand(tokensList,this.conn);
				
				if (status){
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
					//reading into a buffer as mulitple messages arrive simultaneously on server 
					//These messages are separated by ~ (separator) and have to be take care independently
					char[] cbuf = new char[2000];
		 			int charsRead = in.read(cbuf);
		 			if(charsRead == -1)
		 			{
		 				logout = true;
		 				break;	//close if this is end of input stream i.e. client is closed
		 			}
		 			String cmd = new String(cbuf);
		 			ArrayList<String> commandsReceived = Utils.parseMessage(cmd);
					
					for(String command:commandsReceived)
					{
						// process each command from array list
						serverresp = processCommand(command);
						if(serverresp != null)
						{   
							ConsoleLogger.log("server response to client: " + serverresp);	//if logging is enabled, every response is logged						
							out.print(serverresp + "~");
							out.flush();	//to send the response to client immediately
						}
					}
				}
			} catch (IOException e) {
				ConsoleLogger.log("error in reading client's input stream : " + e.toString() + "\n") ;
			}
			finally{
				try {
					in.close();
					out.close();
					conn.close();
					YachtsServer.decreaseConnectionCount();	//client is done, decrement it's connection count
				} catch (IOException e) {
					ConsoleLogger.log("error in closing socket : " + e.toString() + "\n") ;
				}				
			}

			
		}
		
	}	
}