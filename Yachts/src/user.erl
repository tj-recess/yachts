%% Author: arpit
%% Created: Nov 25, 2010
%% Description: TODO: Add description to user
-module(user).

%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handleClient/1]).

%%
%% API Functions
%%

handleClient(ClientSocket) ->
    case gen_tcp:recv(ClientSocket, 0) of
        {ok, Data} ->
			%%Parse the data first and take appropriate action
            case parseClientMessage(self(),Data) of
				{register,[Username, Password, FirstName, LastName, Location, EmailId]} ->
					Status = userManager:registerUser(Username, Password, FirstName, LastName, Location, EmailId);
				{login, Username, Password} ->
					Result = userManager:loginUser(self(), Username, Password),
					case Result of
						{true, Reason} -> 
							Status = string:join(["LoginResponse"|["success"|Reason]], "^"),
							userLoop(ClientSocket);
						{false,Reason} ->
							Status = string:join(["LoginResponse"|["failure"|Reason]], "^");
						{timeout,Reason} -> 
							Status = string:join(["LoginResponse"|["failure"|Reason]], "^")
					end;
				_ ->
					Status = "BadQuery^User need to login first"
			end,
			gen_tcp:send(ClientSocket, Status);
        {error, closed} ->
            ok
    end.



%%
%% Local Functions
%%

parseClientMessage(CallerPid, Msg)->
       [H|T]= string:tokens(Msg,"^"),
       case string:to_lower(H) of
       		"register" ->
				CallerPid ! {register,T};
            "login" -> 
				CallerPid ! {login,T};
		   "createsession" ->
			   	CallerPid ! {createSession, T};
		   "addusertosession" ->
			   CallerPid ! {addUserToSession, T};
		   "chat" ->
			   CallerPid ! {chat, T};
		   "getallloggedinusers" ->
			   CallerPid ! getAllLoggedInUsers
       end.

userLoop(ClientSocket) ->
	case gen_tcp:recv(ClientSocket, 0) of
    {ok, Data} ->
		%%Parse the data first and take appropriate action
            case parseClientMessage(self(),Data) of
				{createSession, ListOfUsers} ->
					Result = sessionManager:createSession(ListOfUsers),
					case Result of
						{true, Response} -> 
							Status = string:join(["CreateSessionResponse"|["success"|Response]], "^");
						{false,Reason} ->
							Status = string:join(["CreateSessionResponse","failure",Reason], "^");
						{timeout,Reason} -> 
							Status = string:join(["CreateSessionResponse","failure",Reason], "^")
					end;
				{addUsersToSession, [SessionID|ListOfUsers]} ->
					{IntSessionID, _} = string:to_integer(SessionID),
					Result = sessionManager:addUsersToSession({IntSessionID, ListOfUsers}),
					case Result of
						{true, Response} -> 
							Status = string:join(["CreateSessionResponse"|["success"|Response]], "^");
						{false,Reason} ->
							Status = string:join(["CreateSessionResponse"|["failure"|Reason]], "^");
						{timeout,Reason} -> 
							Status = string:join(["CreateSessionResponse"|["failure"|Reason]], "^")
					end;
				{chat, [Sender|[SessionID|Text]]}->
					{IntSessionID, _} = string:to_integer(SessionID),
					Status = sessionManager:chat({Sender, IntSessionID, string:join(Text,"^")});
				getAllLoggedInUsers ->
					LoggedInUsersList = users:getAllLoggedInUsers(),
					Status = string:join(["LoggedInUsers"|LoggedInUsersList],"^")
			end,
			gen_tcp:send(ClientSocket, Status),
            userLoop(ClientSocket);
        {error, closed} ->
            ok
    end.