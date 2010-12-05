package edu.ufl.java;

import java.util.*;
import java.util.concurrent.locks.*;
import java.util.concurrent.atomic.AtomicInteger;
import java.io.IOException;
import java.io.PrintWriter;
import java.net.Socket;

public class SessionManager 
{
	Map<String, ArrayList<String>> sessionMap = null;
	private static SessionManager sessionManager = new SessionManager();
	private AtomicInteger sessionCount = new AtomicInteger(0);
	private Lock lock = new ReentrantLock();
	
	private SessionManager()
	{
		sessionMap = Collections.synchronizedMap(new HashMap<String, ArrayList<String>>());
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
		addUserToSession(Integer.toString(newSessionID), userNames);
			
	}
	
	//assumes that sessionID exists and first user is in the same session
	public void addUserToSession(String sessionID, ArrayList<String> userNames)
	{
		LoginManager lm = LoginManager.getLoginManager();
				
		for(String username:userNames)
		{
			ArrayList<String> existingUsersInSession = sessionMap.get(sessionID);
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
		try{
			lock.lock();
			ArrayList<String> currentUserList = sessionMap.get(sessionID); 
			if(currentUserList.contains(username))
			{
				currentUserList.remove(username);
				sessionMap.put(sessionID, currentUserList);
				String response = "removeUserFromSessionResponse^success^" + sessionID + "^" + username;
				for(String aUsername:currentUserList)
				{
					writeOnUserSocket(response, aUsername);
				}
			}
			else
			{
				String response = "removeUserFromSessionResponse^failure^" + sessionID + "^" + username; 
				writeOnUserSocket(response, username);
			}
		}finally{lock.unlock();}
	}
	
	public void chat(String username, String sessionID, String msg)
	{
		ArrayList<String> userNames = sessionMap.get(sessionID); 
		if(userNames.contains(username))
		{
			String response = "chatResponse^success^" + sessionID + ":" + username + ":" + msg;
			for(String aUsername:userNames)
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
		synchronized(socket)
		{			
			try
			{
				PrintWriter pw = new PrintWriter(socket.getOutputStream());
				System.out.println("server response to client: " + msg);
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
