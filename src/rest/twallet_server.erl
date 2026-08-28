%% T-Wallet REST Server
%% Erlang HTTP server using only standard library (gen_tcp).
%% Start with: erl -pa ebin -s twallet_server start
%%
%% All routes delegate to COBOL action binaries via os:cmd/1.
%% Response format: JSON {"status": "ok"|"error", ...}

-module(twallet_server).
-export([start/0, start/1, stop/0]).
-export([accept_loop/1, handle/1]).
%% Exported for testing only
-export([parse_json/1, parse_cobol_output/2, json_object/1,
         json_escape/1, shell_quote/1, http_response/2,
         build_payment_uri/4, parse_query_string/1]).

-define(DEFAULT_PORT, 8080).
-define(BIN_DIR, "./bin").

%%% ============================================================
%%% Public API
%%% ============================================================

start() -> start([]).

start(_Args) ->
    Port = case os:getenv("PORT") of
        false -> ?DEFAULT_PORT;
        P     -> list_to_integer(P)
    end,
    {ok, LSock} = gen_tcp:listen(Port, [
        binary,
        {packet, http_bin},
        {active, false},
        {reuseaddr, true}
    ]),
    io:format("[T-Wallet REST] Listening on port ~w~n", [Port]),
    register(twallet_server, self()),
    accept_loop(LSock).

stop() ->
    twallet_server ! stop.

%%% ============================================================
%%% Accept loop
%%% ============================================================

accept_loop(LSock) ->
    receive
        stop -> gen_tcp:close(LSock)
    after 0 ->
        case gen_tcp:accept(LSock, 100) of
            {ok, Sock} ->
                spawn(?MODULE, handle, [Sock]),
                accept_loop(LSock);
            {error, timeout} ->
                accept_loop(LSock);
            {error, _} ->
                accept_loop(LSock)
        end
    end.

%%% ============================================================
%%% Request handler
%%% ============================================================

handle(Sock) ->
    case recv_request(Sock) of
        {ok, Method, Path, Headers, Body} ->
            Response = route(Method, Path, Headers, Body),
            send_response(Sock, Response);
        {error, _} ->
            ok
    end,
    gen_tcp:close(Sock).

%% Read HTTP request (method, path, headers, body).
recv_request(Sock) ->
    recv_request(Sock, undefined, undefined, [], 0).

recv_request(Sock, Method, Path, Headers, ContentLength) ->
    case gen_tcp:recv(Sock, 0, 5000) of
        {ok, {http_request, M, {abs_path, P}, _}} ->
            recv_request(Sock, atom_to_list(M), binary_to_list(P),
                         Headers, ContentLength);
        {ok, {http_header, _, 'Content-Length', _, V}} ->
            CL = list_to_integer(binary_to_list(V)),
            recv_request(Sock, Method, Path,
                         [{'Content-Length', CL} | Headers], CL);
        {ok, {http_header, _, K, _, V}} ->
            recv_request(Sock, Method, Path,
                         [{K, V} | Headers], ContentLength);
        {ok, http_eoh} ->
            Body = if ContentLength > 0 ->
                inet:setopts(Sock, [{packet, raw}]),
                case gen_tcp:recv(Sock, ContentLength, 5000) of
                    {ok, B} -> binary_to_list(B);
                    _       -> ""
                end;
            true -> ""
            end,
            {ok, Method, Path, Headers, Body};
        {error, Reason} ->
            {error, Reason}
    end.

%%% ============================================================
%%% Router
%%% ============================================================

%% Parse path segments, e.g. "/api/wallet/12345678/deposit"
route(Method, Path, _Headers, Body) ->
    Segments = string:tokens(Path, "/"),
    dispatch(Method, Segments, Body).

%% POST /api/auth/login
dispatch("POST", ["api", "auth", "login"], Body) ->
    J = parse_json(Body),
    Account = get_field("account", J),
    Pin     = get_field("pin", J),
    run_action("auth-login", [Account, Pin],
               fun([Acc]) ->
                   json_ok([{"account", Acc}])
               end);

%% GET /api/wallet/:account
dispatch("GET", ["api", "wallet", Account], _) ->
    run_action("wallet-balance", [Account],
               fun([Acc, Currency, Decimals, RawBal, Formatted]) ->
                   json_ok([{"account",   Acc},
                            {"currency",  Currency},
                            {"decimals",  Decimals},
                            {"balance",   RawBal},
                            {"formatted", string:strip(Formatted)}])
               end);

