package edu.ufl.java;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Random;
import java.util.StringTokenizer;
import java.util.TreeSet;
import java.util.concurrent.*;


public class JavaClient implements Runnable {
	
	static ExecutorService executor;
	static final String LOCATION = System.getProperty("user.home")+"/chatlogs"; //location for logging chatlogs of users
	//Test Input Commands
	static final String[] COMMANDS = {"login^userXX^pwd","createsession^userXX^userYY","adduserstosession^SS^userXX^userYY^userZZ","chat^userXX^SS^Hello","chat^userXX^SS^Bye","removeuserfromsession^SS^userXX","logout^userXX"};
	//static final String[] COMMANDS = {"register^userXX^pwd^usXX^usrXX^usa^userXX@gmail.com"}; 
	static volatile int count=1;
	static final int NUM_USERS= 20;		//Number of dummy users to be created
	static final int PORT_NO = 3000;	//port number to connect to
	
	public static void main(String[] arg) throws Throwable {
		(new File(LOCATION)).mkdir();
		JavaClient client = new JavaClient();
		executor = Executors.newCachedThreadPool();
		while(count<NUM_USERS){			
			executor.execute(new Thread(client));
		}
		
	} 
	@Override
	public void run() {			
		try {
			runSingleClient();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	void runSingleClient() throws Exception{

		String userID = Integer.toString(count++);
		Socket connection = null;
		while(true){try{connection = new Socket("localhost", PORT_NO); break;}catch(Exception ste){/*eat exception*/}}
		InputStreamReader isr = new InputStreamReader(connection.getInputStream());
		BufferedReader in = new BufferedReader(isr);
		String clientreq;
        BufferedWriter	fout = new BufferedWriter(new FileWriter(LOCATION+"/user"+userID+".txt"));
		int messageCount=0;
		PrintWriter out = new PrintWriter(connection.getOutputStream());
		TreeSet<String> sessions = new TreeSet<String>(); 
		ArrayList<String>  responseList = new ArrayList<String>();
		ArrayList<String>  requestList = new ArrayList<String>();
		boolean login=false;
		do{
			//generate dummy messages
			if(messageCount<COMMANDS.length){
				clientreq=COMMANDS[messageCount++];
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
					clientreq=clientreq.replace("YY", Integer.toString(new Random().nextInt(NUM_USERS-1)+1));
				}
				else if("adduserstosession".equalsIgnoreCase(requestType)){
					clientreq=clientreq.replace("XX", userID);
					clientreq=clientreq.replace("YY", Integer.toString(new Random().nextInt(NUM_USERS-1)+1));
					clientreq=clientreq.replace("ZZ", Integer.toString(new Random().nextInt(NUM_USERS-1)+1));
					clientreq=clientreq.replace("SS", sessions.first());
				}
				else if("chat".equalsIgnoreCase(requestType)){
					clientreq=clientreq.replace("XX", userID);
					clientreq=clientreq.replace("SS", sessions.first());
				}
				else if("removeuserfromsession".equalsIgnoreCase(requestType)){
					clientreq=clientreq.replace("XX", userID);
					clientreq=clientreq.replace("SS", sessions.first());
				}
				else if("logout".equalsIgnoreCase(requestType)){
					clientreq=clientreq.replace("XX", userID);
				}
				out.print(clientreq+"~");
				out.flush();
			}
			
			
			char[] cbuf = new char[2000];
 			in.read(cbuf);
 			
 			String response = new String(cbuf);
 			//parse server response into parts

 			ArrayList<String> serverResponseList = parseMessages(response);
 			//process each server message	
 			for(String serverresp:serverResponseList){
				if(serverresp.length()<=0)
					continue;
		 			//System.out.println("User"+userID+" : Server Message: "+serverresp);
		 			//System.out.println("User"+userID+" : SessionList: "+sessions);		
		 			responseList= parse(serverresp);
		 			String responseType=responseList.get(0);
		 			if("registerResponse".equalsIgnoreCase(responseType)){
						if("success".equalsIgnoreCase(responseList.get(1))){
				 				fout.append(responseList.get(2)+"\n");							
						}
						else{
								fout.append(responseList.get(2)+"\n");	
						}
					}	

		 			else if("loginResponse".equalsIgnoreCase(responseType)){
						if("success".equalsIgnoreCase(responseList.get(1))){
				 				fout.append(responseList.get(2)+"\n");
				 				login=true;							
						}
						else{
								fout.append(responseList.get(2)+"\n");				 			
						}
						
					}
					else if("addUsersToSessionResponse".equalsIgnoreCase(responseType)){
						if("success".equalsIgnoreCase(responseList.get(1))){
							
							if(sessions.contains(responseList.get(2))){
								fout.append(responseList.get(3)+" has joined the chatroom "+responseList.get(2)+"\n");	
							}
							else{
								sessions.add(responseList.get(2));
								fout.append("You have been added to chatroom "+responseList.get(2));
								if(responseList.size()>3){
									fout.append(" having members ");
									for(int i=3;i<responseList.size();i++){
										fout.append(responseList.get(i)+" ");
									}
									
								}
								fout.append("\n");
									
							}
							
						}
						else{
								fout.append(responseList.get(2)+"\n");
						}
					}
					else if("chatResponse".equalsIgnoreCase(responseType)){
						if("success".equalsIgnoreCase(responseList.get(1))){
							String chatMessage=responseList.get(2);
							fout.append("ChatRoom: "+chatMessage.replaceFirst(":", "\t")+"\n");
						}
						else{
							fout.append(responseList.get(2)+"\n");
						}
					}
					else if("removeUserFromSessionResponse".equalsIgnoreCase(responseType)){
						if("success".equalsIgnoreCase(responseList.get(1))){
							if(("user"+userID).equalsIgnoreCase(responseList.get(3))){
								sessions.remove(responseList.get(2));
								fout.append("You have been removed from chatroom "+responseList.get(2)+"\n");
							}
							else{
								fout.append(responseList.get(3)+" has exited from chatroom "+responseList.get(2)+"\n");
							}
							
						}
						else{
							fout.append(responseList.get(2)+"\n");
						}
					}
					else if("logoutResponse".equalsIgnoreCase(responseType)){
						if("success".equalsIgnoreCase(responseList.get(1))){
							login=false;
							fout.append("You have been logged out successfully\n");
						}
					}
					
			}
			fout.flush();
			
			
			
		}while(login); //wait till user logs out after loggin in
		
		fout.close();
		in.close();
		out.close();
		
	
	}
	//parse ~ separated multiple messages from server
	public static ArrayList<String> parseMessages(String inputstring){
		ArrayList<String> params = new ArrayList<String>();
				
		// get the parameters
		StringTokenizer st = new StringTokenizer(inputstring,"~");
		while(st.hasMoreTokens()){
			params.add(st.nextToken());
		}
		
		return params;
	}
	//parse single message
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
