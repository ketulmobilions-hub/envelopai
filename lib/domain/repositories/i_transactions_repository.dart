import 'package:envelope/domain/models/models.dart';

abstract interface class ITransactionsRepository {
  Stream<List<Transaction>> watchAll();
  Future<List<Transaction>> getAll();
  Future<Transaction?> getById(String id);
  Stream<List<Transaction>> watchByAccount(String accountId);

  /// Inserts a new transaction and recalculates the affected budget entry.
  Future<void> addTransaction(Transaction transaction);

  /// Creates a pair of linked transfer transactions (source outflow + dest
  /// inflow). Neither transaction has a [categoryId].
  ///
  /// [amount] must be positive (in minor currency units, e.g. cents).
  /// [fromAccountName] / [toAccountName] are stored as the payee on each leg
  /// so the UI can render "Transfer to/from [Account]" without extra lookups.
  Future<void> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required String fromAccountName,
    required String toAccountName,
    required int amount,
    required DateTime date,
    String? memo,
    bool cleared = false,
  });

  /// Updates an existing transaction and recalculates all affected budget
  /// entries (handles category / month changes).
  Future<void> updateTransaction(Transaction transaction);

  /// Soft-deletes a transaction and recalculates the affected budget entry.
  Future<void> deleteTransaction(String id, {required int updatedAtMs});

  // Low-level primitives kept for sync layer use.
  Future<void> save(Transaction transaction);

  /// Soft-deletes the transaction with [id].
  /// Returns the number of rows affected (0 if id was not found).
  Future<int> softDelete(String id, {required int updatedAtMs});
}
