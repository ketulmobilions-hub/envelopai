import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Transaction', () {
    final now = DateTime.utc(2026, 3, 6);

    final a = Transaction(
      id: '1',
      accountId: 'acc-1',
      payee: 'Grocery Store',
      amount: -5000,
      date: now,
      cleared: false,
      type: TransactionType.expense,
      updatedAt: now,
      isDeleted: false,
      categoryId: 'cat-1',
    );

    test('props contains all fields', () {
      expect(a.props.length, 12);
    });

    test('equal when all fields match', () {
      final b = Transaction(
        id: '1',
        accountId: 'acc-1',
        payee: 'Grocery Store',
        amount: -5000,
        date: now,
        cleared: false,
        type: TransactionType.expense,
        updatedAt: now,
        isDeleted: false,
        categoryId: 'cat-1',
      );
      expect(a, equals(b));
    });

    test('not equal when amount differs', () {
      final b = Transaction(
        id: '1',
        accountId: 'acc-1',
        payee: 'Grocery Store',
        amount: -7500,
        date: now,
        cleared: false,
        type: TransactionType.expense,
        updatedAt: now,
        isDeleted: false,
        categoryId: 'cat-1',
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when type differs', () {
      final b = Transaction(
        id: '1',
        accountId: 'acc-1',
        payee: 'Salary',
        amount: 500000,
        date: now,
        cleared: false,
        type: TransactionType.income,
        updatedAt: now,
        isDeleted: false,
      );
      expect(a, isNot(equals(b)));
    });

    test('transfer has null categoryId', () {
      final t = Transaction(
        id: '2',
        accountId: 'acc-1',
        payee: 'Transfer',
        amount: 10000,
        date: now,
        cleared: false,
        type: TransactionType.transfer,
        updatedAt: now,
        isDeleted: false,
        transferPairId: 'txn-3',
      );
      expect(t.categoryId, isNull);
    });

    test('assert rejects transfer with categoryId', () {
      expect(
        () => Transaction(
          id: '3',
          accountId: 'acc-1',
          payee: 'Transfer',
          amount: 10000,
          date: now,
          cleared: false,
          type: TransactionType.transfer,
          updatedAt: now,
          isDeleted: false,
          transferPairId: 'txn-4',
          categoryId: 'cat-1',
        ),
        throwsAssertionError,
      );
    });

    test('assert rejects transfer without transferPairId', () {
      expect(
        () => Transaction(
          id: '4',
          accountId: 'acc-1',
          payee: 'Transfer',
          amount: 10000,
          date: now,
          cleared: false,
          type: TransactionType.transfer,
          updatedAt: now,
          isDeleted: false,
        ),
        throwsAssertionError,
      );
    });

    test('copyWith produces updated instance', () {
      final updated = a.copyWith(cleared: true);
      expect(updated.cleared, isTrue);
      expect(updated.id, a.id);
    });
  });
}
