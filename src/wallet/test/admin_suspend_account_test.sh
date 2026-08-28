# admin-suspend-account tests — sourced by run_tests.sh

test_admin_suspend_account() {
    echo "── admin-suspend-account ─────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── pre-condition: login works before suspend ─────────────────────────────
    assert_eq "account active before suspend" \
        "OK|10000001" \
        "$(run "$T" auth-login 10000001 1234)"

    # ── suspend ───────────────────────────────────────────────────────────────
    assert_prefix "suspend existing account → OK" "OK|10000001" \
        "$(run "$T" admin-suspend-account 10000001)"

    # ── login blocked after suspend ───────────────────────────────────────────
    assert_prefix "correct PIN on suspended account → SUSPENDED" \
        "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_prefix "wrong PIN on suspended account → SUSPENDED (not INVALID_PIN)" \
        "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 9999)"

    # ── wallet operations still function after suspend ────────────────────────
    # (suspend only blocks login, not admin operations)
    assert_prefix "wallet-balance still accessible after suspend" \
        "OK|10000001|" \
        "$(run "$T" wallet-balance 10000001)"

    # ── suspend status persists across re-calls ───────────────────────────────
    run "$T" admin-suspend-account 10000001 > /dev/null
    assert_prefix "re-suspending already-suspended account succeeds" \
        "OK|10000001" \
        "$(run "$T" admin-suspend-account 10000001)"

    assert_prefix "account still suspended after re-suspend" \
        "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 1234)"

    # ── suspending one account does not affect another ────────────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"
    run "$T2" admin-create-account \
        20000001 5678 EUR 2 \
        Jane Doe '+49000000000' 'jane@example.com' \
        'Street 1' '10000' 'Berlin' 'Germany' > /dev/null

    run "$T2" admin-suspend-account 10000001 > /dev/null

    assert_eq "second account unaffected by first account suspension" \
        "OK|20000001" \
        "$(run "$T2" auth-login 20000001 5678)"

    rm -rf "$T2"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" admin-suspend-account 99999999)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" admin-suspend-account)"

    rm -rf "$T"
}
