package edu.ufl.java;

import java.util.ArrayList;

public class SessionManager {
	/*
	 * parameters:
	 * sessionList: tracks all open sessions
	 * 
	 * */
	private ArrayList<Session> sessionList;
	
	
	/* getter and setters */
	public ArrayList<Session> getSessionList() {
		return sessionList;
	}

	public void setSessionList(ArrayList<Session> sessionList) {
		this.sessionList = sessionList;
	}
	
	
	/* the only instance of this class */
	private static SessionManager sessionmgr = new SessionManager();
	
	/* always returns the one instance */
	public static SessionManager getSessionManager(){
		return sessionmgr;
	}
	
	private SessionManager(){} // singleton
	
	
	
	/* spawns a new session */
	public Session createNewSession(boolean isgroupchat){
		Session newsession = new Session(isgroupchat);
		sessionList.add(newsession);
		return newsession;
	}
	
	public boolean addUserToSession(User someUser, Session someSession){
		return someSession.addUser(someUser);
	}
	
	public boolean removeUserFromSession(User someUser, Session someSession){
		return someSession.removeUser(someUser);
	}
	
	Session[] showSessionList(){
		return (Session[]) sessionList.toArray(); 
	}
}