%% POST /api/wallet/:account/deposit
dispatch("POST", ["api", "wallet", Account, "deposit"], Body) ->
    J     = parse_json(Body),
    Whole = get_field("whole", J),
    Frac  = get_field_default("fraction", J, "0"),
    run_action("wallet-deposit", [Account, Whole, Frac],
               fun([Acc, NewBal, Formatted]) ->
                   json_ok([{"account",   Acc},
                            {"balance",   NewBal},
                            {"formatted", string:strip(Formatted)}])
               end);

%% POST /api/wallet/:account/withdraw
dispatch("POST", ["api", "wallet", Account, "withdraw"], Body) ->
    J     = parse_json(Body),
    Whole = get_field("whole", J),
    Frac  = get_field_default("fraction", J, "0"),
    run_action("wallet-withdraw", [Account, Whole, Frac],
               fun([Acc, NewBal, Formatted]) ->
                   json_ok([{"account",   Acc},
                            {"balance",   NewBal},
                            {"formatted", string:strip(Formatted)}])
               end);

%% GET /api/customer/:account
dispatch("GET", ["api", "customer", Account], _) ->
    run_action("customer-get", [Account],
               fun([Acc, Fname, Lname, Phone, Email,
                    Address, Zip, City, Country]) ->
                   json_ok([{"account", Acc},
                            {"fname",   string:strip(Fname)},
                            {"lname",   string:strip(Lname)},
                            {"phone",   string:strip(Phone)},
                            {"email",   string:strip(Email)},
                            {"address", string:strip(Address)},
                            {"zip",     string:strip(Zip)},
                            {"city",    string:strip(City)},
                            {"country", string:strip(Country)}])
               end);

%% PATCH /api/customer/:account  (customer self-service: phone/address/zip/city/country)
dispatch("PATCH", ["api", "customer", Account], Body) ->
    J     = parse_json(Body),
    Field = get_field("field", J),
    Value = get_field("value", J),
    AllowedFields = ["phone", "address", "zip", "city", "country"],
    case lists:member(Field, AllowedFields) of
        false ->
            json_error("FORBIDDEN",
                "Field '" ++ Field ++ "' is read-only for customers.");
        true ->
            run_action("customer-update", [Account, Field, Value],
                       fun([Acc, F, V]) ->
                           json_ok([{"account", Acc},
                                    {"field",   string:strip(F)},
                                    {"value",   string:strip(V)}])
                       end)
    end;

%% -------- Admin routes ----------------------------------------

%% POST /api/admin/accounts
dispatch("POST", ["api", "admin", "accounts"], Body) ->
    J = parse_json(Body),
    Args = [get_field(F, J) || F <- ["account", "pin", "currency",
        "decimals", "fname", "lname", "phone", "email",
        "address", "zip", "city", "country"]],
    run_action("admin-create-account", Args,
               fun([Acc]) -> json_ok([{"account", Acc}]) end);

%% DELETE /api/admin/accounts/:account
dispatch("DELETE", ["api", "admin", "accounts", Account], _) ->
    run_action("admin-delete-account", [Account],
               fun([Acc]) -> json_ok([{"account", Acc}]) end);

%% PATCH /api/admin/accounts/:account/suspend
dispatch("PATCH", ["api", "admin", "accounts", Account, "suspend"], _) ->
    run_action("admin-suspend-account", [Account],
               fun([Acc]) -> json_ok([{"account", Acc}]) end);

%% PUT /api/admin/customer/:account  (all 8 fields allowed)
dispatch("PUT", ["api", "admin", "customer", Account], Body) ->
    J     = parse_json(Body),
    Field = get_field("field", J),
    Value = get_field("value", J),
    AllowedFields = ["phone", "address", "zip", "city", "country",
                     "fname", "lname", "email"],
    case lists:member(Field, AllowedFields) of
        false ->
            json_error("INVALID_FIELD", "Unknown field: " ++ Field);
        true ->
            run_action("customer-update", [Account, Field, Value],
                       fun([Acc, F, V]) ->
                           json_ok([{"account", Acc},
                                    {"field",   string:strip(F)},
                                    {"value",   string:strip(V)}])
                       end)
    end;

%% -------- Banker routes ----------------------------------------

%% POST /api/banker/deposit
dispatch("POST", ["api", "banker", "deposit"], Body) ->
    J       = parse_json(Body),
    Account = get_field("account", J),
    Whole   = get_field("whole", J),
    Frac    = get_field_default("fraction", J, "0"),
    run_action("wallet-deposit", [Account, Whole, Frac],
               fun([Acc, NewBal, Formatted]) ->
                   json_ok([{"account",   Acc},
                            {"balance",   NewBal},
                            {"formatted", string:strip(Formatted)}])
               end);

