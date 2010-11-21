%% Author: Dwai
%% Created: Nov 10, 2010
%% Description: TODO: Add description to echo

-module(server).
-export([start/1]).

start(ListenPort) ->
    case gen_tcp:listen(ListenPort,[{active, false},{packet,0}]) of
        {ok, ListenSocket} ->
             do_accept(ListenSocket);
        {error,Reason} ->
            {error,Reason}
    end.

do_accept(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket),
   spawn(fun() -> do_echo_loop(Socket) end),
    do_accept(ListenSocket).

do_echo_loop(Socket) ->
    case gen_tcp:recv(Socket, 0) of
        {ok, Data} ->
            gen_tcp:send(Socket, Data),
            do_echo_loop(Socket);
        {error, closed} ->
            ok
    end.
