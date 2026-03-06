import 'package:envelope/domain/models/models.dart';

abstract interface class ITransactionsRepository {
  Stream<List<Transaction>> watchAll();
  Future<List<Transaction>> getAll();
  Future<Transaction?> getById(String id);
  Stream<List<Transaction>> watchByAccount(String accountId);

  /// Inserts a new transaction and recalculates the affected budget entry.
  Future<void> addTransaction(Transaction transaction);

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
