# customer-get tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_customer_get() {
    echo "── customer-get ──────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" customer-get 10000001)"
    assert_prefix "existing account" "OK|10000001|" "$out"
    assert_prefix "contains fname"   "OK|10000001|Erika" "$out"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" customer-get 99999999)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" customer-get)"

    rm -rf "$T"
}
