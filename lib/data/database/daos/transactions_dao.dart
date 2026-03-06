import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/tables.dart';

part 'transactions_dao.g.dart';

@DriftAccessor(tables: [TransactionsTable])
class TransactionsDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionsDaoMixin {
  TransactionsDao(super.attachedDatabase);

  /// Excludes soft-deleted transactions.
  Stream<List<TransactionRow>> watchAll() =>
      (select(transactionsTable)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  /// Excludes soft-deleted transactions.
  Future<List<TransactionRow>> getAll() =>
      (select(transactionsTable)
            ..where((t) => t.isDeleted.equals(false))
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();

  /// Returns the row regardless of `isDeleted` — needed by the sync layer.
  Future<TransactionRow?> getById(String id) => (select(
    transactionsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<TransactionRow>> watchByAccount(String accountId) =>
      (select(transactionsTable)
            ..where(
              (t) => t.accountId.equals(accountId) & t.isDeleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .watch();

  Future<void> upsert(TransactionsTableCompanion companion) =>
      into(transactionsTable).insertOnConflictUpdate(companion);

  /// Soft delete — sets `isDeleted = true` and updates `updatedAt` for sync.
  /// Returns the number of rows affected (0 if the id was not found).
  Future<int> softDelete(String id, {required int updatedAtMs}) =>
      (update(transactionsTable)..where((t) => t.id.equals(id))).write(
        TransactionsTableCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(updatedAtMs),
        ),
      );
}
