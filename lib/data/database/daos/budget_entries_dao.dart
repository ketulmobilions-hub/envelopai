import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/tables.dart';
import 'package:uuid/uuid.dart';

part 'budget_entries_dao.g.dart';

@DriftAccessor(tables: [BudgetEntriesTable])
class BudgetEntriesDao extends DatabaseAccessor<AppDatabase>
    with _$BudgetEntriesDaoMixin {
  BudgetEntriesDao(super.attachedDatabase);

  static const _uuid = Uuid();

  Stream<List<BudgetEntryRow>> watchAll() =>
      (select(budgetEntriesTable)..orderBy([
            (t) => OrderingTerm.asc(t.year),
            (t) => OrderingTerm.asc(t.month),
          ]))
          .watch();

  Future<List<BudgetEntryRow>> getAll() =>
      (select(budgetEntriesTable)..orderBy([
            (t) => OrderingTerm.asc(t.year),
            (t) => OrderingTerm.asc(t.month),
          ]))
          .get();

  Future<BudgetEntryRow?> getById(String id) => (select(
    budgetEntriesTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Reactive stream of all budget entries for the given month and year.
  /// Ordered by `categoryId` for stable equality checks — display order is
  /// determined by `Category.sortOrder` in the widget layer.
  Stream<List<BudgetEntryRow>> watchForMonth(int month, int year) =>
      (select(budgetEntriesTable)
            ..where((t) => t.month.equals(month) & t.year.equals(year))
            ..orderBy([(t) => OrderingTerm.asc(t.categoryId)]))
          .watch();

  /// Returns the existing entry for [categoryId]/[month]/[year] or inserts
  /// a default one (budgeted: 0, activity: 0, available: 0).
  ///
  /// Wrapped in a transaction to avoid TOCTOU races.
  Future<BudgetEntryRow> getOrCreate(
    String categoryId,
    int month,
    int year,
  ) => transaction(() async {
    final existing =
        await (select(budgetEntriesTable)..where(
              (t) =>
                  t.categoryId.equals(categoryId) &
                  t.month.equals(month) &
                  t.year.equals(year),
            ))
            .getSingleOrNull();

    if (existing != null) return existing;

    return into(budgetEntriesTable).insertReturning(
      BudgetEntriesTableCompanion.insert(
        id: _uuid.v4(),
        categoryId: categoryId,
        month: month,
        year: year,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  });

  Future<void> upsert(BudgetEntriesTableCompanion companion) =>
      into(budgetEntriesTable).insertOnConflictUpdate(companion);

  /// Updates the `available` field in minor currency units.
  /// Called after every transaction mutation that affects this entry.
  /// Returns the number of rows updated (1 on success, 0 if id not found).
  Future<int> updateAvailable(String id, int available) =>
      (update(budgetEntriesTable)..where((t) => t.id.equals(id))).write(
        BudgetEntriesTableCompanion(available: Value(available)),
      );

  /// Updates `budgeted` and `available` in a single write.
  /// Called by `setBudgeted` inside a transaction.
  /// Returns the number of rows updated (1 on success, 0 if id not found).
  Future<int> updateBudgetedAndAvailable(
    String id,
    int budgeted,
    int available,
  ) => (update(budgetEntriesTable)..where((t) => t.id.equals(id))).write(
    BudgetEntriesTableCompanion(
      budgeted: Value(budgeted),
      available: Value(available),
    ),
  );

  /// Atomically sets [budgeted] for [categoryId]/[month]/[year], creating the
  /// entry if needed, then recalculates `available = budgeted − activity`.
  ///
  /// Wrapped in a transaction to prevent the TOCTOU race between the read of
  /// `activity` (inside [getOrCreate]) and the subsequent write.
  Future<void> setBudgeted(
    String categoryId,
    int month,
    int year,
    int budgeted,
  ) => transaction(() async {
    final entry = await getOrCreate(categoryId, month, year);
    final available = budgeted - entry.activity;
    await updateBudgetedAndAvailable(entry.id, budgeted, available);
  });

  /// Updates both `activity` and `available` in a single write.
  /// Called by `BudgetRepository.recalculateAvailable` after every transaction
  /// mutation.
  /// Returns the number of rows updated (1 on success, 0 if id not found).
  Future<int> updateActivityAndAvailable(
    String id,
    int activity,
    int available,
  ) => (update(budgetEntriesTable)..where((t) => t.id.equals(id))).write(
    BudgetEntriesTableCompanion(
      activity: Value(activity),
      available: Value(available),
    ),
  );

  Future<int> deleteById(String id) =>
      (delete(budgetEntriesTable)..where((t) => t.id.equals(id))).go();

  /// Reactive stream of the To-Be-Budgeted scalar for [month]/[year].
  ///
  /// TBB = sum(income transactions for month) − sum(budget_entries.budgeted
  /// for month). Re-emits whenever either the `transactions` or
  /// `budget_entries` table changes.
  ///
  /// The raw SQL table names `'transactions'` and `'budget_entries'` must stay
  /// in sync with [TransactionsTable.tableName] and
  /// [BudgetEntriesTable.tableName] if either is renamed.
  Stream<int> watchTbbForMonth(int month, int year) {
    final startMs = DateTime.utc(year, month).millisecondsSinceEpoch;
    final endMs = DateTime.utc(year, month + 1).millisecondsSinceEpoch;
    return attachedDatabase
        .customSelect(
          'SELECT '
          'COALESCE((SELECT SUM(amount) FROM transactions '
          "WHERE type = 'income' AND is_deleted = 0 "
          'AND date >= ? AND date < ?), 0) - '
          'COALESCE((SELECT SUM(budgeted) FROM budget_entries '
          'WHERE month = ? AND year = ?), 0) AS tbb',
          variables: [
            Variable<int>(startMs),
            Variable<int>(endMs),
            Variable<int>(month),
            Variable<int>(year),
          ],
          readsFrom: {
            attachedDatabase.budgetEntriesTable,
            attachedDatabase.transactionsTable,
          },
        )
        .watchSingle()
        .map((row) => row.read<int>('tbb'));
  }
}
