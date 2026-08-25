-module(json_helpers_tests).
-include_lib("eunit/include/eunit.hrl").

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
