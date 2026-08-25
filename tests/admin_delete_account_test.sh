# admin-delete-account tests — sourced by tests/run_tests.sh
# Requires: PASS, FAIL, ERRORS, BIN, assert_eq, assert_prefix, setup_fixture, run

test_admin_delete_account() {
    echo "── admin-delete-account ──────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_prefix "delete existing" "OK|10000001" \
        "$(run "$T" admin-delete-account 10000001)"

    (grep -q '10000001' "$T/data/accounts.dat" && \
        { echo "  FAIL: account still in accounts.dat"; (( FAIL++ )) || true; ERRORS+=("account removed from accounts.dat"); }) || \
        { echo "  PASS: account removed from accounts.dat"; (( PASS++ )) || true; }

    (grep -q '10000001' "$T/data/wallets.dat" && \
        { echo "  FAIL: wallet still in wallets.dat"; (( FAIL++ )) || true; ERRORS+=("wallet removed from wallets.dat"); }) || \
        { echo "  PASS: wallet removed from wallets.dat"; (( PASS++ )) || true; }

    (grep -q '10000001' "$T/data/customers.dat" && \
        { echo "  FAIL: customer still in customers.dat"; (( FAIL++ )) || true; ERRORS+=("customer removed from customers.dat"); }) || \
        { echo "  PASS: customer removed from customers.dat"; (( PASS++ )) || true; }

    assert_prefix "delete non-existent" "ERR|NOT_FOUND" \
        "$(run "$T" admin-delete-account 99999999)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" admin-delete-account)"

    rm -rf "$T"
}
