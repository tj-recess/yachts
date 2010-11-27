%% Author: Dwai
%% Created: Nov 10, 2010
%% Description: TODO: Add description to echo

-module(server).
-export([start/1]).

start(ServerPort) ->
    case gen_tcp:listen(ServerPort,[binary, {active, false},{packet,raw}]) of
        {ok, ServerSocket} ->
             acceptClientConnection(ServerSocket);
        {error,Reason} ->
            {error,Reason}
    end.

acceptClientConnection(ServerSocket) ->
	io:format("Server is listening for client's connections..."),
    case gen_tcp:accept(ServerSocket) of
		{ok, ClientSocket} ->
   			spawn(user, handleClient, [ClientSocket]);
		{error, Msg} ->
			io:format("Error in connection: ~w ~n",[Msg])
	end,
		acceptClientConnection(ServerSocket).