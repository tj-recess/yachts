
/* Mysql database script */

/* create database */
create database yachts;

/* use this database */
USE yachts;

/* Users table */
CREATE TABLE RegisteredUsers(UserID INTEGER AUTO_INCREMENT PRIMARY KEY,
Username VARCHAR(20),
Password VARCHAR(30),
FirstName VARCHAR(30),
LastName VARCHAR(30),
Location VARCHAR(30),
EmailID VARCHAR(30));


/* procedure to get user information */
CREATE PROCEDURE GetUserInfo(someUser varchar(30))
BEGIN
    SELECT * FROM Users WHERE Username = someUser;
END

/* procedure to register a new user */
DELIMITER $$
USE yachts;$$
DROP PROCEDURE IF EXISTS RegisterUser;$$
CREATE PROCEDURE `yachts`.`RegisterUser` (Username varchar(30), Password varchar(30), FirstName varchar(30), LastName varchar(30), Location varchar(30), EmailId varchar(30))
BEGIN
INSERT IGNORE INTO RegisteredUsers(Username, Password, FirstName, LastName, Location, EmailId)
values(Username, Password, FirstName, LastName, Location, EmailId);
END $$

/*CALL RegisterUser('at','password', 'arpit', 'tripathi','gainesville','arpit1712@gmail.com');
SELECT * FROM RegisteredUsers*/