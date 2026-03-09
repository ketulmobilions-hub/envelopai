import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _cat = Category(
  id: 'c1',
  groupId: 'g1',
  name: 'Groceries',
  sortOrder: 0,
);

void main() {
  group('AllocationSheet', () {
    testWidgets('shows category name', (tester) async {
      await tester.pumpWidget(
        _wrap(const AllocationSheet(category: _cat, currentBudgeted: 0)),
      );
      expect(find.text('Groceries'), findsOneWidget);
    });

    testWidgets('pre-fills text field with current budgeted amount',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const AllocationSheet(category: _cat, currentBudgeted: 15000)),
      );
      expect(find.text('150.00'), findsOneWidget);
    });

    testWidgets('pre-fills zero when currentBudgeted is 0', (tester) async {
      await tester.pumpWidget(
        _wrap(const AllocationSheet(category: _cat, currentBudgeted: 0)),
      );
      expect(find.text('0.00'), findsOneWidget);
    });

    testWidgets('Save button is present', (tester) async {
      await tester.pumpWidget(
        _wrap(const AllocationSheet(category: _cat, currentBudgeted: 0)),
      );
      expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
    });

    testWidgets('pops with correct int value when Save is tapped',
        (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<int>(
                  context: context,
                  builder: (_) => const AllocationSheet(
                    category: _cat,
                    currentBudgeted: 0,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '250.00');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(result, 25000);
    });

    testWidgets('pops via onSubmitted keyboard action', (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<int>(
                  context: context,
                  builder: (_) => const AllocationSheet(
                    category: _cat,
                    currentBudgeted: 0,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '75.50');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(result, 7550);
    });

    testWidgets('dismiss without save returns null', (tester) async {
      int? result;
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                called = true;
                result = await showModalBottomSheet<int>(
                  context: context,
                  builder: (_) => const AllocationSheet(
                    category: _cat,
                    currentBudgeted: 5000,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Dismiss by popping the route without saving.
      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
    });

    testWidgets('ignores non-numeric input on save', (tester) async {
      int? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<int>(
                  context: context,
                  builder: (_) => const AllocationSheet(
                    category: _cat,
                    currentBudgeted: 0,
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pump();

      // Sheet remains open — result is still null.
      expect(result, isNull);
    });
  });
}
