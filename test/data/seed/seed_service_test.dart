import 'package:drift/native.dart';
import 'package:envelope/data/database/app_database.dart';
import 'package:envelope/data/repositories/accounts_repository.dart';
import 'package:envelope/data/repositories/budget_repository.dart';
import 'package:envelope/data/repositories/categories_repository.dart';
import 'package:envelope/data/repositories/category_groups_repository.dart';
import 'package:envelope/data/repositories/transactions_repository.dart';
import 'package:envelope/data/seed/seed_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppDatabase _openInMemory() => AppDatabase.forTesting(NativeDatabase.memory());

/// Total categories defined across all 5 default groups: 5+5+3+2+3 = 18.
const _expectedCategoryCount = 18;

/// Number of default category groups.
const _expectedGroupCount = 5;

void main() {
  late AppDatabase db;
  late SeedService seedService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    db = _openInMemory();
    final budget = BudgetRepository(db.budgetEntries, db.transactions);
    final accounts = AccountsRepository(db.accounts);
    final categoryGroups = CategoryGroupsRepository(db.categoryGroups);
    final categories = CategoriesRepository(db.categories);
    // TransactionsRepository is constructed to satisfy the BudgetRepository
    // dependency; it is not exercised by the seed but its constructor is
    // required for BudgetRepository.
    final _ = TransactionsRepository(db.transactions, budget, accounts);

    seedService = SeedService(prefs, accounts, categoryGroups, categories);
  });

  tearDown(() => db.close());

  group('SeedService', () {
    test(
      'inserts default account, groups and categories on first call',
      () async {
        await seedService.seedIfNeeded();

        final accounts = await db.accounts.getAll();
        final groups = await db.categoryGroups.getAll();
        final cats = await db.categories.getAll();

        expect(accounts.length, 1);
        expect(accounts.first.name, 'My Checking Account');
        expect(accounts.first.type, 'checking');

        expect(groups.length, _expectedGroupCount);
        expect(cats.length, _expectedCategoryCount);
      },
    );

    test('Income group is marked hidden', () async {
      await seedService.seedIfNeeded();

      final groups = await db.categoryGroups.getAll();
      final incomeGroup = groups.firstWhere((g) => g.name == 'Income');
      expect(incomeGroup.isHidden, isTrue);
    });

    test('groups are inserted in the defined sort order', () async {
      await seedService.seedIfNeeded();

      final groups = await db.categoryGroups.getAll();
      expect(groups[0].name, 'Fixed Bills');
      expect(groups[1].name, 'Everyday Expenses');
      expect(groups[2].name, 'Savings Goals');
      expect(groups[3].name, 'Debt Payments');
      expect(groups[4].name, 'Income');
    });

    test(
      'seedIfNeeded is idempotent — second call inserts no extra data',
      () async {
        await seedService.seedIfNeeded();
        await seedService.seedIfNeeded();

        final accounts = await db.accounts.getAll();
        final groups = await db.categoryGroups.getAll();
        final cats = await db.categories.getAll();

        expect(accounts.length, 1);
        expect(groups.length, _expectedGroupCount);
        expect(cats.length, _expectedCategoryCount);
      },
    );
  });
}
