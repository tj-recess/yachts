%% Author: Dwai
%% Created: Nov 20, 2010
%% Description: TODO: Add description to server
-module(dclient).
-export([client/1]).


client(PortNo) ->
    {ok,Sock} = gen_tcp:connect("localhost",PortNo,[{active,false},{packet,2}]),
    W=spawn(client,loopWrite,[Sock]),
	L=spawn(client,loopListen,[Sock]),
	{W,L}.
	
loopWrite(Sock)->
	receive
		{From,Message} -> gen_tcp:send(Sock,Message),
				loopWrite(Sock)
	end.

loopListen(Sock)->
	{ok,Message}=gen_tcp:recv(Sock,0), 
	 io:format("Socket ~w ~n",[Message]),
	 loopListen(Sock).
	
send(Pid,Message)->
	Pid ! {self(),Message},
	receive
		{send,Value1} -> Value1;
		{recv,Value2} -> Value2
	end.	
		
