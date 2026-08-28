# auth-login tests — sourced by run_tests.sh

test_auth_login() {
    echo "── auth-login ────────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── correct credentials ──────────────────────────────────────────────────
    assert_eq "correct PIN → OK with account number" \
        "OK|10000001" \
        "$(run "$T" auth-login 10000001 1234)"

    # ── wrong PIN variations ─────────────────────────────────────────────────
    assert_prefix "wrong PIN (9999) → INVALID_PIN" \
        "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 9999)"

    assert_prefix "PIN off by one (1235) → INVALID_PIN" \
        "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 1235)"

    assert_prefix "PIN off by one (1233) → INVALID_PIN" \
        "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 1233)"

    assert_prefix "all-zeros PIN → INVALID_PIN" \
        "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 0000)"

    # ── wrong PIN does NOT lock the account (can still log in) ───────────────
    assert_eq "account still works after wrong PIN attempt" \
        "OK|10000001" \
        "$(run "$T" auth-login 10000001 1234)"

    # ── account not found ────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" auth-login 99999999 1234)"

    assert_prefix "account 00000000 → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" auth-login 00000000 1234)"

    # ── usage / missing args ─────────────────────────────────────────────────
    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" auth-login)"

    assert_prefix "account only, no PIN → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" auth-login 10000001)"

    # ── suspend then login ───────────────────────────────────────────────────
    run "$T" admin-suspend-account 10000001 > /dev/null

    assert_prefix "correct PIN on suspended account → SUSPENDED" \
        "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_prefix "wrong PIN on suspended account → still SUSPENDED, not INVALID_PIN" \
        "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 9999)"

    # ── PIN change then login ────────────────────────────────────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"

    run "$T2" banker-change-pin 10000001 5678 > /dev/null

    assert_prefix "old PIN rejected after change" \
        "ERR|INVALID_PIN" \
        "$(run "$T2" auth-login 10000001 1234)"

    assert_eq "new PIN accepted after change" \
        "OK|10000001" \
        "$(run "$T2" auth-login 10000001 5678)"

    assert_prefix "original PIN still rejected after re-login" \
        "ERR|INVALID_PIN" \
        "$(run "$T2" auth-login 10000001 1234)"

    rm -rf "$T" "$T2"
}
