%% Author: arpit
%% Created: Dec 2, 2010
%% Description: TODO: Add description to cmd
-module(cmd).
-import(dclient).
%%
%% Include files
%%

%%
%% Exported Functions
%%
-export([start/0]).

%%
%% API Functions
%%

start() ->
	P = dclient:client(3000),
	Q = dclient:client(3000),
	R = dclient:client(3000),
	S = dclient:client(3000),
	
	dclient:send(P, "login^user1^pwd"),
	dclient:send(Q, "login^user2^pwd"),
	dclient:send(R, "login^user3^pwd"),
	dclient:send(S, "login^kt^pwd").

%% 	dclient:send(P, "createsession^user1^user2"),
%%	dclient:send(P, "adduserstosession^user1^kt"),
%% 	dclient:send(Q, "adduserstosession^user2^user3").
	

%%
%% Local Functions
%%

