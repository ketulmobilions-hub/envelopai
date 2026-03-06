import 'package:envelope/domain/models/models.dart';

abstract interface class ITransactionsRepository {
  Stream<List<Transaction>> watchAll();
  Future<List<Transaction>> getAll();
  Future<Transaction?> getById(String id);
  Stream<List<Transaction>> watchByAccount(String accountId);
  Future<void> save(Transaction transaction);

  /// Soft-deletes the transaction with [id].
  /// Returns the number of rows affected (0 if id was not found).
  Future<int> softDelete(String id, {required int updatedAtMs});
}