%% POST /api/banker/withdraw
dispatch("POST", ["api", "banker", "withdraw"], Body) ->
    J       = parse_json(Body),
    Account = get_field("account", J),
    Whole   = get_field("whole", J),
    Frac    = get_field_default("fraction", J, "0"),
    run_action("wallet-withdraw", [Account, Whole, Frac],
               fun([Acc, NewBal, Formatted]) ->
                   json_ok([{"account",   Acc},
                            {"balance",   NewBal},
                            {"formatted", string:strip(Formatted)}])
               end);

%% GET /api/banker/balance/:account
dispatch("GET", ["api", "banker", "balance", Account], _) ->
    run_action("wallet-balance", [Account],
               fun([Acc, Currency, Decimals, RawBal, Formatted]) ->
                   json_ok([{"account",   Acc},
                            {"currency",  Currency},
                            {"decimals",  Decimals},
                            {"balance",   RawBal},
                            {"formatted", string:strip(Formatted)}])
               end);

%% PATCH /api/banker/accounts/:account/pin
dispatch("PATCH", ["api", "banker", "accounts", Account, "pin"], Body) ->
    J      = parse_json(Body),
    NewPin = get_field("pin", J),
    run_action("banker-change-pin", [Account, NewPin],
               fun([Acc]) -> json_ok([{"account", Acc}]) end);

%% PATCH /api/banker/accounts/:account/currency
dispatch("PATCH", ["api", "banker", "accounts", Account, "currency"], Body) ->
    J        = parse_json(Body),
    Currency = get_field("currency", J),
    Decimals = get_field("decimals", J),
    run_action("banker-change-currency", [Account, Currency, Decimals],
               fun([Acc, Cur, Dec]) ->
                   json_ok([{"account",  Acc},
                            {"currency", string:strip(Cur)},
                            {"decimals", string:strip(Dec)}])
               end);

%% POST /api/banker/accounts  (banker creates account)
dispatch("POST", ["api", "banker", "accounts"], Body) ->
    J = parse_json(Body),
    Args = [get_field(F, J) || F <- ["account", "pin", "currency",
        "decimals", "fname", "lname", "phone", "email",
        "address", "zip", "city", "country"]],
    run_action("admin-create-account", Args,
               fun([Acc]) -> json_ok([{"account", Acc}]) end);

%% GET /qr/:account  — HTML payment page with live QR
dispatch("GET", ["qr", Account], _) ->
    run_action("wallet-balance", [Account],
               fun([Acc, Currency, Decimals, _RawBal, Formatted]) ->
                   Html = qr_html_page(Acc,
                                       string:strip(Currency),
                                       string:strip(Decimals),
                                       string:strip(Formatted)),
                   http_response_binary("text/html", list_to_binary(Html))
               end);

%% GET /api/wallet/:account/qr[?amount=X]  — raw PNG QR code
dispatch("GET", ["api", "wallet", AccountRaw, "qr"], _) ->
    {Account, QS}   = split_path_qs(AccountRaw),
    Params          = parse_query_string(QS),
    AmountStr       = proplists:get_value("amount", Params, ""),
    run_action("wallet-balance", [Account],
               fun([Acc, Currency, Decimals, _RawBal, _Fmt]) ->
                   Uri = build_payment_uri(Acc,
                                          string:strip(Currency),
                                          string:strip(Decimals),
                                          AmountStr),
                   case run_qrencode(Uri) of
                       {ok, PngBytes} ->
                           http_response_binary("image/png", PngBytes);
                       {error, Reason} ->
                           json_error("QR_FAILED", Reason)
                   end
               end);

%% Fallback
dispatch(Method, Path, _) ->
    Msg = "No route: " ++ Method ++ " /" ++
          string:join(Path, "/"),
    json_error("NOT_FOUND", Msg).

%%% ============================================================
%%% COBOL subprocess runner
%%% ============================================================

%% run_action(Binary, Args, SuccessFun)
%%   Calls ./bin/<Binary> with shell-quoted args.
%%   Parses "OK|f1|f2|..." or "ERR|CODE|msg" from stdout.
%%   SuccessFun receives list of fields after "OK".
run_action(Binary, Args, SuccessFun) ->
    Bin  = ?BIN_DIR ++ "/" ++ Binary,
    Argv = string:join([shell_quote(A) || A <- Args], " "),
    Cmd  = Bin ++ " " ++ Argv ++ " 2>&1",
    Raw  = string:strip(os:cmd(Cmd), both, $\n),
    parse_cobol_output(Raw, SuccessFun).

