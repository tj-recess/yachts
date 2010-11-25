%% Author: Dwai
%% Created: Nov 10, 2010
%% Description: TODO: Add description to echo

-module(server).
-export([start/1]).

start(ServerPort) ->
    case gen_tcp:listen(ServerPort,[{active, false},{packet,0}]) of
        {ok, ServerSocket} ->
             acceptClientConnection(ServerSocket);
        {error,Reason} ->
            {error,Reason}
    end.

acceptClientConnection(ServerSocket) ->
    case gen_tcp:accept(ServerSocket) of
		{ok, ClientSocket} ->
   			spawn(user, handleClient, [ClientSocket]),
    		acceptClientConnection(ServerSocket);
		{error, Msg} ->
			io:format("Error in connection: ~w ~n",[Msg]),
			acceptClientConnection(ServerSocket)
	end.

