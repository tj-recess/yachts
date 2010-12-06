%%
%% Module Name
%%
-module(sessionManager).
%%
%% Include files
%%
-import(userManager).
%%
%% Exported Functions
%%
-compile(export_all).
%%
%% API Functions
%%
% start the SessionManager process  
start()->
	PID=spawn(?MODULE, initSessionList, []),
	register(sessionManagerPid,PID).
	
% initialises sessionList dictionary  	
initSessionList()->
	sessionList(dict:new(),0).
%% sessionList dictionary contains key value pairs of the form  
%% Index : {List of users in session[index]} 	

% debugger method to show the sessionList dictionary
getAll() ->
	sessionManagerPid ! {self(),getAll},
	receive
		{getAll,SessionList,Count} -> {SessionList,Count}
	after 2000 ->
		io:fwrite(console,"~nOperation Timed Out, try again later",[])
	end.
% debugger method to find the value corresponding to key 
%'Key' in the sessionList dictionary
find(Key) ->
	sessionManagerPid ! {self(),find,Key},
	receive
		{find,Value} -> Value
	after 2000 ->
		io:fwrite(console,"~nOperation Timed Out, try again later",[])
	end.

% Method to create a new session containing the users contained in UserList
createSession(UserList)->
		[User|_]=UserList,	
		case userManager:getUserInfo(User) of	%check whether first user is logged in
			error -> %if not return failure message 
				{addUsersToSessionResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]}-> %if yes send message to sessionManager process
				sessionManagerPid ! {create,UserList};
			Weird -> 
					io:fwrite(console,"~nreceived weird value in createSession: ~w ~n",[Weird])
		end.
% Method to add users to existing session 		
addUsersToSession({SessionID,[User|T]})->
	case userManager:getUserInfo(User) of	%check whether first user is logged in
			error -> %if not return failure message 
				{addUsersToSessionResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]} -> %if yes send message to sessionManager process
				sessionManagerPid ! {add,SessionID,User,T,UserPid};
			Weird ->
					io:fwrite(console,"~nreceived weird value in addUsersToSession: ~w ~n",[Weird])
	end.	
% Method to relay chat messages from one user to all the other users in the session	
chat({User,SessionID,Message})->
		case userManager:getUserInfo(User) of	%check whether user is logged in
			error -> %if not return failure message 
				{chatResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]} -> %if yes send message to sessionManager process
				sessionManagerPid ! {chat,User,SessionID,Message,UserPid};
			Weird ->
					io:fwrite(console,"~nreceived weird value in chatMessage: ~w ~n",[Weird])
		end.	

% Method to remove a user from a particular session
removeUserFromSession({SessionID,User})->
		case userManager:getUserInfo(User) of	%check whether user is logged in
			error -> %if not return failure message 
				{removeUserFromSessionResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]}-> %if yes send message to sessionManager process
				sessionManagerPid ! {remove,User,SessionID,UserPid};
			Weird ->
					io:fwrite(console,"~nreceived weird value in removeUserFromSession: ~w ~n",[Weird])
		end.

