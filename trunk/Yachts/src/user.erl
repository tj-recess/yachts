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
			io:format("~nuser sent ~w", [list_to_atom(D)]),
			
			%%Parse the data first and take appropriate action
			%check if more than one cmds were received together			
			executeCommands(parseClientMessage(string:tokens(D, "~"),[]),ClientSocket);
			
        {error, closed} ->
            ok
    end.

executePostLoginCommands([],ClientSocket) ->
	done;
executePostLoginCommands([H|T], ClientSocket) ->
	case H of
				{createSession, ListOfUsers} ->
					io:format("~n client sent : createSession, params: ~w",[ListOfUsers]),
					sessionManager:createSession(ListOfUsers);
					
				{addUsersToSession, [SessionID|ListOfUsers]} ->
					io:format("~n client sent : addUsersToSession, params: Session ID ~w UserList~w",[SessionID,ListOfUsers]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:addUsersToSession({IntSessionID, ListOfUsers});

				{removeUserFromSession, [SessionID,Username]} ->
					io:format("~n client sent : removeUserFromSession, params: Session ID~w Username ~w",[SessionID,Username]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:removeUserFromSession({IntSessionID, Username});
				
				{chat, [Sender|[SessionID|Text]]}->
					io:format("~n client sent : chat, params: Sender ~w Session ID ~w Text ~w",[Sender,SessionID,Text]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:chat({Sender, IntSessionID, string:join(Text,"^")});

				getAllLoggedInUsers ->
					LoggedInUsersList = userManager:getAllLoggedInUsers(),
					Status = string:concat(string:join(["LoggedInUsers"|LoggedInUsersList],"^"),"\n"),
					
					gen_tcp:send(ClientSocket, list_to_binary(Status));
				logout ->
					done;
				_ ->
					ignore_junk_request
		
	end,
	executePostLoginCommands(T, ClientSocket).









executeCommands([],ClientSocket) ->
	done;
executeCommands([H|T], ClientSocket) ->
	case H of
		{register,[Username, Password, FirstName, LastName, Location, EmailId]} ->
			io:format("~nUser sent : register"),
			Result = userManager:registerUser(Username, Password, FirstName, LastName, Location, EmailId),
			case Result of
				{success, Reason} -> 
					Status = string:join(["RegisterResponse","success"|Reason], "^"),
					sendClient(ClientSocket,Status);
				{failure,Reason} ->
					Status = string:join(["RegisterResponse","failure"|Reason], "^"),
					sendClient(ClientSocket,Status);
				{timeout,Reason} -> 
					Status = string:join(["RegisterResponse","failure"|Reason], "^"),
					sendClient(ClientSocket,Status)
			end;
		{login, [Username, Password]} ->
			io:format("~nUser sent : login"),
			Pid = spawn(?MODULE, userLoop, [ClientSocket]),
			Result = userManager:loginUser(Pid, Username, Password),
			case Result of
				{true, Reason} -> 
					Status = string:join(["LoginResponse","success"|Reason], "^"),
					sendClient(ClientSocket,Status);							
				{false,Reason} ->
					Status = string:join(["LoginResponse","failure"|Reason], "^"),
					sendClient(ClientSocket,Status),
					exit(Pid, kill);
				{timeout,Reason} -> 
					Status = string:join(["LoginResponse","failure"|Reason], "^"),
					sendClient(ClientSocket,Status),
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
		D = binary_to_list(Data),
			io:format("~nReceived message ~w", [list_to_atom(D)]),
		%%Parse the data first and take appropriate action
		executePostLoginCommands(parseClientMessage(string:tokens(D, "~"),[]),ClientSocket);

	{error, timeout} ->
		Var = "" ; %%Do nothing here as this is intentional timeout for polling

	{error, closed} ->
		self() ! endProcess;
		
	{error, ErrReason} ->
    	io:format("~nError while receving on socket ~w. Reason : ~w ",[ClientSocket,ErrReason]),
		self() ! endProcess
			
	end,	
			
		%%otherwise just wait for another 100 ms for other process to send some data	
		receive
		
			{addUsersToSessionResponse, success, Response} -> 
				ResponseMsg = string:join(["addUsersToSessionResponse","success"|Response], "^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			{addUsersToSessionResponse, failure,Reason} ->
				ResponseMsg = string:join(["addUsersToSessionResponse","failure"|Reason], "^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			{addUsersToSessionResponse, timeout,Reason} -> 
				ResponseMsg = string:join(["addUsersToSessionResponse","timeout"|Reason], "^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			
			{removeUserFromSessionResponse, success, Response} -> 
				ResponseMsg = string:join(["removeUserFromSessionResponse","success"|Response], "^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			{removeUserFromSessionResponse, failure,Reason} ->
				ResponseMsg = string:join(["removeUserFromSessionResponse","failure"|Reason], "^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			{removeUserFromSessionResponse, timeout,Reason} -> 
				ResponseMsg = string:join(["removeUserFromSessionResponse","timeout"|Reason], "^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			
			{chatResponse, success, Response} ->
				ResponseMsg = string:join(["chatResponse","success"|Response],"^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			{chatResponse, failure, Reason} ->
				ResponseMsg = string:join(["chatResponse","failure"|Reason],"^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			{chatResponse, timeout, Reason} ->
				ResponseMsg = string:join(["chatResponse","timeout"|Reason],"^"),
				sendClient(ClientSocket,ResponseMsg),
				userLoop(ClientSocket);
			endProcess ->
				clientDone
		after 100 ->
			userLoop(ClientSocket)
		end.


sendClient(ClientSocket,Message)->
	ResponseMessage=string:concat(Message,"~"),
	gen_tcp:send(ClientSocket, list_to_binary(ResponseMessage)),
	io:format("~nMESSAGE SENT ~s",[ResponseMessage]).