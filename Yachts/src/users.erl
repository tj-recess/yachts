%% Author: Arpit
%% Created: Nov 16, 2010
%% Description: TODO: Add description to user
-module(users).

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
	Pid = spawn(users, initRegisteredUserList, []),
	register(loginManager, Pid).

initRegisteredUserList()->
	application:start(odbc),
	ConnString="Driver={MySQL ODBC 5.1 Driver};Server=localhost;Database=yachts;User=root;Password=root;Option=3;",
	{ok, Conn}=odbc:connect(ConnString, []),
	loginManagerDB(dict:new(), Conn).


registerUser(Username, Password, FirstName, LastName, Location, EmailId)
  -> loginManager ! {self(), register, {Username, Password, FirstName, LastName, Location, EmailId}},
	receive
		success ->io:format("User is registered successfully!");

		{error, Msg} ->Msg
	after 5000 -> 
		io:format("Operation timed out, Try again later!")
	end.

loginUser([UserPid, Username, Password])->
	loginManager ! {self() , login , Username, Password, UserPid},
	receive
		already ->io:format("User is already logged into the system!");
		success ->io:format("User has successfully logged into the system!");
		%%{failure,Result} -> Result;
		failure ->io:format("Username, Password don't match, Login Failed!");
		Result ->Result
	after 2000 ->
		io:format("Operation timed out, Try again later!")
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
				{updated, _ } ->
					From ! success;
			 	{error, _ } ->
					From ! Result
			end,
			loginManagerDB(LoggedInUserList, Conn);

		%%login an existing user
		{From, login, Username, Password, UserPid}->
			case dict:find(Username, LoggedInUserList) of
				{ok, _} -> %% found in dictionary, user already logged in
					From ! already;
			
				error -> %% not already logged in, fetch from DB 
					Result = odbc:param_query(Conn, "CALL GetUserInfo(?,?)", 
						[{{sql_varchar, 30},[Username]},
						{{sql_varchar, 30},[Password]}
						]),
					case Result of %%accepting first record from the returned data
						%% ideally, only one record should have returned.
						{selected, _, []} ->
							From ! {failure, "User doesn't exists in system!!"},
							loginManagerDB(LoggedInUserList, Conn);
						{selected, _, [H|_]} -> 
							NewList = dict:append(Username, {H,UserPid}, LoggedInUserList),
							From ! success,
							loginManagerDB(NewList, Conn);
						{error, _ } ->	
							From ! {failure, Result},
							loginManagerDB(LoggedInUserList, Conn)
					end
			end;
			
		_ ->
			loginManagerDB(LoggedInUserList, Conn)
	end.
