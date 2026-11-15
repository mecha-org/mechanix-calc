import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/result_formatter.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc() : super(const CalculatorState()) {
    on<CalculateResult>(_onCalculateResult);
    on<ClearPressed>(_onClearPressed);
  }

  static final _numberCharPattern = RegExp(r'[0-9.]');
  static final _leadingDecimalPattern = RegExp(r'(?<=[+\-*/])\.');
  static final _negativeNumberPattern = RegExp(
    r'(?<=[+\-*/])-(?:\d+(?:\.\d+)?|\.\d+)',
  );
  static final _operandEndPattern = RegExp(r'[0-9.)%]');

  /// Start index of the operand a `%` at [percentIndex] applies to: a number
  /// ("10%") or a bracketed group ("(-5)%", "(-9.9*10^(17))%").
  /// Returns -1 when there is no operand (e.g. "5+%").
  static int _findPercentOperandStart(String expression, int percentIndex) {
    var i = percentIndex - 1;
    if (i < 0) return -1;

    if (expression[i] == ')') {
      var depth = 0;
      for (; i >= 0; i--) {
        if (expression[i] == ')') {
          depth++;
        } else if (expression[i] == '(') {
          depth--;
          if (depth == 0) return i;
        }
      }
      return -1;
    }

    var start = percentIndex;
    while (start > 0 && _numberCharPattern.hasMatch(expression[start - 1])) {
      start--;
    }
    return start < percentIndex ? start : -1;
  }

  /// Rewrites binary `+%` and `-%` as a percentage of the preceding
  /// operand within the same parenthesis group. Multiplication,
  /// division, and unary minus retain the plain `/100` conversion.
  static String resolvePercentageExpressions(String expression) {
    var result = expression;
    var searchFrom = 0;
    while (true) {
      final percentIndex = result.indexOf('%', searchFrom);
      if (percentIndex == -1) break;

      final operandStart = _findPercentOperandStart(result, percentIndex);
      final opIndex = operandStart - 1;
      final op = operandStart > 0 ? result[opIndex] : '';
      final isBinaryAdditive =
          (op == '+' || op == '-') &&
          opIndex > 0 &&
          _operandEndPattern.hasMatch(result[opIndex - 1]);

      if (!isBinaryAdditive) {
        searchFrom = percentIndex + 1;
        continue;
      }

      // Walk left to the start of the enclosing parenthesis group.
      var depth = 0;
      var i = opIndex - 1;
      for (; i >= 0; i--) {
        final c = result[i];
        if (c == ')') {
          depth++;
        } else if (c == '(') {
          if (depth == 0) break;
          depth--;
        }
      }
      final base = result.substring(i + 1, opIndex);

      // Insert the base's value rather than its text: copying the text
      // makes chained percentages (1+1%+1%+…) grow exponentially.
      final operand = result.substring(operandStart, percentIndex);
      final replacement =
          '(${_toLiteral(_evaluateConvertedExpression(base))}*$operand/100)';
      result = result.replaceRange(operandStart, percentIndex + 1, replacement);
      searchFrom = operandStart + replacement.length;
    }
    return result;
  }

  /// Evaluates an expression whose display symbols are already converted
  /// (`*`, `/`, `^`, no commas) and whose `+%`/`-%` terms are resolved.
  static double _evaluateConvertedExpression(String expression) {
    // Remaining percentages divide their operand by 100:
    // 200*50% -> 200*(50/100), (-5)% -> ((-5)/100).
    var normalized = expression;
    var percentIndex = normalized.indexOf('%');
    while (percentIndex != -1) {
      final operandStart = _findPercentOperandStart(normalized, percentIndex);
      if (operandStart == -1) {
        throw const FormatException('% without an operand');
      }
      final operand = normalized.substring(operandStart, percentIndex);
      normalized = normalized.replaceRange(
        operandStart,
        percentIndex + 1,
        '($operand/100)',
      );
      percentIndex = normalized.indexOf('%');
    }
    // E.g., -2*-2 -> -2*(-2), 5+-3 -> 5+(-3), 10/-2 -> 10/(-2), 5--3 -> 5-(-3)
    normalized = normalized.replaceAllMapped(
      _negativeNumberPattern,
      (match) => '(${match.group(0)})',
    );
    final exp = GrammarParser().parse(normalized);
    return exp.evaluate(EvaluationType.REAL, ContextModel()).toDouble();
  }

  /// A parseable, exact literal for [value] (the grammar has no `e`
  /// notation, so 1e21 becomes `(1*10^(21))`).
  static String _toLiteral(double value) {
    final text = value.toString();
    if (!text.contains('e')) return '($text)';
    final parts = value.toStringAsExponential().split('e');
    return '(${parts[0]}*10^(${int.parse(parts[1])}))';
  }

  void _onClearPressed(ClearPressed event, Emitter<CalculatorState> emit) {
    emit(state.copyWith(expression: '', result: '0', errorMessage: ''));
  }

  void _onCalculateResult(
    CalculateResult event,
    Emitter<CalculatorState> emit,
  ) {
    final expressionToEvaluate = event.expression.isNotEmpty
        ? event.expression
        : state.expression;

    if (expressionToEvaluate.isEmpty) return;

    try {
      // Scientific results reused in a new calculation: 9.9×10¹⁷ -> 9.9*10^(17)
      String finalExpression = ResultFormatter.toEvaluable(
        expressionToEvaluate,
      ).replaceAll(',', '').replaceAll('×', '*').replaceAll('÷', '/');

      // Convert leading decimal values to valid numeric expressions.
      // Example: 4*.2 -> 4*0.2
      finalExpression = finalExpression.replaceAllMapped(
        _leadingDecimalPattern,
        (_) => '0.',
      );

      // Percent after a binary + or - is relative to the left operand,
      // matching common calculators: 200+10% -> 200+(200*10/100) = 220.
      finalExpression = resolvePercentageExpressions(finalExpression);

      // Remaining percentages (200*50% -> 200*(50/100)), negative wrapping.
      final eval = _evaluateConvertedExpression(finalExpression);

      // Handle Division by Zero or other invalid mathematical results
      if (eval.isInfinite || eval.isNaN) {
        emit(
          state.copyWith(
            expression: expressionToEvaluate,
            result: '',
            errorMessage: invalidOperationsErrorMessage,
          ),
        );
        return;
      }

      // Plain up to 15 significant digits; scientific (e.g. 9.99999998×10¹⁷)
      // beyond that, so rounded digits are never shown as exact zeros.
      final result = ResultFormatter.format(eval);

      final updatedHistory = List<HistoryItem>.from(state.history)
        ..insert(
          0,
          HistoryItem(expression: expressionToEvaluate, result: result),
        );

      emit(
        state.copyWith(
          expression: expressionToEvaluate,
          result: result,
          history: updatedHistory,
          errorMessage: '',
        ),
      );
    } catch (e) {
      // Catch syntax errors (e.g., malformed expressions like "5++5")
      emit(
        state.copyWith(
          expression: expressionToEvaluate,
          result: '',
          errorMessage: invalidOperationsErrorMessage,
        ),
      );
    }
  }
}
