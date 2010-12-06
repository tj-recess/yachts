package edu.ufl.java;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.Socket;

public class SessionManager 
{
	Map<String, ArrayList<String>> sessionMap = null;		//maintains a map of all users belonging to a particular session (denoted by SessionID)
	private static SessionManager sessionManager = new SessionManager();	//singleton object of this class which is responsible to maintaining sessions globally
	//initializing here itself to avoid double checked locking
	private AtomicInteger sessionCount = new AtomicInteger(0);		//Atomic Integer value of sessionCount is used for creating new sessions as it is thread safe
	
	private SessionManager()
	{
		sessionMap = new ConcurrentHashMap<String, ArrayList<String>>();
	}
	
	public static SessionManager getSessionManager()
	{
		return sessionManager;		
	}
	
	public void createSession(ArrayList<String> userNames)
	{
		LoginManager lm = LoginManager.getLoginManager();
		//check if first user is logged in
		
		if(lm.getUserInfo(userNames.get(0)) == null)
			return;	//invalid requrest, do nothing 

		int newSessionID = sessionCount.getAndIncrement();
		sessionMap.put(Integer.toString(newSessionID), new ArrayList<String>());
		addUserToSessionHelper(Integer.toString(newSessionID), userNames);
			
	}
	
	//assumes that sessionID exists and first user is in the same session
	public void addUserToSessionHelper(String sessionID, ArrayList<String> userNames)
	{
		LoginManager lm = LoginManager.getLoginManager();
				
		for(String username:userNames)
		{
			ArrayList<String> existingUsersInSession = new ArrayList<String>();
			int backoffValue = 1;
			while(true)//optimistic concurrency control in exponential back off pattern
			{
				try{
					existingUsersInSession.clear();//start over to collect all members from session if some new user is added
					existingUsersInSession.addAll(sessionMap.get(sessionID));
					break;//done with taking snapshot, concurrent execution successful
				}
				catch(ConcurrentModificationException cmex)
				{
					ConsoleLogger.log("Concurrent Modification Exception in SessionManager : " + cmex.toString());
					backoffValue*=2;
					try{Thread.sleep(backoffValue);}catch(InterruptedException iex){/*Can be spurious wake up, do nothing*/}
				}
			}
			Socket aSocket = lm.getUserSocket(username);
			if(aSocket != null && !aSocket.isClosed())
			{
				//user is eligible to b;e added
				//send response to existing users
				String message= "addUsersToSessionResponse^success^" + sessionID;
				String singleMessage= "addUsersToSessionResponse^success^" + sessionID + "^" + username;
			
				for(String existingUser: existingUsersInSession){
					writeOnUserSocket(singleMessage, existingUser);
					message+="^"+existingUser;			
				}
				existingUsersInSession.add(username);
				sessionMap.put(sessionID, existingUsersInSession);
				
				//send response to newly added user				
				writeOnUserSocket(message, username);
			}
		}
	}
	
	public void removeUserFromSession(String sessionID, String username)
	{
		ArrayList<String> existingUsersInSession = new ArrayList<String>();//create a blank array list
		int backoffValue = 1;
		while(true)//optimistic concurrency control in exponential back off pattern
		{
			try{
				existingUsersInSession.clear();//start over to collect all members from session if some new user is added
				existingUsersInSession.addAll(sessionMap.get(sessionID)); //make a deep copy
				break;//done with taking snapshot, concurrent execution successful
			}
			catch(ConcurrentModificationException cmex)
			{
				ConsoleLogger.log("Concurrent Modification Exception in SessionManager : " + cmex.toString());
				backoffValue*=2;
				try{Thread.sleep(backoffValue);}catch(InterruptedException iex){/*Can be spurious wake up, do nothing*/}
			}
		} 
		if(existingUsersInSession.contains(username))
		{
			existingUsersInSession.remove(username);
			sessionMap.put(sessionID, existingUsersInSession);
			String response = "removeUserFromSessionResponse^success^" + sessionID + "^" + username;
			for(String aUsername:existingUsersInSession)
			{
				writeOnUserSocket(response, aUsername);
			}
		}
		else
		{
			String response = "removeUserFromSessionResponse^failure^" + sessionID + "^" + username; 
			writeOnUserSocket(response, username);
		}
	}
	
	public void addUserToSession(String sessionID, ArrayList<String> userNames)
	{
		ArrayList<String> existingUsersInSession = new ArrayList<String>();
		int backoffValue = 1;
		while(true)//optimistic concurrency control in exponential back off pattern
		{
			try{
				existingUsersInSession.clear();//start over to collect all members from session if some new user is added
				existingUsersInSession.addAll(sessionMap.get(sessionID));
				break;//done with taking snapshot, concurrent execution successful
			}
			catch(ConcurrentModificationException cmex)
			{
				ConsoleLogger.log("Concurrent Modification Exception in SessionManager : " + cmex.toString());
				backoffValue*=2;
				try{Thread.sleep(backoffValue);}catch(InterruptedException iex){/*Can be spurious wake up, do nothing*/}
			}
		}
		if(existingUsersInSession != null && existingUsersInSession.contains(userNames.get(0)))
		{
			userNames.remove(0);
			addUserToSessionHelper(sessionID, userNames);
		}		
	}
	
	public void chat(String username, String sessionID, String msg)
	{
		ArrayList<String> existingUsersInSession = new ArrayList<String>();//create a blank array list
		int backoffValue = 1;
		while(true)//optimistic concurrency control in exponential back off pattern
		{
			try{
				existingUsersInSession.clear();//start over to collect all members from session if some new user is added
				existingUsersInSession.addAll(sessionMap.get(sessionID)); //make a deep copy
				break;//done with taking snapshot, concurrent execution successful
			}
			catch(ConcurrentModificationException cmex)
			{
				ConsoleLogger.log("Concurrent Modification Exception in SessionManager : " + cmex.toString());
				backoffValue*=2;
				try{Thread.sleep(backoffValue);}catch(InterruptedException iex){/*Can be spurious wake up, do nothing*/}
			}
		} 
		/*This method uses Reentrant locks to avoid unintended message display to a user who was not present in chat 
		 * at the time when message was sent but got added by some other user in the same session.
		 * By acquiring a lock first

		
		ArrayList<String> existingUsersInSession = new ArrayList<String>();
		try{
			lock.lock();
			existingUsersInSession.addAll(sessionMap.get(sessionID));//get the snapshot of users list
		}
		finally{lock.unlock();}		 
		*/
		if(existingUsersInSession.contains(username))
		{
			String response = "chatResponse^success^" + sessionID + ":" + username + ":" + msg;
			for(String aUsername:existingUsersInSession)
			{
				writeOnUserSocket(response, aUsername);
			}
		}
		else
		{
			String response = "chatResponse^failure^" + sessionID + "^You are not the part of this session"; 
			writeOnUserSocket(response, username);
		}
	}
	
	public void writeOnUserSocket(String msg, String username)
	{
		Socket socket = LoginManager.getLoginManager().getUserSocket(username);
		if(socket.isClosed())
			return;
		//synchronize on Socket object on which data is being written
		synchronized(socket)
		{			
			try
			{
				PrintWriter pw = new PrintWriter(socket.getOutputStream());
				ConsoleLogger.log("ServerResponse : " + msg);
				pw.print(msg + "~");
				pw.flush();
				
			} 
			catch (IOException e) 
			{
				e.printStackTrace();
			}
			
		}
	}
	
}
