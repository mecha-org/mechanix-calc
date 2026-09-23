import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mechanix_calculator/main.dart' as app;
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_panel.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Calculator Integration Test', () {
    testWidgets('Basic addition test: 1 + 2 = 3', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find buttons and tap them
      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.plus));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.equal));
      await tester.pumpAndSettle();

      // Verify the result (specifically in the main display, with larger font)
      expect(
        find.descendant(
          of: find.byType(DisplayPanel),
          matching: find.text('3'),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Clear functionality test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AC'));
      await tester.pumpAndSettle();

      // Should show '0' after clear in the display
      expect(
        find.descendant(
          of: find.byType(DisplayPanel),
          matching: find.text('0'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Deletion test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      // Tap backspace icon
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pumpAndSettle();

      // '12' should become '1' in the display
      expect(
        find.descendant(
          of: find.byType(DisplayPanel),
          matching: find.text('1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Complex expression: 10 + 20 × 3 = 70', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.plus));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.multiply));
      await tester.pumpAndSettle();
      await tester.tap(find.text('3'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.equal));
      await tester.pumpAndSettle();

      // 10 + (20 * 3) = 70 (assuming standard operator precedence)
      expect(
        find.descendant(
          of: find.byType(DisplayPanel),
          matching: find.text('70'),
        ),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('Division by zero error test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.divide));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.equal));
      await tester.pumpAndSettle();

      // Should show the error message
      expect(find.text('Invalid mathematical operation'), findsOneWidget);
      // Expression should still be visible when error occurs
      expect(find.text('5÷0'), findsOneWidget);
    });

    testWidgets('Malformed expression error test', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('5'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.plus));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.equal));
      await tester.pumpAndSettle();

      // Should show the error message
      expect(find.text('Malformed expressions'), findsOneWidget);
      // Expression should still be visible when error occurs
      expect(find.text('5+'), findsOneWidget);
    });
  });
}
