import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/budget/widgets/move_money_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _catA = Category(id: 'c1', groupId: 'g1', name: 'Rent', sortOrder: 0);
const _catB = Category(id: 'c2', groupId: 'g1', name: 'Food', sortOrder: 1);
const List<Category> _cats = [_catA, _catB];

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('MoveMoneySheet', () {
    testWidgets('shows message when fewer than two categories', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const MoveMoneySheet(
            categories: [_catA],
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
        _wrap(const MoveMoneySheet(categories: _cats)),
      );
      expect(find.text('Move Money'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Move'), findsOneWidget);
    });

    testWidgets('shows From and To dropdowns', (tester) async {
      await tester.pumpWidget(
        _wrap(const MoveMoneySheet(categories: _cats)),
      );
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);
    });

    testWidgets('shows validation errors when Move tapped with empty fields',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const MoveMoneySheet(categories: _cats)),
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
                  builder: (_) => const MoveMoneySheet(categories: _cats),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Select From = Rent
      await tester.tap(find.text('From'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rent').last);
      await tester.pumpAndSettle();

      // Select To = Food
      await tester.tap(find.text('To'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Food').last);
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byType(TextFormField).last, '50.00');
      await tester.tap(find.widgetWithText(FilledButton, 'Move'));
      await tester.pumpAndSettle();

      expect(result?.fromCategoryId, 'c1');
      expect(result?.toCategoryId, 'c2');
      expect(result?.amount, 5000);
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
                  builder: (_) => const MoveMoneySheet(categories: _cats),
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
