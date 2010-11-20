USE yachts;
DELIMITER $$

CREATE PROCEDURE GetUserInfo(someUser varchar(30))
BEGIN
    SELECT * FROM Users WHERE Username = someUser;
END