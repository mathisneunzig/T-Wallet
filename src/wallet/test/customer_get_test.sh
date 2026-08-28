# customer-get tests — sourced by run_tests.sh

test_customer_get() {
    echo "── customer-get ──────────────────────────────────────────────────────"
    local T
    T=$(mktemp -d)
    setup_fixture "$T"

    local out
    out="$(run "$T" customer-get 10000001)"

    # ── response structure ────────────────────────────────────────────────────
    assert_prefix "response starts with OK" "OK|10000001|" "$out"

    # Pipe count: OK + 9 fields = 9 pipes
    local pipes
    pipes="$(echo "$out" | tr -cd '|' | wc -c | tr -d ' ')"
    assert_eq "response has 9 pipe separators (10 fields)" "9" "$pipes"

    # ── field values match fixture ────────────────────────────────────────────
    assert_eq "account field" \
        "10000001" "$(echo "$out" | cut -d'|' -f2)"

    local fname
    fname="$(echo "$out" | cut -d'|' -f3 | tr -d ' ')"
    assert_eq "fname is Erika" "Erika" "$fname"

    local lname
    lname="$(echo "$out" | cut -d'|' -f4 | tr -d ' ')"
    assert_eq "lname is Mustermann" "Mustermann" "$lname"

    local phone
    phone="$(echo "$out" | cut -d'|' -f5 | tr -d ' ')"
    assert_eq "phone matches fixture" "+49123456789" "$phone"

    local email
    email="$(echo "$out" | cut -d'|' -f6 | tr -d ' ')"
    assert_eq "email matches fixture" "erikamustermann@example.com" "$email"

    local city
    city="$(echo "$out" | cut -d'|' -f9 | tr -d ' ')"
    assert_eq "city is Berlin" "Berlin" "$city"

    local country
    country="$(echo "$out" | cut -d'|' -f10 | tr -d ' ')"
    assert_eq "country is Germany" "Germany" "$country"

    # ── updates are reflected in get ──────────────────────────────────────────
    run "$T" customer-update 10000001 phone '+49000000000' > /dev/null
    local updated
    updated="$(run "$T" customer-get 10000001 | cut -d'|' -f5 | tr -d ' ')"
    assert_eq "updated phone reflected in get" "+49000000000" "$updated"

    run "$T" customer-update 10000001 city 'Munich' > /dev/null
    local updated_city
    updated_city="$(run "$T" customer-get 10000001 | cut -d'|' -f9 | tr -d ' ')"
    assert_eq "updated city reflected in get" "Munich" "$updated_city"

    run "$T" customer-update 10000001 country 'Austria' > /dev/null
    local updated_country
    updated_country="$(run "$T" customer-get 10000001 | cut -d'|' -f10 | tr -d ' ')"
    assert_eq "updated country reflected in get" "Austria" "$updated_country"

    # ── error cases ───────────────────────────────────────────────────────────
    assert_prefix "non-existent account → NOT_FOUND" \
        "ERR|NOT_FOUND" \
        "$(run "$T" customer-get 99999999)"

    assert_prefix "no args → USAGE" \
        "ERR|USAGE" \
        "$(run "$T" customer-get)"

    rm -rf "$T"
}
