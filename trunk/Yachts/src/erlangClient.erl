%Test Erlang Client for Erlang Server-Erlang Client Testing
%%
%% Module Name
%%
-module(erlangClient).
%%
%% Exported Functions
%%
-export([start/1,send/2,loopWrite/1]).
%%
%% API Functions
%%
%starts client process and connects to 'PortNo' port 
start(PortNo) ->
    {ok,Sock} = gen_tcp:connect("localhost",PortNo,[binary, {active,false},{packet,0}]),
    W=spawn(?MODULE,loopWrite,[Sock]), %spawns a new process 'loopWrite' 
	W.
	
%This process polls between listening to messages from server and messages from the user
loopWrite(Sock)->
	%wait for 20ms and listen to messages from the user
	receive 
		{From,Message} ->
			case gen_tcp:send(Sock,Message) of
				ok ->
					io:format("Socket ~w sent data : ~w ~n",[Sock, Message]);

				{error, Reason} ->
					io:format("client ~p encountered error while sending data, Reason: ~w ~n",[Sock, Reason])
			end,
			loopWrite(Sock);
		
		_ -> loopWrite(Sock)
	%after 20ms listen to response messages from the server
		after 20 -> 
			case  gen_tcp:recv(Sock,0, 20) of %wait for reponses from the server for 20ms 
			{ok, Data} ->
			  io:format("client ~p received data : ~s ~n",[Sock, Data]),
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
%Send message to process with process id 'Pid'
send(Pid,Message)->
	Pid ! {self(),list_to_binary(Message)}.
