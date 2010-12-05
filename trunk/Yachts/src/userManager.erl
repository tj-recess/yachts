%% Author: Arpit
%% Created: Nov 16, 2010
%% Description: TODO: Add description to user
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
%%dwai, password, firstName, lastName, location, emailId

start()->
	Pid = spawn(?MODULE, initRegisteredUserList, []),
	register(loginManager, Pid).

initRegisteredUserList()->
	application:start(odbc),
	%WinConnString="Driver={MySQL ODBC 5.1 Driver};Server=localhost;Database=yachts;User=root;Password=root;Option=3;",
	ConnString="DSN=yachts;UID=root;PWD=root",
	{ok, Conn}=odbc:connect(ConnString, []),
	pg2:create(login),	%change
	loginManagerDB(dict:new(), Conn).


registerUser(Username, Password, FirstName, LastName, Location, EmailId)
  -> loginManager ! {self(), register, {Username, Password, FirstName, LastName, Location, EmailId}},
	receive
		success ->
			{success,["You have been registered successfully"]};
		{error, Reason} ->
			{failure, [Reason]}
%% 	after 5000 -> 
%% 		{timeout,["Operation timed out, Try again later!"]}
	end.

loginUser(UserPid, Username, Password)->
	io:format("received params : ~w ~w ~w ~n",[UserPid,Username, Password]),
	loginManager ! {self() , login , Username, Password, UserPid},
	receive
		already -> {true, ["You are already logged in"]};
		success -> {true, ["You have been logged in successfully"]};
		failure -> {false,["Incorrect Username or Password."]};
		Result -> Result
	after 2000 ->
		UserPid ! {timeout, ["Operation timed out, Try again later!"]}
	end.

getAllLoggedInUsers() ->
	loginManager ! {self(), getAllLoggedInUsers},
	receive
		ListofUsernames -> ListofUsernames
	after 2000 ->
		io:format("Operation Timed Out, try again later")
	end.

getUserInfo(Username) ->
	loginManager ! {self(), info, Username},
	receive
		{ok,[Value]} -> {ok,[Value]};
		error -> error
	after 2000 ->
		io:format("Operation Timed Out, try again later")
	end.

getAll() -> %%returns entire dict for testing purpose
	loginManager ! {self(), getAll},
	receive
		Value -> Value
	after 5000 ->
		io:format("Operation Timed Out, try again later")
	end.

%%
%% Local Functions
%%
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
				{updated, RowCount } ->
					case RowCount of
						0 -> 
							From ! {error, "Username already exists"};
						1 -> 
							From ! success;
						Weird ->
							io:format("~n unexpected rows updated in register user ~w",[Weird])
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
							NewList = dict:append(Username, {H,UserPid}, LoggedInUserList),
							pg2:join(login,UserPid), %change
							From ! success,
							loginManagerDB(NewList, Conn);
						{error, _ } ->	
							From ! {failure, Result},
							loginManagerDB(LoggedInUserList, Conn)
					end
			end;
			
		{From, getAllLoggedInUsers} ->
			From ! dict:fetch_keys(LoggedInUserList),
			loginManagerDB(LoggedInUserList, Conn);

		
		{From, info, Username} ->
			case dict:find(Username, LoggedInUserList) of 
				{ok,[{Info,UserPid}]} ->
					case lists:member(UserPid,pg2:get_members(login)) of
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
					io:format("received weird value in getUserInfo : ~w ~n",[Weird]),
					From ! error,
					loginManagerDB(LoggedInUserList, Conn)
			end;
		
		
		{From, getAll} ->
			From ! LoggedInUserList,
			loginManagerDB(LoggedInUserList, Conn);
			
		_ ->
			loginManagerDB(LoggedInUserList, Conn)
	end.
