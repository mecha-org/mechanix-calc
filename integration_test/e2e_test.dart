import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';

import 'robot.dart';

/// Calculator E2E suite (Mecha Comet)
/// Each group maps to a coverage area; each test: Arrange → Act → Assert.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
 
  late CalculatorRobot calc;
 
  /// Shared launch so every test starts from a clean screen.
  Future<void> start(WidgetTester tester) async {
    calc = CalculatorRobot(tester);
    await calc.launch();
  }
 
  // ===========================================================================
  // 1. RENDER / SMOKE
  // ===========================================================================
  group('Render', () {
    testWidgets('[R1] All keys, backspace and history icon are visible',
        (tester) async {
      await start(tester);
 
      calc.expectAllKeysVisible();
    });
    // Check render time
 
    testWidgets('[R2] Display shows 0 on launch', (tester) async {
      await start(tester);
 
      calc.expectResult('0');
    });
  });
 
  // ===========================================================================
  // 2. ARITHMETIC
  // ===========================================================================
  group('Arithmetic', () {
    testWidgets('[A1] Addition: 1+2 = 3', (tester) async {
      await start(tester);
 
      await calc.calculate('1+2');
 
      calc.expectExpression('1+2');
      calc.expectResult('3');
    });
 
    testWidgets('[A2] Precedence: 10+20×3 = 70 (× before +)', (tester) async {
      await start(tester);
 
      await calc.calculate('10+20×3');
 
      calc.expectExpression('10+20×3');
      calc.expectResult('70');
    });
  });
 
  // ===========================================================================
  // 3. ERRORS
  // ===========================================================================
  group('Errors', () {
    testWidgets('[E1] Divide by zero shows error, keeps expression',
        (tester) async {
      await start(tester);
 
      await calc.calculate('5÷0');
 
      calc.expectError(invalidOperationsErrorMessage);
      calc.expectExpression('5÷0');
    });
  });
}
 