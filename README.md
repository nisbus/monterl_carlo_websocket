monterl_carlo_websocket
=======================

monterl_carlo websocket server  

###Getting started 

```bash
clone git://github.com/nisbus/monterl_carlo_websocket.git
./rebar get-deps
./rebar clean compile generate
./rel/monterl_carlo_websocket/bin/monterl_carlo_websocket console
```
  


You now have websocket server running on localhost:8080  
  
You can now navigate in your browser to http://localhost:8080/index.html and start playing with charting 
  
If you want to play with the websocket connection through a browser a nice way of testing it  
is using the [Simple Websocket Client chrome extension](https://chrome.google.com/webstore/detail/simple-websocket-client/pfdhoblngboilpfeibdedpjgfnlcodoo)  
Just type in localhost:8080 and press connect.  
Then copy paste the api samples (one at a time) from below into the request box and hit send.  

###API  
  
```json
{"type":"start", "symbol":"Y"}
```
```json
{"type":"subscribe", "symbol":"Y"}
```
```json
{"type":"stop", "symbol":"Y"}
```
```json
{"type":"graph", "symbol":"Y","graph_type":"statistics","points":5}
```  

Check out [monterl_carlo](https://github.com/nisbus/monterl_carlo) for more parameters to the start and graph methods.