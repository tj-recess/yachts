%% Author: arpit
%% Created: Nov 25, 2010
%% Description: TODO: Add description to user
-module(user).
-import(userManager).
-import(sessionManager).
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([handleClient/1,dummy/1]).

%%
%% API Functions
%%

dummy(ClientSocket) ->
	gen_tcp:recv(ClientSocket, 0),
	gen_tcp:send(ClientSocket, "dummy data").

handleClient(ClientSocket) ->
    case gen_tcp:recv(ClientSocket, 0) of
        {ok, Data} ->
			D = binary_to_list(Data),
			io:format("user sent ~w", [Data]),
			%gen_tcp:send(ClientSocket, "data from handle client"),
			%%Parse the data first and take appropriate action
            case parseClientMessage(D) of
				{register,[Username, Password, FirstName, LastName, Location, EmailId]} ->
					io:format("User sent : register"),
					Status = userManager:registerUser(Username, Password, FirstName, LastName, Location, EmailId),
					gen_tcp:send(ClientSocket, list_to_binary(Status));
				{login, [Username, Password]} ->
					io:format("User sent : login"),
					Result = userManager:loginUser(self(), Username, Password),
					case Result of
						{true, Reason} -> 
							Status = string:join(["LoginResponse","success",Reason], "^"),
							gen_tcp:send(ClientSocket, list_to_binary(Status)),
							userLoop(ClientSocket);
						{false,Reason} ->
							Status = string:join(["LoginResponse","failure",Reason], "^"),
							gen_tcp:send(ClientSocket, list_to_binary(Status));
						{timeout,Reason} -> 
							Status = string:join(["LoginResponse","failure",Reason], "^"),
							gen_tcp:send(ClientSocket, list_to_binary(Status))
					end;
				_ ->
					Status = "BadQuery^User need to login first",
					gen_tcp:send(ClientSocket, list_to_binary(Status))
			end;
			
        {error, closed} ->
            ok
    end.



%%
%% Local Functions
%%

parseClientMessage(Msg)->
       [H|T]= string:tokens(Msg,"^"),
       case string:to_lower(H) of
       		"register" ->
				{register,T};
            "login" -> 
				{login,T};
		   "createsession" ->
			   	{createSession, T};
		   "addusertosession" ->
			   {addUserToSession, T};
		   "chat" ->
			   {chat, T};
		   "getallloggedinusers" ->
			   getAllLoggedInUsers;
		   "logout" ->
			   logout;
		   _ ->
			   badinput
       end.

userLoop(ClientSocket) ->
	%%wait for 100 ms for user to send a command first,
	case gen_tcp:recv(ClientSocket, 0, 100) of
    {ok, Data} ->
		%%Parse the data first and take appropriate action
            case parseClientMessage(binary_to_list(Data)) of
				{createSession, ListOfUsers} ->
					sessionManager:createSession(ListOfUsers);
					
				{addUsersToSession, [SessionID|ListOfUsers]} ->
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:addUsersToSession({IntSessionID, ListOfUsers});

				{chat, [Sender|[SessionID|Text]]}->
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:chat({Sender, IntSessionID, string:join(Text,"^")});

				getAllLoggedInUsers ->
					LoggedInUsersList = userManager:getAllLoggedInUsers(),
					Status = string:join(["LoggedInUsers",LoggedInUsersList],"^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status));
				logout ->
					done;
				_ ->
					ignore_junk_request
			end;

	{error, timeout} ->
		Var = "" ; %%Do nothing here as this is intentional timeout for polling

			
	{error, ErrReason} ->
    	io:format("Error while receving on socket ~w. Reason : ~w ~n",[ClientSocket,ErrReason])
			
	end,	
			
		%%otherwise just wait for another 100 ms for other process to send some data	
		receive
			{createSessionResponse, success, Response} -> 
				ResponseMsg = string:join(["CreateSessionResponse","success",Response], "^");
			{createSessionResponse, failure,Reason} ->
				ResponseMsg = string:join(["CreateSessionResponse","failure",Reason], "^");
			{createSessionResponse, timeout,Reason} -> 
				ResponseMsg = string:join(["CreateSessionResponse","timeout",Reason], "^");
			{addUserToSessionResponse, success, Response} -> 
				ResponseMsg = string:join(["addUserToSessionResponse","success",Response], "^");
			{addUserToSessionResponse, failure,Reason} ->
				ResponseMsg = string:join(["addUserToSessionResponse","failure",Reason], "^");
			{addUserToSessionResponse, timeout,Reason} -> 
				ResponseMsg = string:join(["addUserToSessionResponse","timeout",Reason], "^");
			{chatResponse, success, Response} ->
				ResponseMsg = string:join(["chatResponse","success",Response],"^");
			{chatResponse, failure, Reason} ->
				ResponseMsg = string:join(["chatResponse","failure",Reason],"^");
			{chatResponse, timeout, Reason} ->
				ResponseMsg = string:join(["chatResponse","timeout",Reason],"^")
		after 100 ->
			ResponseMsg = "",%%this will never be sent because we call the loop immediately
			userLoop(ClientSocket)
		end,

	gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
	userLoop(ClientSocket).