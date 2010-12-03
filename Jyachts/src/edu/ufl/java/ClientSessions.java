package edu.ufl.java;

import java.util.ArrayList;

public class ClientSessions{
	String sessionID;
	ArrayList<String> usersInSession = new ArrayList<String> ();
	
	public ClientSessions(String sessionID, ArrayList<String> users){
		this.sessionID = sessionID;
		System.out.println("CLIENTSESSION: Creating new client session. session id: "+sessionID);
		
		for (int i=0;i<users.size();i++){
			this.usersInSession.add(users.get(i));
			System.out.println("CLIENTSESSION: Adding user: "+users.get(i));
		}
	}
	
	public ArrayList<String> getUsersInSession(){
		return this.usersInSession;
	}
	
	public void addUsersToSession(String username){
		this.usersInSession.add(username);
	}
	
	public void removeUsersFromSession(String username){
		this.usersInSession.remove(username);
	}
}
