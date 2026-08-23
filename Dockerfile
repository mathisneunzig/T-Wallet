FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    gnucobol \
    gcc \
    libssl-dev \
    pkg-config \
    erlang \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY src/ src/
COPY rest/ rest/
COPY build.sh init.sh ./

RUN chmod +x build.sh init.sh

# Build interactive binaries.
RUN mkdir -p bin \
    && gcc $(pkg-config --cflags openssl) \
           -c src/hash.c -o bin/hash.o \
    && cobc -c -I src src/login.cbl        -o bin/login.o \
    && cobc -c -I src src/wallet.cbl       -o bin/wallet.o \
    && cobc -c -I src src/money.cbl        -o bin/money.o \
    && cobc -c -I src src/money-format.cbl -o bin/money-format.o \
    && cobc -c -I src src/customer.cbl     -o bin/customer.o \
    && cobc -c -I src src/banker.cbl       -o bin/banker.o \
    && cobc -c -I src src/admin.cbl        -o bin/admin.o \
    && cobc -x -I src src/menu.cbl \
           bin/login.o bin/wallet.o bin/money.o bin/money-format.o \
           bin/customer.o bin/banker.o bin/admin.o bin/hash.o \
           $(pkg-config --libs openssl) \
           -o bin/wallet

# Build REST action binaries (need hash_pin + OpenSSL).
RUN cobc -x -free -I src src/actions/auth-login.cbl \
           bin/hash.o $(pkg-config --libs openssl) -o bin/auth-login \
    && cobc -x -free -I src src/actions/admin-create-account.cbl \
           bin/hash.o $(pkg-config --libs openssl) -o bin/admin-create-account \
    && cobc -x -free -I src src/actions/banker-change-pin.cbl \
           bin/hash.o $(pkg-config --libs openssl) -o bin/banker-change-pin

# Build REST action binaries (no PIN hashing).
RUN cobc -x -free -I src src/actions/wallet-balance.cbl \
           bin/money-format.o -o bin/wallet-balance \
    && cobc -x -free -I src src/actions/wallet-deposit.cbl \
           bin/money-format.o -o bin/wallet-deposit \
    && cobc -x -free -I src src/actions/wallet-withdraw.cbl \
           bin/money-format.o -o bin/wallet-withdraw \
    && cobc -x -free -I src src/actions/customer-get.cbl    -o bin/customer-get \
    && cobc -x -free -I src src/actions/customer-update.cbl -o bin/customer-update \
    && cobc -x -free -I src src/actions/admin-delete-account.cbl  -o bin/admin-delete-account \
    && cobc -x -free -I src src/actions/admin-suspend-account.cbl -o bin/admin-suspend-account \
    && cobc -x -free -I src src/actions/banker-change-currency.cbl -o bin/banker-change-currency

# Compile Erlang REST server.
RUN mkdir -p rest/ebin \
    && erlc -o rest/ebin rest/src/twallet_server.erl

# Initialise data files at runtime so the data/ directory can be
# mounted as a volume for persistence.
RUN sh -c ./init.sh

# Default: interactive terminal mode.
# To run the REST server instead:
#   docker run -p 8080:8080 twallet erl -pa rest/ebin -noshell -s twallet_server start
CMD ["sh", "-c", "./bin/wallet"]
