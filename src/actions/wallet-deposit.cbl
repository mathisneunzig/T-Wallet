       IDENTIFICATION DIVISION.
       PROGRAM-ID. WALLET-DEPOSIT.

       *> Usage: wallet-deposit <account> <whole_amount> <fraction>
       *>   whole_amount : major currency units (e.g. 10 for $10)
       *>   fraction     : minor units (e.g. 50 for .50); ignored when decimals=0
       *> Output:
       *>   OK|<account>|<new_balance_raw>|<new_balance_formatted>
       *>   ERR|NOT_FOUND|...
       *>   ERR|USAGE|...

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
           05 FILE-WALLET-ACCOUNT  PIC X(8).
           05 FILE-WALLET-CURRENCY PIC X(3).
           05 FILE-WALLET-DECIMALS PIC 9.
           05 FILE-WALLET-BALANCE  PIC 9(18).

       FD WALLET-TEMP-FILE.
       01 WALLET-TEMP-RECORD.
           05 TEMP-WALLET-ACCOUNT  PIC X(8).
           05 TEMP-WALLET-CURRENCY PIC X(3).
           05 TEMP-WALLET-DECIMALS PIC 9.
           05 TEMP-WALLET-BALANCE  PIC 9(18).

       FD TRANSACTION-FILE.
       01 TRANSACTION-RECORD.
           05 FILE-TXN-ACCOUNT   PIC X(8).
           05 FILE-TXN-TYPE      PIC X(10).
           05 FILE-TXN-CURRENCY  PIC X(3).
           05 FILE-TXN-DECIMALS  PIC 9.
           05 FILE-TXN-AMOUNT    PIC 9(18).
           05 FILE-TXN-TIMESTAMP PIC X(19).

       WORKING-STORAGE SECTION.

       01 WS-ARG-ACCOUNT    PIC X(8).
       01 WS-ARG-WHOLE      PIC 9(18).
       01 WS-ARG-FRACTION   PIC 9(6).
       01 WS-ARG-WHOLE-STR  PIC X(18).
       01 WS-ARG-FRAC-STR   PIC X(6).

       01 WS-FOUND          PIC X VALUE "N".
       01 WS-EOF            PIC X VALUE "N".
       01 WS-CURRENCY       PIC X(3).
       01 WS-DECIMALS       PIC 9.
       01 WS-BALANCE        PIC 9(18).
       01 WS-AMOUNT         PIC 9(18).
       01 WS-MULTIPLIER     PIC 9(7) VALUE 1.
       01 WS-FORMATTED      PIC X(40) VALUE SPACES.
       01 WS-CURRENT-DATE   PIC X(21).
       01 WS-TIMESTAMP      PIC X(19).

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-WHOLE-STR FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-FRAC-STR FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES OR WS-ARG-WHOLE-STR = SPACES
               DISPLAY "ERR|USAGE|"
                   "Usage: wallet-deposit <account> <whole> <fraction>"
               STOP RUN
           END-IF.

           MOVE FUNCTION NUMVAL(WS-ARG-WHOLE-STR) TO WS-ARG-WHOLE.
           IF WS-ARG-FRAC-STR NOT = SPACES
               MOVE FUNCTION NUMVAL(WS-ARG-FRAC-STR) TO WS-ARG-FRACTION
           ELSE
               MOVE 0 TO WS-ARG-FRACTION
           END-IF.

           MOVE "N" TO WS-FOUND WS-EOF.
           OPEN INPUT WALLET-FILE.
           PERFORM UNTIL WS-EOF = "Y" OR WS-FOUND = "Y"
               READ WALLET-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-WALLET-ACCOUNT = WS-ARG-ACCOUNT
                           MOVE "Y"                  TO WS-FOUND
                           MOVE FILE-WALLET-CURRENCY TO WS-CURRENCY
                           MOVE FILE-WALLET-DECIMALS TO WS-DECIMALS
                           MOVE FILE-WALLET-BALANCE  TO WS-BALANCE
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE WALLET-FILE.

           IF WS-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Wallet not found."
               STOP RUN
           END-IF.

           EVALUATE WS-DECIMALS
               WHEN 0  MOVE 1       TO WS-MULTIPLIER
               WHEN 1  MOVE 10      TO WS-MULTIPLIER
               WHEN 2  MOVE 100     TO WS-MULTIPLIER
               WHEN 3  MOVE 1000    TO WS-MULTIPLIER
               WHEN 4  MOVE 10000   TO WS-MULTIPLIER
               WHEN 5  MOVE 100000  TO WS-MULTIPLIER
               WHEN 6  MOVE 1000000 TO WS-MULTIPLIER
               WHEN OTHER MOVE 1    TO WS-MULTIPLIER
           END-EVALUATE.

           COMPUTE WS-AMOUNT =
               WS-ARG-WHOLE * WS-MULTIPLIER + WS-ARG-FRACTION.

           ADD WS-AMOUNT TO WS-BALANCE.

           PERFORM SAVE-WALLET.
           PERFORM SAVE-TRANSACTION.

           MOVE SPACES TO WS-FORMATTED.
           CALL "MONEY-FORMAT" USING
               WS-CURRENCY WS-DECIMALS WS-BALANCE WS-FORMATTED.

           DISPLAY "OK|" WS-ARG-ACCOUNT "|"
               WS-BALANCE "|" WS-FORMATTED.
           STOP RUN.


       SAVE-WALLET.
           MOVE "N" TO WS-EOF.
           OPEN INPUT WALLET-FILE.
           OPEN OUTPUT WALLET-TEMP-FILE.
           PERFORM UNTIL WS-EOF = "Y"
               READ WALLET-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       MOVE FILE-WALLET-ACCOUNT  TO TEMP-WALLET-ACCOUNT
                       MOVE FILE-WALLET-CURRENCY TO TEMP-WALLET-CURRENCY
                       MOVE FILE-WALLET-DECIMALS TO TEMP-WALLET-DECIMALS
                       IF FILE-WALLET-ACCOUNT = WS-ARG-ACCOUNT
                           MOVE WS-BALANCE TO TEMP-WALLET-BALANCE
                       ELSE
                           MOVE FILE-WALLET-BALANCE
                               TO TEMP-WALLET-BALANCE
                       END-IF
                       WRITE WALLET-TEMP-RECORD
               END-READ
           END-PERFORM.
           CLOSE WALLET-FILE WALLET-TEMP-FILE.
           CALL "system" USING
               "mv data/wallets.tmp data/wallets.dat".


       SAVE-TRANSACTION.
           OPEN EXTEND TRANSACTION-FILE.
           MOVE WS-ARG-ACCOUNT TO FILE-TXN-ACCOUNT.
           MOVE "DEPOSIT"      TO FILE-TXN-TYPE.
           MOVE WS-CURRENCY    TO FILE-TXN-CURRENCY.
           MOVE WS-DECIMALS    TO FILE-TXN-DECIMALS.
           MOVE WS-AMOUNT      TO FILE-TXN-AMOUNT.
           MOVE FUNCTION CURRENT-DATE TO WS-CURRENT-DATE.
           MOVE WS-CURRENT-DATE(1:4)  TO WS-TIMESTAMP(1:4).
           MOVE "-"                   TO WS-TIMESTAMP(5:1).
           MOVE WS-CURRENT-DATE(5:2)  TO WS-TIMESTAMP(6:2).
           MOVE "-"                   TO WS-TIMESTAMP(8:1).
           MOVE WS-CURRENT-DATE(7:2)  TO WS-TIMESTAMP(9:2).
           MOVE " "                   TO WS-TIMESTAMP(11:1).
           MOVE WS-CURRENT-DATE(9:2)  TO WS-TIMESTAMP(12:2).
           MOVE ":"                   TO WS-TIMESTAMP(14:1).
           MOVE WS-CURRENT-DATE(11:2) TO WS-TIMESTAMP(15:2).
           MOVE ":"                   TO WS-TIMESTAMP(17:1).
           MOVE WS-CURRENT-DATE(13:2) TO WS-TIMESTAMP(18:2).
           MOVE WS-TIMESTAMP          TO FILE-TXN-TIMESTAMP.
           WRITE TRANSACTION-RECORD.
           CLOSE TRANSACTION-FILE.
