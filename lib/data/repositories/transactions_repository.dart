import 'package:drift/drift.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/database/daos/transactions_dao.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:envelope/domain/repositories/repositories.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

@LazySingleton(as: ITransactionsRepository)
class TransactionsRepository implements ITransactionsRepository {
  TransactionsRepository(this._dao, this._budgetRepo);

  static final _uuid = Uuid();

  final TransactionsDao _dao;
  final IBudgetRepository _budgetRepo;

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
  Future<void> addTransaction(Transaction transaction) async {
    await _dao.upsert(_toCompanion(transaction));
    if (transaction.categoryId != null) {
      await _budgetRepo.recalculateAvailable(
        transaction.categoryId!,
        transaction.date.month,
        transaction.date.year,
      );
    }
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    // Capture old state before overwriting so we can recalculate the old
    // budget slot if the category or month/year changed.
    final oldRow = await _dao.getById(transaction.id);

    await _dao.upsert(_toCompanion(transaction));

    // Recalculate new slot.
    if (transaction.categoryId != null) {
      await _budgetRepo.recalculateAvailable(
        transaction.categoryId!,
        transaction.date.month,
        transaction.date.year,
      );
    }

    // Recalculate old slot if it differs from the new one.
    if (oldRow != null && oldRow.categoryId != null) {
      final oldDate = DateTime.fromMillisecondsSinceEpoch(
        oldRow.date,
        isUtc: true,
      );
      final slotChanged =
          oldRow.categoryId != transaction.categoryId ||
          oldDate.month != transaction.date.month ||
          oldDate.year != transaction.date.year;
      if (slotChanged) {
        await _budgetRepo.recalculateAvailable(
          oldRow.categoryId!,
          oldDate.month,
          oldDate.year,
        );
      }
    }
  }

  @override
  Future<void> addTransfer({
    required String fromAccountId,
    required String toAccountId,
    required String fromAccountName,
    required String toAccountName,
    required int amount,
    required DateTime date,
    String? memo,
    bool cleared = false,
  }) async {
    final pairId = _uuid.v4();
    final now = DateTime.now().toUtc();

    final sourceTx = Transaction(
      id: _uuid.v4(),
      accountId: fromAccountId,
      payee: toAccountName,
      amount: -amount,
      date: date,
      memo: memo,
      cleared: cleared,
      type: TransactionType.transfer,
      transferPairId: pairId,
      updatedAt: now,
      isDeleted: false,
    );
    final destTx = Transaction(
      id: _uuid.v4(),
      accountId: toAccountId,
      payee: fromAccountName,
      amount: amount,
      date: date,
      memo: memo,
      cleared: cleared,
      type: TransactionType.transfer,
      transferPairId: pairId,
      updatedAt: now,
      isDeleted: false,
    );

    // Wrap both writes in a DB transaction to ensure atomicity — a crash
    // between the two upserts must not leave a half-formed transfer pair.
    await _dao.attachedDatabase.transaction(() async {
      await _dao.upsert(_toCompanion(sourceTx));
      await _dao.upsert(_toCompanion(destTx));
    });
  }

  @override
  Future<void> deleteTransaction(
    String id, {
    required int updatedAtMs,
  }) async {
    // Fetch before soft-deleting so we know which budget entry to recalculate.
    final row = await _dao.getById(id);

    // Wrap the soft-delete(s) in a transaction so both legs of a transfer are
    // always deleted together — a crash between the two writes must not leave
    // a ghost row with a dangling transferPairId.
    await _dao.attachedDatabase.transaction(() async {
      await _dao.softDelete(id, updatedAtMs: updatedAtMs);

      // Symmetrically soft-delete the transfer partner when applicable.
      if (row?.transferPairId != null) {
        final partner = await _dao.getTransferPartner(
          row!.transferPairId!,
          excludeId: id,
        );
        if (partner != null) {
          await _dao.softDelete(partner.id, updatedAtMs: updatedAtMs);
        }
      }
    });

    if (row != null && row.categoryId != null) {
      final date = DateTime.fromMillisecondsSinceEpoch(row.date, isUtc: true);
      await _budgetRepo.recalculateAvailable(
        row.categoryId!,
        date.month,
        date.year,
      );
    }
  }

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
