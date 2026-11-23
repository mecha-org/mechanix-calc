import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/domain/input/pasted_text.dart';

void main() {
  group('PastedText.normalize', () {
    for (final (text, expected) in [
      ('12+3', '12+3'),
      (' 2 + 3 \n', '2+3'),
      ('2 x 3', '2×3'),
      ('2X3', '2×3'),
      ('2·3', '2×3'),
      ('− 5', '-5'),
      ('= 42', '42'),
      ('6÷2 =', '6÷2'),
      ('1.5', '1.5'),
      // left for TextTyper, which accepts them ("." types "0." on its own)
      ('.5', '.5'),
      ('2*3/4', '2*3/4'),
      ('1,024', '1,024'),
      ('9.9×10¹⁷', '9.9×10¹⁷'),
    ]) {
      test('"$text" -> "$expected"', () {
        expect(PastedText.normalize(text), expected);
      });
    }
  });
}
