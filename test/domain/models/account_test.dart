import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Account', () {
    const a = Account(
      id: '1',
      name: 'Checking',
      type: AccountType.checking,
      balance: 100000,
      clearedBalance: 90000,
      currency: 'USD',
      onBudget: true,
    );

    test('props contains all fields', () {
      expect(a.props.length, 7);
    });

    test('equal when all fields match', () {
      const b = Account(
        id: '1',
        name: 'Checking',
        type: AccountType.checking,
        balance: 100000,
        clearedBalance: 90000,
        currency: 'USD',
        onBudget: true,
      );
      expect(a, equals(b));
    });

    test('not equal when id differs', () {
      const b = Account(
        id: '2',
        name: 'Checking',
        type: AccountType.checking,
        balance: 100000,
        clearedBalance: 90000,
        currency: 'USD',
        onBudget: true,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when type differs', () {
      const b = Account(
        id: '1',
        name: 'Checking',
        type: AccountType.savings,
        balance: 100000,
        clearedBalance: 90000,
        currency: 'USD',
        onBudget: true,
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith produces updated instance', () {
      final updated = a.copyWith(balance: 200000);
      expect(updated.balance, 200000);
      expect(updated.id, a.id);
    });
  });
}
