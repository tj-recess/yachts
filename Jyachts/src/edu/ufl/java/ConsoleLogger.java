package edu.ufl.java;

import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.IOException;

public class ConsoleLogger {

	private static BufferedWriter loggerOut;
	static
	{
		try
		{
			loggerOut = new BufferedWriter(new FileWriter("ConsoleOutput" + System.currentTimeMillis() + ".txt"));
		}
		catch(IOException ioex)
		{
			System.out.println("Can't create a log file. Reason : " + ioex.getMessage());
		}
	}
	
	public static synchronized void log(String msg)
	{
		if (loggerOut == null)
			return;
		try {loggerOut.append(msg + "\n");}catch(Exception ex){/*can't write to log file, do nothing*/}
	}
	
	public static void flushLog()
	{
		try {loggerOut.flush();}catch(Exception ex){/*can't write to log file, do nothing*/}
	}
	
	public static void closeLogging()
	{
		try 
		{
			loggerOut.flush();
			loggerOut.close();
		}
		catch(Exception ex){/*can't write to log file, do nothing*/}
	}

}
