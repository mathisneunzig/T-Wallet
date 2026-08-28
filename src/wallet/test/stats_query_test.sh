# stats-query tests — sourced by run_tests.sh

test_stats_query() {
    echo "── stats-query ───────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── empty file → OK with no TXN lines ────────────────────────────────────
    local out
    out="$(run "$T" stats-query)"
    assert_eq "empty transactions.dat → first line is OK" \
        "OK" "$(echo "$out" | head -1)"

    local line_count
    line_count="$(echo "$out" | wc -l | tr -d ' ')"
    assert_eq "empty transactions.dat → only one line (the OK)" \
        "1" "$line_count"

    # ── after a deposit ───────────────────────────────────────────────────────
    run "$T" wallet-deposit 10000001 5 0 > /dev/null
    out="$(run "$T" stats-query)"
    assert_eq "first line still OK after deposit" "OK" "$(echo "$out" | head -1)"

    local txn_count
    txn_count="$(echo "$out" | grep -c '^TXN|' || true)"
    assert_eq "one TXN line after one deposit" "1" "$txn_count"

    # ── TXN line field structure ──────────────────────────────────────────────
    local txn_line
    txn_line="$(echo "$out" | grep '^TXN|' | head -1)"
    local pipe_count
    pipe_count="$(echo "$txn_line" | tr -cd '|' | wc -c | tr -d ' ')"
    assert_eq "TXN line has 6 pipes (7 fields)" "6" "$pipe_count"

    # Field by field
    assert_eq "TXN field 1 is literal TXN" \
        "TXN" "$(echo "$txn_line" | cut -d'|' -f1)"
    assert_eq "TXN account field matches fixture" \
        "10000001" "$(echo "$txn_line" | cut -d'|' -f2 | tr -d ' ')"

    local txn_type
    txn_type="$(echo "$txn_line" | cut -d'|' -f3 | tr -d ' ')"
    assert_eq "TXN type field is DEPOSIT" "DEPOSIT" "$txn_type"

    assert_eq "TXN currency field is EUR" \
        "EUR" "$(echo "$txn_line" | cut -d'|' -f4 | tr -d ' ')"
    assert_eq "TXN decimals field is 2" \
        "2" "$(echo "$txn_line" | cut -d'|' -f5 | tr -d ' ')"

    local amount
    amount="$(echo "$txn_line" | cut -d'|' -f6 | tr -d ' ')"
    [[ "$amount" =~ ^[0-9]+$ ]] && \
        { echo "  PASS: TXN amount field is numeric (got: $amount)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: TXN amount field is not numeric (got: $amount)"; (( FAIL++ )) || true; ERRORS+=("TXN amount numeric"); }

    # Timestamp: YYYY-MM-DD HH:MM:SS
    local ts
    ts="$(echo "$txn_line" | cut -d'|' -f7)"
    [[ "$ts" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] && \
        { echo "  PASS: TXN timestamp is YYYY-MM-DD HH:MM:SS (got: $ts)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: TXN timestamp format wrong (got: '$ts')"; (( FAIL++ )) || true; ERRORS+=("TXN timestamp format"); }

    # ── after a withdraw ──────────────────────────────────────────────────────
    run "$T" wallet-withdraw 10000001 2 0 > /dev/null
    out="$(run "$T" stats-query)"
    txn_count="$(echo "$out" | grep -c '^TXN|' || true)"
    assert_eq "two TXN lines after deposit + withdraw" "2" "$txn_count"

    local has_withdraw
    has_withdraw="$(echo "$out" | grep '^TXN|' | grep -c 'WITHDRAW' || true)"
    assert_eq "one of the TXN lines is a WITHDRAW" "1" "$has_withdraw"

    local has_deposit
    has_deposit="$(echo "$out" | grep '^TXN|' | grep -c 'DEPOSIT' || true)"
    assert_eq "one of the TXN lines is a DEPOSIT" "1" "$has_deposit"

    # ── multiple deposits accumulate as separate TXN lines ───────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"
    run "$T2" wallet-deposit 10000001 1 0 > /dev/null
    run "$T2" wallet-deposit 10000001 2 0 > /dev/null
    run "$T2" wallet-deposit 10000001 3 0 > /dev/null
    out="$(run "$T2" stats-query)"
    txn_count="$(echo "$out" | grep -c '^TXN|' || true)"
    assert_eq "three deposits produce three TXN lines" "3" "$txn_count"
    rm -rf "$T2"

    # ── failed operations are NOT recorded ───────────────────────────────────
    local T3
    T3=$(mktemp -d)
    setup_fixture "$T3"
    run "$T3" wallet-withdraw 10000001 9999 0 > /dev/null || true   # overdraw
    run "$T3" wallet-deposit  99999999 5 0   > /dev/null || true   # bad account
    out="$(run "$T3" stats-query)"
    txn_count="$(echo "$out" | grep -c '^TXN|' || true)"
    assert_eq "failed operations produce no TXN lines" "0" "$txn_count"
    rm -rf "$T3"

    rm -rf "$T"
}
