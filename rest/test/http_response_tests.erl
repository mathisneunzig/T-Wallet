-module(http_response_tests).
-include_lib("eunit/include/eunit.hrl").

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
    [_Headers, BodyPart] = re:split(R, "\r\n\r\n", [{return, list}]),
    ?assertEqual(Body, BodyPart).
