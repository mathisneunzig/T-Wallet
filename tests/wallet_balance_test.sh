# wallet-balance tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_wallet_balance() {
    echo "── wallet-balance ────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" wallet-balance 10000001)"
    assert_prefix "existing account starts with OK" "OK|10000001|EUR|2|" "$out"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" wallet-balance 99999999)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" wallet-balance)"

    rm -rf "$T"
}
