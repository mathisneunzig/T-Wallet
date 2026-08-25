#!/usr/bin/env bash
# T-Wallet action binary tests
# Each test runs in an isolated tmpdir with its own data/ fixture.
# Usage: bash tests/run_tests.sh

set -uo pipefail

# ─── Locate project root (directory containing this script's parent) ──────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$(cd "$SCRIPT_DIR/.." && pwd)"
BIN="$PROJECT/bin"

# ─── Test counters ────────────────────────────────────────────────────────────
PASS=0
FAIL=0
ERRORS=()

# ─── Helpers ─────────────────────────────────────────────────────────────────

# assert_eq <label> <expected> <actual>
assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [ "$actual" = "$expected" ]; then
        echo "  PASS: $label"
        (( PASS++ )) || true
    else
        echo "  FAIL: $label"
        echo "        expected: $expected"
        echo "        actual:   $actual"
        (( FAIL++ )) || true
        ERRORS+=("$label")
    fi
}

# assert_prefix <label> <expected_prefix> <actual>
assert_prefix() {
    local label="$1" prefix="$2" actual="$3"
    if [[ "$actual" == "$prefix"* ]]; then
        echo "  PASS: $label"
        (( PASS++ )) || true
    else
        echo "  FAIL: $label"
        echo "        expected prefix: $prefix"
        echo "        actual:          $actual"
        (( FAIL++ )) || true
        ERRORS+=("$label")
    fi
}

# setup_fixture <tmpdir>
# Creates data/ with seed records identical to init.sh but ASCII-only.
setup_fixture() {
    local dir="$1"
    mkdir -p "$dir/data"

    # accounts.dat: account 10000001, PIN=1234 hashed, status=A
    # PIN hash for "1234" + salt "STADIUM2026SALT"
    printf '%-8s%-64s%-1s\n' \
        '10000001' \
        '48870ed50ff0e75f2687a8ae7e1d2e85ca92007bcf501ae7a80eb3987c575ded' \
        'A' \
        > "$dir/data/accounts.dat"

    # wallets.dat: account 10000001, EUR, 2 decimals, balance=1000 (=€10.00)
    printf '%-8s%-3s%-1s%018d\n' \
        '10000001' 'EUR' '2' '1000' \
        > "$dir/data/wallets.dat"

    # customers.dat: fixed-width 8+30+30+20+50+50+10+30+30
    printf '%-8s%-30s%-30s%-20s%-50s%-50s%-10s%-30s%-30s\n' \
        '10000001' 'Erika' 'Mustermann' '+49123456789' \
        'erikamustermann@example.com' 'Musterstr. 21' \
        '10115' 'Berlin' 'Germany' \
        > "$dir/data/customers.dat"

    # transactions.dat: empty
    touch "$dir/data/transactions.dat"
}

# run <tmpdir> <binary> [args...]  →  stdout (trimmed)
run() {
    local dir="$1"; shift
    local binary="$1"; shift
    (cd "$dir" && "$BIN/$binary" "$@" 2>/dev/null) | tr -d '\r'
}

# ─── Source individual test suites ────────────────────────────────────────────
# shellcheck source=tests/auth_login_test.sh
source "$SCRIPT_DIR/auth_login_test.sh"
# shellcheck source=tests/wallet_balance_test.sh
source "$SCRIPT_DIR/wallet_balance_test.sh"
# shellcheck source=tests/wallet_deposit_test.sh
source "$SCRIPT_DIR/wallet_deposit_test.sh"
# shellcheck source=tests/wallet_withdraw_test.sh
source "$SCRIPT_DIR/wallet_withdraw_test.sh"
# shellcheck source=tests/customer_get_test.sh
source "$SCRIPT_DIR/customer_get_test.sh"
# shellcheck source=tests/customer_update_test.sh
source "$SCRIPT_DIR/customer_update_test.sh"
# shellcheck source=tests/admin_create_account_test.sh
source "$SCRIPT_DIR/admin_create_account_test.sh"
# shellcheck source=tests/admin_delete_account_test.sh
source "$SCRIPT_DIR/admin_delete_account_test.sh"
# shellcheck source=tests/admin_suspend_account_test.sh
source "$SCRIPT_DIR/admin_suspend_account_test.sh"
# shellcheck source=tests/banker_change_pin_test.sh
source "$SCRIPT_DIR/banker_change_pin_test.sh"
# shellcheck source=tests/banker_change_currency_test.sh
source "$SCRIPT_DIR/banker_change_currency_test.sh"
# shellcheck source=tests/stats_query_test.sh
source "$SCRIPT_DIR/stats_query_test.sh"

# ─── Main ─────────────────────────────────────────────────────────────────────

echo "=============================="
echo "   T-Wallet Action Tests"
echo "=============================="
echo ""

test_auth_login
echo ""
test_wallet_balance
echo ""
test_wallet_deposit
echo ""
test_wallet_withdraw
echo ""
test_customer_get
echo ""
test_customer_update
echo ""
test_admin_create_account
echo ""
test_admin_delete_account
echo ""
test_admin_suspend_account
echo ""
test_banker_change_pin
echo ""
test_banker_change_currency
echo ""
test_stats_query

echo ""
echo "=============================="
TOTAL=$(( PASS + FAIL ))
echo "  Results: $PASS/$TOTAL passed"
if [ "$FAIL" -gt 0 ]; then
    echo "  Failed tests:"
    for e in "${ERRORS[@]}"; do
        echo "    - $e"
    done
    echo "=============================="
    exit 1
else
    echo "  All tests passed!"
    echo "=============================="
fi
