package Jyachts.src.edu.ufl.java;

import java.io.*;
import java.net.*;
import java.util.StringTokenizer;

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
		//SessionManager sessionmanager = SessionManager.getSessionManager();
		
		// start login manager 
		//LoginManager loginmanager = LoginManager.getLoginManager();
		
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
			StringTokenizer st = new StringTokenizer(inputstring,"^");
			boolean flag=true, status;
			String token ="";
			String socketinfo = ""+conn.getRemoteSocketAddress();
			Command cmd = new Command();
			
			while(st.hasMoreTokens()){
				if(flag){
					// first token
					token = st.nextToken();
					
					System.out.println("YACHTSERVER: Extracted command: "+token);
					flag=false;
					
					if(token.equalsIgnoreCase("REGISTER")){
						status = cmd.registerCommand(inputstring);
						return ""+status;
					}
					
					else if(token.equalsIgnoreCase("LOGIN")){
						System.out.println("YACHTSERVER: Login: Client socket details: "+this.conn);
						status = cmd.loginCommand(inputstring,socketinfo,this.conn);
						
						if (status){
							// logged in success message
							return "LoginResponse^SUCCESS^User authenticated successfully";
						}
						
						return "LoginResponse^ERROR^Login Error. Check your credentials";
					}
					
					else if(token.equalsIgnoreCase("CreateSession")){
						String sessionCreationStatus = cmd.createSessionCommand(inputstring);
						return sessionCreationStatus;
					}
					
					else if(token.equalsIgnoreCase("getAllLoggedInUsers")){
						String userlist = cmd.getAllLoggedInUsers(inputstring);
						System.out.println("YACHTSERVER: User list: "+userlist);
						return userlist;
					}
					else if(token.equalsIgnoreCase("Chat")){
						// find out session in which the message was posted
						
						// post message to all session participants
						return "Received chat message: "+inputstring;
					}
					else{
						// unknown command
						System.out.println("YACHTSERVER: ERROR: Unknown command from Client: "+inputstring);
						return "Error: Unknown command received: "+inputstring;
					}
				}
			}
			return "<error>";
		}
		
		public void run() {
			try {
				in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
				out = new PrintWriter(conn.getOutputStream());
				String command = null, serverresp;
				
				while((command = in.readLine())!=null){
					// receive command
					System.out.println("YACHTSERVER: Got command: " + command);
					
					// process command
					serverresp = processCommand(command);
					out.println("Response: "+serverresp);
					out.flush();
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