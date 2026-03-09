import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/accounts/widgets/account_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _account = Account(
  id: 'a1',
  name: 'Main Checking',
  type: AccountType.checking,
  balance: 150000,
  clearedBalance: 120000,
  currency: 'USD',
  onBudget: true,
);

void main() {
  group('AccountRow', () {
    testWidgets('shows account name', (tester) async {
      await tester.pumpWidget(_wrap(const AccountRow(account: _account)));
      expect(find.text('Main Checking'), findsOneWidget);
    });

    testWidgets('shows type label', (tester) async {
      await tester.pumpWidget(_wrap(const AccountRow(account: _account)));
      expect(find.text('Checking'), findsOneWidget);
    });

    testWidgets('shows cleared, uncleared, and total amounts', (tester) async {
      await tester.pumpWidget(_wrap(const AccountRow(account: _account)));
      // cleared = 120000 → $1,200.00
      expect(find.text(r'$1,200.00'), findsOneWidget);
      // uncleared = 150000 - 120000 = 30000 → $300.00
      expect(find.text(r'$300.00'), findsOneWidget);
      // total = 150000 → $1,500.00
      expect(find.text(r'$1,500.00'), findsOneWidget);
    });

    testWidgets('shows negative total in error colour', (tester) async {
      const creditCard = Account(
        id: 'a2',
        name: 'Visa',
        type: AccountType.creditCard,
        balance: -50000,
        clearedBalance: -50000,
        currency: 'USD',
        onBudget: true,
      );
      await tester.pumpWidget(_wrap(const AccountRow(account: creditCard)));
      expect(find.textContaining(r'-$500.00'), findsWidgets);
      final texts = tester.widgetList<Text>(
        find.textContaining(r'-$500.00'),
      );
      final colorScheme =
          Theme.of(tester.element(find.byType(AccountRow))).colorScheme;
      expect(
        texts.any((t) => t.style?.color == colorScheme.error),
        isTrue,
      );
    });

    testWidgets('shows type label for credit card', (tester) async {
      const cc = Account(
        id: 'a3',
        name: 'Visa',
        type: AccountType.creditCard,
        balance: 0,
        clearedBalance: 0,
        currency: 'USD',
        onBudget: true,
      );
      await tester.pumpWidget(_wrap(const AccountRow(account: cc)));
      expect(find.text('Credit Card'), findsOneWidget);
    });
  });

  group('AccountColumnHeader', () {
    testWidgets('shows section title in uppercase', (tester) async {
      await tester.pumpWidget(
        _wrap(const AccountColumnHeader(title: 'Budget Accounts')),
      );
      expect(find.text('BUDGET ACCOUNTS'), findsOneWidget);
    });

    testWidgets('shows Cleared, Uncleared, Total labels', (tester) async {
      await tester.pumpWidget(
        _wrap(const AccountColumnHeader(title: 'Budget Accounts')),
      );
      expect(find.text('Cleared'), findsOneWidget);
      expect(find.text('Uncleared'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });
  });
}
