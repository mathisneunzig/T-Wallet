# stats-query tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_stats_query() {
    echo "── stats-query ───────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # Empty transactions file → OK with no TXN lines
    local out
    out="$(run "$T" stats-query)"
    assert_eq "empty transactions first line" "OK" "$(echo "$out" | head -1)"

    # Deposit some money, then check stats-query records it
    run "$T" wallet-deposit 10000001 5 0 > /dev/null
    out="$(run "$T" stats-query)"
    assert_eq "ok after deposit" "OK" "$(echo "$out" | head -1)"
    [[ "$out" == *"DEPOSIT"* ]] && \
        { echo "  PASS: DEPOSIT line present"; (( PASS++ )) || true; } || \
        { echo "  FAIL: DEPOSIT line present"; (( FAIL++ )) || true; ERRORS+=("DEPOSIT line present"); }
    [[ "$out" == *"10000001"* ]] && \
        { echo "  PASS: account in stats output"; (( PASS++ )) || true; } || \
        { echo "  FAIL: account in stats output"; (( FAIL++ )) || true; ERRORS+=("account in stats output"); }

    # Withdraw, then check both transaction types are present
    run "$T" wallet-withdraw 10000001 2 0 > /dev/null
    out="$(run "$T" stats-query)"
    [[ "$out" == *"WITHDRAW"* ]] && \
        { echo "  PASS: WITHDRAW line present"; (( PASS++ )) || true; } || \
        { echo "  FAIL: WITHDRAW line present"; (( FAIL++ )) || true; ERRORS+=("WITHDRAW line present"); }

    # TXN lines should have 7 pipe-separated fields: TXN|acct|type|currency|decimals|amount|timestamp
    local txn_line
    txn_line="$(echo "$out" | grep '^TXN|' | head -1)"
    local field_count
    field_count="$(echo "$txn_line" | tr -cd '|' | wc -c | tr -d ' ')"
    assert_eq "TXN line has 6 pipes (7 fields)" "6" "$field_count"

    # Timestamp field should look like YYYY-MM-DD HH:MM:SS
    local timestamp
    timestamp="$(echo "$txn_line" | cut -d'|' -f7)"
    [[ "$timestamp" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}\ [0-9]{2}:[0-9]{2}:[0-9]{2}$ ]] && \
        { echo "  PASS: timestamp format valid"; (( PASS++ )) || true; } || \
        { echo "  FAIL: timestamp format valid (got: '$timestamp')"; (( FAIL++ )) || true; ERRORS+=("timestamp format valid"); }

    rm -rf "$T"
}
