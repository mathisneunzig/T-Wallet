# banker-change-pin tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_banker_change_pin() {
    echo "── banker-change-pin ─────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_prefix "change pin OK" "OK|10000001" \
        "$(run "$T" banker-change-pin 10000001 9999)"

    assert_prefix "old PIN rejected" "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_eq "new PIN accepted" "OK|10000001" \
        "$(run "$T" auth-login 10000001 9999)"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" banker-change-pin 99999999 1234)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" banker-change-pin)"

    rm -rf "$T"
}
