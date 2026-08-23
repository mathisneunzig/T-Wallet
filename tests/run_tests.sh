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

# ─── Test suites ─────────────────────────────────────────────────────────────

test_auth_login() {
    echo "── auth-login ────────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_eq "correct PIN"       "OK|10000001" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_prefix "wrong PIN"     "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 9999)"

    assert_prefix "not found"     "ERR|NOT_FOUND" \
        "$(run "$T" auth-login 99999999 1234)"

    assert_prefix "no args"       "ERR|USAGE" \
        "$(run "$T" auth-login)"

    # Suspend the account then try to login
    (cd "$T" && "$BIN/admin-suspend-account" 10000001 > /dev/null)
    assert_prefix "suspended"     "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 1234)"

    rm -rf "$T"
}

test_wallet_balance() {
    echo "── wallet-balance ────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" wallet-balance 10000001)"
    assert_prefix "existing account starts with OK" "OK|10000001|EUR|2|" "$out"

    assert_prefix "not found"  "ERR|NOT_FOUND" \
        "$(run "$T" wallet-balance 99999999)"

    assert_prefix "no args"    "ERR|USAGE" \
        "$(run "$T" wallet-balance)"

    rm -rf "$T"
}

test_wallet_deposit() {
    echo "── wallet-deposit ────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # Initial balance = 1000 raw (€10.00). Deposit 5 whole, 50 frac → 550 raw added → 1550 total
    local out
    out="$(run "$T" wallet-deposit 10000001 5 50)"
    assert_prefix "deposit OK"    "OK|10000001|" "$out"

    # Balance should now be 1550
    local bal
    bal="$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"
    assert_eq "balance after deposit" "000000000000001550" "$bal"

    assert_prefix "not found"     "ERR|NOT_FOUND" \
        "$(run "$T" wallet-deposit 99999999 5 0)"

    assert_prefix "no args"       "ERR|USAGE" \
        "$(run "$T" wallet-deposit)"

    rm -rf "$T"
}

test_wallet_withdraw() {
    echo "── wallet-withdraw ───────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # Initial balance = 1000 raw. Withdraw 3 whole, 0 frac → 300 raw → 700 left
    local out
    out="$(run "$T" wallet-withdraw 10000001 3 0)"
    assert_prefix "withdraw OK"   "OK|10000001|" "$out"

    local bal
    bal="$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"
    assert_eq "balance after withdraw" "000000000000000700" "$bal"

    # Overdraw: try to withdraw 100 (10000 raw) from remaining 700
    assert_prefix "insufficient"  "ERR|INSUFFICIENT" \
        "$(run "$T" wallet-withdraw 10000001 100 0)"

    assert_prefix "not found"     "ERR|NOT_FOUND" \
        "$(run "$T" wallet-withdraw 99999999 1 0)"

    assert_prefix "no args"       "ERR|USAGE" \
        "$(run "$T" wallet-withdraw)"

    rm -rf "$T"
}

test_customer_get() {
    echo "── customer-get ──────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" customer-get 10000001)"
    assert_prefix "existing account" "OK|10000001|" "$out"

    # Check specific fields are present in the output
    assert_prefix "contains fname"  "OK|10000001|Erika" "$out"

    assert_prefix "not found"   "ERR|NOT_FOUND" \
        "$(run "$T" customer-get 99999999)"

    assert_prefix "no args"     "ERR|USAGE" \
        "$(run "$T" customer-get)"

    rm -rf "$T"
}

