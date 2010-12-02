-module(server2).
-compile(export_all).
-import(user).
-import(userManager).
-import(sessionManager).

-define(TCP_OPTIONS, [binary, { active, false}, { packet, 0 } , {reuseaddr, true}]).


% Call echo:listen(Port) to start the service.
listen(Port) ->
	userManager:start(),
	sessionManager:start(),
    {ok, LSocket} = gen_tcp:listen(Port, ?TCP_OPTIONS),
    spawn(fun() -> accept(LSocket) end).

% Wait for incoming connections and spawn the echo loop when we get one.
accept(LSocket) ->
    {ok, Socket} = gen_tcp:accept(LSocket),
    spawn(fun() -> loop(Socket) end),
    accept(LSocket).

% Echo back whatever data we receive on Socket.
loop(Socket) ->
%% 	user:dummy(Socket),
	user:handleClient(Socket).
%%     case gen_tcp:recv(Socket, 0) of
%%         {ok, Data} ->
%%             gen_tcp:send(Socket, "loginResponse^success^Message"),
%% 			gen_tcp:send(Socket,"another reponse"),
%% 			user:handleClient(Socket),
%%             loop(Socket);
%%         {error, closed} ->
%%             ok
%%     end.

%% handleClient(ClientSocket) ->
%% 	gen_tcp:recv(ClientSocket, 0),
%% 	gen_tcp:send(ClientSocket, "data from handle client").