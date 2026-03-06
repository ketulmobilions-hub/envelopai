import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/categories_dao.dart';
import 'package:envelope/data/repositories/categories_repository.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoriesDao extends Mock implements CategoriesDao {}

CategoryRow _row({
  String id = 'c1',
  String groupId = 'g1',
  String name = 'Rent',
  int sortOrder = 0,
  String? note,
  String? goalId,
}) => CategoryRow(
  id: id,
  groupId: groupId,
  name: name,
  sortOrder: sortOrder,
  note: note,
  goalId: goalId,
);

const Category model = Category(
  id: 'c1',
  groupId: 'g1',
  name: 'Rent',
  sortOrder: 0,
);

void main() {
  setUpAll(() => registerFallbackValue(const CategoriesTableCompanion()));

  late MockCategoriesDao dao;
  late CategoriesRepository repo;

  setUp(() {
    dao = MockCategoriesDao();
    repo = CategoriesRepository(dao);
  });

  group('CategoriesRepository', () {
    test('watchAll maps rows to domain models', () {
      when(() => dao.watchAll()).thenAnswer((_) => Stream.value([_row()]));

      expect(repo.watchAll(), emits([model]));
    });

    test('getAll maps rows to domain models', () async {
      when(() => dao.getAll()).thenAnswer((_) async => [_row()]);

      expect(await repo.getAll(), [model]);
    });

    test('getById returns null when not found', () async {
      when(() => dao.getById(any())).thenAnswer((_) async => null);

      expect(await repo.getById('no-such'), isNull);
    });

    test('getById returns mapped model', () async {
      when(() => dao.getById('c1')).thenAnswer((_) async => _row());

      expect(await repo.getById('c1'), model);
    });

    test('watchByGroup filters to group', () {
      when(
        () => dao.watchByGroup('g1'),
      ).thenAnswer((_) => Stream.value([_row()]));

      expect(repo.watchByGroup('g1'), emits([model]));
    });

    test('save calls upsert with correct companion', () async {
      when(() => dao.upsert(any())).thenAnswer((_) async {});

      await repo.save(model);

      final captured =
          verify(() => dao.upsert(captureAny())).captured.single
              as CategoriesTableCompanion;
      expect(captured.id.value, 'c1');
      expect(captured.groupId.value, 'g1');
      expect(captured.name.value, 'Rent');
      expect(captured.sortOrder.value, 0);
    });

    test('deleteById delegates to DAO', () async {
      when(() => dao.deleteById(any())).thenAnswer((_) async => 1);

      await repo.deleteById('c1');

      verify(() => dao.deleteById('c1')).called(1);
    });
  });
}
