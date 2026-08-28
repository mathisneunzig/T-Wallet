#!/bin/zsh

set -e

echo "=============================="
echo "       Building T-Wallet"
echo "=============================="

mkdir -p bin

echo "[1/9] Compiling hash.c..."
gcc $(pkg-config --cflags openssl) \
    -c src/wallet/hash.c \
    -o bin/hash.o

echo "[2/9] Compiling login.cbl..."
cobc -c \
    -I src/wallet \
    src/wallet/login.cbl \
    -o bin/login.o

echo "[3/9] Compiling wallet.cbl..."
cobc -c \
    -I src/wallet \
    src/wallet/wallet.cbl \
    -o bin/wallet.o

echo "[4/9] Compiling money.cbl..."
cobc -c \
    -I src/wallet \
    src/wallet/money.cbl \
    -o bin/money.o

echo "[5/9] Compiling money-format.cbl..."
cobc -c \
    -I src/wallet \
    src/wallet/money-format.cbl \
    -o bin/money-format.o

echo "[6/9] Compiling customer.cbl..."
cobc -c \
    -I src/wallet \
    src/wallet/customer.cbl \
    -o bin/customer.o

echo "[7/9] Compiling banker.cbl..."
cobc -c \
    -I src/wallet \
    src/wallet/banker.cbl \
    -o bin/banker.o

echo "[8/9] Compiling admin.cbl..."
cobc -c \
    -I src/wallet \
    src/wallet/admin.cbl \
    -o bin/admin.o

echo "[9/9] Compiling menu.cbl..."
cobc -x \
    -I src/wallet \
    src/wallet/menu.cbl \
    bin/login.o \
    bin/wallet.o \
    bin/money.o \
    bin/money-format.o \
    bin/customer.o \
    bin/banker.o \
    bin/admin.o \
    bin/hash.o \
    $(pkg-config --libs openssl) \
    -o bin/wallet

echo ""
echo "=============================="
echo "   Building REST action bins"
echo "=============================="

# Helper: compile a COBOL action that needs hash_pin + OpenSSL
compile_action_hash() {
    local name="$1"
    echo "  [action] $name"
    cobc -x -free \
        -I src/wallet \
        "src/wallet/actions/${name}.cbl" \
        bin/hash.o \
        $(pkg-config --libs openssl) \
        -o "bin/${name}"
}

# Helper: compile a COBOL action that uses MONEY-FORMAT
compile_action_money() {
    local name="$1"
    echo "  [action] $name"
    cobc -x -free \
        -I src/wallet \
        "src/wallet/actions/${name}.cbl" \
        bin/money-format.o \
        -o "bin/${name}"
}

# Helper: compile a plain COBOL action (no external subprograms)
compile_action() {
    local name="$1"
    echo "  [action] $name"
    cobc -x -free \
        -I src/wallet \
        "src/wallet/actions/${name}.cbl" \
        -o "bin/${name}"
}

compile_action_hash  "auth-login"
compile_action_hash  "admin-create-account"
compile_action_hash  "banker-change-pin"

compile_action_money "wallet-balance"
compile_action_money "wallet-deposit"
compile_action_money "wallet-withdraw"
compile_action_money "wallet-transfer"

compile_action       "customer-get"
compile_action       "customer-update"
compile_action       "admin-delete-account"
compile_action       "admin-suspend-account"
compile_action       "banker-change-currency"
compile_action       "stats-query"

echo ""
echo "=============================="
echo "  Compiling FORTRAN utilities"
echo "=============================="
echo "  [fortran] transfer_fee"
gfortran -o bin/transfer_fee src/wallet/transfer_fee.f90

echo ""
echo "=============================="
echo "  Copying Lua scripts"
echo "=============================="
echo "  [lua] transfer_summary"
cp src/wallet/transfer_summary.lua bin/transfer_summary.lua

echo ""
echo "=============================="
echo "  Compiling Erlang REST server"
echo "=============================="
mkdir -p src/rest/ebin
erlc -o src/rest/ebin src/rest/twallet_server.erl

echo ""
echo "=============================="
echo "       Build successful!"
echo "=============================="
echo ""
