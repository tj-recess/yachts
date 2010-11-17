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

initRegisteredUserList()->spawn(users, loginManager, [dict:new()]).

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

registerUser(LoginManagerPid, Username, Password, FirstName, LastName, Location, EmailId)
  -> LoginManagerPid ! {self(), register, {Username, Password, FirstName, LastName, Location, EmailId}},
	receive
		success ->io:format("User is registered successfully!");
		failure ->io:format("Username already exists, Registration Failed!")
		
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

