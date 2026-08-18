#!/bin/zsh

set -e

echo "=============================="
echo "       Building T-Wallet"
echo "=============================="

mkdir -p bin

echo "[1/8] Compiling hash.c..."
gcc $(pkg-config --cflags openssl) \
    -c src/hash.c \
    -o bin/hash.o

echo "[2/8] Compiling login.cbl..."
cobc -c src/login.cbl -o bin/login.o

echo "[3/8] Compiling wallet.cbl..."
cobc -c src/wallet.cbl -o bin/wallet.o

echo "[4/8] Compiling money.cbl..."
cobc -c src/money.cbl -o bin/money.o

echo "[5/8] Compiling money-format.cbl..."
cobc -c src/money-format.cbl -o bin/money-format.o

echo "[6/8] Compiling banker.cbl..."
cobc -c src/banker.cbl -o bin/banker.o

echo "[7/8] Compiling admin.cbl..."
cobc -c src/admin.cbl -o bin/admin.o

echo "[8/8] Compiling menu.cbl..."
cobc -x \
    -I src \
    src/menu.cbl \
    bin/login.o \
    bin/wallet.o \
    bin/money.o \
    bin/money-format.o \
    bin/banker.o \
    bin/admin.o \
    bin/hash.o \
    $(pkg-config --libs openssl) \
    -o bin/wallet

echo ""
echo "=============================="
echo "       Build successful!"
echo "=============================="
echo ""

echo "Starting T-Wallet..."
echo ""

clear

./bin/wallet