import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/category_groups_dao.dart';
import 'package:envelope/data/repositories/category_groups_repository.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCategoryGroupsDao extends Mock implements CategoryGroupsDao {}

CategoryGroupRow _row({
  String id = 'g1',
  String name = 'Bills',
  int sortOrder = 0,
  bool isHidden = false,
}) => CategoryGroupRow(
  id: id,
  name: name,
  sortOrder: sortOrder,
  isHidden: isHidden,
);

const CategoryGroup model = CategoryGroup(
  id: 'g1',
  name: 'Bills',
  sortOrder: 0,
  isHidden: false,
);

void main() {
  setUpAll(() => registerFallbackValue(const CategoryGroupsTableCompanion()));

  late MockCategoryGroupsDao dao;
  late CategoryGroupsRepository repo;

  setUp(() {
    dao = MockCategoryGroupsDao();
    repo = CategoryGroupsRepository(dao);
  });

  group('CategoryGroupsRepository', () {
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
      when(() => dao.getById('g1')).thenAnswer((_) async => _row());

      expect(await repo.getById('g1'), model);
    });

    test('save calls upsert with correct companion', () async {
      when(() => dao.upsert(any())).thenAnswer((_) async {});

      await repo.save(model);

      final captured =
          verify(() => dao.upsert(captureAny())).captured.single
              as CategoryGroupsTableCompanion;
      expect(captured.id.value, 'g1');
      expect(captured.name.value, 'Bills');
      expect(captured.sortOrder.value, 0);
      expect(captured.isHidden.value, isFalse);
    });

    test('deleteById delegates to DAO', () async {
      when(() => dao.deleteById(any())).thenAnswer((_) async => 1);

      await repo.deleteById('g1');

      verify(() => dao.deleteById('g1')).called(1);
    });
  });
}
