%% Author: Dwai
%% Created: Nov 20, 2010
%% Description: TODO: Add description to server
-module(client).
-export([client/2]).


client(PortNo,Message) ->
    Status = gen_tcp:connect("localhost",PortNo,[{active,false},{packet,0}]),
    case Status of
		{ok,Sock} ->
			case gen_tcp:send(Sock,list_to_binary(Message)) of
				ok ->
					io:format("Socket ~w sent data : ~w ~n",[Sock, Message]),
					case gen_tcp:recv(Sock,0, 5000) of
						{ok, Data} ->
							io:format("client ~p received data : ~w ~n",[Sock, binary_to_list(Data)]);
					
						{error, Reason} ->
							io:format("client ~p received error, Reason: ~w ~n",[Sock, Reason])
					end;
				{error, Reason} ->
					io:format("client ~p : error in sending data. ~n Error : ~w ~n ",[Sock, Reason])
			end;
		{error, Msg} ->
			io:format("Error in Socket creation ~w",Msg)
	end.
