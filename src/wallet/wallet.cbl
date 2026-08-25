       IDENTIFICATION DIVISION.
       PROGRAM-ID. WALLET.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.

       FILE-CONTROL.

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

       *> Balance stored in smallest currency unit.
       01 WS-BALANCE
           PIC 9(18)
           VALUE 0.

       01 WS-CURRENCY
           PIC X(3)
           VALUE SPACES.

       01 WS-CURRENCY-DECIMALS
           PIC 9
           VALUE 0.

       01 WS-AMOUNT
           PIC 9(18)
           VALUE 0.

       01 WS-DISPLAY-BALANCE
           PIC X(40)
           VALUE SPACES.

       01 WS-MENU-CHOICE
           PIC 9
           VALUE 0.

       01 WS-WALLET-FOUND
           PIC X
           VALUE "N".

       01 WS-END-OF-FILE
           PIC X
           VALUE "N".

       01 WS-TRANSACTION.
           05 WS-TRANSACTION-TYPE
               PIC X(10).

           05 WS-TRANSACTION-AMOUNT
               PIC 9(18).

       *> Customer profile working-storage.
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

       LINKAGE SECTION.

       01 LK-ACCOUNT-NUMBER
           PIC X(8).

       PROCEDURE DIVISION
           USING LK-ACCOUNT-NUMBER.

           PERFORM LOAD-WALLET.

           IF WS-WALLET-FOUND = "Y"

               MOVE 0
                   TO WS-MENU-CHOICE

               PERFORM WALLET-MENU
                   UNTIL WS-MENU-CHOICE = 5

           ELSE

               DISPLAY T-RED "Wallet not found."

           END-IF.

           GOBACK.


       LOAD-WALLET.

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
                          LK-ACCOUNT-NUMBER

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


       WALLET-MENU.

           PERFORM DISPLAY-MENU.

           DISPLAY T-WHITE "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.

           EVALUATE WS-MENU-CHOICE

               WHEN 1
                   PERFORM DEPOSIT-MONEY

               WHEN 2
                   PERFORM WITHDRAW-MONEY

               WHEN 3
                   PERFORM SHOW-BALANCE

               WHEN 4
                   PERFORM MY-PROFILE

               WHEN 5
                   DISPLAY T-RED "Logging out..."

               WHEN OTHER
                   DISPLAY T-RED "Invalid option."

           END-EVALUATE.


       DISPLAY-MENU.

           DISPLAY T-WHITE " ".
           DISPLAY T-CYAN "========================".
           DISPLAY T-CYAN "       WALLET MENU".
           DISPLAY T-CYAN "========================".
           DISPLAY T-WHITE "Currency: " WS-CURRENCY.
           DISPLAY T-WHITE "Decimals: " WS-CURRENCY-DECIMALS.
           DISPLAY T-WHITE " ".
           DISPLAY T-WHITE "1. Deposit money".
           DISPLAY T-WHITE "2. Withdraw money".
           DISPLAY T-WHITE "3. Show balance".
           DISPLAY T-WHITE "4. My profile".
           DISPLAY T-RED   "5. Logout".
           DISPLAY T-WHITE " ".


       DEPOSIT-MONEY.

           MOVE 0
               TO WS-AMOUNT.

           CALL "MONEY"
               USING
                   WS-CURRENCY
                   WS-CURRENCY-DECIMALS
                   WS-AMOUNT.

           ADD WS-AMOUNT
               TO WS-BALANCE.

           MOVE "DEPOSIT"
               TO WS-TRANSACTION-TYPE.

           MOVE WS-AMOUNT
               TO WS-TRANSACTION-AMOUNT.

           PERFORM SAVE-TRANSACTION.

           PERFORM SAVE-WALLET.

           DISPLAY T-BOLD T-BLUE "Deposit successful!".

           PERFORM SHOW-BALANCE.


       WITHDRAW-MONEY.

           MOVE 0
               TO WS-AMOUNT.

           CALL "MONEY"
               USING
                   WS-CURRENCY
                   WS-CURRENCY-DECIMALS
                   WS-AMOUNT.

           IF WS-BALANCE >= WS-AMOUNT

               SUBTRACT WS-AMOUNT
                   FROM WS-BALANCE

               MOVE "WITHDRAW"
                   TO WS-TRANSACTION-TYPE

               MOVE WS-AMOUNT
                   TO WS-TRANSACTION-AMOUNT

               PERFORM SAVE-TRANSACTION

               PERFORM SAVE-WALLET

               DISPLAY T-BOLD T-BLUE "Withdrawal successful!"

               PERFORM SHOW-BALANCE

           ELSE

               DISPLAY T-RED "Withdrawal rejected!"
               DISPLAY T-RED "Insufficient balance."

           END-IF.


       SHOW-BALANCE.

           MOVE SPACES
               TO WS-DISPLAY-BALANCE.

           CALL "MONEY-FORMAT"
               USING
                   WS-CURRENCY
                   WS-CURRENCY-DECIMALS
                   WS-BALANCE
                   WS-DISPLAY-BALANCE.

           DISPLAY T-WHITE " ".
           DISPLAY T-BOLD T-BLUE "Current balance: "
               WS-DISPLAY-BALANCE.


       SAVE-TRANSACTION.

           OPEN EXTEND TRANSACTION-FILE.

           MOVE LK-ACCOUNT-NUMBER
               TO FILE-TRANSACTION-ACCOUNT.

           MOVE WS-TRANSACTION-TYPE
               TO FILE-TRANSACTION-TYPE.

           MOVE WS-CURRENCY
               TO FILE-TRANSACTION-CURRENCY.

           MOVE WS-CURRENCY-DECIMALS
               TO FILE-TRANSACTION-DECIMALS.

           MOVE WS-TRANSACTION-AMOUNT
               TO FILE-TRANSACTION-AMOUNT.

           WRITE TRANSACTION-RECORD.

           CLOSE TRANSACTION-FILE.


       SAVE-WALLET.

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
                          LK-ACCOUNT-NUMBER

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
       *> My Profile: view and edit contact information.
       *> Customer may change: phone, address, zip, city, country.
       *> -------------------------------------------------------
       MY-PROFILE.

           MOVE "LOAD"
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   LK-ACCOUNT-NUMBER
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.

           IF WS-CUST-FOUND = "N"

               DISPLAY T-RED "Profile not found."

           ELSE

               PERFORM DISPLAY-PROFILE

               DISPLAY T-WHITE " ".
               DISPLAY T-WHITE "What to change?".
               DISPLAY T-WHITE "1. Phone number".
               DISPLAY T-WHITE "2. Address".
               DISPLAY T-WHITE "3. Zip code".
               DISPLAY T-WHITE "4. City".
               DISPLAY T-WHITE "5. Country".
               DISPLAY T-RED   "6. Back".
               DISPLAY T-WHITE " ".
               DISPLAY T-WHITE "Choose an option: "
               ACCEPT WS-PROFILE-CHOICE

               EVALUATE WS-PROFILE-CHOICE

                   WHEN 1
                       DISPLAY T-WHITE "New phone number: "
                       ACCEPT WS-CUST-PHONE
                       PERFORM SAVE-PROFILE
                       DISPLAY T-BOLD T-BLUE "Phone number updated."

                   WHEN 2
                       DISPLAY T-WHITE "New address: "
                       ACCEPT WS-CUST-ADDRESS
                       PERFORM SAVE-PROFILE
                       DISPLAY T-BOLD T-BLUE "Address updated."

                   WHEN 3
                       DISPLAY T-WHITE "New zip code: "
                       ACCEPT WS-CUST-ZIP
                       PERFORM SAVE-PROFILE
                       DISPLAY T-BOLD T-BLUE "Zip code updated."

                   WHEN 4
                       DISPLAY T-WHITE "New city: "
                       ACCEPT WS-CUST-CITY
                       PERFORM SAVE-PROFILE
                       DISPLAY T-BOLD T-BLUE "City updated."

                   WHEN 5
                       DISPLAY T-WHITE "New country: "
                       ACCEPT WS-CUST-COUNTRY
                       PERFORM SAVE-PROFILE
                       DISPLAY T-BOLD T-BLUE "Country updated."

                   WHEN 6
                       CONTINUE

                   WHEN OTHER
                       DISPLAY T-RED "Invalid option."

               END-EVALUATE.


       DISPLAY-PROFILE.

           DISPLAY T-WHITE " ".
           DISPLAY T-CYAN "========================".
           DISPLAY T-CYAN "        MY PROFILE".
           DISPLAY T-CYAN "========================".
           DISPLAY T-WHITE "Account: " LK-ACCOUNT-NUMBER.
           DISPLAY T-WHITE "Name:    " WS-CUST-FNAME
                                   " " WS-CUST-LNAME.
           DISPLAY T-WHITE "Phone:   " WS-CUST-PHONE.
           DISPLAY T-WHITE "Email:   " WS-CUST-EMAIL.
           DISPLAY T-WHITE "Address: " WS-CUST-ADDRESS.
           DISPLAY T-WHITE "Zip:     " WS-CUST-ZIP.
           DISPLAY T-WHITE "City:    " WS-CUST-CITY.
           DISPLAY T-WHITE "Country: " WS-CUST-COUNTRY.


       SAVE-PROFILE.

           MOVE "SAVE"
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   LK-ACCOUNT-NUMBER
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.
