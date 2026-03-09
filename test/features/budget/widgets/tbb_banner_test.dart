import 'package:envelope/features/budget/budget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) =>
    MaterialApp(home: Scaffold(body: child));

void main() {
  group('TbbBanner', () {
    testWidgets('shows "Ready to Assign" when tbb > 0', (tester) async {
      await tester.pumpWidget(_wrap(const TbbBanner(tbb: 5000)));

      expect(find.text('Ready to Assign'), findsOneWidget);
      expect(find.text(r'$50.00'), findsOneWidget);
    });

    testWidgets('shows "All Money Assigned" when tbb = 0', (tester) async {
      await tester.pumpWidget(_wrap(const TbbBanner(tbb: 0)));

      expect(find.text('All Money Assigned'), findsOneWidget);
      expect(find.text(r'$0.00'), findsOneWidget);
    });

    testWidgets('shows "Overspent" when tbb < 0', (tester) async {
      await tester.pumpWidget(_wrap(const TbbBanner(tbb: -2000)));

      expect(find.text('Overspent'), findsOneWidget);
      expect(find.text(r'-$20.00'), findsOneWidget);
    });

    testWidgets('updates when tbb changes', (tester) async {
      await tester.pumpWidget(_wrap(const TbbBanner(tbb: 1000)));
      expect(find.text('Ready to Assign'), findsOneWidget);

      await tester.pumpWidget(_wrap(const TbbBanner(tbb: -500)));
      expect(find.text('Overspent'), findsOneWidget);
    });
  });
}
