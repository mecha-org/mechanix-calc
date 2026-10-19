import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/core/utils/constant.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_panel.dart';
import 'package:mechanix_calculator/main.dart' as app;
import 'package:widgets/widgets.dart';

/// Single source of truth for keys. Labels verified against button_grid.dart.
abstract final class Keys {
  // --- Text keys -------------------------------------------------------------
  static const clear = 'AC';
  static const toggleSign = '+/-';
  static const divide = '÷';
  static const multiply = '×';
  static const subtract = '-'; // ASCII hyphen (verified).
  static const add = '+';
  static const equals = '=';
  static const decimal = '.';
  static const digits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];

  static const allTextKeys = [
    clear, toggleSign, divide, multiply,
    subtract, add, equals, decimal, ...digits,
  ];

  // --- Icon keys -------------------------------------------------------------
  static const percentIcon = Icons.percent;
  static const backspaceIcon = Icons.backspace_outlined;
  static const historyIcon = Icons.history;

  static const allIconKeys = [percentIcon, backspaceIcon, historyIcon];

  // --- Input tokens for CalculatorRobot.enter() ------------------------------
  // Single chars standing in for icon / multi-char keys, so a whole
  // interaction reads as one string: enter('5±+50%⌫').
  static const tokenPercent = '%';
  static const tokenToggleSign = '±';
  static const tokenBackspace = '⌫';
}

/// Page-object for the calculator screen.
/// Tests describe behaviour; all finders, taps and pumps live here.
class CalculatorRobot {
  CalculatorRobot(this.tester);

  final WidgetTester tester;

  // ===========================================================================
  // Finders
  // ===========================================================================

  Finder key(String label) => find.widgetWithText(MechanixButton, label);
  Finder get percentKey => find.byIcon(Keys.percentIcon);
  Finder get backspaceKey => find.byIcon(Keys.backspaceIcon);
  Finder get historyIcon => find.byIcon(Keys.historyIcon);

  /// Text inside the display only (ignores button labels / history).
  Finder displayText(String text) => find.descendant(
        of: find.byType(DisplayPanel),
        matching: find.text(text),
      );

  /// Resolves an input token (see [Keys]) to its button finder.
  Finder _finderForToken(String token) => switch (token) {
        Keys.tokenPercent => percentKey,
        Keys.tokenBackspace => backspaceKey,
        Keys.tokenToggleSign => key(Keys.toggleSign),
        _ => key(token),
      };

  // ===========================================================================
  // Actions
  // ===========================================================================

  /// Boots the app.
  /// TODO: switch to tester.pumpWidget(const <RootWidget>()) to avoid
  /// state (e.g. history) leaking between tests via main().
  Future<void> launch() async {
    app.main();
    await tester.pumpAndSettle();
  }

  /// Types a key sequence, e.g. enter('10+20×3') or enter('5±+50%').
  /// Fails fast with a clear message if a token has no matching key.
  Future<void> enter(String sequence) async {
    for (final token in sequence.characters) {
      final finder = _finderForToken(token);
      expect(finder, findsOneWidget, reason: 'No key for token "$token"');
      await tester.tap(finder);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> pressEquals() => _tapAndSettle(key(Keys.equals));
  Future<void> pressClear() => _tapAndSettle(key(Keys.clear));
  Future<void> pressBackspace() => _tapAndSettle(backspaceKey);
  Future<void> pressPercent() => _tapAndSettle(percentKey);
  Future<void> pressToggleSign() => _tapAndSettle(key(Keys.toggleSign));
  Future<void> openHistory() => _tapAndSettle(historyIcon);

  /// Enter an expression and evaluate it.
  Future<void> calculate(String expression) async {
    await enter(expression);
    await pressEquals();
  }

  Future<void> _tapAndSettle(Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // ===========================================================================
  // Assertions
  // ===========================================================================

  /// Upper (small) line: the typed expression.
  void expectExpression(String expression) =>
      expect(displayText(expression), findsOneWidget,
          reason: 'Expression line should show "$expression"');

  /// Lower (large) line: current input or result.
  /// atLeast(1): a live preview may render the same value twice.
  void expectResult(String result) =>
      expect(displayText(result), findsAtLeastNWidgets(1),
          reason: 'Main line should show "$result"');

  void expectNotInDisplay(String text) =>
      expect(displayText(text), findsNothing,
          reason: '"$text" should be cleared from display');

  void expectError() =>
      expect(displayText(invalidOperationsErrorMessage), findsOneWidget,
          reason: 'Error message should be shown');

  void expectNoError() =>
      expect(find.text(invalidOperationsErrorMessage), findsNothing,
          reason: 'No error message expected');

  /// Catches layout overflow / build errors (e.g. very long numbers).
  void expectNoFrameworkErrors() =>
      expect(tester.takeException(), isNull,
          reason: 'Framework threw (overflow / build error)');

  /// Text appears OUTSIDE the display, i.e. in the history view.
  void expectInHistory(String text) {
    final all = find.textContaining(text).evaluate();
    final inDisplay = find
        .descendant(
            of: find.byType(DisplayPanel),
            matching: find.textContaining(text))
        .evaluate()
        .toSet();
    expect(all.where((e) => !inDisplay.contains(e)), isNotEmpty,
        reason: '"$text" should be listed in history');
  }

  /// Every text + icon key renders exactly once; reports all misses at once.
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