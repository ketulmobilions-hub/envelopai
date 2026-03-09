import 'dart:async';

import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/budget_entries_dao.dart';
import 'package:envelope/data/database/daos/transactions_dao.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IBudgetRepository)
class BudgetRepository implements IBudgetRepository {
  const BudgetRepository(this._dao, this._transactionsDao);

  final BudgetEntriesDao _dao;
  final TransactionsDao _transactionsDao;

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
  Stream<({List<BudgetEntry> entries, int tbb})> watchMonthSummary(
    int month,
    int year,
  ) {
    late final StreamController<({List<BudgetEntry> entries, int tbb})>
        controller;
    StreamSubscription<List<BudgetEntry>>? entriesSub;
    StreamSubscription<int>? tbbSub;

    List<BudgetEntry>? latestEntries;
    int? latestTbb;

    void tryEmit() {
      final e = latestEntries;
      final t = latestTbb;
      if (e != null && t != null) controller.add((entries: e, tbb: t));
    }

    controller = StreamController(
      onListen: () {
        entriesSub = watchForMonth(month, year).listen(
          (entries) {
            latestEntries = entries;
            tryEmit();
          },
          onError: controller.addError,
        );
        tbbSub = _dao.watchTbbForMonth(month, year).listen(
          (tbb) {
            latestTbb = tbb;
            tryEmit();
          },
          onError: controller.addError,
        );
      },
      onCancel: () {
        unawaited(entriesSub?.cancel());
        unawaited(tbbSub?.cancel());
      },
    );

    return controller.stream;
  }

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

  @override
  Future<void> allocate(
    String categoryId,
    int month,
    int year,
    int budgeted,
  ) => _dao.setBudgeted(categoryId, month, year, budgeted);

  @override
  Future<void> moveMoney(
    String fromCategoryId,
    String toCategoryId,
    int month,
    int year,
    int amount,
  ) => _dao.moveMoney(fromCategoryId, toCategoryId, month, year, amount);

  /// Recomputes `activity` and `available` from the live transaction sum.
  ///
  /// `activity = -sum(amounts)`: expenses have negative amounts, so flipping
  /// the sign makes activity positive for spending (e.g. -$30 spend →
  /// activity = 3000).
  ///
  /// `available = budgeted − activity` (no rollover in Phase 2).
  @override
  Future<void> recalculateAvailable(
    String categoryId,
    int month,
    int year,
  ) async {
    final sumAmounts = await _transactionsDao.sumAmountsForCategory(
      categoryId,
      month,
      year,
    );
    final activity = -sumAmounts;
    final entry = await _dao.getOrCreate(categoryId, month, year);
    final available = entry.budgeted - activity;
    await _dao.updateActivityAndAvailable(entry.id, activity, available);
  }
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
