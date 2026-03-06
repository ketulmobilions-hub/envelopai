import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/category_groups_dao.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ICategoryGroupsRepository)
class CategoryGroupsRepository implements ICategoryGroupsRepository {
  const CategoryGroupsRepository(this._dao);

  final CategoryGroupsDao _dao;

  @override
  Stream<List<CategoryGroup>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  @override
  Future<List<CategoryGroup>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<CategoryGroup?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Future<void> save(CategoryGroup group) => _dao.upsert(_toCompanion(group));

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);
}

CategoryGroup _toModel(CategoryGroupRow row) => CategoryGroup(
  id: row.id,
  name: row.name,
  sortOrder: row.sortOrder,
  isHidden: row.isHidden,
);

CategoryGroupsTableCompanion _toCompanion(CategoryGroup g) =>
    CategoryGroupsTableCompanion(
      id: Value(g.id),
      name: Value(g.name),
      sortOrder: Value(g.sortOrder),
      isHidden: Value(g.isHidden),
    );
