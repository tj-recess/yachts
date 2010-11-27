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
-export([createSession/1,addUsersToSession/1,chat/1]).

%%
%% API Functions
%%

start()->
	PID=spawn(sessionManager, initSessionManagerList, []),
	register(sessionManager,PID).
	
	
initSessionManagerList()->
	sessionList(dict:new(),0).
%% sessionList contains key value pairs of the form 
%%( Index : {Nummber of users in session[index], [user list in session[index]} )	

createSession(UserList)->
		[User1|_]=UserList,
		case loginManager:getUserInfo(User1) of
			error -> {addUsersToSessionResponse,false,["Invalid Username"]};
				 _->
				sessionManager ! {create,UserList}			
		end.
		
addUsersToSession({SessionID,[User1|T]})->
	case loginManager:getUserInfo(User1) of
			error -> {addUsersToSessionResponse,false,["Invalid Username"]};
			{_,UserPid} ->
				sessionManager ! {add,SessionID,User1,T,UserPid}							
	end.	
	

chat({User,SessionID,Message})->
		case loginManager:getUserInfo(User) of
			error -> {chat,false,["Invalid Username"]};
			{_,UserPid} ->
				sessionManager ! {chat,{User,SessionID,Message,UserPid}}							
		end.	

sessionList(SessionList,Count)->
	receive
		 {create,UserList}->		
			pg2:create(Count),
			AddedUsers=addToSession(UserList,Count,[],[]),
			NewSessionList=dict:append(Count,{Count,AddedUsers},SessionList),
			%%{true,[integer_to_list(Count)| AddedUsers]},%% return tuple of {count and list of added users} 
			sessionList(NewSessionList,Count+1);
		 {add,SessionID,User1,UserList,UserPid}->
			case dict:find(SessionID, SessionList) of
				{error,_} -> %% if SessionID is invalid 
					UserPid ! {addUsersToSessionResponse,failure,["Invalid Session ID"]},
					sessionList(SessionList,Count);
				{ok, {Name,UsersInSession} } -> %% if SessionID is valid
					Present=lists:member(User1,UsersInSession),
						if 
							Present -> %% If User1 is part of the session
								AddedUsers=addToSession(UserList,SessionID,[],UsersInSession),
								NewSessionList=dict:update(SessionID, fun (Old) -> lists:append(UsersInSession, AddedUsers) end, SessionList),
								sessionList(NewSessionList,Count);
							Present ==false ->
								UserPid ! {addUsersToSessionResponse,failure,["User not part of session"]},
								sessionList(SessionList,Count)
						end
			
			end;
		 {chat,{User,SessionID,Message,UserPid}}->
			case dict:find(SessionID, SessionList) of
				{error,_} -> %% if SessionID is invalid 
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
	case loginManager:getUserInfo(User) of
		 error->
			 "Invalid Username",
			 addToSession(T,SessionID,AddedUsers,CurrentUsers);
		 {ok,{_,UserPid}}->
			 TotalUsers =lists:append(CurrentUsers, AddedUsers),
			 SessionID ! {addUsersToSessionResponse,success,[integer_to_list(SessionID),User]},
			 pg2:join(SessionID,UserPid),
			 UserPid ! {addUsersToSessionResponse,success,[integer_to_list(SessionID)|TotalUsers]},
			 addToSession(T,SessionID,[User|AddedUsers],CurrentUsers)
	end.


sendMessage(Pid,Message) ->
    Pid ! Message.
