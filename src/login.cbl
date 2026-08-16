       IDENTIFICATION DIVISION.
       PROGRAM-ID. LOGIN.

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

       WORKING-STORAGE SECTION.

       01 WS-ACCOUNT-NUMBER PIC X(8).
       01 WS-PIN            PIC X(4).

       01 WS-SALT           PIC X(15).
       01 WS-PIN-HASH       PIC X(65).

       01 WS-ACCOUNT-FOUND  PIC X VALUE "N".

       PROCEDURE DIVISION.

           MOVE "STADIUM2026SALT" TO WS-SALT.

           OPEN INPUT ACCOUNT-FILE.

           DISPLAY "========================".
           DISPLAY "     STADIUM WALLET".
           DISPLAY "========================".

           DISPLAY "Account number: ".
           ACCEPT WS-ACCOUNT-NUMBER.

           DISPLAY "PIN: ".
           ACCEPT WS-PIN.

           PERFORM FIND-ACCOUNT.

           IF WS-ACCOUNT-FOUND = "Y"

               CALL "hash_pin"
                   USING
                       WS-PIN
                       WS-SALT
                       WS-PIN-HASH

               IF WS-PIN-HASH(1:64) = FILE-PIN-HASH
                   DISPLAY "Login successful!"
               ELSE
                   DISPLAY "Invalid PIN."
               END-IF

           ELSE

               DISPLAY "Account not found."

           END-IF.

           CLOSE ACCOUNT-FILE.

           STOP RUN.


       FIND-ACCOUNT.

           PERFORM UNTIL WS-ACCOUNT-FOUND = "Y"
               READ ACCOUNT-FILE

                   AT END
                       EXIT PERFORM

                   NOT AT END

                       IF FILE-ACCOUNT-NUMBER =
                          WS-ACCOUNT-NUMBER

                           MOVE "Y"
                               TO WS-ACCOUNT-FOUND

                       END-IF

               END-READ
           END-PERFORM.
           