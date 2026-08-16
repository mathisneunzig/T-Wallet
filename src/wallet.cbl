       IDENTIFICATION DIVISION.
       PROGRAM-ID. WALLET.

       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.

       FILE-CONTROL.
           SELECT TRANSACTION-FILE
               ASSIGN TO "data/transactions.dat"
               ORGANIZATION IS LINE SEQUENTIAL.

       DATA DIVISION.

       FILE SECTION.

       FD TRANSACTION-FILE.
       01 TRANSACTION-RECORD.
           05 FILE-TRANSACTION-TYPE   PIC X(10).
           05 FILE-TRANSACTION-AMOUNT PIC 9(5)V99.

       WORKING-STORAGE SECTION.

       01 WS-BALANCE PIC 9(5)V99 VALUE 0.
       01 WS-DEPOSIT PIC 9(5)V99 VALUE 0.
       01 WS-PAYMENT PIC 9(5)V99 VALUE 0.

       01 WS-TRANSACTION.
           05 WS-TRANSACTION-TYPE   PIC X(10).
           05 WS-TRANSACTION-AMOUNT PIC 9(5)V99.

       PROCEDURE DIVISION.

           OPEN EXTEND TRANSACTION-FILE.

           DISPLAY "========================".
           DISPLAY "     STADIUM WALLET".
           DISPLAY "========================".

           DISPLAY "Current balance: " WS-BALANCE.

           DISPLAY "Enter deposit: ".
           ACCEPT WS-DEPOSIT.

           ADD WS-DEPOSIT TO WS-BALANCE.

           MOVE "DEPOSIT" TO WS-TRANSACTION-TYPE.
           MOVE WS-DEPOSIT TO WS-TRANSACTION-AMOUNT.

           MOVE WS-TRANSACTION-TYPE
               TO FILE-TRANSACTION-TYPE.

           MOVE WS-TRANSACTION-AMOUNT
               TO FILE-TRANSACTION-AMOUNT.

           WRITE TRANSACTION-RECORD.

           DISPLAY "Deposit successful!".
           DISPLAY "New balance: " WS-BALANCE.

           DISPLAY "Enter payment: ".
           ACCEPT WS-PAYMENT.

           IF WS-BALANCE >= WS-PAYMENT

               SUBTRACT WS-PAYMENT FROM WS-BALANCE

               MOVE "PAYMENT" TO WS-TRANSACTION-TYPE
               MOVE WS-PAYMENT TO WS-TRANSACTION-AMOUNT

               MOVE WS-TRANSACTION-TYPE
                   TO FILE-TRANSACTION-TYPE

               MOVE WS-TRANSACTION-AMOUNT
                   TO FILE-TRANSACTION-AMOUNT

               WRITE TRANSACTION-RECORD

               DISPLAY "Payment successful!"
               DISPLAY "New balance: " WS-BALANCE

           ELSE

               DISPLAY "Payment rejected!"
               DISPLAY "Insufficient balance."

           END-IF.

           CLOSE TRANSACTION-FILE.

           STOP RUN.
           