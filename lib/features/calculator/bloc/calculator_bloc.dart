import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/expression_evaluator.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/result_formatter.dart';
import 'calculator_event.dart';
import 'calculator_state.dart';

class CalculatorBloc extends Bloc<CalculatorEvent, CalculatorState> {
  CalculatorBloc() : super(const CalculatorState()) {
    on<CalculateResult>(_onCalculateResult);
    on<ClearPressed>(_onClearPressed);
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
      // Percentages, scientific numbers (9.9×10¹⁷) and leading decimals
      // (4×.2) are understood by the evaluator directly.
      final eval = ExpressionEvaluator.evaluate(expressionToEvaluate);

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
