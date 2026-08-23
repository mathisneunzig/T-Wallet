       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKER-CHANGE-PIN.

       *> Usage: banker-change-pin <account> <new_pin>
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
       01 WS-ARG-PIN     PIC X(4).
       01 WS-PIN-C       PIC X(5).
       01 WS-SALT        PIC X(15) VALUE "STADIUM2026SALT".
       01 WS-SALT-C      PIC X(16).
       01 WS-PIN-HASH    PIC X(65).
       01 WS-FOUND       PIC X VALUE "N".
       01 WS-EOF         PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-PIN FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES OR WS-ARG-PIN = SPACES
               DISPLAY "ERR|USAGE|"
                   "Usage: banker-change-pin <account> <new_pin>"
               STOP RUN
           END-IF.

           MOVE WS-ARG-PIN TO WS-PIN-C(1:4).
           MOVE LOW-VALUES TO WS-PIN-C(5:1).
           MOVE WS-SALT    TO WS-SALT-C(1:15).
           MOVE LOW-VALUES TO WS-SALT-C(16:1).
           CALL "hash_pin" USING WS-PIN-C WS-SALT-C WS-PIN-HASH.

           MOVE "N" TO WS-FOUND WS-EOF.
           OPEN INPUT ACCOUNT-FILE.
           OPEN OUTPUT ACCOUNT-TEMP-FILE.

           PERFORM UNTIL WS-EOF = "Y"
               READ ACCOUNT-FILE
                   AT END MOVE "Y" TO WS-EOF
                   NOT AT END
                       MOVE FILE-ACCOUNT-NUMBER TO TEMP-ACCOUNT-NUMBER
                       MOVE FILE-ACCOUNT-STATUS TO TEMP-ACCOUNT-STATUS
                       IF FILE-ACCOUNT-NUMBER = WS-ARG-ACCOUNT
                           MOVE WS-PIN-HASH(1:64) TO TEMP-PIN-HASH
                           MOVE "Y" TO WS-FOUND
                       ELSE
                           MOVE FILE-PIN-HASH TO TEMP-PIN-HASH
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
