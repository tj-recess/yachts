%%
%% Module Name
%%
-module(userManager).

%%
%% Include files
%%
-import(dict).
%%
%% Exported Functions
%%
-compile(export_all).
%%
%% API Functions
%%
%starts userManager process
start()->
	Pid = spawn(?MODULE, initUserList, []),
	register(userManager, Pid).
%connects to database and initiates loggedInUserList
initUserList()->
	application:start(odbc), %start Erlang ODBC supervisor process
	%Connecton String for Windows
	%WinConnString="Driver={MySQL ODBC 5.1 Driver};Server=localhost;Database=yachts;User=root;Password=root;Option=3;",
	%Connection String for Windows
	ConnString="DSN=yachts;UID=root;PWD=root",
	{ok, Conn}=odbc:connect(ConnString, []), %Connect to database
	pg2:create(login),	%create a prcess group to hold all the user processes for logged in users
	{ok,Pid}=file:open("Console.txt",[write]), %logger file
	register(console,Pid),
	loginManagerDB(dict:new(), Conn). %call loginManagerDB which is responsible for maintaining list of logged in users

%registers a user in database
registerUser(Username, Password, FirstName, LastName, Location, EmailId)
  -> userManager ! {self(), register, {Username, Password, FirstName, LastName, Location, EmailId}}, %send message to userManager process to register the user   
	receive
		success ->
			{success,["You have been registered successfully"]};
		{error, Reason} ->
			{failure, [Reason]}
 	after 2000 -> 
 		{timeout,["Operation timed out, Try again later!"]}
	end.

%logs in a user in the database
loginUser(UserPid, Username, Password)->
	io:fwrite(console,"received params : ~w ~w ~w ~n",[UserPid,Username, Password]),
	userManager ! {self() , login , Username, Password, UserPid}, %sends message to userManager process to log in the user
	receive
		already -> {true, ["You are already logged in"]};
		success -> {true, ["You have been logged in successfully"]};
		failure -> {false,["Incorrect Username or Password."]};
		Result -> Result
	after 2000 ->
		UserPid ! {timeout, ["Operation timed out, Try again later!"]}
	end.
%method to retrieve all the currently logged in users 
getAllLoggedInUsers() ->
	userManager ! {self(), getAllLoggedInUsers}, %send message to userManager process to retrieve all logged in users
	receive
		ListofUsernames -> ListofUsernames %show retreived user list
	after 2000 ->
		io:fwrite(console,"Operation Timed Out, try again later",[])
	end.
%method to fetch user information of a logged in user
getUserInfo(Username) ->
	userManager ! {self(), info, Username}, %send message to userManager process to fetch user information of a logged in user 
	receive
		{ok,[Value]} -> {ok,[Value]};
		error -> error
	after 2000 ->
		io:fwrite(console,"Operation Timed Out, try again later",[])
	end.

getAll() -> %%returns entire dict for testing purpose
	userManager ! {self(), getAll},
	receive
		Value -> Value
	after 5000 ->
		io:fwrite(console,"Operation Timed Out, try again later",[])
	end.

%This method maintains a list of logged in users and listens to messages from other processes
%regarding user management.It handles user registration and login along with responding to queries regarding 
%information of logged in users
loginManagerDB(LoggedInUserList, Conn)->
	receive
		%%register a user
		{From, register, {Username, Password, FirstName, LastName, Location, EmailId}}->
			Result = odbc:param_query(Conn, "CALL RegisterUser(?,?,?,?,?,?)", 
				[{{sql_varchar, 30},[Username]},
				{{sql_varchar, 30},[Password]},
				{{sql_varchar, 30},[FirstName]},
				{{sql_varchar, 30},[LastName]},
				{{sql_varchar, 30},[Location]},
				{{sql_varchar, 30},[EmailId]}]
				),
			case Result of
				{updated, RowCount } -> %response from database
					case RowCount of
						0 -> %Username already exists
							From ! {error, "Username already exists"};
						1 -> %User registered successfully
							From ! success;
						Weird ->
							io:fwrite(console,"~n unexpected rows updated in register user ~w",[Weird])
					end;	
			 	{error, _ } ->
					From ! Result
			end,
			loginManagerDB(LoggedInUserList, Conn);

		%%login an existing user
		{From, login, Username, Password, UserPid}->
			case dict:find(Username, LoggedInUserList) of
				{ok, _} -> %% found in dictionary, user already logged in
					From ! already, 
					loginManagerDB(LoggedInUserList, Conn);
			
				error -> %% not already logged in, fetch from DB 
					Result = odbc:param_query(Conn, "CALL GetUserInfo(?,?)", 
						[{{sql_varchar, 30},[Username]},
						{{sql_varchar, 30},[Password]}
						]),
					case Result of %%accepting first record from the returned data
						%% ideally, only one record should have returned.
						{selected, _, []} ->
							From ! failure,
							loginManagerDB(LoggedInUserList, Conn);
						{selected, _, [H|_]} -> 
							NewList = dict:append(Username, {H,UserPid}, LoggedInUserList),% add entry in dictionary with user info of logged in user along with its userPid
							pg2:join(login,UserPid), %add user to logged in user process group
							From ! success,
							loginManagerDB(NewList, Conn);
						{error, _ } ->	
							From ! {failure, Result},
							loginManagerDB(LoggedInUserList, Conn)
					end
			end;
			
		{From, getAllLoggedInUsers} ->
			From ! dict:fetch_keys(LoggedInUserList),%return Logged-in-users list
			loginManagerDB(LoggedInUserList, Conn);

		
		{From, info, Username} -> %get information of a specific user and return it to requesting peer process
			case dict:find(Username, LoggedInUserList) of 
				{ok,[{Info,UserPid}]} ->
					case lists:member(UserPid,pg2:get_members(login)) of %if user process has ended accidentally then remove it from dictionary else return its information
						true ->
							From ! {ok,[{Info,UserPid}]},
							loginManagerDB(LoggedInUserList, Conn);
						_ -> 
							From ! error,
							%cleanup loggedInUsersList
							NewLoggedInUserList = dict:erase(Username, LoggedInUserList), 
							loginManagerDB(NewLoggedInUserList, Conn)
					end;
				error ->
							From ! error,
							loginManagerDB(LoggedInUserList, Conn);
				Weird ->
					io:fwrite(console,"received weird value in getUserInfo : ~w ~n",[Weird]),
					From ! error,
					loginManagerDB(LoggedInUserList, Conn)
			end;
		
		
		{From, getAll} -> %debugger message handler to retrieve state of dictionary
			From ! LoggedInUserList,
			loginManagerDB(LoggedInUserList, Conn);
			
		_ ->
			loginManagerDB(LoggedInUserList, Conn)
	end.
