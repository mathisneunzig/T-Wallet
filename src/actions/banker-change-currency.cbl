       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKER-CHANGE-CURRENCY.

       *> Usage: banker-change-currency <account> <currency> <decimals>
       *> Output:
       *>   OK|<account>|<currency>|<decimals>
       *>   ERR|NOT_FOUND|Wallet not found.
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

       WORKING-STORAGE SECTION.

       01 WS-ARG-ACCOUNT   PIC X(8).
       01 WS-ARG-CURRENCY  PIC X(3).
       01 WS-ARG-DECIMALS  PIC X(1).
       01 WS-DECIMALS-NUM  PIC 9.
       01 WS-FOUND         PIC X VALUE "N".
       01 WS-EOF           PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT  FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-CURRENCY FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-DECIMALS FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES OR WS-ARG-CURRENCY = SPACES
               DISPLAY "ERR|USAGE|"
                   "Usage: banker-change-currency "
                   "<account> <currency> <decimals>"
               STOP RUN
           END-IF.

           MOVE FUNCTION NUMVAL(WS-ARG-DECIMALS) TO WS-DECIMALS-NUM.

           MOVE "N" TO WS-FOUND WS-EOF.
           OPEN INPUT WALLET-FILE.
           OPEN OUTPUT WALLET-TEMP-FILE.

           PERFORM UNTIL WS-EOF = "Y"
               READ WALLET-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       MOVE FILE-WALLET-ACCOUNT TO TEMP-WALLET-ACCOUNT
                       MOVE FILE-WALLET-BALANCE TO TEMP-WALLET-BALANCE
                       IF FILE-WALLET-ACCOUNT = WS-ARG-ACCOUNT
                           MOVE WS-ARG-CURRENCY TO TEMP-WALLET-CURRENCY
                           MOVE WS-DECIMALS-NUM TO TEMP-WALLET-DECIMALS
                           MOVE "Y" TO WS-FOUND
                       ELSE
                           MOVE FILE-WALLET-CURRENCY TO TEMP-WALLET-CURRENCY
                           MOVE FILE-WALLET-DECIMALS TO TEMP-WALLET-DECIMALS
                       END-IF
                       WRITE WALLET-TEMP-RECORD
               END-READ
           END-PERFORM.

           CLOSE WALLET-FILE WALLET-TEMP-FILE.
           CALL "system" USING
               "mv data/wallets.tmp data/wallets.dat".

           IF WS-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Wallet not found."
           ELSE
               DISPLAY "OK|" WS-ARG-ACCOUNT "|"
                   WS-ARG-CURRENCY "|" WS-DECIMALS-NUM
           END-IF.

           STOP RUN.
