# wallet-transfer tests — sourced by run_tests.sh

# Sets up two EUR wallets plus a USD wallet for mismatch testing.
# Also creates a bin/ symlink so the COBOL binary can find ./bin/transfer_fee.
setup_transfer_fixture() {
    local dir="$1"
    mkdir -p "$dir/data"

    # Accounts (PIN hash for "1234")
    printf '%-8s%-64s%-1s\n' \
        '10000001' \
        '48870ed50ff0e75f2687a8ae7e1d2e85ca92007bcf501ae7a80eb3987c575ded' \
        'A' > "$dir/data/accounts.dat"
    printf '%-8s%-64s%-1s\n' \
        '10000002' \
        '48870ed50ff0e75f2687a8ae7e1d2e85ca92007bcf501ae7a80eb3987c575ded' \
        'A' >> "$dir/data/accounts.dat"

    # wallets.dat: account 10000001 EUR 2 decimals balance=5000 (€50.00)
    #              account 10000002 EUR 2 decimals balance=1000 (€10.00)
    printf '%-8s%-3s%-1s%018d\n' '10000001' 'EUR' '2' '5000' \
        > "$dir/data/wallets.dat"
    printf '%-8s%-3s%-1s%018d\n' '10000002' 'EUR' '2' '1000' \
        >> "$dir/data/wallets.dat"

    # customers.dat (minimal — needed if any action reads it)
    printf '%-8s%-30s%-30s%-20s%-50s%-50s%-10s%-30s%-30s\n' \
        '10000001' 'Alice' 'Sender' '+10000000001' \
        'alice@example.com' '1 Sender St' '00001' 'City' 'Country' \
        > "$dir/data/customers.dat"
    printf '%-8s%-30s%-30s%-20s%-50s%-50s%-10s%-30s%-30s\n' \
        '10000002' 'Bob' 'Receiver' '+10000000002' \
        'bob@example.com' '2 Receiver Rd' '00002' 'City' 'Country' \
        >> "$dir/data/customers.dat"

    # transactions.dat: empty
    touch "$dir/data/transactions.dat"

    # Symlink bin/ so COBOL can call ./bin/transfer_fee from the tmpdir CWD
    ln -sfn "$BIN" "$dir/bin"
}

