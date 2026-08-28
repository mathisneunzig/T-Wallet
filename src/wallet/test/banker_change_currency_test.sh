# banker-change-currency tests — sourced by run_tests.sh

test_banker_change_currency() {
    echo "── banker-change-currency ────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── basic currency change ─────────────────────────────────────────────────
    local out
    out="$(run "$T" banker-change-currency 10000001 USD 0)"
    assert_prefix "change currency → OK" "OK|10000001|USD|" "$out"
    assert_eq "response currency field is USD" \
        "USD" "$(echo "$out" | cut -d'|' -f3 | tr -d ' ')"
    assert_eq "response decimals field is 0" \
        "0" "$(echo "$out" | cut -d'|' -f4 | tr -d ' ')"

    # ── change is reflected in wallet-balance ─────────────────────────────────
    local bal
    bal="$(run "$T" wallet-balance 10000001)"
    assert_eq "wallet-balance shows new currency" \
        "USD" "$(echo "$bal" | cut -d'|' -f3)"
    assert_eq "wallet-balance shows new decimals" \
        "0" "$(echo "$bal" | cut -d'|' -f4)"
    # Raw balance is preserved through the currency change
    assert_eq "raw balance preserved after currency change" \
        "000000000000001000" \
        "$(echo "$bal" | cut -d'|' -f5)"

    # ── change to different currencies/decimals ───────────────────────────────
    run "$T" banker-change-currency 10000001 GBP 2 > /dev/null
    local gbp
    gbp="$(run "$T" wallet-balance 10000001)"
    assert_eq "currency changed to GBP" "GBP" "$(echo "$gbp" | cut -d'|' -f3)"
    assert_eq "decimals changed to 2" "2" "$(echo "$gbp" | cut -d'|' -f4)"

    run "$T" banker-change-currency 10000001 JPY 0 > /dev/null
    local jpy
    jpy="$(run "$T" wallet-balance 10000001)"
    assert_eq "currency changed to JPY" "JPY" "$(echo "$jpy" | cut -d'|' -f3)"
    assert_eq "decimals 0 for JPY" "0" "$(echo "$jpy" | cut -d'|' -f4)"

    # ── change back to original ───────────────────────────────────────────────
    run "$T" banker-change-currency 10000001 EUR 2 > /dev/null
    assert_eq "currency restored to EUR" \
        "EUR" "$(run "$T" wallet-balance 10000001 | cut -d'|' -f3)"

    # ── deposit after currency change uses new multiplier ────────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"
    # Change to 0-decimal currency, then deposit 5 whole
    run "$T2" banker-change-currency 10000001 USD 0 > /dev/null
    run "$T2" wallet-deposit 10000001 5 0 > /dev/null
    # With 0 decimals, multiplier=1, so 5 whole = +5 raw. 1000+5=1005
    assert_eq "deposit after currency change (0 decimals) uses multiplier 1" \
        "000000000000001005" \
        "$(run "$T2" wallet-balance 10000001 | cut -d'|' -f5)"
    rm -rf "$T2"

    # ── currency change on one account does not affect another ────────────────
    local T3
    T3=$(mktemp -d)
    setup_fixture "$T3"
    run "$T3" admin-create-account \
        20000001 5678 EUR 2 \
        Jane Doe '+49000000000' 'jane@example.com' \
        'Street 1' '10000' 'Berlin' 'Germany' > /dev/null
    run "$T3" banker-change-currency 10000001 USD 0 > /dev/null
    assert_eq "second account currency unaffected" \
        "EUR" "$(run "$T3" wallet-balance 20000001 | cut -d'|' -f3)"
    rm -rf "$T3"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" banker-change-currency 99999999 USD 0)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" banker-change-currency)"

    assert_prefix "account only → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" banker-change-currency 10000001)"

    rm -rf "$T"
}