parse_cobol_output(Raw, SuccessFun) ->
    Parts = string:tokens(Raw, "|"),
    case Parts of
        ["OK" | Fields] ->
            SuccessFun(Fields);
        ["ERR", Code, Msg | _] ->
            json_error(Code, Msg);
        _ ->
            json_error("INTERNAL", "Unexpected output: " ++ Raw)
    end.

%%% ============================================================
%%% JSON helpers  (minimal hand-rolled, no deps)
%%% ============================================================

json_ok(Fields) ->
    Pairs = [{"status", "ok"} | Fields],
    Body = json_object(Pairs),
    http_response(200, Body).

json_error(Code, Msg) ->
    Body = json_object([{"status", "error"},
                        {"code",   Code},
                        {"message", Msg}]),
    http_response(400, Body).

json_object(Pairs) ->
    Inner = string:join(
        [json_pair(K, V) || {K, V} <- Pairs],
        ", "),
    "{" ++ Inner ++ "}".

json_pair(K, V) ->
    "\"" ++ K ++ "\": \"" ++ json_escape(V) ++ "\"".

json_escape(S) ->
    S1 = re:replace(S, "\\\\", "\\\\\\\\", [global, {return, list}]),
    S2 = re:replace(S1, "\"", "\\\\\"", [global, {return, list}]),
    S2.

%%% ============================================================
%%% HTTP response
%%% ============================================================

http_response(Status, Body) ->
    StatusLine = case Status of
        200 -> "200 OK";
        400 -> "400 Bad Request";
        404 -> "404 Not Found";
        _   -> integer_to_list(Status) ++ " Unknown"
    end,
    iolist_to_binary([
        "HTTP/1.1 ", StatusLine, "\r\n",
        "Content-Type: application/json\r\n",
        "Content-Length: ", integer_to_list(length(Body)), "\r\n",
        "Connection: close\r\n",
        "\r\n",
        Body
    ]).

http_response_binary(ContentType, Body) when is_binary(Body) ->
    iolist_to_binary([
        "HTTP/1.1 200 OK\r\n",
        "Content-Type: ", ContentType, "\r\n",
        "Content-Length: ", integer_to_list(byte_size(Body)), "\r\n",
        "Connection: close\r\n",
        "\r\n",
        Body
    ]).

send_response(Sock, Response) ->
    gen_tcp:send(Sock, Response).

%%% ============================================================
%%% QR code helpers
%%% ============================================================

%% Build the payment URI encoded into the QR code.
build_payment_uri(Account, Currency, Decimals, Amount) ->
    Base = "twallet://pay?to=" ++ Account
        ++ "&currency=" ++ Currency
        ++ "&decimals=" ++ Decimals,
    case Amount of
        "" -> Base;
        _  -> Base ++ "&amount=" ++ Amount
    end.

%% Run qrencode and return raw PNG bytes.
run_qrencode(Uri) ->
    Cmd = "qrencode -o - -t PNG -s 6 -m 2 " ++ shell_quote(Uri),
    Port = open_port({spawn, Cmd}, [binary, eof, stderr_to_stdout]),
    collect_port(Port, <<>>).

collect_port(Port, Acc) ->
    receive
        {Port, {data, Data}} ->
            collect_port(Port, <<Acc/binary, Data/binary>>);
        {Port, eof} ->
            port_close(Port),
            case Acc of
                <<>> -> {error, "qrencode produced no output"};
                _    -> {ok, Acc}
            end
    after 5000 ->
        port_close(Port),
        {error, "qrencode timed out"}
    end.

%% Split "segment?key=val" into {"segment", "key=val"}.
split_path_qs(Segment) ->
    case string:split(Segment, "?") of
        [Path, QS] -> {Path, QS};
        [Path]     -> {Path, ""}
    end.

%% Parse "key=val&key2=val2" into [{key, val}].
parse_query_string("") -> [];
parse_query_string(QS) ->
    Pairs = string:tokens(QS, "&"),
    lists:filtermap(fun(Pair) ->
        case string:split(Pair, "=") of
            [K, V] -> {true, {K, V}};
            _      -> false
        end
    end, Pairs).

