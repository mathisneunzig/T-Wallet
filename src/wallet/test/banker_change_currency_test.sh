# banker-change-currency tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_banker_change_currency() {
    echo "── banker-change-currency ────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" banker-change-currency 10000001 USD 0)"
    assert_prefix "change currency OK" "OK|10000001|USD|" "$out"

    local bal_out
    bal_out="$(run "$T" wallet-balance 10000001)"
    assert_prefix "balance shows USD" "OK|10000001|USD|0|" "$bal_out"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" banker-change-currency 99999999 USD 0)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" banker-change-currency)"

    rm -rf "$T"
}
