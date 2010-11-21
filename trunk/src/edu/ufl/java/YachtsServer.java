package edu.ufl.java;

import java.io.*;
import java.net.*;
import java.security.NoSuchAlgorithmException;
import java.util.StringTokenizer;

public class YachtsServer {

	private ServerSocket server;
	private Socket connection;
	
	public YachtsServer(int port) throws IOException {
		server = new ServerSocket(port);
		Runtime.getRuntime().addShutdownHook(new Thread() {
			public void run() {
				try {
					System.out.println("\nShutting down server");
					server.close();
				} catch (IOException e) {}
			}
		});
	}

	private void runServer() {
		try {
			while(true) {
				connection = server.accept();
				System.out.println("Got connection");
				ConnectionHandler conn = new ConnectionHandler(connection);
				conn.start();
			}
		} catch (IOException e) {
			System.err.println("Error in server process: " + e.getMessage());
			e.printStackTrace();
		}
	}
	
	public static void main(String arg[]) throws Throwable {
		YachtsServer server = null;
		if(arg.length == 0) {
			server = new YachtsServer(5255);
			System.out.println("Starting Server on port 5255");
		} else if(arg.length == 1) {
			server = new YachtsServer(Integer.parseInt(arg[0]));
			System.out.println("Starting Server on port " + arg[0]);
		} else {
			System.out.println("Usage: java YachtsServer      -> starts server on default port 5255");
			System.out.println("       java YachtsServer port -> starts server on given port");
			System.exit(1);
		}
		
		// start session manager 
		SessionManager sessionmanager = SessionManager.getSessionManager();
		
		// start login manager 
		LoginManager loginmanager = LoginManager.getLoginManager();
		
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
		
		public void processCommand(String inputstring){
			// get the command
			StringTokenizer st = new StringTokenizer(inputstring,"^");
			boolean flag=true;
			String token ="",message="";
			Command cmd = new Command();
			
			while(st.hasMoreTokens()){
				if(flag){
					// first token
					token = st.nextToken();
					
					System.out.println("Extracted command: "+token);
					flag=false;
					
					if(token.equalsIgnoreCase("REGISTER")){
						cmd.registerCommand(inputstring);
					}
					else if(token.equalsIgnoreCase("LOGIN")){
						cmd.loginCommand(inputstring);
					}
				}
			}
		}
		
		public void run() {
			try {
				in = new BufferedReader(new InputStreamReader(conn.getInputStream()));
				out = new PrintWriter(conn.getOutputStream());
				String command = null;
				while((command = in.readLine())!=null){
					// receive command
					System.out.println("Got command: " + command);
					
					// process command
					processCommand(command);
				}
				in.close();
				conn.close();
				
			} catch (IOException e) {
				System.err.println("ERROR: " + e.getMessage());
				e.printStackTrace();
			}
		}
		
	}
	
}
