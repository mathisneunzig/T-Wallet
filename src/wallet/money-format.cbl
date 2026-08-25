       IDENTIFICATION DIVISION.
       PROGRAM-ID. MONEY-FORMAT.

       DATA DIVISION.

       WORKING-STORAGE SECTION.

       01 WS-MULTIPLIER
           PIC 9(7)
           VALUE 1.

       01 WS-WHOLE-AMOUNT
           PIC 9(18)
           VALUE 0.

       01 WS-FRACTION-AMOUNT
           PIC 9(6)
           VALUE 0.

       01 WS-WHOLE-DISPLAY
           PIC Z(17)9.

       01 WS-FRACTION-DISPLAY
           PIC X(6)
           VALUE SPACES.

       LINKAGE SECTION.

       01 LK-CURRENCY
           PIC X(3).

       01 LK-DECIMALS
           PIC 9.

       01 LK-AMOUNT
           PIC 9(18).

       01 LK-FORMATTED-AMOUNT
           PIC X(40).

       PROCEDURE DIVISION
           USING
               LK-CURRENCY
               LK-DECIMALS
               LK-AMOUNT
               LK-FORMATTED-AMOUNT.

           MOVE SPACES
               TO LK-FORMATTED-AMOUNT.

           MOVE SPACES
               TO WS-FRACTION-DISPLAY.

           PERFORM GET-MULTIPLIER.

           DIVIDE LK-AMOUNT
               BY WS-MULTIPLIER
               GIVING WS-WHOLE-AMOUNT
               REMAINDER WS-FRACTION-AMOUNT.

           MOVE WS-WHOLE-AMOUNT
               TO WS-WHOLE-DISPLAY.

           IF LK-DECIMALS = 0

               STRING
                   WS-WHOLE-DISPLAY
                   " "
                   LK-CURRENCY
                   DELIMITED BY SIZE
                   INTO LK-FORMATTED-AMOUNT

           ELSE

               PERFORM BUILD-FRACTION

               STRING
                   WS-WHOLE-DISPLAY
                   "."
                   WS-FRACTION-DISPLAY
                   " "
                   LK-CURRENCY
                   DELIMITED BY SIZE
                   INTO LK-FORMATTED-AMOUNT

           END-IF.

           GOBACK.


       BUILD-FRACTION.

           EVALUATE LK-DECIMALS

               WHEN 1

                   MOVE WS-FRACTION-AMOUNT(6:1)
                       TO WS-FRACTION-DISPLAY(1:1)

               WHEN 2

                   MOVE WS-FRACTION-AMOUNT(5:2)
                       TO WS-FRACTION-DISPLAY(1:2)

               WHEN 3

                   MOVE WS-FRACTION-AMOUNT(4:3)
                       TO WS-FRACTION-DISPLAY(1:3)

               WHEN 4

                   MOVE WS-FRACTION-AMOUNT(3:4)
                       TO WS-FRACTION-DISPLAY(1:4)

               WHEN 5

                   MOVE WS-FRACTION-AMOUNT(2:5)
                       TO WS-FRACTION-DISPLAY(1:5)

               WHEN 6

                   MOVE WS-FRACTION-AMOUNT
                       TO WS-FRACTION-DISPLAY

               WHEN OTHER

                   MOVE SPACES
                       TO WS-FRACTION-DISPLAY

           END-EVALUATE.


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
           