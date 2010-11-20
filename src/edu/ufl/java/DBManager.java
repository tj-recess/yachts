package edu.ufl.java;

import org.hibernate.HibernateException;
import org.hibernate.Session;               
import org.hibernate.Transaction;           
import org.hibernate.Criteria;              
import org.hibernate.criterion.Restrictions;
import org.hibernate.criterion.Order;    

/* manage all database stuff */ 
public class DBManager {
	
	public boolean registerUser(User newuser){
		Session session = HibernateUtils.getSession();			    
		Transaction tx = null;
		try{
			tx=session.beginTransaction();
			session.save(newuser);
			session.getTransaction().commit();
			session.flush();
		}
		catch (HibernateException he) {
			if (tx!=null) tx.rollback();
			throw he;
		}
		finally {
			session.close();
		}
		return true;
	}
	
	

}
