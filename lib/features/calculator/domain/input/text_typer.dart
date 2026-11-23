import 'package:mechanix_calculator/features/calculator/domain/input/calc_operator.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_editor.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/input_token.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/superscript.dart';

/// Types text into the input key by key, through the same
/// [ExpressionEditor] rules as the keypad, so pasting gives exactly what
/// typing the same keys gives: `5%` + `8` -> `5%×8`, `(-5)` + `3` -> `(-53)`.
///
/// The only reading done here is the sign of a number: where a value is
/// expected, `-5` and `(-5)` are a negative number (typed as `5`, then
/// +/-); after a value `-` is subtraction.
class TextTyper {
  const TextTyper(this.editor);

  final ExpressionEditor editor;

  /// A number as shown: digits with thousands separators and a decimal
  /// point, then an optional superscript power.
  static final _number = RegExp(
    '[0-9,]*(?:\\.[0-9]*)?(?:${Superscript.typedPowerPattern.pattern})?',
  );
  static final _digit = RegExp('[0-9]');

  /// Types [text] after [tokens]. Stops at the first key that breaks an
  /// input limit and returns [tokens] with that error. Throws a
  /// [FormatException] for a character no key types, e.g. a letter.
  EditResult type(List<InputToken> tokens, String text) {
    var result = EditResult(tokens);
    var position = 0;

    bool press(EditResult Function(List<InputToken>) key) {
      final next = key(result.tokens);
      if (next.error != null) {
        result = EditResult(tokens, next.error);
        return false;
      }
      result = next;
      return true;
    }

    while (position < text.length) {
      final char = text[position];

      // A negative number where a value is expected: "-5", "(-5)", "(-5²)".
      final sign = char == '-'
          ? 1
          : text.startsWith('(-', position)
          ? 2
          : 0;
      if (sign > 0 && _expectsValue(result.tokens)) {
        final start = position + sign;
        final end = _number.matchAsPrefix(text, start)!.end;
        final closed = end < text.length && text[end] == ')';
        if (sign == 1 || end == text.length || closed) {
          for (final key in _numberKeys(text.substring(start, end))) {
            if (!press(key)) return result;
          }
          if (!press(editor.toggleSign)) return result;
          position = sign == 2 && closed ? end + 1 : end;
          continue;
        }
        // Otherwise "(" opens a group, e.g. "(-5+3)".
      }

      if (char != ',' && !press(_key(char))) return result;
      position++;
    }
    return result;
  }

  Iterable<EditResult Function(List<InputToken>)> _numberKeys(
    String number,
  ) => [
    for (final char in number.split(''))
      if (char != ',') _key(char),
  ];

  /// The key that types [char].
  EditResult Function(List<InputToken>) _key(String char) {
    if (_digit.hasMatch(char)) return (t) => editor.appendDigit(t, char);
    if (Superscript.chars.contains(char)) {
      return (t) => editor.appendSuperscript(t, Superscript.toPlain(char));
    }
    final operator = CalcOperator.fromSymbol(char);
    if (operator != null) return (t) => editor.appendOperator(t, operator);
    return switch (char) {
      '.' => editor.appendDecimalPoint,
      '%' => editor.appendPercent,
      '(' => editor.appendOpenBracket,
      ')' => editor.appendCloseBracket,
      _ => throw FormatException('No key types "$char"'),
    };
  }

  static bool _expectsValue(List<InputToken> tokens) =>
      switch (tokens.lastOrNull) {
        null || OperatorInput() || LeftParenthesisInput() => true,
        _ => false,
      };
}
