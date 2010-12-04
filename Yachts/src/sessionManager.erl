%% Author: Dwai
%% Created: Nov 21, 2010
%% Description: TODO: Add description to sessionManager
-module(sessionManager).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-compile(export_all).
-import(userManager).
%%
%% API Functions
%%

start()->
	PID=spawn(?MODULE, initSessionList, []),
%% 	userManager:start(),
%% 	userManager:loginUser(self(),"at" ,"password"),
%% 	userManager:loginUser(self(),"dwai" ,"pwd"),
%% 	userManager:getUserInfo("dwai"),
	register(sessionManagerPid,PID).
	
	
initSessionList()->
	sessionList(dict:new(),0).
%% sessionList contains key value pairs of the form 
%%( Index : {Nummber of users in session[index], [user list in session[index]} )	

getAll() ->
	sessionManagerPid ! {self(),getAll},
	receive
		{getAll,SessionList,Count} -> {SessionList,Count}
	after 2000 ->
		io:format("Operation Timed Out, try again later")
	end.

find(Key) ->
	sessionManagerPid ! {self(),find,Key},
	receive
		{find,Value} -> Value
	after 2000 ->
		io:format("Operation Timed Out, try again later")
	end.


createSession(UserList)->
		[User|_]=UserList,	
		case userManager:getUserInfo(User) of	%check whether user is logged in
			error -> 
				{addUsersToSessionResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]}->
				sessionManagerPid ! {create,UserList};
			Weird ->
					io:format("received weird value in createSession: ~w ~n",[Weird])
		end.
		
addUsersToSession({SessionID,[User|T]})->
	case userManager:getUserInfo(User) of	%check whether user is logged in
			error -> 
				{addUsersToSessionResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]} ->
				sessionManagerPid ! {add,SessionID,User,T,UserPid};
			Weird ->
					io:format("received weird value in addUsersToSession: ~w ~n",[Weird])
	end.	
	
chat({User,SessionID,Message})->
		case userManager:getUserInfo(User) of	%check whether user is logged in
			error -> 
				{chatResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]} ->
				sessionManagerPid ! {chat,User,SessionID,Message,UserPid};
			Weird ->
					io:format("received weird value in chatMessage: ~w ~n",[Weird])
		end.	

removeUserFromSession({SessionID,User})->
	io:format("remove user ~w ~p", [SessionID,User]),
		case userManager:getUserInfo(User) of	%check whether user is logged in
			error -> 
				{removeUserFromSessionResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]}->
				io:format("user found !"),
				sessionManagerPid ! {remove,User,SessionID,UserPid};
			Weird ->
					io:format("received weird value in removeUserFromSession: ~w ~n",[Weird])
		end.


sessionList(SessionList,Count)->
	receive
		 {From, getAll} ->
			From ! {getAll,SessionList,Count},
			sessionList(SessionList,Count);
		 {From,find,Key} ->
			From ! {find,dict:find(Key,SessionList)},
			sessionList(SessionList,Count);		
		 {create,UserList}->		
			pg2:create(Count),
			AddedUsers = addToSession(UserList,Count,[],[]),
			NewSessionList=dict:append(Count,{AddedUsers},SessionList),
			sessionList(NewSessionList,Count+1);
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
								NewSessionList=dict:store(SessionID,[{lists:append(UsersInSession, AddedUsers)}], SessionList),
								sessionList(NewSessionList,Count);
							Present ==false ->
								UserPid ! {addUsersToSessionResponse,failure,["User not part of session"]},
								sessionList(SessionList,Count)
						end;
				Weird ->
					io:format("received weird value in add: ~w ~n",[Weird]),
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
								TotalUsersPids= pg2:get_members(SessionID),
								sendMessage(TotalUsersPids,{chatResponse,success,[string:join([integer_to_list(SessionID),User,Message],":")]}),
								sessionList(SessionList,Count);
							Present == false ->
								UserPid ! {chatResponse,failure,["User not part of session"]},
								sessionList(SessionList,Count)
						end;
				Weird ->
					io:format("received weird value in chat: ~w ~n",[Weird]),
					sessionList(SessionList, Count)
			end;
		{remove,User,SessionID,UserPid} ->
			io:format("Session ID ~w User Pid ~p_",[SessionID,UserPid]),
			case dict:find(SessionID, SessionList) of
				error -> %% if SessionID is invalid 
					UserPid ! {removeUserFromSessionResponse,failure,["Invalid Session ID"]},
					sessionList(SessionList,Count);
				{ok, [{UsersInSession}] } -> %% if SessionID is valid then Name is the Pid of the Process Group
					Present=lists:member(User, UsersInSession),
						if 
							Present -> %% If User is part of the session
								
								pg2:leave(SessionID,UserPid),
								LeftUsersPids = pg2:get_members(SessionID),
								sendMessage([UserPid],{removeUserFromSessionResponse,success,[integer_to_list(SessionID),User]}),
								case LeftUsersPids of 
									[] -> 
										NewSessionList = dict:erase(SessionID,SessionList),
										pg2:delete(SessionID),
										sessionList(NewSessionList,Count);
									_ ->
										sendMessage(LeftUsersPids,{removeUserFromSessionResponse,success,[integer_to_list(SessionID),User]}),
										NewSessionList = dict:store(SessionID,[{lists:delete(User, UsersInSession)}], SessionList),
										sessionList(NewSessionList,Count)
								end;
							Present == false ->
								UserPid ! {removeUserFromSessionResponse,failure,["User not part of session"]},
								sessionList(SessionList,Count)
						end;
				Weird ->
					io:format("received weird value in remove : ~w ~n",[Weird]),
					sessionList(SessionList, Count)
			end;
		Weird ->
					io:format("received weird value in sessionList: ~w ~n",[Weird]),
					sessionList(SessionList, Count)
		
	end.

%%Helper functions for sessionList
addToSession([],SessionID,AddedUsers,CurrentUsers) ->
    AddedUsers;
addToSession([User|T],SessionID,AddedUsers,CurrentUsers) ->
	case userManager:getUserInfo(User) of
		 error->		% the user is not a logged in user
			 "Invalid Username",
			 addToSession(T,SessionID,AddedUsers,CurrentUsers);
		 {ok,[{_,UserPid}]}->
			 TotalUsers =lists:append(CurrentUsers, AddedUsers),
			 TotalUsersPids= pg2:get_members(SessionID),
			 Present=lists:member(UserPid, TotalUsersPids),
			 if 
				 Present == false->
			 		case pg2:join(SessionID,UserPid) of
			 			ok -> % the user is added to the chat room
							sendMessage(TotalUsersPids,{addUsersToSessionResponse,success,[integer_to_list(SessionID),User]}),				
			 				UserPid ! {addUsersToSessionResponse,success,[integer_to_list(SessionID)|TotalUsers]},
			 				addToSession(T,SessionID,[User|AddedUsers],CurrentUsers);
						{error,Reason} -> Reason, 	%the user is logged in but could not be added to chat room
							addToSession(T,SessionID,AddedUsers,CurrentUsers);
						Weir ->
							io:format("received weird value in addToSession pg2:join : ~w ~n",[Weir]),
							addToSession(T,SessionID,AddedUsers,CurrentUsers)
			 		end;
				 Present == true ->
							addToSession(T,SessionID,AddedUsers,CurrentUsers)
			end;
		Weird ->
					io:format("received weird value in addToSession : ~w ~n",[Weird]),
					addToSession(T,SessionID,AddedUsers,CurrentUsers)
	end.

	
sendMessage([],Message)->done;	
sendMessage([Pid|T],Message) ->
	Pid ! Message,
	sendMessage(T,Message).