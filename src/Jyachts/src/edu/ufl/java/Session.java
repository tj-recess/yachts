package Jyachts.src.edu.ufl.java;

import java.util.ArrayList;

public class Session {
	private ArrayList<User> userList;
	private boolean isGroupChat;
	private int sessionID;
	private String receivedText;
	private static int sessionNum=1;
	
	public static int getSessionNum() {
		return sessionNum;
	}

	public int getSessionID() {
		return sessionID;
	}

	public void setSessionID(int sessionID) {
		this.sessionID = sessionID;
	}


	



	/*
	 * Create a new session
	 * */
	public Session(boolean isgroupchat){
		this.isGroupChat = isgroupchat;
		this.receivedText="Chat log \n";
		this.sessionID = getNextSessionID();
		this.userList = new  ArrayList<User>();
		System.out.println("SESSION: Session created. Session ID: "+this.sessionID);
	}
	
	
	
	private int getNextSessionID() {
		// TODO Auto-generated method stub
		return sessionNum++;
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
		
		System.out.println("SESSION: Adding User: "+someUser.getUsername()+" to session:  "+this.sessionID);
		
		/* add this session id */
		
		if(ai==null){
			// create new array list
			ai = new ArrayList<Integer> ();
			ai.add(this.sessionID);
		}
		else{
			// check if user is already in this session
			if (!someUser.containsSession(this.sessionID))
				ai.add(this.sessionID);
		}
		
		/* store list of session ids back */
		someUser.setActiveSessionIDList(ai);
		
		/* add user object to this session */
		return this.userList.add(someUser);
	}
	
	public boolean removeUser(User someUser){
		System.out.println("SESSION: Removing User: "+someUser.getUsername()+" from session:  "+this.sessionID);
		
		return this.userList.remove(someUser);
	}
	public void acceptAndDisplayText(User fromUser, String text){
		this.receivedText += text; // add received text to existing chat history
	}
}
