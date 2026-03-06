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

  /// Reactive stream of all budget entries for the given month and year,
  /// used by BudgetBloc to rebuild the budget screen on any change.
  Stream<List<BudgetEntryRow>> watchForMonth(int month, int year) =>
      (select(budgetEntriesTable)..where(
            (t) => t.month.equals(month) & t.year.equals(year),
          ))
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
  Future<void> updateAvailable(String id, int available) =>
      (update(budgetEntriesTable)..where((t) => t.id.equals(id))).write(
        BudgetEntriesTableCompanion(available: Value(available)),
      );

  /// Updates both `activity` and `available` in a single write.
  /// Called by `BudgetRepository.recalculateAvailable` after every transaction
  /// mutation.
  Future<void> updateActivityAndAvailable(
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
}
