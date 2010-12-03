package edu.ufl.java;

import org.hibernate.SessionFactory;
import org.hibernate.Session;
import org.hibernate.Transaction;
import org.hibernate.cfg.Configuration;


public class HibernateUtils {
	
	private static org.hibernate.SessionFactory sessionFactory;
	
	public static SessionFactory getSessionFactory() {
		if (sessionFactory == null) {
			initSessionFactory();
		}
		return sessionFactory;
	}
	
	private static synchronized void initSessionFactory() {
		sessionFactory = new Configuration().configure().buildSessionFactory();
	}
	
	public static Session getSession() {
		return getSessionFactory().openSession();
	}
} 
