# auth-login tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_auth_login() {
    echo "── auth-login ────────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_eq "correct PIN" "OK|10000001" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_prefix "wrong PIN" "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 9999)"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" auth-login 99999999 1234)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" auth-login)"

    # Suspend the account then try to login
    (cd "$T" && "$BIN/admin-suspend-account" 10000001 > /dev/null)
    assert_prefix "suspended" "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 1234)"

    rm -rf "$T"
}
