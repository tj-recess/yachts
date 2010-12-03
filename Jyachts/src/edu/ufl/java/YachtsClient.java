package edu.ufl.java;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Random;
import java.util.StringTokenizer;
import java.util.TreeSet;






public class YachtsClient implements Runnable {
	
	
	int[] a= new int[10];
	String[] commands = {"login^userXX^pwd","createsession^userXX^userYY","adduserstosession^SS^userXX^userYY^userZZ","chat^userXX^SS^Hello","chat^userXX^SS^Bye"};
	//String[] commands = {"register^userXX^pwd^usXX^usrXX^usa^userXX@gmail.com"};
	static volatile int count=1;
	static final int numUsers= 2;
	
	
	public static void main(String[] arg) throws Throwable {
		
		YachtsClient yachtsClient = new YachtsClient();	
		while(count<numUsers){
			Thread t = new Thread(yachtsClient,Integer.toString(count++));
			t.start();
			
		}
		
	} 
	@Override
	public void run() {
		
		
		try {
			runSingleClient();
		} catch (Throwable e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	
	void runSingleClient() throws Throwable{

		String userID = Thread.currentThread().getName();
		Socket connection = new Socket("localhost", 3000);
		InputStreamReader isr = new InputStreamReader(connection.getInputStream());
		BufferedReader in = new BufferedReader(isr);
		//BufferedReader console = new BufferedReader(new InputStreamReader(new FileInputStream(arg[0])));
		//BufferedReader console = new BufferedReader(new InputStreamReader(new FileInputStream("/home/dwaipayan/cmd.txt")));
		BufferedWriter fout = new BufferedWriter(new FileWriter("/home/dwaipayan/chatlogs/user"+userID+".txt"));
		
		int messageCount=0;
		PrintWriter out = new PrintWriter(connection.getOutputStream());
		String clientreq;
		String serverresp;
		String onlineusers ="";
		ArrayList<String> loggedInUsers = new ArrayList<String>();
		TreeSet<String> sessions = new TreeSet<String>();
		ArrayList<String>  responseList = new ArrayList<String>();
		ArrayList<String>  requestList = new ArrayList<String>();
		while(messageCount<commands.length){
		//while((clientreq = console.readLine()) != null) {
			//System.out.println("CONSOLEINPUT: "+clientreq);
			// send chat invite to other online users
			clientreq=commands[messageCount++];
			requestList = parse(clientreq);
			String requestType= requestList.get(0);
			
			if("login".equalsIgnoreCase(requestType)){
				clientreq=clientreq.replace("XX",userID );
				
			}
			else if("register".equalsIgnoreCase(requestType)){
				clientreq=clientreq.replace("XX", userID);
			}
			else if ("createsession".equalsIgnoreCase(requestType)){
				clientreq=clientreq.replace("XX", userID);
				clientreq=clientreq.replace("YY", Integer.toString(new Random().nextInt(numUsers-1)+1));
			}
			else if("adduserstosession".equalsIgnoreCase(requestType)){
				clientreq=clientreq.replace("XX", userID);
				clientreq=clientreq.replace("YY", Integer.toString(new Random().nextInt(numUsers-1)+1));
				clientreq=clientreq.replace("ZZ", Integer.toString(new Random().nextInt(numUsers-1)+1));
				clientreq=clientreq.replace("SS", sessions.first());
			}
			else if("chat".equalsIgnoreCase(requestType)){
				clientreq=clientreq.replace("XX", userID);
				clientreq=clientreq.replace("SS", sessions.first());
				
			}
		
			System.out.println("User"+userID+" : "+clientreq);
			out.print(clientreq);
			Thread.sleep(1000);
			out.flush();
			/*for erlang*/
			
			char[] cbuf = new char[1000]; 
 			in.read(cbuf);
 			serverresp = new String(cbuf);
 			//parse server response into parts
 			
 			/*System.out.println("User"+userID+" : Server Response: "+serverresp);
 			System.out.println("User"+userID+" : SessionList: "+sessions);*/
 			
 			fout.write("User"+userID+" : Server Response: "+serverresp);
 			responseList= parse(serverresp);
 			String responseType=responseList.get(0);
 			//			serverresp=in.readLine();
			
			// deal with server responses
			
			if("loginResponse".equalsIgnoreCase(responseType)){
				
			}
			else if("addUsersToSessionResponse".equalsIgnoreCase(responseType)){
				if("success".equalsIgnoreCase(responseList.get(1))){
					sessions.add(responseList.get(2));
				}
				else{
					
				}
			}
			else if("chatResponse".equalsIgnoreCase(responseType)){
				if("success".equalsIgnoreCase(responseList.get(1))){
					
				}
				else{
					
				}
			}
			else if("removeUserFromSessionResponse".equalsIgnoreCase(responseType)){
				if("success".equalsIgnoreCase(responseList.get(1))){
					sessions.remove(responseList.get(2));
				}
				else{
					
				}
			}
			
			
			
			
			
			/*if(serverresp.contains("LoggedInUsers^")){
				// got a list of logged in users - add it to local arraylist
				loggedInUsers = parse(serverresp);
				loggedInUsers.remove(0); // removes the first entry - the response type identifier
				System.out.println("YACHTCLIENT: Stored list of users locally: "+loggedInUsers.toString());
			}
			else if(serverresp.contains("CreateSessionResponse^")){
				// store the list of sessions and respective users.
				System.out.println("YACHTCLIENT: Received session details.. storing locally ");
				
			}*/
			
		}
		
		fout.close();
		//in.close();
		//out.close();
		//console.close();
	
	}

	public static ArrayList<String> parse(String inputstring){
		ArrayList<String> params = new ArrayList<String>();
				
		// get the parameters
		StringTokenizer st = new StringTokenizer(inputstring,"^");
		while(st.hasMoreTokens()){
			params.add(st.nextToken());
		}
		
		return params;
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
