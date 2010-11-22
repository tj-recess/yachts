package edu.ufl.java;

import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;

public class YachtsClient {
	
	public static void main(String[] arg) throws Throwable {
		
		Socket connection = new Socket("localhost", 5255);
		BufferedReader in = new BufferedReader(new InputStreamReader(connection.getInputStream()));
		BufferedReader console = new BufferedReader(new InputStreamReader(new FileInputStream(arg[0])));
		
		PrintWriter out = new PrintWriter(connection.getOutputStream());
		String s;
		String serverresp;
		
		while((s = console.readLine()) != null) {
			System.out.println("CONSOLEINPUT: "+s);
			out.println(s);
			out.flush();
			serverresp=in.readLine();
			System.out.println("YACHTCLIENT: Server says: "+serverresp);
			
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
