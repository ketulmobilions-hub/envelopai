import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/transactions_dao.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ITransactionsRepository)
class TransactionsRepository implements ITransactionsRepository {
  const TransactionsRepository(this._dao);

  final TransactionsDao _dao;

  @override
  Stream<List<Transaction>> watchAll() =>
      _dao.watchAll().map((rows) => rows.map(_toModel).toList());

  @override
  Future<List<Transaction>> getAll() async {
    final rows = await _dao.getAll();
    return rows.map(_toModel).toList();
  }

  @override
  Future<Transaction?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _toModel(row);
  }

  @override
  Stream<List<Transaction>> watchByAccount(String accountId) =>
      _dao.watchByAccount(accountId).map((rows) => rows.map(_toModel).toList());

  @override
  Future<void> save(Transaction transaction) =>
      _dao.upsert(_toCompanion(transaction));

  @override
  Future<int> softDelete(String id, {required int updatedAtMs}) =>
      _dao.softDelete(id, updatedAtMs: updatedAtMs);
}

Transaction _toModel(TransactionRow row) => Transaction(
  id: row.id,
  accountId: row.accountId,
  categoryId: row.categoryId,
  payee: row.payee,
  amount: row.amount,
  date: DateTime.fromMillisecondsSinceEpoch(row.date, isUtc: true),
  memo: row.memo,
  cleared: row.cleared,
  type: TransactionType.values.byName(row.type),
  transferPairId: row.transferPairId,
  updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt, isUtc: true),
  isDeleted: row.isDeleted,
);

TransactionsTableCompanion _toCompanion(Transaction t) =>
    TransactionsTableCompanion(
      id: Value(t.id),
      accountId: Value(t.accountId),
      categoryId: Value(t.categoryId),
      payee: Value(t.payee),
      amount: Value(t.amount),
      date: Value(t.date.millisecondsSinceEpoch),
      memo: Value(t.memo),
      cleared: Value(t.cleared),
      type: Value(t.type.name),
      transferPairId: Value(t.transferPairId),
      updatedAt: Value(t.updatedAt.millisecondsSinceEpoch),
      isDeleted: Value(t.isDeleted),
    );
