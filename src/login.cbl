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
           05 FILE-ACCOUNT-STATUS PIC X.

       WORKING-STORAGE SECTION.

       COPY "terminal.cpy".

       01 WS-ACCOUNT-NUMBER
           PIC X(8).

       01 WS-PIN
           PIC X(4).

       *> C string: 4 characters + null terminator.
       01 WS-PIN-C
           PIC X(5).

       01 WS-SALT
           PIC X(15)
           VALUE "STADIUM2026SALT".

       *> C string: 15 characters + null terminator.
       01 WS-SALT-C
           PIC X(16).

       01 WS-PIN-HASH
           PIC X(65).

       01 WS-ACCOUNT-FOUND
           PIC X
           VALUE "N".

       01 WS-END-OF-FILE
           PIC X
           VALUE "N".

       LINKAGE SECTION.

       01 LK-LOGIN-SUCCESS
           PIC X.

       01 LK-ACCOUNT-NUMBER
           PIC X(8).

       PROCEDURE DIVISION
           USING
               LK-LOGIN-SUCCESS
               LK-ACCOUNT-NUMBER.

           MOVE "N"
               TO LK-LOGIN-SUCCESS.

           MOVE SPACES
               TO LK-ACCOUNT-NUMBER.

           DISPLAY " ".
           DISPLAY T-GREEN "========================".
           DISPLAY T-GREEN "     CUSTOMER LOGIN".
           DISPLAY T-GREEN "========================".

           DISPLAY T-WHITE "Account number: ".
           ACCEPT WS-ACCOUNT-NUMBER.

           DISPLAY T-WHITE "PIN: ".
           ACCEPT WS-PIN.

           *> Build C-compatible PIN.
           MOVE WS-PIN
               TO WS-PIN-C(1:4).

           MOVE LOW-VALUES
               TO WS-PIN-C(5:1).

           *> Build C-compatible salt.
           MOVE WS-SALT
               TO WS-SALT-C(1:15).

           MOVE LOW-VALUES
               TO WS-SALT-C(16:1).

           PERFORM FIND-ACCOUNT.

           IF WS-ACCOUNT-FOUND = "Y"

               IF FILE-ACCOUNT-STATUS = "S"

                   DISPLAY "Account is suspended."

               ELSE

                   CALL "hash_pin"
                       USING
                           WS-PIN-C
                           WS-SALT-C
                           WS-PIN-HASH

                   IF WS-PIN-HASH(1:64) = FILE-PIN-HASH

                       MOVE "Y"
                           TO LK-LOGIN-SUCCESS

                       MOVE WS-ACCOUNT-NUMBER
                           TO LK-ACCOUNT-NUMBER

                       DISPLAY "Login successful!"

                   ELSE

                       DISPLAY "Invalid PIN."

                   END-IF

               END-IF

           ELSE

               DISPLAY "Account not found."

           END-IF.

           GOBACK.


       FIND-ACCOUNT.

           MOVE "N"
               TO WS-ACCOUNT-FOUND.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT ACCOUNT-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"
               OR WS-ACCOUNT-FOUND = "Y"

               READ ACCOUNT-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       IF FILE-ACCOUNT-NUMBER =
                          WS-ACCOUNT-NUMBER

                           MOVE "Y"
                               TO WS-ACCOUNT-FOUND

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.
           