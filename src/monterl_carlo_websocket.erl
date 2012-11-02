-module(monterl_carlo_websocket).  
-behaviour(application).  
-export([start/2, stop/1,start_phase/3]).  
-export([config/0, config/1, config/2,
         start/0, a_start/2]).

-define(APP,monterl_carlo_websocket).

config(Key, Default) ->
    case application:get_env(?APP, Key) of
        undefined -> Default;
        {ok, Val} -> Val
    end.

config(Key) ->
    case application:get_env(?APP, Key) of
        undefined -> erlang:error({missing_config, Key});
        {ok, Val} -> Val
    end.

config() ->
    application:get_all_env(?APP).
  
start() ->
    a_start(?APP, permanent).

start(_StartType, _StartArgs) ->  
    monterl_carlo_websocket_sup:start_link().  
  
stop(_State) ->  
    ok.  

a_start(App, Type) ->
 start_ok(App, Type, application:start(App, Type)).

start_phase(listen,_Type,_Args) ->    
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
    cowboy:start_http(http, 100, [{port, config(http_port)}],[{dispatch, Dispatch}]),
    ok.

start_ok(_App, _Type, ok) -> ok;
start_ok(_App, _Type, {error, {already_started, _App}}) -> ok;
start_ok(App, Type, {error, {not_started, Dep}}) ->
    ok = a_start(Dep, Type),
    a_start(App, Type);
start_ok(App, _Type, {error, Reason}) ->
    erlang:error({app_start_failed, App, Reason}).
