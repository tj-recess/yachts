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
listen(Port) ->
	userManager:start(),
	sessionManager:start(),
    {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
    spawn(fun() -> accept(LSocket) end).

% Wait for incoming connections, spawn the user:handleClient/1 proces when we get one and continue waiting.
accept(LSocket) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    spawn(user,handleClient,[Socket]),
    accept(LSocket).

