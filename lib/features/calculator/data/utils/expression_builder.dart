import 'package:equatable/equatable.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';

class ExpressionResult extends Equatable {
  final String expression;
  final String errorMessage;

  const ExpressionResult({
    required this.expression,
    this.errorMessage = '',
  });

  @override
  List<Object?> get props => [expression, errorMessage];
}

class ExpressionBuilder {
  static const _operators = ['+', '-', '×', '÷', '%'];
  static final _operatorSplitPattern = RegExp(r'[+\-×÷%]');

  static int countOperations(String expression) {
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

  static bool hasNumberExceedingMaxDigits(String expression) {
    final segments = expression.split(_operatorSplitPattern);
    for (final segment in segments) {
      final digits = segment.replaceAll(RegExp(r'\D'), '');
      if (digits.length > maxDigits) {
        return true;
      }
    }
    return false;
  }

  static String? validateExpressionLimits(String expression) {
    if (expression.length > maxCharacters) {
      return maxCharactersErrorMessage;
    }
    if (countOperations(expression) > maxOperations) {
      return maxOperationsErrorMessage;
    }
    if (hasNumberExceedingMaxDigits(expression)) {
      return maxDigitsErrorMessage;
    }
    return null;
  }

  static ExpressionResult handleNumber(String currentExpression, String number) {
    String resultingExpression;

    if (number == '.') {
      final segments = currentExpression.split(_operatorSplitPattern);
      if (segments.isNotEmpty && segments.last.contains('.')) {
        return ExpressionResult(expression: currentExpression);
      }
      resultingExpression =
          (currentExpression.isEmpty || currentExpression == '0')
              ? '0.'
              : '$currentExpression.';
    } else {
      resultingExpression = currentExpression == '0'
          ? number
          : currentExpression + number;
    }

    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(expression: currentExpression, errorMessage: error);
    }

    return ExpressionResult(expression: resultingExpression);
  }

  static ExpressionResult handleOperator(
    String currentExpression,
    String operator, {
    String? previousResult,
  }) {
    // If the screen is empty and there is no previous result,
    // treat a first-pressed '-' strictly as a negative sign.
    if (currentExpression.isEmpty && operator == '-') {
      return const ExpressionResult(expression: '-');
    }

    String resultingExpression;
    if (currentExpression.isEmpty) {
      if (previousResult != null && previousResult.isNotEmpty) {
        resultingExpression = previousResult + operator;
      } else {
        return ExpressionResult(expression: currentExpression);
      }
    } else {
      final lastChar = currentExpression[currentExpression.length - 1];
      if (_operators.contains(lastChar)) {
        resultingExpression =
            currentExpression.substring(0, currentExpression.length - 1) +
            operator;
      } else {
        resultingExpression = currentExpression + operator;
      }
    }

    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(expression: currentExpression, errorMessage: error);
    }

    return ExpressionResult(expression: resultingExpression);
  }

  static ExpressionResult handleDelete(String currentExpression) {
    if (currentExpression.isNotEmpty) {
      return ExpressionResult(
        expression: currentExpression.substring(
          0,
          currentExpression.length - 1,
        ),
      );
    }
    return const ExpressionResult(expression: '');
  }

  static ExpressionResult handleClear() {
    return const ExpressionResult(expression: '');
  }

  static ExpressionResult handleToggleSign(String currentExpression) {
    if (currentExpression.isEmpty) {
      return const ExpressionResult(expression: '');
    }

    final resultingExpression = currentExpression.startsWith('-')
        ? currentExpression.substring(1)
        : '-$currentExpression';

    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(expression: currentExpression, errorMessage: error);
    }

    return ExpressionResult(expression: resultingExpression);
  }

  static ExpressionResult handlePercentage(String currentExpression) {
    if (currentExpression.isEmpty) {
      return const ExpressionResult(expression: '');
    }

    final resultingExpression = '$currentExpression%';
    final error = validateExpressionLimits(resultingExpression);
    if (error != null) {
      return ExpressionResult(expression: currentExpression, errorMessage: error);
    }

    return ExpressionResult(expression: resultingExpression);
  }
}
