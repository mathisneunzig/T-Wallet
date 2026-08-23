       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMIN-DELETE-ACCOUNT.

       *> Usage: admin-delete-account <account>
       *> Output:
       *>   OK|<account>
       *>   ERR|NOT_FOUND|Account not found.
       *>   ERR|USAGE|...

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
           SELECT CUSTOMER-FILE
               ASSIGN TO "data/customers.dat"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT CUSTOMER-TEMP-FILE
               ASSIGN TO "data/customers.tmp"
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

       FD CUSTOMER-FILE.
       01 CUSTOMER-RECORD.
           05 FILE-CUST-ACCOUNT PIC X(8).
           05 FILE-CUST-FNAME   PIC X(30).
           05 FILE-CUST-LNAME   PIC X(30).
           05 FILE-CUST-PHONE   PIC X(20).
           05 FILE-CUST-EMAIL   PIC X(50).
           05 FILE-CUST-ADDRESS PIC X(50).
           05 FILE-CUST-ZIP     PIC X(10).
           05 FILE-CUST-CITY    PIC X(30).
           05 FILE-CUST-COUNTRY PIC X(30).

       FD CUSTOMER-TEMP-FILE.
       01 CUSTOMER-TEMP-RECORD.
           05 TEMP-CUST-ACCOUNT PIC X(8).
           05 TEMP-CUST-FNAME   PIC X(30).
           05 TEMP-CUST-LNAME   PIC X(30).
           05 TEMP-CUST-PHONE   PIC X(20).
           05 TEMP-CUST-EMAIL   PIC X(50).
           05 TEMP-CUST-ADDRESS PIC X(50).
           05 TEMP-CUST-ZIP     PIC X(10).
           05 TEMP-CUST-CITY    PIC X(30).
           05 TEMP-CUST-COUNTRY PIC X(30).

       WORKING-STORAGE SECTION.

       01 WS-ARG-ACCOUNT PIC X(8).
       01 WS-FOUND       PIC X VALUE "N".
       01 WS-EOF         PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES
               DISPLAY "ERR|USAGE|Usage: admin-delete-account <account>"
               STOP RUN
           END-IF.

           *> Verify exists.
           MOVE "N" TO WS-FOUND WS-EOF.
           OPEN INPUT ACCOUNT-FILE.
           PERFORM UNTIL WS-EOF = "Y" OR WS-FOUND = "Y"
               READ ACCOUNT-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-ACCOUNT-NUMBER = WS-ARG-ACCOUNT
                           MOVE "Y" TO WS-FOUND
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE ACCOUNT-FILE.

           IF WS-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Account not found."
               STOP RUN
           END-IF.

           PERFORM REMOVE-ACCOUNT.
           PERFORM REMOVE-WALLET.
           PERFORM REMOVE-CUSTOMER.

           DISPLAY "OK|" WS-ARG-ACCOUNT.
           STOP RUN.


       REMOVE-ACCOUNT.
           MOVE "N" TO WS-EOF.
           OPEN INPUT ACCOUNT-FILE.
           OPEN OUTPUT ACCOUNT-TEMP-FILE.
           PERFORM UNTIL WS-EOF = "Y"
               READ ACCOUNT-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-ACCOUNT-NUMBER NOT = WS-ARG-ACCOUNT
                           MOVE FILE-ACCOUNT-NUMBER TO TEMP-ACCOUNT-NUMBER
                           MOVE FILE-PIN-HASH       TO TEMP-PIN-HASH
                           MOVE FILE-ACCOUNT-STATUS TO TEMP-ACCOUNT-STATUS
                           WRITE ACCOUNT-TEMP-RECORD
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE ACCOUNT-FILE ACCOUNT-TEMP-FILE.
           CALL "system" USING
               "mv data/accounts.tmp data/accounts.dat".


       REMOVE-WALLET.
           MOVE "N" TO WS-EOF.
           OPEN INPUT WALLET-FILE.
           OPEN OUTPUT WALLET-TEMP-FILE.
           PERFORM UNTIL WS-EOF = "Y"
               READ WALLET-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-WALLET-ACCOUNT NOT = WS-ARG-ACCOUNT
                           MOVE FILE-WALLET-ACCOUNT  TO TEMP-WALLET-ACCOUNT
                           MOVE FILE-WALLET-CURRENCY TO TEMP-WALLET-CURRENCY
                           MOVE FILE-WALLET-DECIMALS TO TEMP-WALLET-DECIMALS
                           MOVE FILE-WALLET-BALANCE  TO TEMP-WALLET-BALANCE
                           WRITE WALLET-TEMP-RECORD
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE WALLET-FILE WALLET-TEMP-FILE.
           CALL "system" USING
               "mv data/wallets.tmp data/wallets.dat".


       REMOVE-CUSTOMER.
           MOVE "N" TO WS-EOF.
           OPEN INPUT CUSTOMER-FILE.
           OPEN OUTPUT CUSTOMER-TEMP-FILE.
           PERFORM UNTIL WS-EOF = "Y"
               READ CUSTOMER-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-CUST-ACCOUNT NOT = WS-ARG-ACCOUNT
                           MOVE FILE-CUST-ACCOUNT TO TEMP-CUST-ACCOUNT
                           MOVE FILE-CUST-FNAME   TO TEMP-CUST-FNAME
                           MOVE FILE-CUST-LNAME   TO TEMP-CUST-LNAME
                           MOVE FILE-CUST-PHONE   TO TEMP-CUST-PHONE
                           MOVE FILE-CUST-EMAIL   TO TEMP-CUST-EMAIL
                           MOVE FILE-CUST-ADDRESS TO TEMP-CUST-ADDRESS
                           MOVE FILE-CUST-ZIP     TO TEMP-CUST-ZIP
                           MOVE FILE-CUST-CITY    TO TEMP-CUST-CITY
                           MOVE FILE-CUST-COUNTRY TO TEMP-CUST-COUNTRY
                           WRITE CUSTOMER-TEMP-RECORD
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE CUSTOMER-FILE CUSTOMER-TEMP-FILE.
           CALL "system" USING
               "mv data/customers.tmp data/customers.dat".
