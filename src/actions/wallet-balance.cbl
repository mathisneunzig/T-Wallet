       IDENTIFICATION DIVISION.
       PROGRAM-ID. WALLET-BALANCE.

       *> Usage: wallet-balance <account_number>
       *> Output:
       *>   OK|<account>|<currency>|<decimals>|<raw_balance>|<formatted>
       *>   ERR|NOT_FOUND|Wallet not found.
       *>   ERR|USAGE|...

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT WALLET-FILE
               ASSIGN TO "data/wallets.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD WALLET-FILE.
       01 WALLET-RECORD.
           05 FILE-WALLET-ACCOUNT  PIC X(8).
           05 FILE-WALLET-CURRENCY PIC X(3).
           05 FILE-WALLET-DECIMALS PIC 9.
           05 FILE-WALLET-BALANCE  PIC 9(18).

       WORKING-STORAGE SECTION.

       01 WS-ARG-ACCOUNT    PIC X(8).
       01 WS-FOUND          PIC X VALUE "N".
       01 WS-EOF            PIC X VALUE "N".
       01 WS-FORMATTED      PIC X(40) VALUE SPACES.

       01 WS-CURRENCY       PIC X(3).
       01 WS-DECIMALS       PIC 9.
       01 WS-BALANCE        PIC 9(18).

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES
               DISPLAY "ERR|USAGE|Usage: wallet-balance <account>"
               STOP RUN
           END-IF.

           MOVE "N" TO WS-FOUND.
           MOVE "N" TO WS-EOF.

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

           MOVE SPACES TO WS-FORMATTED.
           CALL "MONEY-FORMAT" USING
               WS-CURRENCY WS-DECIMALS WS-BALANCE WS-FORMATTED.

           DISPLAY "OK|" WS-ARG-ACCOUNT "|" WS-CURRENCY "|"
               WS-DECIMALS "|" WS-BALANCE "|" WS-FORMATTED.

           STOP RUN.
