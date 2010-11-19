%% Author: Arpit
%% Created: Nov 17, 2010
%% Description: TODO: Add description to dbManager
-module(dbManager).

%%
%% Include files
%%
-import(application).
%%
%% Exported Functions
%%
-compile(export_all).

%%
%% API Functions
%%

intDbManager()->
	application:start(odbc),
	ConnString="Driver={MySQL ODBC 5.1 Driver};Server=localhost;Database=test;User=root;Password=root;Option=3;",
	{ok, Conn}=odbc:connect(ConnString, []),
	spawn(dbManager, runQuery, [Conn,""]).

runQuery(Conn)->
	receive
		{From, runSelect, QueryToRun} ->
			Results= odbc:sql_query(Conn, QueryToRun),
			From ! Results,
			runQuery(Conn);
		{From, _, QueryToRun} ->
			runQuery(Conn)
	end.


%%
%% Local Functions
%%

