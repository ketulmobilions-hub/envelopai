// isNotNull/isNull are hidden from drift to avoid ambiguity with flutter_test.
import 'package:drift/drift.dart' hide isNotNull, isNull;
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

    group('rolloverMonth', () {
      late String categoryId2;

      setUp(() async {
        categoryId2 = _uuid.v4();
        await db.categories.upsert(
          CategoriesTableCompanion.insert(
            id: categoryId2,
            groupId: groupId,
            name: 'Cat2',
          ),
        );
      });

      test('deducts overspent available from next month budgeted', () async {
        // Feb 2026: budgeted=1000, activity=2000, available=-1000.
        await db.budgetEntries.upsert(
          BudgetEntriesTableCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            month: 2,
            year: 2026,
            budgeted: const Value(1000),
            activity: const Value(2000),
            available: const Value(-1000),
          ),
        );

        await db.budgetEntries.rolloverMonth(2, 2026);

        final march = await db.budgetEntries.getOrCreate(categoryId, 3, 2026);
        // 0 (default budgeted) - 1000 (shortfall) = -1000.
        expect(march.budgeted, -1000);
        expect(march.available, -1000);
      });

      test('non-overspent categories are unaffected', () async {
        // Cat1 (positive available): should NOT have a March entry created.
        await db.budgetEntries.upsert(
          BudgetEntriesTableCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            month: 2,
            year: 2026,
            budgeted: const Value(5000),
            activity: const Value(2000),
            available: const Value(3000),
          ),
        );
        // Cat2 (overspent): should have March budgeted reduced.
        await db.budgetEntries.upsert(
          BudgetEntriesTableCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId2,
            month: 2,
            year: 2026,
            budgeted: const Value(1000),
            activity: const Value(1500),
            available: const Value(-500),
          ),
        );

        await db.budgetEntries.rolloverMonth(2, 2026);

        // Cat1 March must NOT have been created by rollover.
        final cat1March = await (db.select(db.budgetEntriesTable)
              ..where(
                (t) =>
                    t.categoryId.equals(categoryId) &
                    t.month.equals(3) &
                    t.year.equals(2026),
              ))
            .getSingleOrNull();
        expect(cat1March, isNull);

        // Cat2 March: budgeted reduced by 500.
        final cat2March = await db.budgetEntries.getOrCreate(
          categoryId2,
          3,
          2026,
        );
        expect(cat2March.budgeted, -500);
        expect(cat2March.available, -500);
      });

      test('creates next month entry if it does not exist yet', () async {
        await db.budgetEntries.upsert(
          BudgetEntriesTableCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            month: 2,
            year: 2026,
            budgeted: const Value(500),
            activity: const Value(800),
            available: const Value(-300),
          ),
        );

        await db.budgetEntries.rolloverMonth(2, 2026);

        final march = await (db.select(db.budgetEntriesTable)
              ..where(
                (t) =>
                    t.categoryId.equals(categoryId) &
                    t.month.equals(3) &
                    t.year.equals(2026),
              ))
            .getSingleOrNull();
        expect(march, isNotNull);
        expect(march!.budgeted, -300);
      });

      test('wraps December → January across year boundary', () async {
        await db.budgetEntries.upsert(
          BudgetEntriesTableCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            month: 12,
            year: 2025,
            budgeted: const Value(500),
            activity: const Value(700),
            available: const Value(-200),
          ),
        );

        await db.budgetEntries.rolloverMonth(12, 2025);

        final jan2026 = await (db.select(db.budgetEntriesTable)
              ..where(
                (t) =>
                    t.categoryId.equals(categoryId) &
                    t.month.equals(1) &
                    t.year.equals(2026),
              ))
            .getSingleOrNull();
        expect(jan2026, isNotNull);
        expect(jan2026!.budgeted, -200);
      });

      test('is a no-op when no overspent categories exist', () async {
        // No entries at all for Feb 2026.
        await db.budgetEntries.rolloverMonth(2, 2026);

        final march = await db.budgetEntries.watchForMonth(3, 2026).first;
        expect(march, isEmpty);
      });

      test('reduces existing next-month budgeted rather than overwriting',
          () async {
        // Cat already has $50 budgeted in March.
        await db.budgetEntries.upsert(
          BudgetEntriesTableCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            month: 3,
            year: 2026,
            budgeted: const Value(5000),
            activity: const Value(0),
            available: const Value(5000),
          ),
        );
        // Feb overspent by $10.
        await db.budgetEntries.upsert(
          BudgetEntriesTableCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            month: 2,
            year: 2026,
            budgeted: const Value(1000),
            activity: const Value(2000),
            available: const Value(-1000),
          ),
        );

        await db.budgetEntries.rolloverMonth(2, 2026);

        final march = await db.budgetEntries.getOrCreate(categoryId, 3, 2026);
        // 5000 - 1000 = 4000.
        expect(march.budgeted, 4000);
        expect(march.available, 4000);
      });
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
