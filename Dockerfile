FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    gnucobol \
    gcc \
    libssl-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY src/ src/
COPY build.sh init.sh ./

RUN chmod +x build.sh init.sh

# Build binaries.
RUN mkdir -p bin \
    && gcc $(pkg-config --cflags openssl) \
           -c src/hash.c -o bin/hash.o \
    && cobc -c -I src src/login.cbl       -o bin/login.o \
    && cobc -c -I src src/wallet.cbl      -o bin/wallet.o \
    && cobc -c -I src src/money.cbl       -o bin/money.o \
    && cobc -c -I src src/money-format.cbl -o bin/money-format.o \
    && cobc -c -I src src/customer.cbl    -o bin/customer.o \
    && cobc -c -I src src/banker.cbl      -o bin/banker.o \
    && cobc -c -I src src/admin.cbl       -o bin/admin.o \
    && cobc -x -I src src/menu.cbl \
           bin/login.o bin/wallet.o bin/money.o bin/money-format.o \
           bin/customer.o bin/banker.o bin/admin.o bin/hash.o \
           $(pkg-config --libs openssl) \
           -o bin/wallet

# Initialise data files at runtime so the data/ directory can be
# mounted as a volume for persistence.
RUN sh -c ./init.sh

CMD ["sh", "-c", "./bin/wallet"]
