       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMIN-CREATE-ACCOUNT.

       *> Usage: admin-create-account <account> <pin> <currency>
       *>                              <decimals> <fname> <lname>
       *>                              <phone> <email> <address>
       *>                              <zip> <city> <country>
       *> Output:
       *>   OK|<account>
       *>   ERR|EXISTS|Account already exists.
       *>   ERR|USAGE|...

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "data/accounts.dat"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT WALLET-FILE
               ASSIGN TO "data/wallets.dat"
               ORGANIZATION IS LINE SEQUENTIAL.
           SELECT CUSTOMER-FILE
               ASSIGN TO "data/customers.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD ACCOUNT-FILE.
       01 ACCOUNT-RECORD.
           05 FILE-ACCOUNT-NUMBER PIC X(8).
           05 FILE-PIN-HASH       PIC X(64).
           05 FILE-ACCOUNT-STATUS PIC X.

       FD WALLET-FILE.
       01 WALLET-RECORD.
           05 FILE-WALLET-ACCOUNT  PIC X(8).
           05 FILE-WALLET-CURRENCY PIC X(3).
           05 FILE-WALLET-DECIMALS PIC 9.
           05 FILE-WALLET-BALANCE  PIC 9(18).

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

       01 WS-ARG-ACCOUNT   PIC X(8).
       01 WS-ARG-PIN       PIC X(4).
       01 WS-ARG-CURRENCY  PIC X(3).
       01 WS-ARG-DECIMALS  PIC X(1).
       01 WS-ARG-FNAME     PIC X(30).
       01 WS-ARG-LNAME     PIC X(30).
       01 WS-ARG-PHONE     PIC X(20).
       01 WS-ARG-EMAIL     PIC X(50).
       01 WS-ARG-ADDRESS   PIC X(50).
       01 WS-ARG-ZIP       PIC X(10).
       01 WS-ARG-CITY      PIC X(30).
       01 WS-ARG-COUNTRY   PIC X(30).

       01 WS-DECIMALS-NUM  PIC 9.
       01 WS-PIN-C         PIC X(5).
       01 WS-SALT          PIC X(15) VALUE "STADIUM2026SALT".
       01 WS-SALT-C        PIC X(16).
       01 WS-PIN-HASH      PIC X(65).
       01 WS-FOUND         PIC X VALUE "N".
       01 WS-EOF           PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT  FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-PIN      FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-CURRENCY FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-DECIMALS FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-FNAME    FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-LNAME    FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-PHONE    FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-EMAIL    FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-ADDRESS  FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-ZIP      FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-CITY     FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-COUNTRY  FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES OR WS-ARG-PIN = SPACES
               DISPLAY "ERR|USAGE|"
                   "Usage: admin-create-account <account> <pin> "
                   "<currency> <decimals> <fname> <lname> "
                   "<phone> <email> <address> <zip> <city> <country>"
               STOP RUN
           END-IF.

           MOVE FUNCTION NUMVAL(WS-ARG-DECIMALS) TO WS-DECIMALS-NUM.

           *> Check for duplicate.
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

           IF WS-FOUND = "Y"
               DISPLAY "ERR|EXISTS|Account already exists."
               STOP RUN
           END-IF.

           *> Hash PIN.
           MOVE WS-ARG-PIN    TO WS-PIN-C(1:4).
           MOVE LOW-VALUES    TO WS-PIN-C(5:1).
           MOVE WS-SALT       TO WS-SALT-C(1:15).
           MOVE LOW-VALUES    TO WS-SALT-C(16:1).
           CALL "hash_pin" USING WS-PIN-C WS-SALT-C WS-PIN-HASH.

           *> Write account record.
           OPEN EXTEND ACCOUNT-FILE.
           MOVE WS-ARG-ACCOUNT      TO FILE-ACCOUNT-NUMBER.
           MOVE WS-PIN-HASH(1:64)   TO FILE-PIN-HASH.
           MOVE "A"                 TO FILE-ACCOUNT-STATUS.
           WRITE ACCOUNT-RECORD.
           CLOSE ACCOUNT-FILE.

           *> Write wallet record.
           OPEN EXTEND WALLET-FILE.
           MOVE WS-ARG-ACCOUNT    TO FILE-WALLET-ACCOUNT.
           MOVE WS-ARG-CURRENCY   TO FILE-WALLET-CURRENCY.
           MOVE WS-DECIMALS-NUM   TO FILE-WALLET-DECIMALS.
           MOVE 0                 TO FILE-WALLET-BALANCE.
           WRITE WALLET-RECORD.
           CLOSE WALLET-FILE.

           *> Write customer record.
           OPEN EXTEND CUSTOMER-FILE.
           MOVE WS-ARG-ACCOUNT  TO FILE-CUST-ACCOUNT.
           MOVE WS-ARG-FNAME    TO FILE-CUST-FNAME.
           MOVE WS-ARG-LNAME    TO FILE-CUST-LNAME.
           MOVE WS-ARG-PHONE    TO FILE-CUST-PHONE.
           MOVE WS-ARG-EMAIL    TO FILE-CUST-EMAIL.
           MOVE WS-ARG-ADDRESS  TO FILE-CUST-ADDRESS.
           MOVE WS-ARG-ZIP      TO FILE-CUST-ZIP.
           MOVE WS-ARG-CITY     TO FILE-CUST-CITY.
           MOVE WS-ARG-COUNTRY  TO FILE-CUST-COUNTRY.
           WRITE CUSTOMER-RECORD.
           CLOSE CUSTOMER-FILE.

           DISPLAY "OK|" WS-ARG-ACCOUNT.
           STOP RUN.
