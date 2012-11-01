-module(monterl_carlo_websocket).  
-behaviour(application).  
-export([start/2, stop/1]).  
  
start(_StartType, _StartArgs) ->  
    %% {Host, list({Path, Handler, Opts})}  
    %% Dispatch the requests (whatever the host is) to  
    %% erws_handler, without any additional options.  
    Dispatch = [{'_', [  
			 {[<<"index.html">>,'...'], cowboy_static,
			  [ {directory, {priv_dir, monterl_carlo_websocket,[]}},
			    {file,<<"index.html">>},
			    {mimetypes,[{<<".html">>, [<<"text/html">>]}]}]},
			 {[<<"jquery.flot.js">>,'...'],cowboy_static,
			  [ {directory, {priv_dir, monterl_carlo_websocket,[]}},
			    {file,<<"jquery.flot.js">>},
			    {mimetypes, [{<<".js">>, [<<"text/javascript">>]}]}]},
			 {'_', monterl_carlo_websocket_handler, []}
		      ]}],  
    Port = list_to_integer(os:getenv("PORT")),
    cowboy:start_http(http, 100, [{port, Port}],[{dispatch, Dispatch}]),  
    monterl_carlo_websocket_sup:start_link().  
  
stop(_State) ->  
    ok.  
