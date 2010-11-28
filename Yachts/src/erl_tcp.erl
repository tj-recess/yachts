%% Author: Arpit
%% Created: Nov 26, 2010
%% Description: TODO: Add description to erl_tcp
-module(erl_tcp).
-export([start_server/1, connect/1, recv_loop/1]).

-define(LISTEN_PORT, 9000).
-define(TCP_OPTS, [binary, {packet, raw}, {nodelay, true}, {reuseaddr, true}, {active, once}]).

start_server(Port) ->
% start up the service and error out if we cannot
case gen_tcp:listen(Port, ?TCP_OPTS) of
{ok, Listen} -> spawn(?MODULE, connect, [Listen]),
io:format("~p Server Started.~n", [erlang:localtime()]);
Error ->
io:format("Error: ~p~n", [Error])
end.

connect(Listen) ->
{ok, Socket} = gen_tcp:accept(Listen),
inet:setopts(Socket, ?TCP_OPTS),
% kick off another process to handle connections concurrently
spawn(fun() -> connect(Listen) end),
%%handleClient(Socket),
recv_loop(Socket),
gen_tcp:close(Socket).


handleClient(ClientSocket) ->
	inet:setopts(ClientSocket, [{active, once}]),
	io:format("seperate loop running for a client"),
    receive
		{tcp, ClientSocket, Data} ->
			io:format("user sent ~w", [list_to_atom(Data)]),
			gen_tcp:send(ClientSocket, "LoginResponse^Success^Welcome"),
			handleClient(ClientSocket);
		% exit loop if the client disconnects
		{tcp_closed, ClientSocket} ->
			io:format("~w: Client ~w Disconnected.~n", [erlang:localtime(), ClientSocket])
	end.


recv_loop(Socket) ->
% reset the socket for flow control
inet:setopts(Socket, [{active, once}]),
receive
% do something with the data you receive
{tcp, Socket, Data} ->
io:format("~p ~p ~p~n", [inet:peername(Socket), erlang:localtime(), Data]),
gen_tcp:send(Socket, "I Received " ++ Data),
gen_tcp:send(Socket, "Some new data"),
recv_loop(Socket);
% exit loop if the client disconnects
{tcp_closed, Socket} ->
io:format("~p Client Disconnected.~n", [erlang:localtime()])
end.

recv_loop_activef(Socket) ->
% reset the socket for flow control
inet:setopts(Socket, [{active, false}]),
case gen_tcp:recv(Socket, 0, 2000) of
% do something with the data you receive
	{ok, Data} ->
		io:format("~p ~p ~p~n", [inet:peername(Socket), erlang:localtime(), Data]),
		gen_tcp:send(Socket, "I Received " ++ Data),
		recv_loop_activef(Socket);
% exit loop if the client disconnects
	{error, Reason} ->
		io:format("~p Client received error : ~p .~n", [erlang:localtime(),Reason])
end.