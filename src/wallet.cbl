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
                   UNTIL WS-MENU-CHOICE = 4

           ELSE

               DISPLAY "Wallet not found."

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

           DISPLAY "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.

           EVALUATE WS-MENU-CHOICE

               WHEN 1
                   PERFORM DEPOSIT-MONEY

               WHEN 2
                   PERFORM WITHDRAW-MONEY

               WHEN 3
                   PERFORM SHOW-BALANCE

               WHEN 4
                   DISPLAY "Logging out..."

               WHEN OTHER
                   DISPLAY "Invalid option."

           END-EVALUATE.


       DISPLAY-MENU.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "       WALLET MENU".
           DISPLAY "========================".
           DISPLAY "Currency: " WS-CURRENCY.
           DISPLAY "Decimals: " WS-CURRENCY-DECIMALS.
           DISPLAY " ".
           DISPLAY "1. Deposit money".
           DISPLAY "2. Withdraw money".
           DISPLAY "3. Show balance".
           DISPLAY "4. Logout".
           DISPLAY " ".


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

           DISPLAY "Deposit successful!".

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

               DISPLAY "Withdrawal successful!"

               PERFORM SHOW-BALANCE

           ELSE

               DISPLAY "Withdrawal rejected!"
               DISPLAY "Insufficient balance."

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

           DISPLAY " ".
           DISPLAY "Current balance: "
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
                   