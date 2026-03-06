import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:envelope/data/database/daos/accounts_dao.dart';
import 'package:envelope/data/database/daos/budget_entries_dao.dart';
import 'package:envelope/data/database/daos/categories_dao.dart';
import 'package:envelope/data/database/daos/category_groups_dao.dart';
import 'package:envelope/data/database/daos/transactions_dao.dart';
import 'package:envelope/data/database/tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AccountsTable,
    CategoryGroupsTable,
    CategoriesTable,
    BudgetEntriesTable,
    TransactionsTable,
    GoalsTable,
  ],
  daos: [
    AccountsDao,
    CategoryGroupsDao,
    CategoriesDao,
    BudgetEntriesDao,
    TransactionsDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For use in tests only — pass a [NativeDatabase.memory()] executor.
  AppDatabase.forTesting(super.e);

  late final AccountsDao accounts = AccountsDao(this);
  late final CategoryGroupsDao categoryGroups = CategoryGroupsDao(this);
  late final CategoriesDao categories = CategoriesDao(this);
  late final BudgetEntriesDao budgetEntries = BudgetEntriesDao(this);
  late final TransactionsDao transactions = TransactionsDao(this);

  /// Increment this whenever the schema changes and add a migration step in
  /// [migration] below.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      // Indexes for high-frequency query patterns.
      await customStatement(
        'CREATE INDEX idx_transactions_account_date '
        'ON transactions (account_id, date)',
      );
      await customStatement(
        'CREATE INDEX idx_transactions_category '
        'ON transactions (category_id)',
      );
      await customStatement(
        'CREATE INDEX idx_budget_entries_category '
        'ON budget_entries (category_id)',
      );
      await customStatement(
        'CREATE INDEX idx_categories_group '
        'ON categories (group_id)',
      );
      await customStatement(
        'CREATE INDEX idx_goals_category '
        'ON goals (category_id)',
      );
      await customStatement(
        'CREATE INDEX idx_budget_entries_month_year '
        'ON budget_entries (year, month)',
      );
    },
    onUpgrade: (m, from, to) async {
      // Add migration steps here when schemaVersion is incremented.
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'envelope_db');
  }
}
