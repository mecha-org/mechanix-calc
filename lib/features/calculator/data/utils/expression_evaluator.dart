import 'dart:math' as math;

import 'package:mechanix_calculator/features/calculator/data/utils/result_formatter.dart';

/// Evaluates calculator expressions with standard operator precedence,
/// parentheses, scientific notation and percentage handling.
class ExpressionEvaluator {
  ExpressionEvaluator._(this._input);

  final String _input;
  int _position = 0;

  static final _numberPattern = RegExp(r'[0-9]*\.?[0-9]*');
  static final _exponentPattern = RegExp(
    '×10([${ResultFormatter.superscriptChars}]+)',
  );

  static double evaluate(String expression) {
    final evaluator = ExpressionEvaluator._(expression.replaceAll(',', ''));
    final value = evaluator._expression();
    if (evaluator._position != evaluator._input.length) {
      throw evaluator._error('Unexpected character');
    }
    return value;
  }

  /// The character at the current position, or null at the end.
  String? get _nextChar =>
      _position < _input.length ? _input[_position] : null;

  double _expression() {
    var value = _term(percentBase: null);
    while (_nextChar == '+' || _nextChar == '-') {
      final symbol = _input[_position++];
      final right = _term(percentBase: value);
      value = symbol == '+' ? value + right : value - right;
    }
    return value;
  }

  /// [percentBase] is the value left of a binary `+`/`-`; it is used when
  /// the term's first factor is a percentage.
  double _term({required double? percentBase}) {
    var value = _factor(percentBase: percentBase);
    while (const {'×', '*', '÷', '/'}.contains(_nextChar)) {
      final symbol = _input[_position++];
      final right = _factor(percentBase: null);
      value = (symbol == '×' || symbol == '*')
          ? value * right
          : value / right;
    }
    return value;
  }

  double _factor({required double? percentBase}) {
    if (_accept('-')) return -_factor(percentBase: percentBase);

    var value = _primary();
    var base = percentBase;
    while (_accept('%')) {
      value = base == null ? value / 100 : base * value / 100;
      base = null;
    }
    return value;
  }

  double _primary() {
    if (_accept('(')) {
      final value = _expression();
      if (!_accept(')')) throw _error('Missing ")"');
      return value;
    }
    return _number();
  }

  double _number() {
    final match = _numberPattern.matchAsPrefix(_input, _position)!;
    var text = match[0]!;
    if (text.isEmpty || text == '.') throw _error('Expected a number');
    _position = match.end;

    if (text.startsWith('.')) text = '0$text';
    if (text.endsWith('.')) text = '${text}0';
    var value = double.parse(text);

    // Scientific notation as displayed: 9.9×10¹⁷.
    final exponent = _exponentPattern.matchAsPrefix(_input, _position);
    if (exponent != null) {
      _position = exponent.end;
      final power = int.parse(ResultFormatter.fromSuperscript(exponent[1]!));
      value *= math.pow(10, power);
    }
    return value;
  }

  bool _accept(String char) {
    if (_nextChar == char) {
      _position++;
      return true;
    }
    return false;
  }

  FormatException _error(String message) =>
      FormatException(message, _input, _position);
}
