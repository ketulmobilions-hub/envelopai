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
  /// Wrapped in a transaction to avoid TOCTOU races. Callers that already
  /// supply an outer transaction should use [_getOrCreateInTx] instead to
  /// avoid unnecessary savepoints.
  Future<BudgetEntryRow> getOrCreate(
    String categoryId,
    int month,
    int year,
  ) => transaction(() => _getOrCreateInTx(categoryId, month, year));

  /// Core get-or-create logic with no transaction wrapper.
  /// Must only be called from within an existing transaction.
  Future<BudgetEntryRow> _getOrCreateInTx(
    String categoryId,
    int month,
    int year,
  ) async {
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
  }

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
    final entry = await _getOrCreateInTx(categoryId, month, year);
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

  /// Atomically transfers [amount] of budget from [fromCategoryId] to
  /// [toCategoryId] for the given [month]/[year].
  ///
  /// Both entries are created if they do not exist yet. `available` is
  /// recalculated for each entry as `budgeted − activity`.
  ///
  /// If the source entry carries rollover debt (`budgeted < 0`), the move
  /// will decrement `budgeted` further below zero. This is intentional —
  /// the user is deepening their rollover debt, consistent with the
  /// convention established by [rolloverMonth].
  Future<void> moveMoney(
    String fromCategoryId,
    String toCategoryId,
    int month,
    int year,
    int amount,
  ) => transaction(() async {
    final from = await _getOrCreateInTx(fromCategoryId, month, year);
    final to = await _getOrCreateInTx(toCategoryId, month, year);
    // Cap against `available` (not `budgeted`) so that post-rollover entries
    // with negative `budgeted` do not block all moves.
    if (amount > from.available) {
      throw Exception(
        'Cannot move \$$amount — only \$${from.available} available in '
        'category $fromCategoryId.',
      );
    }
    final newFromBudgeted = from.budgeted - amount;
    final newToBudgeted = to.budgeted + amount;
    await updateBudgetedAndAvailable(
      from.id,
      newFromBudgeted,
      newFromBudgeted - from.activity,
    );
    await updateBudgetedAndAvailable(
      to.id,
      newToBudgeted,
      newToBudgeted - to.activity,
    );
  });

  /// Applies negative-available rollover from [fromMonth]/[fromYear] to the
  /// following month.
  ///
  /// For each category whose `available < 0`, the absolute shortfall is
  /// subtracted from `budgeted` in the next month entry (creating the entry if
  /// it does not exist yet), and `available` is recalculated as
  /// `budgeted − activity`. Categories with non-negative available are
  /// unaffected.
  ///
  /// **Negative `budgeted` is intentional** — it represents carried rollover
  /// debt. A category that was overspent by $10 last month will have
  /// `budgeted = -1000` in the next month until the user manually allocates
  /// funds to cover it.
  ///
  /// All reads and writes run inside a single transaction. Callers must ensure
  /// this is invoked at most once per month transition (e.g. via a
  /// `SharedPreferences` guard in the Bloc layer) because there is no
  /// idempotency marker on the entries themselves.
  Future<void> rolloverMonth(int fromMonth, int fromYear) =>
      transaction(() async {
        final toMonth = fromMonth == 12 ? 1 : fromMonth + 1;
        final toYear = fromMonth == 12 ? fromYear + 1 : fromYear;

        final overspent = await (select(budgetEntriesTable)
              ..where(
                (t) =>
                    t.month.equals(fromMonth) &
                    t.year.equals(fromYear) &
                    t.available.isSmallerThanValue(0),
              ))
            .get();

        for (final entry in overspent) {
          // available is negative — deduction is the positive shortfall.
          final deduction = -entry.available;
          final next =
              await _getOrCreateInTx(entry.categoryId, toMonth, toYear);
          final newBudgeted = next.budgeted - deduction;
          await updateBudgetedAndAvailable(
            next.id,
            newBudgeted,
            newBudgeted - next.activity,
          );
        }
      });

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
