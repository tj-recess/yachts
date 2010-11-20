package edu.ufl.java;

import java.io.UnsupportedEncodingException;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.ArrayList;

public class User {
	
	/* parameters */
	private String FirstName;
	private String LastName;
	private byte[] Password;
	private final String Username; // Username cannot be changed
	private String Location;
	private String EmailAddress;
	private ArrayList<Integer> activeSessionIDList; // Ids of all current sessions in which this user is active
	
	public ArrayList<Integer> getActiveSessionIDList() {
		return activeSessionIDList;
	}

	public void setActiveSessionIDList(ArrayList<Integer> activeSessionIDList) {
		this.activeSessionIDList = activeSessionIDList;
	}

	/* getters and setters */
	public String getFirstName() {
		return FirstName;
	}

	public void setFirstName(String firstName) {
		FirstName = firstName;
	}

	public String getLastName() {
		return LastName;
	}

	public void setLastName(String lastName) {
		LastName = lastName;
	}

	public byte[] getPassword() {
		return Password;
	}

	public void setPassword(byte[] password) {
		Password = password;
	}

	public String getLocation() {
		return Location;
	}

	public void setLocation(String location) {
		Location = location;
	}

	public String getEmailAddress() {
		return EmailAddress;
	}

	public void setEmailAddress(String emailAddress) {
		EmailAddress = emailAddress;
	}

	public String getUsername() {
		return Username;
	}

	
	public User(String fname, String lname, String password, String username,String location,String email) throws NoSuchAlgorithmException, UnsupportedEncodingException{
		this.FirstName=fname;
		this.LastName=lname;
		this.Username=username;
		this.Location=location;
		this.EmailAddress=email;
		
		/* converting password to md5 hash*/
		byte[] passwordBytes = password.getBytes("UTF-8");
		MessageDigest md = MessageDigest.getInstance("MD5");
		this.Password = md.digest(passwordBytes);	
	}
	
	public boolean login(String username,String password) throws UnsupportedEncodingException, NoSuchAlgorithmException{
		boolean loginstatus=false;
		
		/* converting password to md5 hash*/
		byte[] passwordBytes = password.getBytes("UTF-8");
		MessageDigest md = MessageDigest.getInstance("MD5");
		byte[] passwd = md.digest(passwordBytes);	
		
		/* validate the user */
		
		return loginstatus;
	}
	
	boolean leaveChat(Session someSession){
		return someSession.removeUser(this);
	}
	
	boolean joinChat(Session someSession){
		return someSession.addUser(this);
	}
}
