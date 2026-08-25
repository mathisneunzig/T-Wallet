       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTOMER-UPDATE.

       *> Usage: customer-update <account> <field> <value>
       *>   field: phone | address | zip | city | country
       *>          fname | lname | email   (admin-only fields, enforced at HTTP layer)
       *> Output:
       *>   OK|<account>|<field>|<new_value>
       *>   ERR|NOT_FOUND|Customer not found.
       *>   ERR|INVALID_FIELD|Unknown field.
       *>   ERR|USAGE|...

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUSTOMER-FILE
               ASSIGN TO "data/customers.dat"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT CUSTOMER-TEMP-FILE
               ASSIGN TO "data/customers.tmp"
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
       01 WS-ARG-FIELD   PIC X(10).
       01 WS-ARG-VALUE   PIC X(50).
       01 WS-FOUND       PIC X VALUE "N".
       01 WS-EOF         PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-FIELD FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-VALUE FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES OR WS-ARG-FIELD = SPACES
               DISPLAY "ERR|USAGE|"
                   "Usage: customer-update <account> <field> <value>"
               STOP RUN
           END-IF.

           EVALUATE WS-ARG-FIELD
               WHEN "phone"   CONTINUE
               WHEN "address" CONTINUE
               WHEN "zip"     CONTINUE
               WHEN "city"    CONTINUE
               WHEN "country" CONTINUE
               WHEN "fname"   CONTINUE
               WHEN "lname"   CONTINUE
               WHEN "email"   CONTINUE
               WHEN OTHER
                   DISPLAY "ERR|INVALID_FIELD|Unknown field: "
                       WS-ARG-FIELD
                   STOP RUN
           END-EVALUATE.

           MOVE "N" TO WS-FOUND WS-EOF.
           OPEN INPUT CUSTOMER-FILE.
           OPEN OUTPUT CUSTOMER-TEMP-FILE.

           PERFORM UNTIL WS-EOF = "Y"
               READ CUSTOMER-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       MOVE FILE-CUST-ACCOUNT TO TEMP-CUST-ACCOUNT
                       MOVE FILE-CUST-FNAME   TO TEMP-CUST-FNAME
                       MOVE FILE-CUST-LNAME   TO TEMP-CUST-LNAME
                       MOVE FILE-CUST-PHONE   TO TEMP-CUST-PHONE
                       MOVE FILE-CUST-EMAIL   TO TEMP-CUST-EMAIL
                       MOVE FILE-CUST-ADDRESS TO TEMP-CUST-ADDRESS
                       MOVE FILE-CUST-ZIP     TO TEMP-CUST-ZIP
                       MOVE FILE-CUST-CITY    TO TEMP-CUST-CITY
                       MOVE FILE-CUST-COUNTRY TO TEMP-CUST-COUNTRY

                       IF FILE-CUST-ACCOUNT = WS-ARG-ACCOUNT
                           MOVE "Y" TO WS-FOUND
                           EVALUATE WS-ARG-FIELD
                               WHEN "phone"
                                   MOVE WS-ARG-VALUE(1:20)
                                       TO TEMP-CUST-PHONE
                               WHEN "address"
                                   MOVE WS-ARG-VALUE(1:50)
                                       TO TEMP-CUST-ADDRESS
                               WHEN "zip"
                                   MOVE WS-ARG-VALUE(1:10)
                                       TO TEMP-CUST-ZIP
                               WHEN "city"
                                   MOVE WS-ARG-VALUE(1:30)
                                       TO TEMP-CUST-CITY
                               WHEN "country"
                                   MOVE WS-ARG-VALUE(1:30)
                                       TO TEMP-CUST-COUNTRY
                               WHEN "fname"
                                   MOVE WS-ARG-VALUE(1:30)
                                       TO TEMP-CUST-FNAME
                               WHEN "lname"
                                   MOVE WS-ARG-VALUE(1:30)
                                       TO TEMP-CUST-LNAME
                               WHEN "email"
                                   MOVE WS-ARG-VALUE(1:50)
                                       TO TEMP-CUST-EMAIL
                           END-EVALUATE
                       END-IF
                       WRITE CUSTOMER-TEMP-RECORD
               END-READ
           END-PERFORM.

           CLOSE CUSTOMER-FILE CUSTOMER-TEMP-FILE.
           CALL "system" USING
               "mv data/customers.tmp data/customers.dat".

           IF WS-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Customer not found."
               STOP RUN
           END-IF.

           DISPLAY "OK|" WS-ARG-ACCOUNT "|"
               WS-ARG-FIELD "|" WS-ARG-VALUE.
           STOP RUN.