%% HTML page for /qr/:account
qr_html_page(Account, Currency, _Decimals, Formatted) ->
    ApiBase = "/api/wallet/" ++ Account ++ "/qr",
    "<!DOCTYPE html>"
    "<html lang=\"en\">"
    "<head>"
      "<meta charset=\"utf-8\">"
      "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1\">"
      "<title>T-Wallet &mdash; Pay " ++ Account ++ "</title>"
      "<style>"
        "body{font-family:system-ui,sans-serif;background:#0f0f0f;color:#f0f0f0;"
          "display:flex;flex-direction:column;align-items:center;"
          "justify-content:center;min-height:100vh;margin:0;padding:1rem;box-sizing:border-box}"
        "h1{font-size:1.4rem;margin:0 0 .25rem}"
        "p.sub{color:#888;margin:0 0 1.5rem;font-size:.9rem}"
        ".card{background:#1a1a1a;border-radius:1rem;padding:1.5rem 2rem;"
          "box-shadow:0 4px 24px #0008;max-width:340px;width:100%;text-align:center}"
        ".info{margin-bottom:1rem;font-size:.95rem;color:#ccc}"
        ".info strong{color:#fff}"
        "label{display:block;font-size:.85rem;color:#888;margin-bottom:.35rem;text-align:left}"
        "input[type=number]{width:100%;box-sizing:border-box;padding:.6rem .8rem;"
          "border-radius:.5rem;border:1px solid #333;background:#111;color:#fff;"
          "font-size:1rem;margin-bottom:1.2rem}"
        "#qr-wrapper{background:#fff;border-radius:.75rem;padding:.75rem;display:inline-block}"
        "#qr-wrapper img{display:block;width:220px;height:220px}"
        ".hint{margin-top:1rem;font-size:.8rem;color:#666}"
        ".currency{color:#4af;font-weight:bold}"
      "</style>"
    "</head>"
    "<body>"
      "<div class=\"card\">"
        "<h1>T-Wallet</h1>"
        "<p class=\"sub\">Payment QR Code</p>"
        "<div class=\"info\">"
          "Account: <strong>" ++ Account ++ "</strong><br>"
          "Balance: <strong><span class=\"currency\">" ++ Formatted ++ " " ++ Currency ++ "</span></strong>"
        "</div>"
        "<label for=\"amt\">Amount (optional)</label>"
        "<input type=\"number\" id=\"amt\" min=\"0\" step=\"0.01\""
          " placeholder=\"Leave blank for any amount\""
          " oninput=\"updateQr()\">"
        "<div id=\"qr-wrapper\">"
          "<img id=\"qr\" src=\"" ++ ApiBase ++ "\" alt=\"QR code\">"
        "</div>"
        "<p class=\"hint\">Scan with your phone to pay</p>"
      "</div>"
      "<script>"
        "function updateQr(){"
          "var amt=document.getElementById('amt').value;"
          "var base='" ++ ApiBase ++ "';"
          "document.getElementById('qr').src=amt?base+'?amount='+encodeURIComponent(amt):base;"
        "}"
      "</script>"
    "</body>"
    "</html>".

%%% ============================================================
%%% Minimal JSON parser  (key-value strings only)
%%% ============================================================

%% Parses {"key": "value", ...} → [{key, value}]
%% Handles simple string values only (sufficient for this API).
parse_json(Body) ->
    %% Strip outer braces.
    Stripped = re:replace(Body, "^\\s*\\{|\\}\\s*$", "",
                          [global, {return, list}]),
    %% Split on comma (naive — works for non-nested values).
    Pairs = re:split(Stripped, ",(?=\\s*\")", [{return, list}]),
    lists:filtermap(fun(Pair) ->
        case re:run(Pair,
            "\"([^\"]+)\"\\s*:\\s*\"([^\"]*)\"",
            [{capture, all_but_first, list}]) of
            {match, [K, V]} -> {true, {K, V}};
            _               -> false
        end
    end, Pairs).

get_field(Key, Fields) ->
    case lists:keyfind(Key, 1, Fields) of
        {_, V} -> V;
        false  -> ""
    end.

get_field_default(Key, Fields, Default) ->
    case lists:keyfind(Key, 1, Fields) of
        {_, V} when V =/= "" -> V;
        _                    -> Default
    end.

%%% ============================================================
%%% Shell quoting (single-quote wrap, escape internal quotes)
%%% ============================================================

shell_quote(S) ->
    Escaped = re:replace(S, "'", "'\\\\''", [global, {return, list}]),
    "'" ++ Escaped ++ "'".
