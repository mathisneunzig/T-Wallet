# admin-delete-account tests — sourced by run_tests.sh

test_admin_delete_account() {
    echo "── admin-delete-account ──────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── successful delete ─────────────────────────────────────────────────────
    assert_prefix "delete existing account → OK" "OK|10000001" \
        "$(run "$T" admin-delete-account 10000001)"

    # ── all three files scrubbed ──────────────────────────────────────────────
    (grep -q '10000001' "$T/data/accounts.dat" && \
        { echo "  FAIL: account still in accounts.dat after delete"; (( FAIL++ )) || true; ERRORS+=("account removed from accounts.dat"); }) || \
        { echo "  PASS: account removed from accounts.dat"; (( PASS++ )) || true; }

    (grep -q '10000001' "$T/data/wallets.dat" && \
        { echo "  FAIL: wallet still in wallets.dat after delete"; (( FAIL++ )) || true; ERRORS+=("wallet removed from wallets.dat"); }) || \
        { echo "  PASS: wallet removed from wallets.dat"; (( PASS++ )) || true; }

    (grep -q '10000001' "$T/data/customers.dat" && \
        { echo "  FAIL: customer still in customers.dat after delete"; (( FAIL++ )) || true; ERRORS+=("customer removed from customers.dat"); }) || \
        { echo "  PASS: customer removed from customers.dat"; (( PASS++ )) || true; }

    # ── deleted account is no longer accessible ───────────────────────────────
    assert_prefix "login after delete → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_prefix "wallet-balance after delete → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" wallet-balance 10000001)"

    assert_prefix "customer-get after delete → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" customer-get 10000001)"

    # ── delete already-deleted account ────────────────────────────────────────
    assert_prefix "delete already-deleted account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" admin-delete-account 10000001)"

    # ── deleting one account does not affect others ───────────────────────────
    local T2
    T2=$(mktemp -d)
    setup_fixture "$T2"
    run "$T2" admin-create-account \
        20000001 5678 EUR 2 \
        Jane Doe '+49000000000' 'jane@example.com' \
        'Street 1' '10000' 'Berlin' 'Germany' > /dev/null

    run "$T2" admin-delete-account 20000001 > /dev/null

    assert_eq "original account unaffected after deleting second account" \
        "OK|10000001" \
        "$(run "$T2" auth-login 10000001 1234)"

    assert_prefix "original wallet unaffected" \
        "OK|10000001|EUR|2|" \
        "$(run "$T2" wallet-balance 10000001)"

    rm -rf "$T2"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" admin-delete-account 99999999)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" admin-delete-account)"

    rm -rf "$T"
}
