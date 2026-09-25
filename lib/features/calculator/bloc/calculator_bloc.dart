import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
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

  static const _operators = ['+', '-', '×', '÷', '%'];
  static final _percentPattern = RegExp(r'(\d+(?:\.\d+)?)%');
  static final _numberFormattingPattern = RegExp(
    r'(\d{1,3})(?=(\d{3})+(?!\d))',
  );
  static final _operatorSplitPattern = RegExp(r'[+\-×÷%]');

  static int _countOperations(String expression) {
    if (expression.isEmpty) return 0;

    int count = 0;
    for (int i = 0; i < expression.length; i++) {
      final char = expression[i];
      // Count '-' as an operator only when it's not a leading negative sign.
      if (operationCharacters.contains(char)) {
        count++;
      } else if (char == '-' && i > 0) {
        count++;
      }
    }
    return count;
  }

  static bool _hasNumberExceedingMaxDigits(String expression) {
    final segments = expression.split(_operatorSplitPattern);
    for (final segment in segments) {
      final digits = segment.replaceAll(RegExp(r'\D'), '');
      if (digits.length > maxDigits) {
        return true;
      }
    }
    return false;
  }

  static String? _validateExpressionLimits(String expression) {
    if (expression.length > maxCharacters) {
      return maxCharactersErrorMessage;
    }
    if (_countOperations(expression) > maxOperations) {
      return maxOperationsErrorMessage;
    }
    if (_hasNumberExceedingMaxDigits(expression)) {
      return maxDigitsErrorMessage;
    }
    return null;
  }

  void _onNumberPressed(NumberPressed event, Emitter<CalculatorState> emit) {
    String resultingExpression;

    if (event.number == '.') {
      final segments = state.expression.split(_operatorSplitPattern);
      if (segments.isNotEmpty && segments.last.contains('.')) {
        return;
      }
      resultingExpression =
          (state.expression.isEmpty || state.expression == '0')
          ? '0.'
          : '${state.expression}.';
    } else {
      resultingExpression = state.expression == '0'
          ? event.number
          : state.expression + event.number;
    }

    final error = _validateExpressionLimits(resultingExpression);
    if (error != null) {
      emit(state.copyWith(errorMessage: error));
      return;
    }

    emit(state.copyWith(expression: resultingExpression, errorMessage: ''));
  }

  void _onOperatorPressed(
    OperatorPressed event,
    Emitter<CalculatorState> emit,
  ) {
    // If the screen is empty and there is no previous result,
    // treat a first-pressed '-' strictly as a negative sign.
    if (state.expression.isEmpty && event.operator == '-') {
      emit(state.copyWith(expression: '-', result: '', errorMessage: ''));
      return;
    }

    String resultingExpression;
    if (state.expression.isEmpty) {
      if (state.result.isNotEmpty) {
        resultingExpression = state.result + event.operator;
      } else {
        return;
      }
    } else {
      final lastChar = state.expression[state.expression.length - 1];
      if (_operators.contains(lastChar)) {
        resultingExpression =
            state.expression.substring(0, state.expression.length - 1) +
            event.operator;
      } else {
        resultingExpression = state.expression + event.operator;
      }
    }

    final error = _validateExpressionLimits(resultingExpression);
    if (error != null) {
      emit(state.copyWith(errorMessage: error));
      return;
    }

    emit(
      state.copyWith(
        expression: resultingExpression,
        result: '',
        errorMessage: '',
      ),
    );
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

      // Convert percentage values to division by 100 for evaluation.
      finalExpression = finalExpression.replaceAllMapped(
        _percentPattern,
        (match) => '(${match[1]}/100)',
      );

      GrammarParser p = GrammarParser();
      Expression exp = p.parse(finalExpression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      // Handle Division by Zero or other invalid mathematical results
      if (eval.isInfinite || eval.isNaN) {
        emit(
          state.copyWith(
            result: '',
            errorMessage: invalidOperationsErrorMessage,
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
        result = result.replaceAllMapped(
          _numberFormattingPattern,
          (match) => '${match[1]},',
        );
      }

      final updatedHistory = List<HistoryItem>.from(state.history)
        ..insert(0, HistoryItem(expression: state.expression, result: result));

      emit(
        state.copyWith(
          expression: "",
          result: result,
          history: updatedHistory,
          errorMessage: '',
        ),
      );
    } catch (e) {
      // Catch syntax errors (e.g., malformed expressions like "5++5")
      emit(
        state.copyWith(result: '', errorMessage: invalidOperationsErrorMessage),
      );
    }
  }

  void _onToggleSignPressed(
    ToggleSignPressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.expression.isEmpty) return;

    final resultingExpression = state.expression.startsWith('-')
        ? state.expression.substring(1)
        : '-${state.expression}';

    final error = _validateExpressionLimits(resultingExpression);
    if (error != null) {
      emit(state.copyWith(errorMessage: error));
      return;
    }

    emit(state.copyWith(expression: resultingExpression, errorMessage: ''));
  }

  void _onPercentagePressed(
    PercentagePressed event,
    Emitter<CalculatorState> emit,
  ) {
    if (state.expression.isEmpty) return;

    final resultingExpression = '${state.expression}%';
    final error = _validateExpressionLimits(resultingExpression);
    if (error != null) {
      emit(state.copyWith(errorMessage: error));
      return;
    }

    emit(state.copyWith(expression: resultingExpression, errorMessage: ''));
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
