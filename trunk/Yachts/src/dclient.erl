%% Author: Dwai
%% Created: Nov 20, 2010
%% Description: TODO: Add description to server
-module(dclient).
-export([client/1,send/2,recv/1,loopWrite/1,loopListen/1]).


client(PortNo) ->
    {ok,Sock} = gen_tcp:connect("localhost",PortNo,[binary, {active,false},{packet,0}]),
    W=spawn(dclient,loopWrite,[Sock]),
	%L=spawn(client,loopListen,[Sock]),
	W.
	
loopWrite(Sock)->
	receive
		{From,Message} ->
%% 			io:format("Message received from ~p =  ~w ~n",[From, Message]),
			case gen_tcp:send(Sock,Message) of
				ok ->
					io:format("Socket ~w sent data : ~w ~n",[Sock, Message]);

				{error, Reason} ->
					io:format("client ~p encountered error while sending data, Reason: ~w ~n",[Sock, Reason])
			end,
			loopWrite(Sock);
		
		_ -> loopWrite(Sock)

		after 20 ->
			case  gen_tcp:recv(Sock,0, 20) of
			{ok, Data} ->
			  io:format("client ~p received data : ~w ~n",[Sock, list_to_atom(binary_to_list(Data))]),
			  loopWrite(Sock);
 			{error, timeout} ->				
 				io:format(""),
				loopWrite(Sock);
			{error, closed} ->
				io:format("server down!!! ~n Client will be terminated now...Done.");
			{error, ebadf} ->
				io:format("server down!!! ~n Client will be terminated now...Done.");			
			{error, Reason} ->
				io:format("client ~p encountered error while receiving, Reason: ~w ~n",[Sock, Reason]),
				loopWrite(Sock)
			end	
	end.

loopListen(Sock)->
	receive 
		{From,recv} ->
			case gen_tcp:recv(Sock,0) of
				{ok,Data} ->
					From ! {recv,ok};
				
					Other -> From ! {error,Other} 
			end,
			loopListen(Sock);
			Other ->ok,	
		loopListen(Sock)
	end.
		

send(Pid,Message)->
	Pid ! {self(),list_to_binary(Message)}.
%% 	receive
%% 		{ok,Sock,Data} -> io:format("client ~p received data : ~w ~n",[Sock, list_to_atom(Data)]);
%% 		{error,Sock,Reason} -> io:format("client ~p received error, Reason: ~w ~n",[Sock, Reason]);
%% 		{sendErr,Sock,Reason} ->io:format("client ~p : error in sending data. ~n Error : ~w ~n ",[Sock, Reason]);
%% 		_->io:format("end")
%% 	end.	
		
recv(Pid)->
	Pid ! {self(),recv},
	receive
		{recv,Value1} -> "received"++Value1;
		{error,Other} -> Other
	end.