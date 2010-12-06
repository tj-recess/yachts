%%
%% Module Name
%%
-module(user).
%%
%% Include files
%%
-import(userManager).
-import(sessionManager).
%%
%% Exported Functions
%%
-export([handleClient/1,userLoop/1]).
%%
%% API Functions
%%
% process that receives the first message from the user process that it is listening on
handleClient(ClientSocket) ->
    case gen_tcp:recv(ClientSocket, 0) of
        {ok, Data} ->
			D = binary_to_list(Data),
			io:fwrite(console,"~nuser sent ~w", [list_to_atom(D)]),
			%%Parse the data first and take appropriate action
			%check if more than one cmds were received together			
			executeCommands(parseClientMessage(string:tokens(D, "~"),[]),ClientSocket);
        {error, closed} ->
            ok
    end.


%parses multiple messages received together by the server process listening to the client 
%and creates a list of server-executable commands
parseClientMessage([],FormattedList) ->
	FormattedList;
parseClientMessage([First|Rest],FormattedList)->
    NewFormattedList = [parseSingleCmd(First)|FormattedList],
	parseClientMessage(Rest, NewFormattedList).

%parses a single message sent by the user and
%creates a server executable command
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


%method to execute a list of commands recieved from a client before he is logged in
%If client sends a valid register request then the user is registered if not already and the handleClient process is terminted.
%If the client sends a vaid login request then the user is logged in and a new user process is spawned to handle post login messages from the user
%If any junk message is recieved then it is ignored and handleClient process is terminated
executeCommands([],ClientSocket) ->
	done;
executeCommands([H|T], ClientSocket) ->
	case H of
		{register,[Username, Password, FirstName, LastName, Location, EmailId]} ->
			io:fwrite(console,"~nUser sent : register",[]),
			Result = userManager:registerUser(Username, Password, FirstName, LastName, Location, EmailId), %register user in database
			case Result of %if user is successfully registered then send a success message else send error message to client
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
			io:fwrite(console,"~nUser sent : login",[]),
			Pid = spawn(?MODULE, userLoop, [ClientSocket]),% spawn a new process 'userloop', to listen to post login commands from the client
			Result = userManager:loginUser(Pid, Username, Password),% login the user
			case Result of
				{true, Reason} -> %send success message to client if the client was successfully logged in
					Status = string:join(["LoginResponse","success"|Reason], "^"),
					sendClient(ClientSocket,Status);							
				{false,Reason} -> %if the login was unsuccessful due to some unexpected problem then terminate the 'userloop' process listening to the client
					Status = string:join(["LoginResponse","failure"|Reason], "^"),
					sendClient(ClientSocket,Status),
					exit(Pid, kill);
				{timeout,Reason} -> %if the login process has timed out then terminate the 'userloop' process listening to the client
					Status = string:join(["LoginResponse","failure"|Reason], "^"),
					sendClient(ClientSocket,Status),
					exit(Pid, kill)
			end;
		
		_ -> %handle junk message and send message to client
			Status = "BadQuery^User need to login first",
			gen_tcp:send(ClientSocket, list_to_binary(Status))
	end,
	executeCommands(T, ClientSocket). % process the next commands in the list

%method to execute a list of post-login commands received from a client
%for all valid post-login messages received from the user a message is sent to the sessionManager process
%to execute the required actions 
executePostLoginCommands([],ClientSocket) ->
	done;
executePostLoginCommands([H|T], ClientSocket) ->
	case H of
				{createSession, ListOfUsers} -> %send message to sessionManager process to create a session and add the users in ListOfUsers 
					io:fwrite(console,"~n client sent : createSession, params: ~w",[ListOfUsers]),
					sessionManager:createSession(ListOfUsers);
					
				{addUsersToSession, [SessionID|ListOfUsers]} -> %send message to sessionManager process to add the users in ListOfUsers to a specific session
					io:fwrite(console,"~n client sent : addUsersToSession, params: Session ID ~w UserList~w",[SessionID,ListOfUsers]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:addUsersToSession({IntSessionID, ListOfUsers});

				{removeUserFromSession, [SessionID,Username]} -> %send message to sessionManager process to remove a user from a session 
					io:fwrite(console,"~n client sent : removeUserFromSession, params: Session ID~w Username ~w",[SessionID,Username]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:removeUserFromSession({IntSessionID, Username});
				
				{chat, [Sender|[SessionID|Text]]}-> %send message to sessionManager process to process a chat message sent by a specific user 
					io:fwrite(console,"~n client sent : chat, params: Sender ~w Session ID ~w Text ~w",[Sender,SessionID,Text]),
					{IntSessionID, _} = string:to_integer(SessionID),
					sessionManager:chat({Sender, IntSessionID, string:join(Text,"^")});
				{logout,[User]} -> %send message to userManager process to log out the user and a second message to sessionManager to remove the user from corresponding sessions
					io:fwrite(console,"~n client sent : logout, params: ~w",[User]),
					userManager:logout(User);
				getAllLoggedInUsers -> % 
					LoggedInUsersList = userManager:getAllLoggedInUsers(),
					Status = string:concat(string:join(["LoggedInUsers"|LoggedInUsersList],"^"),"\n"),					
					gen_tcp:send(ClientSocket, list_to_binary(Status));
									
				_ ->
					ignore_junk_request
		
	end,
	executePostLoginCommands(T, ClientSocket).%process next commands iteratively

%the userLoop process is the sole process that handles a client after it has logged in and polls between two modes
%In Mode 1 it  listens for any message from the user for 100ms,if a message is received it parses the message 
%		and sends corresponding commands to sessionManager to execute them
%In Mode 2 it listens for any reply messages from the sessionManager process, returns response messages to the client
%		It basically acts an interface between the client and sessionManager
userLoop(ClientSocket) ->
	%%wait for 100 ms to listen to client messages,
	case gen_tcp:recv(ClientSocket, 0, 100) of
    {ok, Data} ->
		D = binary_to_list(Data),
			io:fwrite(console,"~nReceived message ~w", [list_to_atom(D)]),
		%%Parse the data first and take appropriate action
		executePostLoginCommands(parseClientMessage(string:tokens(D, "~"),[]),ClientSocket);

	{error, timeout} ->
		Var = "" ; %%Do nothing here as this is intentional timeout for polling

	{error, closed} ->
		self() ! endProcess;
		
	{error, ErrReason} ->
    	io:fwrite(console,"~nError while receving on socket ~w. Reason : ~w ",[ClientSocket,ErrReason]),
		self() ! endProcess
			
	end,	
			
		%%otherwise just wait for another 100 ms for other process to send some data	
		receive
		%translates messages received from sessionManager process and sends them to the client
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
			
			{logoutResponse,Status, Response} ->
				ResponseMsg = string:join(["logoutResponse",Status,Response],"^"),
				sendClient(ClientSocket,ResponseMsg);
			
			endProcess ->
				clientDone
		after 100 ->
			userLoop(ClientSocket) %
		end.

%sends message 'Message' to the user connected to ClientSocket 
%with '~' appended in the end which acts as  file separator

sendClient(ClientSocket,Message)->
	ResponseMessage=string:concat(Message,"~"),
	gen_tcp:send(ClientSocket, list_to_binary(ResponseMessage)),
	io:fwrite(console,"~nMESSAGE SENT ~s",[ResponseMessage]).