%% Author: Dwai
%% Created: Nov 20, 2010
%% Description: TODO: Add description to server
-module(client).
-export([client/2]).


client(PortNo,Message) ->
    Status = gen_tcp:connect("localhost",PortNo,[{active,false},{packet,0}]),
    case Status of
		{ok,Sock} ->
			gen_tcp:send(Sock,Message),
			io:format("Socket ~w ~n",[Sock]),
			A = gen_tcp:recv(Sock,0),
    		io:format("client ~w received data : ~w ~n",[Sock, A]);
		{error, Msg} ->
			io:format("Error in Socket creation ~w",Msg)
	end.
