DELIMITER $$
USE yachts;$$
DROP PROCEDURE IF EXISTS GetUserInfo;$$
CREATE PROCEDURE GetUserInfo(someUsername varchar(30), somePassword varchar(30))
BEGIN
    SELECT FirstName, LastName, Location, EmailID
    FROM RegisteredUsers 
    WHERE Username = someUsername
    AND Password = somePassword;
END