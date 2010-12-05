

USE yachts;
CALL RegisterUser('at','password', 'arpit', 'tripathi','gainesville','arpit1712@gmail.com');

SELECT * FROM RegisteredUsers where Username = 'at';

CALL GetUserInfo('at','password');