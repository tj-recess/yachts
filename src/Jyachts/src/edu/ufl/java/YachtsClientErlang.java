package Jyachts.src.edu.ufl.java;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.ArrayList;
import java.util.StringTokenizer;

public class YachtsClientErlang {
	
	private static ArrayList<String> loggedInUsers = new ArrayList<String>();
	private static String userName;
	
	
	public static ArrayList<String> parse(String inputstring){
		ArrayList<String> params = new ArrayList<String>();
				
		// get the parameters
		StringTokenizer st = new StringTokenizer(inputstring,"^");
		while(st.hasMoreTokens()){
			params.add(st.nextToken());
		}
		
		return params;
	}
	
	public static void main(String[] arg) throws Throwable {
		
		Socket connection = new Socket("localhost", 3000);
		InputStreamReader isr = new InputStreamReader(connection.getInputStream());
		BufferedReader in = new BufferedReader(isr);
		BufferedReader console = new BufferedReader(new InputStreamReader(new FileInputStream(arg[0])));
		
		PrintWriter out = new PrintWriter(connection.getOutputStream());
		String clientreq;
		String serverresp;
		String onlineusers ="";
		
		
		while((clientreq = console.readLine()) != null) {
			System.out.println("CONSOLEINPUT: "+clientreq);
			// send chat invite to other online users
			if((clientreq.contains("CreateSession"))){
				
				// get list of logged in users.
				for(int i=0; i<loggedInUsers.size();i++)
					onlineusers += "^"+loggedInUsers.get(i);
				
				out.println(clientreq+onlineusers);
			}
			else if(clientreq.contains("Login")){
				ArrayList<String> params = new ArrayList<String>();
				params = parse(clientreq);
				userName = params.get(1);
				System.out.println("YACHTCLIENT: This is user: "+userName);
			}
			else{
					out.print(clientreq);
			}
			out.flush();
			/*for erlang*/
			char[] cbuf = new char[1000]; 
 			in.read(cbuf);
 			serverresp = new String(cbuf);
			
		//	serverresp=in.readLine(); commented for Erlang client
			System.out.println("YACHTCLIENT: Server says: "+serverresp);
			
			// deal with server responses
			if(serverresp.contains("LoggedInUsers^")){
				// got a list of logged in users - add it to local arraylist
				loggedInUsers = parse(serverresp);
				loggedInUsers.remove(0); // removes the first entry - the response type identifier
				System.out.println("YACHTCLIENT: Stored list of users locally: "+loggedInUsers.toString());
			}
			else if(serverresp.contains("CreateSessionResponse^")){
				// store the list of sessions and respective users.
				System.out.println("YACHTCLIENT: Received session details.. storing locally ");
			}
		}
		while((serverresp=in.readLine())!="BYE"){
			System.out.println("YACHTCLIENT: Server Response: "+serverresp);
			if(serverresp.contains("CreateSessionResponse^")){
				// send a test message in the newly created chat window
				System.out.println("YACHTCLIENT: sending a chat message ");
				out.println("Hello there... this is user: "+userName);
			}
		}
		in.close();
		out.close();
		console.close();
	} 
	
}
/*
 *  client message formats
 * 

Register a new user:  Register^Username^Password^FirstName^LastName^Location^EmailId
User login: Login^Username^Password
Create session (start new chat): CreateSession^Username1^Username2
add user to a session: addUserToSession^Username^SessionID
send a message in a chat: acceptAndDisplayText^Username^SessionID^Text
 
 * */
