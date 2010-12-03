package src.edu.ufl.java;

import java.net.Socket;
import java.util.ArrayList;

public class User {
	
	/* parameters */
	private int UserID;
	private String FirstName;
	private String LastName;
	private String Password;
	private String Username; // Username cannot be changed
	private String Location;
	private String EmailAddress;
	
	public void setUsername(String username) {
		Username = username;
	}

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

	public String getPassword() {
		return Password;
	}

	public void setPassword(String password) {
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

	public User(){} //default constructor 
	
	public User(String fname, String lname, String username, String password, String location,String email){
		this.FirstName=fname;
		this.LastName=lname;
		this.Username=username;
		this.Location=location;
		this.EmailAddress=email;
		this.Password=password; // played a bit with md5 but did not get it working - sorry.
		this.activeSessionIDList= new ArrayList<Integer>();
		
		 //converting password to md5 hash
		/*try{
			byte[] passwordBytes = password.getBytes("UTF-8");
			MessageDigest md = MessageDigest.getInstance("MD5");
			this.Password = (md);
		}
		catch(NoSuchAlgorithmException ne){}
		catch (UnsupportedEncodingException ue){}
		*/
	}
	
	boolean leaveChat(Session someSession){
		return someSession.removeUser(this);
	}
	
	boolean joinChat(Session someSession){
		return someSession.addUser(this);
	}

	public void setUserID(int userID) {
		UserID = userID;
	}

	public int getUserID() {
		return UserID;
	}
	public boolean containsSession(int sessionID){
		
		if(this.activeSessionIDList!= null){
			if(this.activeSessionIDList.contains(sessionID))
				return true;
		}
		return false;
	}
}
