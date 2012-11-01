-module(monterl_carlo_websocket_handler).  
-behaviour(cowboy_http_handler).  
-behaviour(cowboy_http_websocket_handler).  
  
% Behaviour cowboy_http_handler  
-export([init/3, handle/2, terminate/2]).  
  
% Behaviour cowboy_http_websocket_handler  
-export([  
    websocket_init/3, websocket_handle/3,  
    websocket_info/3, websocket_terminate/3  
]).  
-record(state,
	{
	  callback,
	  sim_pid
	}).

% Called to know how to dispatch a new connection.  
init(_Any, _Req, _Opts) ->      
    {upgrade, protocol, cowboy_websocket}.
  
% Should never get here.  
handle(_Req, State) ->  
    {ok, Req2} = cowboy_http_req:reply(404, [  
        {'Content-Type', <<"text/html">>}  
    ]),  
    {ok, Req2, State}.  
  
terminate(_Req, _State) ->  
    ok.  
  
% Called for every new websocket connection.  
websocket_init(_Any, Req, []) ->  
%    Req2 = cowboy_http_req:compact(Req),
    Client = self(),
    C = fun(X) -> Client ! {send,jsx:to_json(X)} end,
    {ok, Req, #state{callback = C}}.  
  
% Called when a text message arrives.  
websocket_handle({text, Msg}, Req, State) ->  
    case jsx:is_json(Msg) of
	true ->
	    handle_message(Msg,Req,State);
	false ->

	    {ok, Req, State}
    end;
  
websocket_handle(_Any, Req, State) ->  
    
    {ok, Req, State}.  

websocket_info({send,Message}, Req, State) -> 
    {reply, {text, Message}, Req, State};
  
websocket_info(_Info, Req, State) ->     
    {ok, Req, State, hibernate}.  
  
websocket_terminate(_Reason, _Req, _State) ->  
    ok.  

handle_message(Msg,Req,#state{callback = Callback} = State) ->
    Props = jsx:json_to_term(Msg),
    Type = case is_list(Props) of
	       true -> proplists:get_value(<<"type">>,Props,undefined);
	       false -> undefined
	   end,
    case Type of
	<<"graph">> -> 
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    Points = to_int(proplists:get_value(<<"points">>,Props,50)),
	    GraphType = proplists:get_value(<<"graph_type">>,Props,<<"both">>),
	    Resp = monterl_carlo:graph(Symbol,Points,GraphType),
	    Callback(Resp),
	    {ok, Req, State};
	<<"subscribe">> -> 
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    monterl_carlo:subscribe(Symbol,Callback),
	    {ok, Req, State};
	<<"start">> ->	    
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    Px = to_float(proplists:get_value(<<"price">>,Props,100.50)),
	    Precision = to_int(proplists:get_value(<<"precision">>,Props,5)),
	    Annual_Vol = to_float(proplists:get_value(<<"annual_volatility">>,Props,0.1)),
	    AnnualExpRet = to_float(proplists:get_value(<<"annual_expected_returns">>,Props,0.1)),
	    Interval = to_int(proplists:get_value(<<"interval">>,Props,1000)),
	    io:format("Creating sim ~p, ~p, ~p, ~p, ~p, ~p~n",[Symbol,Px,Precision,Annual_Vol,AnnualExpRet,Interval]),
	    Resp = monterl_carlo:start_link(Symbol,Px,Precision,Annual_Vol,AnnualExpRet,Interval),
	    {ok, Pid} = Resp,
	    {ok, Req, State#state{sim_pid=Pid}};
	<<"unsubscribe">> -> 
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    monterl_carlo:unsubscribe(Symbol),
	    {ok, Req, State};
	<<"stop">> -> 
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    monterl_carlo:stop(Symbol),
	    {ok, Req, State};
	_ ->
	    io:format("Ignoring request~n"),
	    {ok, Req, State}
    end.

to_int(Val) when is_binary(Val) ->
    to_int(binary_to_list(Val));
to_int(Val) when is_list(Val) ->
    list_to_integer(Val);
to_int(Val) when is_integer(Val) ->
    Val;
to_int(_) ->
    0.

to_float(Val) when is_binary(Val) ->
    to_float(binary_to_list(Val));
to_float(Val) when is_list(Val) ->
    list_to_float(Val);
to_float(Val) when is_float(Val) ->
    Val;
to_float(_) ->
    0.0.


	       
