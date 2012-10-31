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
	  callback
	}).

% Called to know how to dispatch a new connection.  
init(_Any, _Req, _Opts) ->  
    
    {upgrade, protocol, cowboy_http_websocket}.  
  
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
    C = fun(X) -> Client ! {send,X} end,
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
    {reply, {text, jsx:term_to_json(Message)}, Req, State};
  
websocket_info(_Info, Req, State) ->     
    {ok, Req, State, hibernate}.  
  
websocket_terminate(_Reason, _Req, _State) ->  
    ok.  

handle_message(Msg,Req,State) ->
    Props = jsx:json_to_term(Msg),
    Type = proplists:get_value("type",Props),
    case Type of
	<<"graph">> -> void;
	<<"subscribe">> -> void
    end,
    {reply,{text,Msg,Req,State}}.
