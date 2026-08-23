       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMIN-SUSPEND-ACCOUNT.

       *> Usage: admin-suspend-account <account>
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

       WORKING-STORAGE SECTION.

       01 WS-ARG-ACCOUNT PIC X(8).
       01 WS-FOUND       PIC X VALUE "N".
       01 WS-EOF         PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES
               DISPLAY "ERR|USAGE|"
                   "Usage: admin-suspend-account <account>"
               STOP RUN
           END-IF.

           MOVE "N" TO WS-FOUND WS-EOF.
           OPEN INPUT ACCOUNT-FILE.
           OPEN OUTPUT ACCOUNT-TEMP-FILE.

           PERFORM UNTIL WS-EOF = "Y"
               READ ACCOUNT-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       MOVE FILE-ACCOUNT-NUMBER TO TEMP-ACCOUNT-NUMBER
                       MOVE FILE-PIN-HASH       TO TEMP-PIN-HASH
                       IF FILE-ACCOUNT-NUMBER = WS-ARG-ACCOUNT
                           MOVE "S" TO TEMP-ACCOUNT-STATUS
                           MOVE "Y" TO WS-FOUND
                       ELSE
                           MOVE FILE-ACCOUNT-STATUS TO TEMP-ACCOUNT-STATUS
                       END-IF
                       WRITE ACCOUNT-TEMP-RECORD
               END-READ
           END-PERFORM.

           CLOSE ACCOUNT-FILE ACCOUNT-TEMP-FILE.
           CALL "system" USING
               "mv data/accounts.tmp data/accounts.dat".

           IF WS-FOUND = "N"
               DISPLAY "ERR|NOT_FOUND|Account not found."
           ELSE
               DISPLAY "OK|" WS-ARG-ACCOUNT
           END-IF.

           STOP RUN.
