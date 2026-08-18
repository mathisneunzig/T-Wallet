       IDENTIFICATION DIVISION.
       PROGRAM-ID. BANKER.

       DATA DIVISION.

       WORKING-STORAGE SECTION.

       01 WS-BANKER-USER
           PIC X(20).

       01 WS-BANKER-PIN
           PIC X(4).

       01 WS-MENU-CHOICE
           PIC 9
           VALUE 0.

       PROCEDURE DIVISION.

           PERFORM BANKER-LOGIN.

           IF WS-MENU-CHOICE = 0

               PERFORM BANKER-MENU
                   UNTIL WS-MENU-CHOICE = 6

           END-IF.

           GOBACK.


       BANKER-LOGIN.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "       BANKER LOGIN".
           DISPLAY "========================".

           DISPLAY "Username: ".
           ACCEPT WS-BANKER-USER.

           DISPLAY "PIN: ".
           ACCEPT WS-BANKER-PIN.

           *> Temporary authentication.
           IF WS-BANKER-USER = "banker"
              AND WS-BANKER-PIN = "1234"

               DISPLAY "Banker login successful!"
               MOVE 0
                   TO WS-MENU-CHOICE

           ELSE

               DISPLAY "Invalid banker credentials."
               MOVE 6
                   TO WS-MENU-CHOICE

           END-IF.


       BANKER-MENU.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "       BANKER MENU".
           DISPLAY "========================".
           DISPLAY " ".
           DISPLAY "1. Deposit money for customer".
           DISPLAY "2. Withdraw money for customer".
           DISPLAY "3. Tell balance for customer".
           DISPLAY "4. Change customer information".
           DISPLAY "5. Create new account".
           DISPLAY "6. Logout".
           DISPLAY " ".

           DISPLAY "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.

           EVALUATE WS-MENU-CHOICE

               WHEN 1

                   DISPLAY "Deposit for customer is not"
                   DISPLAY "implemented yet."

               WHEN 2

                   DISPLAY "Withdrawal for customer is not"
                   DISPLAY "implemented yet."

               WHEN 3

                   DISPLAY "Balance lookup is not"
                   DISPLAY "implemented yet."

               WHEN 4

                   DISPLAY "Customer information editing is"
                   DISPLAY "not implemented yet."

               WHEN 5

                   DISPLAY "Account creation is not"
                   DISPLAY "implemented yet."

               WHEN 6

                   DISPLAY "Logging out..."

               WHEN OTHER

                   DISPLAY "Invalid option."

           END-EVALUATE.
           