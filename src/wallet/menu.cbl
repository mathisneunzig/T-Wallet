       IDENTIFICATION DIVISION.
       PROGRAM-ID. MENU.

       DATA DIVISION.

       WORKING-STORAGE SECTION.

       COPY "terminal.cpy".

       01 WS-MENU-CHOICE
           PIC 9
           VALUE 0.

       01 WS-LOGIN-SUCCESS
           PIC X
           VALUE "N".

       01 WS-ACCOUNT-NUMBER
           PIC X(8)
           VALUE SPACES.

       PROCEDURE DIVISION.

           PERFORM MAIN-MENU
               UNTIL WS-MENU-CHOICE = 4.

           DISPLAY " ".
           DISPLAY "Goodbye!".

           STOP RUN.


       MAIN-MENU.

           MOVE 0
               TO WS-MENU-CHOICE.

           DISPLAY T-WHITE " ".
           DISPLAY T-GREEN "==============================".
           DISPLAY T-WHITE "          T-WALLET"
           DISPLAY T-GREEN "==============================".
           DISPLAY T-WHITE " ".
           DISPLAY T-WHITE "1. Customer Logon".
           DISPLAY T-WHITE "2. Banker Logon".
           DISPLAY T-WHITE "3. Admin Logon".
           DISPLAY T-RED   "4. Exit".
           DISPLAY T-WHITE " ".    

           DISPLAY "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.

           EVALUATE WS-MENU-CHOICE

               WHEN 1

                   PERFORM CUSTOMER-LOGON

               WHEN 2

                   CALL "BANKER"

               WHEN 3

                   CALL "ADMIN"

               WHEN 4

                   CONTINUE

               WHEN OTHER

                   DISPLAY "Invalid option."

           END-EVALUATE.


       CUSTOMER-LOGON.

           MOVE "N"
               TO WS-LOGIN-SUCCESS.

           MOVE SPACES
               TO WS-ACCOUNT-NUMBER.

           CALL "LOGIN"
               USING
                   WS-LOGIN-SUCCESS
                   WS-ACCOUNT-NUMBER.

           IF WS-LOGIN-SUCCESS = "Y"

               CALL "WALLET"
                   USING
                       WS-ACCOUNT-NUMBER

           END-IF.
