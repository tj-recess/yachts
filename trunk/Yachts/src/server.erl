%% Author: Dwai
%% Created: Nov 10, 2010
%% Description: TODO: Add description to echo

-module(server).
-export([start/1]).

-define(TCP_OPTS, [binary, {packet, raw}, {nodelay, true}, {reuseaddr, true}, {active, once}]).

start(ServerPort) ->
    case gen_tcp:listen(ServerPort,?TCP_OPTS) of
        {ok, ServerSocket} ->
        	spawn(?MODULE, acceptClientConnection, [ServerSocket]),
			io:format("~p Server Started.~n", [erlang:localtime()]);
        {error,Reason} ->
            io:format("Error: ~p~n", [Reason])
    end.

acceptClientConnection(ServerSocket) ->
	case gen_tcp:accept(ServerSocket) of
	{ok, ClientSocket} -> 
		inet:setopts(ClientSocket, ?TCP_OPTS),
		% kick off another process to handle connections concurrently
		spawn(fun() -> acceptClientConnection(ServerSocket) end),
		handleClient(ClientSocket),
		gen_tcp:close(ClientSocket);
	{error, Msg} ->
			io:format("Error in connection: ~w ~n",[Msg])
	end.

handleClient(ClientSocket) ->
	inet:setopts(ClientSocket, [{active, once}]),
	io:format("seperate loop running for a client"),
    receive
		{tcp, ClientSocket, Data} ->
			io:format("user sent ~w", [Data]),
			%%Parse the data first and take appropriate action
            case parseClientMessage(Data) of
				{register,[Username, Password, FirstName, LastName, Location, EmailId]} ->
					io:format("User sent : register"),
					Status = userManager:registerUser(Username, Password, FirstName, LastName, Location, EmailId);
				{login, Username, Password} ->
					io:format("User sent : login"),
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
        {tcp_closed, Socket} ->
            io:format("~p Client ~p Disconnected.~n", [erlang:localtime(), Socket])
    end.



%%
%% Local Functions
%%


userLoop(ClientSocket) ->
	inet:setopts(ClientSocket, [{active, once}]),
	%%wait for 100 ms for user to send a command first,
	receive
		{tcp, ClientSocket, Data} ->
			%%Parse the data first and take appropriate action
            case parseClientMessage(Data) of
				{createSession, ListOfUsers} ->
					sessionManager:createSession(ListOfUsers);
					
				{addUsersToSession, [SessionID|ListOfUsers]} ->
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:addUsersToSession({IntSessionID, ListOfUsers});

				{chat, [Sender|[SessionID|Text]]}->
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:chat({Sender, IntSessionID, string:join(Text,"^")});

				getAllLoggedInUsers ->
					LoggedInUsersList = users:getAllLoggedInUsers(),
					Status = string:join(["LoggedInUsers"|LoggedInUsersList],"^"),
					gen_tcp:send(ClientSocket, Status)
			end;
				
		{createSessionResponse, success, Response} -> 
			ResponseMsg = string:join(["CreateSessionResponse"|["success"|Response]], "^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{createSessionResponse, failure,Reason} ->
			ResponseMsg = string:join(["CreateSessionResponse","failure",Reason], "^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{createSessionResponse, timeout,Reason} -> 
			ResponseMsg = string:join(["CreateSessionResponse","timeout",Reason], "^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{addUserToSessionResponse, success, Response} -> 
			ResponseMsg = string:join(["addUserToSessionResponse"|["success"|Response]], "^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{addUserToSessionResponse, failure,Reason} ->
			ResponseMsg = string:join(["addUserToSessionResponse"|["failure"|Reason]], "^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{addUserToSessionResponse, timeout,Reason} -> 
			ResponseMsg = string:join(["addUserToSessionResponse"|["timeout"|Reason]], "^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{chatResponse, success, Response} ->
			ResponseMsg = string:join(["chatResponse"|["success"|Response]],"^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{chatResponse, failure, Reason} ->
			ResponseMsg = string:join(["chatResponse"|["failure"|Reason]],"^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
		{chatResponse, timeout, Reason} ->
			ResponseMsg = string:join(["chatResponse"|["timeout"|Reason]],"^"),
			gen_tcp:send(ClientSocket, ResponseMsg);
        {tcp_closed, Socket} ->
			io:format("~p : Client ~p Disconnected.~n", [erlang:localtime(), Socket])
	end,	
	
	userLoop(ClientSocket).

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
			   getAllLoggedInUsers
       end.
