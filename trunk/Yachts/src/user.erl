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
-export([handleClient/1,dummy/1,userLoop/1]).

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
			io:format("user sent ~w", [list_to_atom(D)]),
			
			%%Parse the data first and take appropriate action
			%check if more than one cmds were received together			
			executeCommands(parseClientMessage(string:tokens(D, "~"),[]),ClientSocket);
			
        {error, closed} ->
            ok
    end.


executeCommands([],ClientSocket) ->
	done;
executeCommands([H|T], ClientSocket) ->
	case H of
		{register,[Username, Password, FirstName, LastName, Location, EmailId]} ->
			io:format("User sent : register"),
			Result = userManager:registerUser(Username, Password, FirstName, LastName, Location, EmailId),
			case Result of
				{success, Reason} -> 
					Status = string:join(["RegisterResponse","success"|Reason], "^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status));
				{failure,Reason} ->
					Status = string:join(["RegisterResponse","failure"|Reason], "^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status));
				{timeout,Reason} -> 
					Status = string:join(["RegisterResponse","failure"|Reason], "^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status))
			end;
		{login, [Username, Password]} ->
			io:format("User sent : login"),
			Pid = spawn(?MODULE, userLoop, [ClientSocket]),
			Result = userManager:loginUser(Pid, Username, Password),
			case Result of
				{true, Reason} -> 
					Status = string:join(["LoginResponse","success"|Reason], "^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status));							
				{false,Reason} ->
					Status = string:join(["LoginResponse","failure"|Reason], "^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status)),
					exit(Pid, kill);
				{timeout,Reason} -> 
					Status = string:join(["LoginResponse","failure"|Reason], "^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status)),
					exit(Pid, kill)
			end;
		
		_ ->
			Status = "BadQuery^User need to login first",
			gen_tcp:send(ClientSocket, list_to_binary(Status))
	end,
	executeCommands(T, ClientSocket).


%%
%% Local Functions
%%

parseClientMessage([],FormattedList) ->
	FormattedList;
parseClientMessage([First|Rest],FormattedList)->
    NewFormattedList = [parseSingleCmd(First)|FormattedList],
	parseClientMessage(Rest, NewFormattedList).

parseSingleCmd(Cmd) ->
	[H|T] = string:tokens(Cmd, "^"),
	case string:to_lower(H) of
       		"register" ->
				{register,T};
            "login" -> 
				{login,T};
		   "createsession" ->
			   	{createSession, T};
		   "adduserstosession" ->
			   {addUsersToSession, T};
		   "chat" ->
			   {chat, T};
		   "getallloggedinusers" ->
			   getAllLoggedInUsers;
		   "removeuserfromsession" ->
			   {removeUserFromSession, T};
		   "logout" ->
			   {logout,T};
		   _ ->
			   {badinput,T}
    end.

userLoop(ClientSocket) ->
	%%wait for 100 ms for user to send a command first,
	case gen_tcp:recv(ClientSocket, 0, 100) of
    {ok, Data} ->
		%%Parse the data first and take appropriate action
            case parseSingleCmd(binary_to_list(Data)) of
				{createSession, ListOfUsers} ->
					sessionManager:createSession(ListOfUsers);
					
				{addUsersToSession, [SessionID|ListOfUsers]} ->
					io:format("~n clien sent : addUsersToSession, params: ~w ~w",[SessionID,ListOfUsers]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:addUsersToSession({IntSessionID, ListOfUsers});

				{removeUserFromSession, [SessionID|Username]} ->
					io:format("~n clien sent : removeUserFromSession, params: ~w ~w",[SessionID,Username]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:removeUserFromSession({IntSessionID, Username});
				
				{chat, [Sender|[SessionID|Text]]}->
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:chat({Sender, IntSessionID, string:join(Text,"^")});

				getAllLoggedInUsers ->
					LoggedInUsersList = userManager:getAllLoggedInUsers(),
					Status = string:join(["LoggedInUsers"|LoggedInUsersList],"^"),
					gen_tcp:send(ClientSocket, list_to_binary(Status));
				logout ->
					done;
				_ ->
					ignore_junk_request
			end;

	{error, timeout} ->
		Var = "" ; %%Do nothing here as this is intentional timeout for polling

	{error, closed} ->
		self() ! endProcess;
		
	{error, ErrReason} ->
    	io:format("Error while receving on socket ~w. Reason : ~w ~n",[ClientSocket,ErrReason]),
		self() ! endProcess
			
	end,	
			
		%%otherwise just wait for another 100 ms for other process to send some data	
		receive
			{createSessionResponse, success, Response} -> 
				ResponseMsg = string:join(["CreateSessionResponse","success"|Response], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{createSessionResponse, failure,Reason} ->
				ResponseMsg = string:join(["CreateSessionResponse","failure"|Reason], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{createSessionResponse, timeout,Reason} -> 
				ResponseMsg = string:join(["CreateSessionResponse","timeout"|Reason], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{addUsersToSessionResponse, success, Response} -> 
				ResponseMsg = string:join(["addUsersToSessionResponse","success"|Response], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{addUsersToSessionResponse, failure,Reason} ->
				ResponseMsg = string:join(["addUsersToSessionResponse","failure"|Reason], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{addUsersToSessionResponse, timeout,Reason} -> 
				ResponseMsg = string:join(["addUsersToSessionResponse","timeout"|Reason], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			
			{removeUserFromSessionResponse, success, Response} -> 
				ResponseMsg = string:join(["removeUserFromSessionResponse","success"|Response], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{removeUserFromSessionResponse, failure,Reason} ->
				ResponseMsg = string:join(["removeUserFromSessionResponse","failure"|Reason], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{removeUserFromSessionResponse, timeout,Reason} -> 
				ResponseMsg = string:join(["removeUserFromSessionResponse","timeout"|Reason], "^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			
			{chatResponse, success, Response} ->
				ResponseMsg = string:join(["chatResponse","success"|Response],"^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{chatResponse, failure, Reason} ->
				ResponseMsg = string:join(["chatResponse","failure"|Reason],"^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			{chatResponse, timeout, Reason} ->
				ResponseMsg = string:join(["chatResponse","timeout"|Reason],"^"),
				gen_tcp:send(ClientSocket, list_to_binary(ResponseMsg)),
				userLoop(ClientSocket);
			endProcess ->
				clientDone
		after 100 ->
			userLoop(ClientSocket)
		end.
