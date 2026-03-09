import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _cat = Category(
  id: 'c1',
  groupId: 'g1',
  name: 'Rent',
  sortOrder: 0,
);

const _entry = BudgetEntry(
  id: 'e1',
  categoryId: 'c1',
  month: 3,
  year: 2026,
  budgeted: 150000,
  activity: 150000,
  available: 0,
);

void main() {
  group('CategoryRow', () {
    testWidgets('shows category name', (tester) async {
      await tester.pumpWidget(_wrap(const CategoryRow(category: _cat)));
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('shows zero amounts when entry is null', (tester) async {
      await tester.pumpWidget(_wrap(const CategoryRow(category: _cat)));
      // All three columns show $0.00.
      expect(find.text(r'$0.00'), findsNWidgets(3));
    });

    testWidgets('shows budgeted and activity from entry', (tester) async {
      await tester
          .pumpWidget(_wrap(const CategoryRow(category: _cat, entry: _entry)));
      expect(find.text(r'$1,500.00'), findsNWidgets(2)); // budgeted + activity
      expect(find.text(r'$0.00'), findsOneWidget); // available
    });

    testWidgets('shows negative available in red', (tester) async {
      const overspent = BudgetEntry(
        id: 'e2',
        categoryId: 'c1',
        month: 3,
        year: 2026,
        budgeted: 50000,
        activity: 100000,
        available: -50000,
      );
      await tester.pumpWidget(
        _wrap(const CategoryRow(category: _cat, entry: overspent)),
      );
      expect(find.text(r'-$500.00'), findsOneWidget);
      // Verify the overspent amount is rendered in the error colour.
      final text = tester.widget<Text>(find.text(r'-$500.00'));
      final colorScheme =
          Theme.of(tester.element(find.text(r'-$500.00'))).colorScheme;
      expect(text.style?.color, colorScheme.error);
    });
  });

  group('CategoryGroupHeader', () {
    testWidgets('shows group name in uppercase', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CategoryGroupHeader(
            name: 'Fixed Bills',
            totalAvailable: 10000,
            isExpanded: true,
            onToggle: () {},
          ),
        ),
      );
      expect(find.text('FIXED BILLS'), findsOneWidget);
    });

    testWidgets('shows total available amount', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CategoryGroupHeader(
            name: 'Savings',
            totalAvailable: 25000,
            isExpanded: true,
            onToggle: () {},
          ),
        ),
      );
      expect(find.text(r'$250.00'), findsOneWidget);
    });

    testWidgets('calls onToggle when tapped', (tester) async {
      var toggled = false;
      await tester.pumpWidget(
        _wrap(
          CategoryGroupHeader(
            name: 'Bills',
            totalAvailable: 0,
            isExpanded: true,
            onToggle: () => toggled = true,
          ),
        ),
      );
      await tester.tap(find.byType(CategoryGroupHeader));
      expect(toggled, isTrue);
    });

    testWidgets('shows negative totalAvailable in error colour',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CategoryGroupHeader(
            name: 'Overspent',
            totalAvailable: -10000,
            isExpanded: true,
            onToggle: () {},
          ),
        ),
      );
      expect(find.text(r'-$100.00'), findsOneWidget);
      final text = tester.widget<Text>(find.text(r'-$100.00'));
      final colorScheme =
          Theme.of(tester.element(find.text(r'-$100.00'))).colorScheme;
      expect(text.style?.color, colorScheme.error);
    });
  });
}
