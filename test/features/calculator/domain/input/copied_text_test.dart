import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/expression_builder.dart';
import 'package:mechanix_calculator/features/calculator/domain/engine/calc_engine.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/copied_text.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/expression_reader.dart';

void main() {
  group('CopiedText.fromDisplay', () {
    for (final (display, copied) in [
      ('8888×979999', '8888*979999'),
      ('8÷2', '8/2'),
      ('9.9×10¹⁷', '9.9*10^17'),
      ('1.2×10⁻⁷', '1.2*10^-7'),
      ('5²', '5^2'),
      ('(2+3)²³', '(2+3)^23'),
      ('5⁻', '5^-'),
      ('2^3', '2^3'),
      ('(-5)+10%', '(-5)+10%'),
      ('1,024', '1,024'),
      ('0', '0'),
    ]) {
      test('"$display" -> "$copied"', () {
        final text = CopiedText.fromDisplay(display);
        expect(text, copied);
        expect(text.codeUnits.every((c) => c < 128), isTrue, reason: text);
      });
    }

    test('copied text pastes back to the same value', () {
      const reader = ExpressionReader();
      final engine = CalcEngine();
      for (final display in [
        '8888×979999',
        '8÷2',
        '9.9×10¹⁷',
        '1.2×10⁻⁷',
        '(2+3)²',
        '2×3²',
        '(-5)+10%',
      ]) {
        final pasted = ExpressionBuilder.handlePaste(
          '',
          CopiedText.fromDisplay(display),
        );
        expect(pasted.errorMessage, '', reason: display);
        expect(
          engine.evaluate(reader.read(pasted.expression)),
          engine.evaluate(reader.read(display)),
          reason: display,
        );
      }
    });
  });
}
