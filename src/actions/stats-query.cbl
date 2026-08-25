       IDENTIFICATION DIVISION.
       PROGRAM-ID. STATS-QUERY.

       *> Usage: stats-query
       *> Output (multi-line, Python reads directly):
       *>   OK
       *>   TXN|<account>|<type>|<currency>|<decimals>|<amount>|<timestamp>
       *>   TXN|...
       *> Error:
       *>   ERR|CANNOT_READ|Cannot open transactions file.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO "data/transactions.dat"
               ORGANIZATION IS LINE SEQUENTIAL
               FILE STATUS IS WS-FILE-STATUS.

       DATA DIVISION.
       FILE SECTION.

       FD TRANSACTION-FILE.
       01 TRANSACTION-RECORD.
           05 FILE-TXN-ACCOUNT   PIC X(8).
           05 FILE-TXN-TYPE      PIC X(10).
           05 FILE-TXN-CURRENCY  PIC X(3).
           05 FILE-TXN-DECIMALS  PIC 9.
           05 FILE-TXN-AMOUNT    PIC 9(18).
           05 FILE-TXN-TIMESTAMP PIC X(19).

       WORKING-STORAGE SECTION.

       01 WS-EOF            PIC X VALUE "N".
       01 WS-FILE-STATUS    PIC XX.

       PROCEDURE DIVISION.

           OPEN INPUT TRANSACTION-FILE.
           IF WS-FILE-STATUS NOT = "00"
               DISPLAY "ERR|CANNOT_READ|Cannot open transactions file."
               STOP RUN
           END-IF.

           DISPLAY "OK".

           MOVE "N" TO WS-EOF.
           PERFORM UNTIL WS-EOF = "Y"
               READ TRANSACTION-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       DISPLAY "TXN|"
                           FILE-TXN-ACCOUNT   "|"
                           FILE-TXN-TYPE      "|"
                           FILE-TXN-CURRENCY  "|"
                           FILE-TXN-DECIMALS  "|"
                           FILE-TXN-AMOUNT    "|"
                           FILE-TXN-TIMESTAMP
               END-READ
           END-PERFORM.

           CLOSE TRANSACTION-FILE.
           STOP RUN.
