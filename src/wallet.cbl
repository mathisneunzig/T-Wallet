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

       *> Balance in smallest currency unit
       01 WS-BALANCE PIC 9(18) VALUE 0.

       *> Currency configuration
       01 WS-CURRENCY PIC X(3) VALUE SPACES.
       01 WS-CURRENCY-DECIMALS PIC 9 VALUE 0.

       *> User amount
       01 WS-AMOUNT-MAJOR PIC 9(15) VALUE 0.
       01 WS-AMOUNT-MINOR PIC 9(6) VALUE 0.

       *> Calculated amount in smallest unit
       01 WS-AMOUNT PIC 9(18) VALUE 0.

       *> Helper for decimal conversion
       01 WS-MULTIPLIER PIC 9(6) VALUE 1.

       *> Display helpers
       01 WS-DISPLAY-MAJOR PIC 9(18) VALUE 0.
       01 WS-DISPLAY-MINOR PIC 9(6) VALUE 0.

       01 WS-MENU-CHOICE PIC 9 VALUE 0.

       01 WS-WALLET-FOUND PIC X VALUE "N".
       01 WS-END-OF-FILE PIC X VALUE "N".

       01 WS-TRANSACTION.
           05 WS-TRANSACTION-TYPE   PIC X(10).
           05 WS-TRANSACTION-AMOUNT PIC 9(18).

       LINKAGE SECTION.

       01 LK-ACCOUNT-NUMBER PIC X(8).

       PROCEDURE DIVISION
           USING LK-ACCOUNT-NUMBER.

           PERFORM LOAD-WALLET

           IF WS-WALLET-FOUND = "Y"

               PERFORM WALLET-MENU
                   UNTIL WS-MENU-CHOICE = 4

           ELSE

               DISPLAY "Wallet not found."

           END-IF

           GOBACK.


       LOAD-WALLET.

           MOVE "N" TO WS-WALLET-FOUND.
           MOVE "N" TO WS-END-OF-FILE.

           OPEN INPUT WALLET-FILE

           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-WALLET-FOUND = "Y"

               READ WALLET-FILE

                   AT END
                       MOVE "Y" TO WS-END-OF-FILE

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

           END-PERFORM

           CLOSE WALLET-FILE.


       WALLET-MENU.

           PERFORM DISPLAY-MENU

           PERFORM GET-MENU-CHOICE

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


       GET-MENU-CHOICE.

           DISPLAY "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.


       DEPOSIT-MONEY.

           PERFORM GET-AMOUNT.

           ADD WS-AMOUNT TO WS-BALANCE.

           MOVE "DEPOSIT"
               TO WS-TRANSACTION-TYPE.

           MOVE WS-AMOUNT
               TO WS-TRANSACTION-AMOUNT.

           PERFORM SAVE-TRANSACTION.

           PERFORM SAVE-WALLET.

           DISPLAY "Deposit successful!"

           PERFORM SHOW-BALANCE.


       WITHDRAW-MONEY.

           PERFORM GET-AMOUNT.

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


       GET-AMOUNT.

           MOVE 0 TO WS-AMOUNT-MAJOR.
           MOVE 0 TO WS-AMOUNT-MINOR.
           MOVE 0 TO WS-AMOUNT.
           MOVE 1 TO WS-MULTIPLIER.

           DISPLAY " ".

           DISPLAY "Amount in "
               WS-CURRENCY.

           DISPLAY "Whole amount: ".
           ACCEPT WS-AMOUNT-MAJOR.

           IF WS-CURRENCY-DECIMALS > 0
               DISPLAY "Fractional amount: "
               ACCEPT WS-AMOUNT-MINOR
           END-IF

           PERFORM BUILD-MULTIPLIER

           COMPUTE WS-AMOUNT =
               WS-AMOUNT-MAJOR * WS-MULTIPLIER
               + WS-AMOUNT-MINOR.


       BUILD-MULTIPLIER.

           MOVE 1 TO WS-MULTIPLIER

           EVALUATE WS-CURRENCY-DECIMALS

               WHEN 0
                   MOVE 1 TO WS-MULTIPLIER

               WHEN 1
                   MOVE 10 TO WS-MULTIPLIER

               WHEN 2
                   MOVE 100 TO WS-MULTIPLIER

               WHEN 3
                   MOVE 1000 TO WS-MULTIPLIER

               WHEN 4
                   MOVE 10000 TO WS-MULTIPLIER

               WHEN 5
                   MOVE 100000 TO WS-MULTIPLIER

               WHEN 6
                   MOVE 1000000 TO WS-MULTIPLIER

               WHEN OTHER
                   MOVE 1 TO WS-MULTIPLIER

           END-EVALUATE.


       SHOW-BALANCE.

           PERFORM BUILD-MULTIPLIER

           DIVIDE WS-BALANCE
               BY WS-MULTIPLIER
               GIVING WS-DISPLAY-MAJOR
               REMAINDER WS-DISPLAY-MINOR

           DISPLAY " "

           IF WS-CURRENCY-DECIMALS = 0

               DISPLAY "Current balance: "
                   WS-DISPLAY-MAJOR
                   " "
                   WS-CURRENCY

           ELSE

               DISPLAY "Current balance: "
                   WS-DISPLAY-MAJOR
                   "."

               DISPLAY "Fractional units: "
                   WS-DISPLAY-MINOR
                   " "
                   WS-CURRENCY

           END-IF.


       SAVE-TRANSACTION.

           OPEN EXTEND TRANSACTION-FILE

           MOVE LK-ACCOUNT-NUMBER
               TO FILE-TRANSACTION-ACCOUNT

           MOVE WS-TRANSACTION-TYPE
               TO FILE-TRANSACTION-TYPE

           MOVE WS-CURRENCY
               TO FILE-TRANSACTION-CURRENCY

           MOVE WS-CURRENCY-DECIMALS
               TO FILE-TRANSACTION-DECIMALS

           MOVE WS-TRANSACTION-AMOUNT
               TO FILE-TRANSACTION-AMOUNT

           WRITE TRANSACTION-RECORD

           CLOSE TRANSACTION-FILE.


       SAVE-WALLET.

           MOVE "N" TO WS-END-OF-FILE

           OPEN INPUT WALLET-FILE

           OPEN OUTPUT WALLET-TEMP-FILE

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

           END-PERFORM

           CLOSE WALLET-FILE

           CLOSE WALLET-TEMP-FILE

           CALL "system"
               USING
               "mv data/wallets.tmp data/wallets.dat".
