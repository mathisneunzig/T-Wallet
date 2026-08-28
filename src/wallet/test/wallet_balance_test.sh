# wallet-balance tests — sourced by run_tests.sh

test_wallet_balance() {
    echo "── wallet-balance ────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── field structure ───────────────────────────────────────────────────────
    local out
    out="$(run "$T" wallet-balance 10000001)"
    assert_prefix "OK prefix with account" \
        "OK|10000001|EUR|2|" "$out"

    # Extract and verify each field individually
    assert_eq "currency field is EUR" \
        "EUR" "$(echo "$out" | cut -d'|' -f3)"

    assert_eq "decimals field is 2" \
        "2" "$(echo "$out" | cut -d'|' -f4)"

    assert_eq "initial raw balance is 1000" \
        "000000000000001000" "$(echo "$out" | cut -d'|' -f5)"

    # Formatted field should be non-empty
    local fmt
    fmt="$(echo "$out" | cut -d'|' -f6 | tr -d ' ')"
    [[ -n "$fmt" ]] && \
        { echo "  PASS: formatted balance is non-empty (got: $fmt)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: formatted balance is empty"; (( FAIL++ )) || true; ERRORS+=("formatted balance non-empty"); }

    # ── balance reflects deposit ──────────────────────────────────────────────
    run "$T" wallet-deposit 10000001 5 0 > /dev/null
    assert_eq "balance increases after deposit" \
        "000000000000001500" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── balance reflects withdraw ─────────────────────────────────────────────
    run "$T" wallet-withdraw 10000001 2 0 > /dev/null
    assert_eq "balance decreases after withdraw" \
        "000000000000001300" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── balance reflects fractional deposit (0.50 EUR = 50 raw) ──────────────
    run "$T" wallet-deposit 10000001 0 50 > /dev/null
    assert_eq "balance increases by fraction" \
        "000000000000001350" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── currency change is reflected ──────────────────────────────────────────
    run "$T" banker-change-currency 10000001 USD 0 > /dev/null
    local usd_out
    usd_out="$(run "$T" wallet-balance 10000001)"
    assert_eq "currency updates to USD" \
        "USD" "$(echo "$usd_out" | cut -d'|' -f3)"
    assert_eq "decimals updates to 0" \
        "0" "$(echo "$usd_out" | cut -d'|' -f4)"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" wallet-balance 99999999)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-balance)"

    rm -rf "$T"
}
