%%
%%Module Name
%%
-module(erlangServer).
%%
%% Include files
%%
-import(user).
-import(userManager).
-import(sessionManager).
%%
%% Exported Functions
%%
-compile(export_all).
%%
%% Constants
%%
-define(TCP_OPTIONS, [binary, { active, false}, { packet, 0 } , {reuseaddr, true}]).
%binary - Received Packet is delivered as a binary
%{active,false} - Indicates passive mode, the process has to explicitly receive incoming data by calling gen_tcp:recv/2,3
%{packet,0} - {packet,PacketType} -> defines the type of packets to use for a socket.O indicates no packaging is done
%{reuseaddr,true} - allows local reuse of port numbers

%%
%% API Functions
%%
% Call echo:listen(Port) to start the service.
listen(Port,MaxConn) ->
	{TimeUserManager,_}=timer:tc(userManager,start,[]),
	io:format("Time taken by userManager ~w~n",[TimeUserManager]),
	{TimeSessionManager,_}=timer:tc(sessionManager,start,[]),
	io:format("Time taken by sessionManager ~w~n",[TimeSessionManager]),
	%userManager:start(),
	%sessionManager:start(),
    {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
    {Time,_}=timer:tc(?MODULE,accept,[LSocket,MaxConn,1]),
	io:format("Time taken by accept ~w~n",[Time]).
	%spawn(fun() -> accept(LSocket) end).

% Wait for incoming connections, spawn tMaxConnhe user:handleClient/1 proces when we get one and continue waiting.
accept(LSocket,MaxConn,Count) ->
	if
		Count==MaxConn ->
			io:format("Maximum Connections Reached ~w !! No more connections~n",[Count]);
		Count =< MaxConn ->
		 	{ok, Socket} = gen_tcp:accept(LSocket),
    		spawn(user,handleClient,[Socket]),
    		accept(LSocket,MaxConn,Count+1)
	end.

