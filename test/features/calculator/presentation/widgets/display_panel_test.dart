import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_calculator/features/calculator/bloc/calculator_state.dart';
import 'package:mechanix_calculator/features/calculator/presentation/widgets/display_panel.dart';

void main() {
  group('DisplayPanel', () {
    testWidgets('shows 0 when history is empty and expression is empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '',
              result: '0',
              errorMessage: '',
              history: [],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets(
        'shows only 0 when cleared (AC) even if history is not empty',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '',
              result: '0',
              errorMessage: '',
              history: [
                HistoryItem(expression: '3+5', result: '8'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
      expect(find.text('3+5'), findsNothing);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets('shows previous expression and result for completed calculation',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '',
              result: '12,950',
              errorMessage: '',
              history: [
                HistoryItem(expression: '12.95 × 10', result: '12,950'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('12.95 × 10'), findsOneWidget);
      expect(find.text('12,950'), findsOneWidget);
      expect(find.byType(HistoryOverlay), findsNothing);
    });

    testWidgets('shows expression and exact error message when error is present',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '5÷0',
              result: '',
              errorMessage: 'Invalid mathematical operation',
              history: [],
            ),
          ),
        ),
      );

      expect(find.text('5÷0'), findsOneWidget);
      expect(find.text('Invalid mathematical operation'), findsOneWidget);
    });

    testWidgets('shows expression and Maximum length reached when limit is hit',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '12345',
              result: '',
              errorMessage: 'Maximum length reached',
              history: [],
            ),
          ),
        ),
      );

      expect(find.text('12345'), findsOneWidget);
      expect(find.text('Maximum length reached'), findsOneWidget);
    });

    testWidgets('shows active expression when typing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '12.95 × 10',
              result: '0',
              errorMessage: '',
              history: [],
            ),
          ),
        ),
      );

      expect(find.text('12.95 × 10'), findsOneWidget);
    });

    testWidgets('renders HistoryOverlay when isHistoryOpen is true and handles tap',
        (tester) async {
      String? tappedExpr;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DisplayPanel(
              expression: '',
              result: '12,950',
              errorMessage: '',
              isHistoryOpen: true,
              history: const [
                HistoryItem(expression: '11 × 21', result: '231'),
                HistoryItem(expression: '12.95 × 10', result: '12,950'),
              ],
              onHistoryItemTap: (expr) {
                tappedExpr = expr;
              },
            ),
          ),
        ),
      );

      expect(find.byType(HistoryOverlay), findsOneWidget);
      expect(find.text('11 × 21'), findsOneWidget);
      expect(find.text('231'), findsOneWidget);
      expect(find.text('12.95 × 10'), findsOneWidget);

      await tester.tap(find.text('11 × 21'));
      await tester.pumpAndSettle();

      expect(tappedExpr, '11 × 21');
    });

    testWidgets('renders vertical Scrollbar and SingleChildScrollView for long digits',
        (tester) async {
      final longDigits = '1234567890' * 20;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 300,
              child: DisplayPanel(
                expression: longDigits,
                result: '0',
                errorMessage: '',
                history: const [],
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Scrollbar), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text(longDigits), findsOneWidget);

      final scrollable = find.byType(SingleChildScrollView);
      final singleChild = tester.widget<SingleChildScrollView>(scrollable);
      expect(singleChild.scrollDirection, Axis.vertical);
      expect(singleChild.reverse, isTrue);
    });
  });
}
