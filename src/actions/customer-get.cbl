       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTOMER-GET.

       *> Usage: customer-get <account_number>
       *> Output:
       *>   OK|<account>|<fname>|<lname>|<phone>|<email>|<address>|<zip>|<city>|<country>
       *>   ERR|NOT_FOUND|Customer not found.
       *>   ERR|USAGE|...

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSTOMER-FILE
               ASSIGN TO "data/customers.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

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

       WORKING-STORAGE SECTION.

       01 WS-ARG-ACCOUNT PIC X(8).
       01 WS-FOUND       PIC X VALUE "N".
       01 WS-EOF         PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES
               DISPLAY "ERR|USAGE|Usage: customer-get <account>"
               STOP RUN
           END-IF.

           MOVE "N" TO WS-FOUND WS-EOF.
           OPEN INPUT CUSTOMER-FILE.
           PERFORM UNTIL WS-EOF = "Y" OR WS-FOUND = "Y"
               READ CUSTOMER-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       IF FILE-CUST-ACCOUNT = WS-ARG-ACCOUNT
                           MOVE "Y" TO WS-FOUND
                       END-IF
               END-READ
           END-PERFORM.
           CLOSE CUSTOMER-FILE.

           IF WS-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Customer not found."
               STOP RUN
           END-IF.

           DISPLAY "OK|"
               FILE-CUST-ACCOUNT "|"
               FILE-CUST-FNAME   "|"
               FILE-CUST-LNAME   "|"
               FILE-CUST-PHONE   "|"
               FILE-CUST-EMAIL   "|"
               FILE-CUST-ADDRESS "|"
               FILE-CUST-ZIP     "|"
               FILE-CUST-CITY    "|"
               FILE-CUST-COUNTRY.

           STOP RUN.
