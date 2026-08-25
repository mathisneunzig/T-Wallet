       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKER.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.

       FILE-CONTROL.

           SELECT ACCOUNT-FILE
               ASSIGN TO "data/accounts.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT ACCOUNT-TEMP-FILE
               ASSIGN TO "data/accounts.tmp"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT WALLET-FILE
               ASSIGN TO "data/wallets.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT WALLET-TEMP-FILE
               ASSIGN TO "data/wallets.tmp"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT TRANSACTION-FILE
               ASSIGN TO "data/transactions.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.

       FILE SECTION.

       FD ACCOUNT-FILE.
       01 ACCOUNT-RECORD.
           05 FILE-ACCOUNT-NUMBER PIC X(8).
           05 FILE-PIN-HASH       PIC X(64).
           05 FILE-ACCOUNT-STATUS PIC X.

       FD ACCOUNT-TEMP-FILE.
       01 ACCOUNT-TEMP-RECORD.
           05 TEMP-ACCOUNT-NUMBER PIC X(8).
           05 TEMP-PIN-HASH       PIC X(64).
           05 TEMP-ACCOUNT-STATUS PIC X.

       FD WALLET-FILE.
       01 WALLET-RECORD.
           05 FILE-WALLET-ACCOUNT-NUMBER PIC X(8).
           05 FILE-WALLET-CURRENCY       PIC X(3).
           05 FILE-WALLET-DECIMALS       PIC 9.
           05 FILE-WALLET-BALANCE        PIC 9(18).

       FD WALLET-TEMP-FILE.
       01 WALLET-TEMP-RECORD.
           05 TEMP-WALLET-ACCOUNT-NUMBER PIC X(8).
           05 TEMP-WALLET-CURRENCY       PIC X(3).
           05 TEMP-WALLET-DECIMALS       PIC 9.
           05 TEMP-WALLET-BALANCE        PIC 9(18).

       FD TRANSACTION-FILE.
       01 TRANSACTION-RECORD.
           05 FILE-TRANSACTION-ACCOUNT   PIC X(8).
           05 FILE-TRANSACTION-TYPE      PIC X(10).
           05 FILE-TRANSACTION-CURRENCY  PIC X(3).
           05 FILE-TRANSACTION-DECIMALS  PIC 9.
           05 FILE-TRANSACTION-AMOUNT    PIC 9(18).

       WORKING-STORAGE SECTION.

       COPY "terminal.cpy".

       01 WS-BANKER-USER
           PIC X(20).

       01 WS-BANKER-PIN
           PIC X(4).

       01 WS-MENU-CHOICE
           PIC 9
           VALUE 0.

       *> Current customer context.
       01 WS-TARGET-ACCOUNT
           PIC X(8).

       01 WS-WALLET-FOUND
           PIC X
           VALUE "N".

       01 WS-ACCOUNT-FOUND
           PIC X
           VALUE "N".

       01 WS-END-OF-FILE
           PIC X
           VALUE "N".

       *> Wallet state for the current customer.
       01 WS-CURRENCY
           PIC X(3)
           VALUE SPACES.

       01 WS-CURRENCY-DECIMALS
           PIC 9
           VALUE 0.

       01 WS-BALANCE
           PIC 9(18)
           VALUE 0.

       01 WS-AMOUNT
           PIC 9(18)
           VALUE 0.

       01 WS-DISPLAY-BALANCE
           PIC X(40)
           VALUE SPACES.

       *> New account creation fields.
       01 WS-NEW-ACCOUNT-NUMBER
           PIC X(8).

       01 WS-NEW-PIN
           PIC X(4).

       *> C string: 4 characters + null terminator.
       01 WS-NEW-PIN-C
           PIC X(5).

       01 WS-SALT
           PIC X(15)
           VALUE "STADIUM2026SALT".

       *> C string: 15 characters + null terminator.
       01 WS-SALT-C
           PIC X(16).

       01 WS-NEW-PIN-HASH
           PIC X(65).

       01 WS-NEW-CURRENCY
           PIC X(3).

       01 WS-NEW-DECIMALS
           PIC 9.

       *> Change customer info fields.
       01 WS-NEW-PIN-CONFIRM
           PIC X(4).

       01 WS-INFO-CHOICE
           PIC 9.

       *> Customer profile fields.
       01 WS-CUST-OP
           PIC X(4).

       01 WS-CUST-FOUND
           PIC X.

       01 WS-CUST-FNAME
           PIC X(30).

       01 WS-CUST-LNAME
           PIC X(30).

       01 WS-CUST-PHONE
           PIC X(20).

       01 WS-CUST-EMAIL
           PIC X(50).

       01 WS-CUST-ADDRESS
           PIC X(50).

       01 WS-CUST-ZIP
           PIC X(10).

       01 WS-CUST-CITY
           PIC X(30).

       01 WS-CUST-COUNTRY
           PIC X(30).

       01 WS-PROFILE-CHOICE
           PIC 9.

       PROCEDURE DIVISION.

           PERFORM BANKER-LOGIN.

           IF WS-MENU-CHOICE = 0

               PERFORM BANKER-MENU
                   UNTIL WS-MENU-CHOICE = 6

           END-IF.

           GOBACK.


       BANKER-LOGIN.

           DISPLAY T-WHITE " ".
           DISPLAY T-YELLOW "========================".
           DISPLAY T-YELLOW "       BANKER LOGIN".
           DISPLAY T-YELLOW "========================".

           DISPLAY T-WHITE "Username: ".
           ACCEPT WS-BANKER-USER.

           DISPLAY T-WHITE "PIN: ".
           ACCEPT WS-BANKER-PIN.

           *> Temporary authentication.
           IF WS-BANKER-USER = "banker"
              AND WS-BANKER-PIN = "1234"

               DISPLAY T-BOLD T-BLUE "Banker login successful!"
               MOVE 0
                   TO WS-MENU-CHOICE

           ELSE

               DISPLAY T-RED "Invalid banker credentials."
               MOVE 6
                   TO WS-MENU-CHOICE

           END-IF.


       BANKER-MENU.

           DISPLAY T-WHITE " ".
           DISPLAY T-YELLOW "========================".
           DISPLAY T-YELLOW "       BANKER MENU".
           DISPLAY T-YELLOW "========================".
           DISPLAY T-WHITE " ".
           DISPLAY T-WHITE "1. Deposit money for customer".
           DISPLAY T-WHITE "2. Withdraw money for customer".
           DISPLAY T-WHITE "3. Tell balance for customer".
           DISPLAY T-WHITE "4. Change customer information".
           DISPLAY T-WHITE "5. Create new account".
           DISPLAY T-RED   "6. Logout".
           DISPLAY T-WHITE " ".

           DISPLAY T-WHITE "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.

           EVALUATE WS-MENU-CHOICE

               WHEN 1
                   PERFORM BANKER-DEPOSIT

               WHEN 2
                   PERFORM BANKER-WITHDRAW

               WHEN 3
                   PERFORM BANKER-BALANCE

               WHEN 4
                   PERFORM BANKER-CHANGE-INFO

               WHEN 5
                   PERFORM BANKER-CREATE-ACCOUNT

               WHEN 6
                   DISPLAY T-RED "Logging out..."

               WHEN OTHER
                   DISPLAY T-RED "Invalid option."

           END-EVALUATE.


       *> -------------------------------------------------------
       *> Load wallet data for WS-TARGET-ACCOUNT into working
       *> storage. Sets WS-WALLET-FOUND to Y or N.
       *> -------------------------------------------------------
       LOAD-CUSTOMER-WALLET.

           MOVE "N"
               TO WS-WALLET-FOUND.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT WALLET-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-WALLET-FOUND = "Y"

               READ WALLET-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       IF FILE-WALLET-ACCOUNT-NUMBER =
                          WS-TARGET-ACCOUNT

                           MOVE "Y"
                               TO WS-WALLET-FOUND

                           MOVE FILE-WALLET-CURRENCY
                               TO WS-CURRENCY

                           MOVE FILE-WALLET-DECIMALS
                               TO WS-CURRENCY-DECIMALS

                           MOVE FILE-WALLET-BALANCE
                               TO WS-BALANCE

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE WALLET-FILE.


       *> -------------------------------------------------------
       *> Write updated WS-BALANCE back to wallets.dat for the
       *> current WS-TARGET-ACCOUNT.
       *> -------------------------------------------------------
       SAVE-CUSTOMER-WALLET.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT WALLET-FILE.
           OPEN OUTPUT WALLET-TEMP-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"

               READ WALLET-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       MOVE FILE-WALLET-ACCOUNT-NUMBER
                           TO TEMP-WALLET-ACCOUNT-NUMBER

                       MOVE FILE-WALLET-CURRENCY
                           TO TEMP-WALLET-CURRENCY

                       MOVE FILE-WALLET-DECIMALS
                           TO TEMP-WALLET-DECIMALS

                       IF FILE-WALLET-ACCOUNT-NUMBER =
                          WS-TARGET-ACCOUNT

                           MOVE WS-BALANCE
                               TO TEMP-WALLET-BALANCE

                       ELSE

                           MOVE FILE-WALLET-BALANCE
                               TO TEMP-WALLET-BALANCE

                       END-IF

                       WRITE WALLET-TEMP-RECORD

               END-READ

           END-PERFORM.

           CLOSE WALLET-FILE.
           CLOSE WALLET-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/wallets.tmp data/wallets.dat".


       *> -------------------------------------------------------
       *> Append a transaction record to transactions.dat.
       *> -------------------------------------------------------
       SAVE-TRANSACTION.

           OPEN EXTEND TRANSACTION-FILE.

           MOVE WS-TARGET-ACCOUNT
               TO FILE-TRANSACTION-ACCOUNT.

           MOVE WS-CURRENCY
               TO FILE-TRANSACTION-CURRENCY.

           MOVE WS-CURRENCY-DECIMALS
               TO FILE-TRANSACTION-DECIMALS.

           MOVE WS-AMOUNT
               TO FILE-TRANSACTION-AMOUNT.

           WRITE TRANSACTION-RECORD.

           CLOSE TRANSACTION-FILE.


       *> -------------------------------------------------------
       *> Banker: deposit for a customer.
       *> -------------------------------------------------------
       BANKER-DEPOSIT.

           DISPLAY T-WHITE " ".
           DISPLAY T-WHITE "Customer account number: ".
           ACCEPT WS-TARGET-ACCOUNT.

           PERFORM LOAD-CUSTOMER-WALLET.

           IF WS-WALLET-FOUND = "N"

               DISPLAY T-RED "Wallet not found."

           ELSE

               MOVE 0
                   TO WS-AMOUNT

               CALL "MONEY"
                   USING
                       WS-CURRENCY
                       WS-CURRENCY-DECIMALS
                       WS-AMOUNT

               ADD WS-AMOUNT
                   TO WS-BALANCE

               MOVE "DEPOSIT"
                   TO FILE-TRANSACTION-TYPE

               PERFORM SAVE-TRANSACTION

               PERFORM SAVE-CUSTOMER-WALLET

               DISPLAY T-BOLD T-BLUE "Deposit successful!"

               PERFORM SHOW-CUSTOMER-BALANCE

           END-IF.


       *> -------------------------------------------------------
       *> Banker: withdraw for a customer.
       *> -------------------------------------------------------
       BANKER-WITHDRAW.

           DISPLAY T-WHITE " ".
           DISPLAY T-WHITE "Customer account number: ".
           ACCEPT WS-TARGET-ACCOUNT.

           PERFORM LOAD-CUSTOMER-WALLET.

           IF WS-WALLET-FOUND = "N"

               DISPLAY T-RED "Wallet not found."

           ELSE

               MOVE 0
                   TO WS-AMOUNT

               CALL "MONEY"
                   USING
                       WS-CURRENCY
                       WS-CURRENCY-DECIMALS
                       WS-AMOUNT

               IF WS-BALANCE >= WS-AMOUNT

                   SUBTRACT WS-AMOUNT
                       FROM WS-BALANCE

                   MOVE "WITHDRAW"
                       TO FILE-TRANSACTION-TYPE

                   PERFORM SAVE-TRANSACTION

                   PERFORM SAVE-CUSTOMER-WALLET

                   DISPLAY T-BOLD T-BLUE "Withdrawal successful!"

                   PERFORM SHOW-CUSTOMER-BALANCE

               ELSE

                   DISPLAY T-RED "Withdrawal rejected!"
                   DISPLAY T-RED "Insufficient balance."

               END-IF

           END-IF.


       *> -------------------------------------------------------
       *> Banker: show balance for a customer.
       *> -------------------------------------------------------
       BANKER-BALANCE.

           DISPLAY T-WHITE " ".
           DISPLAY T-WHITE "Customer account number: ".
           ACCEPT WS-TARGET-ACCOUNT.

           PERFORM LOAD-CUSTOMER-WALLET.

           IF WS-WALLET-FOUND = "N"

               DISPLAY T-RED "Wallet not found."

           ELSE

               PERFORM SHOW-CUSTOMER-BALANCE

           END-IF.


       SHOW-CUSTOMER-BALANCE.

           MOVE SPACES
               TO WS-DISPLAY-BALANCE.

           CALL "MONEY-FORMAT"
               USING
                   WS-CURRENCY
                   WS-CURRENCY-DECIMALS
                   WS-BALANCE
                   WS-DISPLAY-BALANCE.

           DISPLAY T-WHITE " ".
           DISPLAY T-BOLD T-BLUE "Account:  " WS-TARGET-ACCOUNT.
           DISPLAY T-BOLD T-BLUE "Balance:  " WS-DISPLAY-BALANCE.


       *> -------------------------------------------------------
       *> Banker: change customer information.
       *> -------------------------------------------------------
       BANKER-CHANGE-INFO.

           DISPLAY T-WHITE " ".
           DISPLAY T-WHITE "Customer account number: ".
           ACCEPT WS-TARGET-ACCOUNT.

           PERFORM VERIFY-ACCOUNT-EXISTS.

           IF WS-ACCOUNT-FOUND = "N"

               DISPLAY T-RED "Account not found."

           ELSE

               DISPLAY T-WHITE " ".
               DISPLAY T-WHITE "What to change?".
               DISPLAY T-WHITE "1. PIN".
               DISPLAY T-WHITE "2. Currency / decimals".
               DISPLAY T-WHITE "3. Contact information".
               DISPLAY T-WHITE " ".
               DISPLAY T-WHITE "Choose an option: ".
               ACCEPT WS-INFO-CHOICE.

               EVALUATE WS-INFO-CHOICE

                   WHEN 1
                       PERFORM CHANGE-CUSTOMER-PIN

                   WHEN 2
                       PERFORM CHANGE-CUSTOMER-CURRENCY

                   WHEN 3
                       PERFORM CHANGE-CUSTOMER-CONTACT

                   WHEN OTHER
                       DISPLAY T-RED "Invalid option."

               END-EVALUATE.

           *> End of BANKER-CHANGE-INFO.


       VERIFY-ACCOUNT-EXISTS.

           MOVE "N"
               TO WS-ACCOUNT-FOUND.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT ACCOUNT-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-ACCOUNT-FOUND = "Y"

               READ ACCOUNT-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       IF FILE-ACCOUNT-NUMBER =
                          WS-TARGET-ACCOUNT

                           MOVE "Y"
                               TO WS-ACCOUNT-FOUND

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.


       CHANGE-CUSTOMER-PIN.

           DISPLAY T-WHITE "New PIN (4 digits): ".
           ACCEPT WS-NEW-PIN.

           DISPLAY T-WHITE "Confirm new PIN: ".
           ACCEPT WS-NEW-PIN-CONFIRM.

           IF WS-NEW-PIN NOT = WS-NEW-PIN-CONFIRM

               DISPLAY T-RED "PINs do not match. Cancelled."

           ELSE

               PERFORM HASH-NEW-PIN

               PERFORM UPDATE-ACCOUNT-PIN

               DISPLAY T-BOLD T-BLUE "PIN updated successfully."

           END-IF.


       HASH-NEW-PIN.

           MOVE WS-NEW-PIN
               TO WS-NEW-PIN-C(1:4).

           MOVE LOW-VALUES
               TO WS-NEW-PIN-C(5:1).

           MOVE WS-SALT
               TO WS-SALT-C(1:15).

           MOVE LOW-VALUES
               TO WS-SALT-C(16:1).

           CALL "hash_pin"
               USING
                   WS-NEW-PIN-C
                   WS-SALT-C
                   WS-NEW-PIN-HASH.


       UPDATE-ACCOUNT-PIN.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT ACCOUNT-FILE.
           OPEN OUTPUT ACCOUNT-TEMP-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"

               READ ACCOUNT-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       MOVE FILE-ACCOUNT-NUMBER
                           TO TEMP-ACCOUNT-NUMBER

                       MOVE FILE-ACCOUNT-STATUS
                           TO TEMP-ACCOUNT-STATUS

                       IF FILE-ACCOUNT-NUMBER =
                          WS-TARGET-ACCOUNT

                           MOVE WS-NEW-PIN-HASH(1:64)
                               TO TEMP-PIN-HASH

                       ELSE

                           MOVE FILE-PIN-HASH
                               TO TEMP-PIN-HASH

                       END-IF

                       WRITE ACCOUNT-TEMP-RECORD

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.
           CLOSE ACCOUNT-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/accounts.tmp data/accounts.dat".


       CHANGE-CUSTOMER-CURRENCY.

           PERFORM LOAD-CUSTOMER-WALLET.

           IF WS-WALLET-FOUND = "N"

               DISPLAY T-RED "Wallet not found."

           ELSE

               DISPLAY T-WHITE "New currency (3 chars, e.g. USD): "
               ACCEPT WS-NEW-CURRENCY

               DISPLAY T-WHITE "New decimal places (0-6): "
               ACCEPT WS-NEW-DECIMALS

               MOVE WS-NEW-CURRENCY
                   TO WS-CURRENCY

               MOVE WS-NEW-DECIMALS
                   TO WS-CURRENCY-DECIMALS

               PERFORM UPDATE-WALLET-CURRENCY

               DISPLAY T-BOLD T-BLUE "Currency updated successfully."

           END-IF.


       UPDATE-WALLET-CURRENCY.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT WALLET-FILE.
           OPEN OUTPUT WALLET-TEMP-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"

               READ WALLET-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       MOVE FILE-WALLET-ACCOUNT-NUMBER
                           TO TEMP-WALLET-ACCOUNT-NUMBER

                       MOVE FILE-WALLET-BALANCE
                           TO TEMP-WALLET-BALANCE

                       IF FILE-WALLET-ACCOUNT-NUMBER =
                          WS-TARGET-ACCOUNT

                           MOVE WS-CURRENCY
                               TO TEMP-WALLET-CURRENCY

                           MOVE WS-CURRENCY-DECIMALS
                               TO TEMP-WALLET-DECIMALS

                       ELSE

                           MOVE FILE-WALLET-CURRENCY
                               TO TEMP-WALLET-CURRENCY

                           MOVE FILE-WALLET-DECIMALS
                               TO TEMP-WALLET-DECIMALS

                       END-IF

                       WRITE WALLET-TEMP-RECORD

               END-READ

           END-PERFORM.

           CLOSE WALLET-FILE.
           CLOSE WALLET-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/wallets.tmp data/wallets.dat".


       *> -------------------------------------------------------
       *> Banker: edit phone, address, zip, city, country.
       *> First name, last name, and email are admin-only.
       *> -------------------------------------------------------
       CHANGE-CUSTOMER-CONTACT.

           MOVE "LOAD"
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   WS-TARGET-ACCOUNT
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.

           IF WS-CUST-FOUND = "N"

               DISPLAY T-RED "Customer profile not found."

           ELSE

               DISPLAY T-WHITE " ".
               DISPLAY T-WHITE "1. Phone number".
               DISPLAY T-WHITE "2. Address".
               DISPLAY T-WHITE "3. Zip code".
               DISPLAY T-WHITE "4. City".
               DISPLAY T-WHITE "5. Country".
               DISPLAY T-RED   "6. Back".
               DISPLAY T-WHITE " ".
               DISPLAY T-WHITE "Choose field to change: "
               ACCEPT WS-PROFILE-CHOICE

               EVALUATE WS-PROFILE-CHOICE

                   WHEN 1
                       DISPLAY T-WHITE "New phone number: "
                       ACCEPT WS-CUST-PHONE
                       PERFORM SAVE-CUSTOMER-PROFILE
                       DISPLAY T-BOLD T-BLUE "Phone number updated."

                   WHEN 2
                       DISPLAY T-WHITE "New address: "
                       ACCEPT WS-CUST-ADDRESS
                       PERFORM SAVE-CUSTOMER-PROFILE
                       DISPLAY T-BOLD T-BLUE "Address updated."

                   WHEN 3
                       DISPLAY T-WHITE "New zip code: "
                       ACCEPT WS-CUST-ZIP
                       PERFORM SAVE-CUSTOMER-PROFILE
                       DISPLAY T-BOLD T-BLUE "Zip code updated."

                   WHEN 4
                       DISPLAY T-WHITE "New city: "
                       ACCEPT WS-CUST-CITY
                       PERFORM SAVE-CUSTOMER-PROFILE
                       DISPLAY T-BOLD T-BLUE "City updated."

                   WHEN 5
                       DISPLAY T-WHITE "New country: "
                       ACCEPT WS-CUST-COUNTRY
                       PERFORM SAVE-CUSTOMER-PROFILE
                       DISPLAY T-BOLD T-BLUE "Country updated."

                   WHEN 6
                       CONTINUE

                   WHEN OTHER
                       DISPLAY T-RED "Invalid option."

               END-EVALUATE.


       SAVE-CUSTOMER-PROFILE.

           MOVE "SAVE"
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   WS-TARGET-ACCOUNT
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.


       *> -------------------------------------------------------
       *> Banker: create a new account (identical to admin flow).
       *> -------------------------------------------------------
       BANKER-CREATE-ACCOUNT.

           DISPLAY T-WHITE " ".
           DISPLAY T-YELLOW "========================".
           DISPLAY T-YELLOW "      CREATE ACCOUNT".
           DISPLAY T-YELLOW "========================".

           DISPLAY T-WHITE "New account number (8 chars): ".
           ACCEPT WS-NEW-ACCOUNT-NUMBER.

           PERFORM CHECK-ACCOUNT-EXISTS.

           IF WS-ACCOUNT-FOUND = "Y"

               DISPLAY T-RED "Account already exists."

           ELSE

               DISPLAY T-WHITE "PIN (4 digits): "
               ACCEPT WS-NEW-PIN

               DISPLAY T-WHITE "Currency (3 chars, e.g. USD): "
               ACCEPT WS-NEW-CURRENCY

               DISPLAY T-WHITE "Decimal places (0-6): "
               ACCEPT WS-NEW-DECIMALS

               DISPLAY T-WHITE "First name: "
               ACCEPT WS-CUST-FNAME

               DISPLAY T-WHITE "Last name: "
               ACCEPT WS-CUST-LNAME

               DISPLAY T-WHITE "Phone number: "
               ACCEPT WS-CUST-PHONE

               DISPLAY T-WHITE "Email: "
               ACCEPT WS-CUST-EMAIL

               DISPLAY T-WHITE "Address: "
               ACCEPT WS-CUST-ADDRESS

               DISPLAY T-WHITE "Zip code: "
               ACCEPT WS-CUST-ZIP

               DISPLAY T-WHITE "City: "
               ACCEPT WS-CUST-CITY

               DISPLAY T-WHITE "Country: "
               ACCEPT WS-CUST-COUNTRY

               PERFORM HASH-NEW-PIN

               PERFORM WRITE-NEW-ACCOUNT

               PERFORM WRITE-NEW-WALLET

               PERFORM WRITE-NEW-CUSTOMER

               DISPLAY T-BOLD T-BLUE "Account created successfully."

           END-IF.


       CHECK-ACCOUNT-EXISTS.

           MOVE "N"
               TO WS-ACCOUNT-FOUND.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT ACCOUNT-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-ACCOUNT-FOUND = "Y"

               READ ACCOUNT-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       IF FILE-ACCOUNT-NUMBER =
                          WS-NEW-ACCOUNT-NUMBER

                           MOVE "Y"
                               TO WS-ACCOUNT-FOUND

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.


       WRITE-NEW-ACCOUNT.

           OPEN EXTEND ACCOUNT-FILE.

           MOVE WS-NEW-ACCOUNT-NUMBER
               TO FILE-ACCOUNT-NUMBER.

           MOVE WS-NEW-PIN-HASH(1:64)
               TO FILE-PIN-HASH.

           MOVE "A"
               TO FILE-ACCOUNT-STATUS.

           WRITE ACCOUNT-RECORD.

           CLOSE ACCOUNT-FILE.


       WRITE-NEW-WALLET.

           OPEN EXTEND WALLET-FILE.

           MOVE WS-NEW-ACCOUNT-NUMBER
               TO FILE-WALLET-ACCOUNT-NUMBER.

           MOVE WS-NEW-CURRENCY
               TO FILE-WALLET-CURRENCY.

           MOVE WS-NEW-DECIMALS
               TO FILE-WALLET-DECIMALS.

           MOVE 0
               TO FILE-WALLET-BALANCE.

           WRITE WALLET-RECORD.

           CLOSE WALLET-FILE.


       WRITE-NEW-CUSTOMER.

           MOVE "NEW "
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   WS-NEW-ACCOUNT-NUMBER
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.
