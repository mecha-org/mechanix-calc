import 'package:equatable/equatable.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/calc_operator.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_editor.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/pasted_text.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/text_typer.dart';
import 'package:mechanix_calculator/features/calculator/presentation/formatting/expression_renderer.dart';

class ExpressionResult extends Equatable {
  final String expression;
  final String errorMessage;

  const ExpressionResult({required this.expression, this.errorMessage = ''});

  @override
  List<Object?> get props => [expression, errorMessage];
}

/// String adapter over [ExpressionEditor] for `CalculatorScreen`,
/// Each call reads the text into tokens, applies one edit and renders the
/// result.
abstract final class ExpressionBuilder {
  static const _reader = ExpressionReader();
  static const _renderer = ExpressionRenderer();
  static const _editor = ExpressionEditor(renderer: _renderer);
  static const _typer = TextTyper(_editor);

  static ExpressionResult handleNumber(
    String currentExpression,
    String number,
  ) => _edit(
    currentExpression,
    (tokens) => number == '.'
        ? _editor.appendDecimalPoint(tokens)
        : _editor.appendDigit(tokens, number),
  );

  /// Ctrl+digit or Ctrl+`-`: extends the power of the last number or `)`.
  static ExpressionResult handleSuperscript(
    String currentExpression,
    String char,
  ) => _edit(
    currentExpression,
    (tokens) => _editor.appendSuperscript(tokens, char),
  );

  /// With empty input the operator continues [previousResult]: `42` then
  /// `+` gives `42+`.
  static ExpressionResult handleOperator(
    String currentExpression,
    String operator, {
    String? previousResult,
  }) {
    final calcOperator = CalcOperator.fromSymbol(operator);
    if (calcOperator == null) {
      return ExpressionResult(expression: currentExpression);
    }
    return _editContinuing(
      currentExpression,
      previousResult,
      (tokens) => _editor.appendOperator(tokens, calcOperator),
    );
  }

  static ExpressionResult handleOpenBracket(String currentExpression) =>
      _edit(currentExpression, _editor.appendOpenBracket);

  static ExpressionResult handleCloseBracket(String currentExpression) =>
      _edit(currentExpression, _editor.appendCloseBracket);

  static ExpressionResult handleDelete(String currentExpression) => _edit(
    currentExpression,
    (tokens) => EditResult(_editor.backspace(tokens)),
  );

  static ExpressionResult handleClear() =>
      const ExpressionResult(expression: '');

  /// With empty input, +/- negates [previousResult] as a whole:
  /// `8` -> `(-8)`, `-9.9×10¹⁷` -> `9.9×10¹⁷`.
  static ExpressionResult handleToggleSign(
    String currentExpression, {
    String? previousResult,
  }) => _editContinuing(
    currentExpression,
    previousResult,
    _editor.toggleSign,
    onResult: _editor.negateResult,
  );

  /// With empty input, `%` continues [previousResult]: `8` then `%` gives
  /// `8%`.
  static ExpressionResult handlePercentage(
    String currentExpression, {
    String? previousResult,
  }) =>
      _editContinuing(currentExpression, previousResult, _editor.appendPercent);

  /// Handles pasted text by typing it key by key using keypad rules, preserving input validation and limits.
  static ExpressionResult handlePaste(String currentExpression, String pasted) {
    final text = PastedText.normalize(pasted);
    if (text.isEmpty) return ExpressionResult(expression: currentExpression);

    final List<InputToken> tokens;
    try {
      tokens = _reader.read(currentExpression);
    } on FormatException {
      return ExpressionResult(expression: currentExpression);
    }
    try {
      return _render(_typer.type(tokens, text), currentExpression);
    } on FormatException {
      return ExpressionResult(
        expression: currentExpression,
        errorMessage: invalidPasteErrorMessage,
      );
    }
  }

  /// The expression to evaluate on `=`: open brackets are closed.
  static String closeBrackets(String currentExpression) {
    try {
      return _renderer.render(
        _editor.closeBrackets(_reader.read(currentExpression)),
      );
    } on FormatException {
      return currentExpression;
    }
  }

  /// Applies [key] to the previous result when input is empty.
  /// Uses [onResult] for result-specific behavior.
  static ExpressionResult _editContinuing(
    String currentExpression,
    String? previousResult,
    EditResult Function(List<InputToken>) key, {
    EditResult Function(List<InputToken>)? onResult,
  }) {
    final result = _readResult(previousResult);
    if (currentExpression.isEmpty && result != null) {
      return _render(
        _editor.continueResult(result, onResult ?? key),
        currentExpression,
      );
    }
    return _edit(currentExpression, key);
  }

  /// A calculated result as input tokens, or null for none (or not a
  /// finished value).
  static List<InputToken>? _readResult(String? text) =>
      text == null ? null : _reader.readResult(text);

  static ExpressionResult _edit(
    String expression,
    EditResult Function(List<InputToken>) edit,
  ) {
    final List<InputToken> tokens;
    try {
      tokens = _reader.read(expression);
    } on FormatException {
      return ExpressionResult(expression: expression);
    }
    return _render(edit(tokens), expression);
  }

  static ExpressionResult _render(EditResult result, String before) {
    final error = result.error;
    if (error != null) {
      return ExpressionResult(
        expression: before,
        errorMessage: _messages[error]!,
      );
    }
    return ExpressionResult(expression: _renderer.render(result.tokens));
  }

  static const _messages = {
    InputLimitError.maxCharacters: maxCharactersErrorMessage,
    InputLimitError.maxOperations: maxOperationsErrorMessage,
    InputLimitError.maxDigits: maxDigitsErrorMessage,
  };
}
