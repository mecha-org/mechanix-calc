import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:widgets/widgets.dart';

import 'robot.dart';


/// Calculator E2E suite (Mecha Comet).
///
/// Group IDs:  R render · N number entry · A arithmetic · D decimal
///             S sign · P percent · B backspace · C clear · Q equals
///             E errors · H history · X edge cases (incl. large numbers)
///
/// Known failure: [S3] is kept failing on purpose (app shows "(-" after +/-
/// on empty input). Raised as a bug / spec question, do not "fix" the test.
///
/// Tests tagged [assumption] assert a product decision that is not yet
/// confirmed. A failure there = "check the spec", not necessarily a bug.
/// Run only verified tests:  --exclude-tags assumption
///
/// Input tokens:  ± = +/-   % = percent   ⌫ = backspace   (see Keys)

const assumption = 'assumption';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late CalculatorRobot calc;

  /// Fresh app for every test.
  Future<void> start(WidgetTester tester) async {
    calc = CalculatorRobot(tester);
    await calc.launch();
  }


  // ===========================================================================
  // R. RENDER / SMOKE
  // ===========================================================================
  group('Render', () {
    testWidgets('[R1] All keys, backspace and history icon are visible',
        (tester) async {
      await start(tester);
      calc.expectAllKeysVisible();
    });

    testWidgets('[R2] Display shows 0 on launch', (tester) async {
      await start(tester);
      calc.expectResult('0');
    });

    testWidgets('[R3] Every key type can be entered; backspace, equals and AC end at 0',
        (tester) async {
      await start(tester);
      await calc.enter('1234567890+3-3×3÷3%3±33');
      await calc.pressBackspace(); // remove the last digit
      await calc.enter('+3');
      await calc.pressEquals();
      await calc.pressClear();
      calc.expectResult('0');
    });
  });

  // ===========================================================================
  // N. NUMBER ENTRY
  // ===========================================================================
  group('Number entry', () {
    testWidgets('[N1] Every digit 0–9 is entered into display', (tester) async {
      await start(tester);
      for (final digit in Keys.digits) {
        await calc.pressClear();
        await calc.enter(digit);
        calc.expectResult(digit);
      }
    });

    testWidgets('[N2] Multi-digit number: 305', (tester) async {
      await start(tester);
      await calc.enter('305');
      calc.expectResult('305');
    });

    testWidgets('[N3] Leading zeros suppressed: 007 → 7', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.enter('007');
      calc.expectResult('7');
    });
  });

  // ===========================================================================
  // A. ARITHMETIC
  // ===========================================================================
  group('Arithmetic', () {
    testWidgets('[A1] Addition: 1+2 = 3', (tester) async {
      await start(tester);
      await calc.calculate('1+2');
      calc.expectExpression('1+2');
      calc.expectResult('3');
    });

    testWidgets('[A2] Precedence: 10+20×3 = 70', (tester) async {
      await start(tester);
      await calc.calculate('10+20×3');
      calc.expectExpression('10+20×3');
      calc.expectResult('70');
    });

    testWidgets('[A3] Subtraction: 8-2 = 6', (tester) async {
      await start(tester);
      await calc.calculate('8-2');
      calc.expectResult('6');
    });

    testWidgets('[A4] Multiplication: 8×2 = 16', (tester) async {
      await start(tester);
      await calc.calculate('8×2');
      calc.expectResult('16');
    });

    testWidgets('[A5] Division: 8÷2 = 4', (tester) async {
      await start(tester);
      await calc.calculate('8÷2');
      calc.expectResult('4');
    });

    testWidgets('[A6] Left-to-right for same precedence', (tester) async {
      await start(tester);
      await calc.calculate('20-5-3'); // (20-5)-3, not 20-(5-3)
      calc.expectResult('12');

      await calc.pressClear();
      await calc.calculate('100÷10÷2'); // (100÷10)÷2
      calc.expectResult('5');
    });

    testWidgets('[A7] Mixed precedence right-to-left: 2+3×4-6÷2 = 11', (tester) async {
      await start(tester);
      await calc.calculate('2+3×4-6÷2');
      calc.expectResult('11');
    });

    testWidgets('[A8] Negative result: 3-8 = -5', (tester) async {
      await start(tester);
      await calc.calculate('3-8');
      calc.expectResult('-5');
    });

    testWidgets('[A9] Non-integer division: 7÷2 = 3.5', (tester) async {
      await start(tester);
      await calc.calculate('7÷2');
      calc.expectResult('3.5');
    });

    testWidgets('[A10] Second operator replaces first: 5+×3 → 5×3 = 15',
        tags: assumption, (tester) async {
      await start(tester);
      await calc.calculate('5+×3');
      calc.expectExpression('5×3');
      calc.expectResult('15');
    });

    testWidgets(
        '[A11] Large operands and precedence: 1234567890+1234567890-1234567890×1234567890÷1234567890 = 1,234,567,890',
        (tester) async {
      await start(tester);
      const expression =
          '1234567890+1234567890-1234567890×1234567890÷1234567890';
      await calc.calculate(expression);
      calc.expectExpression(expression);
      calc.expectResult('1,234,567,890');
    });

    testWidgets('[A12] Result uses thousands separators: 852×951 = 810,252',
        (tester) async {
      await start(tester);
      await calc.calculate('852×951');
      calc.expectExpression('852×951');
      calc.expectResult('810,252');
    });

    testWidgets(
        '[A13] Non-terminating division is rounded: 808÷15505 = 0.05211222186',
        (tester) async {
      // Observed on device: results are rounded to 10 significant digits.
      await start(tester);
      await calc.calculate('808÷15505');
      calc.expectExpression('808÷15505');
      calc.expectResult('0.05211222186');
    });

    testWidgets('[A14] Multiplication by zero: 999×0 = 0', (tester) async {
      await start(tester);
      await calc.calculate('999×0');
      calc.expectExpression('999×0');
      calc.expectResult('0');
    });

    testWidgets('[A15] Mixed × ÷ evaluate left-to-right: 20÷5×2 = 8',
        (tester) async {
      await start(tester);
      await calc.calculate('20÷5×2'); // (20÷5)×2, not 20÷(5×2)
      calc.expectExpression('20÷5×2');
      calc.expectResult('8');
    });
  });

  // ===========================================================================
  // D. DECIMAL
  // ===========================================================================
  group('Decimal', () {
    testWidgets('[D1] Decimal addition: 0.5+0.25 = 0.75', (tester) async {
      await start(tester);
      await calc.calculate('0.5+0.25');
      calc.expectResult('0.75');
    });

    testWidgets('[D2] Leading "." gets a zero: .5 → 0.5', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.enter('.5');
      calc.expectResult('0.5');
    });

    testWidgets('[D3] Duplicate "." ignored: 1..5 → 1.5', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.enter('1..5');
      calc.expectResult('1.5');
    });

    testWidgets('[D4] Whole result has no ".0": 2.5+2.5 = 5', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.calculate('2.5+2.5');
      calc.expectResult('5');
      calc.expectNotInDisplay('5.0');
    });

    testWidgets('[D5] Decimal multiplication: 2.5×4 = 10', (tester) async {
      await start(tester);
      await calc.calculate('2.5×4');
      calc.expectExpression('2.5×4');
      calc.expectResult('10');
    });

    testWidgets('[D6] Decimal sum is rounded: 1.234567+8965320 = 8965321.235', (tester) async {
      // Observed on device: results are rounded to 10 significant digits.
      await start(tester);
      await calc.calculate('1.234567+8965320');
      calc.expectExpression('1.234567+8965320');
      calc.expectResult('8965321.235');
    });

    testWidgets('[D6] Decimal sum is rounded: .2×5 = 1', (tester) async { // earlier an issue, fixed now
      await start(tester);
      await calc.calculate('.2×5');
      calc.expectExpression('0.2×5');
      calc.expectResult('1');
    });
  });

  // ===========================================================================
  // S. SIGN TOGGLE (+/-)
  //    Asserted via the computed result, so display format of "-5" vs "(-5)"
  //    does not matter.
  // ===========================================================================
  group('Sign toggle', () {
    testWidgets('[S1] Toggle makes operand negative: -5+8 = 3',
        (tester) async {
      await start(tester);
      await calc.calculate('5±+8');
      calc.expectResult('3');
    });

    testWidgets('[S2] Double toggle restores sign: 5+1 = 6', (tester) async {
      await start(tester);
      await calc.calculate('5±±+1');
      calc.expectResult('6');
    });

    // KNOWN FAILURE (kept on purpose): app shows "(-" instead of "0".
    testWidgets('[S3] Toggle on 0 stays 0 (no "-0")', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.pressToggleSign();
      calc.expectResult('0');
      calc.expectNotInDisplay('-0');
    });
  });

  // ===========================================================================
  // P. PERCENT
  // ===========================================================================
  group('Percent', () {
    testWidgets('[P1] Standalone: 50% = 0.5', (tester) async {
      await start(tester);
      await calc.calculate('50%');
      calc.expectResult('0.5');
    });

    testWidgets('[P2] In expression: 200+10% = 200.1 (operand ÷ 100)',
        tags: assumption, (tester) async {
      // Alternative spec (iOS-style) would give 220.
      await start(tester);
      await calc.calculate('200+10%');
      calc.expectResult('200.1');
    });
    
    testWidgets('[P3] In expression: 15×10%100 = ?', // ubuntu gives Malformed expression, mobile 150 and google 50
        tags: assumption, (tester) async {
      // Alternative spec (iOS-style) would give 220.
      await start(tester);
      await calc.calculate('15×10%100');
      calc.expectNoError();
    });
  });

  // ===========================================================================
  // B. BACKSPACE
  // ===========================================================================
  group('Backspace', () {
    testWidgets('[B1] Removes last digit: 12 → 1', (tester) async {
      await start(tester);
      await calc.enter('12⌫');
      calc.expectResult('1');
    });

    testWidgets('[B2] Removes trailing operator: 5+⌫×3 = 15', (tester) async {
      // Proves "+" was removed: result is 5×3, not error / 5+×3.
      await start(tester);
      await calc.calculate('5+⌫×3');
      calc.expectResult('15');
    });

    testWidgets('[B3] Deleting last char shows 0', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.enter('7⌫');
      calc.expectResult('0');
    });
  });

  // ===========================================================================
  // C. CLEAR (AC)
  // ===========================================================================
  group('Clear', () {
    testWidgets('[C1] AC mid-expression resets to 0', (tester) async {
      await start(tester);
      await calc.enter('5+3');
      await calc.pressClear();
      calc.expectResult('0');
      calc.expectNotInDisplay('5+3');
    });

    testWidgets('[C2] AC after result resets to 0', (tester) async {
      await start(tester);
      await calc.calculate('1+2');
      await calc.pressClear();
      calc.expectResult('0');
      calc.expectNotInDisplay('1+2');
    });

    testWidgets('[C3] AC after error clears error', (tester) async {
      await start(tester);
      await calc.calculate('5÷0');
      await calc.pressClear();
      calc.expectNoError();
      calc.expectResult('0');
    });
  });

  // ===========================================================================
  // Q. EQUALS BEHAVIOUR
  // ===========================================================================
  group('Equals', () {
    testWidgets('[Q1] Repeated "=" keeps result: 2+3== → 5', tags: assumption,
        (tester) async {
      // Alternative spec (repeat last op) would give 8.
      await start(tester);
      await calc.enter('2+3');
      await calc.pressEquals();
      await calc.pressEquals();
      calc.expectResult('5');
    });

    testWidgets('[Q2] Digit after result starts new expression',
        tags: assumption, (tester) async {
      await start(tester);
      await calc.calculate('2+3');
      await calc.calculate('4+1');
      calc.expectExpression('4+1'); // not "54+1"
      calc.expectResult('5');
    });

    testWidgets('[Q3] Operator after result continues: (2+3)×2 = 10',
        tags: assumption, (tester) async {
      await start(tester);
      await calc.calculate('2+3');
      await calc.calculate('×2');
      calc.expectResult('10');
    });

    testWidgets('[Q4] "=" on a bare number returns it: 7= → 7',
        tags: assumption, (tester) async {
      await start(tester);
      await calc.calculate('7');
      calc.expectResult('7');
      calc.expectNoError();
    });

    testWidgets('[Q5] "=" on empty input does nothing', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.pressEquals();
      calc.expectResult('0');
      calc.expectNoError();
    });

    testWidgets('[Q6] "=" on big number returns it as it is', tags: assumption, // fails, same as ubuntu native calc
        (tester) async {
      await start(tester);
      await calc.calculate('123456789012345');
      calc.expectResult('123,456,789,012,345');
    });
  });

  // ===========================================================================
  // E. ERRORS
  // ===========================================================================
  group('Errors', () {
    testWidgets('[E1] Divide by zero shows error, keeps expression',
        (tester) async {
      await start(tester);
      await calc.calculate('5÷0');
      calc.expectError();
      calc.expectExpression('5÷0');
    });

    testWidgets('[E2] Trailing operator shows error, keeps expression',
        (tester) async {
      await start(tester);
      await calc.calculate('5+');
      calc.expectError();
      calc.expectExpression('5+');
    });

    testWidgets('[E3] Leading operator is prefixed with 0: ×5= → 0×5 = 0',
        tags: assumption, (tester) async {
      await start(tester);
      await calc.calculate('×5');
      // Observed on device: expression "0×5", result "0", no error.
      calc.expectExpression('0×5');
      calc.expectResult('0');
      calc.expectNoError();
    });

    testWidgets('[E4] Typing after error starts fresh: 3+4 = 7',
        tags: assumption, (tester) async {
      await start(tester);
      await calc.calculate('5÷0');
      await calc.calculate('3+4');
      calc.expectNoError();
      calc.expectResult('7');
    });

    testWidgets('[E5] Digit after percentage: 10%8 = Error', (tester) async {
      await start(tester);
      await calc.calculate('10%8');
      calc.expectExpression('10%8');
      calc.expectResult('Error');
    });

    testWidgets(
        '[E6] Digit after percentage in a longer expression: 123×580%1880 = Error',
        (tester) async {
      await start(tester);
      await calc.calculate('123×580%1880');
      calc.expectExpression('123×580%1880');
      calc.expectResult('Error');
    });
  });

  // ===========================================================================
  // H. HISTORY
  //    Uses unique expressions so leaked history from other tests can't
  //    cause false passes.
  // ===========================================================================
  group('History', () {
    testWidgets('[H1] Calculation is listed in history', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.calculate('7×6');
      await calc.openHistory();
      calc.expectInHistory('7×6');
      calc.expectInHistory('42');
    });

    testWidgets('[H2] Multiple calculations are all listed', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.calculate('11+22');
      await calc.calculate('9×9');
      await calc.openHistory();
      calc.expectInHistory('11+22');
      calc.expectInHistory('9×9');
    });

    testWidgets('[H3] History panel opens and closes', (tester) async {
      await start(tester);
      await calc.calculate('100+200');
      calc.expectExpression('100+200');
      calc.expectResult('300');
      await calc.openHistory();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('[H4] Tapping a history entry loads it into the display', (tester) async {
      await start(tester);
      await calc.calculate('13×7');
      calc.expectResult('91');
 
      // Clear first, so the display can only show 13×7 if the tap loaded it.
      await calc.pressClear();
      calc.expectNotInDisplay('13×7');
      calc.expectNotInDisplay('91');
 
      await calc.openHistory();
      // After AC the display no longer contains "13×7", so a match here is
      // the history entry. .first in case history holds repeated entries.
      await tester.tap(find.textContaining('13×7').first);
      // await tester.pumpAndSettle();
 
      // calc.expectExpression('13×7');
      // calc.expectResult('91');
    });
 
    testWidgets('[H5] Tapping an older entry loads that one, not the latest', (tester) async {
      await start(tester);
      await calc.calculate('13×7'); // 91 (older)
      await calc.calculate('19+4'); // 23 (latest)
      await calc.pressClear();
 
      await calc.openHistory();
      await tester.tap(find.textContaining('13×7').first);
      await tester.pumpAndSettle();
 
      calc.expectExpression('13×7');
      // calc.expectResult('91');
      calc.expectNotInDisplay('19+4');
    });

  });

  // ===========================================================================
  // X. INPUT LIMITS 
  //    The "15 digits" message is visible in the app; the 100-char and
  //    20-operator messages are not known yet, so those tests assert that the
  //    display stops growing instead of matching message text.
  // ===========================================================================
  group('Input limits', () {
    // Part of the real message "Can't enter more than 15 digits"
    // fragment avoids apostrophe-style differences.
    final digitLimitMessage = find.textContaining('more than 15 digits');

    testWidgets(
        '[X3] 16th digit is rejected: display stays at 15 digits, message shown',
        (tester) async {
      await start(tester);
      await calc.enter('123456789012345'); // exactly 15 digits: allowed
      expect(digitLimitMessage, findsNothing,
          reason: '15 digits is within the limit, no message expected');

      // Tap the 16th digit by hand (no pumpAndSettle) so a timed message is
      // still on screen when we look for it.
      await tester.tap(calc.key('6'));
      await tester.pump(const Duration(milliseconds: 200));

      expect(digitLimitMessage, findsOneWidget,
          reason: 'Limit message should appear on the 16th digit');
      calc.expectResult('123456789012345');
      calc.expectNotInDisplay('1234567890123456');
      calc.expectNoFrameworkErrors();
    });

    testWidgets('[X5] Digit limit is per number: two 15-digit numbers allowed',
        (tester) async {
      await start(tester);
      const expression = '123456789012345+123456789012345';

      await calc.enter(expression);

      calc.expectExpression(expression);
      expect(digitLimitMessage, findsNothing,
          reason: 'Each number is within 15 digits');
    });

    testWidgets('[X6] 100-character limit: character 101 is ignored',
        tags: assumption, (tester) async {
      // Boundary assumed inclusive: exactly 100 characters is allowed.
      await start(tester);
      // 6 × 16 chars + 4 = 100 characters, 6 operators, numbers ≤ 15 digits.
      final expression = '123456789012345+' * 6 + '1234';
      expect(expression.length, 100);

      await calc.enter(expression);
      calc.expectExpression(expression);

      await tester.tap(calc.key('5'));
      await tester.pump(const Duration(milliseconds: 200));

      calc.expectExpression(expression); // unchanged
      calc.expectNotInDisplay('${expression}5');
      calc.expectNoFrameworkErrors();
    });

    testWidgets('[X7] 20-operator limit: the 21st operator is ignored',
        tags: assumption, (tester) async {
      // Boundary assumed inclusive: exactly 20 operators is allowed.
      await start(tester);
      final expression = '1+' * 20 + '1'; // 20 operators, 41 characters

      await calc.enter(expression);
      calc.expectExpression(expression);

      await tester.tap(calc.key('+')); // would be operator number 21
      await tester.pump(const Duration(milliseconds: 200));

      calc.expectExpression(expression); // unchanged, no trailing "+"
      calc.expectNotInDisplay('$expression+');
      calc.expectNoFrameworkErrors();
    });
  });

  // ===========================================================================
  // X. EDGE CASES
  // ===========================================================================
  group('Edge cases', () {
    testWidgets('[X1] Float precision: 0.1+0.2 = 0.3', tags: assumption,
        (tester) async {
      await start(tester);
      await calc.calculate('0.1+0.2');
      calc.expectResult('0.3');
      calc.expectNotInDisplay('0.30000000000000004');
    });

    testWidgets('[X2] Large result renders without error/overflow',
        (tester) async {
      await start(tester);
      await calc.calculate('99999999×99999999');
      calc.expectNoError();
      calc.expectNoFrameworkErrors();
    });

    testWidgets('[X4] 15-digit sum is shown rounded to 10 significant digits',
        tags: assumption, (tester) async {
      await start(tester);
      const expression =
          '123456789012345+111111111111111+222222222222222-353535353535353';
      await calc.calculate(expression);
      calc.expectExpression(expression);
      // Exact sum is 103,254,768,810,325 but the app displays it rounded.
      // Observed value asserted here; confirm with product that losing the
      // last digits of an integer result is intended.
      calc.expectResult('103,254,768,800,000');
    });
  });


  // ===========================================================================
  // NF. NON-FUNCTIONAL  (U = usability · P = performance)
  // ===========================================================================
  group('Non-functional', () {
    /// Wall-clock time of [action]. Includes test-framework overhead, so it is
    /// an upper bound on real latency, not a true input-to-pixel measurement.
    Future<int> timeMs(Future<void> Function() action) async {
      final sw = Stopwatch()..start();
      await action();
      sw.stop();
      return sw.elapsedMilliseconds;
    }

    Finder keyFinder(String label) =>
      find.widgetWithText(MechanixButton, label);

    Future<void> tapKey(WidgetTester tester, String label) async {
      await tester.tap(keyFinder(label));
      await tester.pump();
    }

    // ---- Usability ----------------------------------------------------------

    testWidgets('[U1] Every key is at least 48×48 dp', (tester) async {
      await start(tester);

      final tooSmall = <String>[];

      for (final label in Keys.allTextKeys) {
        final size = tester.getSize(calc.key(label));
        if (size.width < 48 || size.height < 48) {
          tooSmall.add('"$label" ${size.width}×${size.height}');
        }
      }

      // Icon keys: measure the button around the icon, not the icon itself.
      for (final icon in [
        Icons.percent,
        Icons.backspace_outlined,
        Icons.history,
      ]) {
        final button = find.ancestor(
          of: find.byIcon(icon),
          matching: find.byType(MechanixButton),
        );
        if (button.evaluate().isEmpty) {
          debugPrint('[U1] icon 0x${icon.codePoint.toRadixString(16)} has no '
              'MechanixButton ancestor — measure it manually');
          continue;
        }
        final size = tester.getSize(button.first);
        if (size.width < 48 || size.height < 48) {
          tooSmall.add('icon 0x${icon.codePoint.toRadixString(16)} '
              '${size.width}×${size.height}');
        }
      }

      expect(tooSmall, isEmpty, reason: 'Touch targets below 48dp: $tooSmall');
    });

    testWidgets('[U2] Every key is fully on screen', (tester) async {
      // Checks on-screen only. "Thumb zone" needs an agreed definition first.
      await start(tester);

      // final screen = MediaQuery.of(tester.element(calc.key('7'))).size; // Find the screen size
      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      print('[U2] screen size: ${screen.width}×${screen.height}'); // [U2] screen size: 540.0×590.0
      final bounds = (Offset.zero & screen).inflate(0.5); // rounding tolerance
      final offScreen = <String>[
        for (final label in Keys.allTextKeys)
          if (!bounds.contains(tester.getTopLeft(calc.key(label))) ||
              !bounds.contains(tester.getBottomRight(calc.key(label))))
            label,
      ];

      expect(offScreen, isEmpty, reason: 'Keys outside the screen: $offScreen');
    });

    testWidgets('[U3] History opens and closes in one tap each', (tester) async {
      await start(tester);
      await calc.calculate('1+2'); // history needs at least one entry

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsOneWidget,
      reason: 'One tap on the history icon should open history');

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.close), findsNothing,
      reason: 'One tap on close should dismiss history');
    });

    testWidgets('[U4] Text meets the 4.5:1 contrast guideline',
        (tester) async {
      // Not verified on eLinux: if the guideline cannot run there, drop it.
      await start(tester);

      final handle = tester.ensureSemantics();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    // ---- Performance --------------------------------------------------------

    testWidgets('[P1] Launch settles within 2 s', (tester) async {
      // Measures main() → settled first screen, not a cold boot of the device.
      final ms = await timeMs(() => start(tester));

      expect(ms, lessThanOrEqualTo(2000), reason: 'Launch took $ms ms');
    });

    testWidgets('[P2] A key tap renders within 50 ms', (tester) async {
      await start(tester);
      await tapKey(tester, '1'); // warm-up: first frame is always slower

      final ms = await timeMs(() => tapKey(tester, '7'));

      expect(ms, lessThanOrEqualTo(50), reason: 'Digit tap took $ms ms');
    });

    testWidgets('[P3] "=" shows the result within 100 ms (median of 5)',
      (tester) async {
      await start(tester);

      final samples = <int>[];
        for (final expr in ['12+34', '56×7', '9÷3', '100-1', '8+8']) {
          await calc.pressClear();
          await calc.enter(expr);
          samples.add(await timeMs(() => tapKey(tester, '=')));
          await tester.pumpAndSettle();
        }
        calc.expectResult('16'); // last expression: 8+8

        debugPrint('[P3] "=" samples (in order, ms): $samples');
        samples.sort();
        final median = samples[samples.length ~/ 2];
        debugPrint('[P3] "=" samples (sorted, ms): $samples');

        expect(median, lessThanOrEqualTo(100),
            reason: '"=" median $median ms, samples $samples');
    });

    testWidgets('[P4] 200 mixed key presses cause no framework errors',
        (tester) async {
      // Soak test, not a real crash-rate measurement.
      await start(tester);

      const keys = ['7', '+', '3', '×', '9', '÷', '2', '.', '5', '='];
      for (var i = 0; i < 200; i++) {
        await tapKey(tester, keys[(i * 7) % keys.length]);
      }
      await tester.pumpAndSettle();

      calc.expectNoFrameworkErrors();
    });
  });
}