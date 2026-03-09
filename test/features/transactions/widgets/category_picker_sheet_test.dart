import 'package:envelope/domain/models/models.dart';
import 'package:envelope/features/transactions/widgets/category_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

const _group1 = CategoryGroup(
  id: 'g1',
  name: 'Bills',
  sortOrder: 0,
  isHidden: false,
);
const _group2 = CategoryGroup(
  id: 'g2',
  name: 'Groceries',
  sortOrder: 1,
  isHidden: false,
);
const _catRent = Category(id: 'c1', groupId: 'g1', name: 'Rent', sortOrder: 0);
const _catElectric = Category(
  id: 'c2',
  groupId: 'g1',
  name: 'Electric',
  sortOrder: 1,
);
const _catFood = Category(id: 'c3', groupId: 'g2', name: 'Food', sortOrder: 0);

void main() {
  group('CategoryPickerSheet', () {
    testWidgets('shows group headers in uppercase', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryPickerSheet(
            groups: [_group1],
            categories: [_catRent],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('BILLS'), findsOneWidget);
    });

    testWidgets('shows category names', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryPickerSheet(
            groups: [_group1, _group2],
            categories: [_catRent, _catElectric, _catFood],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Electric'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('shows checkmark for selectedId', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryPickerSheet(
            groups: [_group1],
            categories: [_catRent, _catElectric],
            selectedId: 'c1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('filters categories by search query', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryPickerSheet(
            groups: [_group1, _group2],
            categories: [_catRent, _catElectric, _catFood],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'rent');
      await tester.pump();
      expect(find.text('Rent'), findsOneWidget);
      expect(find.text('Electric'), findsNothing);
      expect(find.text('Food'), findsNothing);
    });

    testWidgets('hides group header when no categories match search',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryPickerSheet(
            groups: [_group1, _group2],
            categories: [_catRent, _catElectric, _catFood],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'food');
      await tester.pump();
      expect(find.text('BILLS'), findsNothing);
      expect(find.text('GROCERIES'), findsOneWidget);
    });

    testWidgets('shows No categories found when nothing matches',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const CategoryPickerSheet(
            groups: [_group1],
            categories: [_catRent],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('No categories found'), findsOneWidget);
    });

    testWidgets('pops with selected category when tapped', (tester) async {
      Category? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showModalBottomSheet<Category>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const CategoryPickerSheet(
                    groups: [_group1],
                    categories: [_catRent],
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
      await tester.tap(find.text('Rent'));
      await tester.pumpAndSettle();
      expect(result?.id, 'c1');
      expect(result?.name, 'Rent');
    });
  });
}
