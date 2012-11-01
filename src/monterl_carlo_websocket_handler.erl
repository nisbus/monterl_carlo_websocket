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
    C = fun(X) -> Client ! {send,jsx:term_to_json(X)} end,
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
    Type = proplists:get_value(<<"type">>,Props),
    case Type of
	<<"graph">> -> 
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    Points = proplists:get_value(<<"points">>,Props,50),
	    GraphType = proplists:get_value("graph_type",Props,bid),
	    Resp = monterl_carlo:graph(Symbol,Points,GraphType),
	    {reply,{text,jsx:term_to_json(Resp),Req,State}};	    
	<<"subscribe">> -> 
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    monterl_carlo:start(Symbol,Callback),
	    {ok, Req, State};
	<<"start">> ->
	    Symbol = proplists:get_value(<<"symbol">>,Props),
	    Px = proplists:get_value(<<"price">>,Props),
	    Precision = proplists:get_value(<<"precision">>,Props),
	    Annual_Vol = proplists:get_value(<<"annual_volatility">>,Props),
	    AnnualExpRet = proplists:get_value(<<"annual_expected_returns">>,Props),
	    Interval = proplists:get_value(<<"interval">>,Props),
	    {ok, Pid} = monterl_carlo:start_link(Symbol,Px,Precision,Annual_Vol,AnnualExpRet,Interval),
	    {ok, Req, State#state{sim_pid=Pid}};
	_ ->
	    {ok, Req, State}
    end.
