import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/data/utils/expression_evaluator.dart';

void main() {
  group('ExpressionEvaluator', () {
    void expectValue(String expression, double expected) {
      test('$expression = $expected', () {
        expect(
          ExpressionEvaluator.evaluate(expression),
          closeTo(expected, expected.abs() * 1e-12 + 1e-12),
        );
      });
    }

    group('arithmetic', () {
      expectValue('3+5', 8);
      expectValue('2×3÷4', 1.5);
      expectValue('2+3×4', 14);
      expectValue('0.1+0.2', 0.3);
      expectValue('4×.2', 0.8);
      expectValue('5.+1', 6);
      expectValue('1,000+2', 1002);
    });

    group('negative numbers', () {
      expectValue('(-2)×(-2)', 4);
      expectValue('5-(-3)', 8);
      expectValue('10÷(-2)', -5);
      expectValue('-5+2', -3);
    });

    group('percent after + or - is relative to the left value', () {
      expectValue('200+10%', 220);
      expectValue('200-10%', 180);
      expectValue('100+10%+10%', 121);
      expectValue('2×3+10%', 6.6);
      expectValue('100+50+10%', 165);
      expectValue('200+10%×2', 240);
      expectValue('(200+10%)×2', 440);
      expectValue('(-5)+10%', -5.5);
      expectValue('200×50%+10%', 110);
      expectValue('50%+10%', 0.55);
    });

    group('other percentages divide by 100', () {
      expectValue('50%', 0.5);
      expectValue('200×50%', 100);
      expectValue('200÷50%', 400);
      expectValue('200+5×10%', 200.5);
    });

    group('percent after brackets', () {
      expectValue('(-5)%', -0.05);
      expectValue('2×(-5)%', -0.1);
      expectValue('200+(-5)%', 190);
      expectValue('200-(-5)%', 210);
      expectValue('(-5)%+10%', -0.055);
    });

    group('scientific numbers', () {
      expectValue('9.99999998×10¹⁷+1', 9.99999998e17 + 1);
      expectValue('(-9.9×10¹⁷)÷2', -4.95e17);
      expectValue('(-9.9×10¹⁷)%', -9.9e15);
      expectValue('1.2×10⁻⁷×2', 2.4e-7);
      // After backspacing the exponent away it is a plain multiplication.
      expectValue('9.9×10', 99);
    });

    test('chained percentages stay exact', () {
      expect(
        ExpressionEvaluator.evaluate('1${'+1%' * 10}'),
        closeTo(1.1046221254112045, 1e-12),
      );
    });

    test('division by zero gives infinity (shown as Error)', () {
      expect(ExpressionEvaluator.evaluate('5÷0'), double.infinity);
    });

    group('malformed input throws', () {
      for (final expression in [
        '5×',
        '5++5',
        '5+%',
        '(-5',
        '(-5)5',
        '.',
        '9.9×10⁻',
        '',
      ]) {
        test('"$expression"', () {
          expect(
            () => ExpressionEvaluator.evaluate(expression),
            throwsFormatException,
          );
        });
      }
    });
  });
}
