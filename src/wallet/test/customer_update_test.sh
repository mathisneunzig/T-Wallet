# customer-update tests — sourced by run_tests.sh

test_customer_update() {
    echo "── customer-update ───────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    # ── all updatable fields ──────────────────────────────────────────────────
    for field in phone address zip city country fname lname email; do
        assert_prefix "update $field → OK" "OK|10000001|" \
            "$(run "$T" customer-update 10000001 "$field" "testvalue")"
    done

    # ── each update persists via customer-get ─────────────────────────────────
    run "$T" customer-update 10000001 phone '+49987654321' > /dev/null
    local got_phone
    got_phone="$(run "$T" customer-get 10000001 | cut -d'|' -f5 | tr -d ' ')"
    assert_eq "phone update persists" "+49987654321" "$got_phone"

    run "$T" customer-update 10000001 city 'Hamburg' > /dev/null
    local got_city
    got_city="$(run "$T" customer-get 10000001 | cut -d'|' -f9 | tr -d ' ')"
    assert_eq "city update persists" "Hamburg" "$got_city"

    run "$T" customer-update 10000001 zip '20095' > /dev/null
    local got_zip
    got_zip="$(run "$T" customer-get 10000001 | cut -d'|' -f8 | tr -d ' ')"
    assert_eq "zip update persists" "20095" "$got_zip"

    run "$T" customer-update 10000001 country 'Austria' > /dev/null
    local got_country
    got_country="$(run "$T" customer-get 10000001 | cut -d'|' -f10 | tr -d ' ')"
    assert_eq "country update persists" "Austria" "$got_country"

    run "$T" customer-update 10000001 fname 'Max' > /dev/null
    local got_fname
    got_fname="$(run "$T" customer-get 10000001 | cut -d'|' -f3 | tr -d ' ')"
    assert_eq "fname update persists" "Max" "$got_fname"

    run "$T" customer-update 10000001 lname 'Muster' > /dev/null
    local got_lname
    got_lname="$(run "$T" customer-get 10000001 | cut -d'|' -f4 | tr -d ' ')"
    assert_eq "lname update persists" "Muster" "$got_lname"

    run "$T" customer-update 10000001 email 'max@example.com' > /dev/null
    local got_email
    got_email="$(run "$T" customer-get 10000001 | cut -d'|' -f6 | tr -d ' ')"
    assert_eq "email update persists" "max@example.com" "$got_email"

    # ── second update overwrites first ────────────────────────────────────────
    run "$T" customer-update 10000001 city 'Berlin' > /dev/null
    run "$T" customer-update 10000001 city 'Munich' > /dev/null
    local got_city2
    got_city2="$(run "$T" customer-get 10000001 | cut -d'|' -f9 | tr -d ' ')"
    assert_eq "second city update overwrites first" "Munich" "$got_city2"

    # ── invalid fields rejected ───────────────────────────────────────────────
    assert_prefix "unknown field → INVALID_FIELD" \
        "ERR|INVALID_FIELD" \
        "$(run "$T" customer-update 10000001 badfield value)"

    assert_prefix "field 'balance' is not updatable via customer-update → INVALID_FIELD" \
        "ERR|INVALID_FIELD" \
        "$(run "$T" customer-update 10000001 balance 9999)"

    assert_prefix "field 'account' is not updatable → INVALID_FIELD" \
        "ERR|INVALID_FIELD" \
        "$(run "$T" customer-update 10000001 account 99999999)"

    assert_prefix "empty field name → INVALID_FIELD or USAGE" \
        "ERR|" \
        "$(run "$T" customer-update 10000001 '' value)"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" customer-update 99999999 phone 12345)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" customer-update)"

    assert_prefix "account only → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" customer-update 10000001)"

    rm -rf "$T"
}
