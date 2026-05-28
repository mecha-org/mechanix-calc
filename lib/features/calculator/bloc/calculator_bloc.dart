import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:math_expressions/math_expressions.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc() : super(const CalculatorState()) {
    on<NumberPressed>(_onNumberPressed);
    on<OperatorPressed>(_onOperatorPressed);
    on<ClearPressed>(_onClearPressed);
    on<DeletePressed>(_onDeletePressed);
    on<CalculateResult>(_onCalculateResult);
    on<ToggleSignPressed>(_onToggleSignPressed);
    on<PercentagePressed>(_onPercentagePressed);
    on<ExpressionChanged>(_onExpressionChanged);
  }

  void _onNumberPressed(NumberPressed event, Emitter<CalculatorState> emit) {
    String newExpression = state.expression;

    // 1. Handle decimal point press
    if (event.number == '.') {
      // If the screen is empty or currently just '0', force it to be '0.'
      if (newExpression.isEmpty || newExpression == '0') {
        newExpression = '0.';
      } else {
        // SAFEGUARD: Prevent adding multiple decimals in a single number (e.g., '5.5.')
        final segments = newExpression.split(RegExp(r'[+\-×÷%]'));
        if (segments.isNotEmpty && segments.last.contains('.')) {
          return; // Ignore the press if this number already has a decimal point
        }
        newExpression += '.';
      }
    }
    // 2. Handle normal numbers (0-9)
    else {
      if (newExpression == '0') {
        newExpression = event.number;
      } else {
        newExpression += event.number;
      }
    }

    emit(state.copyWith(expression: newExpression, errorMessage: ''));
  }

  void _onOperatorPressed(
    OperatorPressed event,
    Emitter<CalculatorState> emit,
  ) {
    const operators = ['+', '-', '×', '÷', '%'];

    // If the screen is empty or currently shows just '0', and there is no
    // previous result, treat a first-pressed '-' strictly as a negative sign.
    if (state.expression.isEmpty && event.operator == '-') {
      emit(state.copyWith(expression: '-', result: '', errorMessage: ''));
      return;
    }

    // 1. Handle the case where the expression is empty
    if (state.expression.isEmpty) {
      // If we have a result from a previous calculation, start the new expression with it.
      // Example: result is "30". Pressing '+' makes expression "30+"
      if (state.result.isNotEmpty) {
        emit(
          state.copyWith(
            expression: state.result + event.operator,
            result:
                '', // Optional: clear the result so it doesn't linger awkwardly
          ),
        );
      }
      return;
    }

    // 2. Handle the case where the expression is NOT empty
    String lastChar = state.expression.substring(state.expression.length - 1);

    // If the last character is already an operator, replace it
    if (operators.contains(lastChar)) {
      emit(
        state.copyWith(
          expression:
              state.expression.substring(0, state.expression.length - 1) +
              event.operator,
          errorMessage: '',
        ),
      );
    } else {
      // Otherwise, just append the operator
      emit(
        state.copyWith(
          expression: state.expression + event.operator,
          errorMessage: '',
        ),
      );
    }
  }

  void _onClearPressed(ClearPressed event, Emitter<CalculatorState> emit) {
    emit(state.copyWith(expression: '', result: '0', errorMessage: ''));
  }

  void _onDeletePressed(DeletePressed event, Emitter<CalculatorState> emit) {
    if (state.expression.isNotEmpty) {
      emit(
        state.copyWith(
          expression: state.expression.substring(
            0,
            state.expression.length - 1,
          ),
          errorMessage: '',
        ),
      );
    }
  }

  void _onCalculateResult(
    CalculateResult event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.expression.isEmpty) return;

    try {
      String finalExpression = state.expression
          .replaceAll(',', '')
          .replaceAll('×', '*')
          .replaceAll('÷', '/');

      GrammarParser p = GrammarParser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Handle Division by Zero or other invalid mathematical results
      if (eval.isInfinite || eval.isNaN) {
        emit(
          state.copyWith(
            result: '',
            errorMessage: 'Invalid mathematical operation',
          ),
        );
        return;
      }

      String result;
      if (eval == 0) {
        result = '0';
      } else {
        result = double.parse(eval.toStringAsPrecision(10)).toString();
        if (result.endsWith('.0')) {
          result = result.substring(0, result.length - 2);
        }
      }

      // Formatting for whole numbers
      if (result.length > 3 && !result.contains('.')) {
        RegExp reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
        result = result.replaceAllMapped(reg, (Match m) => '${m[1]},');
      }

      final updatedHistory = List<HistoryItem>.from(state.history)
        ..insert(0, HistoryItem(expression: state.expression, result: result));

      emit(
        state.copyWith(expression: "", result: result, history: updatedHistory),
      );
    } catch (e) {
      // Catch syntax errors (e.g., malformed expressions like "5++5")
      emit(state.copyWith(result: '', errorMessage: 'Malformed expressions'));
    }
  }

  void _onToggleSignPressed(
    ToggleSignPressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.expression.isEmpty) return;

    String expression = state.expression;
    if (expression.startsWith('-')) {
      emit(
        state.copyWith(expression: expression.substring(1), errorMessage: ''),
      );
    } else {
      emit(state.copyWith(expression: '-$expression', errorMessage: ''));
    }
  }

  void _onPercentagePressed(
    PercentagePressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.expression.isEmpty) return;
    emit(state.copyWith(expression: '${state.expression}%', errorMessage: ''));
    // Usually percentage divides by 100, but often in calculators it acts as an operator or immediate transform.
    // For simplicity here, we add the symbol and the parser might need to handle it or we handle it during evaluation.
    // math_expressions might not handle % natively as "divide by 100" in all contexts without custom setup.
  }

  void _onExpressionChanged(
    ExpressionChanged event,
    Emitter<CalculatorState> emit,
  ) {
    emit(
      state.copyWith(
        expression: event.expression,
        result: '',
        errorMessage: '',
      ),
    );
  }
}
