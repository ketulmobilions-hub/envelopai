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

  /// Returns the other leg of a transfer pair (excludes the row with [excludeId]).
  ///
  /// Returns `null` when the partner has already been deleted or doesn't exist.
  Future<TransactionRow?> getTransferPartner(
    String transferPairId, {
    required String excludeId,
  }) =>
      (select(transactionsTable)
            ..where(
              (t) =>
                  t.transferPairId.equals(transferPairId) &
                  t.id.equals(excludeId).not() &
                  t.isDeleted.equals(false),
            ))
          .getSingleOrNull();

  /// Returns the sum of `amount` for all non-deleted transactions whose
  /// `categoryId` and date fall within [month]/[year].
  ///
  /// A positive result means net inflow; negative means net outflow (spending).
  /// Returns 0 when there are no matching rows.
  ///
  /// Note: `DateTime.utc(year, 13)` rolls over to Jan of the next year, so
  /// month = 12 is handled correctly.
  Future<int> sumAmountsForCategory(
    String categoryId,
    int month,
    int year,
  ) async {
    final startMs = DateTime.utc(year, month).millisecondsSinceEpoch;
    final endMs = DateTime.utc(year, month + 1).millisecondsSinceEpoch;
    final amountSum = transactionsTable.amount.sum();
    final result =
        await (selectOnly(transactionsTable)
              ..addColumns([amountSum])
              ..where(
                transactionsTable.categoryId.equals(categoryId) &
                    transactionsTable.isDeleted.equals(false) &
                    transactionsTable.date.isBiggerOrEqualValue(startMs) &
                    transactionsTable.date.isSmallerThanValue(endMs),
              ))
            .getSingleOrNull();
    return result?.read(amountSum) ?? 0;
  }
}
