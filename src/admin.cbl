       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMIN.

       DATA DIVISION.

       WORKING-STORAGE SECTION.

       01 WS-ADMIN-USER
           PIC X(20).

       01 WS-ADMIN-PIN
           PIC X(4).

       01 WS-MENU-CHOICE
           PIC 9
           VALUE 0.

       PROCEDURE DIVISION.

           PERFORM ADMIN-LOGIN.

           IF WS-MENU-CHOICE = 0

               PERFORM ADMIN-MENU
                   UNTIL WS-MENU-CHOICE = 4

           END-IF.

           GOBACK.


       ADMIN-LOGIN.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "        ADMIN LOGIN".
           DISPLAY "========================".

           DISPLAY "Username: ".
           ACCEPT WS-ADMIN-USER.

           DISPLAY "PIN: ".
           ACCEPT WS-ADMIN-PIN.

           *> Temporary authentication.
           IF WS-ADMIN-USER = "admin"
              AND WS-ADMIN-PIN = "1234"

               DISPLAY "Admin login successful!"
               MOVE 0
                   TO WS-MENU-CHOICE

           ELSE

               DISPLAY "Invalid admin credentials."
               MOVE 4
                   TO WS-MENU-CHOICE

           END-IF.


       ADMIN-MENU.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "        ADMIN MENU".
           DISPLAY "========================".
           DISPLAY " ".
           DISPLAY "1. Create new account".
           DISPLAY "2. Delete account".
           DISPLAY "3. Suspend account".
           DISPLAY "4. Logout".
           DISPLAY " ".

           DISPLAY "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.

           EVALUATE WS-MENU-CHOICE

               WHEN 1

                   DISPLAY "Account creation is not"
                   DISPLAY "implemented yet."

               WHEN 2

                   DISPLAY "Account deletion is not"
                   DISPLAY "implemented yet."

               WHEN 3

                   DISPLAY "Account suspension is not"
                   DISPLAY "implemented yet."

               WHEN 4

                   DISPLAY "Logging out..."

               WHEN OTHER

                   DISPLAY "Invalid option."

           END-EVALUATE.
           