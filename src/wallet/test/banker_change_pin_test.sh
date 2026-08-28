# banker-change-pin tests — sourced by run_tests.sh

test_banker_change_pin() {
    echo "── banker-change-pin ─────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── basic PIN change ──────────────────────────────────────────────────────
    assert_prefix "change PIN → OK" "OK|10000001" \
        "$(run "$T" banker-change-pin 10000001 9999)"

    assert_prefix "old PIN rejected immediately after change" \
        "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_eq "new PIN accepted immediately after change" \
        "OK|10000001" \
        "$(run "$T" auth-login 10000001 9999)"

    # ── old PIN remains rejected after login with new PIN ────────────────────
    run "$T" auth-login 10000001 9999 > /dev/null
    assert_prefix "old PIN still rejected after successful new-PIN login" \
        "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 1234)"

    # ── change PIN again (chain of changes) ───────────────────────────────────
    run "$T" banker-change-pin 10000001 1111 > /dev/null
    assert_prefix "intermediate PIN rejected after second change" \
        "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 9999)"
    assert_eq "latest PIN accepted after second change" \
        "OK|10000001" \
        "$(run "$T" auth-login 10000001 1111)"

    # ── change PIN back to original ───────────────────────────────────────────
    run "$T" banker-change-pin 10000001 1234 > /dev/null
    assert_eq "PIN changed back to original works" \
        "OK|10000001" \
        "$(run "$T" auth-login 10000001 1234)"

    # ── PIN change on one account does not affect another ────────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"
    run "$T2" admin-create-account \
        20000001 5678 EUR 2 \
        Jane Doe '+49000000000' 'jane@example.com' \
        'Street 1' '10000' 'Berlin' 'Germany' > /dev/null

    run "$T2" banker-change-pin 10000001 0000 > /dev/null

    assert_eq "second account PIN unaffected by first account PIN change" \
        "OK|20000001" \
        "$(run "$T2" auth-login 20000001 5678)"

    rm -rf "$T2"

    # ── PIN change on suspended account ──────────────────────────────────────
    local T3
    T3=$(mktemp -d)
    setup_fixture "$T3"
    run "$T3" admin-suspend-account 10000001 > /dev/null
    assert_prefix "changing PIN on suspended account → OK (banker operation)" \
        "OK|10000001" \
        "$(run "$T3" banker-change-pin 10000001 4321)"
    # Account still suspended after PIN change
    assert_prefix "account still suspended after PIN change" \
        "ERR|SUSPENDED" \
        "$(run "$T3" auth-login 10000001 4321)"
    rm -rf "$T3"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" banker-change-pin 99999999 1234)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" banker-change-pin)"

    assert_prefix "account only → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" banker-change-pin 10000001)"

    rm -rf "$T"
}
