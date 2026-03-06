import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/tables.dart';

part 'category_groups_dao.g.dart';

@DriftAccessor(tables: [CategoryGroupsTable])
class CategoryGroupsDao extends DatabaseAccessor<AppDatabase>
    with _$CategoryGroupsDaoMixin {
  CategoryGroupsDao(super.attachedDatabase);

  Stream<List<CategoryGroupRow>> watchAll() => (select(
    categoryGroupsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch();

  Future<List<CategoryGroupRow>> getAll() => (select(
    categoryGroupsTable,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  Future<CategoryGroupRow?> getById(String id) => (select(
    categoryGroupsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(CategoryGroupsTableCompanion companion) =>
      into(categoryGroupsTable).insertOnConflictUpdate(companion);

  Future<int> deleteById(String id) =>
      (delete(categoryGroupsTable)..where((t) => t.id.equals(id))).go();
}
