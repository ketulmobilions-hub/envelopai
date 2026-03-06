import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetEntry', () {
    const a = BudgetEntry(
      id: '1',
      categoryId: 'cat-1',
      month: 3,
      year: 2026,
      budgeted: 50000,
      activity: 20000,
      available: 30000,
    );

    test('props contains all fields', () {
      expect(a.props.length, 7);
    });

    test('equal when all fields match', () {
      const b = BudgetEntry(
        id: '1',
        categoryId: 'cat-1',
        month: 3,
        year: 2026,
        budgeted: 50000,
        activity: 20000,
        available: 30000,
      );
      expect(a, equals(b));
    });

    test('not equal when available differs', () {
      const b = BudgetEntry(
        id: '1',
        categoryId: 'cat-1',
        month: 3,
        year: 2026,
        budgeted: 50000,
        activity: 20000,
        available: 10000,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when budgeted differs', () {
      const b = BudgetEntry(
        id: '1',
        categoryId: 'cat-1',
        month: 3,
        year: 2026,
        budgeted: 60000,
        activity: 20000,
        available: 30000,
      );
      expect(a, isNot(equals(b)));
    });

    test('assert rejects invalid month', () {
      expect(
        () => BudgetEntry(
          id: '2',
          categoryId: 'cat-1',
          month: 13,
          year: 2026,
          budgeted: 0,
          activity: 0,
          available: 0,
        ),
        throwsAssertionError,
      );
    });

    test('copyWith produces updated instance', () {
      final updated = a.copyWith(budgeted: 60000);
      expect(updated.budgeted, 60000);
      expect(updated.id, a.id);
    });
  });
}
