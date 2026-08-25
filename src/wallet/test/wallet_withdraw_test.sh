# wallet-withdraw tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run
# Note: wallet-withdraw now writes a timestamp to transactions.dat (YYYY-MM-DD HH:MM:SS).

test_wallet_withdraw() {
    echo "── wallet-withdraw ───────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # Initial balance = 1000 raw. Withdraw 3 whole, 0 frac → 300 raw → 700 left
    local out
    out="$(run "$T" wallet-withdraw 10000001 3 0)"
    assert_prefix "withdraw OK" "OK|10000001|" "$out"

    local bal
    bal="$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"
    assert_eq "balance after withdraw" "000000000000000700" "$bal"

    # Transaction should be recorded with a timestamp
    local txn
    txn="$(cat "$T/data/transactions.dat")"
    [[ "$txn" == *"WITHDRAW"* ]] && \
        { echo "  PASS: transaction recorded"; (( PASS++ )) || true; } || \
        { echo "  FAIL: transaction recorded"; (( FAIL++ )) || true; ERRORS+=("transaction recorded"); }

    # Overdraw: try to withdraw 100 (10000 raw) from remaining 700
    assert_prefix "insufficient" "ERR|INSUFFICIENT" \
        "$(run "$T" wallet-withdraw 10000001 100 0)"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" wallet-withdraw 99999999 1 0)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" wallet-withdraw)"

    rm -rf "$T"
}
