-- --------------------------------------------------------------------------------
-- Routine DDL
-- --------------------------------------------------------------------------------
DELIMITER $$
USE yachts;$$
DROP PROCEDURE IF EXISTS RegisterUser;$$
CREATE PROCEDURE `yachts`.`RegisterUser` (Username varchar(30), Password varchar(30), FirstName varchar(30), LastName varchar(30), Location varchar(30), EmailId varchar(30))
BEGIN
INSERT IGNORE INTO RegisteredUsers(Username, Password, FirstName, LastName, Location, EmailId)
values(Username, Password, FirstName, LastName, Location, EmailId);
END
