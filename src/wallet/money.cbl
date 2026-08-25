       IDENTIFICATION DIVISION.
       PROGRAM-ID. MONEY.

       DATA DIVISION.

       WORKING-STORAGE SECTION.

       01 WS-MULTIPLIER
           PIC 9(6)
           VALUE 1.

       01 WS-WHOLE-AMOUNT
           PIC 9(18)
           VALUE 0.

       01 WS-FRACTION-AMOUNT
           PIC 9(6)
           VALUE 0.

       LINKAGE SECTION.

       01 LK-CURRENCY
           PIC X(3).

       01 LK-DECIMALS
           PIC 9.

       01 LK-AMOUNT
           PIC 9(18).

       PROCEDURE DIVISION
           USING
               LK-CURRENCY
               LK-DECIMALS
               LK-AMOUNT.

           MOVE 0
               TO LK-AMOUNT.

           MOVE 0
               TO WS-WHOLE-AMOUNT.

           MOVE 0
               TO WS-FRACTION-AMOUNT.

           PERFORM GET-MULTIPLIER.

           DISPLAY " ".
           DISPLAY "Amount in " LK-CURRENCY.
           DISPLAY "Whole amount: ".

           ACCEPT WS-WHOLE-AMOUNT.

           IF LK-DECIMALS > 0

               DISPLAY "Fractional amount: "
               ACCEPT WS-FRACTION-AMOUNT

           END-IF.

           COMPUTE LK-AMOUNT =
               WS-WHOLE-AMOUNT * WS-MULTIPLIER
               + WS-FRACTION-AMOUNT.

           GOBACK.


       GET-MULTIPLIER.

           EVALUATE LK-DECIMALS

               WHEN 0
                   MOVE 1
                       TO WS-MULTIPLIER

               WHEN 1
                   MOVE 10
                       TO WS-MULTIPLIER

               WHEN 2
                   MOVE 100
                       TO WS-MULTIPLIER

               WHEN 3
                   MOVE 1000
                       TO WS-MULTIPLIER

               WHEN 4
                   MOVE 10000
                       TO WS-MULTIPLIER

               WHEN 5
                   MOVE 100000
                       TO WS-MULTIPLIER

               WHEN 6
                   MOVE 1000000
                       TO WS-MULTIPLIER

               WHEN OTHER
                   MOVE 1
                       TO WS-MULTIPLIER

           END-EVALUATE.
           