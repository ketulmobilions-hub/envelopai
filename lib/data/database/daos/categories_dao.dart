import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/tables.dart';

part 'categories_dao.g.dart';

@DriftAccessor(tables: [CategoriesTable])
class CategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$CategoriesDaoMixin {
  CategoriesDao(super.attachedDatabase);

  Stream<List<CategoryRow>> watchAll() => (select(
    categoriesTable,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<List<CategoryRow>> getAll() => (select(
    categoriesTable,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<CategoryRow?> getById(String id) => (select(
    categoriesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<CategoryRow>> watchByGroup(String groupId) =>
      (select(categoriesTable)
            ..where((t) => t.groupId.equals(groupId))
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  Future<void> upsert(CategoriesTableCompanion companion) =>
      into(categoriesTable).insertOnConflictUpdate(companion);

  Future<int> deleteById(String id) =>
      (delete(categoriesTable)..where((t) => t.id.equals(id))).go();
}
