# admin-create-account tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_admin_create_account() {
    echo "── admin-create-account ──────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" admin-create-account \
        20000001 5678 USD 2 \
        John Doe '+1555000111' 'john@example.com' \
        'Main St 1' '10001' 'NewYork' 'USA')"
    assert_prefix "create new account" "OK|20000001" "$out"

    (grep -q '20000001' "$T/data/accounts.dat" && \
        { echo "  PASS: account in accounts.dat"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: account in accounts.dat"; (( FAIL++ )) || true; ERRORS+=("account in accounts.dat"); }

    (grep -q '20000001' "$T/data/wallets.dat" && \
        { echo "  PASS: wallet created"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: wallet created"; (( FAIL++ )) || true; ERRORS+=("wallet created"); }

    (grep -q '20000001' "$T/data/customers.dat" && \
        { echo "  PASS: customer profile created"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: customer profile created"; (( FAIL++ )) || true; ERRORS+=("customer profile created"); }

    assert_prefix "duplicate account" "ERR|" \
        "$(run "$T" admin-create-account \
            20000001 5678 USD 2 \
            John Doe '+1555000111' 'john@example.com' \
            'Main St 1' '10001' 'NewYork' 'USA')"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" admin-create-account)"

    rm -rf "$T"
}
