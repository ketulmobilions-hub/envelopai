// isNull is hidden from drift to avoid ambiguity with flutter_test's isNull.
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

AppDatabase _openInMemory() => AppDatabase.forTesting(NativeDatabase.memory());

const _uuid = Uuid();

void main() {
  late AppDatabase db;

  setUp(() => db = _openInMemory());
  tearDown(() => db.close());

  // ---------------------------------------------------------------------------
  // AccountsDao
  // ---------------------------------------------------------------------------
  group('AccountsDao', () {
    AccountsTableCompanion makeAccount({
      String? id,
      String name = 'Checking',
    }) => AccountsTableCompanion.insert(
      id: id ?? _uuid.v4(),
      name: name,
      type: 'checking',
      balance: 0,
      clearedBalance: 0,
    );

    test('upsert and getAll', () async {
      await db.accounts.upsert(makeAccount(name: 'Main'));
      final rows = await db.accounts.getAll();
      expect(rows.length, 1);
      expect(rows.first.name, 'Main');
    });

    test('getById returns null for unknown id', () async {
      final row = await db.accounts.getById('no-such-id');
      expect(row, isNull);
    });

    test('upsert updates existing row', () async {
      final id = _uuid.v4();
      await db.accounts.upsert(makeAccount(id: id, name: 'Old'));
      await db.accounts.upsert(makeAccount(id: id, name: 'New'));
      final row = await db.accounts.getById(id);
      expect(row?.name, 'New');
    });

    test('deleteById removes row', () async {
      final id = _uuid.v4();
      await db.accounts.upsert(makeAccount(id: id));
      await db.accounts.deleteById(id);
      expect(await db.accounts.getById(id), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CategoryGroupsDao
  // ---------------------------------------------------------------------------
  group('CategoryGroupsDao', () {
    CategoryGroupsTableCompanion makeGroup({
      String? id,
      String name = 'Bills',
    }) => CategoryGroupsTableCompanion.insert(id: id ?? _uuid.v4(), name: name);

    test('upsert and getAll ordered by sortOrder', () async {
      await db.categoryGroups.upsert(
        CategoryGroupsTableCompanion.insert(
          id: _uuid.v4(),
          name: 'B',
          sortOrder: const Value(1),
        ),
      );
      await db.categoryGroups.upsert(
        CategoryGroupsTableCompanion.insert(
          id: _uuid.v4(),
          name: 'A',
          sortOrder: const Value(0),
        ),
      );
      final rows = await db.categoryGroups.getAll();
      expect(rows.map((r) => r.name).toList(), ['A', 'B']);
    });

    test('deleteById removes row', () async {
      final id = _uuid.v4();
      await db.categoryGroups.upsert(makeGroup(id: id));
      await db.categoryGroups.deleteById(id);
      expect(await db.categoryGroups.getById(id), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // CategoriesDao
  // ---------------------------------------------------------------------------
  group('CategoriesDao', () {
    Future<String> insertGroup() async {
      final id = _uuid.v4();
      await db.categoryGroups.upsert(
        CategoryGroupsTableCompanion.insert(id: id, name: 'Group'),
      );
      return id;
    }

    test('upsert and getById', () async {
      final groupId = await insertGroup();
      final catId = _uuid.v4();
      await db.categories.upsert(
        CategoriesTableCompanion.insert(
          id: catId,
          groupId: groupId,
          name: 'Rent',
        ),
      );
      final row = await db.categories.getById(catId);
      expect(row?.name, 'Rent');
    });

    test('watchByGroup emits categories for that group only', () async {
      final g1 = await insertGroup();
      final g2 = await insertGroup();
      await db.categories.upsert(
        CategoriesTableCompanion.insert(
          id: _uuid.v4(),
          groupId: g1,
          name: 'In G1',
        ),
      );
      await db.categories.upsert(
        CategoriesTableCompanion.insert(
          id: _uuid.v4(),
          groupId: g2,
          name: 'In G2',
        ),
      );
      final rows = await db.categories.watchByGroup(g1).first;
      expect(rows.length, 1);
      expect(rows.first.name, 'In G1');
    });
  });

  // ---------------------------------------------------------------------------
  // BudgetEntriesDao
  // ---------------------------------------------------------------------------
  group('BudgetEntriesDao', () {
    late String groupId;
    late String categoryId;

    setUp(() async {
      groupId = _uuid.v4();
      categoryId = _uuid.v4();
      await db.categoryGroups.upsert(
        CategoryGroupsTableCompanion.insert(id: groupId, name: 'G'),
      );
      await db.categories.upsert(
        CategoriesTableCompanion.insert(
          id: categoryId,
          groupId: groupId,
          name: 'Cat',
        ),
      );
    });

    test('getOrCreate inserts default entry', () async {
      final entry = await db.budgetEntries.getOrCreate(categoryId, 3, 2026);
      expect(entry.budgeted, 0);
      expect(entry.activity, 0);
      expect(entry.available, 0);
    });

    test('getOrCreate returns existing entry on second call', () async {
      final first = await db.budgetEntries.getOrCreate(categoryId, 3, 2026);
      final second = await db.budgetEntries.getOrCreate(categoryId, 3, 2026);
      expect(first.id, second.id);
    });

    test('updateAvailable persists new value', () async {
      final entry = await db.budgetEntries.getOrCreate(categoryId, 3, 2026);
      await db.budgetEntries.updateAvailable(entry.id, 50000);
      final updated = await db.budgetEntries.getById(entry.id);
      expect(updated?.available, 50000);
    });

    test('watchForMonth emits only entries for the given month', () async {
      await db.budgetEntries.getOrCreate(categoryId, 3, 2026);
      await db.budgetEntries.getOrCreate(categoryId, 4, 2026);
      final rows = await db.budgetEntries.watchForMonth(3, 2026).first;
      expect(rows.length, 1);
      expect(rows.first.month, 3);
      expect(rows.first.year, 2026);
    });
  });

  // ---------------------------------------------------------------------------
  // TransactionsDao
  // ---------------------------------------------------------------------------
  group('TransactionsDao', () {
    late String accountId;

    setUp(() async {
      accountId = _uuid.v4();
      await db.accounts.upsert(
        AccountsTableCompanion.insert(
          id: accountId,
          name: 'Checking',
          type: 'checking',
          balance: 0,
          clearedBalance: 0,
        ),
      );
    });

    TransactionsTableCompanion makeTxn({
      String? id,
      int amount = -1000,
      bool isDeleted = false,
    }) => TransactionsTableCompanion.insert(
      id: id ?? _uuid.v4(),
      accountId: accountId,
      payee: 'Store',
      amount: amount,
      date: DateTime.utc(2026, 3, 6).millisecondsSinceEpoch,
      type: 'expense',
      updatedAt: DateTime.utc(2026, 3, 6).millisecondsSinceEpoch,
      isDeleted: Value(isDeleted),
    );

    test('upsert and getAll excludes soft-deleted', () async {
      await db.transactions.upsert(makeTxn());
      await db.transactions.upsert(makeTxn(isDeleted: true));
      final rows = await db.transactions.getAll();
      expect(rows.length, 1);
    });

    test('softDelete sets isDeleted flag', () async {
      final id = _uuid.v4();
      await db.transactions.upsert(makeTxn(id: id));
      await db.transactions.softDelete(
        id,
        updatedAtMs: DateTime.utc(2026, 3, 7).millisecondsSinceEpoch,
      );
      final row = await db.transactions.getById(id);
      expect(row?.isDeleted, isTrue);
    });

    test('watchByAccount excludes soft-deleted', () async {
      await db.transactions.upsert(makeTxn());
      await db.transactions.upsert(makeTxn(isDeleted: true));
      final rows = await db.transactions.watchByAccount(accountId).first;
      expect(rows.length, 1);
    });
  });
}
