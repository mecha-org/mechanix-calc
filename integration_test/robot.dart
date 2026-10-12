import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_panel.dart';
import 'package:mechanix_calculator/main.dart' as app;
import 'package:widgets/widgets.dart';

/// Single source of truth for key labels as rendered on screen
/// If a glyph changes in the UI, update it here only
abstract final class Keys {
  static const clear = 'AC';
  static const toggleSign = '+/-';
  static const divide = '÷';
  static const multiply = '×';
//   static const subtract = '−'; // NOTE: U+2212. Change to '-' if the button uses ASCII.
  static const subtract = '-'; // ASCII hyphen (verified in button_grid.dart).
  static const add = '+';
  static const equals = '=';
  static const decimal = '.';
  static const digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  /// All text-labelled buttons.
  static const allTextKeys = [
    clear, toggleSign, divide, multiply,
    subtract, add, equals, decimal, ...digits,
  ];

  // Icon-only buttons (source: button_grid.dart).
  static const percentIcon = Icons.percent;
  static const backspaceIcon = Icons.backspace_outlined;
  static const historyIcon = Icons.history;

  static const allIconKeys = [percentIcon, backspaceIcon, historyIcon];
}

/// Page-object for the calculator screen.
///
/// creating a small Calculator API for our tests
/// so UI changes are fixed in one place and tests read like specs.
class CalculatorRobot {
  CalculatorRobot(this.tester);

  final WidgetTester tester;

  // ---------------------------------------------------------------------------
  // Finders
  // ---------------------------------------------------------------------------

  Finder key(String label) => find.widgetWithText(MechanixButton, label);
  Finder get percentKey => find.byIcon(Keys.percentIcon);
  Finder get backspaceKey => find.byIcon(Keys.backspaceIcon);
  Finder get historyIcon => find.byIcon(Keys.historyIcon);

  /// Text scoped to the display only, so button labels / history never collide.
  Finder displayText(String text) => find.descendant(
        of: find.byType(DisplayPanel),
        matching: find.text(text),
      );

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  /// Boots the app. Swap to `tester.pumpWidget(const <AppWidget>())`
  /// once the root widget name is confirmed (avoids state leaking via main()).
  Future<void> launch() async {
    app.main();
    await tester.pumpAndSettle();
  }

  /// Taps a single key by its label.
  Future<void> tapKey(String label) async {
    await tester.tap(key(label));
    await tester.pump();
  }

  /// Types a sequence of single-character keys, e.g. `enter('10+20×3')`.
  /// Multi-char keys (AC, +/-) have dedicated methods below.
  Future<void> enter(String sequence) async {
    for (final char in sequence.characters) {
      await tapKey(char);
    }
    await tester.pumpAndSettle();
  }

  Future<void> pressEquals() async {
    await tapKey(Keys.equals);
    await tester.pumpAndSettle();
  }

  Future<void> pressClear() async {
    await tapKey(Keys.clear);
    await tester.pumpAndSettle();
  }

  Future<void> pressBackspace() async {
    await tester.tap(backspaceKey);
    await tester.pumpAndSettle();
  }

  Future<void> pressPercent() async {
    await tester.tap(percentKey);
    await tester.pumpAndSettle();
  }

  /// Convenience: enter an expression and evaluate it.
  Future<void> calculate(String expression) async {
    await enter(expression);
    await pressEquals();
  }

  // ---------------------------------------------------------------------------
  // Assertions
  // ---------------------------------------------------------------------------

  /// Upper (small) line showing the typed expression.
  void expectExpression(String expression) =>
      expect(displayText(expression), findsOneWidget,
          reason: 'Expression line should show "$expression"');

  /// Lower (large) line showing the result.
  /// atLeast(1): a live preview may render the same value twice.
  void expectResult(String result) =>
      expect(displayText(result), findsAtLeastNWidgets(1),
          reason: 'Result line should show "$result"');

  void expectError(String message) =>
      expect(displayText(message), findsOneWidget,
          reason: 'Error message should be shown in display');

  /// Checks every text + icon key and fails ONCE listing all missing ones
  /// (avoids one device run per missing key).
  void expectAllKeysVisible() {
    final missing = <String>[
      for (final label in Keys.allTextKeys)
        if (key(label).evaluate().length != 1) 'text "$label"',
      for (final icon in Keys.allIconKeys)
        if (find.byIcon(icon).evaluate().length != 1)
          'icon 0x${icon.codePoint.toRadixString(16)}',
    ];
    expect(missing, isEmpty, reason: 'Missing/duplicate keys: $missing');
  }
}