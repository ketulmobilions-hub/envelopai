import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/budget_entries_dao.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IBudgetRepository)
class BudgetRepository implements IBudgetRepository {
  const BudgetRepository(this._dao);

  final BudgetEntriesDao _dao;

  @override
  Stream<List<BudgetEntry>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  @override
  Future<List<BudgetEntry>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<BudgetEntry?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Stream<List<BudgetEntry>> watchForMonth(int month, int year) => _dao
      .watchForMonth(month, year)
      .map((rows) => rows.map(_toModel).toList());

  @override
  Future<BudgetEntry> getOrCreate(
    String categoryId,
    int month,
    int year,
  ) async {
    final row = await _dao.getOrCreate(categoryId, month, year);
    return _toModel(row);
  }

  @override
  Future<void> save(BudgetEntry entry) => _dao.upsert(_toCompanion(entry));

  @override
  Future<void> updateAvailable(String id, int available) =>
      _dao.updateAvailable(id, available);

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);
}

BudgetEntry _toModel(BudgetEntryRow row) => BudgetEntry(
  id: row.id,
  categoryId: row.categoryId,
  month: row.month,
  year: row.year,
  budgeted: row.budgeted,
  activity: row.activity,
  available: row.available,
);

BudgetEntriesTableCompanion _toCompanion(BudgetEntry e) =>
    BudgetEntriesTableCompanion(
      id: Value(e.id),
      categoryId: Value(e.categoryId),
      month: Value(e.month),
      year: Value(e.year),
      budgeted: Value(e.budgeted),
      activity: Value(e.activity),
      available: Value(e.available),
    );
