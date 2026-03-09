import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/budget/widgets/move_money_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MoveMoneySheet', () {
    const catA = Category(id: 'c1', groupId: 'g1', name: 'Rent', sortOrder: 0);
    const catB = Category(id: 'c2', groupId: 'g1', name: 'Food', sortOrder: 1);
    const cats = [catA, catB];
    // Rent: $100 (10000 cents), Food: $80 (8000 cents).
    const budgeted = {'c1': 10000, 'c2': 8000};

    testWidgets('shows message when fewer than two categories', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MoveMoneySheet(
            categories: [catA],
            budgetedByCategoryId: budgeted,
          ),
        ),
      );
      expect(
        find.text('Add at least two categories before moving money.'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Move'), findsNothing);
    });

    testWidgets('shows title and Move button', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MoveMoneySheet(
            categories: cats,
            budgetedByCategoryId: budgeted,
          ),
        ),
      );
      expect(find.text('Move Money'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Move'), findsOneWidget);
    });

    testWidgets('shows From and To dropdowns', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MoveMoneySheet(
            categories: cats,
            budgetedByCategoryId: budgeted,
          ),
        ),
      );
      expect(
        find.byType(DropdownButtonFormField<String>),
        findsNWidgets(2),
      );
    });

    testWidgets('shows validation errors when Move tapped with empty fields',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MoveMoneySheet(
            categories: cats,
            budgetedByCategoryId: budgeted,
          ),
        ),
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Move'));
      await tester.pump();
      expect(find.text('Select a category'), findsWidgets);
      expect(find.text('Enter a positive amount'), findsOneWidget);
    });

    testWidgets('pops with correct result on valid input', (tester) async {
      MoveMoneyResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<MoveMoneyResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const MoveMoneySheet(
                    categories: cats,
                    budgetedByCategoryId: budgeted,
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

      // Select From = Rent.
      await tester.tap(
        find.byType(DropdownButtonFormField<String>).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent').last);
      await tester.pumpAndSettle();

      // Select To = Food.
      await tester.tap(
        find.byType(DropdownButtonFormField<String>).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      // Enter amount — $50 is within the $100 budgeted for Rent.
      await tester.enterText(find.byType(TextFormField).last, '50.00');
      await tester.tap(find.widgetWithText(FilledButton, 'Move'));
      await tester.pumpAndSettle();

      expect(result?.fromCategoryId, 'c1');
      expect(result?.toCategoryId, 'c2');
      expect(result?.amount, 5000);
    });

    testWidgets(
        'shows error with formatted cap when amount exceeds budgeted in from '
        'category', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showModalBottomSheet<MoveMoneyResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const MoveMoneySheet(
                    categories: cats,
                    // Rent (c1) has $100 budgeted.
                    budgetedByCategoryId: budgeted,
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

      // Select From = Rent.
      await tester.tap(
        find.byType(DropdownButtonFormField<String>).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent').last);
      await tester.pumpAndSettle();

      // Select To = Food.
      await tester.tap(
        find.byType(DropdownButtonFormField<String>).last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      // Enter amount exceeding budgeted ($150 > $100).
      await tester.enterText(find.byType(TextFormField).last, '150.00');
      await tester.tap(find.widgetWithText(FilledButton, 'Move'));
      await tester.pump();

      // Error must mention the formatted cap ($100.00).
      expect(find.textContaining(r'$100.00'), findsOneWidget);
      expect(find.textContaining('budgeted in this category'), findsOneWidget);
    });

    testWidgets(
        'shows error when from category has no budgeted amount '
        '(budgetedByCategoryId fallback to 0)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showModalBottomSheet<MoveMoneyResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const MoveMoneySheet(
                    categories: cats,
                    // Empty map — covers the `?? 0` fallback path.
                    budgetedByCategoryId: {},
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

      // Select From = Rent.
      await tester.tap(
        find.byType(DropdownButtonFormField<String>).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent').last);
      await tester.pumpAndSettle();

      // Enter any positive amount.
      await tester.enterText(find.byType(TextFormField).last, '10.00');
      await tester.tap(find.widgetWithText(FilledButton, 'Move'));
      await tester.pump();

      expect(
        find.text('No positive amount is budgeted in this category'),
        findsOneWidget,
      );
    });

    testWidgets('dismiss without saving returns null', (tester) async {
      var called = false;
      MoveMoneyResult? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                called = true;
                result = await showModalBottomSheet<MoveMoneyResult>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const MoveMoneySheet(
                    categories: cats,
                    budgetedByCategoryId: budgeted,
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

      tester.state<NavigatorState>(find.byType(Navigator).last).pop();
      await tester.pumpAndSettle();

      expect(called, isTrue);
      expect(result, isNull);
    });
  });
}
