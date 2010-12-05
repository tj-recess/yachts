DELIMITER $$
USE yachts;$$
DROP TABLE IF EXISTS RegisteredUsers;$$
CREATE TABLE RegisteredUsers(
Username VARCHAR(20) PRIMARY KEY,
Password VARCHAR(30),
FirstName VARCHAR(30),
LastName VARCHAR(30),
Location VARCHAR(30),
EmailID VARCHAR(30));