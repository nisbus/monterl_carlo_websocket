-module(monterl_carlo_websocket).  
-behaviour(application).  
-export([start/2, stop/1]).  
  
start(_StartType, _StartArgs) ->  
    %% {Host, list({Path, Handler, Opts})}  
    %% Dispatch the requests (whatever the host is) to  
    %% erws_handler, without any additional options.  
    Dispatch = [{'_', [  
        {'_', monterl_carlo_websocket_handler, []}  
    ]}],  
    %% Name, NbAcceptors, Transport, TransOpts, Protocol, ProtoOpts  
    %% Listen in 10100/tcp for http connections.  
    cowboy:start_http(http, 100, [{port, 8080}],[{dispatch, Dispatch}]),  
    monterl_carlo_websocket_sup:start_link().  
  
stop(_State) ->  
    ok.  
