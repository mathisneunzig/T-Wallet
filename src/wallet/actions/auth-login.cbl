       IDENTIFICATION DIVISION.
       PROGRAM-ID. AUTH-LOGIN.

       *> Usage: auth-login <account_number> <pin>
       *> Output:
       *>   OK|<account_number>
       *>   ERR|NOT_FOUND|Account not found.
       *>   ERR|SUSPENDED|Account is suspended.
       *>   ERR|INVALID_PIN|Invalid PIN.
       *>   ERR|USAGE|Usage: auth-login <account> <pin>

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT ACCOUNT-FILE
               ASSIGN TO "data/accounts.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.
       FILE SECTION.

       FD ACCOUNT-FILE.
       01 ACCOUNT-RECORD.
           05 FILE-ACCOUNT-NUMBER PIC X(8).
           05 FILE-PIN-HASH       PIC X(64).
           05 FILE-ACCOUNT-STATUS PIC X.

       WORKING-STORAGE SECTION.

       01 WS-ARG-ACCOUNT    PIC X(8).
       01 WS-ARG-PIN        PIC X(4).

       01 WS-PIN-C          PIC X(5).
       01 WS-SALT           PIC X(15) VALUE "STADIUM2026SALT".
       01 WS-SALT-C         PIC X(16).
       01 WS-PIN-HASH       PIC X(65).

       01 WS-FOUND          PIC X VALUE "N".
       01 WS-EOF            PIC X VALUE "N".

       PROCEDURE DIVISION.

           ACCEPT WS-ARG-ACCOUNT FROM ARGUMENT-VALUE.
           ACCEPT WS-ARG-PIN FROM ARGUMENT-VALUE.

           IF WS-ARG-ACCOUNT = SPACES OR WS-ARG-PIN = SPACES
               DISPLAY "ERR|USAGE|Usage: auth-login <account> <pin>"
               STOP RUN
           END-IF.

           MOVE "N" TO WS-FOUND.
           MOVE "N" TO WS-EOF.

           OPEN INPUT ACCOUNT-FILE.

           PERFORM UNTIL WS-EOF = "Y" OR WS-FOUND = "Y"
               READ ACCOUNT-FILE
                   AT END    MOVE "Y" TO WS-EOF
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

           IF FILE-ACCOUNT-STATUS = "S"
               DISPLAY "ERR|SUSPENDED|Account is suspended."
               STOP RUN
           END-IF.

           MOVE WS-ARG-PIN    TO WS-PIN-C(1:4).
           MOVE LOW-VALUES    TO WS-PIN-C(5:1).
           MOVE WS-SALT       TO WS-SALT-C(1:15).
           MOVE LOW-VALUES    TO WS-SALT-C(16:1).

           CALL "hash_pin" USING WS-PIN-C WS-SALT-C WS-PIN-HASH.

           IF WS-PIN-HASH(1:64) = FILE-PIN-HASH
               DISPLAY "OK|" WS-ARG-ACCOUNT
           ELSE
               DISPLAY "ERR|INVALID_PIN|Invalid PIN."
           END-IF.

           STOP RUN.
