# admin-create-account tests — sourced by run_tests.sh

test_admin_create_account() {
    echo "── admin-create-account ──────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── successful creation ───────────────────────────────────────────────────
    local out
    out="$(run "$T" admin-create-account \
        20000001 5678 USD 2 \
        John Doe '+1555000111' 'john@example.com' \
        'Main St 1' '10001' 'NewYork' 'USA')"
    assert_prefix "create account → OK with account number" "OK|20000001" "$out"

    # ── all three files are updated ───────────────────────────────────────────
    (grep -q '20000001' "$T/data/accounts.dat" && \
        { echo "  PASS: new account in accounts.dat"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: new account missing from accounts.dat"; (( FAIL++ )) || true; ERRORS+=("new account in accounts.dat"); }

    (grep -q '20000001' "$T/data/wallets.dat" && \
        { echo "  PASS: new wallet in wallets.dat"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: new wallet missing from wallets.dat"; (( FAIL++ )) || true; ERRORS+=("new wallet in wallets.dat"); }

    (grep -q '20000001' "$T/data/customers.dat" && \
        { echo "  PASS: new customer in customers.dat"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: new customer missing from customers.dat"; (( FAIL++ )) || true; ERRORS+=("new customer in customers.dat"); }

    # ── new account is immediately usable ─────────────────────────────────────
    assert_eq "new account PIN works immediately" \
        "OK|20000001" \
        "$(run "$T" auth-login 20000001 5678)"

    assert_prefix "new wallet balance is zero" \
        "OK|20000001|USD|2|000000000000000000" \
        "$(run "$T" wallet-balance 20000001)"

    # ── customer data stored correctly ────────────────────────────────────────
    local cust
    cust="$(run "$T" customer-get 20000001)"
    assert_prefix "customer-get works on new account" "OK|20000001|" "$cust"

    local fname
    fname="$(echo "$cust" | cut -d'|' -f3 | tr -d ' ')"
    assert_eq "fname stored correctly" "John" "$fname"

    local lname
    lname="$(echo "$cust" | cut -d'|' -f4 | tr -d ' ')"
    assert_eq "lname stored correctly" "Doe" "$lname"

    # ── create a second distinct account ─────────────────────────────────────
    run "$T" admin-create-account \
        30000001 9999 EUR 2 \
        Anna Smith '+44123456' 'anna@example.com' \
        'High St 9' 'SW1A' 'London' 'UK' > /dev/null
    assert_eq "second account PIN works" \
        "OK|30000001" \
        "$(run "$T" auth-login 30000001 9999)"

    # Original account still works after second creation
    assert_eq "original account still works after second creation" \
        "OK|10000001" \
        "$(run "$T" auth-login 10000001 1234)"

    # ── duplicate account number → error ─────────────────────────────────────
    assert_prefix "duplicate account number → EXISTS error" \
        "ERR|EXISTS" \
        "$(run "$T" admin-create-account \
            20000001 0000 EUR 2 \
            Jane Dup '+1000000000' 'dup@example.com' \
            'Dup St 1' '00000' 'NN' 'XX')"

    # Duplicate must not overwrite original PIN
    assert_eq "duplicate create did not overwrite original PIN" \
        "OK|20000001" \
        "$(run "$T" auth-login 20000001 5678)"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" admin-create-account)"

    rm -rf "$T"
}
