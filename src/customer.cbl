       IDENTIFICATION DIVISION.
       PROGRAM-ID. CUSTOMER.

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
           05 FILE-CUST-ACCOUNT  PIC X(8).
           05 FILE-CUST-FNAME    PIC X(30).
           05 FILE-CUST-LNAME    PIC X(30).
           05 FILE-CUST-PHONE    PIC X(20).
           05 FILE-CUST-EMAIL    PIC X(50).
           05 FILE-CUST-ADDRESS  PIC X(50).
           05 FILE-CUST-ZIP      PIC X(10).
           05 FILE-CUST-CITY     PIC X(30).
           05 FILE-CUST-COUNTRY  PIC X(30).

       FD CUSTOMER-TEMP-FILE.
       01 CUSTOMER-TEMP-RECORD.
           05 TEMP-CUST-ACCOUNT  PIC X(8).
           05 TEMP-CUST-FNAME    PIC X(30).
           05 TEMP-CUST-LNAME    PIC X(30).
           05 TEMP-CUST-PHONE    PIC X(20).
           05 TEMP-CUST-EMAIL    PIC X(50).
           05 TEMP-CUST-ADDRESS  PIC X(50).
           05 TEMP-CUST-ZIP      PIC X(10).
           05 TEMP-CUST-CITY     PIC X(30).
           05 TEMP-CUST-COUNTRY  PIC X(30).

       WORKING-STORAGE SECTION.

       01 WS-END-OF-FILE
           PIC X
           VALUE "N".

       LINKAGE SECTION.

       *> Operation code:
       *>   "LOAD" - load record for LK-ACCOUNT into linkage fields
       *>   "SAVE" - write linkage fields back to customers.dat
       *>   "NEW " - append a new record (all fields from linkage)
       01 LK-OPERATION
           PIC X(4).

       01 LK-FOUND
           PIC X.

       01 LK-ACCOUNT
           PIC X(8).

       01 LK-FNAME
           PIC X(30).

       01 LK-LNAME
           PIC X(30).

       01 LK-PHONE
           PIC X(20).

       01 LK-EMAIL
           PIC X(50).

       01 LK-ADDRESS
           PIC X(50).

       01 LK-ZIP
           PIC X(10).

       01 LK-CITY
           PIC X(30).

       01 LK-COUNTRY
           PIC X(30).

       PROCEDURE DIVISION
           USING
               LK-OPERATION
               LK-FOUND
               LK-ACCOUNT
               LK-FNAME
               LK-LNAME
               LK-PHONE
               LK-EMAIL
               LK-ADDRESS
               LK-ZIP
               LK-CITY
               LK-COUNTRY.

           EVALUATE LK-OPERATION

               WHEN "LOAD"
                   PERFORM DO-LOAD

               WHEN "SAVE"
                   PERFORM DO-SAVE

               WHEN "NEW "
                   PERFORM DO-NEW

               WHEN OTHER
                   MOVE "N"
                       TO LK-FOUND

           END-EVALUATE.

           GOBACK.


       DO-LOAD.

           MOVE "N"
               TO LK-FOUND.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT CUSTOMER-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR LK-FOUND = "Y"

               READ CUSTOMER-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       IF FILE-CUST-ACCOUNT = LK-ACCOUNT

                           MOVE "Y"
                               TO LK-FOUND

                           MOVE FILE-CUST-FNAME
                               TO LK-FNAME

                           MOVE FILE-CUST-LNAME
                               TO LK-LNAME

                           MOVE FILE-CUST-PHONE
                               TO LK-PHONE

                           MOVE FILE-CUST-EMAIL
                               TO LK-EMAIL

                           MOVE FILE-CUST-ADDRESS
                               TO LK-ADDRESS

                           MOVE FILE-CUST-ZIP
                               TO LK-ZIP

                           MOVE FILE-CUST-CITY
                               TO LK-CITY

                           MOVE FILE-CUST-COUNTRY
                               TO LK-COUNTRY

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE CUSTOMER-FILE.


       DO-SAVE.

           MOVE "N"
               TO LK-FOUND.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT CUSTOMER-FILE.
           OPEN OUTPUT CUSTOMER-TEMP-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"

               READ CUSTOMER-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       MOVE FILE-CUST-ACCOUNT
                           TO TEMP-CUST-ACCOUNT

                       IF FILE-CUST-ACCOUNT = LK-ACCOUNT

                           MOVE "Y"
                               TO LK-FOUND

                           MOVE LK-FNAME
                               TO TEMP-CUST-FNAME

                           MOVE LK-LNAME
                               TO TEMP-CUST-LNAME

                           MOVE LK-PHONE
                               TO TEMP-CUST-PHONE

                           MOVE LK-EMAIL
                               TO TEMP-CUST-EMAIL

                           MOVE LK-ADDRESS
                               TO TEMP-CUST-ADDRESS

                           MOVE LK-ZIP
                               TO TEMP-CUST-ZIP

                           MOVE LK-CITY
                               TO TEMP-CUST-CITY

                           MOVE LK-COUNTRY
                               TO TEMP-CUST-COUNTRY

                       ELSE

                           MOVE FILE-CUST-FNAME
                               TO TEMP-CUST-FNAME

                           MOVE FILE-CUST-LNAME
                               TO TEMP-CUST-LNAME

                           MOVE FILE-CUST-PHONE
                               TO TEMP-CUST-PHONE

                           MOVE FILE-CUST-EMAIL
                               TO TEMP-CUST-EMAIL

                           MOVE FILE-CUST-ADDRESS
                               TO TEMP-CUST-ADDRESS

                           MOVE FILE-CUST-ZIP
                               TO TEMP-CUST-ZIP

                           MOVE FILE-CUST-CITY
                               TO TEMP-CUST-CITY

                           MOVE FILE-CUST-COUNTRY
                               TO TEMP-CUST-COUNTRY

                       END-IF

                       WRITE CUSTOMER-TEMP-RECORD

               END-READ

           END-PERFORM.

           CLOSE CUSTOMER-FILE.
           CLOSE CUSTOMER-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/customers.tmp data/customers.dat".


       DO-NEW.

           MOVE "Y"
               TO LK-FOUND.

           OPEN EXTEND CUSTOMER-FILE.

           MOVE LK-ACCOUNT
               TO FILE-CUST-ACCOUNT.

           MOVE LK-FNAME
               TO FILE-CUST-FNAME.

           MOVE LK-LNAME
               TO FILE-CUST-LNAME.

           MOVE LK-PHONE
               TO FILE-CUST-PHONE.

           MOVE LK-EMAIL
               TO FILE-CUST-EMAIL.

           MOVE LK-ADDRESS
               TO FILE-CUST-ADDRESS.

           MOVE LK-ZIP
               TO FILE-CUST-ZIP.

           MOVE LK-CITY
               TO FILE-CUST-CITY.

           MOVE LK-COUNTRY
               TO FILE-CUST-COUNTRY.

           WRITE CUSTOMER-RECORD.

           CLOSE CUSTOMER-FILE.
