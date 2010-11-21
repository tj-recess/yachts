%% Author: Dwai
%% Created: Nov 20, 2010
%% Description: TODO: Add description to server
-module(client).
-export([client/2]).


client(PortNo,Message) ->
    {ok,Sock} = gen_tcp:connect("localhost",PortNo,[{active,false},{packet,2}]),
    gen_tcp:send(Sock,Message),
	io:format("Socket ~w ~n",[Sock]),
    {ok,A} = gen_tcp:recv(Sock,0),
    A.
