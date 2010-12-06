package edu.ufl.java;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.Socket;

public class SessionManager 
{
	Map<String, CopyOnWriteArrayList<String>> sessionMap = null;		//maintains a map of all users belonging to a particular session (denoted by SessionID)
	private static SessionManager sessionManager = new SessionManager();	//singleton object of this class which is responsible to maintaining sessions globally
	//initializing here itself to avoid double checked locking
	private AtomicInteger sessionCount = new AtomicInteger(0);		//Atomic Integer value of sessionCount is used for creating new sessions as it is thread safe
	
	private SessionManager()
	{
		sessionMap = new ConcurrentHashMap<String, CopyOnWriteArrayList<String>>();
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
		{//invalid requrest, send Bad query response to invoker
			String responseMsg = "BadQuery^User need to login first";
			writeOnUserSocket(responseMsg, userNames.get(0));
			return;	 
		}

		int newSessionID = sessionCount.getAndIncrement();
		sessionMap.put(Integer.toString(newSessionID), new CopyOnWriteArrayList<String>());
		addUserToSessionHelper(Integer.toString(newSessionID), userNames);
			
	}
	
	//assumes that sessionID exists and first user is in the same session
	public void addUserToSessionHelper(String sessionID, ArrayList<String> userNames)
	{
		LoginManager lm = LoginManager.getLoginManager();

		for(String username:userNames)
		{
			User sender = lm.getUserInfo(username);
			if(sender != null)	//check if every user asked to be added to session is logged in or not
			{					//if yes, add user to session otherwise just ignore
				CopyOnWriteArrayList<String> existingUsersInSession = new CopyOnWriteArrayList<String>();
				CopyOnWriteArrayList<String> list = sessionMap.get(sessionID);
				synchronized (list)	//actual write operation has to be synchronized on the list of usernames stored in the hash map 
				{
					existingUsersInSession.addAll(list);
					if(!list.contains(username))
						list.add(username);
					sessionMap.put(sessionID, list);	
				}				
				//user is added
				//send response to existing users
				String message= "addUsersToSessionResponse^success^" + sessionID;
				String singleMessage= "addUsersToSessionResponse^success^" + sessionID + "^" + username;
			
				for(String existingUser: existingUsersInSession){
					writeOnUserSocket(singleMessage, existingUser);
					message+="^"+existingUser;			
				}				
				//send response to newly added user				
				writeOnUserSocket(message, username);
			}
		}
	}
	
	/*
	 * As this method writes to the sessionMap object with a new list (from which it is removed)
	 * we need explicit synchronization here
	 */
	public void removeUserFromSession(String sessionID, String username)
	{
		CopyOnWriteArrayList<String> existingUsersInSession = new CopyOnWriteArrayList<String>();
		CopyOnWriteArrayList<String> list = sessionMap.get(sessionID);
		existingUsersInSession.addAll(list);
		synchronized (list) {
			list.remove(username);
			sessionMap.put(sessionID, list);
		}
		if(existingUsersInSession.contains(username))
		{
			existingUsersInSession.remove(username);
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
	
	/*
	 * add a particular user to a session given, this methods just 
	 * verifies the requestor's identity and formats the argument list
	 */
	public void addUserToSession(String sessionID, ArrayList<String> userNames)
	{
		CopyOnWriteArrayList<String> existingUsersInSession = sessionMap.get(sessionID);
		if(existingUsersInSession != null && existingUsersInSession.contains(userNames.get(0)))
		{
			userNames.remove(0);
			addUserToSessionHelper(sessionID, userNames);
		}		
	}
	
	/*
	 * send the text message to all users in the given session ID in ==
	 */
	public void chat(String username, String sessionID, String msg)
	{
		CopyOnWriteArrayList<String> existingUsersInSession = sessionMap.get(sessionID);
		//copy-on-write arraylist takes care of concurrent modification exceptions
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
	
	/*
	 * get the user socket from the hash map stored in loginManager
	 * write is synchronized as we dont' want multiple threads to cause datarace 
	 * while writing to the output stream
	 */
	
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
