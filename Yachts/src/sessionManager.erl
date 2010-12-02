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


createSession(UserList)->
		[User1|_]=UserList,
		case userManager:getUserInfo(User1) of
			error -> 
				{addUsersToSessionResponse,false,["Invalid Username"]};
				 _->
				sessionManagerPid ! {create,UserList}			
		end.
		
addUsersToSession({SessionID,[User1|T]})->
	case userManager:getUserInfo(User1) of
			error -> {addUsersToSessionResponse,false,["Invalid Username"]};
			{ok,[{_,UserPid}]} ->
				sessionManagerPid ! {add,SessionID,User1,T,UserPid}							
	end.	
	
chat({User,SessionID,Message})->
		case userManager:getUserInfo(User) of
			error -> {chat,false,["Invalid Username"]};
			{ok,[{_,UserPid}]} ->
				sessionManagerPid ! {chat,{User,SessionID,Message,UserPid}}							
		end.	

sessionList(SessionList,Count)->
	receive
		 {From, getAll} ->
			From ! {getAll,SessionList,Count},
			sessionList(SessionList,Count);
		
		 {create,UserList}->		
			pg2:create(Count),
			AddedUsers = addToSession(UserList,Count,[],[]),
			NewSessionList=dict:append(Count,{Count,AddedUsers},SessionList),
			%{true,[integer_to_list(Count)| AddedUsers]},%% return tuple of {count and list of added users} 
			sessionList(NewSessionList,Count+1);
		 {add,SessionID,User1,UserList,UserPid}->
			case dict:find(SessionID, SessionList) of
				error -> %% if SessionID is invalid 
					UserPid ! {addUsersToSessionResponse,failure,["Invalid Session ID"]},
					sessionList(SessionList,Count);
				{ok, [{Name,UsersInSession}] } -> %% if SessionID is valid
					Present=lists:member(User1,UsersInSession),
						if 
							Present -> %% If User1 is part of the session
								AddedUsers=addToSession(UserList,SessionID,[],UsersInSession),
								NewSessionList=dict:update(SessionID, fun (Old) -> lists:append(UsersInSession, AddedUsers) end, SessionList),
								sessionList(NewSessionList,Count);
							Present ==false ->
								UserPid ! {addUsersToSessionResponse,failure,["User not part of session"]},
								sessionList(SessionList,Count)
						end;
				Weird ->
					io:format("received weird value : ~w ~n",[Weird])
			
			end;
		 {chat,{User,SessionID,Message,UserPid}}->
			case dict:find(SessionID, SessionList) of
				error -> %% if SessionID is invalid 
					UserPid ! {chatResponse,failure,["Invalid Session ID"]};
				{ok, {Name,UsersInSession} } -> %% if SessionID is valid then Name is the Pid of the Process Group
					Present=lists:member(User, UsersInSession),
						if 
							Present -> %% If User is part of the session
								Name ! {chatResponse,success,[string:join([integer_to_list(Name),User,Message],":")]};
							Present == false ->
								UserPid ! {chatResponse,failure,["User not part of session"]}
						end
			
			end,
			sessionList(SessionList,Count)
			
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
			 case pg2:join(SessionID,UserPid) of
			 	ok -> % the user is added to the chat room
					sendMessage(TotalUsersPids,{addUsersToSessionResponse,success,[integer_to_list(SessionID),User]}),				
			 		UserPid ! {addUsersToSessionResponse,success,[integer_to_list(SessionID)|TotalUsers]},
			 		addToSession(T,SessionID,[User|AddedUsers],CurrentUsers);
				{error,Reason} -> Reason, 	%the user is logged in but could not be added to chat room
					addToSession(T,SessionID,AddedUsers,CurrentUsers)
			 end
	end.

	
sendMessage([],Message)->done;	
sendMessage([Pid|T],Message) ->
	Pid ! Message,
	sendMessage(T,Message).