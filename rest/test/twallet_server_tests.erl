-module(twallet_server_tests).
-include_lib("eunit/include/eunit.hrl").

%%% ============================================================
%%% parse_json/1
%%% ============================================================

parse_json_simple_test() ->
    Result = twallet_server:parse_json(
               "{\"account\": \"10000001\", \"pin\": \"1234\"}"),
    ?assertEqual("10000001", proplists:get_value("account", Result)),
    ?assertEqual("1234",     proplists:get_value("pin",     Result)).

parse_json_single_field_test() ->
    Result = twallet_server:parse_json("{\"field\": \"phone\"}"),
    ?assertEqual("phone", proplists:get_value("field", Result)).

parse_json_empty_value_test() ->
    Result = twallet_server:parse_json("{\"fraction\": \"\"}"),
    ?assertEqual("", proplists:get_value("fraction", Result)).

parse_json_missing_key_test() ->
    Result = twallet_server:parse_json("{\"account\": \"123\"}"),
    ?assertEqual(undefined, proplists:get_value("pin", Result)).

parse_json_many_fields_test() ->
    Body = "{\"account\": \"10000001\", \"pin\": \"1234\","
           " \"currency\": \"EUR\", \"decimals\": \"2\"}",
    Result = twallet_server:parse_json(Body),
    ?assertEqual("10000001", proplists:get_value("account",  Result)),
    ?assertEqual("1234",     proplists:get_value("pin",      Result)),
    ?assertEqual("EUR",      proplists:get_value("currency", Result)),
    ?assertEqual("2",        proplists:get_value("decimals", Result)).

parse_json_empty_body_test() ->
    Result = twallet_server:parse_json("{}"),
    ?assertEqual([], Result).

%%% ============================================================
%%% parse_cobol_output/2
%%% ============================================================

parse_cobol_ok_single_field_test() ->
    Response = twallet_server:parse_cobol_output(
                 "OK|10000001",
                 fun([Acc]) -> <<"got:", (list_to_binary(Acc))/binary>> end),
    ?assertEqual(<<"got:10000001">>, Response).

parse_cobol_ok_multiple_fields_test() ->
    Response = twallet_server:parse_cobol_output(
                 "OK|10000001|EUR|2|1000|10.00 EUR",
                 fun([Acc, Cur, Dec, Bal, Fmt]) ->
                     {Acc, Cur, Dec, Bal, Fmt}
                 end),
    ?assertEqual({"10000001", "EUR", "2", "1000", "10.00 EUR"}, Response).

parse_cobol_err_test() ->
    Response = twallet_server:parse_cobol_output(
                 "ERR|NOT_FOUND|Account not found.",
                 fun(_) -> should_not_be_called end),
    %% json_error returns a full HTTP response binary
    Str = binary_to_list(Response),
    ?assertMatch({match, _}, re:run(Str, "HTTP/1.1 400")),
    ?assertMatch({match, _}, re:run(Str, "\"status\": \"error\"")),
    ?assertMatch({match, _}, re:run(Str, "\"code\": \"NOT_FOUND\"")).

parse_cobol_unexpected_test() ->
    Response = twallet_server:parse_cobol_output(
                 "garbage output",
                 fun(_) -> should_not_be_called end),
    Str = binary_to_list(Response),
    ?assertMatch({match, _}, re:run(Str, "HTTP/1.1 400")),
    ?assertMatch({match, _}, re:run(Str, "\"code\": \"INTERNAL\"")).

parse_cobol_err_with_extra_pipes_test() ->
    %% ERR lines may have extra pipe-separated detail; only CODE and first message used
    Response = twallet_server:parse_cobol_output(
                 "ERR|USAGE|Usage: foo <bar>|extra",
                 fun(_) -> should_not_be_called end),
    ?assertMatch({match, _},
                 re:run(binary_to_list(Response), "\"code\": \"USAGE\"")).

%%% ============================================================
%%% json_object/1 and json_escape/1
%%% ============================================================

json_object_single_pair_test() ->
    Out = twallet_server:json_object([{"status", "ok"}]),
    ?assertEqual("{\"status\": \"ok\"}", Out).

