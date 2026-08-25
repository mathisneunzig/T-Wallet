# wallet-deposit tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run
# Note: wallet-deposit now writes a timestamp to transactions.dat (YYYY-MM-DD HH:MM:SS).

test_wallet_deposit() {
    echo "── wallet-deposit ────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # Initial balance = 1000 raw (€10.00). Deposit 5 whole, 50 frac → 550 raw added → 1550 total
    local out
    out="$(run "$T" wallet-deposit 10000001 5 50)"
    assert_prefix "deposit OK" "OK|10000001|" "$out"

    # Balance should now be 1550
    local bal
    bal="$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"
    assert_eq "balance after deposit" "000000000000001550" "$bal"

    # Transaction should be recorded with a timestamp
    local txn
    txn="$(cat "$T/data/transactions.dat")"
    [[ "$txn" == *"DEPOSIT"* ]] && \
        { echo "  PASS: transaction recorded"; (( PASS++ )) || true; } || \
        { echo "  FAIL: transaction recorded"; (( FAIL++ )) || true; ERRORS+=("transaction recorded"); }

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" wallet-deposit 99999999 5 0)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" wallet-deposit)"

    rm -rf "$T"
}
