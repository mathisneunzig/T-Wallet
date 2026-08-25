-module(parse_json_tests).
-include_lib("eunit/include/eunit.hrl").

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
