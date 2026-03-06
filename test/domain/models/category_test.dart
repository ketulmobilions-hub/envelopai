import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    const a = Category(
      id: '1',
      groupId: 'g1',
      name: 'Rent',
      sortOrder: 0,
    );

    test('props contains all fields', () {
      expect(a.props.length, 6);
    });

    test('equal when all fields match', () {
      const b = Category(id: '1', groupId: 'g1', name: 'Rent', sortOrder: 0);
      expect(a, equals(b));
    });

    test('not equal when goalId differs', () {
      const b = Category(
        id: '1',
        groupId: 'g1',
        name: 'Rent',
        sortOrder: 0,
        goalId: 'goal-1',
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when note differs', () {
      const b = Category(
        id: '1',
        groupId: 'g1',
        name: 'Rent',
        sortOrder: 0,
        note: 'Due 1st',
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith produces updated instance', () {
      final updated = a.copyWith(note: 'Due 1st');
      expect(updated.note, 'Due 1st');
      expect(updated.id, a.id);
    });
  });
}