test_wallet_transfer() {
    echo "── wallet-transfer ───────────────────────────────────────────────────"

    # ── basic transfer ────────────────────────────────────────────────────────
    # from=10000001 (€50.00 = 5000 raw), to=10000002 (€10.00 = 1000 raw)
    # Transfer 5 whole = 500 raw. Fee = max(1, 500*5/1000) = 2 raw.
    # from after: 5000 - 502 = 4498. to after: 1000 + 500 = 1500.
    local T
    T=$(mktemp -d)
    setup_transfer_fixture "$T"

    local out
    out="$(run "$T" wallet-transfer 10000001 10000002 5 0)"
    assert_prefix "basic transfer → OK" "OK|10000001|10000002|" "$out"

    assert_eq "sender balance after transfer (5 whole, fee=2)" \
        "000000000000004498" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"

    assert_eq "recipient balance after transfer (5 whole)" \
        "000000000000001500" \
        "$(run "$T" wallet-balance 10000002 | cut -d'|' -f5)"

    # ── fee field in response ─────────────────────────────────────────────────
    local fee_field
    fee_field="$(echo "$out" | cut -d'|' -f8)"
    # fee should be a non-empty numeric string
    [[ "$fee_field" =~ ^[0-9]+$ ]] && \
        { echo "  PASS: fee_raw field is numeric (got: $fee_field)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: fee_raw field not numeric (got: '$fee_field')"; (( FAIL++ )) || true; ERRORS+=("fee_raw field numeric"); }

    # ── transfer zero ─────────────────────────────────────────────────────────
    # Transfer 0 whole 0 frac: amount=0, fee=1 (minimum). from loses 1 raw.
    local T2
    T2=$(mktemp -d)
    setup_transfer_fixture "$T2"
    run "$T2" wallet-transfer 10000001 10000002 0 0 > /dev/null
    assert_eq "sender loses minimum fee on zero transfer" \
        "000000000000004999" \
        "$(run "$T2" wallet-balance 10000001 | cut -d'|' -f5)"
    assert_eq "recipient balance unchanged on zero transfer" \
        "000000000000001000" \
        "$(run "$T2" wallet-balance 10000002 | cut -d'|' -f5)"
    rm -rf "$T2"

    # ── fractional transfer ───────────────────────────────────────────────────
    # Transfer 0 whole 50 frac = 50 raw. Fee = max(1, 50*5/1000) = 1.
    # from: 5000 - 51 = 4949. to: 1000 + 50 = 1050.
    local T3
    T3=$(mktemp -d)
    setup_transfer_fixture "$T3"
    run "$T3" wallet-transfer 10000001 10000002 0 50 > /dev/null
    assert_eq "sender balance after fractional transfer" \
        "000000000000004949" \
        "$(run "$T3" wallet-balance 10000001 | cut -d'|' -f5)"
    assert_eq "recipient balance after fractional transfer" \
        "000000000000001050" \
        "$(run "$T3" wallet-balance 10000002 | cut -d'|' -f5)"
    rm -rf "$T3"

    # ── transactions recorded ─────────────────────────────────────────────────
    local xfer_out_count xfer_in_count
    xfer_out_count="$(grep -c 'XFER-OUT' "$T/data/transactions.dat" || true)"
    xfer_in_count="$(grep -c 'XFER-IN'  "$T/data/transactions.dat" || true)"
    [[ "$xfer_out_count" -ge 1 ]] && \
        { echo "  PASS: XFER-OUT transaction recorded ($xfer_out_count entries)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: no XFER-OUT in transactions.dat"; (( FAIL++ )) || true; ERRORS+=("XFER-OUT transaction recorded"); }
    [[ "$xfer_in_count" -ge 1 ]] && \
        { echo "  PASS: XFER-IN transaction recorded ($xfer_in_count entries)"; (( PASS++ )) || true; } || \
        { echo "  FAIL: no XFER-IN in transactions.dat"; (( FAIL++ )) || true; ERRORS+=("XFER-IN transaction recorded"); }

    # ── INSUFFICIENT ─────────────────────────────────────────────────────────
    # from has 4498 left. Try to transfer 45 whole = 4500 raw + fee=22 = 4522 → over.
    assert_prefix "overdraft → INSUFFICIENT" \
        "ERR|INSUFFICIENT" \
        "$(run "$T" wallet-transfer 10000001 10000002 45 0)"

    # Balances must be unchanged
    assert_eq "sender balance unchanged after failed transfer" \
        "000000000000004498" \
        "$(run "$T" wallet-balance 10000001 | cut -d'|' -f5)"
    assert_eq "recipient balance unchanged after failed transfer" \
        "000000000000001500" \
        "$(run "$T" wallet-balance 10000002 | cut -d'|' -f5)"

    # Failed transfer must not be recorded
    local total_before total_after
    total_before="$(wc -l < "$T/data/transactions.dat" | tr -d ' ')"
    run "$T" wallet-transfer 10000001 10000002 45 0 > /dev/null || true
    total_after="$(wc -l < "$T/data/transactions.dat" | tr -d ' ')"
    assert_eq "failed transfer not recorded in transactions" \
        "$total_before" "$total_after"

    # ── CURRENCY_MISMATCH ────────────────────────────────────────────────────
    local TM
    TM=$(mktemp -d)
    mkdir -p "$TM/data"
    printf '%-8s%-3s%-1s%018d\n' '10000001' 'EUR' '2' '5000' \
        > "$TM/data/wallets.dat"
    printf '%-8s%-3s%-1s%018d\n' '10000002' 'USD' '2' '1000' \
        >> "$TM/data/wallets.dat"
    touch "$TM/data/transactions.dat"
    ln -sfn "$BIN" "$TM/bin"
    assert_prefix "currency mismatch → CURRENCY_MISMATCH" \
        "ERR|CURRENCY_MISMATCH" \
        "$(run "$TM" wallet-transfer 10000001 10000002 5 0)"
    rm -rf "$TM"

    # ── NOT_FOUND errors ──────────────────────────────────────────────────────
    assert_prefix "unknown from account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" wallet-transfer 99999999 10000002 5 0)"

    assert_prefix "unknown to account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" wallet-transfer 10000001 99999999 5 0)"

    # ── USAGE errors ──────────────────────────────────────────────────────────
    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-transfer)"

    assert_prefix "one arg → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-transfer 10000001)"

    assert_prefix "two args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" wallet-transfer 10000001 10000002)"

    rm -rf "$T"
}
