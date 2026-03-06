// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_groups_dao.dart';

// ignore_for_file: type=lint
mixin _$CategoryGroupsDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoryGroupsTableTable get categoryGroupsTable =>
      attachedDatabase.categoryGroupsTable;
  CategoryGroupsDaoManager get managers => CategoryGroupsDaoManager(this);
}

class CategoryGroupsDaoManager {
  final _$CategoryGroupsDaoMixin _db;
  CategoryGroupsDaoManager(this._db);
  $$CategoryGroupsTableTableTableManager get categoryGroupsTable =>
      $$CategoryGroupsTableTableTableManager(
        _db.attachedDatabase,
        _db.categoryGroupsTable,
      );
}
