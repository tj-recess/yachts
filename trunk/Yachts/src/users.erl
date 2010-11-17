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
%%

initRegisteredUserList()->spawn(users, loginManager, [dict:new()]).

loginManager(UserDict)->
	receive
		{From, register, {Username, Password, FirstName, LastName, Location, EmailId}}->
			case dict:find(Username, UserDict) of
				error -> From ! success,
						loginManager(dict:append(Username, {Password, FirstName, LastName, Location, EmailId}, UserDict));		
				{ok, _} -> From ! failure,
						loginManager(UserDict)
			end
	end.

registerUser(LoginManagerPid, UserInfo)
  -> LoginManagerPid ! {self(), register, UserInfo},
	receive
		success ->io:format("User is registered successfully!");
		failure ->io:format("Username already exists, Registration Failed!")
	end.

login(UserName, Passwd) when UserName == arpit, Passwd == passwd
  -> true.
	%%[UserName, Passwd].
	%%fetch from database
	
loop() ->
	receive {From, Message} -> From ! Message,
		loop()
	end.

%%
%% Local Functions
%%

