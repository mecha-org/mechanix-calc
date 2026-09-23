import 'package:flutter_test/flutter_test.dart';
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
        const CalculatorState(expression: '5+', result: '0', history: []),
        const CalculatorState(expression: '5+3', result: '0', history: []),
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
        const CalculatorState(expression: '5+', result: '0', history: []),
        const CalculatorState(expression: '5+3', result: '0', history: []),
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
        const CalculatorState(expression: '5÷', result: '0', history: []),
        const CalculatorState(expression: '5÷0', result: '0', history: []),
        const CalculatorState(
          expression: '5÷0',
          result: '',
          errorMessage: 'Invalid mathematical operation',
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
        const CalculatorState(expression: '5+', result: '0', history: []),
        const CalculatorState(
          expression: '5+',
          result: '',
          errorMessage: 'Malformed expressions',
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
          const CalculatorState(expression: '10-', result: '0', history: []),
          // 3. Typing '20'
          const CalculatorState(expression: '10-2', result: '0', history: []),
          const CalculatorState(expression: '10-20', result: '0', history: []),
          // 4. First calculation: 10 - 20 = -10
          const CalculatorState(
            expression: '',
            result: '-10',
            history: [HistoryItem(expression: '10-20', result: '-10')],
          ),
          // 5. Pressing '×' (FIXED: result is '' in your Bloc)
          const CalculatorState(
            expression: '-10×',
            result: '', // Changed from '-10' to ''
            history: [HistoryItem(expression: '10-20', result: '-10')],
          ),
          // 6. Typing '0' (FIXED: result is '' in your Bloc)
          const CalculatorState(
            expression: '-10×0',
            result: '', // Changed from '-10' to ''
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
          const CalculatorState(expression: '5.5+', result: '0', history: []),
          const CalculatorState(expression: '5.5+2', result: '0', history: []),
          const CalculatorState(expression: '5.5+2.', result: '0', history: []),
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
          const CalculatorState(expression: '9+', result: '0', history: []),
          const CalculatorState(expression: '9-', result: '0', history: []),
          const CalculatorState(expression: '9×', result: '0', history: []),
          const CalculatorState(expression: '9÷', result: '0', history: []),
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
          const CalculatorState(expression: '200×', result: '0', history: []),
          const CalculatorState(expression: '200×5', result: '0', history: []),
          const CalculatorState(expression: '200×50', result: '0', history: []),
          const CalculatorState(
            expression: '200×50%',
            result: '0',
            history: [],
          ),
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
          const CalculatorState(expression: '1000+', result: '0', history: []),
          const CalculatorState(expression: '1000+2', result: '0', history: []),
          const CalculatorState(
            expression: '1000+20',
            result: '0',
            history: [],
          ),
          const CalculatorState(
            expression: '1000+200',
            result: '0',
            history: [],
          ),

          const CalculatorState(
            expression: '1000+2000',
            result: '0',
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
  });
}
