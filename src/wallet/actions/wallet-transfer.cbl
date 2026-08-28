       IDENTIFICATION DIVISION.
       PROGRAM-ID. WALLET-TRANSFER.

       *> Usage: wallet-transfer <from_account> <to_account> <whole> <fraction>
       *>   Transfers money between two wallets of the same currency.
       *>   A 0.5% fee (min 1 raw unit) is deducted from the sender via
       *>   the external FORTRAN program bin/transfer_fee.
       *> Output:
       *>   OK|<from>|<to>|<from_new_raw>|<to_new_raw>|<from_formatted>|<to_formatted>|<fee_raw>
       *>   ERR|NOT_FOUND|...
       *>   ERR|CURRENCY_MISMATCH|Wallets use different currencies.
       *>   ERR|INSUFFICIENT|Insufficient balance.
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
           SELECT FEE-FILE
               ASSIGN TO "data/transfer_fee.tmp"
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

       FD FEE-FILE.
       01 FEE-RECORD             PIC X(20).

       WORKING-STORAGE SECTION.

       01 WS-ARG-FROM       PIC X(8).
       01 WS-ARG-TO         PIC X(8).
       01 WS-ARG-WHOLE      PIC 9(18).
       01 WS-ARG-FRACTION   PIC 9(6).
       01 WS-ARG-WHOLE-STR  PIC X(18).
       01 WS-ARG-FRAC-STR   PIC X(6).

       01 WS-FROM-FOUND     PIC X VALUE "N".
       01 WS-TO-FOUND       PIC X VALUE "N".
       01 WS-EOF            PIC X VALUE "N".

       01 WS-FROM-CURRENCY  PIC X(3).
       01 WS-FROM-DECIMALS  PIC 9.
       01 WS-FROM-BALANCE   PIC 9(18).

       01 WS-TO-CURRENCY    PIC X(3).
       01 WS-TO-DECIMALS    PIC 9.
       01 WS-TO-BALANCE     PIC 9(18).

       01 WS-AMOUNT         PIC 9(18) VALUE 0.
       01 WS-MULTIPLIER     PIC 9(7)  VALUE 1.
       01 WS-FEE-RAW        PIC 9(18) VALUE 0.
       01 WS-TOTAL-DEBIT    PIC 9(18) VALUE 0.

       01 WS-FROM-FORMATTED PIC X(40) VALUE SPACES.
       01 WS-TO-FORMATTED   PIC X(40) VALUE SPACES.

       01 WS-CURRENT-DATE   PIC X(21).
       01 WS-TIMESTAMP      PIC X(19).

       *> For building the system command to call transfer_fee
       01 WS-AMOUNT-STR     PIC X(18).
       01 WS-DEC-STR        PIC X(1).
       01 WS-SYSTEM-CMD     PIC X(200).
       01 WS-FEE-STR        PIC X(20).

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-FROM      FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-TO        FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-WHOLE-STR FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-FRAC-STR  FROM ARGUMENT-VALUE.

           IF WS-ARG-FROM = SPACES
           OR WS-ARG-TO   = SPACES
           OR WS-ARG-WHOLE-STR = SPACES
               DISPLAY "ERR|USAGE|"
                   "Usage: wallet-transfer <from> <to> <whole> <fraction>"
               STOP RUN
           END-IF.

           MOVE FUNCTION NUMVAL(WS-ARG-WHOLE-STR) TO WS-ARG-WHOLE.
           IF WS-ARG-FRAC-STR NOT = SPACES
               MOVE FUNCTION NUMVAL(WS-ARG-FRAC-STR) TO WS-ARG-FRACTION
           ELSE
               MOVE 0 TO WS-ARG-FRACTION
           END-IF.

           *> ── Pass 1: load from-wallet ──────────────────────────────────────
           MOVE "N" TO WS-FROM-FOUND WS-EOF.
           OPEN INPUT WALLET-FILE.
           PERFORM UNTIL WS-EOF = "Y" OR WS-FROM-FOUND = "Y"
               READ WALLET-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-WALLET-ACCOUNT = WS-ARG-FROM
                           MOVE "Y"                  TO WS-FROM-FOUND
                           MOVE FILE-WALLET-CURRENCY TO WS-FROM-CURRENCY
                           MOVE FILE-WALLET-DECIMALS TO WS-FROM-DECIMALS
                           MOVE FILE-WALLET-BALANCE  TO WS-FROM-BALANCE
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE WALLET-FILE.

           IF WS-FROM-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Source wallet not found."
               STOP RUN
           END-IF.

           *> ── Pass 2: load to-wallet ────────────────────────────────────────
           MOVE "N" TO WS-TO-FOUND WS-EOF.
           OPEN INPUT WALLET-FILE.
           PERFORM UNTIL WS-EOF = "Y" OR WS-TO-FOUND = "Y"
               READ WALLET-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-WALLET-ACCOUNT = WS-ARG-TO
                           MOVE "Y"                  TO WS-TO-FOUND
                           MOVE FILE-WALLET-CURRENCY TO WS-TO-CURRENCY
                           MOVE FILE-WALLET-DECIMALS TO WS-TO-DECIMALS
                           MOVE FILE-WALLET-BALANCE  TO WS-TO-BALANCE
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE WALLET-FILE.

           IF WS-TO-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Destination wallet not found."
               STOP RUN
           END-IF.

           *> ── Currency check ───────────────────────────────────────────────
           IF WS-FROM-CURRENCY NOT = WS-TO-CURRENCY
               DISPLAY "ERR|CURRENCY_MISMATCH|"
                   "Wallets use different currencies."
               STOP RUN
           END-IF.

           *> ── Compute transfer amount ───────────────────────────────────────
           EVALUATE WS-FROM-DECIMALS
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

           *> ── Call FORTRAN fee calculator ──────────────────────────────────
           *> Build: ./bin/transfer_fee <amount> <decimals> > data/transfer_fee.tmp
           MOVE FUNCTION TRIM(FUNCTION NUMVAL-C(
               FUNCTION TRIM(WS-AMOUNT)))
               TO WS-AMOUNT-STR.
           MOVE FUNCTION TRIM(WS-AMOUNT) TO WS-AMOUNT-STR.
           MOVE WS-FROM-DECIMALS TO WS-DEC-STR.

           STRING
               "./bin/transfer_fee "   DELIMITED SIZE
               FUNCTION TRIM(WS-AMOUNT-STR) DELIMITED SIZE
               " "                     DELIMITED SIZE
               WS-DEC-STR              DELIMITED SIZE
               " > data/transfer_fee.tmp"
                                       DELIMITED SIZE
               INTO WS-SYSTEM-CMD.

           CALL "system" USING WS-SYSTEM-CMD.

           MOVE 1 TO WS-FEE-RAW.
           OPEN INPUT FEE-FILE.
           READ FEE-FILE INTO WS-FEE-STR
               AT END MOVE SPACES TO WS-FEE-STR
           END-READ.
           CLOSE FEE-FILE.
           CALL "system" USING "rm -f data/transfer_fee.tmp".

           IF WS-FEE-STR NOT = SPACES
               MOVE FUNCTION NUMVAL(WS-FEE-STR) TO WS-FEE-RAW
           ELSE
               MOVE 1 TO WS-FEE-RAW
           END-IF.

           *> ── Sufficient balance check (amount + fee) ───────────────────────
           COMPUTE WS-TOTAL-DEBIT = WS-AMOUNT + WS-FEE-RAW.

           IF WS-FROM-BALANCE < WS-TOTAL-DEBIT
               DISPLAY "ERR|INSUFFICIENT|Insufficient balance."
               STOP RUN
           END-IF.

           *> ── Apply transfer ───────────────────────────────────────────────
           SUBTRACT WS-TOTAL-DEBIT FROM WS-FROM-BALANCE.
           ADD WS-AMOUNT TO WS-TO-BALANCE.

           *> ── Save both wallets in one pass ────────────────────────────────
           PERFORM SAVE-WALLETS.

           *> ── Record transactions ──────────────────────────────────────────
           PERFORM WRITE-TIMESTAMP.
           PERFORM SAVE-TXN-OUT.
           PERFORM SAVE-TXN-IN.

           *> ── Format balances ──────────────────────────────────────────────
           MOVE SPACES TO WS-FROM-FORMATTED.
           CALL "MONEY-FORMAT" USING
               WS-FROM-CURRENCY WS-FROM-DECIMALS
               WS-FROM-BALANCE WS-FROM-FORMATTED.

           MOVE SPACES TO WS-TO-FORMATTED.
           CALL "MONEY-FORMAT" USING
               WS-TO-CURRENCY WS-TO-DECIMALS
               WS-TO-BALANCE WS-TO-FORMATTED.

           DISPLAY "OK|" WS-ARG-FROM "|" WS-ARG-TO "|"
               WS-FROM-BALANCE "|" WS-TO-BALANCE "|"
               WS-FROM-FORMATTED "|" WS-TO-FORMATTED "|"
               WS-FEE-RAW.
           STOP RUN.


       SAVE-WALLETS.
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
                       EVALUATE TRUE
                           WHEN FILE-WALLET-ACCOUNT = WS-ARG-FROM
                               MOVE WS-FROM-BALANCE TO TEMP-WALLET-BALANCE
                           WHEN FILE-WALLET-ACCOUNT = WS-ARG-TO
                               MOVE WS-TO-BALANCE   TO TEMP-WALLET-BALANCE
                           WHEN OTHER
                               MOVE FILE-WALLET-BALANCE
                                   TO TEMP-WALLET-BALANCE
                       END-EVALUATE
                       WRITE WALLET-TEMP-RECORD
               END-READ
           END-PERFORM.
           CLOSE WALLET-FILE WALLET-TEMP-FILE.
           CALL "system" USING "mv data/wallets.tmp data/wallets.dat".


       WRITE-TIMESTAMP.
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


       SAVE-TXN-OUT.
           OPEN EXTEND TRANSACTION-FILE.
           MOVE WS-ARG-FROM       TO FILE-TXN-ACCOUNT.
           MOVE "XFER-OUT"        TO FILE-TXN-TYPE.
           MOVE WS-FROM-CURRENCY  TO FILE-TXN-CURRENCY.
           MOVE WS-FROM-DECIMALS  TO FILE-TXN-DECIMALS.
           MOVE WS-TOTAL-DEBIT    TO FILE-TXN-AMOUNT.
           MOVE WS-TIMESTAMP      TO FILE-TXN-TIMESTAMP.
           WRITE TRANSACTION-RECORD.
           CLOSE TRANSACTION-FILE.


       SAVE-TXN-IN.
           OPEN EXTEND TRANSACTION-FILE.
           MOVE WS-ARG-TO         TO FILE-TXN-ACCOUNT.
           MOVE "XFER-IN"         TO FILE-TXN-TYPE.
           MOVE WS-TO-CURRENCY    TO FILE-TXN-CURRENCY.
           MOVE WS-TO-DECIMALS    TO FILE-TXN-DECIMALS.
           MOVE WS-AMOUNT         TO FILE-TXN-AMOUNT.
           MOVE WS-TIMESTAMP      TO FILE-TXN-TIMESTAMP.
           WRITE TRANSACTION-RECORD.
           CLOSE TRANSACTION-FILE.
