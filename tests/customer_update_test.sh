# customer-update tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_customer_update() {
    echo "── customer-update ───────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" customer-update 10000001 phone '+49987654321')"
    assert_prefix "update phone OK" "OK|10000001|" "$out"

    # Verify change persisted via customer-get
    local get
    get="$(run "$T" customer-get 10000001)"
    [[ "$get" == *"+49987654321"* ]] && \
        { echo "  PASS: phone change persisted"; (( PASS++ )) || true; } || \
        { echo "  FAIL: phone change persisted"; (( FAIL++ )) || true; ERRORS+=("phone change persisted"); }

    assert_prefix "update address OK" "OK|10000001|" \
        "$(run "$T" customer-update 10000001 address 'New Street 5')"

    assert_prefix "invalid field" "ERR|INVALID_FIELD" \
        "$(run "$T" customer-update 10000001 badfield value)"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" customer-update 99999999 phone 12345)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" customer-update)"

    rm -rf "$T"
}
