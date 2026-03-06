import 'package:envelope/domain/models/models.dart';

abstract interface class IAccountsRepository {
  Stream<List<Account>> watchAll();
  Future<List<Account>> getAll();
  Future<Account?> getById(String id);

  /// Inserts a new account. `account.id` must be a UUID set by the caller.
  Future<void> addAccount(Account account);

  /// Updates an existing account by id (upsert semantics).
  Future<void> updateAccount(Account account);

  /// Hard-deletes the account with [id].
  Future<void> deleteAccount(String id);

  // Low-level primitives kept for sync layer use.
  Future<void> save(Account account);
  Future<void> deleteById(String id);
}