test_customer_update() {
    echo "── customer-update ───────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # Update phone (COBOL pads field name to fixed width, so just check account prefix)
    local out
    out="$(run "$T" customer-update 10000001 phone '+49987654321')"
    assert_prefix "update phone OK" "OK|10000001|" "$out"

    # Verify change persisted via customer-get
    local get
    get="$(run "$T" customer-get 10000001)"
    [[ "$get" == *"+49987654321"* ]] && \
        { echo "  PASS: phone change persisted"; (( PASS++ )) || true; } || \
        { echo "  FAIL: phone change persisted"; (( FAIL++ )) || true; ERRORS+=("phone change persisted"); }

    # Update address
    assert_prefix "update address OK" "OK|10000001|" \
        "$(run "$T" customer-update 10000001 address 'New Street 5')"

    # Invalid field (fname is read-only at COBOL level INVALID_FIELD; the Erlang layer
    # adds a FORBIDDEN check, but the COBOL binary itself returns INVALID_FIELD for unknown fields)
    assert_prefix "invalid field"   "ERR|INVALID_FIELD" \
        "$(run "$T" customer-update 10000001 badfield value)"

    assert_prefix "not found"       "ERR|NOT_FOUND" \
        "$(run "$T" customer-update 99999999 phone 12345)"

    assert_prefix "no args"         "ERR|USAGE" \
        "$(run "$T" customer-update)"

    rm -rf "$T"
}

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

    # Verify account exists in accounts.dat
    (grep -q '20000001' "$T/data/accounts.dat" && \
        { echo "  PASS: account in accounts.dat"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: account in accounts.dat"; (( FAIL++ )) || true; ERRORS+=("account in accounts.dat"); }

    # Verify wallet created
    (grep -q '20000001' "$T/data/wallets.dat" && \
        { echo "  PASS: wallet created"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: wallet created"; (( FAIL++ )) || true; ERRORS+=("wallet created"); }

    # Verify customer profile created
    (grep -q '20000001' "$T/data/customers.dat" && \
        { echo "  PASS: customer profile created"; (( PASS++ )) || true; }) || \
        { echo "  FAIL: customer profile created"; (( FAIL++ )) || true; ERRORS+=("customer profile created"); }

    # Duplicate account
    assert_prefix "duplicate account" "ERR|" \
        "$(run "$T" admin-create-account \
            20000001 5678 USD 2 \
            John Doe '+1555000111' 'john@example.com' \
            'Main St 1' '10001' 'NewYork' 'USA')"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" admin-create-account)"

    rm -rf "$T"
}

test_admin_delete_account() {
    echo "── admin-delete-account ──────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_prefix "delete existing" "OK|10000001" \
        "$(run "$T" admin-delete-account 10000001)"

    # Account must be gone from all three files
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

test_admin_suspend_account() {
    echo "── admin-suspend-account ─────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_prefix "suspend existing" "OK|10000001" \
        "$(run "$T" admin-suspend-account 10000001)"

    # Login should now return SUSPENDED
    assert_prefix "login after suspend" "ERR|SUSPENDED" \
        "$(run "$T" auth-login 10000001 1234)"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" admin-suspend-account 99999999)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" admin-suspend-account)"

    rm -rf "$T"
}

test_banker_change_pin() {
    echo "── banker-change-pin ─────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    assert_prefix "change pin OK" "OK|10000001" \
        "$(run "$T" banker-change-pin 10000001 9999)"

    # Old PIN should no longer work
    assert_prefix "old PIN rejected" "ERR|INVALID_PIN" \
        "$(run "$T" auth-login 10000001 1234)"

    # New PIN should work
    assert_eq "new PIN accepted" "OK|10000001" \
        "$(run "$T" auth-login 10000001 9999)"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" banker-change-pin 99999999 1234)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" banker-change-pin)"

    rm -rf "$T"
}

test_banker_change_currency() {
    echo "── banker-change-currency ────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" banker-change-currency 10000001 USD 0)"
    assert_prefix "change currency OK" "OK|10000001|USD|" "$out"

    # Balance display should reflect new currency
    local bal_out
    bal_out="$(run "$T" wallet-balance 10000001)"
    assert_prefix "balance shows USD" "OK|10000001|USD|0|" "$bal_out"

    assert_prefix "not found" "ERR|NOT_FOUND" \
        "$(run "$T" banker-change-currency 99999999 USD 0)"

    assert_prefix "no args" "ERR|USAGE" \
        "$(run "$T" banker-change-currency)"

    rm -rf "$T"
}

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
