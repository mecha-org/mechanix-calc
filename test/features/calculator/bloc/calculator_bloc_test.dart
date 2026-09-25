import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_bloc.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_event.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_state.dart';

void main() {
  group('CalculatorBloc', () {
    late CalculatorBloc calculatorBloc;

    setUp(() {
      calculatorBloc = CalculatorBloc();
    });

    tearDown(() {
      calculatorBloc.close();
    });

    test('initial state should be empty expression and result 0', () {
      expect(
        calculatorBloc.state,
        const CalculatorState(expression: '', result: '0', history: []),
      );
    });

    test('ClearPressed should NOT clear history', () async {
      final expectedStates = [
        const CalculatorState(expression: '5', result: '0', history: []),
        const CalculatorState(expression: '5+', result: '', history: []),
        const CalculatorState(expression: '5+3', result: '', history: []),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '')
            .having((s) => s.result, 'result', '8')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '')
            .having((s) => s.result, 'result', '0')
            .having((s) => s.history.length, 'history length', 1),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      // 1. Calculate something to add to history
      calculatorBloc.add(const NumberPressed('5'));
      calculatorBloc.add(const OperatorPressed('+'));
      calculatorBloc.add(const NumberPressed('3'));
      calculatorBloc.add(const CalculateResult());

      // 2. Clear current calculation
      calculatorBloc.add(const ClearPressed());
    });

    test('Multiple calculations should be added to history', () {
      final expectedStates = [
        const CalculatorState(expression: '5', result: '0', history: []),
        const CalculatorState(expression: '5+', result: '', history: []),
        const CalculatorState(expression: '5+3', result: '', history: []),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '')
            .having((s) => s.result, 'result', '8')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '1')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '15')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '15+')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '15+1')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '15+10')
            .having((s) => s.history.length, 'history length', 1),
        isA<CalculatorState>()
            .having((s) => s.expression, 'expression', '')
            .having((s) => s.result, 'result', '25')
            .having((s) => s.history.length, 'history length', 2),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      // 1. First calculation
      calculatorBloc.add(const NumberPressed('5'));
      calculatorBloc.add(const OperatorPressed('+'));
      calculatorBloc.add(const NumberPressed('3'));
      calculatorBloc.add(const CalculateResult());

      // 2. Second calculation
      calculatorBloc.add(const NumberPressed('1'));
      calculatorBloc.add(const NumberPressed('5'));
      calculatorBloc.add(const OperatorPressed('+'));
      calculatorBloc.add(const NumberPressed('1'));
      calculatorBloc.add(const NumberPressed('0'));
      calculatorBloc.add(const CalculateResult());
    });

    test('Division by zero should show error message', () {
      final expectedStates = [
        const CalculatorState(expression: '5', result: '0', history: []),
        const CalculatorState(expression: '5÷', result: '', history: []),
        const CalculatorState(expression: '5÷0', result: '', history: []),
        const CalculatorState(
          expression: '5÷0',
          result: '',
          errorMessage: invalidOperationsErrorMessage,
          history: [],
        ),
        const CalculatorState(
          expression: '',
          result: '0',
          errorMessage: '',
          history: [],
        ),
        const CalculatorState(
          expression: '1',
          result: '0',
          errorMessage: '',
          history: [],
        ),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      calculatorBloc.add(const NumberPressed('5'));
      calculatorBloc.add(const OperatorPressed('÷'));
      calculatorBloc.add(const NumberPressed('0'));
      calculatorBloc.add(const CalculateResult());

      // Clear the error and state before pressing a new number to match expected state exactly
      calculatorBloc.add(const ClearPressed());
      calculatorBloc.add(const NumberPressed('1'));
    });

    test('Malformed expression should show error message', () {
      final expectedStates = [
        const CalculatorState(expression: '5', result: '0', history: []),
        const CalculatorState(expression: '5+', result: '', history: []),
        const CalculatorState(
          expression: '5+',
          result: '',
          errorMessage: invalidOperationsErrorMessage,
          history: [],
        ),
        const CalculatorState(
          expression: '',
          result: '0',
          errorMessage: '',
          history: [],
        ),
      ];

      expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

      calculatorBloc.add(const NumberPressed('5'));
      calculatorBloc.add(const OperatorPressed('+'));
      calculatorBloc.add(const CalculateResult());

      // Pressing AC should clear error message
      calculatorBloc.add(const ClearPressed());
    });

    test(
      'Multiplying a negative result by zero should yield 0 instead of -0',
      () {
        final expectedStates = [
          // 1. Typing '10'
          const CalculatorState(expression: '1', result: '0', history: []),
          const CalculatorState(expression: '10', result: '0', history: []),

          // 2. Pressing '-'
          const CalculatorState(expression: '10-', result: '', history: []),

          // 3. Typing '20'
          const CalculatorState(expression: '10-2', result: '', history: []),
          const CalculatorState(expression: '10-20', result: '', history: []),

          // 4. First calculation: 10 - 20 = -10
          const CalculatorState(
            expression: '',
            result: '-10',
            history: [HistoryItem(expression: '10-20', result: '-10')],
          ),

          // 5. Pressing '×'
          const CalculatorState(
            expression: '-10×',
            result: '',
            history: [HistoryItem(expression: '10-20', result: '-10')],
          ),

          // 6. Typing '0'
          const CalculatorState(
            expression: '-10×0',
            result: '',
            history: [HistoryItem(expression: '10-20', result: '-10')],
          ),

          // 7. Final calculation: -10 × 0 = 0
          const CalculatorState(
            expression: '',
            result: '0',
            history: [
              HistoryItem(expression: '-10×0', result: '0'),
              HistoryItem(expression: '10-20', result: '-10'),
            ],
          ),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        // Execute sequence for '10 - 20 ='
        calculatorBloc.add(const NumberPressed('1'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const OperatorPressed('-'));
        calculatorBloc.add(const NumberPressed('2'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const CalculateResult());

        // Execute sequence for '× 0 ='
        calculatorBloc.add(const OperatorPressed('×'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const CalculateResult());
      },
    );
    group('Decimal point handling', () {
      test('decimal on empty expression produces 0.', () {
        final expectedStates = [
          const CalculatorState(expression: '0.', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('.'));
      });

      test('decimal when expression is 0 produces 0.', () {
        final expectedStates = [
          const CalculatorState(expression: '0', result: '0', history: []),
          const CalculatorState(expression: '0.', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const NumberPressed('.'));
      });

      test('decimal when number has no decimal appends dot', () {
        final expectedStates = [
          const CalculatorState(expression: '5', result: '0', history: []),
          const CalculatorState(expression: '5.', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('5'));
        calculatorBloc.add(const NumberPressed('.'));
      });

      test('decimal ignored if current segment already has decimal', () {
        final expectedStates = [
          const CalculatorState(expression: '5', result: '0', history: []),
          const CalculatorState(expression: '5.', result: '0', history: []),
          const CalculatorState(expression: '5.5', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('5'));
        calculatorBloc.add(const NumberPressed('.'));
        calculatorBloc.add(const NumberPressed('5'));
        calculatorBloc.add(const NumberPressed('.')); // should be ignored
      });

      test('decimal allowed in second segment after operator', () {
        final expectedStates = [
          const CalculatorState(expression: '5', result: '0', history: []),
          const CalculatorState(expression: '5.', result: '0', history: []),
          const CalculatorState(expression: '5.5', result: '0', history: []),
          const CalculatorState(expression: '5.5+', result: '', history: []),
          const CalculatorState(expression: '5.5+2', result: '', history: []),
          const CalculatorState(expression: '5.5+2.', result: '', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('5'));
        calculatorBloc.add(const NumberPressed('.'));
        calculatorBloc.add(const NumberPressed('5'));
        calculatorBloc.add(const OperatorPressed('+'));
        calculatorBloc.add(const NumberPressed('2'));
        calculatorBloc.add(const NumberPressed('.'));
      });
    });

    group('Number zero replacement', () {
      test('typing non-zero replaces existing standalone 0', () {
        final expectedStates = [
          const CalculatorState(expression: '0', result: '0', history: []),
          const CalculatorState(expression: '7', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const NumberPressed('7'));
      });
    });

    group('Operator handling', () {
      test('first pressed minus on empty expression sets negative sign', () {
        final expectedStates = [
          const CalculatorState(expression: '-', result: '', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const OperatorPressed('-'));
      });

      test('consecutive operators replace the last operator', () {
        final expectedStates = [
          const CalculatorState(expression: '9', result: '0', history: []),
          const CalculatorState(expression: '9+', result: '', history: []),
          const CalculatorState(expression: '9-', result: '', history: []),
          const CalculatorState(expression: '9×', result: '', history: []),
          const CalculatorState(expression: '9÷', result: '', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('9'));
        calculatorBloc.add(const OperatorPressed('+'));
        calculatorBloc.add(const OperatorPressed('-'));
        calculatorBloc.add(const OperatorPressed('×'));
        calculatorBloc.add(const OperatorPressed('÷'));
      });
    });

    group('DeletePressed', () {
      test('deletes last character when expression is not empty', () {
        final expectedStates = [
          const CalculatorState(expression: '1', result: '0', history: []),
          const CalculatorState(expression: '12', result: '0', history: []),
          const CalculatorState(expression: '1', result: '0', history: []),
          const CalculatorState(expression: '', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('1'));
        calculatorBloc.add(const NumberPressed('2'));
        calculatorBloc.add(const DeletePressed());
        calculatorBloc.add(const DeletePressed());
      });

      test('does nothing when expression is empty', () {
        calculatorBloc.add(const DeletePressed());
        expect(calculatorBloc.state.expression, '');
      });
    });

    group('ToggleSignPressed', () {
      test('does nothing when expression is empty', () {
        calculatorBloc.add(const ToggleSignPressed());
        expect(calculatorBloc.state.expression, '');
      });

      test('toggles positive expression to negative and back', () {
        final expectedStates = [
          const CalculatorState(expression: '4', result: '0', history: []),
          const CalculatorState(expression: '42', result: '0', history: []),
          const CalculatorState(expression: '-42', result: '0', history: []),
          const CalculatorState(expression: '42', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('4'));
        calculatorBloc.add(const NumberPressed('2'));
        calculatorBloc.add(const ToggleSignPressed());
        calculatorBloc.add(const ToggleSignPressed());
      });
    });

    group('PercentagePressed', () {
      test('does nothing when expression is empty', () {
        calculatorBloc.add(const PercentagePressed());
        expect(calculatorBloc.state.expression, '');
      });

      test('appends % when expression is not empty', () {
        final expectedStates = [
          const CalculatorState(expression: '5', result: '0', history: []),
          const CalculatorState(expression: '50', result: '0', history: []),
          const CalculatorState(expression: '50%', result: '0', history: []),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('5'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const PercentagePressed());
      });

      test('calculates expression with percentage correctly', () {
        final expectedStates = [
          const CalculatorState(expression: '2', result: '0', history: []),
          const CalculatorState(expression: '20', result: '0', history: []),
          const CalculatorState(expression: '200', result: '0', history: []),
          const CalculatorState(expression: '200×', result: '', history: []),
          const CalculatorState(expression: '200×5', result: '', history: []),
          const CalculatorState(expression: '200×50', result: '', history: []),
          const CalculatorState(expression: '200×50%', result: '', history: []),
          isA<CalculatorState>()
              .having((s) => s.expression, 'expression', '')
              .having((s) => s.result, 'result', '100')
              .having((s) => s.history.length, 'history length', 1),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('2'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const OperatorPressed('×'));
        calculatorBloc.add(const NumberPressed('5'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const PercentagePressed());
        calculatorBloc.add(const CalculateResult());
      });
    });

    group('CalculateResult edge cases', () {
      test('does nothing when expression is empty', () {
        calculatorBloc.add(const CalculateResult());
        expect(calculatorBloc.state.expression, '');
        expect(calculatorBloc.state.result, '0');
      });

      test('formats large whole numbers with comma separators', () {
        final expectedStates = [
          const CalculatorState(expression: '1', result: '0', history: []),
          const CalculatorState(expression: '10', result: '0', history: []),
          const CalculatorState(expression: '100', result: '0', history: []),
          const CalculatorState(expression: '1000', result: '0', history: []),
          const CalculatorState(expression: '1000+', result: '', history: []),
          const CalculatorState(expression: '1000+2', result: '', history: []),
          const CalculatorState(expression: '1000+20', result: '', history: []),
          const CalculatorState(
            expression: '1000+200',
            result: '',
            history: [],
          ),

          const CalculatorState(
            expression: '1000+2000',
            result: '',
            history: [],
          ),
          isA<CalculatorState>()
              .having((s) => s.expression, 'expression', '')
              .having((s) => s.result, 'result', '3,000')
              .having((s) => s.history.first.result, 'history result', '3,000'),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const NumberPressed('1'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const OperatorPressed('+'));
        calculatorBloc.add(const NumberPressed('2'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const NumberPressed('0'));
        calculatorBloc.add(const CalculateResult());
      });
    });

    group('ExpressionChanged', () {
      test('sets expression and clears result and error', () {
        final expectedStates = [
          const CalculatorState(
            expression: '15+25',
            result: '',
            errorMessage: '',
            history: [],
          ),
        ];

        expectLater(calculatorBloc.stream, emitsInOrder(expectedStates));

        calculatorBloc.add(const ExpressionChanged('15+25'));
      });
    });

    group('Limits: 15 Digits, 20 Operations, and 100 Characters', () {
      test('20 operations limit prevents adding the 21st operation', () async {
        // Build 20 operations:
        // "1+1+1+...+1+".
        for (int i = 0; i < 20; i++) {
          calculatorBloc.add(const NumberPressed('1'));
          calculatorBloc.add(const OperatorPressed('+'));
        }

        await pumpEventQueue();

        final exprWith20Ops = calculatorBloc.state.expression;

        // 20 operations should be accepted.
        expect(exprWith20Ops.endsWith('+'), isTrue);
        expect(calculatorBloc.state.errorMessage, '');

        // Adding a number does not increase the operation count,
        // so it should still be allowed.
        calculatorBloc.add(const NumberPressed('1'));
        await pumpEventQueue();

        final exprWith20OpsAndNumber = calculatorBloc.state.expression;

        expect(exprWith20OpsAndNumber.endsWith('1'), isTrue);
        expect(calculatorBloc.state.errorMessage, '');

        // Adding another operator would create the 21st operation,
        // so it should be blocked.
        calculatorBloc.add(const OperatorPressed('+'));
        await pumpEventQueue();

        expect(calculatorBloc.state.expression, exprWith20OpsAndNumber);
        expect(calculatorBloc.state.errorMessage, maxOperationsErrorMessage);

        // Delete the last number.
        calculatorBloc.add(const DeletePressed());
        await pumpEventQueue();

        expect(calculatorBloc.state.errorMessage, '');

        // The expression is back to 20 operations.
        expect(calculatorBloc.state.expression, exprWith20Ops);
      });

      test(
        'single number has 15 digits limit and shows digits limit message',
        () async {
          // Type 15 digits
          for (int i = 0; i < 15; i++) {
            calculatorBloc.add(const NumberPressed('1'));
          }
          await pumpEventQueue();

          expect(calculatorBloc.state.expression, '111111111111111');
          expect(calculatorBloc.state.errorMessage, '');

          // 16th digit on the same number should be blocked
          calculatorBloc.add(const NumberPressed('1'));
          await pumpEventQueue();

          expect(calculatorBloc.state.expression, '111111111111111');
          expect(
            calculatorBloc.state.errorMessage,
            "Can't enter more than 15 digits",
          );

          // Pressing an operator starts a new number and clears error
          calculatorBloc.add(const OperatorPressed('+'));
          await pumpEventQueue();

          expect(calculatorBloc.state.expression, '111111111111111+');
          expect(calculatorBloc.state.errorMessage, '');

          // Second number can accept up to 15 digits
          for (int i = 0; i < 15; i++) {
            calculatorBloc.add(const NumberPressed('2'));
          }
          await pumpEventQueue();

          expect(
            calculatorBloc.state.expression,
            '111111111111111+222222222222222',
          );
          expect(calculatorBloc.state.errorMessage, '');

          // 16th digit on second number is blocked
          calculatorBloc.add(const NumberPressed('2'));
          await pumpEventQueue();

          expect(
            calculatorBloc.state.expression,
            '111111111111111+222222222222222',
          );
          expect(
            calculatorBloc.state.errorMessage,
            "Can't enter more than 15 digits",
          );
        },
      );

      test('decimal numbers respect 15 digits limit', () async {
        // 14 digits, decimal point, 1 digit = 15 digits total
        for (int i = 0; i < 14; i++) {
          calculatorBloc.add(const NumberPressed('3'));
        }
        calculatorBloc.add(const NumberPressed('.'));
        calculatorBloc.add(const NumberPressed('3'));
        await pumpEventQueue();

        expect(calculatorBloc.state.expression, '33333333333333.3');
        expect(calculatorBloc.state.errorMessage, '');

        // Additional digit is blocked
        calculatorBloc.add(const NumberPressed('3'));
        await pumpEventQueue();

        expect(calculatorBloc.state.expression, '33333333333333.3');
        expect(
          calculatorBloc.state.errorMessage,
          "Can't enter more than 15 digits",
        );
      });

      test(
        'allows five 15-digit numbers separated by plus signs (79 chars)',
        () async {
          // 111111111111111 + 222222222222222 + 333333333333333 + 444444444444444 + 555555555555555
          for (int num = 1; num <= 5; num++) {
            if (num > 1) {
              calculatorBloc.add(const OperatorPressed('+'));
            }
            for (int d = 0; d < 15; d++) {
              calculatorBloc.add(NumberPressed('$num'));
            }
          }
          await pumpEventQueue();

          expect(calculatorBloc.state.expression.length, 79);
          expect(calculatorBloc.state.errorMessage, '');
        },
      );

      test(
        '100 characters limit blocks further typing and shows characters limit message',
        () async {
          // Build 100 characters: 6 numbers of 15 digits (90) + 5 operators (5) + 1 number of 5 digits (5) = 100
          for (int i = 0; i < 6; i++) {
            if (i > 0) {
              calculatorBloc.add(const OperatorPressed('+'));
            }
            for (int d = 0; d < 15; d++) {
              calculatorBloc.add(const NumberPressed('1'));
            }
          }
          // Current length: 95. Add '+' and 4 digits = 100
          calculatorBloc.add(const OperatorPressed('+'));
          for (int d = 0; d < 4; d++) {
            calculatorBloc.add(const NumberPressed('1'));
          }
          await pumpEventQueue();

          expect(calculatorBloc.state.expression.length, 100);
          expect(calculatorBloc.state.errorMessage, '');

          // Typing 101st character should be blocked and show error
          calculatorBloc.add(const NumberPressed('2'));
          await pumpEventQueue();

          expect(calculatorBloc.state.expression.length, 100);
          expect(
            calculatorBloc.state.errorMessage,
            "Can't enter more than 100 characters",
          );

          // Adding an operator at 100 characters is also blocked
          calculatorBloc.add(const OperatorPressed('+'));
          await pumpEventQueue();

          expect(calculatorBloc.state.expression.length, 100);
          expect(
            calculatorBloc.state.errorMessage,
            "Can't enter more than 100 characters",
          );

          // Deleting one character clears error and allows typing up to 100 again
          calculatorBloc.add(const DeletePressed());
          await pumpEventQueue();

          expect(calculatorBloc.state.expression.length, 99);
          expect(calculatorBloc.state.errorMessage, '');

          calculatorBloc.add(const NumberPressed('9'));
          await pumpEventQueue();

          expect(calculatorBloc.state.expression.length, 100);
          expect(calculatorBloc.state.expression.endsWith('9'), isTrue);
          expect(calculatorBloc.state.errorMessage, '');
        },
      );

      test('ToggleSignPressed respects 100 characters limit', () async {
        // Build 100 characters
        for (int i = 0; i < 6; i++) {
          if (i > 0) {
            calculatorBloc.add(const OperatorPressed('+'));
          }
          for (int d = 0; d < 15; d++) {
            calculatorBloc.add(const NumberPressed('5'));
          }
        }
        calculatorBloc.add(const OperatorPressed('+'));
        for (int d = 0; d < 4; d++) {
          calculatorBloc.add(const NumberPressed('5'));
        }
        await pumpEventQueue();

        expect(calculatorBloc.state.expression.length, 100);

        // Toggling sign would make it 101 characters, so it should be blocked
        calculatorBloc.add(const ToggleSignPressed());
        await pumpEventQueue();

        expect(calculatorBloc.state.expression.length, 100);
        expect(calculatorBloc.state.expression.startsWith('-'), isFalse);
        expect(
          calculatorBloc.state.errorMessage,
          "Can't enter more than 100 characters",
        );
      });

      test('PercentagePressed respects 100 characters limit', () async {
        // Build 100 characters
        for (int i = 0; i < 6; i++) {
          if (i > 0) {
            calculatorBloc.add(const OperatorPressed('+'));
          }
          for (int d = 0; d < 15; d++) {
            calculatorBloc.add(const NumberPressed('5'));
          }
        }
        calculatorBloc.add(const OperatorPressed('+'));
        for (int d = 0; d < 4; d++) {
          calculatorBloc.add(const NumberPressed('5'));
        }
        await pumpEventQueue();

        calculatorBloc.add(const PercentagePressed());
        await pumpEventQueue();

        expect(calculatorBloc.state.expression.length, 100);
        expect(
          calculatorBloc.state.errorMessage,
          "Can't enter more than 100 characters",
        );
      });
    });
  });
}
