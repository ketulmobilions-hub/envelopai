import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/categories_dao.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ICategoriesRepository)
class CategoriesRepository implements ICategoriesRepository {
  const CategoriesRepository(this._dao);

  final CategoriesDao _dao;

  @override
  Stream<List<Category>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  @override
  Future<List<Category>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<Category?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Stream<List<Category>> watchByGroup(String groupId) =>
      _dao.watchByGroup(groupId).map((rows) => rows.map(_toModel).toList());

  @override
  Future<void> save(Category category) => _dao.upsert(_toCompanion(category));

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);
}

Category _toModel(CategoryRow row) => Category(
  id: row.id,
  groupId: row.groupId,
  name: row.name,
  sortOrder: row.sortOrder,
  note: row.note,
  goalId: row.goalId,
);

CategoriesTableCompanion _toCompanion(Category c) => CategoriesTableCompanion(
  id: Value(c.id),
  groupId: Value(c.groupId),
  name: Value(c.name),
  sortOrder: Value(c.sortOrder),
  note: Value(c.note),
  goalId: Value(c.goalId),
);
