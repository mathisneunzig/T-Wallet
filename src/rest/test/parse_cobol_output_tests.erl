-module(parse_cobol_output_tests).
-include_lib("eunit/include/eunit.hrl").

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
    Response = twallet_server:parse_cobol_output(
                 "ERR|USAGE|Usage: foo <bar>|extra",
                 fun(_) -> should_not_be_called end),
    ?assertMatch({match, _},
                 re:run(binary_to_list(Response), "\"code\": \"USAGE\"")).
