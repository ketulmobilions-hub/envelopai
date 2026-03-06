import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/tables.dart';

part 'accounts_dao.g.dart';

@DriftAccessor(tables: [AccountsTable])
class AccountsDao extends DatabaseAccessor<AppDatabase>
    with _$AccountsDaoMixin {
  AccountsDao(super.attachedDatabase);

  Stream<List<AccountRow>> watchAll() => select(accountsTable).watch();

  Future<List<AccountRow>> getAll() => select(accountsTable).get();

  Future<AccountRow?> getById(String id) =>
      (select(accountsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsert(AccountsTableCompanion companion) =>
      into(accountsTable).insertOnConflictUpdate(companion);

  /// Hard delete — accounts are not synced with soft-delete in Phase 2.
  Future<int> deleteById(String id) =>
      (delete(accountsTable)..where((t) => t.id.equals(id))).go();
}
