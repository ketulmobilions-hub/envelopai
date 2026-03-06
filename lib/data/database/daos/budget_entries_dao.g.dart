// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'budget_entries_dao.dart';

// ignore_for_file: type=lint
mixin _$BudgetEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CategoryGroupsTableTable get categoryGroupsTable =>
      attachedDatabase.categoryGroupsTable;
  $CategoriesTableTable get categoriesTable => attachedDatabase.categoriesTable;
  $BudgetEntriesTableTable get budgetEntriesTable =>
      attachedDatabase.budgetEntriesTable;
  BudgetEntriesDaoManager get managers => BudgetEntriesDaoManager(this);
}

class BudgetEntriesDaoManager {
  final _$BudgetEntriesDaoMixin _db;
  BudgetEntriesDaoManager(this._db);
  $$CategoryGroupsTableTableTableManager get categoryGroupsTable =>
      $$CategoryGroupsTableTableTableManager(
        _db.attachedDatabase,
        _db.categoryGroupsTable,
      );
  $$CategoriesTableTableTableManager get categoriesTable =>
      $$CategoriesTableTableTableManager(
        _db.attachedDatabase,
        _db.categoriesTable,
      );
  $$BudgetEntriesTableTableTableManager get budgetEntriesTable =>
      $$BudgetEntriesTableTableTableManager(
        _db.attachedDatabase,
        _db.budgetEntriesTable,
      );
}
