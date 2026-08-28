-module(qr_tests).
-include_lib("eunit/include/eunit.hrl").

%%% ============================================================
%%% build_payment_uri/4
%%% ============================================================

uri_no_amount_test() ->
    Uri = twallet_server:build_payment_uri("10000001", "EUR", "2", ""),
    ?assertEqual("twallet://pay?to=10000001&currency=EUR&decimals=2", Uri).

uri_with_amount_test() ->
    Uri = twallet_server:build_payment_uri("10000001", "EUR", "2", "1500"),
    ?assertEqual("twallet://pay?to=10000001&currency=EUR&decimals=2&amount=1500", Uri).

uri_zero_decimals_test() ->
    Uri = twallet_server:build_payment_uri("20000001", "USD", "0", ""),
    ?assertEqual("twallet://pay?to=20000001&currency=USD&decimals=0", Uri).

uri_amount_zero_test() ->
    %% Explicit zero amount is still encoded
    Uri = twallet_server:build_payment_uri("10000001", "EUR", "2", "0"),
    ?assertEqual("twallet://pay?to=10000001&currency=EUR&decimals=2&amount=0", Uri).

%%% ============================================================
%%% parse_query_string/1
%%% ============================================================

qs_empty_test() ->
    ?assertEqual([], twallet_server:parse_query_string("")).

qs_single_test() ->
    Result = twallet_server:parse_query_string("amount=1500"),
    ?assertEqual("1500", proplists:get_value("amount", Result)).

qs_multiple_test() ->
    Result = twallet_server:parse_query_string("amount=500&currency=EUR"),
    ?assertEqual("500", proplists:get_value("amount",   Result)),
    ?assertEqual("EUR", proplists:get_value("currency", Result)).

qs_missing_key_test() ->
    Result = twallet_server:parse_query_string("amount=999"),
    ?assertEqual(undefined, proplists:get_value("other", Result)).

qs_malformed_pair_test() ->
    %% A pair with no "=" is silently skipped
    Result = twallet_server:parse_query_string("badpair&amount=42"),
    ?assertEqual("42", proplists:get_value("amount", Result)),
    ?assertEqual(1, length(Result)).