% SessionList Method which holds the sessionList dictionary and waits 
% for messages from user processes, processes the message and sends back
% necessay messages to one or more user processes
sessionList(SessionList,Count)->
	receive
		 {From, getAll} -> 
			From ! {getAll,SessionList,Count},
			sessionList(SessionList,Count);
		 {From,find,Key} ->
			From ! {find,dict:find(Key,SessionList)},
			sessionList(SessionList,Count);		
		 {create,UserList}->		
			pg2:create(Count),	%create process group for session having id as count
			AddedUsers = addToSession(UserList,Count,[],[]), %add users to session
			NewSessionList=dict:append(Count,{AddedUsers},SessionList), % update dictionary
			sessionList(NewSessionList,Count+1); % 
		 {add,SessionID,User1,UserList,UserPid}->
			case dict:find(SessionID, SessionList) of
				error -> %% if SessionID is invalid 
					UserPid ! {addUsersToSessionResponse,failure,["Invalid Session ID"]},
					sessionList(SessionList,Count);
				{ok, [{UsersInSession}] } -> %% if SessionID is valid
					Present=lists:member(User1,UsersInSession), %check whether User1 is part of the Session
						if 
							Present -> %% If User1 is part of the session
								AddedUsers=addToSession(UserList,SessionID,[],UsersInSession), %add users to session
								NewSessionList=dict:store(SessionID,[{lists:append(UsersInSession, AddedUsers)}], SessionList), %update dictionary
								sessionList(NewSessionList,Count);
							Present ==false -> %% send error message if user1 is not part of the session
								UserPid ! {addUsersToSessionResponse,failure,["You are not part of the chatroom and so you cannot add members"]},
								sessionList(SessionList,Count)
						end;
				Weird ->
					io:fwrite(console,"~nreceived weird value in add: ~w ~n",[Weird]),
					sessionList(SessionList, Count)
			
			end;
		 {chat,User,SessionID,Message,UserPid}->
			case dict:find(SessionID, SessionList) of
				error -> %% if SessionID is invalid 
					UserPid ! {chatResponse,failure,["Invalid Session ID"]},
					sessionList(SessionList,Count);
				{ok, [{UsersInSession}] } -> %% if SessionID is valid then Name is the Pid of the Process Group
					Present=lists:member(User, UsersInSession),
						if 
							Present -> %% If User is part of the session
								TotalUsersPids= pg2:get_members(SessionID), %get all members present in the session
								sendMessage(TotalUsersPids,{chatResponse,success,[string:join([integer_to_list(SessionID),User,Message],":")]}),% send message to all the users 
								sessionList(SessionList,Count);
							Present == false -> %% send error message if user is not part of the session
								UserPid ! {chatResponse,failure,["You are not part of the chatroom"]},
								sessionList(SessionList,Count)
						end;
				Weird ->
					io:fwrite(console,"~nreceived weird value in chat: ~w ~n",[Weird]),
					sessionList(SessionList, Count)
			end;
		{remove,User,SessionID,UserPid} ->
			case dict:find(SessionID, SessionList) of
				error -> %% if SessionID is invalid 
					UserPid ! {removeUserFromSessionResponse,failure,["Invalid Session ID"]},
					sessionList(SessionList,Count);
				{ok, [{UsersInSession}] } -> %% if SessionID is valid then Name is the Pid of the Process Group
					Present=lists:member(User, UsersInSession),
						if 
							Present -> %% If User is part of the session							
								pg2:leave(SessionID,UserPid), %remove user from the session
								LeftUsersPids = pg2:get_members(SessionID), 
								sendMessage([UserPid],{removeUserFromSessionResponse,success,[integer_to_list(SessionID),User]}), %notify the user that he has been removed from the session
								case LeftUsersPids of 
									[] -> 
										NewSessionList = dict:erase(SessionID,SessionList),
										pg2:delete(SessionID), %remove the process group representing the session if its empty
										sessionList(NewSessionList,Count);
									_ ->
										sendMessage(LeftUsersPids,{removeUserFromSessionResponse,success,[integer_to_list(SessionID),User]}), %notify other users that the user has been removed from the session
										NewSessionList = dict:store(SessionID,[{lists:delete(User, UsersInSession)}], SessionList), %remove user from the session in dictionaty and update it
										sessionList(NewSessionList,Count)
								end;
							Present == false -> %% send error message if user is not part of the session
								UserPid ! {removeUserFromSessionResponse,failure,["User not part of session"]},
								sessionList(SessionList,Count)
						end;
				Weird ->
					io:fwrite(console,"~nreceived weird value in remove : ~w ~n",[Weird]),
					sessionList(SessionList, Count)
			end
	end.

%%Helper functions for sessionList
%% add users to the session having i as 'SessionID' and for each user added send messages to 
%the other users in the session and also to the user being added
addToSession([],SessionID,AddedUsers,CurrentUsers) ->
    AddedUsers;
addToSession([User|T],SessionID,AddedUsers,CurrentUsers) ->
	case userManager:getUserInfo(User) of
		 error->		% the user is not a logged in user
			 "Invalid Username",
			 addToSession(T,SessionID,AddedUsers,CurrentUsers);
		 {ok,[{_,UserPid}]}-> %if the user is logged in check if the user is part of the session
			 TotalUsers =lists:append(CurrentUsers, AddedUsers),
			 TotalUsersPids= pg2:get_members(SessionID), % get all members in the session
			 Present=lists:member(UserPid, TotalUsersPids), 
			 if  
				 Present == false-> %if user is not part of session
			 		case pg2:join(SessionID,UserPid) of
			 			ok -> % the user is added to the chat room
							sendMessage(TotalUsersPids,{addUsersToSessionResponse,success,[integer_to_list(SessionID),User]}), %send message				
			 				UserPid ! {addUsersToSessionResponse,success,[integer_to_list(SessionID)|TotalUsers]},
			 				addToSession(T,SessionID,[User|AddedUsers],CurrentUsers);
						{error,Reason} -> Reason, 	%the user is logged in but could not be added to chat room
							addToSession(T,SessionID,AddedUsers,CurrentUsers);
						Weir ->
							io:fwrite(console,"~nreceived weird value in addToSession pg2:join : ~w ~n",[Weir]),
							addToSession(T,SessionID,AddedUsers,CurrentUsers)
			 		end; 
				 Present == true -> %ignore if user is already part of session
							addToSession(T,SessionID,AddedUsers,CurrentUsers)
			end;
		Weird ->
					io:fwrite(console,"~nreceived weird value in addToSession : ~w ~n",[Weird]),
					addToSession(T,SessionID,AddedUsers,CurrentUsers)
	end.

% iterates a list of processes and sends message to each of them	
sendMessage([],Message)->done;	
sendMessage([Pid|T],Message) ->
	Pid ! Message,
	sendMessage(T,Message).