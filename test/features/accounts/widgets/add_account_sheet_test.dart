import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/accounts/widgets/add_account_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('AddAccountSheet', () {
    testWidgets('shows title and Add Account button', (tester) async {
      await tester.pumpWidget(_wrap(const AddAccountSheet()));
      expect(find.text('Add Account'), findsWidgets);
    });

    testWidgets('shows validation errors when saved with empty fields',
        (tester) async {
      await tester.pumpWidget(_wrap(const AddAccountSheet()));
      await tester.tap(find.widgetWithText(FilledButton, 'Add Account'));
      await tester.pump();
      expect(find.text('Enter a name'), findsOneWidget);
      expect(find.text('Enter a balance'), findsOneWidget);
    });

    testWidgets('pops with correct Account on valid input', (tester) async {
      Account? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<Account>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddAccountSheet(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Enter name.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Account name'),
        'My Checking',
      );
      // Enter balance.
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Starting balance'),
        '250.00',
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Add Account'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result?.name, 'My Checking');
      expect(result?.balance, 25000);
      expect(result?.clearedBalance, 25000);
      expect(result?.currency, 'USD');
      expect(result?.onBudget, isTrue);
      // id must be a valid non-empty UUID.
      expect(result?.id, isNotEmpty);
    });

    testWidgets('onBudget toggle defaults to true', (tester) async {
      await tester.pumpWidget(_wrap(const AddAccountSheet()));
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('toggling onBudget to false is reflected in result',
        (tester) async {
      Account? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<Account>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddAccountSheet(),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Account name'),
        'Savings',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Starting balance'),
        '0',
      );
      // Turn off onBudget.
      await tester.tap(find.byType(Switch));
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Add Account'));
      await tester.pumpAndSettle();

      expect(result?.onBudget, isFalse);
    });

    testWidgets('dismiss without saving returns null', (tester) async {
      Account? result;
      var called = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                called = true;
                result = await showModalBottomSheet<Account>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const AddAccountSheet(),
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
