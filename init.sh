#!/bin/zsh

set -e

echo "=============================="
echo "   Initializing T-Wallet Data"
echo "=============================="

mkdir -p data


# ==========================================
# accounts.dat
# ==========================================

if [ ! -f data/accounts.dat ]; then
    echo "Creating data/accounts.dat..."

    cat > data/accounts.dat << EOF
1000000148870ed50ff0e75f2687a8ae7e1d2e85ca92007bcf501ae7a80eb3987c575dedA
EOF

else
    echo "data/accounts.dat already exists."
fi


# ==========================================
# wallets.dat
# ==========================================

if [ ! -f data/wallets.dat ]; then
    echo "Creating data/wallets.dat..."

    cat > data/wallets.dat << EOF
10000001EUR20000000000000010000
EOF

else
    echo "data/wallets.dat already exists."
fi


# ==========================================
# customers.dat
# ==========================================

if [ ! -f data/customers.dat ]; then
    echo "Creating data/customers.dat..."

    printf '%-8s%-30s%-30s%-20s%-50s%-50s%-10s%-30s%-30s\n' \
        '10000001' 'Erika' 'Mustermann' '+49123456789' \
        'erikamustermann@example.com' 'Musterstraße 21' \
        '10115' 'Berlin' 'Germany' \
        > data/customers.dat

else
    echo "data/customers.dat already exists."
fi


# ==========================================
# transactions.dat
# ==========================================

if [ ! -f data/transactions.dat ]; then
    echo "Creating data/transactions.dat..."

    touch data/transactions.dat

else
    echo "data/transactions.dat already exists."
fi


echo ""
echo "=============================="
echo "   Data initialization done!"
echo "=============================="
echo ""
echo "Demo account:"
echo "Account number: 10000001"
echo "PIN:            1234"
echo "Balance:        10.00 EUR"
echo ""