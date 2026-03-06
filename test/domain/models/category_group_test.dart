import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryGroup', () {
    const a = CategoryGroup(
      id: '1',
      name: 'Fixed Bills',
      sortOrder: 0,
      isHidden: false,
    );

    test('props contains all fields', () {
      expect(a.props.length, 4);
    });

    test('equal when all fields match', () {
      const b = CategoryGroup(
        id: '1',
        name: 'Fixed Bills',
        sortOrder: 0,
        isHidden: false,
      );
      expect(a, equals(b));
    });

    test('not equal when name differs', () {
      const b = CategoryGroup(
        id: '1',
        name: 'Savings',
        sortOrder: 0,
        isHidden: false,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when isHidden differs', () {
      const b = CategoryGroup(
        id: '1',
        name: 'Fixed Bills',
        sortOrder: 0,
        isHidden: true,
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith produces updated instance', () {
      final updated = a.copyWith(isHidden: true);
      expect(updated.isHidden, isTrue);
      expect(updated.id, a.id);
    });
  });
}
