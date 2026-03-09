import 'package:drift/native.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/repositories/accounts_repository.dart';
import 'package:envelope/data/repositories/budget_repository.dart';
import 'package:envelope/data/repositories/transactions_repository.dart';
import 'package:envelope/domain/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

AppDatabase _openInMemory() => AppDatabase.forTesting(NativeDatabase.memory());

void main() {
  late AppDatabase db;
  late AccountsRepository accounts;
  late BudgetRepository budget;
  late TransactionsRepository transactions;

  setUp(() {
    db = _openInMemory();
    budget = BudgetRepository(db.budgetEntries, db.transactions);
    accounts = AccountsRepository(db.accounts);
    transactions = TransactionsRepository(db.transactions, budget, accounts);
  });

  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // Helper builders
  // ---------------------------------------------------------------------------

  Account makeAccount({String? id}) => Account(
    id: id ?? _uuid.v4(),
    name: 'Checking',
    type: AccountType.checking,
    balance: 0,
    clearedBalance: 0,
    currency: 'USD',
    onBudget: true,
  );

  Future<String> insertCategory(String groupId) async {
    final catId = _uuid.v4();
    await db.categories.upsert(
      CategoriesTableCompanion.insert(
        id: catId,
        groupId: groupId,
        name: 'Groceries',
      ),
    );
    return catId;
  }

  Future<String> insertGroup() async {
    final groupId = _uuid.v4();
    await db.categoryGroups.upsert(
      CategoryGroupsTableCompanion.insert(id: groupId, name: 'Everyday'),
    );
    return groupId;
  }

  Transaction makeTxn({
    required String accountId,
    required String categoryId,
    int amount = -3000,
    String? id,
    DateTime? date,
  }) {
    final txnDate = date ?? DateTime.utc(2026, 3, 15);
    return Transaction(
      id: id ?? _uuid.v4(),
      accountId: accountId,
      categoryId: categoryId,
      payee: 'Store',
      amount: amount,
      date: txnDate,
      cleared: false,
      type: TransactionType.expense,
      updatedAt: txnDate,
      isDeleted: false,
    );
  }

  // ---------------------------------------------------------------------------
  // AccountsRepository CRUD
  // ---------------------------------------------------------------------------

  group('AccountsRepository CRUD', () {
    test('addAccount stores and retrieves the account', () async {
      final account = makeAccount();
      await accounts.addAccount(account);

      final found = await accounts.getById(account.id);
      expect(found?.name, 'Checking');
    });

    test('updateAccount overwrites existing account', () async {
      final account = makeAccount();
      await accounts.addAccount(account);

      await accounts.updateAccount(account.copyWith(name: 'Updated'));
      final found = await accounts.getById(account.id);
      expect(found?.name, 'Updated');
    });

    test('deleteAccount removes the account', () async {
      final account = makeAccount();
      await accounts.addAccount(account);

      await accounts.deleteAccount(account.id);
      expect(await accounts.getById(account.id), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // TransactionsRepository CRUD + budget recalculation
  // ---------------------------------------------------------------------------

  group('TransactionsRepository CRUD + recalculation', () {
    late String accountId;
    late String categoryId;

    setUp(() async {
      final account = makeAccount();
      accountId = account.id;
      await accounts.addAccount(account);
      final groupId = await insertGroup();
      categoryId = await insertCategory(groupId);
    });

    test('addTransaction decreases available in budget entry', () async {
      // Assign $50 budget (5000 cents) via repository to get a full companion.
      final entry = await budget.getOrCreate(categoryId, 3, 2026);
      await budget.save(entry.copyWith(budgeted: 5000));

      // Spend $30 (amount = -3000)
      await transactions.addTransaction(
        makeTxn(accountId: accountId, categoryId: categoryId),
      );

      final updated = await budget.getById(entry.id);
      expect(updated?.activity, 3000); // -(-3000) = 3000
      expect(updated?.available, 2000); // 5000 - 3000 = 2000
    });

    test('addTransaction with no category does not touch budget', () async {
      final transfer = Transaction(
        id: _uuid.v4(),
        accountId: accountId,
        payee: 'Transfer',
        amount: 10000,
        date: DateTime.utc(2026, 3),
        cleared: false,
        type: TransactionType.transfer,
        transferPairId: _uuid.v4(),
        updatedAt: DateTime.utc(2026, 3),
        isDeleted: false,
      );
      await transactions.addTransaction(transfer);

      // No budget entry should exist for March 2026 with no category seed
      final entries = await db.budgetEntries.getAll();
      expect(entries, isEmpty);
    });

    test('updateTransaction recalculates after amount change', () async {
      final txnId = _uuid.v4();
      final txn = makeTxn(
        id: txnId,
        accountId: accountId,
        categoryId: categoryId,
      );
      await transactions.addTransaction(txn);

      // Change amount from -3000 to -5000
      await transactions.updateTransaction(txn.copyWith(amount: -5000));

      final entry = await budget.getOrCreate(categoryId, 3, 2026);
      expect(entry.activity, 5000);
      expect(entry.available, -5000); // budgeted=0, available = 0 - 5000
    });

    test(
      'updateTransaction recalculates old slot when category changes',
      () async {
        final groupId = await insertGroup();
        final cat2Id = await insertCategory(groupId);

        // Seed budgets
        await budget.getOrCreate(categoryId, 3, 2026);
        await budget.getOrCreate(cat2Id, 3, 2026);

        final txnId = _uuid.v4();
        final txn = makeTxn(
          id: txnId,
          accountId: accountId,
          categoryId: categoryId,
          amount: -2000,
        );
        await transactions.addTransaction(txn);

        // Reassign to cat2
        await transactions.updateTransaction(
          txn.copyWith(categoryId: cat2Id),
        );

        final oldEntry = await budget.getOrCreate(categoryId, 3, 2026);
        final newEntry = await budget.getOrCreate(cat2Id, 3, 2026);

        expect(oldEntry.activity, 0); // no longer has any transactions
        expect(newEntry.activity, 2000); // now has the transaction
      },
    );

    test('deleteTransaction restores available', () async {
      final txn = makeTxn(
        accountId: accountId,
        categoryId: categoryId,
        amount: -4000,
      );
      await transactions.addTransaction(txn);

      final beforeDelete = await budget.getOrCreate(categoryId, 3, 2026);
      expect(beforeDelete.activity, 4000);

      await transactions.deleteTransaction(
        txn.id,
        updatedAtMs: DateTime.utc(2026, 3, 16).millisecondsSinceEpoch,
      );

      final afterDelete = await budget.getOrCreate(categoryId, 3, 2026);
      expect(afterDelete.activity, 0);
      expect(afterDelete.available, 0); // budgeted=0, activity=0
    });
  });
}
