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

initRegisteredUserList()->
	application:start(odbc),
	ConnString="Driver={MySQL ODBC 5.1 Driver};Server=localhost;Database=yachts;User=root;Password=root;Option=3;",
	{ok, Conn}=odbc:connect(ConnString, []),
	spawn(users, loginManagerDB, [dict:new(), Conn]).

loginManagerDB(UserDict, Conn)->
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
				{udpated, _ } ->
					From ! success;
			 	{error, _ } ->
					From ! Result
			end,
			odbc:disconnect(Conn),
			loginManagerDB(UserDict, Conn);
		_ ->
			odbc:disconnect(Conn),
			loginManagerDB(UserDict, Conn)
	end.
		

registerUser(LoginManagerPid, Username, Password, FirstName, LastName, Location, EmailId)
  -> LoginManagerPid ! {self(), register, {Username, Password, FirstName, LastName, Location, EmailId}},
	receive
		success ->io:format("User is registered successfully!");
		{error, Msg} ->Msg;
		Other -> Other
	end.

loginUser(LoginManagerPid, Username, Password)->
	LoginManagerPid ! {self() , login , Username, Password},
	receive
		true ->io:format("User is logged in successfully!");
		false ->io:format("Username or password is incorrect, Login Failed!");
		failure ->io:format("Username or password is incorrect, Login Failed!")
	end.

%%
%% Local Functions
%%

loginManager(UserDict)->
	receive
		{From, register, {Username, Password, FirstName, LastName, Location, EmailId}}->
			case dict:find(Username, UserDict) of
				error -> From ! success,
						loginManager(dict:append(Username, {Password, FirstName, LastName, Location, EmailId}, UserDict));		
				{ok, _} -> From ! failure,
						loginManager(UserDict)
			end;
		
		{From, login, Username, Password}->
			case dict:find(Username, UserDict) of
				error -> From ! failure,
						loginManager(UserDict);		
				{ok, [{Passwd, _, _, _, _}]} when Password == Passwd-> From ! true,
						loginManager(UserDict);
				{ok, _} -> From ! false,
						loginManager(UserDict)  
			end
	end.