json_object_multiple_pairs_test() ->
    Out = twallet_server:json_object([{"status", "ok"}, {"account", "123"}]),
    ?assertMatch("{" ++ _, Out),
    ?assertMatch({match, _}, re:run(Out, "\"status\": \"ok\"")),
    ?assertMatch({match, _}, re:run(Out, "\"account\": \"123\"")).

json_escape_plain_test() ->
    ?assertEqual("hello", twallet_server:json_escape("hello")).

json_escape_double_quote_test() ->
    ?assertEqual("say \\\"hi\\\"", twallet_server:json_escape("say \"hi\"")).

json_escape_backslash_test() ->
    ?assertEqual("a\\\\b", twallet_server:json_escape("a\\b")).

json_escape_both_test() ->
    %% Input: backslash followed by double-quote  →  \\\"
    ?assertEqual("\\\\\\\"", twallet_server:json_escape("\\\"")).

%%% ============================================================
%%% shell_quote/1
%%% ============================================================

shell_quote_plain_test() ->
    ?assertEqual("'hello'", twallet_server:shell_quote("hello")).

shell_quote_with_spaces_test() ->
    ?assertEqual("'Main St 1'", twallet_server:shell_quote("Main St 1")).

shell_quote_with_single_quote_test() ->
    %% The single quote in "it's" must be escaped as: 'it'\''s'
    ?assertEqual("'it'\\''s'", twallet_server:shell_quote("it's")).

shell_quote_empty_test() ->
    ?assertEqual("''", twallet_server:shell_quote("")).

shell_quote_multiple_single_quotes_test() ->
    ?assertEqual("'a'\\''b'\\''c'", twallet_server:shell_quote("a'b'c")).

%%% ============================================================
%%% http_response/2
%%% ============================================================

http_response_200_test() ->
    R = binary_to_list(twallet_server:http_response(200, "{}")),
    ?assertMatch("HTTP/1.1 200 OK" ++ _, R),
    ?assertMatch({match, _}, re:run(R, "Content-Type: application/json")),
    ?assertMatch({match, _}, re:run(R, "Content-Length: 2")),
    ?assertMatch({match, _}, re:run(R, "Connection: close")).

http_response_400_test() ->
    R = binary_to_list(twallet_server:http_response(400, "{\"error\":true}")),
    ?assertMatch("HTTP/1.1 400 Bad Request" ++ _, R).

http_response_body_test() ->
    Body = "{\"status\": \"ok\"}",
    R = binary_to_list(twallet_server:http_response(200, Body)),
    %% Body must appear after the blank line separator
    [_Headers, BodyPart] = re:split(R, "\r\n\r\n", [{return, list}]),
    ?assertEqual(Body, BodyPart).

%%% ============================================================
%%% Integration smoke test
%% Starts the server on a random port, sends a real HTTP request,
%% checks the response. Requires bin/ and data/ to exist relative
%% to the cwd (run from project root).
%%% ============================================================

integration_wallet_balance_test_() ->
    {timeout, 10,
     fun() ->
         %% Pick a port unlikely to be in use
         Port = 19876,
         %% Start server in background process
         Pid = spawn(fun() ->
             os:putenv("PORT", integer_to_list(Port)),
             twallet_server:start([])
         end),
         %% Give it time to bind
         timer:sleep(300),
         %% Connect and send GET /api/wallet/10000001
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
         %% Parse response: split on blank line, check body
         Str = binary_to_list(Data),
         case re:split(Str, "\r\n\r\n", [{return, list}, {parts, 2}]) of
             [_Headers, Body] ->
                 ?assertMatch({match, _},
                               re:run(Body, "\"status\": \"ok\"")),
                 ?assertMatch({match, _},
                               re:run(Body, "\"account\":"));
             _ ->
                 ?assert(false) %% malformed response
         end
     end}.

recv_all(Sock, Acc) ->
    case gen_tcp:recv(Sock, 0, 3000) of
        {ok, Data}       -> recv_all(Sock, <<Acc/binary, Data/binary>>);
        {error, closed}  -> {ok, Acc};
        {error, timeout} -> {ok, Acc}
    end.
