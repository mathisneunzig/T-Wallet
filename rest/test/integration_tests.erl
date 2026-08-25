-module(integration_tests).
-include_lib("eunit/include/eunit.hrl").

%%% Integration smoke test.
%%% Starts the server on a random port, sends a real HTTP request,
%%% checks the response. Requires bin/ and data/ to exist relative
%%% to the cwd (run from project root).

integration_wallet_balance_test_() ->
    {timeout, 10,
     fun() ->
         Port = 19876,
         Pid = spawn(fun() ->
             os:putenv("PORT", integer_to_list(Port)),
             twallet_server:start([])
         end),
         timer:sleep(300),
         {ok, Sock} = gen_tcp:connect("127.0.0.1", Port,
                                       [binary, {active, false}]),
         Req = "GET /api/wallet/10000001 HTTP/1.1\r\n"
               "Host: localhost\r\n"
               "Connection: close\r\n"
               "\r\n",
         ok = gen_tcp:send(Sock, Req),
         {ok, Data} = recv_all(Sock, <<>>),
         gen_tcp:close(Sock),
         twallet_server:stop(),
         timer:sleep(100),
         exit(Pid, kill),
         Str = binary_to_list(Data),
         case re:split(Str, "\r\n\r\n", [{return, list}, {parts, 2}]) of
             [_Headers, Body] ->
                 ?assertMatch({match, _},
                               re:run(Body, "\"status\": \"ok\"")),
                 ?assertMatch({match, _},
                               re:run(Body, "\"account\":"));
             _ ->
                 ?assert(false)
         end
     end}.

recv_all(Sock, Acc) ->
    case gen_tcp:recv(Sock, 0, 3000) of
        {ok, Data}       -> recv_all(Sock, <<Acc/binary, Data/binary>>);
        {error, closed}  -> {ok, Acc};
        {error, timeout} -> {ok, Acc}
    end.
