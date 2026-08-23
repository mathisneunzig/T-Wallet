       IDENTIFICATION DIVISION.
       PROGRAM-ID. ADMIN.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.

       FILE-CONTROL.

           SELECT ACCOUNT-FILE
               ASSIGN TO "data/accounts.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT ACCOUNT-TEMP-FILE
               ASSIGN TO "data/accounts.tmp"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT WALLET-FILE
               ASSIGN TO "data/wallets.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT WALLET-TEMP-FILE
               ASSIGN TO "data/wallets.tmp"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT CUSTOMER-FILE
               ASSIGN TO "data/customers.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

           SELECT CUSTOMER-TEMP-FILE
               ASSIGN TO "data/customers.tmp"
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

       FD WALLET-FILE.
       01 WALLET-RECORD.
           05 FILE-WALLET-ACCOUNT-NUMBER PIC X(8).
           05 FILE-WALLET-CURRENCY       PIC X(3).
           05 FILE-WALLET-DECIMALS       PIC 9.
           05 FILE-WALLET-BALANCE        PIC 9(18).

       FD WALLET-TEMP-FILE.
       01 WALLET-TEMP-RECORD.
           05 TEMP-WALLET-ACCOUNT-NUMBER PIC X(8).
           05 TEMP-WALLET-CURRENCY       PIC X(3).
           05 TEMP-WALLET-DECIMALS       PIC 9.
           05 TEMP-WALLET-BALANCE        PIC 9(18).

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

       01 WS-ADMIN-USER
           PIC X(20).

       01 WS-ADMIN-PIN
           PIC X(4).

       01 WS-MENU-CHOICE
           PIC 9
           VALUE 0.

       01 WS-NEW-ACCOUNT-NUMBER
           PIC X(8).

       01 WS-NEW-PIN
           PIC X(4).

       *> C string: 4 characters + null terminator.
       01 WS-NEW-PIN-C
           PIC X(5).

       01 WS-SALT
           PIC X(15)
           VALUE "STADIUM2026SALT".

       *> C string: 15 characters + null terminator.
       01 WS-SALT-C
           PIC X(16).

       01 WS-NEW-PIN-HASH
           PIC X(65).

       01 WS-NEW-CURRENCY
           PIC X(3).

       01 WS-NEW-DECIMALS
           PIC 9.

       01 WS-TARGET-ACCOUNT
           PIC X(8).

       01 WS-ACCOUNT-FOUND
           PIC X
           VALUE "N".

       01 WS-END-OF-FILE
           PIC X
           VALUE "N".

       01 WS-CONFIRM
           PIC X.

       *> Customer profile fields.
       01 WS-CUST-OP
           PIC X(4).

       01 WS-CUST-FOUND
           PIC X.

       01 WS-CUST-FNAME
           PIC X(30).

       01 WS-CUST-LNAME
           PIC X(30).

       01 WS-CUST-PHONE
           PIC X(20).

       01 WS-CUST-EMAIL
           PIC X(50).

       01 WS-CUST-ADDRESS
           PIC X(50).

       01 WS-CUST-ZIP
           PIC X(10).

       01 WS-CUST-CITY
           PIC X(30).

       01 WS-CUST-COUNTRY
           PIC X(30).

       01 WS-PROFILE-CHOICE
           PIC 9.

       PROCEDURE DIVISION.

           PERFORM ADMIN-LOGIN.

           IF WS-MENU-CHOICE = 0

               PERFORM ADMIN-MENU
                   UNTIL WS-MENU-CHOICE = 5

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
               MOVE 5
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
           DISPLAY "4. Edit customer profile".
           DISPLAY "5. Logout".
           DISPLAY " ".

           DISPLAY "Choose an option: ".
           ACCEPT WS-MENU-CHOICE.

           EVALUATE WS-MENU-CHOICE

               WHEN 1
                   PERFORM CREATE-ACCOUNT

               WHEN 2
                   PERFORM DELETE-ACCOUNT

               WHEN 3
                   PERFORM SUSPEND-ACCOUNT

               WHEN 4
                   PERFORM EDIT-CUSTOMER-PROFILE

               WHEN 5
                   DISPLAY "Logging out..."

               WHEN OTHER
                   DISPLAY "Invalid option."

           END-EVALUATE.


       CREATE-ACCOUNT.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "      CREATE ACCOUNT".
           DISPLAY "========================".

           DISPLAY "New account number (8 chars): ".
           ACCEPT WS-NEW-ACCOUNT-NUMBER.

           PERFORM CHECK-ACCOUNT-EXISTS.

           IF WS-ACCOUNT-FOUND = "Y"

               DISPLAY "Account already exists."

           ELSE

               DISPLAY "PIN (4 digits): "
               ACCEPT WS-NEW-PIN

               DISPLAY "Currency (3 chars, e.g. USD): "
               ACCEPT WS-NEW-CURRENCY

               DISPLAY "Decimal places (0-6): "
               ACCEPT WS-NEW-DECIMALS

               DISPLAY "First name: "
               ACCEPT WS-CUST-FNAME

               DISPLAY "Last name: "
               ACCEPT WS-CUST-LNAME

               DISPLAY "Phone number: "
               ACCEPT WS-CUST-PHONE

               DISPLAY "Email: "
               ACCEPT WS-CUST-EMAIL

               DISPLAY "Address: "
               ACCEPT WS-CUST-ADDRESS

               DISPLAY "Zip code: "
               ACCEPT WS-CUST-ZIP

               DISPLAY "City: "
               ACCEPT WS-CUST-CITY

               DISPLAY "Country: "
               ACCEPT WS-CUST-COUNTRY

               PERFORM HASH-NEW-PIN

               PERFORM WRITE-NEW-ACCOUNT

               PERFORM WRITE-NEW-WALLET

               PERFORM WRITE-NEW-CUSTOMER

               DISPLAY "Account created successfully."

           END-IF.


       CHECK-ACCOUNT-EXISTS.

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
                          WS-NEW-ACCOUNT-NUMBER

                           MOVE "Y"
                               TO WS-ACCOUNT-FOUND

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.


       HASH-NEW-PIN.

           *> Build C-compatible PIN string.
           MOVE WS-NEW-PIN
               TO WS-NEW-PIN-C(1:4).

           MOVE LOW-VALUES
               TO WS-NEW-PIN-C(5:1).

           *> Build C-compatible salt string.
           MOVE WS-SALT
               TO WS-SALT-C(1:15).

           MOVE LOW-VALUES
               TO WS-SALT-C(16:1).

           CALL "hash_pin"
               USING
                   WS-NEW-PIN-C
                   WS-SALT-C
                   WS-NEW-PIN-HASH.


       WRITE-NEW-ACCOUNT.

           OPEN EXTEND ACCOUNT-FILE.

           MOVE WS-NEW-ACCOUNT-NUMBER
               TO FILE-ACCOUNT-NUMBER.

           MOVE WS-NEW-PIN-HASH(1:64)
               TO FILE-PIN-HASH.

           MOVE "A"
               TO FILE-ACCOUNT-STATUS.

           WRITE ACCOUNT-RECORD.

           CLOSE ACCOUNT-FILE.


       WRITE-NEW-WALLET.

           OPEN EXTEND WALLET-FILE.

           MOVE WS-NEW-ACCOUNT-NUMBER
               TO FILE-WALLET-ACCOUNT-NUMBER.

           MOVE WS-NEW-CURRENCY
               TO FILE-WALLET-CURRENCY.

           MOVE WS-NEW-DECIMALS
               TO FILE-WALLET-DECIMALS.

           MOVE 0
               TO FILE-WALLET-BALANCE.

           WRITE WALLET-RECORD.

           CLOSE WALLET-FILE.


       WRITE-NEW-CUSTOMER.

           MOVE "NEW "
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   WS-NEW-ACCOUNT-NUMBER
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.


       DELETE-ACCOUNT.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "      DELETE ACCOUNT".
           DISPLAY "========================".

           DISPLAY "Account number to delete: ".
           ACCEPT WS-TARGET-ACCOUNT.

           PERFORM VERIFY-TARGET-EXISTS.

           IF WS-ACCOUNT-FOUND = "N"

               DISPLAY "Account not found."

           ELSE

               DISPLAY "Confirm deletion (Y/N): "
               ACCEPT WS-CONFIRM

               IF WS-CONFIRM = "Y" OR WS-CONFIRM = "y"

                   PERFORM REMOVE-ACCOUNT-RECORD
                   PERFORM REMOVE-WALLET-RECORD
                   PERFORM REMOVE-CUSTOMER-RECORD

                   DISPLAY "Account deleted."

               ELSE

                   DISPLAY "Deletion cancelled."

               END-IF

           END-IF.


       VERIFY-TARGET-EXISTS.

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
                          WS-TARGET-ACCOUNT

                           MOVE "Y"
                               TO WS-ACCOUNT-FOUND

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.


       REMOVE-ACCOUNT-RECORD.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT ACCOUNT-FILE.
           OPEN OUTPUT ACCOUNT-TEMP-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"

               READ ACCOUNT-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       IF FILE-ACCOUNT-NUMBER NOT =
                          WS-TARGET-ACCOUNT

                           MOVE FILE-ACCOUNT-NUMBER
                               TO TEMP-ACCOUNT-NUMBER

                           MOVE FILE-PIN-HASH
                               TO TEMP-PIN-HASH

                           MOVE FILE-ACCOUNT-STATUS
                               TO TEMP-ACCOUNT-STATUS

                           WRITE ACCOUNT-TEMP-RECORD

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.
           CLOSE ACCOUNT-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/accounts.tmp data/accounts.dat".


       REMOVE-WALLET-RECORD.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT WALLET-FILE.
           OPEN OUTPUT WALLET-TEMP-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"

               READ WALLET-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       IF FILE-WALLET-ACCOUNT-NUMBER NOT =
                          WS-TARGET-ACCOUNT

                           MOVE FILE-WALLET-ACCOUNT-NUMBER
                               TO TEMP-WALLET-ACCOUNT-NUMBER

                           MOVE FILE-WALLET-CURRENCY
                               TO TEMP-WALLET-CURRENCY

                           MOVE FILE-WALLET-DECIMALS
                               TO TEMP-WALLET-DECIMALS

                           MOVE FILE-WALLET-BALANCE
                               TO TEMP-WALLET-BALANCE

                           WRITE WALLET-TEMP-RECORD

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE WALLET-FILE.
           CLOSE WALLET-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/wallets.tmp data/wallets.dat".


       REMOVE-CUSTOMER-RECORD.

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

                       IF FILE-CUST-ACCOUNT NOT =
                          WS-TARGET-ACCOUNT

                           MOVE FILE-CUST-ACCOUNT
                               TO TEMP-CUST-ACCOUNT

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

                           WRITE CUSTOMER-TEMP-RECORD

                       END-IF

               END-READ

           END-PERFORM.

           CLOSE CUSTOMER-FILE.
           CLOSE CUSTOMER-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/customers.tmp data/customers.dat".


       SUSPEND-ACCOUNT.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "     SUSPEND ACCOUNT".
           DISPLAY "========================".

           DISPLAY "Account number to suspend: ".
           ACCEPT WS-TARGET-ACCOUNT.

           PERFORM SET-ACCOUNT-SUSPENDED.


       SET-ACCOUNT-SUSPENDED.

           MOVE "N"
               TO WS-ACCOUNT-FOUND.

           MOVE "N"
               TO WS-END-OF-FILE.

           OPEN INPUT ACCOUNT-FILE.
           OPEN OUTPUT ACCOUNT-TEMP-FILE.

           PERFORM UNTIL WS-END-OF-FILE = "Y"

               READ ACCOUNT-FILE

                   AT END

                       MOVE "Y"
                           TO WS-END-OF-FILE

                   NOT AT END

                       MOVE FILE-ACCOUNT-NUMBER
                           TO TEMP-ACCOUNT-NUMBER

                       MOVE FILE-PIN-HASH
                           TO TEMP-PIN-HASH

                       IF FILE-ACCOUNT-NUMBER =
                          WS-TARGET-ACCOUNT

                           MOVE "S"
                               TO TEMP-ACCOUNT-STATUS

                           MOVE "Y"
                               TO WS-ACCOUNT-FOUND

                       ELSE

                           MOVE FILE-ACCOUNT-STATUS
                               TO TEMP-ACCOUNT-STATUS

                       END-IF

                       WRITE ACCOUNT-TEMP-RECORD

               END-READ

           END-PERFORM.

           CLOSE ACCOUNT-FILE.
           CLOSE ACCOUNT-TEMP-FILE.

           CALL "system"
               USING
                   "mv data/accounts.tmp data/accounts.dat".

           IF WS-ACCOUNT-FOUND = "Y"

               DISPLAY "Account suspended."

           ELSE

               DISPLAY "Account not found."

           END-IF.


       *> -------------------------------------------------------
       *> Admin: edit any field of a customer profile including
       *> first name, last name, and email.
       *> -------------------------------------------------------
       EDIT-CUSTOMER-PROFILE.

           DISPLAY " ".
           DISPLAY "Customer account number: ".
           ACCEPT WS-TARGET-ACCOUNT.

           MOVE "LOAD"
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   WS-TARGET-ACCOUNT
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.

           IF WS-CUST-FOUND = "N"

               DISPLAY "Customer profile not found."

           ELSE

               PERFORM DISPLAY-PROFILE

               DISPLAY " ".
               DISPLAY "What to change?".
               DISPLAY "1. First name".
               DISPLAY "2. Last name".
               DISPLAY "3. Phone number".
               DISPLAY "4. Email".
               DISPLAY "5. Address".
               DISPLAY "6. Zip code".
               DISPLAY "7. City".
               DISPLAY "8. Country".
               DISPLAY "9. Back".
               DISPLAY " ".
               DISPLAY "Choose an option: "
               ACCEPT WS-PROFILE-CHOICE

               EVALUATE WS-PROFILE-CHOICE

                   WHEN 1
                       DISPLAY "New first name: "
                       ACCEPT WS-CUST-FNAME
                       PERFORM SAVE-PROFILE
                       DISPLAY "First name updated."

                   WHEN 2
                       DISPLAY "New last name: "
                       ACCEPT WS-CUST-LNAME
                       PERFORM SAVE-PROFILE
                       DISPLAY "Last name updated."

                   WHEN 3
                       DISPLAY "New phone number: "
                       ACCEPT WS-CUST-PHONE
                       PERFORM SAVE-PROFILE
                       DISPLAY "Phone number updated."

                   WHEN 4
                       DISPLAY "New email: "
                       ACCEPT WS-CUST-EMAIL
                       PERFORM SAVE-PROFILE
                       DISPLAY "Email updated."

                   WHEN 5
                       DISPLAY "New address: "
                       ACCEPT WS-CUST-ADDRESS
                       PERFORM SAVE-PROFILE
                       DISPLAY "Address updated."

                   WHEN 6
                       DISPLAY "New zip code: "
                       ACCEPT WS-CUST-ZIP
                       PERFORM SAVE-PROFILE
                       DISPLAY "Zip code updated."

                   WHEN 7
                       DISPLAY "New city: "
                       ACCEPT WS-CUST-CITY
                       PERFORM SAVE-PROFILE
                       DISPLAY "City updated."

                   WHEN 8
                       DISPLAY "New country: "
                       ACCEPT WS-CUST-COUNTRY
                       PERFORM SAVE-PROFILE
                       DISPLAY "Country updated."

                   WHEN 9
                       CONTINUE

                   WHEN OTHER
                       DISPLAY "Invalid option."

               END-EVALUATE.


       DISPLAY-PROFILE.

           DISPLAY " ".
           DISPLAY "========================".
           DISPLAY "    CUSTOMER PROFILE".
           DISPLAY "========================".
           DISPLAY "Account: " WS-TARGET-ACCOUNT.
           DISPLAY "Name:    " WS-CUST-FNAME
                            " " WS-CUST-LNAME.
           DISPLAY "Phone:   " WS-CUST-PHONE.
           DISPLAY "Email:   " WS-CUST-EMAIL.
           DISPLAY "Address: " WS-CUST-ADDRESS.
           DISPLAY "Zip:     " WS-CUST-ZIP.
           DISPLAY "City:    " WS-CUST-CITY.
           DISPLAY "Country: " WS-CUST-COUNTRY.


       SAVE-PROFILE.

           MOVE "SAVE"
               TO WS-CUST-OP.

           CALL "CUSTOMER"
               USING
                   WS-CUST-OP
                   WS-CUST-FOUND
                   WS-TARGET-ACCOUNT
                   WS-CUST-FNAME
                   WS-CUST-LNAME
                   WS-CUST-PHONE
                   WS-CUST-EMAIL
                   WS-CUST-ADDRESS
                   WS-CUST-ZIP
                   WS-CUST-CITY
                   WS-CUST-COUNTRY.
