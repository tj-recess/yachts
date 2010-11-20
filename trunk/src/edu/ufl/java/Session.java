package edu.ufl.java;

import java.util.ArrayList;

public class Session {
	private ArrayList<User> userList;
	private boolean isGroupChat;
	private int sessionID;
	private String receivedText;
	
	/*
	 * Create a new session
	 * */
	public Session(boolean isgroupchat){
		this.isGroupChat = isgroupchat;
		this.receivedText="Chat log \n";
		//this.sessionID = 
	}
	
	/*
	 * return list of users in current session.
	 * */
	public ArrayList<User> showUsers(){
		return this.userList;
	}
	
	public boolean addUser(User someUser){
		/* get active sessions of a user */
		ArrayList<Integer> ai = someUser.getActiveSessionIDList();
		
		/* add this session id */
		if (!ai.contains(this.sessionID))
			ai.add(this.sessionID);
		
		/* store list of session ids back */
		someUser.setActiveSessionIDList(ai);
		
		/* add user object to this session */
		return this.userList.add(someUser);
	}
	
	public boolean removeUser(User someUser){
		return this.userList.remove(someUser);
	}
	public void acceptAndDisplayText(User fromUser, String text){
		this.receivedText += text; // add received text to existing chat history
	}
}
