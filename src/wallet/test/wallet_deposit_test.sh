# wallet-deposit tests — sourced by run_tests.sh

test_wallet_deposit() {
    echo "── wallet-deposit ────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── basic whole-unit deposit ──────────────────────────────────────────────
    # Initial balance = 1000 raw (€10.00). Deposit 5 whole → +500 raw → 1500 total
    local out
    out="$(run "$T" wallet-deposit 10000001 5 0)"
    assert_prefix "whole deposit → OK" "OK|10000001|" "$out"
    assert_eq "raw balance after deposit 5 whole" \
        "000000000000001500" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── fractional deposit ────────────────────────────────────────────────────
    # Deposit 0 whole, 50 frac → +50 raw → 1550 total
    run "$T" wallet-deposit 10000001 0 50 > /dev/null
    assert_eq "balance after fractional deposit (0 whole, 50 frac)" \
        "000000000000001550" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── combined whole + fractional ───────────────────────────────────────────
    # Deposit 3 whole, 25 frac → +325 raw → 1875 total
    run "$T" wallet-deposit 10000001 3 25 > /dev/null
    assert_eq "balance after combined deposit (3 whole, 25 frac)" \
        "000000000000001875" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── deposit zero ─────────────────────────────────────────────────────────
    out="$(run "$T" wallet-deposit 10000001 0 0)"
    assert_prefix "deposit zero → OK (no error)" "OK|10000001|" "$out"
    assert_eq "balance unchanged after zero deposit" \
        "000000000000001875" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── large deposit ─────────────────────────────────────────────────────────
    run "$T" wallet-deposit 10000001 1000 0 > /dev/null
    assert_eq "balance after large deposit (1000 whole)" \
        "000000000000101875" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── return fields ─────────────────────────────────────────────────────────
    out="$(run "$T" wallet-deposit 10000001 1 0)"
    assert_eq "deposit response account field" \
        "10000001" "$(echo "$out" | cut -d'|' -f2)"
    # raw balance field should be numeric
    local raw
    raw="$(echo "$out" | cut -d'|' -f3)"
    [[ "$raw" =~ ^[0-9]+$ ]] && \
        { echo "  PASS: deposit response raw balance is numeric (got: $raw)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: deposit response raw balance not numeric (got: $raw)"; (( FAIL++ )) || true; ERRORS+=("deposit raw balance numeric"); }

    # ── transaction recorded ──────────────────────────────────────────────────
    local txn_count
    txn_count="$(grep -c 'DEPOSIT' "$T/data/transactions.dat" || true)"
    [[ "$txn_count" -ge 1 ]] && \
        { echo "  PASS: DEPOSIT transactions recorded ($txn_count entries)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: no DEPOSIT in transactions.dat"; (( FAIL++ )) || true; ERRORS+=("DEPOSIT transactions recorded"); }

    # ── multiple deposits accumulate correctly ────────────────────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"
    run "$T2" wallet-deposit 10000001 1 0 > /dev/null
    run "$T2" wallet-deposit 10000001 1 0 > /dev/null
    run "$T2" wallet-deposit 10000001 1 0 > /dev/null
    assert_eq "three deposits of 1 each accumulate to 1300 (start 1000)" \
        "000000000000001300" \
        "$(run "$T2" wallet-balance 10000001 | cut -d'|' -f5)"
    rm -rf "$T2"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" wallet-deposit 99999999 5 0)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-deposit)"

    assert_prefix "account only → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-deposit 10000001)"

    rm -rf "$T"
}
