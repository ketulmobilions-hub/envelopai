import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/accounts_dao.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: IAccountsRepository)
class AccountsRepository implements IAccountsRepository {
  const AccountsRepository(this._dao);

  final AccountsDao _dao;

  @override
  Stream<List<Account>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  @override
  Future<List<Account>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<Account?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Future<void> addAccount(Account account) => save(account);

  @override
  Future<void> updateAccount(Account account) => save(account);

  @override
  Future<void> deleteAccount(String id) => deleteById(id);

  @override
  Future<void> save(Account account) => _dao.upsert(_toCompanion(account));

  @override
  Future<void> deleteById(String id) => _dao.deleteById(id);
}

Account _toModel(AccountRow row) => Account(
  id: row.id,
  name: row.name,
  type: AccountType.values.byName(row.type),
  balance: row.balance,
  clearedBalance: row.clearedBalance,
  currency: row.currency,
  onBudget: row.onBudget,
  lastReconciledAt: row.lastReconciledAt != null
      ? DateTime.fromMillisecondsSinceEpoch(row.lastReconciledAt!, isUtc: true)
      : null,
);

AccountsTableCompanion _toCompanion(Account a) => AccountsTableCompanion(
  id: Value(a.id),
  name: Value(a.name),
  type: Value(a.type.name),
  balance: Value(a.balance),
  clearedBalance: Value(a.clearedBalance),
  currency: Value(a.currency),
  onBudget: Value(a.onBudget),
  lastReconciledAt: Value(a.lastReconciledAt?.millisecondsSinceEpoch),
);
