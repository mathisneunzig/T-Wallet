# admin-suspend-account tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_admin_suspend_account() {
    echo "── admin-suspend-account ─────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_prefix "suspend existing" "OK|10000001" \
        "$(run "$T" admin-suspend-account 10000001)"

    assert_prefix "login after suspend" "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" admin-suspend-account 99999999)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" admin-suspend-account)"

    rm -rf "$T"
}
