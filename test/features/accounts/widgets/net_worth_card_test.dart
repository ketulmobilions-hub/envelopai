import 'package:envelope/features/accounts/widgets/net_worth_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('NetWorthCard', () {
    testWidgets('shows Net Worth label', (tester) async {
      await tester.pumpWidget(_wrap(const NetWorthCard(netWorth: 0)));
      expect(find.text('Net Worth'), findsOneWidget);
    });

    testWidgets('formats positive net worth correctly', (tester) async {
      await tester.pumpWidget(_wrap(const NetWorthCard(netWorth: 123456)));
      expect(find.text(r'$1,234.56'), findsOneWidget);
    });

    testWidgets('formats negative net worth correctly', (tester) async {
      await tester.pumpWidget(_wrap(const NetWorthCard(netWorth: -50000)));
      expect(find.text(r'-$500.00'), findsOneWidget);
    });

    testWidgets('shows negative value in error colour', (tester) async {
      await tester.pumpWidget(_wrap(const NetWorthCard(netWorth: -1000)));
      final text = tester.widget<Text>(find.text(r'-$10.00'));
      final colorScheme =
          Theme.of(tester.element(find.byType(NetWorthCard))).colorScheme;
      expect(text.style?.color, colorScheme.error);
    });

    testWidgets('shows positive value in primary colour', (tester) async {
      await tester.pumpWidget(_wrap(const NetWorthCard(netWorth: 5000)));
      final text = tester.widget<Text>(find.text(r'$50.00'));
      final colorScheme =
          Theme.of(tester.element(find.byType(NetWorthCard))).colorScheme;
      expect(text.style?.color, colorScheme.primary);
    });
  });
}
