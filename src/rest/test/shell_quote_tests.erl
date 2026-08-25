-module(shell_quote_tests).
-include_lib("eunit/include/eunit.hrl").

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
