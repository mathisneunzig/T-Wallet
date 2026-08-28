# wallet-withdraw tests — sourced by run_tests.sh

test_wallet_withdraw() {
    echo "── wallet-withdraw ───────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── basic whole-unit withdraw ─────────────────────────────────────────────
    # Initial balance = 1000 raw (€10.00). Withdraw 3 whole → -300 raw → 700 left
    local out
    out="$(run "$T" wallet-withdraw 10000001 3 0)"
    assert_prefix "whole withdraw → OK" "OK|10000001|" "$out"
    assert_eq "balance after withdraw 3 whole" \
        "000000000000000700" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── fractional withdraw ───────────────────────────────────────────────────
    # Withdraw 0 whole, 50 frac → -50 raw → 650 left
    run "$T" wallet-withdraw 10000001 0 50 > /dev/null
    assert_eq "balance after fractional withdraw (0 whole, 50 frac)" \
        "000000000000000650" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── combined whole + fractional ───────────────────────────────────────────
    # Withdraw 1 whole, 25 frac → -125 raw → 525 left
    run "$T" wallet-withdraw 10000001 1 25 > /dev/null
    assert_eq "balance after combined withdraw (1 whole, 25 frac)" \
        "000000000000000525" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── withdraw zero ─────────────────────────────────────────────────────────
    out="$(run "$T" wallet-withdraw 10000001 0 0)"
    assert_prefix "withdraw zero → OK" "OK|10000001|" "$out"
    assert_eq "balance unchanged after zero withdraw" \
        "000000000000000525" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── withdraw exact balance (goes to 0) ────────────────────────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"
    # Balance = 1000 raw. Withdraw exactly 10 whole, 0 frac → 0 left
    run "$T2" wallet-withdraw 10000001 10 0 > /dev/null
    assert_eq "balance is zero after withdrawing entire balance" \
        "000000000000000000" \
        "$(run "$T2" wallet-balance 10000001 | cut -d'|' -f5)"
    rm -rf "$T2"

    # ── overdraw by 1 raw unit ────────────────────────────────────────────────
    # Current balance 525. Try to withdraw 5 whole 26 frac = 526 raw → INSUFFICIENT
    assert_prefix "overdraw by 1 raw unit → INSUFFICIENT" \
        "ERR|INSUFFICIENT" \
        "$(run "$T" wallet-withdraw 10000001 5 26)"

    # Balance must be unchanged after failed overdraw
    assert_eq "balance unchanged after failed overdraw" \
        "000000000000000525" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    # ── large overdraw ────────────────────────────────────────────────────────
    assert_prefix "large overdraw → INSUFFICIENT" \
        "ERR|INSUFFICIENT" \
        "$(run "$T" wallet-withdraw 10000001 9999 0)"

    # ── transaction recorded ──────────────────────────────────────────────────
    local txn_count
    txn_count="$(grep -c 'WITHDRAW' "$T/data/transactions.dat" || true)"
    [[ "$txn_count" -ge 1 ]] && \
        { echo "  PASS: WITHDRAW transactions recorded ($txn_count entries)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: no WITHDRAW in transactions.dat"; (( FAIL++ )) || true; ERRORS+=("WITHDRAW transactions recorded"); }

    # Failed withdraws must NOT be recorded
    local total_before
    total_before="$(wc -l < "$T/data/transactions.dat" | tr -d ' ')"
    run "$T" wallet-withdraw 10000001 9999 0 > /dev/null || true
    local total_after
    total_after="$(wc -l < "$T/data/transactions.dat" | tr -d ' ')"
    assert_eq "failed withdraw not recorded in transactions" \
        "$total_before" "$total_after"

    # ── deposit then withdraw in sequence ─────────────────────────────────────
    local T3
    T3=$(mktemp -d)
    setup_fixture "$T3"
    run "$T3" wallet-deposit  10000001 20 0 > /dev/null   # 1000 + 2000 = 3000
    run "$T3" wallet-withdraw 10000001  5 0 > /dev/null   # 3000 - 500  = 2500
    run "$T3" wallet-deposit  10000001  3 0 > /dev/null   # 2500 + 300  = 2800
    run "$T3" wallet-withdraw 10000001  2 50 > /dev/null  # 2800 - 250  = 2550
    assert_eq "balance correct after interleaved deposit/withdraw sequence" \
        "000000000000002550" \
        "$(run "$T3" wallet-balance 10000001 | cut -d'|' -f5)"
    rm -rf "$T3"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" wallet-withdraw 99999999 1 0)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-withdraw)"

    assert_prefix "account only → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-withdraw 10000001)"

    rm -rf "$T"
}
